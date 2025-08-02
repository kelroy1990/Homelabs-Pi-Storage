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
        
        log_handlers.append(logging.StreamHandler())
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=log_handlers
        )
        return logging.getLogger(__name__)
    
    def run_command(self, command: List[str], check: bool = True, 
                   capture_output: bool = True) -> subprocess.CompletedProcess:
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
        
        # Detectar pools ZFS
        self._detect_zfs_pools()
        
        # Detectar filesystems BTRFS
        self._detect_btrfs_filesystems()
        
        # Detectar arrays MDADM
        self._detect_mdadm_arrays()
    
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
            result = self.system.run_command(['zpool', 'list', '-H'])
            if result.stdout.strip():
                self.console.print("🏊 Pools ZFS encontrados:", style="green")
                # Parsear y mostrar pools
            else:
                self.console.print("ℹ️  No se encontraron pools ZFS", style="yellow")
        except subprocess.CalledProcessError:
            self.console.print("ℹ️  ZFS no disponible", style="yellow")
    
    def _detect_btrfs_filesystems(self):
        """Detecta filesystems BTRFS existentes"""
        try:
            result = self.system.run_command(['btrfs', 'filesystem', 'show'])
            if result.stdout.strip():
                self.console.print("🌳 Filesystems BTRFS encontrados:", style="green")
                # Parsear y mostrar filesystems
            else:
                self.console.print("ℹ️  No se encontraron filesystems BTRFS", style="yellow")
        except subprocess.CalledProcessError:
            self.console.print("ℹ️  BTRFS no disponible", style="yellow")
    
    def _detect_mdadm_arrays(self):
        """Detecta arrays MDADM existentes"""
        try:
            result = self.system.run_command(['cat', '/proc/mdstat'])
            # Parsear /proc/mdstat
            self.console.print("ℹ️  Verificando arrays MDADM...", style="blue")
        except subprocess.CalledProcessError:
            self.console.print("ℹ️  MDADM no disponible", style="yellow")
    
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
