#!/bin/bash

# Test script for BTRFS fstab cleanup validation
echo "=== Testing BTRFS fstab cleanup ==="

# Current fstab content
echo "Current /etc/fstab content:"
cat /etc/fstab
echo ""

# Test UUID detection
btrfs_uuid=$(sudo btrfs filesystem show /dev/sdc 2>/dev/null | grep "uuid:" | awk '{print $4}')
echo "Detected BTRFS UUID: $btrfs_uuid"

# Test what entries would be found
echo "BTRFS entries that would be found in fstab:"
grep -E "UUID=$btrfs_uuid" /etc/fstab 2>/dev/null | grep -i btrfs || echo "  (none found)"

# Test device entries
echo "Device-based entries that would be found:"
for device in sdc sdd sde sdf; do
    device_entries=$(grep -E "/dev/$device" /etc/fstab 2>/dev/null | grep -i btrfs || true)
    if [ -n "$device_entries" ]; then
        echo "  /dev/$device: $device_entries"
    else
        echo "  /dev/$device: (none found)"
    fi
done

echo ""
echo "Array information:"
sudo btrfs filesystem show /dev/sdc 2>/dev/null

echo ""
echo "=== Test completed ==="
