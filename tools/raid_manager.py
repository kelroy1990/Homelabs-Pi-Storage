#!/usr/bin/env python3
"""
RAID Configuration Manager for Raspberry Pi
A modern Python replacement for the bash raid_script.sh

Features:
- ZFS and BTRFS management
- Interactive CLI with rich formatting
- Modular, object-oriented design
- Comprehensive error handling
- Easy configuration and maintenance
"""

import os
import sys
import json
import subprocess
import logging
import time
import math
import datetime
import re
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, field
from enum import Enum
import argparse

# Try to import rich for better CLI experience
try:
    from rich.console import Console as RichConsole
    from rich.table import Table
    from rich.panel import Panel
    from rich.prompt import Prompt, Confirm
    from rich.progress import Progress, SpinnerColumn, TextColumn
    from rich.text import Text
    RICH_AVAILABLE = True
except ImportError:
    RICH_AVAILABLE = False
    print("⚠️  Para una mejor experiencia, instala rich: pip install rich")

class RAIDType(Enum):
    """Tipos de RAID soportados"""
    STRIPE = "stripe"
    MIRROR = "mirror" 
    RAIDZ1 = "raidz1"
    RAIDZ2 = "raidz2"
    RAIDZ3 = "raidz3"
    BTRFS_RAID0 = "btrfs_raid0"
    BTRFS_RAID1 = "btrfs_raid1"
    BTRFS_RAID10 = "btrfs_raid10"
    BTRFS_RAID5 = "btrfs_raid5"
    BTRFS_RAID6 = "btrfs_raid6"

class FilesystemType(Enum):
    """Tipos de filesystem soportados"""
    ZFS = "zfs"
    BTRFS = "btrfs"

@dataclass
class Disk:
    """Representa un disco en el sistema"""
    name: str
    size: int
    model: str
    serial: str
    sector_size: int
    is_system: bool = False
    has_partitions: bool = False
    filesystem_type: Optional[str] = None
    mount_points: List[str] = field(default_factory=list)
    
    @property
    def device_path(self) -> str:
        return f"/dev/{self.name}"
    
    @property
    def size_human(self) -> str:
        """Tamaño en formato legible"""
        size = self.size
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if size < 1024:
                return f"{size:.1f} {unit}"
            size /= 1024
        return f"{size:.1f} PB"

@dataclass
class Pool:
    """Representa un pool ZFS o filesystem BTRFS"""
    name: str
    type: FilesystemType
    raid_type: RAIDType
    disks: List[Disk]
    health: str
    size: int
    used: int
    available: int
    ashift: Optional[int] = None
    
    @property
    def usage_percent(self) -> float:
        return (self.used / self.size) * 100 if self.size > 0 else 0

class UIConsole:
    """Manejo de la interfaz de usuario"""
    
    def __init__(self):
        if RICH_AVAILABLE:
            self.console = RichConsole()
        else:
            self.console = None
    
    def print(self, message: str, style: str = ""):
        """Imprime un mensaje con estilo opcional"""
        if RICH_AVAILABLE and self.console:
            self.console.print(message, style=style)
        else:
            print(message)
    
    def print_panel(self, message: str, title: str = "", style: str = ""):
        """Imprime un panel con mensaje"""
        if RICH_AVAILABLE and self.console:
            panel = Panel(message, title=title, style=style)
            self.console.print(panel)
        else:
            print(f"\n=== {title} ===")
            print(message)
            print("=" * (len(title) + 8))
    
    def prompt(self, message: str, default: str = "") -> str:
        """Solicita input del usuario"""
        if RICH_AVAILABLE:
            return Prompt.ask(message, default=default)
        else:
            response = input(f"{message} [{default}]: ").strip()
            return response if response else default
    
    def confirm(self, message: str, default: bool = False) -> bool:
        """Solicita confirmación del usuario"""
        if RICH_AVAILABLE:
            return Confirm.ask(message, default=default)
        else:
            while True:
                response = input(f"{message} ({'S/n' if default else 's/N'}): ").strip().lower()
                if not response:
                    return default
                if response in ['s', 'sí', 'si', 'y', 'yes']:
                    return True
                elif response in ['n', 'no']:
                    return False
                print("Por favor responde 's' (sí) o 'n' (no)")

class SystemManager:
    """Gestión de operaciones del sistema"""
    
    def __init__(self, console: UIConsole):
        self.console = console
        self.logger = self._setup_logging()
        # Lista de comandos que típicamente requieren sudo
        self.sudo_commands = {
            'umount', 'mount', 'mkfs', 'wipefs', 'dd', 'zpool', 'zfs', 
            'btrfs', 'mdadm', 'pvremove', 'vgchange', 'vgreduce', 'lvremove',
            'partprobe', 'sgdisk', 'mkdir', 'chown', 'chmod'
        }
    
    def _setup_logging(self) -> logging.Logger:
        """Configura el logging"""
        log_handlers = []
        
        # Intentar crear log en /var/log, si no funciona usar directorio local
        try:
            log_handlers.append(logging.FileHandler('/var/log/raid_manager.log'))
        except PermissionError:
            # Usar directorio local si no hay permisos
            log_file = Path.home() / '.raid_manager.log'
            log_handlers.append(logging.FileHandler(log_file))
        
        # Solo logging a archivo, no a consola durante detección
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=log_handlers
        )
        return logging.getLogger(__name__)
    
    def run_command(self, command: List[str], check: bool = True, 
                   capture_output: bool = True, show_errors: bool = False,
                   use_sudo: bool = None) -> subprocess.CompletedProcess:
        """Ejecuta un comando del sistema con sudo automático cuando sea necesario"""
        
        # Determinar si necesita sudo automáticamente
        if use_sudo is None:
            command_name = command[0].split('/')[-1]  # Obtener nombre base del comando
            needs_sudo = command_name in self.sudo_commands and not self.is_root()
        else:
            needs_sudo = use_sudo
        
        # Agregar sudo si es necesario
        if needs_sudo:
            command = ['sudo'] + command
        
        try:
            self.logger.info(f"Ejecutando: {' '.join(command)}")
            result = subprocess.run(
                command,
                check=check,
                capture_output=capture_output,
                text=True
            )
            return result
        except subprocess.CalledProcessError as e:
            self.logger.error(f"Error ejecutando comando: {e}")
            if show_errors:
                self.console.print(f"❌ Error ejecutando comando: {e}", style="red")
            raise
    
    def run_command_safe(self, command: List[str], show_errors: bool = False) -> bool:
        """Ejecuta un comando de forma segura, retorna True si fue exitoso"""
        try:
            self.run_command(command, check=True, show_errors=show_errors)
            return True
        except subprocess.CalledProcessError:
            return False
    
    def is_root(self) -> bool:
        """Verifica si el script se ejecuta como root"""
        return os.geteuid() == 0
    
    def check_sudo(self) -> bool:
        """Verifica disponibilidad de sudo"""
        try:
            self.run_command(['sudo', '-n', 'true'], use_sudo=False)
            return True
        except subprocess.CalledProcessError:
            return False

class DiskManager:
    """Gestión de discos del sistema"""
    
    def __init__(self, system: SystemManager, console: UIConsole):
        self.system = system
        self.console = console
    
    def detect_disks(self) -> List[Disk]:
        """Detecta todos los discos disponibles"""
        self.console.print("🔍 Detectando discos disponibles...", style="blue")
        
        disks = []
        try:
            # Usar lsblk para obtener información de discos
            result = self.system.run_command([
                'lsblk', '-J', '-o', 
                'NAME,SIZE,MODEL,SERIAL,PHY-SEC,TYPE,MOUNTPOINT,FSTYPE'
            ])
            
            data = json.loads(result.stdout)
            system_disks = self._get_system_disks()
            
            for device in data['blockdevices']:
                if device['type'] == 'disk':
                    disk = self._parse_disk_info(device, system_disks)
                    if disk:
                        disks.append(disk)
                        
        except Exception as e:
            self.console.print(f"❌ Error detectando discos: {e}", style="red")
            
        return disks
    
    def _get_system_disks(self) -> set:
        """Obtiene lista de discos del sistema que no deben tocarse"""
        system_disks = set()
        try:
            # Disco raíz
            result = self.system.run_command(['findmnt', '-n', '-o', 'SOURCE', '/'])
            root_device = result.stdout.strip()
            if root_device:
                # Extraer nombre del disco (sin partición)
                disk_name = root_device.split('/')[-1].rstrip('0123456789')
                system_disks.add(disk_name)
                
            # Otros puntos de montaje críticos del sistema
            critical_mounts = ['/boot', '/usr', '/var', '/etc', '/lib', '/bin', '/sbin', '/home']
            for mount_point in critical_mounts:
                try:
                    result = self.system.run_command(['findmnt', '-n', '-o', 'SOURCE', mount_point])
                    device = result.stdout.strip()
                    if device:
                        disk_name = device.split('/')[-1].rstrip('0123456789')
                        system_disks.add(disk_name)
                except subprocess.CalledProcessError:
                    continue
            
            # Detectar todos los dispositivos montados con filesystems críticos
            try:
                result = self.system.run_command(['findmnt', '-rn', '-o', 'SOURCE,TARGET'])
                for line in result.stdout.strip().split('\n'):
                    if line.strip():
                        parts = line.split()
                        if len(parts) >= 2:
                            device = parts[0]
                            mount_point = parts[1]
                            
                            # Si está montado en puntos críticos del sistema
                            if any(mount_point.startswith(critical) for critical in ['/', '/boot', '/usr', '/var', '/etc']):
                                if device.startswith('/dev/'):
                                    disk_name = device.split('/')[-1].rstrip('0123456789')
                                    system_disks.add(disk_name)
            except subprocess.CalledProcessError:
                pass
            
            # PROTECCIÓN CRÍTICA: Agregar TODA la familia mmcblk0 (Raspberry Pi)
            # Esto incluye mmcblk0, mmcblk0boot0, mmcblk0boot1, mmcblk0rpmb, etc.
            system_disks.add('mmcblk0')
            # También proteger cualquier variante de mmcblk0
            system_disks.add('mmcblk0boot0')
            system_disks.add('mmcblk0boot1')
            system_disks.add('mmcblk0rpmb')
            
            # Proteger otros dispositivos típicos del sistema
            system_disks.add('nvme0n1')  # SSD NVMe del sistema
                    
        except Exception as e:
            self.console.print(f"⚠️  Error detectando discos del sistema: {e}", style="yellow")
            # Fallback de seguridad: agregar discos típicos del sistema
            system_disks.update(['sda', 'mmcblk0', 'mmcblk0boot0', 'mmcblk0boot1', 'mmcblk0rpmb', 'nvme0n1'])
            
        return system_disks
    
    def _parse_disk_info(self, device: dict, system_disks: set) -> Optional[Disk]:
        """Parsea información de un disco desde lsblk"""
        name = device['name']
        
        # Convertir tamaño a bytes
        size_str = device['size']
        size_bytes = self._parse_size(size_str)
        
        # Filtrar discos con tamaño 0 o inválido
        if size_bytes <= 0:
            return None
        
        # Información del disco
        model = device.get('model', 'Desconocido')
        serial = device.get('serial', 'Desconocido')
        sector_size = int(device.get('phy-sec', 512))
        
        # Verificar si es disco del sistema
        is_system_disk = name in system_disks
        
        # Verificar particiones y filesystems
        has_partitions = len(device.get('children', [])) > 0
        filesystem_type = None
        mount_points = []
        
        if has_partitions:
            for child in device['children']:
                if child.get('fstype'):
                    filesystem_type = child['fstype']
                if child.get('mountpoint'):
                    mount_points.append(child['mountpoint'])
                    # Si tiene montajes críticos del sistema, marcarlo como sistema
                    if child['mountpoint'] in ['/', '/boot', '/usr', '/var', '/etc', '/lib', '/bin', '/sbin']:
                        is_system_disk = True
        
        return Disk(
            name=name,
            size=size_bytes,
            model=model,
            serial=serial,
            sector_size=sector_size,
            is_system=is_system_disk,
            has_partitions=has_partitions,
            filesystem_type=filesystem_type,
            mount_points=mount_points
        )
    
    def _parse_size(self, size_str: str) -> int:
        """Convierte string de tamaño a bytes"""
        if not size_str:
            return 0
            
        # Normalizar formato (cambiar comas por puntos)
        size_str = size_str.replace(',', '.').upper().strip()
        
        multipliers = {
            'B': 1,
            'K': 1024,
            'M': 1024**2,
            'G': 1024**3,
            'T': 1024**4,
            'P': 1024**5
        }
        
        # Buscar sufijo
        for suffix, multiplier in multipliers.items():
            if size_str.endswith(suffix):
                try:
                    number_str = size_str[:-1].strip()
                    number = float(number_str)
                    return int(number * multiplier)
                except ValueError:
                    break
        
        # Sin sufijo, asumir bytes
        try:
            # Intentar parsear como número directo
            return int(float(size_str))
        except ValueError:
            return 0

