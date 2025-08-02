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
                   capture_output: bool = True, show_errors: bool = False) -> subprocess.CompletedProcess:
        """Ejecuta un comando del sistema"""
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
    
    def is_root(self) -> bool:
        """Verifica si el script se ejecuta como root"""
        return os.geteuid() == 0
    
    def check_sudo(self) -> bool:
        """Verifica disponibilidad de sudo"""
        try:
            self.run_command(['sudo', '-n', 'true'])
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
                
            # Otros puntos de montaje críticos
            for mount_point in ['/boot', '/usr', '/var']:
                try:
                    result = self.system.run_command(['findmnt', '-n', '-o', 'SOURCE', mount_point])
                    device = result.stdout.strip()
                    if device:
                        disk_name = device.split('/')[-1].rstrip('0123456789')
                        system_disks.add(disk_name)
                except subprocess.CalledProcessError:
                    continue
                    
        except Exception as e:
            self.console.print(f"⚠️  Error detectando discos del sistema: {e}", style="yellow")
            
        return system_disks
    
    def _parse_disk_info(self, device: dict, system_disks: set) -> Optional[Disk]:
        """Parsea información de un disco desde lsblk"""
        name = device['name']
        
        # Saltar si es disco del sistema
        if name in system_disks:
            return None
            
        # Convertir tamaño a bytes
        size_str = device['size']
        size_bytes = self._parse_size(size_str)
        
        # Información del disco
        model = device.get('model', 'Desconocido')
        serial = device.get('serial', 'Desconocido')
        sector_size = int(device.get('phy-sec', 512))
        
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
        
        return Disk(
            name=name,
            size=size_bytes,
            model=model,
            serial=serial,
            sector_size=sector_size,
            has_partitions=has_partitions,
            filesystem_type=filesystem_type,
            mount_points=mount_points
        )
    
    def _parse_size(self, size_str: str) -> int:
        """Convierte string de tamaño a bytes"""
        if not size_str:
            return 0
            
        size_str = size_str.upper()
        multipliers = {
            'B': 1,
            'K': 1024,
            'M': 1024**2,
            'G': 1024**3,
            'T': 1024**4
        }
        
        for suffix, multiplier in multipliers.items():
            if size_str.endswith(suffix):
                try:
                    number = float(size_str[:-1])
                    return int(number * multiplier)
                except ValueError:
                    break
        
        # Sin sufijo, asumir bytes
        try:
            return int(size_str)
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
        
        # Detectar discos disponibles
        disks = self.disk_manager.detect_disks()
        available_disks = [d for d in disks if not d.is_system and not d.has_partitions]
        
        if not available_disks:
            self.console.print("❌ No hay discos disponibles para RAID", style="red")
            return
        
        # Mostrar discos disponibles
        self._show_available_disks(available_disks)
        
        # Seleccionar tipo de filesystem
        fs_type = self._select_filesystem_type()
        
        # Seleccionar discos
        selected_disks = self._select_disks(available_disks)
        
        # Seleccionar tipo de RAID
        raid_type = self._select_raid_type(fs_type, len(selected_disks))
        
        # Configuración final
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
        # Implementar lógica de selección de discos
        pass
    
    def _select_raid_type(self, fs_type: FilesystemType, disk_count: int) -> RAIDType:
        """Selecciona tipo de RAID según filesystem y número de discos"""
        # Implementar lógica de selección de RAID
        pass
    
    def _configure_raid(self, fs_type: FilesystemType, raid_type: RAIDType, disks: List[Disk]):
        """Configura el RAID con los parámetros seleccionados"""
        # Implementar configuración de RAID
        pass
    
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
