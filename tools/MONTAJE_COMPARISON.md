# Diferencias de Montaje: ZFS vs BTRFS

## 🔷 ZFS - Sistema de Montaje Automático

### Características principales:
- **NO requiere** entradas en `/etc/fstab`
- **Sistema integrado** de gestión de montaje
- **Montaje automático** al arranque del sistema
- **Persistencia** de configuración en metadatos del pool

### Configuración:
```bash
# ZFS maneja automáticamente el montaje
zfs set mountpoint=/storage tank/data
zfs set canmount=on tank/data

# Los pools se importan automáticamente
systemctl enable zfs-import-cache.service
systemctl enable zfs-mount.service
systemctl enable zfs.target
```

### Comandos útiles:
```bash
# Ver puntos de montaje
zfs get mountpoint

# Cambiar punto de montaje
zfs set mountpoint=/nueva/ruta pool/dataset

# Montar manualmente
zfs mount pool/dataset

# Desmontar
zfs unmount pool/dataset
```

## 🌿 BTRFS - Sistema de Montaje Tradicional

### Características principales:
- **SÍ requiere** entradas en `/etc/fstab`
- **Montaje tradicional** del sistema Linux
- **UUID obligatorio** para identificación
- **Opciones de montaje** en fstab

### Configuración en /etc/fstab:
```bash
# Ejemplo de entrada fstab para BTRFS RAID
UUID=12345678-1234-1234-1234-123456789abc /storage btrfs defaults,compress=zstd,noatime,space_cache=v2 0 2
```

### Opciones recomendadas:
- `compress=zstd` - Compresión moderna y eficiente
- `noatime` - Mejor rendimiento (no actualiza tiempo de acceso)
- `space_cache=v2` - Cache de espacio libre v2
- `defaults` - Opciones estándar de montaje

### Comandos útiles:
```bash
# Ver filesystems BTRFS
btrfs filesystem show

# Ver uso del espacio
btrfs filesystem usage /punto/montaje

# Montar manualmente
mount -t btrfs /dev/dispositivo /punto/montaje

# Ver subvolúmenes
btrfs subvolume list /punto/montaje
```

## 📋 Resumen de Diferencias

| Aspecto | ZFS | BTRFS |
|---------|-----|-------|
| **fstab** | ❌ No necesario | ✅ Obligatorio |
| **Servicios** | zfs-import-cache, zfs-mount | mount.btrfs (automático) |
| **Configuración** | Metadatos del pool | /etc/fstab |
| **UUID** | No requerido para montaje | Requerido en fstab |
| **Flexibilidad** | Alta (comandos zfs) | Media (opciones fstab) |
| **Persistencia** | Automática en pool | Manual en fstab |

## 🔧 Nuestro Sistema

### Implementación en raid_manager.py:

**Para ZFS:**
1. Habilita servicios del sistema (`zfs-import-cache`, `zfs-mount`, `zfs.target`)
2. Los pools se importan automáticamente al arranque
3. Los datasets se montan según su propiedad `mountpoint`
4. NO modifica `/etc/fstab`

**Para BTRFS:**
1. Obtiene UUID del filesystem
2. Configura punto de montaje (por defecto `/storage`)
3. Crea entrada optimizada en `/etc/fstab`
4. Hace backup de fstab antes de modificar
5. Prueba el montaje automático

### Ventajas de nuestro enfoque:
- ✅ Respeta las mejores prácticas de cada filesystem
- ✅ Configuración automática y robusta
- ✅ Backups de seguridad (fstab.backup)
- ✅ Validación de configuración
- ✅ Opciones optimizadas para cada sistema
