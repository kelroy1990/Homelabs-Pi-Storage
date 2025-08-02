#!/bin/bash

# Simple test for BTRFS detection
test_btrfs_detection() {
    local disk="$1"
    
    echo "Testing disk: $disk"
    
    # Verificar BTRFS - Mejorado para detectar arrays multi-disco
    if command -v btrfs &> /dev/null; then
        # Primero verificar si el disco tiene un filesystem BTRFS
        if sudo btrfs filesystem show "/dev/$disk" 2>/dev/null | grep -q "uuid:"; then
            local btrfs_uuid=$(sudo btrfs filesystem show "/dev/$disk" 2>/dev/null | grep "uuid:" | awk '{print $4}')
            local btrfs_label=$(sudo btrfs filesystem show "/dev/$disk" 2>/dev/null | grep "Label:" | awk '{print $2}')
            
            # Obtener información detallada del array BTRFS
            local btrfs_info=$(sudo btrfs filesystem show "/dev/$disk" 2>/dev/null)
            local total_devices=$(echo "$btrfs_info" | grep "Total devices" | awk '{print $3}')
            local device_list=$(echo "$btrfs_info" | grep "devid" | awk '{print $NF}' | sed 's|/dev/||' | tr '\n' ',' | sed 's/,$//')
            
            # Obtener el punto de montaje si existe
            local mount_point=$(mount | grep "/dev/$disk" | awk '{print $3}' | head -1)
            
            # Intentar obtener el tipo de RAID si está montado
            local raid_profile=""
            if [ -n "$mount_point" ]; then
                raid_profile=$(sudo btrfs filesystem usage "$mount_point" 2>/dev/null | grep "Data," | head -1 | awk -F',' '{print $1}' | sed 's/Data,//')
                if [ -z "$raid_profile" ]; then
                    raid_profile="single"
                fi
            fi
            
            # Construir información del RAID
            if [ "$total_devices" -gt 1 ]; then
                if [ -n "$mount_point" ]; then
                    echo "Result: BTRFS RAID ($raid_profile, $total_devices discos: $device_list) - Montado en: $mount_point"
                else
                    echo "Result: BTRFS RAID ($total_devices discos: $device_list)"
                fi
            else
                if [ -n "$mount_point" ]; then
                    echo "Result: BTRFS (Single disk) - Montado en: $mount_point"
                else
                    echo "Result: BTRFS (Single disk)"
                fi
            fi
        else
            echo "Result: No BTRFS detected"
        fi
    fi
    echo ""
}

# Test all disks
for disk in sdc sdd sde sdf; do
    test_btrfs_detection "$disk"
done
