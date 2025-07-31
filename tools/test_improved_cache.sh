#!/bin/bash

echo "=== Testing Improved Cache Device Detection ==="
echo ""

echo "All detected block devices:"
lsblk -dpno NAME,SIZE,MODEL,ROTA | grep -v "^/dev/loop"
echo ""

echo "Testing device filtering logic:"
echo ""

# Simulate the filtering logic
while IFS= read -r disk; do
    disk_name=$(basename "$disk")
    
    echo "Processing: $disk_name"
    
    # Check exclusions
    if [[ "$disk_name" == "mmcblk0"* ]] || [[ "$disk_name" == *"boot"* ]]; then
        echo "  ❌ Excluded: Boot device"
        continue
    fi
    
    # Check size
    size_raw=$(lsblk -dpno SIZE "/dev/$disk_name" 2>/dev/null | tr -d ' ')
    if [[ "$size_raw" == "0B" ]] || [[ -z "$size_raw" ]]; then
        echo "  ❌ Excluded: Zero size ($size_raw)"
        continue
    fi
    
    # Check mount points
    mount_check=$(lsblk -no MOUNTPOINT "/dev/$disk_name" 2>/dev/null | grep -E "^/$|^/boot|^/home")
    if [ -n "$mount_check" ]; then
        echo "  ❌ Excluded: System mount point ($mount_check)"
        continue
    fi
    
    # Check rotation (SSD vs HDD)
    if lsblk -dpno ROTA "/dev/$disk_name" 2>/dev/null | grep -q "0"; then
        device_type="SSD"
    else
        device_type="HDD"
    fi
    
    model=$(lsblk -dpno MODEL "/dev/$disk_name" 2>/dev/null | tr -d ' ')
    echo "  ✅ Available: $disk_name - $size_raw - $model ($device_type)"
    
done < <(lsblk -dpno NAME | grep -v "^/dev/loop")

echo ""
echo "=== Test completed ==="
