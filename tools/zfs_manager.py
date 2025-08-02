"""
ZFS Manager - Gestión específica de ZFS
"""

import subprocess
import json
import re
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass
from .config import DEFAULT_CONFIG


@dataclass
class ZFSPool:
    """Representa un pool ZFS"""
    name: str
    health: str
    size: int
    allocated: int
    free: int
    capacity: int
    dedup_ratio: float
    ashift: int
    devices: List[str]
    raid_type: str


@dataclass 
class ZFSDataset:
    """Representa un dataset ZFS"""
    name: str
    type: str
    used: int
    available: int
    referenced: int
    mountpoint: str
    compression: str
    readonly: bool


class ZFSManager:
    """Gestor de operaciones ZFS"""
    
    def __init__(self, system_manager, console):
        self.system = system_manager
        self.console = console
        self.zpool_cmd = DEFAULT_CONFIG["commands"]["zfs"]["zpool"]
        self.zfs_cmd = DEFAULT_CONFIG["commands"]["zfs"]["zfs"]
    
    def is_available(self) -> bool:
        """Verifica si ZFS está disponible"""
        try:
            self.system.run_command([self.zpool_cmd, 'list'], capture_output=True)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            return False
    
    def list_pools(self) -> List[ZFSPool]:
        """Lista todos los pools ZFS"""
        pools = []
        try:
            # Obtener información básica de pools
            result = self.system.run_command([
                self.zpool_cmd, 'list', '-H', '-p', '-o',
                'name,health,size,allocated,free,capacity,dedupratio'
            ])
            
            for line in result.stdout.strip().split('\n'):
                if line:
                    parts = line.split('\t')
                    if len(parts) >= 7:
                        pool_name = parts[0]
                        
                        # Obtener ashift y dispositivos
                        ashift, devices, raid_type = self._get_pool_details(pool_name)
                        
                        pool = ZFSPool(
                            name=pool_name,
                            health=parts[1],
                            size=int(parts[2]),
                            allocated=int(parts[3]),
                            free=int(parts[4]),
                            capacity=int(parts[5]),
                            dedup_ratio=float(parts[6].rstrip('x')),
                            ashift=ashift,
                            devices=devices,
                            raid_type=raid_type
                        )
                        pools.append(pool)
                        
        except subprocess.CalledProcessError as e:
            self.console.print(f"❌ Error listando pools ZFS: {e}", style="red")
            
        return pools
    
    def _get_pool_details(self, pool_name: str) -> Tuple[int, List[str], str]:
        """Obtiene detalles específicos de un pool"""
        ashift = 12  # Default
        devices = []
        raid_type = "unknown"
        
        try:
            # Obtener estado del pool
            result = self.system.run_command([self.zpool_cmd, 'status', pool_name])
            status_output = result.stdout
            
            # Extraer ashift
            ashift_match = re.search(r'ashift=(\d+)', status_output)
            if ashift_match:
                ashift = int(ashift_match.group(1))
            
            # Extraer dispositivos y tipo de RAID
            lines = status_output.split('\n')
            in_config = False
            current_vdev_type = None
            
            for line in lines:
                line = line.strip()
                
                if 'config:' in line.lower():
                    in_config = True
                    continue
                
                if in_config and line and not line.startswith('NAME'):
                    if not line.startswith('\t') and not line.startswith(' '):
                        # Es el nombre del pool
                        continue
                    
                    # Detectar tipo de vdev
                    if any(x in line for x in ['mirror', 'raidz1', 'raidz2', 'raidz3']):
                        if 'mirror' in line:
                            current_vdev_type = 'mirror'
                            raid_type = 'mirror'
                        elif 'raidz3' in line:
                            current_vdev_type = 'raidz3'
                            raid_type = 'raidz3'
                        elif 'raidz2' in line:
                            current_vdev_type = 'raidz2'
                            raid_type = 'raidz2'
                        elif 'raidz1' in line or 'raidz' in line:
                            current_vdev_type = 'raidz1'
                            raid_type = 'raidz1'
                    else:
                        # Es un dispositivo
                        device_match = re.search(r'(sd[a-z]+|nvme\d+n\d+)', line)
                        if device_match:
                            devices.append(device_match.group(1))
                            if raid_type == "unknown":
                                raid_type = "stripe"  # Si no hay vdev específico, es stripe
                        
        except subprocess.CalledProcessError:
            pass
            
        return ashift, devices, raid_type
    
    def list_datasets(self, pool_name: Optional[str] = None) -> List[ZFSDataset]:
        """Lista datasets ZFS"""
        datasets = []
        try:
            cmd = [
                self.zfs_cmd, 'list', '-H', '-p', '-o',
                'name,type,used,available,referenced,mountpoint,compression,readonly'
            ]
            
            if pool_name:
                cmd.append(pool_name)
            
            result = self.system.run_command(cmd)
            
            for line in result.stdout.strip().split('\n'):
                if line:
                    parts = line.split('\t')
                    if len(parts) >= 8:
                        dataset = ZFSDataset(
                            name=parts[0],
                            type=parts[1],
                            used=int(parts[2]),
                            available=int(parts[3]),
                            referenced=int(parts[4]),
                            mountpoint=parts[5],
                            compression=parts[6],
                            readonly=parts[7] == 'on'
                        )
                        datasets.append(dataset)
                        
        except subprocess.CalledProcessError as e:
            self.console.print(f"❌ Error listando datasets: {e}", style="red")
            
        return datasets
    
    def create_pool(self, name: str, raid_type: str, devices: List[str], 
                   ashift: Optional[int] = None, force: bool = False) -> bool:
        """Crea un nuevo pool ZFS"""
        try:
            self.console.print(f"🏗️  Creando pool ZFS '{name}' con tipo {raid_type}...")
            
            # Construir comando
            cmd = [self.zpool_cmd, 'create']
            
            if force:
                cmd.append('-f')
            
            # Ashift
            if ashift:
                cmd.extend(['-o', f'ashift={ashift}'])
            
            cmd.append(name)
            
            # Tipo de RAID y dispositivos
            if raid_type == 'mirror':
                cmd.append('mirror')
            elif raid_type in ['raidz1', 'raidz2', 'raidz3']:
                cmd.append(raid_type.replace('1', '').replace('2', '2').replace('3', '3'))
            
            # Agregar dispositivos
            for device in devices:
                cmd.append(f'/dev/{device}')
            
            self.system.run_command(cmd)
            self.console.print(f"✅ Pool '{name}' creado exitosamente", style="green")
            return True
            
        except subprocess.CalledProcessError as e:
            self.console.print(f"❌ Error creando pool: {e}", style="red")
            return False
    
    def destroy_pool(self, name: str, force: bool = False) -> bool:
        """Destruye un pool ZFS"""
        try:
            cmd = [self.zpool_cmd, 'destroy']
            if force:
                cmd.append('-f')
            cmd.append(name)
            
            self.system.run_command(cmd)
            self.console.print(f"✅ Pool '{name}' eliminado", style="green")
            return True
            
        except subprocess.CalledProcessError as e:
            self.console.print(f"❌ Error eliminando pool: {e}", style="red")
            return False
    
    def create_dataset(self, name: str, mountpoint: Optional[str] = None,
                      properties: Optional[Dict[str, str]] = None) -> bool:
        """Crea un dataset ZFS"""
        try:
            cmd = [self.zfs_cmd, 'create']
            
            # Propiedades
            if properties:
                for key, value in properties.items():
                    cmd.extend(['-o', f'{key}={value}'])
            
            # Mountpoint
            if mountpoint:
                cmd.extend(['-o', f'mountpoint={mountpoint}'])
            
            cmd.append(name)
            
            self.system.run_command(cmd)
            self.console.print(f"✅ Dataset '{name}' creado", style="green")
            return True
            
        except subprocess.CalledProcessError as e:
            self.console.print(f"❌ Error creando dataset: {e}", style="red")
            return False
    
    def add_cache_device(self, pool_name: str, device: str, device_type: str = 'cache') -> bool:
        """Agrega dispositivo de cache (L2ARC) o log (SLOG) a un pool"""
        try:
            cmd = [self.zpool_cmd, 'add', pool_name]
            
            if device_type == 'log':
                cmd.append('log')
            elif device_type == 'cache':
                cmd.append('cache')
            
            cmd.append(f'/dev/{device}')
            
            self.system.run_command(cmd)
            self.console.print(f"✅ Dispositivo {device_type} agregado al pool", style="green")
            return True
            
        except subprocess.CalledProcessError as e:
            self.console.print(f"❌ Error agregando dispositivo: {e}", style="red")
            return False
    
    def get_pool_io_stats(self, pool_name: str) -> Dict:
        """Obtiene estadísticas de I/O de un pool"""
        stats = {}
        try:
            result = self.system.run_command([self.zpool_cmd, 'iostat', '-v', pool_name])
            # Parsear output de iostat
            # TODO: Implementar parsing completo
            stats['raw_output'] = result.stdout
            
        except subprocess.CalledProcessError:
            pass
            
        return stats
    
    def scrub_pool(self, pool_name: str) -> bool:
        """Inicia scrub en un pool"""
        try:
            self.system.run_command([self.zpool_cmd, 'scrub', pool_name])
            self.console.print(f"✅ Scrub iniciado en pool '{pool_name}'", style="green")
            return True
            
        except subprocess.CalledProcessError as e:
            self.console.print(f"❌ Error iniciando scrub: {e}", style="red")
            return False
    
    def calculate_optimal_ashift(self, devices: List[str]) -> int:
        """Calcula el ashift óptimo basado en los dispositivos"""
        max_sector_size = 512
        
        for device in devices:
            try:
                # Obtener tamaño de sector físico
                result = self.system.run_command([
                    'lsblk', '-dno', 'PHY-SEC', f'/dev/{device}'
                ])
                sector_size = int(result.stdout.strip())
                max_sector_size = max(max_sector_size, sector_size)
                
            except (subprocess.CalledProcessError, ValueError):
                continue
        
        # Calcular ashift basado en tamaño de sector
        # Siempre usar mínimo 12 (4K) para compatibilidad con SSDs
        if max_sector_size <= 512:
            return 12  # 4K para compatibilidad
        elif max_sector_size <= 4096:
            return 12  # 4K
        elif max_sector_size <= 8192:
            return 13  # 8K
        else:
            return 14  # 16K