class RAIDManager:
    """Gestor principal de RAID"""
    
    def __init__(self):
        self.console = UIConsole()
        self.system = SystemManager(self.console)
        self.disk_manager = DiskManager(self.system, self.console)
        
    def main_menu(self):
        """Menú principal"""
        self.console.print_panel(
            "Script de Configuración RAID para Raspberry Pi\n"
            "Versión Python - Gestión avanzada de almacenamiento",
            title="🏠 RAID Manager",
            style="blue"
        )
        
        while True:
            self.console.print("\n📋 OPCIONES PRINCIPALES:")
            options = [
                "1. Detectar configuraciones RAID existentes",
                "2. Crear nueva configuración RAID",
                "3. Gestionar pools/filesystems existentes",
                "4. Herramientas de disco",
                "5. Configuración del sistema",
                "0. Salir"
            ]
            
            for option in options:
                self.console.print(f"   {option}")
            
            choice = self.console.prompt("👉 Selecciona una opción", "0")
            
            if choice == "0":
                self.console.print("👋 ¡Hasta luego!", style="green")
                break
            elif choice == "1":
                self.detect_existing_raid()
            elif choice == "2":
                self.create_raid_wizard()
            elif choice == "3":
                self.manage_existing()
            elif choice == "4":
                self.disk_tools()
            elif choice == "5":
                self.system_configuration()
            else:
                self.console.print("❌ Opción inválida", style="red")
    
    def detect_existing_raid(self):
        """Detecta configuraciones RAID existentes"""
        self.console.print_panel(
            "Detectando configuraciones RAID existentes...",
            title="🔍 Detección RAID"
        )
        
        # Verificar permisos
        if not self.system.is_root() and not self.system.check_sudo():
            self.console.print("⚠️  Algunas funciones requieren permisos de administrador", style="yellow")
        
        found_anything = False
        
        # Detectar pools ZFS
        if self._detect_zfs_pools():
            found_anything = True
        
        # Detectar filesystems BTRFS
        if self._detect_btrfs_filesystems():
            found_anything = True
        
        # Detectar arrays MDADM
        if self._detect_mdadm_arrays():
            found_anything = True
        
        # Detectar Volume Groups LVM
        if self._detect_lvm_volumes():
            found_anything = True
        
        # Si no se encontró nada
        if not found_anything:
            self.console.print_panel(
                "No se detectaron configuraciones RAID activas en el sistema.",
                title="📭 Sin configuraciones RAID",
                style="yellow"
            )
    
    def create_raid_wizard(self):
        """Asistente para crear nueva configuración RAID"""
        self.console.print_panel(
            "Asistente de creación de RAID\n"
            "Te guiaremos paso a paso para crear tu configuración ideal",
            title="🧙‍♂️ Asistente RAID"
        )
        
        # Verificar permisos
        if not self.system.is_root() and not self.system.check_sudo():
            self.console.print("⚠️  Se requieren permisos de administrador para crear RAID", style="yellow")
            if not self.console.confirm("¿Continuar de todas formas?", default=False):
                return
        
        # Paso 1: Detectar discos disponibles
        self.console.print_panel("Paso 1: Detectando discos disponibles", title="🔍 Detección")
        disks = self.disk_manager.detect_disks()
        available_disks = [d for d in disks if not d.is_system]
        
        if not available_disks:
            self.console.print("❌ No hay discos disponibles para RAID", style="red")
            self.console.print("💡 Todos los discos detectados son del sistema o están en uso crítico", style="blue")
            
            # Mostrar discos del sistema detectados para información
            system_disks = [d for d in disks if d.is_system]
            if system_disks:
                self.console.print("\n🔒 Discos del sistema detectados (protegidos):")
                for disk in system_disks:
                    mount_info = f" (montajes: {', '.join(disk.mount_points)})" if disk.mount_points else ""
                    self.console.print(f"   • {disk.name} - {disk.size_human}{mount_info}")
            
            return
        
        # Mostrar discos detectados
        self._show_available_disks(available_disks)
        
        # Paso 2: Seleccionar tipo de filesystem
        self.console.print_panel("Paso 2: Seleccionando tipo de filesystem", title="🗂️ Filesystem")
        fs_type = self._select_filesystem_type()
        
        # Paso 3 y 4: Bucle para selección de discos y tipo de RAID
        while True:
            # Paso 3: Seleccionar discos
            self.console.print_panel("Paso 3: Seleccionando discos para el RAID", title="💾 Selección")
            selected_disks = self._select_disks(available_disks)
            
            if not selected_disks:
                self.console.print("❌ Operación cancelada", style="yellow")
                return
            
            # Paso 4: Seleccionar tipo de RAID
            self.console.print_panel("Paso 4: Seleccionando tipo de RAID", title="⚙️ Configuración")
            raid_type = self._select_raid_type(fs_type, len(selected_disks))
            
            # Si raid_type es None, significa que quiere volver a selección de discos
            if raid_type is None:
                self.console.print("↩️  Volviendo a selección de discos...", style="blue")
                continue
            else:
                break  # Salir del bucle si se seleccionó un tipo válido
        
        # Paso 5: Cálculo de capacidad y confirmación
        self.console.print_panel("Paso 5: Resumen y confirmación", title="📋 Confirmación")
        capacity_info = self._calculate_raid_capacity(raid_type, selected_disks)
        
        # Mostrar resumen
        self._show_raid_summary(fs_type, raid_type, selected_disks, capacity_info)
        
        # Confirmación final
        if not self.console.confirm("¿Proceder con la creación del RAID?", default=False):
            self.console.print("❌ Operación cancelada", style="yellow")
            return
        
        # Paso 6: Ejecución
        self.console.print_panel("Paso 6: Creando RAID", title="🔨 Ejecución")
        self._configure_raid(fs_type, raid_type, selected_disks)
    
    def _detect_zfs_pools(self):
        """Detecta pools ZFS existentes"""
        try:
            # Verificar si ZFS está disponible
            self.system.run_command(['which', 'zpool'])
            
            result = self.system.run_command(['zpool', 'list', '-H'])
            if result.stdout.strip():
                self._show_zfs_pools_detailed()
                return True
            else:
                return False
        except subprocess.CalledProcessError:
            return False
    
    def _show_zfs_pools_detailed(self):
        """Muestra información detallada de pools ZFS"""
        try:
            # Obtener lista de pools con información detallada
            result = self.system.run_command(['zpool', 'list', '-H', '-o', 'name,size,allocated,free,health,altroot'])
            
            if RICH_AVAILABLE:
                table = Table(title="🔷 Pools ZFS", show_header=True, header_style="bold blue")
                table.add_column("Pool", style="cyan", no_wrap=True)
                table.add_column("Tamaño", style="green")
                table.add_column("Usado", style="yellow")
                table.add_column("Libre", style="blue")
                table.add_column("Estado", style="magenta")
                table.add_column("Datasets", style="white")
                
                for line in result.stdout.strip().split('\n'):
                    if line.strip():
                        parts = line.split('\t')
                        if len(parts) >= 5:
                            pool_name = parts[0]
                            size = parts[1]
                            allocated = parts[2]
                            free = parts[3]
                            health = parts[4]
                            
                            # Obtener número de datasets
                            datasets_count = self._get_zfs_datasets_count(pool_name)
                            
                            # Formatear estado con emojis
                            health_emoji = "💚" if health == "ONLINE" else "⚠️" if health == "DEGRADED" else "❌"
                            health_display = f"{health_emoji} {health}"
                            
                            table.add_row(pool_name, size, allocated, free, health_display, str(datasets_count))
                
                self.console.console.print(table)
                
                # Mostrar información de datasets para cada pool
                self._show_zfs_datasets_info()
                
            else:
                print("\n🔷 Pools ZFS:")
                for line in result.stdout.strip().split('\n'):
                    if line.strip():
                        parts = line.split('\t')
                        if len(parts) >= 5:
                            print(f"  📦 {parts[0]} - {parts[1]} (Usado: {parts[2]}, Libre: {parts[3]}, Estado: {parts[4]})")
                            
        except subprocess.CalledProcessError as e:
            self.console.print(f"❌ Error obteniendo información de pools ZFS: {e}", style="red")
    
    def _show_zfs_datasets_info(self):
        """Muestra información de datasets para cada pool ZFS"""
        try:
            pools_result = self.system.run_command(['zpool', 'list', '-H', '-o', 'name'])
            for pool_name in pools_result.stdout.strip().split('\n'):
                if pool_name.strip():
                    # Obtener datasets del pool
                    try:
                        datasets_result = self.system.run_command(['zfs', 'list', '-H', '-r', pool_name, '-o', 'name,used,avail,mountpoint,compression'])
                        if datasets_result.stdout.strip():
                            # Crear tabla para datasets de este pool
                            if RICH_AVAILABLE:
                                datasets_table = Table(title=f"📁 Datasets del pool '{pool_name}'", show_header=True, header_style="bold cyan")
                                datasets_table.add_column("Dataset", style="cyan")
                                datasets_table.add_column("Usado", style="yellow")
                                datasets_table.add_column("Disponible", style="green")
                                datasets_table.add_column("Montaje", style="blue")
                                datasets_table.add_column("Compresión", style="magenta")
                                
                                for line in datasets_result.stdout.strip().split('\n'):
                                    parts = line.split('\t')
                                    if len(parts) >= 4 and parts[0] != pool_name:  # Skip pool itself
                                        dataset_name = parts[0].split('/')[-1] if '/' in parts[0] else parts[0]
                                        used = parts[1]
                                        avail = parts[2] 
                                        mountpoint = parts[3]
                                        compression = parts[4] if len(parts) > 4 else "N/A"
                                        
                                        datasets_table.add_row(dataset_name, used, avail, mountpoint, compression)
                                
                                self.console.console.print(datasets_table)
                                
                            else:
                                print(f"\n📁 Datasets del pool '{pool_name}':")
                                for line in datasets_result.stdout.strip().split('\n'):
                                    parts = line.split('\t')
                                    if len(parts) >= 4 and parts[0] != pool_name:
                                        dataset_name = parts[0].split('/')[-1]
                                        used = parts[1]
                                        mountpoint = parts[3]
                                        print(f"  • {dataset_name} - Usado: {used}, Montaje: {mountpoint}")
                    except subprocess.CalledProcessError:
                        pass
                        
        except subprocess.CalledProcessError:
            pass
    
    def _get_zfs_datasets_count(self, pool_name: str) -> int:
        """Obtiene el número de datasets en un pool ZFS"""
        try:
            result = self.system.run_command(['zfs', 'list', '-H', '-r', pool_name])
            # Contar líneas menos la del pool principal
            lines = result.stdout.strip().split('\n')
            return len([line for line in lines if line.strip()]) - 1
        except subprocess.CalledProcessError:
            return 0
    
    def _show_zfs_pool_details(self):
        """Muestra detalles adicionales de cada pool ZFS"""
        try:
            pools_result = self.system.run_command(['zpool', 'list', '-H', '-o', 'name'])
            for pool_name in pools_result.stdout.strip().split('\n'):
                if pool_name.strip():
                    self.console.print(f"\n📋 Detalles del pool '{pool_name}':", style="bold blue")
                    
                    # Información de datasets
                    try:
                        datasets_result = self.system.run_command(['zfs', 'list', '-H', '-r', pool_name, '-o', 'name,used,avail,mountpoint,compression'])
                        if datasets_result.stdout.strip():
                            self.console.print("  📁 Datasets:")
                            for line in datasets_result.stdout.strip().split('\n'):
                                parts = line.split('\t')
                                if len(parts) >= 4 and parts[0] != pool_name:  # Skip pool itself
                                    dataset_name = parts[0]
                                    used = parts[1]
                                    avail = parts[2] 
                                    mountpoint = parts[3]
                                    compression = parts[4] if len(parts) > 4 else "N/A"
                                    self.console.print(f"    • {dataset_name.split('/')[-1]} - Usado: {used}, Montaje: {mountpoint}, Compresión: {compression}")
                    except subprocess.CalledProcessError:
                        pass
                    
                    # Información de dispositivos
                    try:
                        status_result = self.system.run_command(['zpool', 'status', pool_name])
                        self.console.print("  💿 Dispositivos:")
                        
                        # Parsear salida de zpool status para mostrar dispositivos
                        in_config = False
                        config_lines = []
                        
                        for line in status_result.stdout.split('\n'):
                            stripped_line = line.strip()
                            
                            if 'config:' in line.lower():
                                in_config = True
                                continue
                            elif in_config and stripped_line and not stripped_line.startswith('NAME') and not stripped_line.startswith('errors'):
                                if not stripped_line.startswith('pool:') and not stripped_line.startswith('state:'):
                                    # Buscar líneas que contengan dispositivos
                                    parts = stripped_line.split()
                                    if parts and (parts[0].startswith('/dev/') or 
                                                any(x in parts[0] for x in ['sd', 'nvme', 'loop']) or
                                                parts[0] in ['mirror-0', 'raidz1-0', 'raidz2-0', 'raidz3-0']):
                                        
                                        device_name = parts[0]
                                        device_state = parts[1] if len(parts) > 1 else "UNKNOWN"
                                        read_errors = parts[2] if len(parts) > 2 else "0"
                                        write_errors = parts[3] if len(parts) > 3 else "0"
                                        checksum_errors = parts[4] if len(parts) > 4 else "0"
                                        
                                        # Formatear estado con emoji
                                        if device_state == "ONLINE":
                                            state_emoji = "✅"
                                        elif device_state in ["DEGRADED", "FAULTED"]:
                                            state_emoji = "⚠️"
                                        elif device_state == "OFFLINE":
                                            state_emoji = "❌"
                                        else:
                                            state_emoji = "❓"
                                        
                                        self.console.print(f"    • {device_name} - {state_emoji} {device_state}")
                                        
                                        # Mostrar errores si los hay
                                        if any(err != "0" for err in [read_errors, write_errors, checksum_errors]):
                                            self.console.print(f"      ⚠️  Errores: R:{read_errors} W:{write_errors} C:{checksum_errors}")
                            elif in_config and (stripped_line.startswith('errors:') or stripped_line == ''):
                                break
                                
                        # Si no se encontraron dispositivos específicos, mostrar información básica
                        if not any('✅' in line or '⚠️' in line or '❌' in line for line in config_lines):
                            # Obtener información básica del pool
                            try:
                                list_result = self.system.run_command(['zpool', 'list', '-v', pool_name])
                                self.console.print("    📊 Configuración del pool detectada")
                            except subprocess.CalledProcessError:
                                pass
                                
                    except subprocess.CalledProcessError:
                        pass
                        
        except subprocess.CalledProcessError:
            pass
    
    def _detect_btrfs_filesystems(self):
        """Detecta filesystems BTRFS existentes"""
        try:
            # Verificar si BTRFS está disponible
            self.system.run_command(['which', 'btrfs'])
            
            result = self.system.run_command(['btrfs', 'filesystem', 'show'])
            if result.stdout.strip() and 'no btrfs found' not in result.stdout.lower():
                self._show_btrfs_detailed()
                return True
            else:
                return False
        except subprocess.CalledProcessError:
            return False
    
    def _show_btrfs_detailed(self):
        """Muestra información detallada de filesystems BTRFS"""
        try:
            # Obtener información de filesystems BTRFS
            result = self.system.run_command(['btrfs', 'filesystem', 'show'])
            
            if RICH_AVAILABLE:
                table = Table(title="🌿 Filesystems BTRFS", show_header=True, header_style="bold green")
                table.add_column("UUID", style="cyan")
                table.add_column("Label", style="green")
                table.add_column("Dispositivos", style="yellow")
                table.add_column("Uso", style="blue")
                table.add_column("Estado", style="magenta")
                
                # Parsear salida de btrfs filesystem show
                current_fs = {}
                for line in result.stdout.split('\n'):
                    line = line.strip()
                    if line.startswith('uuid:'):
                        if current_fs:
                            # Agregar filesystem anterior a la tabla
                            self._add_btrfs_to_table(table, current_fs)
                        current_fs = {'uuid': line.split('uuid:')[1].strip()}
                    elif 'Label:' in line:
                        current_fs['label'] = line.split('Label:')[1].strip().replace("'", "")
                    elif line.startswith('devid'):
                        if 'devices' not in current_fs:
                            current_fs['devices'] = []
                        # Extraer información del dispositivo
                        parts = line.split()
                        for part in parts:
                            if part.startswith('/dev/'):
                                current_fs['devices'].append(part)
                
                # Agregar último filesystem
                if current_fs:
                    self._add_btrfs_to_table(table, current_fs)
                
                self.console.console.print(table)
                
            else:
                print("\n🌿 Filesystems BTRFS:")
                # Versión texto simple
                current_fs = None
                for line in result.stdout.split('\n'):
                    line = line.strip()
                    if line.startswith('uuid:'):
                        uuid = line.split('uuid:')[1].strip()
                        print(f"  📦 UUID: {uuid}")
                    elif 'Label:' in line:
                        label = line.split('Label:')[1].strip().replace("'", "")
                        print(f"     Label: {label}")
                    elif line.startswith('devid'):
                        parts = line.split()
                        for part in parts:
                            if part.startswith('/dev/'):
                                print(f"     Dispositivo: {part}")
                                
        except subprocess.CalledProcessError as e:
            self.console.print(f"❌ Error obteniendo información de BTRFS: {e}", style="red")
    
    def _add_btrfs_to_table(self, table, fs_info):
        """Añade información de filesystem BTRFS a la tabla"""
        uuid_short = fs_info.get('uuid', 'N/A')[:8] + '...'
        label = fs_info.get('label', 'Sin label')
        devices = ', '.join(fs_info.get('devices', []))
        
        # Obtener información de uso
        usage_info = self._get_btrfs_usage(fs_info.get('devices', []))
        
        table.add_row(
            uuid_short,
            label,
            devices,
            usage_info.get('usage', 'N/A'),
            usage_info.get('status', '✅ OK')
        )
    
    def _get_btrfs_usage(self, devices):
        """Obtiene información de uso de un filesystem BTRFS"""
        if not devices:
            return {'usage': 'N/A', 'status': 'N/A'}
        
        try:
            # Intentar obtener información de uso del primer dispositivo
            device = devices[0]
            result = self.system.run_command(['btrfs', 'filesystem', 'usage', device])
            
            # Parsear información básica
            usage_lines = result.stdout.split('\n')
            size = "N/A"
            used = "N/A"
            
            for line in usage_lines:
                if 'Device size:' in line:
                    size = line.split('Device size:')[1].strip()
                elif 'Used:' in line and 'Device' not in line:
                    used = line.split('Used:')[1].strip()
            
            return {
                'usage': f"Usado: {used} / {size}",
                'status': '✅ OK'
            }
            
        except subprocess.CalledProcessError:
            return {'usage': 'Error', 'status': '❌ Error'}
    
    def _show_btrfs_usage_details(self):
        """Muestra detalles de uso de filesystems BTRFS"""
        try:
            # Obtener lista de filesystems montados
            result = self.system.run_command(['findmnt', '-t', 'btrfs', '-n', '-o', 'TARGET,SOURCE'])
            
            if result.stdout.strip():
                self.console.print("\n📊 Información detallada de BTRFS:", style="bold blue")
                
                for line in result.stdout.strip().split('\n'):
                    parts = line.split()
                    if len(parts) >= 2:
                        mountpoint = parts[0]
                        device = parts[1]
                        
                        self.console.print(f"  📁 Montado en: {mountpoint}")
                        self.console.print(f"     Dispositivo: {device}")
                        
                        # Obtener información de subvolúmenes
                        try:
                            subvol_result = self.system.run_command(['btrfs', 'subvolume', 'list', mountpoint])
                            if subvol_result.stdout.strip():
                                subvol_count = len(subvol_result.stdout.strip().split('\n'))
                                self.console.print(f"     Subvolúmenes: {subvol_count}")
                        except subprocess.CalledProcessError:
                            pass
                        
                        self.console.print("")
                        
        except subprocess.CalledProcessError:
            pass
    
    def _detect_mdadm_arrays(self):
        """Detecta arrays MDADM existentes"""
        try:
            # Verificar si MDADM está disponible
            self.system.run_command(['which', 'mdadm'])
            
            # Leer /proc/mdstat
            result = self.system.run_command(['cat', '/proc/mdstat'])
            
            if 'md' in result.stdout and 'active' in result.stdout:
                self._show_mdadm_detailed()
                return True
            else:
                return False
                
        except subprocess.CalledProcessError:
            return False
    
    def _show_mdadm_detailed(self):
        """Muestra información detallada de arrays MDADM"""
        try:
            result = self.system.run_command(['cat', '/proc/mdstat'])
            
            if RICH_AVAILABLE:
                table = Table(title="⚡ Arrays MDADM", show_header=True, header_style="bold yellow")
                table.add_column("Array", style="cyan")
                table.add_column("Tipo RAID", style="green")
                table.add_column("Estado", style="yellow")
                table.add_column("Dispositivos", style="blue")
                table.add_column("Progreso", style="magenta")
                
                # Parsear /proc/mdstat
                arrays_info = self._parse_mdstat(result.stdout)
                
                for array_info in arrays_info:
                    status_emoji = "✅" if array_info['active'] else "❌"
                    status = f"{status_emoji} {'Activo' if array_info['active'] else 'Inactivo'}"
                    
                    progress = array_info.get('progress', 'Completo')
                    
                    table.add_row(
                        array_info['name'],
                        array_info['raid_type'],
                        status,
                        ', '.join(array_info['devices']),
                        progress
                    )
                
                self.console.console.print(table)
                
            else:
                print("\n⚡ Arrays MDADM:")
                arrays_info = self._parse_mdstat(result.stdout)
                for array_info in arrays_info:
                    status = "Activo" if array_info['active'] else "Inactivo"
                    print(f"  📦 {array_info['name']} - {array_info['raid_type']} - {status}")
                    print(f"     Dispositivos: {', '.join(array_info['devices'])}")
                    
        except subprocess.CalledProcessError as e:
            self.console.print(f"❌ Error obteniendo información de MDADM: {e}", style="red")
    
    def _parse_mdstat(self, mdstat_content):
        """Parsea el contenido de /proc/mdstat"""
        arrays = []
        lines = mdstat_content.split('\n')
        
        i = 0
        while i < len(lines):
            line = lines[i].strip()
            
            if line.startswith('md') and ':' in line:
                # Línea de definición del array
                parts = line.split()
                array_name = parts[0]
                active = 'active' in line
                
                # Extraer tipo RAID
                raid_type = "Unknown"
                if 'raid0' in line:
                    raid_type = "RAID 0"
                elif 'raid1' in line:
                    raid_type = "RAID 1"
                elif 'raid5' in line:
                    raid_type = "RAID 5"
                elif 'raid6' in line:
                    raid_type = "RAID 6"
                elif 'raid10' in line:
                    raid_type = "RAID 10"
                
                # Extraer dispositivos
                devices = []
                for part in parts:
                    if part.startswith('sd') or part.startswith('nvme'):
                        # Limpiar sufijos como [0], [1], etc.
                        device = part.split('[')[0]
                        devices.append(device)
                
                array_info = {
                    'name': array_name,
                    'active': active,
                    'raid_type': raid_type,
                    'devices': devices
                }
                
                # Verificar línea siguiente para progreso
                if i + 1 < len(lines):
                    next_line = lines[i + 1].strip()
                    if '%' in next_line and ('recovery' in next_line or 'resync' in next_line or 'rebuild' in next_line):
                        # Extraer información de progreso
                        if 'recovery' in next_line:
                            array_info['progress'] = "🔄 Recuperando..."
                        elif 'resync' in next_line:
                            array_info['progress'] = "🔄 Resincronizando..."
                        elif 'rebuild' in next_line:
                            array_info['progress'] = "🔄 Reconstruyendo..."
                
                arrays.append(array_info)
            
            i += 1
        
        return arrays
    
    def _show_mdadm_details(self):
        """Muestra detalles adicionales de arrays MDADM"""
        try:
            # Obtener lista de arrays activos
            result = self.system.run_command(['cat', '/proc/mdstat'])
            arrays_info = self._parse_mdstat(result.stdout)
            
            for array_info in arrays_info:
                array_name = array_info['name']
                self.console.print(f"\n📋 Detalles del array '{array_name}':", style="bold blue")
                
                try:
                    # Obtener información detallada con mdadm --detail
                    detail_result = self.system.run_command(['mdadm', '--detail', f'/dev/{array_name}'])
                    
                    # Parsear información importante
                    for line in detail_result.stdout.split('\n'):
                        line = line.strip()
                        if 'Array Size' in line:
                            size = line.split(':')[1].strip()
                            self.console.print(f"  📏 Tamaño: {size}")
                        elif 'Used Dev Size' in line:
                            used_size = line.split(':')[1].strip()
                            self.console.print(f"  💾 Tamaño por dispositivo: {used_size}")
                        elif 'State :' in line:
                            state = line.split(':')[1].strip()
                            self.console.print(f"  🔍 Estado: {state}")
                        elif 'Active Devices' in line:
                            active_devs = line.split(':')[1].strip()
                            self.console.print(f"  ✅ Dispositivos activos: {active_devs}")
                        elif 'Failed Devices' in line:
                            failed_devs = line.split(':')[1].strip()
                            if failed_devs != '0':
                                self.console.print(f"  ❌ Dispositivos fallidos: {failed_devs}")
                        
                except subprocess.CalledProcessError:
                    self.console.print(f"  ⚠️  No se pudo obtener información detallada de {array_name}")
                    
        except subprocess.CalledProcessError:
            pass
    
    def _detect_lvm_volumes(self):
        """Detecta Volume Groups LVM existentes"""
        try:
            # Verificar si LVM está disponible
            self.system.run_command(['which', 'vgs'])
            
            result = self.system.run_command(['vgs', '--noheadings'])
            if result.stdout.strip():
                self._show_lvm_detailed()
                return True
            else:
                return False
                
        except subprocess.CalledProcessError:
            return False
    
    def _show_lvm_detailed(self):
        """Muestra información detallada de Volume Groups LVM"""
        try:
            result = self.system.run_command(['vgs', '--noheadings', '--units', 'g'])
            
            if RICH_AVAILABLE:
                table = Table(title="💼 Volume Groups LVM", show_header=True, header_style="bold magenta")
                table.add_column("VG Name", style="cyan")
                table.add_column("PVs", style="green")
                table.add_column("LVs", style="yellow")
                table.add_column("Tamaño", style="blue")
                table.add_column("Libre", style="magenta")
                table.add_column("Logical Volumes", style="white")
                
                for line in result.stdout.strip().split('\n'):
                    if line.strip():
                        parts = line.split()
                        if len(parts) >= 6:
                            vg_name = parts[0]
                            pv_count = parts[1]
                            lv_count = parts[2]
                            vg_size = parts[5]
                            vg_free = parts[6]
                            
                            # Obtener nombres de logical volumes
                            lv_names = self._get_lvm_logical_volumes(vg_name)
                            lv_display = ', '.join(lv_names[:3])  # Mostrar hasta 3
                            if len(lv_names) > 3:
                                lv_display += f" (+{len(lv_names)-3} más)"
                            
                            table.add_row(vg_name, pv_count, lv_count, vg_size, vg_free, lv_display)
                
                self.console.console.print(table)
                
            else:
                print("\n💼 Volume Groups LVM:")
                for line in result.stdout.strip().split('\n'):
                    if line.strip():
                        parts = line.split()
                        if len(parts) >= 6:
                            print(f"  📦 {parts[0]} - PVs: {parts[1]}, LVs: {parts[2]}, Tamaño: {parts[5]}")
                            
        except subprocess.CalledProcessError as e:
            self.console.print(f"❌ Error obteniendo información de LVM: {e}", style="red")
    
    def _get_lvm_logical_volumes(self, vg_name):
        """Obtiene nombres de logical volumes de un VG"""
        try:
            result = self.system.run_command(['lvs', '--noheadings', '-o', 'name', vg_name])
            return [line.strip() for line in result.stdout.strip().split('\n') if line.strip()]
        except subprocess.CalledProcessError:
            return []
    
    def _show_lvm_details(self):
        """Muestra detalles adicionales de Volume Groups LVM"""
        try:
            vgs_result = self.system.run_command(['vgs', '--noheadings', '-o', 'name'])
            
            for line in vgs_result.stdout.strip().split('\n'):
                vg_name = line.strip()
                if vg_name:
                    self.console.print(f"\n📋 Detalles del Volume Group '{vg_name}':", style="bold blue")
                    
                    # Información de Physical Volumes
                    try:
                        pvs_result = self.system.run_command(['pvs', '--noheadings', '-o', 'name,size', '-S', f'vg_name={vg_name}'])
                        if pvs_result.stdout.strip():
                            self.console.print("  💿 Physical Volumes:")
                            for pv_line in pvs_result.stdout.strip().split('\n'):
                                pv_parts = pv_line.strip().split()
                                if len(pv_parts) >= 2:
                                    self.console.print(f"    • {pv_parts[0]} - {pv_parts[1]}")
                    except subprocess.CalledProcessError:
                        pass
                    
                    # Información de Logical Volumes
                    try:
                        lvs_result = self.system.run_command(['lvs', '--noheadings', '-o', 'name,size,attr', vg_name])
                        if lvs_result.stdout.strip():
                            self.console.print("  📁 Logical Volumes:")
                            for lv_line in lvs_result.stdout.strip().split('\n'):
                                lv_parts = lv_line.strip().split()
                                if len(lv_parts) >= 3:
                                    lv_name = lv_parts[0]
                                    lv_size = lv_parts[1]
                                    lv_attr = lv_parts[2]
                                    active_status = "✅ Activo" if lv_attr[4] == 'a' else "❌ Inactivo"
                                    self.console.print(f"    • {lv_name} - {lv_size} - {active_status}")
                    except subprocess.CalledProcessError:
                        pass
                        
        except subprocess.CalledProcessError:
            pass
    
    def _show_available_disks(self, disks: List[Disk]):
        """Muestra discos disponibles en formato tabla"""
        if RICH_AVAILABLE:
            table = Table(title="💾 Discos Disponibles")
            table.add_column("Disco", style="cyan")
            table.add_column("Tamaño", style="green")
            table.add_column("Modelo", style="yellow")
            table.add_column("Sectores", style="blue")
            
            for disk in disks:
                table.add_row(
                    disk.name,
                    disk.size_human,
                    disk.model,
                    str(disk.sector_size)
                )
            
            self.console.console.print(table)
        else:
            print("\n💾 Discos Disponibles:")
            for i, disk in enumerate(disks, 1):
                print(f"  {i}. {disk.name} - {disk.size_human} - {disk.model}")
    
    def _select_filesystem_type(self) -> FilesystemType:
        """Selecciona tipo de filesystem"""
        self.console.print("\n📁 Tipo de filesystem:")
        self.console.print("   1. ZFS (recomendado para máxima funcionalidad)")
        self.console.print("   2. BTRFS (alternativa moderna)")
        
        while True:
            choice = self.console.prompt("👉 Selecciona tipo", "1")
            if choice == "1":
                return FilesystemType.ZFS
            elif choice == "2":
                return FilesystemType.BTRFS
            else:
                self.console.print("❌ Opción inválida", style="red")
    
    def _select_disks(self, available_disks: List[Disk]) -> List[Disk]:
        """Selecciona discos para el RAID"""
        self.console.print("\n💾 Selección de discos para RAID:")
        
        selected_disks = []
        
        while True:
            # Mostrar tabla actualizada con selecciones
            self._show_disk_selection_table(available_disks, selected_disks)
            
            self.console.print(f"\n📋 Discos seleccionados: {len(selected_disks)}")
            if selected_disks:
                selected_names = [f"{disk.name} ({disk.size_human})" for disk in selected_disks]
                self.console.print(f"   ✅ {', '.join(selected_names)}")
            
            self.console.print("\nOpciones:")
            self.console.print("   • Números separados por espacios (ej: 1 3 4) para agregar/quitar")
            self.console.print("   • 'c' para continuar con la selección actual")
            self.console.print("   • 'q' para cancelar")
            
            choice = self.console.prompt("👉 Selección", "c").strip().lower()
            
            if choice == 'c':
                if len(selected_disks) < 2:
                    self.console.print("❌ Necesitas al menos 2 discos para RAID", style="red")
                    continue
                
                # Verificar advertencias sobre datos existentes solo al final
                disks_with_data = [d for d in selected_disks if d.has_partitions or d.filesystem_type]
                if disks_with_data:
                    self.console.print("\n⚠️  ADVERTENCIA: Los siguientes discos seleccionados contienen datos:", style="yellow")
                    for disk in disks_with_data:
                        warnings = []
                        if disk.has_partitions:
                            warnings.append("particiones")
                        if disk.filesystem_type:
                            warnings.append(f"filesystem {disk.filesystem_type}")
                        self.console.print(f"   • {disk.name} - {', '.join(warnings)}")
                    
                    self.console.print("🚨 La creación de RAID DESTRUIRÁ todos los datos existentes", style="red")
                    if not self.console.confirm("¿Continuar de todas formas?", default=False):
                        continue
                
                break
            elif choice == 'q':
                return []
            else:
                # Parsear números múltiples
                try:
                    disk_numbers = [int(x.strip()) for x in choice.split() if x.strip().isdigit()]
                    
                    for disk_num in disk_numbers:
                        disk_index = disk_num - 1
                        if 0 <= disk_index < len(available_disks):
                            disk = available_disks[disk_index]
                            
                            if disk in selected_disks:
                                selected_disks.remove(disk)
                                self.console.print(f"➖ Disco {disk.name} eliminado de la selección", style="yellow")
                            else:
                                selected_disks.append(disk)
                                self.console.print(f"➕ Disco {disk.name} agregado a la selección", style="green")
                        else:
                            self.console.print(f"❌ Número de disco inválido: {disk_num}", style="red")
                    
                    if not disk_numbers:
                        self.console.print("❌ Entrada inválida. Usa números separados por espacios", style="red")
                        
                except ValueError:
                    self.console.print("❌ Entrada inválida. Usa números separados por espacios", style="red")
        
        return selected_disks
    
    def _show_disk_selection_table(self, available_disks: List[Disk], selected_disks: List[Disk]):
        """Muestra tabla de selección de discos con estado de selección"""
        if RICH_AVAILABLE:
            table = Table(title="🎯 Selección de Discos para RAID")
            table.add_column("Sel", style="bold green", width=4, justify="center")
            table.add_column("#", style="bold cyan", width=3)
            table.add_column("Disco", style="cyan")
            table.add_column("Tamaño", style="green")
            table.add_column("Modelo", style="yellow")
            table.add_column("Estado", style="blue")
            
            for i, disk in enumerate(available_disks, 1):
                # Verificar si está seleccionado
                is_selected = disk in selected_disks
                selection_mark = "✅" if is_selected else "⬜"
                
                # Verificar estado del disco
                status_parts = []
                if disk.has_partitions:
                    status_parts.append("🟡 Particiones")
                if disk.filesystem_type:
                    status_parts.append(f"🔵 {disk.filesystem_type}")
                
                status = " + ".join(status_parts) if status_parts else "🟢 Libre"
                
                table.add_row(
                    selection_mark,
                    str(i),
                    disk.name,
                    disk.size_human,
                    disk.model,
                    status
                )
            
            self.console.console.print(table)
        else:
            print("\n🎯 Selección de Discos para RAID:")
            for i, disk in enumerate(available_disks, 1):
                is_selected = disk in selected_disks
                mark = "[✓]" if is_selected else "[ ]"
                
                status_parts = []
                if disk.has_partitions:
                    status_parts.append("Particiones")
                if disk.filesystem_type:
                    status_parts.append(disk.filesystem_type)
                
                status = " + ".join(status_parts) if status_parts else "Libre"
                
                print(f"  {mark} {i}. {disk.name} - {disk.size_human} - {disk.model} ({status})")
    
    def _select_raid_type(self, fs_type: FilesystemType, disk_count: int) -> RAIDType:
        """Selecciona tipo de RAID según filesystem y número de discos"""
        self.console.print(f"\n⚙️ Selección de tipo RAID para {fs_type.value.upper()}")
        self.console.print(f"📊 Discos disponibles: {disk_count}")
        
        if fs_type == FilesystemType.ZFS:
            return self._select_zfs_raid_type(disk_count)
        else:
            return self._select_btrfs_raid_type(disk_count)
    
    def _select_zfs_raid_type(self, disk_count: int) -> RAIDType:
        """Selecciona tipo de RAID para ZFS"""
        self.console.print("\n🔷 Tipos de RAID disponibles en ZFS:")
        
        options = []
        
        # Stripe (sin redundancia)
        options.append((1, RAIDType.STRIPE, "Stripe - Sin redundancia, máximo rendimiento"))
        
        # Mirror (requiere 2+ discos)
        if disk_count >= 2:
            options.append((2, RAIDType.MIRROR, "Mirror - Datos duplicados (50% capacidad)"))
        
        # RAIDZ1 (requiere 3+ discos)
        if disk_count >= 3:
            options.append((3, RAIDType.RAIDZ1, "RAIDZ1 - Tolerancia a 1 fallo (equivalente RAID 5)"))
        
        # RAIDZ2 (requiere 4+ discos)  
        if disk_count >= 4:
            options.append((4, RAIDType.RAIDZ2, "RAIDZ2 - Tolerancia a 2 fallos (equivalente RAID 6)"))
        
        # RAIDZ3 (requiere 5+ discos)
        if disk_count >= 5:
            options.append((5, RAIDType.RAIDZ3, "RAIDZ3 - Tolerancia a 3 fallos"))
        
        # Mostrar opciones
        for num, raid_type, description in options:
            self.console.print(f"   {num}. {description}")
        
        # Opción para volver a selección de discos
        self.console.print(f"   0. ← Volver a selección de discos")
        
        while True:
            choice = self.console.prompt("👉 Selecciona tipo de RAID", "2" if disk_count >= 2 else "1")
            
            if choice == "0":
                return None  # Señal para volver a selección de discos
            
            for num, raid_type, description in options:
                if choice == str(num):
                    return raid_type
            
            self.console.print("❌ Opción inválida", style="red")
    
    def _select_btrfs_raid_type(self, disk_count: int) -> RAIDType:
        """Selecciona tipo de RAID para BTRFS"""
        self.console.print("\n🌿 Tipos de RAID disponibles en BTRFS:")
        
        options = []
        
        # RAID 0
        options.append((1, RAIDType.BTRFS_RAID0, "RAID 0 - Sin redundancia, máximo rendimiento"))
        
        # RAID 1 (requiere 2+ discos)
        if disk_count >= 2:
            options.append((2, RAIDType.BTRFS_RAID1, "RAID 1 - Datos duplicados (50% capacidad)"))
        
        # RAID 10 (requiere 4+ discos)
        if disk_count >= 4:
            options.append((3, RAIDType.BTRFS_RAID10, "RAID 10 - Combinación RAID 0+1 (requiere 4+ discos)"))
        
        # RAID 5 (requiere 3+ discos) - EXPERIMENTAL
        if disk_count >= 3:
            options.append((4, RAIDType.BTRFS_RAID5, "RAID 5 - Tolerancia a 1 fallo ⚠️ EXPERIMENTAL"))
        
        # RAID 6 (requiere 4+ discos) - EXPERIMENTAL  
        if disk_count >= 4:
            options.append((5, RAIDType.BTRFS_RAID6, "RAID 6 - Tolerancia a 2 fallos ⚠️ EXPERIMENTAL"))
        
        # Mostrar opciones
        for num, raid_type, description in options:
            self.console.print(f"   {num}. {description}")
        
        # Advertencia sobre RAID 5/6 experimental
        if disk_count >= 3:
            self.console.print("\n⚠️  ADVERTENCIA: RAID 5/6 en BTRFS es experimental", style="yellow")
            self.console.print("   • Puede tener problemas de estabilidad y rendimiento", style="yellow")
            self.console.print("   • No recomendado para sistemas de producción críticos", style="yellow")
        
        # Opción para volver a selección de discos
        self.console.print(f"\n   0. ← Volver a selección de discos")
        
        while True:
            choice = self.console.prompt("👉 Selecciona tipo de RAID", "2" if disk_count >= 2 else "1")
            
            if choice == "0":
                return None  # Señal para volver a selección de discos
            
            for num, raid_type, description in options:
                if choice == str(num):
                    return raid_type
            
            self.console.print("❌ Opción inválida", style="red")
    
    def _configure_raid(self, fs_type: FilesystemType, raid_type: RAIDType, disks: List[Disk]):
        """Configura el RAID con los parámetros seleccionados"""
        self.console.print("🔨 Iniciando configuración del RAID...", style="bold blue")
        
        # Verificar permisos de root - sin pedir confirmación, usar sudo directamente
        if not self.system.is_root():
            self.console.print("🔐 Se ejecutarán comandos con sudo según sea necesario", style="blue")
        
        try:
            # Paso 1: Limpieza de discos (ejecutar sin confirmaciones adicionales)
            self._clean_disks(disks)
            
            # Paso 2: Crear RAID según el tipo de filesystem
            if fs_type == FilesystemType.ZFS:
                self._create_zfs_raid(raid_type, disks)
            else:
                self._create_btrfs_raid(raid_type, disks)
            
            # Paso 3: Configurar montaje automático
            self._configure_auto_mount(fs_type, raid_type, disks)
            
            # Paso 4: Mostrar resumen final
            self._show_final_summary(fs_type, raid_type, disks)
            
        except Exception as e:
            self.console.print(f"❌ Error durante la configuración: {e}", style="red")
            self.console.print("🔄 Revirtiendo cambios...", style="yellow")
            # Aquí podríamos implementar rollback si es necesario
            raise
    
    def _calculate_raid_capacity(self, raid_type: RAIDType, disks: List[Disk]) -> Dict[str, str]:
        """Calcula la capacidad del RAID según tipo y discos"""
        if not disks:
            return {"total": "0 GB", "usable": "0 GB", "redundancy": "Ninguna"}
        
        # Encontrar disco más pequeño
        min_size = min(disk.size for disk in disks)
        total_raw = sum(disk.size for disk in disks)
        disk_count = len(disks)
        
        # Calcular según tipo de RAID
        if raid_type in [RAIDType.STRIPE, RAIDType.BTRFS_RAID0]:
            usable_size = total_raw
            redundancy = "Ninguna - Sin tolerancia a fallos"
            efficiency = "100%"
            
        elif raid_type in [RAIDType.MIRROR, RAIDType.BTRFS_RAID1]:
            usable_size = min_size * (disk_count // 2)
            redundancy = f"Tolerancia a {disk_count // 2} fallos"
            efficiency = f"{((disk_count // 2) / disk_count) * 100:.1f}%"
            
        elif raid_type == RAIDType.RAIDZ1:
            usable_size = min_size * (disk_count - 1)
            redundancy = "Tolerancia a 1 fallo"
            efficiency = f"{((disk_count - 1) / disk_count) * 100:.1f}%"
            
        elif raid_type == RAIDType.RAIDZ2:
            usable_size = min_size * (disk_count - 2)
            redundancy = "Tolerancia a 2 fallos"
            efficiency = f"{((disk_count - 2) / disk_count) * 100:.1f}%"
            
        elif raid_type == RAIDType.RAIDZ3:
            usable_size = min_size * (disk_count - 3)
            redundancy = "Tolerancia a 3 fallos"
            efficiency = f"{((disk_count - 3) / disk_count) * 100:.1f}%"
            
        elif raid_type == RAIDType.BTRFS_RAID10:
            usable_size = min_size * (disk_count // 2)
            redundancy = "Tolerancia múltiple (RAID 0+1)"
            efficiency = "50%"
            
        elif raid_type == RAIDType.BTRFS_RAID5:
            usable_size = min_size * (disk_count - 1)
            redundancy = "Tolerancia a 1 fallo (EXPERIMENTAL)"
            efficiency = f"{((disk_count - 1) / disk_count) * 100:.1f}%"
            
        elif raid_type == RAIDType.BTRFS_RAID6:
            usable_size = min_size * (disk_count - 2)
            redundancy = "Tolerancia a 2 fallos (EXPERIMENTAL)"
            efficiency = f"{((disk_count - 2) / disk_count) * 100:.1f}%"
            
        else:
            usable_size = total_raw
            redundancy = "Desconocida"
            efficiency = "N/A"
        
        # Convertir a formato legible
        def size_to_human(size_bytes: int) -> str:
            for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
                if size_bytes < 1024:
                    return f"{size_bytes:.1f} {unit}"
                size_bytes /= 1024
            return f"{size_bytes:.1f} PB"
        
        return {
            "total": size_to_human(total_raw),
            "usable": size_to_human(usable_size),
            "redundancy": redundancy,
            "efficiency": efficiency,
            "min_disk": size_to_human(min_size)
        }
    
    def _show_raid_summary(self, fs_type: FilesystemType, raid_type: RAIDType, 
                          disks: List[Disk], capacity_info: Dict[str, str]):
        """Muestra resumen de la configuración RAID"""
        if RICH_AVAILABLE:
            # Crear tabla de resumen
            summary_table = Table(title="📋 Resumen de Configuración RAID", show_header=False)
            summary_table.add_column("Concepto", style="bold cyan", width=20)
            summary_table.add_column("Valor", style="white")
            
            summary_table.add_row("Filesystem", fs_type.value.upper())
            summary_table.add_row("Tipo RAID", raid_type.value)
            summary_table.add_row("Número de discos", str(len(disks)))
            summary_table.add_row("Capacidad total", capacity_info["total"])
            summary_table.add_row("Capacidad utilizable", capacity_info["usable"])
            summary_table.add_row("Eficiencia", capacity_info["efficiency"])
            summary_table.add_row("Redundancia", capacity_info["redundancy"])
            
            self.console.console.print(summary_table)
            
            # Crear tabla de discos
            disks_table = Table(title="💾 Discos Seleccionados", show_header=True)
            disks_table.add_column("Disco", style="cyan")
            disks_table.add_column("Tamaño", style="green")
            disks_table.add_column("Modelo", style="yellow")
            disks_table.add_column("Sectores", style="blue")
            
            for disk in disks:
                disks_table.add_row(
                    disk.name,
                    disk.size_human,
                    disk.model,
                    str(disk.sector_size)
                )
            
            self.console.console.print(disks_table)
            
        else:
            print("\n📋 Resumen de Configuración RAID:")
            print(f"   Filesystem: {fs_type.value.upper()}")
            print(f"   Tipo RAID: {raid_type.value}")
            print(f"   Discos: {len(disks)}")
            print(f"   Capacidad total: {capacity_info['total']}")
            print(f"   Capacidad utilizable: {capacity_info['usable']}")
            print(f"   Redundancia: {capacity_info['redundancy']}")
            
            print("\n💾 Discos seleccionados:")
            for disk in disks:
                print(f"   • {disk.name} - {disk.size_human} - {disk.model}")
        
        # Advertencias específicas
        warnings = []
        
        if raid_type in [RAIDType.STRIPE, RAIDType.BTRFS_RAID0]:
            warnings.append("⚠️  Sin redundancia: la pérdida de cualquier disco significa pérdida total de datos")
        
        if fs_type == FilesystemType.BTRFS and "raid" in raid_type.value:
            warnings.append("⚠️  BTRFS RAID puede requerir configuración adicional después de la creación")
        
        if raid_type in [RAIDType.BTRFS_RAID5, RAIDType.BTRFS_RAID6]:
            warnings.append("🚨 RAID 5/6 en BTRFS es EXPERIMENTAL - no recomendado para producción")
            warnings.append("⚠️  Riesgo de corrupción de datos durante reconstrucción en RAID 5/6")
        
        # Verificar si los discos tienen tamaños muy diferentes
        sizes = [disk.size for disk in disks]
        if max(sizes) > min(sizes) * 1.5:  # Si hay más de 50% de diferencia
            warnings.append("⚠️  Los discos tienen tamaños muy diferentes - se usará el tamaño del más pequeño")
        
        if warnings:
            self.console.print("\n🚨 Advertencias importantes:")
            for warning in warnings:
                self.console.print(f"   {warning}", style="yellow")
    
    def _clean_disks(self, disks: List[Disk]):
        """Limpia los discos antes de crear el RAID"""
        self.console.print_panel("Analizando y limpiando discos seleccionados", title="🧹 Preparación")
        
        for disk in disks:
            self.console.print(f"🔍 Analizando disco {disk.name}...")
            
            try:
                # 1. Detectar qué tipo de configuración tiene el disco
                disk_info = self._analyze_disk_configuration(disk.name)
                
                # 2. Mostrar información encontrada automáticamente
                if disk_info['has_data']:
                    self.console.print(f"   📋 Configuración detectada en {disk.name}:")
                    for info in disk_info['details']:
                        self.console.print(f"      • {info}")
                    
                    # 3. Limpiar automáticamente sin preguntar (como el script bash)
                    self.console.print(f"   🧹 Procediendo con limpieza automática...")
                    self._perform_disk_cleanup(disk.name, disk_info)
                else:
                    self.console.print(f"   ✅ Disco {disk.name} está limpio")
                
                self.console.print(f"✅ Disco {disk.name} preparado correctamente", style="green")
                
            except Exception as e:
                self.console.print(f"⚠️  Advertencia preparando disco {disk.name}: {e}", style="yellow")
                # Continuar con el siguiente disco en lugar de fallar completamente
                self.console.print(f"   🔄 Continuando con limpieza básica...", style="blue")
                try:
                    self._wipe_disk_completely(disk.name)
                    self.console.print(f"✅ Limpieza básica completada para {disk.name}", style="green")
                except Exception as e2:
                    self.console.print(f"❌ Error crítico con disco {disk.name}: {e2}", style="red")
                    raise
    
    def _analyze_disk_configuration(self, disk_name: str) -> Dict:
        """Analiza la configuración actual de un disco"""
        info = {
            'has_data': False,
            'details': [],
            'zfs_pools': [],
            'btrfs_filesystems': [],
            'mdadm_arrays': [],
            'lvm_volumes': [],
            'mounted_partitions': [],
            'partitions': []
        }
        
        device_path = f"/dev/{disk_name}"
        
        # 1. Verificar particiones
        try:
            result = self.system.run_command(['lsblk', '-n', '-o', 'NAME,MOUNTPOINT,FSTYPE', device_path])
            for line in result.stdout.strip().split('\n'):
                if line.strip():
                    parts = line.split()
                    if len(parts) >= 1:
                        part_name = parts[0].strip()
                        mountpoint = parts[1].strip() if len(parts) > 1 and parts[1] != '' else None
                        fstype = parts[2].strip() if len(parts) > 2 and parts[2] != '' else None
                        
                        if part_name != disk_name:  # Es una partición
                            info['partitions'].append(part_name)
                            info['has_data'] = True
                            
                            if mountpoint and mountpoint != '':
                                info['mounted_partitions'].append(f"/dev/{part_name} en {mountpoint}")
                                info['details'].append(f"Partición {part_name} montada en {mountpoint}")
                            elif fstype:
                                info['details'].append(f"Partición {part_name} con filesystem {fstype}")
                            else:
                                info['details'].append(f"Partición {part_name}")
        except subprocess.CalledProcessError:
            pass
        
        # 2. Verificar si forma parte de pools ZFS
        try:
            self.system.run_command(['which', 'zpool'])
            result = self.system.run_command(['zpool', 'status'])
            
            current_pool = None
            for line in result.stdout.split('\n'):
                line = line.strip()
                if line.startswith('pool:'):
                    current_pool = line.split('pool:')[1].strip()
                elif current_pool and (disk_name in line or any(f"{disk_name}p{i}" in line for i in range(1, 10))):
                    if current_pool not in info['zfs_pools']:
                        info['zfs_pools'].append(current_pool)
                        info['has_data'] = True
                        info['details'].append(f"Miembro del pool ZFS '{current_pool}'")
        except subprocess.CalledProcessError:
            pass
        
        # 3. Verificar si forma parte de filesystems BTRFS
        try:
            self.system.run_command(['which', 'btrfs'])
            result = self.system.run_command(['btrfs', 'filesystem', 'show'])
            
            current_uuid = None
            current_label = None
            for line in result.stdout.split('\n'):
                if 'uuid:' in line:
                    current_uuid = line.split('uuid:')[1].strip()
                    current_label = None
                elif 'Label:' in line:
                    current_label = line.split('Label:')[1].strip().replace("'", "")
                elif 'devid' in line and device_path in line:
                    fs_name = current_label if current_label else f"UUID {current_uuid[:8]}..."
                    info['btrfs_filesystems'].append(fs_name)
                    info['has_data'] = True
                    info['details'].append(f"Miembro del filesystem BTRFS '{fs_name}'")
        except subprocess.CalledProcessError:
            pass
        
        # 4. Verificar arrays MDADM
        try:
            result = self.system.run_command(['cat', '/proc/mdstat'])
            for line in result.stdout.split('\n'):
                if 'active' in line and disk_name in line:
                    # Extraer nombre del array
                    array_name = line.split(':')[0].strip()
                    info['mdadm_arrays'].append(array_name)
                    info['has_data'] = True
                    info['details'].append(f"Miembro del array MDADM '{array_name}'")
        except subprocess.CalledProcessError:
            pass
        
        # 5. Verificar Volume Groups LVM
        try:
            self.system.run_command(['which', 'pvs'])
            result = self.system.run_command(['pvs', '--noheadings', '-o', 'pv_name,vg_name'])
            for line in result.stdout.strip().split('\n'):
                if line.strip() and device_path in line:
                    parts = line.split()
                    if len(parts) >= 2:
                        vg_name = parts[1]
                        info['lvm_volumes'].append(vg_name)
                        info['has_data'] = True
                        info['details'].append(f"Physical Volume en VG '{vg_name}'")
        except subprocess.CalledProcessError:
            pass
        
        return info
    
    def _perform_disk_cleanup(self, disk_name: str, disk_info: Dict):
        """Realiza la limpieza del disco según la configuración detectada"""
        if not disk_info['has_data']:
            self.console.print(f"   ✅ Disco {disk_name} ya está limpio")
            return
        
        # 1. Desmontar particiones montadas
        if disk_info['mounted_partitions']:
            self.console.print(f"   📤 Desmontando particiones...")
            for partition_info in disk_info['mounted_partitions']:
                partition = partition_info.split(' en ')[0]  # Extraer solo el dispositivo
                self.console.print(f"      • Desmontando {partition}")
                
                # Intentar desmontaje normal
                if not self.system.run_command_safe(['umount', partition]):
                    # Intentar desmontaje forzado
                    if self.system.run_command_safe(['umount', '-f', partition]):
                        self.console.print(f"      ✅ Desmontado forzadamente {partition}")
                    else:
                        self.console.print(f"      ⚠️  No se pudo desmontar {partition}, continuando...")
                else:
                    self.console.print(f"      ✅ Desmontado {partition}")
        
        # 2. Destruir pools ZFS
        if disk_info['zfs_pools']:
            self.console.print(f"   🔷 Destruyendo pools ZFS...")
            for pool in disk_info['zfs_pools']:
                self.console.print(f"      • Destruyendo pool {pool}")
                
                # Exportar pool primero (sin falla si ya está exportado)
                self.system.run_command_safe(['zpool', 'export', pool])
                
                # Destruir pool con fuerza
                if self.system.run_command_safe(['zpool', 'destroy', '-f', pool]):
                    self.console.print(f"      ✅ Pool {pool} destruido")
                else:
                    self.console.print(f"      ⚠️  Error destruyendo pool {pool}, continuando...")
        
        # 3. Limpiar filesystems BTRFS (desmontaje automático)
        if disk_info['btrfs_filesystems']:
            self.console.print(f"   🌿 Limpiando filesystems BTRFS...")
            device_path = f"/dev/{disk_name}"
            try:
                # Buscar y desmontar puntos de montaje BTRFS
                result = self.system.run_command(['findmnt', '-t', 'btrfs', '-n', '-o', 'TARGET,SOURCE'], check=False)
                if result.returncode == 0:
                    for line in result.stdout.strip().split('\n'):
                        if line.strip() and device_path in line:
                            mountpoint = line.split()[0]
                            if self.system.run_command_safe(['umount', mountpoint]):
                                self.console.print(f"      ✅ Desmontado BTRFS en {mountpoint}")
                            elif self.system.run_command_safe(['umount', '-f', mountpoint]):
                                self.console.print(f"      ✅ Desmontado BTRFS forzadamente en {mountpoint}")
                            else:
                                self.console.print(f"      ⚠️  No se pudo desmontar {mountpoint}")
            except subprocess.CalledProcessError:
                pass  # No hay filesystems BTRFS montados
        
        # 4. Parar arrays MDADM
        if disk_info['mdadm_arrays']:
            self.console.print(f"   ⚡ Parando arrays MDADM...")
            for array in disk_info['mdadm_arrays']:
                self.console.print(f"      • Parando array {array}")
                if self.system.run_command_safe(['mdadm', '--stop', f"/dev/{array}"]):
                    self.console.print(f"      ✅ Array {array} parado")
                else:
                    self.console.print(f"      ⚠️  Error parando array {array}, continuando...")
        
        # 5. Remover de Volume Groups LVM
        if disk_info['lvm_volumes']:
            self.console.print(f"   💼 Removiendo de Volume Groups LVM...")
            device_path = f"/dev/{disk_name}"
            for vg in disk_info['lvm_volumes']:
                # Desactivar VG primero
                self.system.run_command_safe(['vgchange', '-an', vg])
                
                # Remover PV del VG
                self.system.run_command_safe(['vgreduce', vg, device_path])
                
                # Remover PV completamente con fuerza
                if self.system.run_command_safe(['pvremove', '-ff', device_path]):
                    self.console.print(f"      ✅ PV removido del VG {vg}")
                else:
                    self.console.print(f"      ⚠️  Error removiendo PV de {vg}, continuando...")
        
        # 6. Limpiar completamente el disco
        self.console.print(f"   🧽 Limpiando todos los metadatos...")
        self._wipe_disk_completely(disk_name)
    
    def _wipe_disk_completely(self, disk_name: str):
        """Limpia completamente un disco de todos los metadatos"""
        device_path = f"/dev/{disk_name}"
        
        # 1. Limpiar etiquetas ZFS si es posible
        try:
            self.system.run_command(['which', 'zpool'], check=False)
            if self.system.run_command_safe(['zpool', 'labelclear', '-f', device_path]):
                self.console.print(f"      ✅ Etiquetas ZFS limpiadas")
        except subprocess.CalledProcessError:
            pass  # ZFS no disponible
        
        # 2. Limpiar metadatos MDADM
        if self.system.run_command_safe(['mdadm', '--zero-superblock', device_path]):
            self.console.print(f"      ✅ Metadatos MDADM limpiados")
        
        # 3. Usar wipefs para limpiar todas las firmas de filesystem
        self.console.print(f"      • Limpiando firmas de filesystem...")
        if self.system.run_command_safe(['wipefs', '-af', device_path]):
            self.console.print(f"      ✅ Firmas de filesystem limpiadas")
        else:
            self.console.print(f"      ⚠️  Error con wipefs, usando método alternativo...")
        
        # 4. Limpiar primeros sectores con dd (como en script bash)
        self.console.print(f"      • Limpiando primeros 100MB...")
        if self.system.run_command_safe(['dd', 'if=/dev/zero', f'of={device_path}', 'bs=1M', 'count=100', 'conv=fsync']):
            self.console.print(f"      ✅ Primeros sectores limpiados")
        else:
            self.console.print(f"      ⚠️  Error limpiando primeros sectores")
        
        # 5. Limpiar últimos sectores (metadatos al final del disco)
        try:
            self.console.print(f"      • Limpiando últimos sectores...")
            # Obtener tamaño del disco en bytes
            result = self.system.run_command(['lsblk', '-dpno', 'SIZE', device_path, '--bytes'], check=False)
            if result.returncode == 0:
                disk_size = int(result.stdout.strip())
                
                if disk_size > 104857600:  # Mayor a 100MB
                    seek_mb = (disk_size // 1048576) - 100  # 100MB antes del final
                    if self.system.run_command_safe(['dd', 'if=/dev/zero', f'of={device_path}', 
                                                   'bs=1M', f'seek={seek_mb}', 'count=100', 'conv=fsync']):
                        self.console.print(f"      ✅ Últimos sectores limpiados")
                    else:
                        self.console.print(f"      ⚠️  Error limpiando últimos sectores")
        except (subprocess.CalledProcessError, ValueError):
            self.console.print(f"      ⚠️  Error obteniendo tamaño del disco")
        
        # 6. Limpiar tabla de particiones con sgdisk si está disponible
        if self.system.run_command_safe(['sgdisk', '--zap-all', device_path]):
            self.console.print(f"      ✅ Tabla de particiones GPT limpiada")
        else:
            # sgdisk no disponible, usar dd básico para MBR
            if self.system.run_command_safe(['dd', 'if=/dev/zero', f'of={device_path}', 'bs=512', 'count=1', 'conv=fsync']):
                self.console.print(f"      ✅ Tabla de particiones MBR limpiada")
        
        # 7. Informar al kernel sobre los cambios y esperar
        self.system.run_command_safe(['partprobe', device_path])
        self.system.run_command_safe(['udevadm', 'settle'])
        
        # 8. Esperar como en el script bash
        import time
        time.sleep(3)
    
    def _unmount_disk(self, disk_name: str):
        """Desmonta todas las particiones de un disco"""
        try:
            # Obtener particiones montadas
            result = self.system.run_command(['mount'])
            mounted_partitions = []
            
            for line in result.stdout.split('\n'):
                if f'/dev/{disk_name}' in line:
                    parts = line.split()
                    if len(parts) > 0:
                        mounted_partitions.append(parts[0])
            
            # Desmontar cada partición
            for partition in mounted_partitions:
                self.console.print(f"   📤 Desmontando {partition}...")
                try:
                    self.system.run_command(['umount', partition])
                except subprocess.CalledProcessError:
                    # Forzar desmontaje si es necesario
                    try:
                        self.system.run_command(['umount', '-f', partition])
                    except subprocess.CalledProcessError:
                        self.console.print(f"   ⚠️  No se pudo desmontar {partition}", style="yellow")
                        
        except subprocess.CalledProcessError:
            pass  # No hay problema si no hay particiones montadas
    
    def _destroy_zfs_pools_using_disk(self, disk_name: str):
        """Destruye pools ZFS que usen el disco especificado"""
        try:
            # Verificar si ZFS está disponible
            self.system.run_command(['which', 'zpool'])
            
            # Obtener lista de pools
            result = self.system.run_command(['zpool', 'list', '-H', '-o', 'name'])
            pools = [line.strip() for line in result.stdout.strip().split('\n') if line.strip()]
            
            pools_to_destroy = []
            
            for pool in pools:
                try:
                    # Verificar si el disco está en el pool
                    status_result = self.system.run_command(['zpool', 'status', pool])
                    
                    # Buscar el disco en la salida del status
                    for line in status_result.stdout.split('\n'):
                        if disk_name in line and ('/dev/' in line or line.strip().startswith(disk_name)):
                            pools_to_destroy.append(pool)
                            break
                            
                except subprocess.CalledProcessError:
                    continue
            
            # Destruir pools que usen este disco
            for pool in pools_to_destroy:
                self.console.print(f"   🗑️  Destruyendo pool ZFS: {pool}")
                if self.console.confirm(f"¿Confirmar destrucción del pool '{pool}'?", default=False):
                    try:
                        # Primero intentar exportar el pool
                        try:
                            self.system.run_command(['zpool', 'export', pool])
                            self.console.print(f"   📤 Pool {pool} exportado", style="blue")
                        except subprocess.CalledProcessError:
                            self.console.print(f"   ⚠️  No se pudo exportar {pool}, forzando destrucción", style="yellow")
                        
                        # Luego destruir
                        self.system.run_command(['zpool', 'destroy', '-f', pool])
                        self.console.print(f"   ✅ Pool {pool} destruido", style="green")
                        
                    except subprocess.CalledProcessError as e:
                        # Intentar forzar la destrucción más agresivamente
                        self.console.print(f"   ⚠️  Error destruyendo {pool}, intentando limpieza forzada", style="yellow")
                        try:
                            # Forzar unmount y destruir
                            self.system.run_command(['zfs', 'unmount', '-f', pool])
                            self.system.run_command(['zpool', 'destroy', '-f', pool])
                            self.console.print(f"   ✅ Pool {pool} destruido (forzado)", style="green")
                        except subprocess.CalledProcessError:
                            self.console.print(f"   ❌ No se pudo destruir el pool {pool}. Continúa con limpieza manual.", style="red")
                            self.console.print(f"   💡 Comando manual: sudo zpool destroy -f {pool}", style="blue")
                else:
                    self.console.print("❌ Operación cancelada por el usuario", style="red")
                    raise Exception("Operación cancelada")
                    
        except subprocess.CalledProcessError:
            # ZFS no disponible, continuar
            pass
    
    def _wipe_disk_metadata(self, disk_name: str):
        """Limpia todos los metadatos del disco"""
        self.console.print(f"   🧽 Limpiando metadatos de /dev/{disk_name}...")
        
        try:
            # Primero intentar con dd para limpiar los primeros sectores
            try:
                self.system.run_command(['dd', 'if=/dev/zero', f'of=/dev/{disk_name}', 'bs=1M', 'count=100'])
                self.console.print(f"   ✨ Primeros sectores limpiados con dd", style="blue")
            except subprocess.CalledProcessError:
                self.console.print(f"   ⚠️  No se pudieron limpiar sectores con dd", style="yellow")
            
            # Usar wipefs para limpiar metadatos
            try:
                self.system.run_command(['wipefs', '-af', f'/dev/{disk_name}'])
                self.console.print(f"   ✨ Metadatos limpiados con wipefs", style="green")
            except subprocess.CalledProcessError:
                self.console.print(f"   ⚠️  wipefs falló, intentando limpieza manual", style="yellow")
                
                # Intentar limpiar manualmente con dd
                try:
                    # Limpiar el principio del disco
                    self.system.run_command(['dd', 'if=/dev/zero', f'of=/dev/{disk_name}', 'bs=512', 'count=2048'])
                    
                    # Obtener tamaño del disco y limpiar el final
                    result = self.system.run_command(['blockdev', '--getsz', f'/dev/{disk_name}'])
                    sectors = int(result.stdout.strip())
                    end_sector = sectors - 2048
                    
                    self.system.run_command(['dd', 'if=/dev/zero', f'of=/dev/{disk_name}', 
                                           f'seek={end_sector}', 'bs=512', 'count=2048'])
                    
                    self.console.print(f"   ✨ Limpieza manual completada", style="green")
                    
                except subprocess.CalledProcessError as e:
                    self.console.print(f"   ❌ Error en limpieza manual: {e}", style="red")
                    # Continuar de todas formas
            
            # Limpiar también particiones existentes si existen
            try:
                result = self.system.run_command(['lsblk', '-ln', '-o', 'NAME', f'/dev/{disk_name}'])
                partitions = result.stdout.strip().split('\n')[1:]  # Skip el disco principal
                
                for partition in partitions:
                    if partition.strip():
                        partition_name = partition.strip()
                        try:
                            self.system.run_command(['wipefs', '-af', f'/dev/{partition_name}'])
                            self.console.print(f"   ✨ Partición {partition_name} limpiada", style="blue")
                        except subprocess.CalledProcessError:
                            self.console.print(f"   ⚠️  No se pudo limpiar partición {partition_name}", style="yellow")
                            
            except subprocess.CalledProcessError:
                pass  # No hay particiones para limpiar
                
            # Notificar al kernel sobre los cambios
            try:
                self.system.run_command(['partprobe', f'/dev/{disk_name}'])
                self.console.print(f"   🔄 Kernel notificado de cambios", style="blue")
            except subprocess.CalledProcessError:
                pass
                
            self.console.print(f"   ✅ Disco /dev/{disk_name} preparado", style="green")
            
        except Exception as e:
            self.console.print(f"   ⚠️  Algunos errores durante la limpieza, pero continuando: {e}", style="yellow")
            # No lanzar excepción, continuar con el proceso
    
    def _create_zfs_raid(self, raid_type: RAIDType, disks: List[Disk]):
        """Crea un RAID ZFS"""
        self.console.print_panel("Configurando ZFS RAID", title="🔷 ZFS")
        
        # Verificar que ZFS esté disponible
        try:
            self.system.run_command(['which', 'zpool'])
        except subprocess.CalledProcessError:
            self.console.print("❌ ZFS no está disponible en el sistema", style="red")
            raise Exception("ZFS no disponible")
        
        # Cargar módulo ZFS si no está cargado
        self._ensure_zfs_module_loaded()
        
        # Obtener configuración del usuario
        pool_name = self._get_zfs_pool_name()
        
        # Configurar ARC (cache)
        arc_size = self._configure_zfs_arc()
        
        # Detectar ashift óptimo
        ashift = self._detect_optimal_ashift(disks)
        
        # Crear pool ZFS (SIN punto de montaje específico - ZFS lo maneja automáticamente)
        self._create_zfs_pool(pool_name, raid_type, disks, ashift)
        
        # Configurar propiedades del pool
        self._configure_zfs_properties(pool_name, arc_size)
        
        self.console.print(f"✅ Pool ZFS '{pool_name}' creado exitosamente", style="green")
        
        # Configurar cache devices (SLOG/L2ARC) si hay dispositivos NVMe/SSD disponibles
        self._configure_cache_devices(pool_name, disks)
        
    def _ensure_zfs_module_loaded(self):
        """Asegura que el módulo ZFS esté cargado"""
        try:
            result = self.system.run_command(['lsmod'])
            if 'zfs' not in result.stdout:
                self.console.print("📦 Cargando módulo ZFS...")
                self.system.run_command(['modprobe', 'zfs'])
                
                # Esperar un poco y verificar
                import time
                time.sleep(2)
                
                result = self.system.run_command(['lsmod'])
                if 'zfs' not in result.stdout:
                    raise Exception("No se pudo cargar el módulo ZFS")
                    
                self.console.print("✅ Módulo ZFS cargado", style="green")
                
        except subprocess.CalledProcessError as e:
            self.console.print(f"❌ Error cargando módulo ZFS: {e}", style="red")
            raise
    
    def _get_zfs_pool_name(self) -> str:
        """Obtiene el nombre del pool ZFS del usuario"""
        while True:
            pool_name = self.console.prompt("📝 Nombre del pool ZFS", "storage").strip()
            
            if not pool_name:
                self.console.print("❌ El nombre no puede estar vacío", style="red")
                continue
                
            # Verificar que el nombre sea válido
            if not pool_name.replace('_', '').replace('-', '').isalnum():
                self.console.print("❌ El nombre solo puede contener letras, números, _ y -", style="red")
                continue
                
            # Verificar que no exista ya
            try:
                result = self.system.run_command(['zpool', 'list', pool_name])
                self.console.print(f"❌ El pool '{pool_name}' ya existe", style="red")
                continue
            except subprocess.CalledProcessError:
                # Pool no existe, perfecto
                return pool_name
    
    def _get_mount_point(self, default_path: str) -> str:
        """Obtiene el punto de montaje del usuario"""
        mount_point = self.console.prompt("📁 Punto de montaje", default_path).strip()
        
        if not mount_point.startswith('/'):
            mount_point = f"/{mount_point}"
            
        # Crear directorio si no existe
        if not os.path.exists(mount_point):
            if self.console.confirm(f"El directorio {mount_point} no existe. ¿Crearlo?", default=True):
                try:
                    # Intentar crear sin sudo primero
                    os.makedirs(mount_point, exist_ok=True)
                    self.console.print(f"✅ Directorio {mount_point} creado", style="green")
                except OSError:
                    # Si falla, usar sudo automáticamente
                    try:
                        self.console.print(f"🔐 Creando directorio con permisos elevados...")
                        # SystemManager ahora maneja sudo automáticamente
                        self.system.run_command(['mkdir', '-p', mount_point])
                        self.console.print(f"✅ Directorio {mount_point} creado", style="green")
                    except subprocess.CalledProcessError as e:
                        self.console.print(f"❌ Error creando directorio: {e}", style="red")
                        raise Exception(f"No se pudo crear el directorio {mount_point}")
            else:
                raise Exception("Se necesita un punto de montaje válido")
                
        return mount_point
    
    def _configure_zfs_arc(self) -> int:
        """Configura el tamaño del ARC de ZFS"""
        try:
            # Obtener RAM del sistema
            with open('/proc/meminfo', 'r') as f:
                for line in f:
                    if line.startswith('MemTotal:'):
                        ram_kb = int(line.split()[1])
                        ram_gb = ram_kb // (1024 * 1024)
                        break
            
            # Calcular ARC recomendado (25% de RAM)
            recommended_arc = max(1, ram_gb // 4)
            
            self.console.print(f"💾 RAM del sistema: {ram_gb}GB")
            self.console.print(f"📊 ARC recomendado: {recommended_arc}GB")
            
            while True:
                arc_input = self.console.prompt(f"🎯 Tamaño del ARC en GB", str(recommended_arc)).strip()
                try:
                    arc_size = int(arc_input)
                    if arc_size < 1:
                        self.console.print("❌ El ARC debe ser al menos 1GB", style="red")
                        continue
                    if arc_size > ram_gb:
                        self.console.print(f"❌ El ARC no puede ser mayor que la RAM ({ram_gb}GB)", style="red")
                        continue
                    return arc_size
                except ValueError:
                    self.console.print("❌ Ingresa un número válido", style="red")
                    
        except Exception as e:
            self.console.print(f"⚠️  Error detectando RAM, usando 1GB para ARC: {e}", style="yellow")
            return 1
    
    def _detect_optimal_ashift(self, disks: List[Disk]) -> int:
        """Detecta el ashift óptimo para ZFS"""
        max_sector_size = 512
        has_4k_sectors = False
        
        for disk in disks:
            if disk.sector_size > max_sector_size:
                max_sector_size = disk.sector_size
            if disk.sector_size == 4096:
                has_4k_sectors = True
        
        # Estrategia de ashift optimizada para compatibilidad
        if max_sector_size <= 512 and not has_4k_sectors:
            ashift = 12  # Compatibilidad con cache devices SSD
            self.console.print("🔧 Usando ashift=12 para compatibilidad con cache devices", style="blue")
        else:
            # Calcular ashift basado en el tamaño de sector
            import math
            ashift = int(math.log2(max_sector_size)) if max_sector_size >= 512 else 12
            if ashift < 9:
                ashift = 12  # Mínimo seguro
            self.console.print(f"🔧 Ashift detectado: {ashift} (sector size: {max_sector_size})", style="blue")
        
        return ashift
    
    def _create_zfs_pool(self, pool_name: str, raid_type: RAIDType, disks: List[Disk], ashift: int):
        """Crea el pool ZFS con configuración automática de montaje"""
        self.console.print(f"🔨 Creando pool ZFS '{pool_name}'...")
        
        # Preguntar sobre mountpoint (opcional)
        use_custom_mountpoint = self.console.confirm(
            "¿Configurar punto de montaje personalizado? (No recomendado - ZFS lo maneja automáticamente)", 
            default=False
        )
        
        # Construir comando base
        cmd = ['zpool', 'create', '-f', '-o', f'ashift={ashift}']
        
        # Configurar mountpoint
        if use_custom_mountpoint:
            custom_mount = self.console.prompt("📁 Punto de montaje personalizado", f"/{pool_name}")
            cmd.extend(['-m', custom_mount])
            self.console.print(f"📁 Usando punto de montaje personalizado: {custom_mount}")
        else:
            # Dejar que ZFS maneje automáticamente (mountpoint por defecto será /{pool_name})
            self.console.print(f"📁 ZFS configurará automáticamente el montaje en: /{pool_name}")
        
        # Añadir nombre del pool
        cmd.append(pool_name)
        
        # Añadir configuración RAID
        if raid_type == RAIDType.STRIPE:
            # Stripe: solo añadir los discos directamente
            pass
        elif raid_type == RAIDType.MIRROR:
            cmd.append('mirror')
        elif raid_type == RAIDType.RAIDZ1:
            cmd.append('raidz1')
        elif raid_type == RAIDType.RAIDZ2:
            cmd.append('raidz2')
        elif raid_type == RAIDType.RAIDZ3:
            cmd.append('raidz3')
        
        # Añadir discos
        for disk in disks:
            cmd.append(f'/dev/{disk.name}')
        
        try:
            self.console.print(f"📝 Ejecutando: {' '.join(cmd)}")
            self.system.run_command(cmd)
            self.console.print(f"✅ Pool '{pool_name}' creado exitosamente", style="green")
            
            # Mostrar información del pool creado
            self._show_created_pool_info(pool_name)
            
        except subprocess.CalledProcessError as e:
            self.console.print(f"❌ Error creando pool: {e}", style="red")
            raise
    
    def _show_created_pool_info(self, pool_name: str):
        """Muestra información del pool recién creado"""
        try:
            # Obtener información básica del pool
            result = self.system.run_command(['zfs', 'get', 'mounted,mountpoint', pool_name])
            self.console.print(f"\n📋 Información del pool '{pool_name}':")
            
            for line in result.stdout.strip().split('\n')[1:]:  # Skip header
                if line.strip():
                    parts = line.split()
                    if len(parts) >= 4:
                        property_name = parts[1]
                        value = parts[2]
                        if property_name == 'mountpoint':
                            self.console.print(f"   📁 Punto de montaje: {value}")
                        elif property_name == 'mounted':
                            mounted_status = "✅ Montado" if value == 'yes' else "❌ No montado"
                            self.console.print(f"   🔗 Estado: {mounted_status}")
            
            # Mostrar comando útil
            self.console.print(f"\n💡 Comandos útiles:")
            self.console.print(f"   • Ver estado: zpool status {pool_name}")
            self.console.print(f"   • Ver propiedades: zfs get all {pool_name}")
            self.console.print(f"   • Crear dataset: zfs create {pool_name}/mi_dataset")
            
        except subprocess.CalledProcessError:
            self.console.print("   ⚠️  No se pudo obtener información adicional del pool", style="yellow")
    
    def _configure_zfs_properties(self, pool_name: str, arc_size: int):
        """Configura propiedades optimizadas del pool ZFS"""
        self.console.print("⚙️  Configurando propiedades optimizadas del pool...", style="blue")
        
        # Propiedades básicas de rendimiento
        basic_properties = [
            ('compression', 'lz4', 'Compresión LZ4 (rápida y eficiente)'),
            ('atime', 'off', 'Desactivar atime para mejor rendimiento'),
            ('relatime', 'on', 'Activar relatime (compromiso rendimiento/compatibilidad)'),
            ('xattr', 'sa', 'Atributos extendidos en system attributes'),
            ('recordsize', '128K', 'Tamaño de registro optimizado para uso general'),
            ('logbias', 'latency', 'Optimizar para latencia en lugar de throughput'),
            ('sync', 'standard', 'Comportamiento de sync estándar'),
            ('dedup', 'off', 'Desactivar deduplicación (consume mucha RAM)'),
            ('dnodesize', 'auto', 'Tamaño de dnode automático')
        ]
        
        # Aplicar propiedades básicas
        for prop, value, description in basic_properties:
            if self._set_zfs_property(pool_name, prop, value):
                self.console.print(f"   ✅ {description}")
            else:
                self.console.print(f"   ⚠️  {description} - no aplicada", style="yellow")
        
        # Configuraciones específicas según el tipo de uso
        self.console.print("\n🎯 Configuraciones específicas por tipo de uso:")
        
        # Preguntar tipo de uso previsto
        use_case = self._get_zfs_use_case()
        
        if use_case == "storage":
            self._configure_zfs_for_storage(pool_name)
        elif use_case == "database":
            self._configure_zfs_for_database(pool_name)
        elif use_case == "media":
            self._configure_zfs_for_media(pool_name)
        elif use_case == "mixed":
            self._configure_zfs_for_mixed(pool_name)
        
        # Configurar ARC del sistema
        self._configure_zfs_arc_system(arc_size)
        
        # Configuraciones adicionales de pool
        self._configure_zfs_advanced_properties(pool_name)
        
        # Crear datasets si el usuario lo desea
        self._create_zfs_datasets(pool_name)
        
        self.console.print("✅ Propiedades ZFS configuradas", style="green")
    
    def _set_zfs_property(self, pool_name: str, prop: str, value: str) -> bool:
        """Establece una propiedad ZFS y maneja errores"""
        try:
            self.system.run_command(['zfs', 'set', f'{prop}={value}', pool_name])
            return True
        except subprocess.CalledProcessError:
            return False
    
    def _get_zfs_use_case(self) -> str:
        """Obtiene el caso de uso previsto para el pool ZFS"""
        self.console.print("\n📊 ¿Cuál será el uso principal de este pool?")
        self.console.print("   1. Almacenamiento general (documentos, backups)")
        self.console.print("   2. Base de datos / aplicaciones")
        self.console.print("   3. Media server (vídeos, música, fotos)")
        self.console.print("   4. Uso mixto")
        
        while True:
            choice = self.console.prompt("👉 Selecciona el tipo de uso", "1")
            if choice == "1":
                return "storage"
            elif choice == "2":
                return "database"
            elif choice == "3":
                return "media"
            elif choice == "4":
                return "mixed"
            else:
                self.console.print("❌ Opción inválida", style="red")
    
    def _configure_zfs_for_storage(self, pool_name: str):
        """Configuración optimizada para almacenamiento general"""
        self.console.print("   📦 Optimizando para almacenamiento general...")
        
        storage_properties = [
            ('recordsize', '1M', 'Registros grandes para archivos grandes'),
            ('compression', 'zstd', 'Compresión alta para mejor ratio'),
            ('checksum', 'sha256', 'Checksums robustos'),
            ('redundant_metadata', 'most', 'Metadatos redundantes')
        ]
        
        for prop, value, description in storage_properties:
            if self._set_zfs_property(pool_name, prop, value):
                self.console.print(f"      ✅ {description}")
    
    def _configure_zfs_for_database(self, pool_name: str):
        """Configuración optimizada para bases de datos"""
        self.console.print("   🗄️  Optimizando para bases de datos...")
        
        db_properties = [
            ('recordsize', '8K', 'Registros pequeños para I/O de BD'),
            ('logbias', 'throughput', 'Optimizar para throughput'),
            ('sync', 'always', 'Sync inmediato para consistencia'),
            ('primarycache', 'metadata', 'Cache solo metadatos'),
            ('redundant_metadata', 'all', 'Todos los metadatos redundantes')
        ]
        
        for prop, value, description in db_properties:
            if self._set_zfs_property(pool_name, prop, value):
                self.console.print(f"      ✅ {description}")
    
    def _configure_zfs_for_media(self, pool_name: str):
        """Configuración optimizada para media server"""
        self.console.print("   🎬 Optimizando para media server...")
        
        media_properties = [
            ('recordsize', '1M', 'Registros grandes para streaming'),
            ('compression', 'lz4', 'Compresión rápida'),
            ('atime', 'off', 'Sin atime para mejor rendimiento'),
            ('logbias', 'latency', 'Baja latencia para streaming'),
            ('primarycache', 'all', 'Cache completo para acceso frecuente')
        ]
        
        for prop, value, description in media_properties:
            if self._set_zfs_property(pool_name, prop, value):
                self.console.print(f"      ✅ {description}")
    
    def _configure_zfs_for_mixed(self, pool_name: str):
        """Configuración balanceada para uso mixto"""
        self.console.print("   ⚖️  Configuración balanceada para uso mixto...")
        
        mixed_properties = [
            ('recordsize', '128K', 'Registro balanceado'),
            ('compression', 'lz4', 'Compresión eficiente'),
            ('logbias', 'latency', 'Balance latencia/throughput'),
            ('primarycache', 'all', 'Cache completo'),
            ('redundant_metadata', 'most', 'Metadatos importantes redundantes')
        ]
        
        for prop, value, description in mixed_properties:
            if self._set_zfs_property(pool_name, prop, value):
                self.console.print(f"      ✅ {description}")
    
    def _configure_zfs_arc_system(self, arc_size: int):
        """Configura el ARC del sistema ZFS"""
        self.console.print("\n💾 Configurando ZFS ARC del sistema...")
        
        try:
            # Crear directorio de configuración si no existe
            config_dir = "/etc/modprobe.d"
            if not os.path.exists(config_dir):
                if self.system.run_command_safe(['mkdir', '-p', config_dir]):
                    self.console.print(f"   ✅ Directorio {config_dir} creado")
            
            # Configurar ARC
            arc_bytes = arc_size * 1024 * 1024 * 1024
            arc_min = arc_bytes // 4  # Mínimo 25% del máximo
            
            zfs_conf_content = f"""# ZFS ARC Configuration - Configurado por raid_manager.py
# Tamaño máximo del ARC: {arc_size}GB
options zfs zfs_arc_max={arc_bytes}
# Tamaño mínimo del ARC: {arc_size//4}GB  
options zfs zfs_arc_min={arc_min}
# Configuración de L2ARC
options zfs l2arc_write_max=134217728
options zfs l2arc_headroom=4
"""
            
            # Escribir configuración usando sudo
            config_file = '/etc/modprobe.d/zfs.conf'
            temp_file = '/tmp/zfs_config.tmp'
            
            # Escribir a archivo temporal primero
            try:
                with open(temp_file, 'w') as f:
                    f.write(zfs_conf_content)
                
                # Mover archivo con sudo
                if self.system.run_command_safe(['sudo', 'cp', temp_file, config_file]):
                    self.console.print(f"   ✅ ARC máximo: {arc_size}GB")
                    self.console.print(f"   ✅ ARC mínimo: {arc_size//4}GB")
                    self.console.print("   ✅ Configuración L2ARC optimizada")
                    
                    # Limpiar archivo temporal
                    try:
                        os.remove(temp_file)
                    except:
                        pass
                        
                    # Aplicar configuración actual (si es posible)
                    try:
                        current_max = f"/sys/module/zfs/parameters/zfs_arc_max"
                        if os.path.exists(current_max):
                            # Usar echo con sudo para escribir al sistema
                            if self.system.run_command_safe(['sudo', 'bash', '-c', f'echo {arc_bytes} > {current_max}']):
                                self.console.print("   ✅ ARC aplicado inmediatamente")
                            else:
                                self.console.print("   💡 ARC se aplicará en el próximo reinicio")
                        else:
                            self.console.print("   💡 ARC se aplicará cuando se cargue el módulo ZFS")
                    except Exception:
                        self.console.print("   💡 ARC se aplicará en el próximo reinicio")
                else:
                    self.console.print("   ⚠️  No se pudo escribir configuración ARC", style="yellow")
                    self.console.print("   💡 Puedes configurar manualmente editando /etc/modprobe.d/zfs.conf", style="blue")
                    
            except Exception as e:
                self.console.print(f"   ⚠️  Error escribiendo configuración temporal: {e}", style="yellow")
                
        except Exception as e:
            self.console.print(f"   ⚠️  Error configurando ARC: {e}", style="yellow")
            self.console.print("   💡 Puedes configurar manualmente editando /etc/modprobe.d/zfs.conf", style="blue")
    
    def _configure_zfs_advanced_properties(self, pool_name: str):
        """Configuraciones avanzadas adicionales de ZFS"""
        self.console.print("\n🔧 Configuraciones avanzadas del pool...")
        
        # Solo configuraciones que aplican al pool entero
        self.console.print("   💡 Las cuotas y snapshots se configurarán por dataset individual")
        
        # Configuración de cache devices (futuro)
        self.console.print("   💡 Después puedes agregar cache devices con: zpool add <pool> cache <device>")
    
    def _create_zfs_datasets(self, pool_name: str):
        """Crea datasets ZFS según las necesidades del usuario"""
        self.console.print("\n📁 Configuración de Datasets ZFS")
        
        if not self.console.confirm("¿Crear datasets organizados?", default=True):
            return
        
        while True:
            self.console.print("\n🎯 Opciones de creación de datasets:")
            self.console.print("   1. Configuración rápida recomendada")
            self.console.print("   2. Crear datasets personalizados")
            self.console.print("   3. No crear datasets ahora")
            
            choice = self.console.prompt("👉 Selecciona opción", "1")
            
            if choice == "1":
                # Mostrar explicación y pedir confirmación
                if self._explain_recommended_setup(pool_name):
                    self._create_recommended_datasets(pool_name)
                    break  # Salir del bucle después de crear
                # Si no confirma, volver al menú de opciones
                
            elif choice == "2":
                self._create_custom_datasets(pool_name)
                break  # Salir del bucle después de crear
                
            elif choice == "3":
                self.console.print("   ⏭️  Omitiendo creación de datasets")
                break  # Salir sin crear nada
                
            else:
                self.console.print("❌ Opción inválida", style="red")
    
    def _explain_recommended_setup(self, pool_name: str):
        """Explica la configuración rápida recomendada al usuario"""
        self.console.print("\n📋 Configuración Rápida Recomendada:")
        self.console.print(f"   Se crearán 5 datasets organizados en el pool '{pool_name}':")
        
        self.console.print("\n   📁 Datasets que se crearán:")
        self.console.print("   ┌─ 📦 data/       → Datos generales del usuario")
        self.console.print("   ├─ 🎬 media/      → Videos, música, fotos (optimizado para streaming)")
        self.console.print("   ├─ 💾 backups/    → Respaldos (máxima compresión)")
        self.console.print("   ├─ 🌐 shares/     → Carpetas compartidas en red")
        self.console.print("   └─ ⚙️  apps/       → Datos de aplicaciones y servicios")
        
        self.console.print("\n   🔧 Configuraciones específicas por dataset:")
        self.console.print("   • data/    → Compresión LZ4, recordsize 128K (uso general)")
        self.console.print("   • media/   → Compresión LZ4, recordsize 1M (archivos grandes)")
        self.console.print("   • backups/ → Compresión ZSTD, recordsize 1M (máximo ratio)")
        self.console.print("   • shares/  → Compresión LZ4, recordsize 128K (red)")
        self.console.print("   • apps/    → Compresión LZ4, recordsize 64K (aplicaciones)")
        
        self.console.print("\n   📍 Puntos de montaje:")
        self.console.print(f"   • /{pool_name}/data    → Datos del usuario")
        self.console.print(f"   • /{pool_name}/media   → Biblioteca multimedia")
        self.console.print(f"   • /{pool_name}/backups → Respaldos importantes")
        self.console.print(f"   • /{pool_name}/shares  → Recursos compartidos")
        self.console.print(f"   • /{pool_name}/apps    → Datos de aplicaciones")
        
        self.console.print("\n   ✅ Beneficios de esta estructura:")
        self.console.print("   • Organización clara y escalable")
        self.console.print("   • Configuraciones optimizadas por tipo de contenido")
        self.console.print("   • Gestión independiente por dataset")
        self.console.print("   • Fácil gestión de permisos y políticas")
        
        if not self.console.confirm("\n¿Proceder con esta configuración básica?", default=True):
            self.console.print("   ❌ Configuración cancelada")
            return False
        
        return True
    
    def _create_recommended_datasets(self, pool_name: str):
        """Crea una estructura de datasets recomendada"""
        self.console.print("\n🏗️  Creando estructura de datasets recomendada...")
        
        # Preguntar sobre configuraciones adicionales una sola vez
        self.console.print("\n⚙️  Configuraciones adicionales para todos los datasets:")
        
        # Explicar qué son los snapshots antes de preguntar
        self.console.print("📸 Snapshots automáticos:")
        self.console.print("   • Crean copias de seguridad automáticas de tus datos")
        self.console.print("   • Permiten recuperar archivos borrados o versiones anteriores")
        self.console.print("   • Podrás elegir la frecuencia (diario, semanal, mensual, etc.)")
        
        enable_snapshots = self.console.confirm("¿Habilitar snapshots automáticos para los datasets?", default=True)
        enable_quotas = self.console.confirm("¿Configurar cuotas de espacio para los datasets?", default=False)
        
        # Datasets recomendados con configuraciones específicas
        recommended_datasets = [
            {
                'name': 'data',
                'description': 'Datos generales del usuario',
                'properties': {
                    'compression': 'lz4',
                    'atime': 'off',
                    'recordsize': '128K'
                },
                'suggested_quota': '500G'
            },
            {
                'name': 'media',
                'description': 'Archivos multimedia (videos, música, fotos)',
                'properties': {
                    'compression': 'lz4',
                    'atime': 'off',
                    'recordsize': '1M'
                },
                'suggested_quota': '2T'
            },
            {
                'name': 'backups',
                'description': 'Respaldos y archivos importantes',
                'properties': {
                    'compression': 'zstd',
                    'atime': 'off',
                    'recordsize': '1M'
                },
                'suggested_quota': '1T'
            },
            {
                'name': 'shares',
                'description': 'Carpetas compartidas en red',
                'properties': {
                    'compression': 'lz4',
                    'atime': 'off',
                    'recordsize': '128K'
                },
                'suggested_quota': '200G'
            },
            {
                'name': 'apps',
                'description': 'Datos de aplicaciones y servicios',
                'properties': {
                    'compression': 'lz4',
                    'atime': 'off',
                    'recordsize': '64K'
                },
                'suggested_quota': '100G'
            }
        ]
        
        created_datasets = []
        
        for dataset_config in recommended_datasets:
            dataset_full_name = f"{pool_name}/{dataset_config['name']}"
            
            try:
                # Crear dataset
                self.console.print(f"   📁 Creando dataset: {dataset_full_name}")
                self.system.run_command(['zfs', 'create', dataset_full_name])
                
                # Aplicar propiedades específicas
                for prop, value in dataset_config['properties'].items():
                    try:
                        self.system.run_command(['zfs', 'set', f'{prop}={value}', dataset_full_name])
                    except subprocess.CalledProcessError:
                        self.console.print(f"      ⚠️  No se pudo configurar {prop}={value}", style="yellow")
                
                # Configurar automontaje para este dataset (ZFS maneja automáticamente)
                try:
                    self.system.run_command(['zfs', 'set', 'canmount=on', dataset_full_name])
                    # ZFS automáticamente usa /{pool_name}/{dataset_name} como mountpoint por defecto
                except subprocess.CalledProcessError:
                    self.console.print(f"      ⚠️  No se pudo configurar automontaje", style="yellow")
                
                # Configurar snapshots solo si el usuario lo pidió
                if enable_snapshots:
                    self._configure_dataset_snapshots(dataset_full_name)
                
                # Configurar cuota solo si el usuario lo pidió
                if enable_quotas:
                    self._configure_dataset_quota(dataset_full_name, dataset_config['suggested_quota'])
                
                created_datasets.append({
                    'name': dataset_full_name,
                    'description': dataset_config['description'],
                    'mountpoint': f"/{dataset_full_name}"
                })
                
                self.console.print(f"      ✅ Dataset creado: {dataset_config['description']}", style="green")
                
            except subprocess.CalledProcessError as e:
                self.console.print(f"      ❌ Error creando dataset {dataset_config['name']}: {e}", style="red")
        
        # Mostrar resumen de datasets creados
        if created_datasets:
            self._show_datasets_summary(created_datasets)
    
    def _create_custom_datasets(self, pool_name: str):
        """Permite al usuario crear datasets personalizados"""
        self.console.print("\n🛠️  Creación de datasets personalizados")
        
        datasets_created = []
        
        while True:
            self.console.print(f"\n📁 Crear nuevo dataset en pool '{pool_name}'")
            
            # Nombre del dataset
            dataset_name = self.console.prompt("📝 Nombre del dataset", "").strip()
            if not dataset_name:
                break
            
            # Validar nombre
            if not self._validate_dataset_name(dataset_name):
                self.console.print("❌ Nombre inválido. Use solo letras, números, - y _", style="red")
                continue
            
            dataset_full_name = f"{pool_name}/{dataset_name}"
            
            # Verificar si ya existe
            try:
                result = self.system.run_command(['zfs', 'list', dataset_full_name], check=False)
                if result.returncode == 0:
                    self.console.print(f"❌ El dataset '{dataset_full_name}' ya existe", style="red")
                    continue
            except:
                pass
            
            # Descripción opcional
            description = self.console.prompt("📋 Descripción (opcional)", "").strip()
            
            # Configuraciones específicas
            self.console.print("\n⚙️  Configuraciones del dataset:")
            
            # Compresión
            compression_options = {
                '1': 'off',
                '2': 'lz4',
                '3': 'zstd',
                '4': 'gzip'
            }
            
            self.console.print("   Compresión:")
            self.console.print("   1. Sin compresión")
            self.console.print("   2. LZ4 (rápida)")
            self.console.print("   3. ZSTD (alta ratio)")
            self.console.print("   4. GZIP (máxima ratio)")
            
            comp_choice = self.console.prompt("   👉 Compresión", "2")
            compression = compression_options.get(comp_choice, 'lz4')
            
            # Recordsize
            recordsize_options = {
                '1': '16K',
                '2': '64K', 
                '3': '128K',
                '4': '1M'
            }
            
            self.console.print("\n   Tamaño de registro:")
            self.console.print("   1. 16K (bases de datos)")
            self.console.print("   2. 64K (aplicaciones)")
            self.console.print("   3. 128K (uso general)")
            self.console.print("   4. 1M (archivos grandes)")
            
            rec_choice = self.console.prompt("   👉 Recordsize", "3")
            recordsize = recordsize_options.get(rec_choice, '128K')
            
            # Atime
            disable_atime = self.console.confirm("   ¿Desactivar atime? (recomendado para rendimiento)", default=True)
            atime = 'off' if disable_atime else 'on'
            
            # Automontaje
            enable_automount = self.console.confirm("   ¿Habilitar automontaje?", default=True)
            
            # Snapshots
            self.console.print("\n   📸 Snapshots automáticos (copias de seguridad automáticas):")
            enable_snapshots = self.console.confirm("   ¿Habilitar snapshots automáticos?", default=True)
            
            # Cuota
            configure_quota = self.console.confirm("   ¿Configurar cuota de espacio?", default=False)
            quota_size = None
            if configure_quota:
                quota_size = self.console.prompt("   💾 Cuota (ej: 100G, 1T)", "").strip()
            
            # Crear dataset
            try:
                self.console.print(f"\n🔨 Creando dataset '{dataset_full_name}'...")
                
                # Crear con propiedades
                cmd = ['zfs', 'create']
                cmd.extend(['-o', f'compression={compression}'])
                cmd.extend(['-o', f'recordsize={recordsize}'])
                cmd.extend(['-o', f'atime={atime}'])
                if enable_automount:
                    cmd.extend(['-o', 'canmount=on'])
                    # ZFS automáticamente usa /{pool_name}/{dataset_name} como mountpoint por defecto
                else:
                    cmd.extend(['-o', 'canmount=off'])
                cmd.append(dataset_full_name)
                
                self.system.run_command(cmd)
                
                # Configurar snapshots si está habilitado
                if enable_snapshots:
                    self._configure_dataset_snapshots(dataset_full_name)
                
                # Configurar cuota si se especificó
                if quota_size:
                    self._configure_dataset_quota(dataset_full_name, quota_size)
                
                datasets_created.append({
                    'name': dataset_full_name,
                    'description': description or "Dataset personalizado",
                    'mountpoint': f"/{dataset_full_name}",
                    'compression': compression,
                    'recordsize': recordsize,
                    'atime': atime
                })
                
                self.console.print(f"✅ Dataset '{dataset_name}' creado exitosamente", style="green")
                
                # Preguntar si crear otro
                if not self.console.confirm("¿Crear otro dataset?", default=False):
                    break
                    
            except subprocess.CalledProcessError as e:
                self.console.print(f"❌ Error creando dataset: {e}", style="red")
        
        # Mostrar resumen
        if datasets_created:
            self._show_datasets_summary(datasets_created)
    
    def _validate_dataset_name(self, name: str) -> bool:
        """Valida que el nombre del dataset sea válido"""
        if not name:
            return False
        
        # Solo letras, números, guiones y guiones bajos
        import re
        return bool(re.match(r'^[a-zA-Z0-9_-]+$', name))
    
    def _show_datasets_summary(self, datasets: list):
        """Muestra un resumen de los datasets creados"""
        self.console.print("\n📊 Resumen de Datasets Creados:")
        
        if RICH_AVAILABLE:
            from rich.table import Table
            table = Table(title="📁 Datasets ZFS Creados")
            table.add_column("Dataset", style="cyan")
            table.add_column("Punto de Montaje", style="green")
            table.add_column("Descripción", style="yellow")
            
            for dataset in datasets:
                table.add_row(
                    dataset['name'],
                    dataset['mountpoint'],
                    dataset['description']
                )
            
            self.console.console.print(table)
        else:
            for dataset in datasets:
                print(f"   📁 {dataset['name']}")
                print(f"      📍 Montaje: {dataset['mountpoint']}")
                print(f"      📝 Descripción: {dataset['description']}")
                print()
        
        self.console.print("\n💡 Comandos útiles para datasets:")
        self.console.print("   • Listar datasets: zfs list")
        self.console.print("   • Ver propiedades: zfs get all <dataset>")
        self.console.print("   • Crear snapshot: zfs snapshot <dataset>@<nombre>")
        self.console.print("   • Configurar cuota: zfs set quota=<tamaño> <dataset>")
    
    def _configure_dataset_snapshots(self, dataset_name: str):
        """Configura snapshots automáticos para un dataset específico con selección de frecuencia"""
        self.console.print(f"      📸 Configurando snapshots para {dataset_name}")
        
        # MEJORA 1: Verificar/instalar servicio zfs-auto-snapshot
        if not self._verify_zfs_auto_snapshot_service():
            return
        
        # Preguntar qué tipo de snapshots quiere el usuario
        self.console.print("         🕐 Frecuencia de snapshots automáticos:")
        self.console.print("         1. Solo diarios (recomendado para uso general)")
        self.console.print("         2. Solo semanales (para datos poco cambiantes)")
        self.console.print("         3. Solo mensuales (para archivos estáticos)")
        self.console.print("         4. Diarios + semanales (balance espacio/protección)")
        self.console.print("         5. Semanales + mensuales (mínimo espacio)")
        self.console.print("         6. Todos (cada hora, día, semana, mes) ⚠️ Consume más espacio")
        
        choice = self.console.prompt("         👉 Selecciona frecuencia", "1")
        
        # Configurar snapshots base (siempre necesario)
        base_properties = [('com.sun:auto-snapshot', 'true', 'Snapshots automáticos base')]
        
        # Configurar según la elección del usuario
        if choice == "1":  # Solo diarios
            snapshot_properties = base_properties + [
                ('com.sun:auto-snapshot:daily', 'true', 'Snapshots diarios')
            ]
        elif choice == "2":  # Solo semanales
            snapshot_properties = base_properties + [
                ('com.sun:auto-snapshot:weekly', 'true', 'Snapshots semanales')
            ]
        elif choice == "3":  # Solo mensuales
            snapshot_properties = base_properties + [
                ('com.sun:auto-snapshot:monthly', 'true', 'Snapshots mensuales')
            ]
        elif choice == "4":  # Diarios + semanales
            snapshot_properties = base_properties + [
                ('com.sun:auto-snapshot:daily', 'true', 'Snapshots diarios'),
                ('com.sun:auto-snapshot:weekly', 'true', 'Snapshots semanales')
            ]
        elif choice == "5":  # Semanales + mensuales
            snapshot_properties = base_properties + [
                ('com.sun:auto-snapshot:weekly', 'true', 'Snapshots semanales'),
                ('com.sun:auto-snapshot:monthly', 'true', 'Snapshots mensuales')
            ]
        elif choice == "6":  # Todos
            snapshot_properties = base_properties + [
                ('com.sun:auto-snapshot:hourly', 'true', 'Snapshots cada hora'),
                ('com.sun:auto-snapshot:daily', 'true', 'Snapshots diarios'),
                ('com.sun:auto-snapshot:weekly', 'true', 'Snapshots semanales'),
                ('com.sun:auto-snapshot:monthly', 'true', 'Snapshots mensuales')
            ]
        else:  # Default a diarios
            self.console.print("         ⚠️  Opción inválida, usando snapshots diarios por defecto", style="yellow")
            snapshot_properties = base_properties + [
                ('com.sun:auto-snapshot:daily', 'true', 'Snapshots diarios')
            ]
        
        # Aplicar configuración seleccionada
        for prop, value, description in snapshot_properties:
            try:
                self.system.run_command(['zfs', 'set', f'{prop}={value}', dataset_name])
            except subprocess.CalledProcessError:
                self.console.print(f"         ⚠️  No se pudo configurar {description}", style="yellow")
        
        # MEJORA 2: Crear snapshot de demostración
        self._create_demo_snapshot(dataset_name)
        
        # Configurar retención de snapshots (nueva funcionalidad)
        retention_config = self._configure_snapshot_retention(choice)
        
        # MEJORA 4: Mostrar métodos de acceso a snapshots (mejorado)
        self._show_snapshot_access_methods(dataset_name)
        
        # Mostrar comandos útiles para gestión de snapshots
        self._show_snapshot_management_commands(dataset_name)
        
        self.console.print(f"         ✅ Snapshots automáticos configurados")
    
    def _show_snapshot_retention_info(self, choice: str):
        """Muestra información sobre retención de snapshots según la configuración"""
        retention_info = {
            "1": "Se mantendrán ~30 snapshots diarios",
            "2": "Se mantendrán ~12 snapshots semanales", 
            "3": "Se mantendrán ~12 snapshots mensuales",
            "4": "Se mantendrán ~30 diarios + ~12 semanales",
            "5": "Se mantendrán ~12 semanales + ~12 mensuales",
            "6": "Se mantendrán ~24 por hora + ~30 diarios + ~12 semanales + ~12 mensuales"
        }
        
        info = retention_info.get(choice, "Retención según configuración estándar")
        self.console.print(f"         💡 {info}", style="blue")
        
        if choice == "6":
            self.console.print("         ⚠️  Los snapshots por hora pueden consumir espacio significativo", style="yellow")
    
    def _configure_snapshot_retention(self, choice: str):
        """Configura cuántos snapshots mantener vivos según la frecuencia seleccionada"""
        self.console.print("         ⚙️  Configurando retención de snapshots...")
        
        # Configuraciones recomendadas para cada frecuencia
        retention_config = {}
        
        if choice == "1":  # Solo diarios
            retention_config['daily'] = self._ask_retention_count("diarios", 30)
        elif choice == "2":  # Solo semanales
            retention_config['weekly'] = self._ask_retention_count("semanales", 12)
        elif choice == "3":  # Solo mensuales
            retention_config['monthly'] = self._ask_retention_count("mensuales", 12)
        elif choice == "4":  # Diarios + semanales
            retention_config['daily'] = self._ask_retention_count("diarios", 30)
            retention_config['weekly'] = self._ask_retention_count("semanales", 12)
        elif choice == "5":  # Semanales + mensuales
            retention_config['weekly'] = self._ask_retention_count("semanales", 12)
            retention_config['monthly'] = self._ask_retention_count("mensuales", 12)
        elif choice == "6":  # Todos
            retention_config['hourly'] = self._ask_retention_count("por hora", 24)
            retention_config['daily'] = self._ask_retention_count("diarios", 30)
            retention_config['weekly'] = self._ask_retention_count("semanales", 12)
            retention_config['monthly'] = self._ask_retention_count("mensuales", 12)
        
        # Aplicar configuración de retención
        self._apply_retention_configuration(retention_config)
        
        return retention_config
    
    def _ask_retention_count(self, frequency_name: str, recommended: int) -> int:
        """Pregunta al usuario cuántos snapshots mantener para una frecuencia específica"""
        self.console.print(f"         📅 Snapshots {frequency_name}:")
        self.console.print(f"            Recomendado: {recommended} snapshots")
        
        while True:
            try:
                count = self.console.prompt(f"            ¿Cuántos snapshots {frequency_name} mantener?", str(recommended))
                count = int(count.strip())
                
                if count < 1:
                    self.console.print("            ❌ Debe ser al menos 1", style="red")
                    continue
                elif count > 100:
                    if not self.console.confirm(f"            ⚠️  {count} snapshots es mucho. ¿Continuar?", default=False):
                        continue
                
                # Mostrar estimación de espacio si es relevante
                if frequency_name == "por hora" and count > 48:
                    self.console.print("            ⚠️  Muchos snapshots por hora pueden consumir espacio significativo", style="yellow")
                elif frequency_name == "diarios" and count > 60:
                    self.console.print("            💡 Considere usar snapshots semanales para períodos largos", style="blue")
                
                return count
                
            except ValueError:
                self.console.print("            ❌ Ingrese un número válido", style="red")
    
    def _apply_retention_configuration(self, retention_config: dict):
        """Aplica la configuración de retención al archivo de configuración del sistema"""
        self.console.print("         🔧 Aplicando configuración de retención...")
        
        config_file = '/etc/default/zfs-auto-snapshot'
        temp_file = '/tmp/zfs_auto_snapshot_config.tmp'
        
        try:
            # Leer configuración actual si existe
            current_config = {}
            if os.path.exists(config_file):
                try:
                    result = self.system.run_command(['sudo', 'cat', config_file], check=False)
                    if result.returncode == 0:
                        for line in result.stdout.strip().split('\n'):
                            if '=' in line and not line.strip().startswith('#'):
                                key, value = line.split('=', 1)
                                current_config[key.strip()] = value.strip()
                except:
                    pass
            
            # Preparar nueva configuración
            new_config = {
                'HOURLY': str(retention_config.get('hourly', current_config.get('HOURLY', '0'))),
                'DAILY': str(retention_config.get('daily', current_config.get('DAILY', '0'))),
                'WEEKLY': str(retention_config.get('weekly', current_config.get('WEEKLY', '0'))),
                'MONTHLY': str(retention_config.get('monthly', current_config.get('MONTHLY', '0')))
            }
            
            # Crear contenido del archivo de configuración
            config_content = f"""# ZFS Auto-Snapshot Configuration
# Configurado por raid_manager.py - {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

# Número de snapshots a mantener para cada frecuencia
# 0 = deshabilitado, >0 = número de snapshots a conservar

# Snapshots por hora (0-24 recomendado)
HOURLY={new_config['HOURLY']}

# Snapshots diarios (7-60 recomendado)
DAILY={new_config['DAILY']}

# Snapshots semanales (4-12 recomendado)
WEEKLY={new_config['WEEKLY']}

# Snapshots mensuales (6-24 recomendado)
MONTHLY={new_config['MONTHLY']}

# Configuraciones adicionales
VERBOSE=false
DRYRUN=false
"""
            
            # Escribir a archivo temporal
            with open(temp_file, 'w') as f:
                f.write(config_content)
            
            # Copiar con sudo al destino final
            result = self.system.run_command(['sudo', 'cp', temp_file, config_file], check=False)
            
            if result.returncode == 0:
                self.console.print("         ✅ Configuración de retención aplicada", style="green")
                
                # Mostrar resumen de configuración
                self._show_retention_summary(retention_config)
                
                # Limpiar archivo temporal
                os.remove(temp_file)
                
            else:
                self.console.print("         ⚠️  Error aplicando configuración, usando valores por defecto", style="yellow")
                
        except Exception as e:
            self.console.print(f"         ⚠️  Error configurando retención: {e}", style="yellow")
            self.console.print("         💡 Puedes configurar manualmente editando /etc/default/zfs-auto-snapshot", style="blue")
    
    def _show_retention_summary(self, retention_config: dict):
        """Muestra un resumen de la configuración de retención aplicada"""
        self.console.print("         📊 Configuración de retención aplicada:", style="blue")
        
        frequency_names = {
            'hourly': 'Por hora',
            'daily': 'Diarios', 
            'weekly': 'Semanales',
            'monthly': 'Mensuales'
        }
        
        for freq, count in retention_config.items():
            name = frequency_names.get(freq, freq.capitalize())
            self.console.print(f"            📅 {name}: {count} snapshots")
        
        # Calcular estimación de snapshots totales
        total_snapshots = sum(retention_config.values())
        self.console.print(f"         💾 Total máximo de snapshots por dataset: ~{total_snapshots}")
        
        if total_snapshots > 50:
            self.console.print("         💡 Considera monitorear el uso de espacio regularmente", style="blue")
    
    def _show_snapshot_management_commands(self, dataset_name: str):
        """Muestra comandos útiles para gestionar snapshots"""
        self.console.print(f"         📚 Comandos útiles para gestionar snapshots:", style="blue")
        self.console.print(f"         • Ver snapshots: zfs list -t snapshot {dataset_name}")
        self.console.print(f"         • Crear manual: zfs snapshot {dataset_name}@manual-$(date +%Y%m%d)")
        self.console.print(f"         • Restaurar archivo: zfs send/recv o acceso directo en .zfs/snapshot/")
        self.console.print(f"         • Eliminar snapshot: zfs destroy {dataset_name}@nombre_snapshot")
    
    def _verify_zfs_auto_snapshot_service(self) -> bool:
        """MEJORA 1: Verifica si el servicio zfs-auto-snapshot está instalado y lo instala si es necesario"""
        self.console.print("         🔍 Verificando servicio zfs-auto-snapshot...")
        
        # Verificar si zfs-auto-snapshot está instalado
        try:
            self.system.run_command(['which', 'zfs-auto-snapshot'])
            self.console.print("         ✅ Servicio zfs-auto-snapshot encontrado", style="green")
            
            # Verificar que los cron jobs estén configurados
            self._verify_snapshot_cron_jobs()
            return True
            
        except subprocess.CalledProcessError:
            self.console.print("         ❌ zfs-auto-snapshot no está instalado", style="red")
            
            if self.console.confirm("         ¿Instalar zfs-auto-snapshot automáticamente?", default=True):
                return self._install_zfs_auto_snapshot()
            else:
                self.console.print("         ⚠️  Sin zfs-auto-snapshot, los snapshots automáticos no funcionarán", style="yellow")
                self.console.print("         💡 Instala manualmente: apt install zfs-auto-snapshot", style="blue")
                return False
    
    def _verify_snapshot_cron_jobs(self):
        """Verifica que los cron jobs de snapshots estén activos"""
        cron_files = [
            '/etc/cron.hourly/zfs-auto-snapshot',
            '/etc/cron.daily/zfs-auto-snapshot', 
            '/etc/cron.weekly/zfs-auto-snapshot',
            '/etc/cron.monthly/zfs-auto-snapshot'
        ]
        
        active_jobs = []
        for cron_file in cron_files:
            if os.path.exists(cron_file) and os.access(cron_file, os.X_OK):
                active_jobs.append(cron_file.split('/')[-2])  # hourly, daily, etc.
        
        if active_jobs:
            self.console.print(f"         ✅ Cron jobs activos: {', '.join(active_jobs)}", style="green")
        else:
            self.console.print("         ⚠️  No se encontraron cron jobs activos", style="yellow")
    
    def _install_zfs_auto_snapshot(self) -> bool:
        """Instala el servicio zfs-auto-snapshot"""
        self.console.print("         🔄 Instalando zfs-auto-snapshot...")
        
        try:
            # Actualizar lista de paquetes
            self.console.print("         📦 Actualizando lista de paquetes...")
            self.system.run_command(['sudo', 'apt', 'update', '-qq'])
            
            # Instalar zfs-auto-snapshot
            self.console.print("         📥 Instalando zfs-auto-snapshot...")
            result = self.system.run_command(['sudo', 'apt', 'install', '-y', 'zfs-auto-snapshot'])
            
            if result.returncode == 0:
                self.console.print("         ✅ zfs-auto-snapshot instalado exitosamente", style="green")
                
                # Verificar instalación
                try:
                    self.system.run_command(['which', 'zfs-auto-snapshot'])
                    self.console.print("         ✅ Instalación verificada", style="green")
                    self._verify_snapshot_cron_jobs()
                    return True
                except subprocess.CalledProcessError:
                    self.console.print("         ❌ Error verificando instalación", style="red")
                    return False
            else:
                self.console.print("         ❌ Error durante la instalación", style="red")
                return False
                
        except subprocess.CalledProcessError as e:
            self.console.print(f"         ❌ Error instalando zfs-auto-snapshot: {e}", style="red")
            self.console.print("         💡 Instala manualmente: sudo apt install zfs-auto-snapshot", style="blue")
            return False
    
    def _create_demo_snapshot(self, dataset_name: str):
        """MEJORA 2: Crea un snapshot de demostración para probar el sistema"""
        self.console.print("         🧪 Creando snapshot de demostración...")
        
        try:
            # Crear timestamp para el snapshot
            import datetime
            timestamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
            snapshot_name = f"{dataset_name}@demo-{timestamp}"
            
            # Crear el snapshot
            self.system.run_command(['zfs', 'snapshot', snapshot_name])
            self.console.print(f"         ✅ Snapshot creado: {snapshot_name}", style="green")
            
            # Verificar que se creó correctamente
            try:
                result = self.system.run_command(['zfs', 'list', '-t', 'snapshot', snapshot_name])
                if result.returncode == 0:
                    self.console.print("         ✅ Snapshot verificado correctamente", style="green")
                    
                    # Mostrar información del snapshot
                    self._show_demo_snapshot_info(dataset_name, snapshot_name)
                    
            except subprocess.CalledProcessError:
                self.console.print("         ⚠️  No se pudo verificar el snapshot", style="yellow")
                
        except subprocess.CalledProcessError as e:
            self.console.print(f"         ❌ Error creando snapshot de demostración: {e}", style="red")
    
    def _show_demo_snapshot_info(self, dataset_name: str, snapshot_name: str):
        """Muestra información del snapshot de demostración creado"""
        self.console.print("         📊 Información del snapshot de demostración:", style="blue")
        
        try:
            # Obtener información del snapshot
            result = self.system.run_command(['zfs', 'list', '-t', 'snapshot', '-o', 'name,used,refer', snapshot_name])
            lines = result.stdout.strip().split('\n')
            if len(lines) > 1:
                self.console.print(f"         📸 {lines[1]}")
            
            # Mostrar cómo acceder al snapshot
            pool_name = dataset_name.split('/')[0]
            dataset_path = dataset_name.replace(pool_name, f"/{pool_name}")
            snapshot_timestamp = snapshot_name.split('@')[1]
            
            self.console.print(f"         🔗 Acceso al snapshot:")
            self.console.print(f"             • Ruta directa: {dataset_path}/.zfs/snapshot/{snapshot_timestamp}/")
            self.console.print(f"             • Navegación: cd {dataset_path}/.zfs/snapshot/")
            
        except subprocess.CalledProcessError:
            self.console.print("         ⚠️  No se pudo obtener información detallada", style="yellow")
    
    def _show_snapshot_access_methods(self, dataset_name: str):
        """MEJORA 4: Muestra métodos detallados para acceder a snapshots"""
        pool_name = dataset_name.split('/')[0]
        dataset_path = dataset_name.replace(pool_name, f"/{pool_name}")
        
        self.console.print("         🔗 Métodos de acceso a snapshots:", style="blue")
        self.console.print("         ")
        self.console.print("         📁 1. Acceso directo por navegación:")
        self.console.print(f"            cd {dataset_path}/.zfs/snapshot/")
        self.console.print("            ls -la                    # Ver todos los snapshots")
        self.console.print("            cd auto-2024MMDD-HHMM/    # Entrar en snapshot específico")
        self.console.print("            ")
        self.console.print("         📁 2. Restaurar archivos específicos:")
        self.console.print(f"            cp {dataset_path}/.zfs/snapshot/SNAPSHOT_NAME/archivo.txt {dataset_path}/")
        self.console.print("            # Copia archivo desde snapshot a ubicación actual")
        self.console.print("            ")
        self.console.print("         📁 3. Explorar contenido de snapshots:")
        self.console.print(f"            find {dataset_path}/.zfs/snapshot/ -name '*archivo*' -type f")
        self.console.print("            # Busca archivos en todos los snapshots")
        self.console.print("            ")
        self.console.print("         📁 4. Comparar versiones:")
        self.console.print(f"            diff {dataset_path}/archivo.txt {dataset_path}/.zfs/snapshot/SNAPSHOT/archivo.txt")
        self.console.print("            # Compara archivo actual con versión en snapshot")
        self.console.print("            ")
        self.console.print("         💡 Los snapshots son de solo lectura y no ocupan espacio inicialmente")
        self.console.print("         💡 Solo los cambios posteriores al snapshot consumen espacio adicional")
    
    def _configure_dataset_quota(self, dataset_name: str, suggested_quota: str):
        """Configura cuota para un dataset específico"""
        try:
            self.system.run_command(['zfs', 'set', f'quota={suggested_quota}', dataset_name])
            self.console.print(f"      💾 Cuota de {suggested_quota} configurada")
        except subprocess.CalledProcessError:
            self.console.print(f"      ⚠️  No se pudo configurar cuota de {suggested_quota}", style="yellow")
    
    def _create_btrfs_raid(self, raid_type: RAIDType, disks: List[Disk]):
        """Crea un RAID BTRFS"""
        self.console.print_panel("Configurando BTRFS RAID", title="🌿 BTRFS")
        
        # Verificar que BTRFS esté disponible
        try:
            self.system.run_command(['which', 'mkfs.btrfs'])
        except subprocess.CalledProcessError:
            self.console.print("❌ BTRFS no está disponible en el sistema", style="red")
            raise Exception("BTRFS no disponible")
        
        # Obtener punto de montaje
        mount_point = self._get_mount_point("/mnt/btrfs_raid")
        
        # Mapear tipos de RAID
        raid_mapping = {
            RAIDType.BTRFS_RAID0: 'raid0',
            RAIDType.BTRFS_RAID1: 'raid1', 
            RAIDType.BTRFS_RAID10: 'raid10',
            RAIDType.BTRFS_RAID5: 'raid5',
            RAIDType.BTRFS_RAID6: 'raid6'
        }
        
        btrfs_raid_type = raid_mapping.get(raid_type)
        if not btrfs_raid_type:
            raise Exception(f"Tipo de RAID no soportado: {raid_type}")
        
        # Mostrar advertencia para RAID experimentales
        if raid_type in [RAIDType.BTRFS_RAID5, RAIDType.BTRFS_RAID6]:
            self.console.print("⚠️  ADVERTENCIA: RAID 5/6 en BTRFS es experimental", style="yellow")
            if not self.console.confirm("¿Continuar con RAID experimental?", default=False):
                raise Exception("Operación cancelada por el usuario")
        
        # Crear filesystem BTRFS
        self._create_btrfs_filesystem(btrfs_raid_type, disks, mount_point)
        
        # Configurar propiedades BTRFS
        self._configure_btrfs_properties(mount_point)
        
        self.console.print("✅ BTRFS RAID creado exitosamente", style="green")
    
    def _create_btrfs_filesystem(self, raid_type: str, disks: List[Disk], mount_point: str):
        """Crea el filesystem BTRFS"""
        self.console.print(f"🔨 Creando filesystem BTRFS {raid_type.upper()}...")
        
        # Construir comando
        cmd = ['mkfs.btrfs', '-f', '-d', raid_type, '-m', raid_type]
        
        # Añadir discos
        for disk in disks:
            cmd.append(f'/dev/{disk.name}')
        
        try:
            self.console.print(f"📝 Ejecutando: {' '.join(cmd)}")
            self.system.run_command(cmd)
            self.console.print("✅ Filesystem BTRFS creado", style="green")
            
            # Montar el filesystem
            self.console.print(f"📁 Montando en {mount_point}...")
            self.system.run_command(['mount', f'/dev/{disks[0].name}', mount_point])
            self.console.print(f"✅ Montado en {mount_point}", style="green")
            
        except subprocess.CalledProcessError as e:
            self.console.print(f"❌ Error creando filesystem BTRFS: {e}", style="red")
            raise
    
    def _configure_btrfs_properties(self, mount_point: str):
        """Configura propiedades del filesystem BTRFS"""
        self.console.print("⚙️  Configurando propiedades BTRFS...")
        
        # Habilitar compresión
        try:
            self.system.run_command(['btrfs', 'property', 'set', mount_point, 'compression', 'lzo'])
            self.console.print("   ✅ Compresión LZO habilitada", style="green")
        except subprocess.CalledProcessError as e:
            self.console.print(f"   ⚠️  No se pudo habilitar compresión: {e}", style="yellow")
        
        # Mostrar información del filesystem
        try:
            result = self.system.run_command(['btrfs', 'filesystem', 'show', mount_point])
            self.console.print("📊 Información del filesystem:")
            for line in result.stdout.split('\n'):
                if line.strip():
                    self.console.print(f"   {line}")
        except subprocess.CalledProcessError:
            pass
    
    def _configure_auto_mount(self, fs_type: FilesystemType, raid_type: RAIDType, disks: List[Disk]):
        """Configura el montaje automático según el tipo de filesystem"""
        self.console.print_panel("Configurando montaje automático", title="🔧 Configuración")
        
        if not self.console.confirm("¿Configurar montaje automático en el arranque?", default=True):
            self.console.print("⏭️  Saltando configuración de montaje automático", style="blue")
            return
        
        try:
            if fs_type == FilesystemType.ZFS:
                self._configure_zfs_auto_mount()
            else:
                # BTRFS requiere entrada en fstab
                self._configure_btrfs_fstab(disks)
                
        except Exception as e:
            self.console.print(f"❌ Error configurando montaje automático: {e}", style="red")
    
    def _configure_zfs_auto_mount(self):
        """Configura montaje automático para ZFS (sin fstab)"""
        self.console.print("🔷 Configurando ZFS para montaje automático...", style="blue")
        
        # ZFS no necesita /etc/fstab - maneja su propio sistema de montaje
        self.console.print("💡 ZFS gestiona automáticamente el montaje de pools y datasets")
        self.console.print("   • Los pools se importan automáticamente al arranque")
        self.console.print("   • Los datasets se montan según su propiedad 'mountpoint'")
        
        # Habilitar servicios ZFS del sistema
        zfs_services = [
            ('zfs-import-cache.service', 'Importación automática de pools'),
            ('zfs-mount.service', 'Montaje automático de datasets'),
            ('zfs.target', 'Target principal de ZFS')
        ]
        
        for service, description in zfs_services:
            if self.system.run_command_safe(['systemctl', 'enable', service]):
                self.console.print(f"   ✅ {service} habilitado - {description}")
            else:
                self.console.print(f"   ⚠️  Error con {service} - {description}", style="yellow")
        
        # Verificar que los servicios estén activos
        self.console.print("\n🔍 Verificando estado de servicios ZFS...")
        for service, description in zfs_services:
            try:
                result = self.system.run_command(['systemctl', 'is-enabled', service], check=False)
                if result.returncode == 0:
                    status = result.stdout.strip()
                    if status == 'enabled':
                        self.console.print(f"   ✅ {service}: {status}")
                    else:
                        self.console.print(f"   ⚠️  {service}: {status}", style="yellow")
                else:
                    self.console.print(f"   ❌ {service}: no disponible", style="red")
            except subprocess.CalledProcessError:
                self.console.print(f"   ❌ {service}: error verificando", style="red")
        
        # Información adicional sobre montaje ZFS
        self.console.print("\n📚 Información sobre montaje ZFS:")
        self.console.print("   • Para cambiar punto de montaje: zfs set mountpoint=/ruta pool/dataset")
        self.console.print("   • Para deshabilitar montaje: zfs set mountpoint=none pool/dataset") 
        self.console.print("   • Para montar manualmente: zfs mount pool/dataset")
        self.console.print("   • Para ver puntos de montaje: zfs get mountpoint")
        
        self.console.print("✅ Configuración ZFS completada", style="green")
    
    def _configure_btrfs_fstab(self, disks: List[Disk]):
        """Configura fstab para BTRFS"""
        self.console.print("🌿 Configurando BTRFS para montaje automático...", style="green")
        
        try:
            # Para BTRFS RAID, necesitamos el UUID del filesystem, no del dispositivo individual
            device_path = f"/dev/{disks[0].name}"
            
            # Intentar obtener UUID del filesystem BTRFS
            result = self.system.run_command(['blkid', '-s', 'UUID', '-o', 'value', device_path], check=False)
            uuid = result.stdout.strip() if result.returncode == 0 else None
            
            if not uuid:
                # Si no hay UUID, el filesystem podría no estar montado aún
                self.console.print("⚠️  No se encontró UUID, intentando detectar filesystem BTRFS...", style="yellow")
                try:
                    # Usar btrfs filesystem show para obtener UUID
                    result = self.system.run_command(['btrfs', 'filesystem', 'show', device_path])
                    for line in result.stdout.split('\n'):
                        if 'uuid:' in line:
                            uuid = line.split('uuid:')[1].strip()
                            break
                except subprocess.CalledProcessError:
                    pass
            
            if not uuid:
                raise Exception("No se pudo obtener UUID del filesystem BTRFS")
            
            # Obtener o definir punto de montaje
            mount_point = "/storage"  # Punto de montaje por defecto
            
            try:
                result = self.system.run_command(['findmnt', '-n', '-o', 'TARGET', device_path], check=False)
                if result.returncode == 0 and result.stdout.strip():
                    mount_point = result.stdout.strip()
                    self.console.print(f"📁 Punto de montaje detectado: {mount_point}")
                else:
                    self.console.print(f"📁 Usando punto de montaje por defecto: {mount_point}")
                    # Crear directorio si no existe
                    if self.system.run_command_safe(['mkdir', '-p', mount_point]):
                        self.console.print(f"   ✅ Directorio {mount_point} creado")
            except subprocess.CalledProcessError:
                self.console.print(f"📁 Usando punto de montaje por defecto: {mount_point}")
                self.system.run_command_safe(['mkdir', '-p', mount_point])
            
            # Crear entrada fstab optimizada para BTRFS
            fstab_options = []
            fstab_options.append("defaults")
            fstab_options.append("compress=zstd")  # Compresión moderna y eficiente
            fstab_options.append("noatime")        # Mejor rendimiento
            fstab_options.append("space_cache=v2") # Cache de espacio v2
            
            fstab_entry = f"UUID={uuid} {mount_point} btrfs {','.join(fstab_options)} 0 2\n"
            
            # Crear backup de fstab
            if self.system.run_command_safe(['cp', '/etc/fstab', '/etc/fstab.backup']):
                self.console.print("   ✅ Backup de /etc/fstab creado")
            
            # Verificar si ya existe una entrada para este UUID
            try:
                with open('/etc/fstab', 'r') as f:
                    fstab_content = f.read()
                
                if uuid in fstab_content:
                    self.console.print("⚠️  Ya existe una entrada para este UUID en fstab", style="yellow")
                    if not self.console.confirm("¿Sobrescribir entrada existente?", default=False):
                        self.console.print("⏭️  Manteniendo configuración existente", style="blue")
                        return
                    
                    # Remover entrada existente
                    lines = fstab_content.split('\n')
                    new_lines = [line for line in lines if uuid not in line]
                    fstab_content = '\n'.join(new_lines)
                    
                    with open('/etc/fstab', 'w') as f:
                        f.write(fstab_content)
                    
                    self.console.print("   🔄 Entrada anterior removida")
                
                # Añadir nueva entrada a fstab
                with open('/etc/fstab', 'a') as f:
                    f.write(f"\n# BTRFS RAID configurado por raid_manager.py - {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
                    f.write(fstab_entry)
                
                self.console.print("✅ Entrada añadida a /etc/fstab", style="green")
                self.console.print(f"   📄 UUID: {uuid}")
                self.console.print(f"   📁 Punto de montaje: {mount_point}")
                self.console.print(f"   ⚙️  Opciones: {','.join(fstab_options)}")
                
                # Verificar que el montaje funciona
                if self.console.confirm("¿Probar montaje automático?", default=True):
                    if self.system.run_command_safe(['mount', '-a']):
                        self.console.print("✅ Montaje automático verificado", style="green")
                    else:
                        self.console.print("⚠️  Error en montaje automático - revisar configuración", style="yellow")
                
            except Exception as e:
                raise Exception(f"Error escribiendo fstab: {e}")
            
        except Exception as e:
            self.console.print(f"❌ Error configurando fstab: {e}", style="red")
            self.console.print("💡 Puedes configurar el montaje manualmente después", style="blue")
    
    def _show_final_summary(self, fs_type: FilesystemType, raid_type: RAIDType, disks: List[Disk]):
        """Muestra el resumen final de la configuración"""
        self.console.print_panel("¡RAID configurado exitosamente!", title="🎉 ¡Completado!")
        
        if RICH_AVAILABLE:
            # Crear tabla de resumen final
            summary_table = Table(title="📋 Configuración Final", show_header=False)
            summary_table.add_column("Aspecto", style="bold cyan", width=20)
            summary_table.add_column("Detalle", style="white")
            
            summary_table.add_row("Filesystem", fs_type.value.upper())
            summary_table.add_row("Tipo RAID", raid_type.value)
            summary_table.add_row("Discos utilizados", f"{len(disks)} discos")
            
            disk_list = ", ".join([f"{disk.name} ({disk.size_human})" for disk in disks])
            summary_table.add_row("Detalle de discos", disk_list)
            
            # Estado del sistema
            if fs_type == FilesystemType.ZFS:
                try:
                    result = self.system.run_command(['zpool', 'list'])
                    summary_table.add_row("Estado ZFS", "✅ Online")
                except:
                    summary_table.add_row("Estado ZFS", "⚠️  Verificar manualmente")
            else:
                summary_table.add_row("Estado BTRFS", "✅ Montado")
            
            self.console.console.print(summary_table)
        
        # Comandos útiles
        self.console.print("\n💡 Comandos útiles:", style="bold blue")
        
        if fs_type == FilesystemType.ZFS:
            useful_commands = [
                "zpool status - Ver estado del pool",
                "zfs list - Listar datasets",
                "zpool iostat 1 - Monitor de I/O en tiempo real",
                "zfs get all <pool> - Ver todas las propiedades"
            ]
        else:
            useful_commands = [
                "btrfs filesystem show - Ver filesystems BTRFS",
                "btrfs filesystem usage <mount> - Ver uso del espacio",
                "btrfs device stats <mount> - Estadísticas de dispositivos",
                "btrfs scrub start <mount> - Iniciar verificación de integridad"
            ]
        
        for cmd in useful_commands:
            self.console.print(f"   • {cmd}", style="blue")
        
        # Advertencias finales
        warnings = [
            "🔄 Reinicia el sistema para asegurar el montaje automático",
            "📊 Monitorea el rendimiento inicial del RAID",
            "💾 Configura backups regulares de tus datos importantes"
        ]
        
        self.console.print("\n⚠️  Recomendaciones importantes:", style="bold yellow")
        for warning in warnings:
            self.console.print(f"   {warning}", style="yellow")
    
    def _configure_cache_devices(self, pool_name: str, pool_disks: List[Disk]):
        """Configura dispositivos de cache (SLOG/L2ARC) para el pool ZFS"""
        self.console.print_panel(
            f"Configuración de dispositivos de cache para '{pool_name}'\n"
            "Los dispositivos de cache mejoran el rendimiento del pool ZFS",
            title="🚀 Cache Devices",
            style="blue"
        )
        
        # Detectar dispositivos disponibles para cache
        cache_devices = self._detect_cache_devices(pool_disks)
        
        if not cache_devices['nvme'] and not cache_devices['ssd']:
            self.console.print_panel(
                "⚠️  NO SE DETECTARON DISPOSITIVOS NVMe O SSD ADECUADOS\n\n"
                "• Los dispositivos de cache deben ser más rápidos que el almacenamiento principal\n"
                "• Usar dispositivos lentos como cache puede REDUCIR el rendimiento\n"
                "• Se recomienda conseguir un dispositivo NVMe o SSD para cache",
                title="❌ Sin dispositivos de cache",
                style="yellow"
            )
            return
        
        # Mostrar información sobre cache devices
        self._show_cache_info()
        
        # Mostrar dispositivos disponibles
        self._show_available_cache_devices(cache_devices)
        
        # Preguntar si quiere configurar cache devices
        if not self.console.confirm("¿Deseas configurar dispositivos de cache para mejorar el rendimiento?", default=True):
            self.console.print("⏭️  Saltando configuración de cache devices", style="yellow")
            return
        
        # Menú de opciones de cache
        self._show_cache_menu(pool_name, cache_devices)
    
    def _detect_cache_devices(self, pool_disks: List[Disk]) -> Dict[str, List[Disk]]:
        """Detecta dispositivos disponibles para cache (NVMe/SSD)"""
        all_disks = self.disk_manager.detect_disks()
        pool_disk_names = {disk.name for disk in pool_disks}
        
        cache_devices = {
            'nvme': [],
            'ssd': [],
            'other': []
        }
        
        for disk in all_disks:
            # Excluir discos del sistema y discos usados en el pool principal
            if disk.is_system or disk.name in pool_disk_names:
                continue
            
            # Clasificar por tipo
            if disk.name.startswith('nvme'):
                cache_devices['nvme'].append(disk)
            elif self._is_ssd(disk):
                cache_devices['ssd'].append(disk)
            else:
                cache_devices['other'].append(disk)
        
        return cache_devices
    
    def _is_ssd(self, disk: Disk) -> bool:
        """Verifica si un disco es SSD"""
        try:
            # Verificar ROTA (rotational) - 0 significa SSD
            result = self.system.run_command(['lsblk', '-dpno', 'ROTA', f'/dev/{disk.name}'])
            return result.stdout.strip() == '0'
        except subprocess.CalledProcessError:
            return False
    
    def _show_cache_info(self):
        """Muestra información sobre cache devices"""
        info_text = (
            "🚀 L2ARC (Level 2 Adaptive Replacement Cache):\n"
            "   • Cache de segundo nivel para lecturas frecuentes\n"
            "   • Ideal: SSD rápido (NVMe > SATA SSD)\n"
            "   • Mejora rendimiento de lectura en datasets accedidos frecuentemente\n"
            "   • No es crítico - si falla, el pool sigue funcionando\n\n"
            "📝 SLOG (Separate Intent Log):\n"
            "   • Log de transacciones para escrituras síncronas\n"
            "   • Ideal: SSD con baja latencia (NVMe recomendado)\n"
            "   • Mejora rendimiento de escrituras síncronas (bases de datos, VMs)\n"
            "   • Crítico para integridad - usar dispositivos confiables"
        )
        self.console.print_panel(info_text, title="💡 Información sobre Cache Devices")
    
    def _show_available_cache_devices(self, cache_devices: Dict[str, List[Disk]]):
        """Muestra dispositivos disponibles para cache"""
        if RICH_AVAILABLE:
            table = Table(title="💾 Dispositivos Disponibles para Cache")
            table.add_column("Tipo", style="cyan")
            table.add_column("Dispositivo", style="green")
            table.add_column("Tamaño", style="yellow")
            table.add_column("Modelo", style="blue")
            table.add_column("Recomendación", style="magenta")
            
            # Dispositivos NVMe
            for disk in cache_devices['nvme']:
                table.add_row(
                    "🚀 NVMe", 
                    disk.name, 
                    disk.size_human, 
                    disk.model,
                    "✅ EXCELENTE"
                )
            
            # Dispositivos SSD
            for disk in cache_devices['ssd']:
                table.add_row(
                    "💾 SSD", 
                    disk.name, 
                    disk.size_human, 
                    disk.model,
                    "⚠️ ACEPTABLE"
                )
            
            # Otros dispositivos (no recomendados)
            for disk in cache_devices['other']:
                table.add_row(
                    "🐌 HDD", 
                    disk.name, 
                    disk.size_human, 
                    disk.model,
                    "❌ NO RECOMENDADO"
                )
            
            self.console.console.print(table)
        else:
            print("\n💾 Dispositivos Disponibles para Cache:")
            for disk in cache_devices['nvme']:
                print(f"  🚀 {disk.name} - {disk.size_human} - {disk.model} (NVMe - EXCELENTE)")
            for disk in cache_devices['ssd']:
                print(f"  💾 {disk.name} - {disk.size_human} - {disk.model} (SSD - ACEPTABLE)")
    
    def _show_cache_menu(self, pool_name: str, cache_devices: Dict[str, List[Disk]]):
        """Muestra menú de opciones de cache"""
        self.console.print("\n🎯 Opciones de configuración de cache:")
        self.console.print("   1. Solo L2ARC (cache de lectura)")
        self.console.print("   2. Solo SLOG (log de escritura)")
        self.console.print("   3. L2ARC y SLOG en dispositivos separados")
        self.console.print("   4. L2ARC y SLOG particionados en el mismo dispositivo")
        self.console.print("   0. Saltar configuración de cache")
        
        while True:
            choice = self.console.prompt("👉 Selecciona opción", "1")
            
            if choice == "0":
                self.console.print("⏭️  Saltando configuración de cache", style="yellow")
                break
            elif choice == "1":
                self._setup_l2arc_only(pool_name, cache_devices)
                break
            elif choice == "2":
                self._setup_slog_only(pool_name, cache_devices)
                break
            elif choice == "3":
                self._setup_separate_cache_devices(pool_name, cache_devices)
                break
            elif choice == "4":
                self._setup_partitioned_cache(pool_name, cache_devices)
                break
            else:
                self.console.print("❌ Opción inválida", style="red")
    
    def _setup_l2arc_only(self, pool_name: str, cache_devices: Dict[str, List[Disk]]):
        """Configura solo L2ARC"""
        self.console.print_panel("Configurando L2ARC (cache de lectura)", title="🚀 L2ARC")
        
        # Seleccionar dispositivo
        device = self._select_cache_device(cache_devices, "L2ARC")
        if not device:
            return
        
        # Limpiar dispositivo si es necesario
        if not self._prepare_cache_device(device):
            return
        
        # Agregar L2ARC al pool
        try:
            self.console.print(f"📦 Agregando {device.name} como L2ARC al pool {pool_name}...")
            self.system.run_command(['zpool', 'add', pool_name, 'cache', f'/dev/{device.name}'])
            self.console.print("✅ L2ARC configurado exitosamente", style="green")
        except subprocess.CalledProcessError as e:
            self.console.print(f"❌ Error configurando L2ARC: {e}", style="red")
    
    def _setup_slog_only(self, pool_name: str, cache_devices: Dict[str, List[Disk]]):
        """Configura solo SLOG"""
        self.console.print_panel("Configurando SLOG (log de escritura)", title="📝 SLOG")
        
        # Seleccionar dispositivo
        device = self._select_cache_device(cache_devices, "SLOG")
        if not device:
            return
        
        # Limpiar dispositivo si es necesario
        if not self._prepare_cache_device(device):
            return
        
        # Agregar SLOG al pool
        try:
            self.console.print(f"📦 Agregando {device.name} como SLOG al pool {pool_name}...")
            self.system.run_command(['zpool', 'add', pool_name, 'log', f'/dev/{device.name}'])
            self.console.print("✅ SLOG configurado exitosamente", style="green")
        except subprocess.CalledProcessError as e:
            self.console.print(f"❌ Error configurando SLOG: {e}", style="red")
    
    def _setup_separate_cache_devices(self, pool_name: str, cache_devices: Dict[str, List[Disk]]):
        """Configura L2ARC y SLOG en dispositivos separados"""
        self.console.print_panel("Configurando L2ARC y SLOG en dispositivos separados", title="🔄 Dual Cache")
        
        # Verificar que hay al menos 2 dispositivos
        available_count = len(cache_devices['nvme']) + len(cache_devices['ssd'])
        if available_count < 2:
            self.console.print("❌ Se necesitan al menos 2 dispositivos para configuración separada", style="red")
            return
        
        # Seleccionar dispositivo para L2ARC
        self.console.print("\n🚀 Seleccionar dispositivo para L2ARC:")
        l2arc_device = self._select_cache_device(cache_devices, "L2ARC")
        if not l2arc_device:
            return
        
        # Remover el dispositivo seleccionado de las opciones
        for device_type in cache_devices:
            cache_devices[device_type] = [d for d in cache_devices[device_type] if d.name != l2arc_device.name]
        
        # Seleccionar dispositivo para SLOG
        self.console.print("\n📝 Seleccionar dispositivo para SLOG:")
        slog_device = self._select_cache_device(cache_devices, "SLOG")
        if not slog_device:
            return
        
        # Preparar dispositivos
        if not self._prepare_cache_device(l2arc_device) or not self._prepare_cache_device(slog_device):
            return
        
        # Configurar L2ARC y SLOG
        try:
            self.console.print(f"📦 Configurando cache devices...")
            self.system.run_command(['zpool', 'add', pool_name, 'cache', f'/dev/{l2arc_device.name}'])
            self.system.run_command(['zpool', 'add', pool_name, 'log', f'/dev/{slog_device.name}'])
            self.console.print("✅ L2ARC y SLOG configurados exitosamente", style="green")
        except subprocess.CalledProcessError as e:
            self.console.print(f"❌ Error configurando cache devices: {e}", style="red")
    
    def _setup_partitioned_cache(self, pool_name: str, cache_devices: Dict[str, List[Disk]]):
        """Configura L2ARC y SLOG particionados en el mismo dispositivo"""
        self.console.print_panel("Configurando L2ARC y SLOG particionados en el mismo dispositivo", title="🔀 Cache Particionado")
        
        # Seleccionar dispositivo
        device = self._select_cache_device(cache_devices, "Cache particionado")
        if not device:
            return
        
        # Verificar tamaño mínimo (al menos 4GB para particionar)
        if device.size < 4 * 1024**3:  # 4GB
            self.console.print("❌ El dispositivo debe tener al menos 4GB para particionado", style="red")
            return
        
        # Limpiar dispositivo
        if not self._prepare_cache_device(device):
            return
        
        # Crear particiones
        try:
            self.console.print(f"🔧 Particionando {device.name}...")
            
            # Calcular tamaños (SLOG: 10% o máximo 32GB, resto para L2ARC)
            total_size = device.size
            slog_size = min(int(total_size * 0.1), 32 * 1024**3)  # 10% o 32GB máximo
            
            # Limpiar tabla de particiones primero
            self.console.print("   • Limpiando tabla de particiones...")
            self.system.run_command(['sgdisk', '--zap-all', f'/dev/{device.name}'])
            
            # Crear nueva tabla GPT y particiones
            self.console.print("   • Creando particiones...")
            # Crear SLOG (partición 1)
            self.system.run_command(['sgdisk', '-n', f'1:0:+{slog_size // 512}', f'/dev/{device.name}'])
            # Crear L2ARC (partición 2 - resto del espacio)
            self.system.run_command(['sgdisk', '-n', '2:0:0', f'/dev/{device.name}'])
            
            # Establecer etiquetas para identificar las particiones
            self.system.run_command(['sgdisk', '-c', '1:ZFS-SLOG', f'/dev/{device.name}'])
            self.system.run_command(['sgdisk', '-c', '2:ZFS-L2ARC', f'/dev/{device.name}'])
            
            # Notificar al kernel sobre cambios en particiones
            self.console.print("   • Actualizando tabla de particiones...")
            self.system.run_command(['partprobe', f'/dev/{device.name}'])
            self.system.run_command(['udevadm', 'settle'])
            
            # Determinar nombres de particiones según el tipo de dispositivo
            if device.name.startswith('nvme'):
                slog_partition = f"{device.name}p1"
                l2arc_partition = f"{device.name}p2"
            else:
                slog_partition = f"{device.name}1"
                l2arc_partition = f"{device.name}2"
            
            # Esperar a que las particiones estén disponibles
            self.console.print("   • Esperando a que las particiones estén disponibles...")
            import time
            max_wait = 10
            for i in range(max_wait):
                if (Path(f'/dev/{slog_partition}').exists() and 
                    Path(f'/dev/{l2arc_partition}').exists()):
                    break
                time.sleep(1)
                if i == max_wait - 1:
                    raise Exception(f"Las particiones no están disponibles después de {max_wait} segundos")
            
            # Agregar particiones al pool
            self.console.print("📦 Agregando particiones al pool...")
            self.system.run_command(['zpool', 'add', pool_name, 'log', f'/dev/{slog_partition}'])
            self.system.run_command(['zpool', 'add', pool_name, 'cache', f'/dev/{l2arc_partition}'])
            
            self.console.print("✅ Cache particionado configurado exitosamente", style="green")
            self.console.print(f"   📝 SLOG: {slog_partition} ({slog_size // (1024**3)}GB)")
            self.console.print(f"   🚀 L2ARC: {l2arc_partition} ({(total_size - slog_size) // (1024**3)}GB)")
            
        except subprocess.CalledProcessError as e:
            self.console.print(f"❌ Error configurando cache particionado: {e}", style="red")
        except Exception as e:
            self.console.print(f"❌ Error configurando cache particionado: {e}", style="red")
    
    def _select_cache_device(self, cache_devices: Dict[str, List[Disk]], purpose: str) -> Optional[Disk]:
        """Selecciona un dispositivo para cache"""
        available_devices = cache_devices['nvme'] + cache_devices['ssd']
        
        if not available_devices:
            self.console.print(f"❌ No hay dispositivos disponibles para {purpose}", style="red")
            return None
        
        if len(available_devices) == 1:
            device = available_devices[0]
            device_type = "NVMe" if device.name.startswith('nvme') else "SSD"
            if self.console.confirm(f"¿Usar {device.name} ({device.size_human} {device_type}) para {purpose}?", default=True):
                return device
            return None
        
        # Mostrar opciones
        self.console.print(f"\n💾 Dispositivos disponibles para {purpose}:")
        for i, device in enumerate(available_devices, 1):
            device_type = "🚀 NVMe" if device.name.startswith('nvme') else "💾 SSD"
            self.console.print(f"   {i}. {device_type} {device.name} - {device.size_human} - {device.model}")
        
        while True:
            choice = self.console.prompt("👉 Selecciona dispositivo", "1")
            try:
                index = int(choice) - 1
                if 0 <= index < len(available_devices):
                    return available_devices[index]
                else:
                    self.console.print("❌ Opción inválida", style="red")
            except ValueError:
                if choice.lower() == 'q':
                    return None
                self.console.print("❌ Por favor ingresa un número válido", style="red")
    
    def _prepare_cache_device(self, device: Disk) -> bool:
        """Prepara un dispositivo para usar como cache (limpia si es necesario)"""
        # Verificar si el dispositivo tiene datos
        if device.has_partitions or device.filesystem_type:
            self.console.print_panel(
                f"⚠️  ADVERTENCIA: El dispositivo {device.name} contiene datos\n"
                f"Configurarlo como cache DESTRUIRÁ todos los datos existentes\n\n"
                f"Datos detectados:\n"
                f"• Particiones: {'Sí' if device.has_partitions else 'No'}\n"
                f"• Filesystem: {device.filesystem_type or 'Ninguno'}\n"
                f"• Puntos de montaje: {', '.join(device.mount_points) if device.mount_points else 'Ninguno'}",
                title="🚨 Confirmación Destructiva",
                style="red"
            )
            
            if not self.console.confirm(f"¿DESTRUIR todos los datos en {device.name} para configurar cache?", default=False):
                self.console.print("❌ Operación cancelada", style="yellow")
                return False
        
        # Limpiar dispositivo
        try:
            self.console.print(f"🧹 Limpiando dispositivo {device.name}...")
            
            # Desmontar particiones si están montadas
            if device.mount_points:
                for mount_point in device.mount_points:
                    try:
                        self.system.run_command(['umount', mount_point])
                    except subprocess.CalledProcessError:
                        pass
            
            # Limpiar firmas de filesystem
            self.system.run_command(['wipefs', '-a', f'/dev/{device.name}'])
            
            # Limpiar tabla de particiones
            self.system.run_command(['sgdisk', '-Z', f'/dev/{device.name}'])
            
            self.console.print(f"✅ Dispositivo {device.name} preparado", style="green")
            return True
            
        except subprocess.CalledProcessError as e:
            self.console.print(f"❌ Error preparando dispositivo: {e}", style="red")
            return False

    def manage_existing(self):
        """Gestiona pools/filesystems existentes"""
        pass
    
    def disk_tools(self):
        """Herramientas de disco"""
        pass
    
    def system_configuration(self):
        """Configuración del sistema"""
        pass

def main():
    """Función principal"""
    parser = argparse.ArgumentParser(description="RAID Manager para Raspberry Pi")
    parser.add_argument("--debug", action="store_true", help="Modo debug")
    parser.add_argument("--config", type=str, help="Archivo de configuración")
    
    args = parser.parse_args()
    
    # Verificar permisos
    if os.geteuid() == 0:
        print("❌ No ejecutes este script como root. Usa sudo cuando sea necesario.")
        sys.exit(1)
    
    try:
        raid_manager = RAIDManager()
        raid_manager.main_menu()
    except KeyboardInterrupt:
        print("\n👋 Script interrumpido por el usuario")
        sys.exit(0)
    except Exception as e:
        print(f"❌ Error inesperado: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
