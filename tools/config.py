"""
Configuración para RAID Manager
"""

# Configuración por defecto
DEFAULT_CONFIG = {
    "language": "es",
    "log_level": "INFO",
    "log_file": "/var/log/raid_manager.log",
    
    # Configuración ZFS
    "zfs": {
        "default_ashift": 12,
        "arc_max_percent": 50,  # Porcentaje máximo de RAM para ARC
        "compression": "lz4",
        "atime": "off",
        "cache_devices": {
            "l2arc_size_mb": 1024,
            "slog_size_mb": 512
        }
    },
    
    # Configuración BTRFS
    "btrfs": {
        "default_compress": "zstd",
        "autodefrag": True,
        "space_cache": "v2"
    },
    
    # Discos a excluir (del sistema)
    "exclude_disks": [
        "mmcblk0",  # SD card típica de RPi
        "loop*",    # Dispositivos loop
        "sr*",      # CD/DVD
        "ram*"      # RAM disks
    ],
    
    # Tamaños mínimos recomendados
    "min_sizes": {
        "raid_disk_gb": 1,      # Mínimo 1GB para RAID
        "cache_device_gb": 0.1, # Mínimo 100MB para cache
        "slog_device_mb": 100   # Mínimo 100MB para SLOG
    },
    
    # Comandos del sistema
    "commands": {
        "zfs": {
            "zpool": "/usr/sbin/zpool",
            "zfs": "/usr/sbin/zfs"
        },
        "btrfs": {
            "btrfs": "/usr/bin/btrfs",
            "mkfs.btrfs": "/usr/bin/mkfs.btrfs"
        },
        "system": {
            "lsblk": "/usr/bin/lsblk",
            "wipefs": "/usr/sbin/wipefs",
            "sgdisk": "/usr/sbin/sgdisk",
            "partprobe": "/usr/sbin/partprobe"
        }
    }
}

# Mensajes de la interfaz
MESSAGES = {
    "title": "🏠 RAID Manager para Raspberry Pi",
    "subtitle": "Gestión avanzada de almacenamiento - Versión Python",
    
    "menus": {
        "main": {
            "title": "📋 OPCIONES PRINCIPALES",
            "options": [
                "1. Detectar configuraciones RAID existentes",
                "2. Crear nueva configuración RAID", 
                "3. Gestionar pools/filesystems existentes",
                "4. Herramientas de disco",
                "5. Configuración del sistema",
                "0. Salir"
            ]
        },
        "filesystem": {
            "title": "📁 Tipo de filesystem",
            "options": [
                "1. ZFS (recomendado para máxima funcionalidad)",
                "2. BTRFS (alternativa moderna)"
            ]
        },
        "raid_zfs": {
            "title": "⚡ Tipo de RAID ZFS",
            "options": [
                "1. Stripe (RAID 0) - Máximo rendimiento, sin redundancia",
                "2. Mirror (RAID 1) - Redundancia completa",
                "3. RAIDZ1 (similar RAID 5) - 1 disco de paridad",
                "4. RAIDZ2 (similar RAID 6) - 2 discos de paridad", 
                "5. RAIDZ3 - 3 discos de paridad (máxima seguridad)"
            ]
        }
    },
    
    "status": {
        "detecting_disks": "🔍 Detectando discos disponibles...",
        "detecting_raid": "🔍 Detectando configuraciones RAID existentes...",
        "creating_pool": "🏗️  Creando pool...",
        "cleaning_disks": "🧹 Limpiando discos...",
        "success": "✅ Operación completada exitosamente",
        "error": "❌ Error en la operación",
        "warning": "⚠️  Advertencia",
        "info": "ℹ️  Información"
    },
    
    "errors": {
        "no_disks": "No hay discos disponibles para RAID",
        "insufficient_disks": "Discos insuficientes para el tipo de RAID seleccionado",
        "command_failed": "Error ejecutando comando",
        "permission_denied": "Permisos insuficientes",
        "disk_in_use": "El disco está en uso",
        "pool_exists": "Ya existe un pool con ese nombre"
    },
    
    "confirmations": {
        "delete_pool": "⚠️  ¿Estás seguro de eliminar el pool? Esta acción es IRREVERSIBLE",
        "clean_disk": "⚠️  ¿Limpiar el disco? Se perderán todos los datos",
        "create_raid": "✅ ¿Crear la configuración RAID con los parámetros seleccionados?",
        "continue": "¿Continuar?"
    }
}

# Información sobre tipos de RAID
RAID_INFO = {
    "zfs": {
        "stripe": {
            "min_disks": 1,
            "description": "Combina discos para máximo rendimiento. SIN redundancia.",
            "use_case": "Ideal para: datos temporales, máximo rendimiento",
            "fault_tolerance": 0
        },
        "mirror": {
            "min_disks": 2,
            "description": "Duplica datos en todos los discos. Máxima redundancia.",
            "use_case": "Ideal para: datos críticos, máxima seguridad",
            "fault_tolerance": "n-1 discos"
        },
        "raidz1": {
            "min_disks": 3,
            "description": "Similar a RAID 5. Tolera falla de 1 disco.",
            "use_case": "Ideal para: balance rendimiento/seguridad",
            "fault_tolerance": 1
        },
        "raidz2": {
            "min_disks": 4,
            "description": "Similar a RAID 6. Tolera falla de 2 discos.",
            "use_case": "Ideal para: alta seguridad con buen rendimiento",
            "fault_tolerance": 2
        },
        "raidz3": {
            "min_disks": 5,
            "description": "Tolera falla de 3 discos. Máxima seguridad.",
            "use_case": "Ideal para: datos ultra-críticos",
            "fault_tolerance": 3
        }
    },
    "btrfs": {
        "raid0": {
            "min_disks": 2,
            "description": "Stripe. Máximo rendimiento, sin redundancia.",
            "use_case": "Ideal para: datos temporales",
            "fault_tolerance": 0
        },
        "raid1": {
            "min_disks": 2,
            "description": "Mirror. Duplica datos entre discos.",
            "use_case": "Ideal para: datos importantes",
            "fault_tolerance": "50% de discos"
        },
        "raid10": {
            "min_disks": 4,
            "description": "Combina mirror + stripe. Balance óptimo.",
            "use_case": "Ideal para: alta performance + seguridad",
            "fault_tolerance": "1 disco por par"
        }
    }
}
