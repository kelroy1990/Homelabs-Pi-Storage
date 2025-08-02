#!/bin/bash

echo "=== ZFS Cache Diagnostic Tool ==="
echo "Date: $(date)"
echo ""

echo "📊 SYSTEM INFORMATION:"
echo "   ZFS Version: $(zfs version 2>/dev/null | head -n 1 || echo "Not available")"
echo "   Kernel: $(uname -r)"
echo ""

echo "🏊 ZFS POOLS:"
zpool list 2>/dev/null || echo "   No pools found"
echo ""

echo "📀 SDA PARTITION INFORMATION:"
if [ -b "/dev/sda" ]; then
    echo "   Device: /dev/sda"
    echo "   Size: $(lsblk -dno SIZE /dev/sda 2>/dev/null)"
    echo "   Sector size (logical): $(sudo blockdev --getss /dev/sda 2>/dev/null) bytes"
    echo "   Sector size (physical): $(sudo blockdev --getpbsz /dev/sda 2>/dev/null) bytes"
    echo ""
    
    echo "   Partitions:"
    lsblk /dev/sda 2>/dev/null || echo "   Cannot read partitions"
    echo ""
    
    if [ -b "/dev/sda1" ]; then
        echo "   sda1 info:"
        echo "     Size: $(lsblk -dno SIZE /dev/sda1 2>/dev/null)"
        echo "     Sector (logical): $(sudo blockdev --getss /dev/sda1 2>/dev/null) bytes"
        echo "     Sector (physical): $(sudo blockdev --getpbsz /dev/sda1 2>/dev/null) bytes"
        echo "     Filesystem: $(lsblk -no FSTYPE /dev/sda1 2>/dev/null || echo "none")"
    fi
    
    if [ -b "/dev/sda2" ]; then
        echo "   sda2 info:"
        echo "     Size: $(lsblk -dno SIZE /dev/sda2 2>/dev/null)"
        echo "     Sector (logical): $(sudo blockdev --getss /dev/sda2 2>/dev/null) bytes"
        echo "     Sector (physical): $(sudo blockdev --getpbsz /dev/sda2 2>/dev/null) bytes"
        echo "     Filesystem: $(lsblk -no FSTYPE /dev/sda2 2>/dev/null || echo "none")"
    fi
else
    echo "   /dev/sda not found"
fi
echo ""

echo "🏊 POOL DETAILS (if available):"
for pool in $(zpool list -H -o name 2>/dev/null); do
    echo "   Pool: $pool"
    echo "     Health: $(zpool get health "$pool" -H -o value 2>/dev/null)"
    echo "     Ashift: $(zpool get ashift "$pool" -H -o value 2>/dev/null)"
    echo "     Version: $(zpool get version "$pool" -H -o value 2>/dev/null)"
    
    # Get main pool devices
    echo "     Main devices:"
    zpool status "$pool" | grep -E "^\s+[a-z]" | awk '{print $1}' | grep -v "cache\|log\|spare" | while read device; do
        if [ -b "/dev/$device" ]; then
            sector=$(sudo blockdev --getpbsz "/dev/$device" 2>/dev/null)
            echo "       $device: $sector bytes sector"
        fi
    done
    echo ""
done

echo "🔧 SUGGESTED TESTS:"
echo "   1. Check if partitions can be read:"
echo "      sudo dd if=/dev/sda1 of=/dev/null bs=1M count=1"
echo "      sudo dd if=/dev/sda2 of=/dev/null bs=1M count=1"
echo ""
echo "   2. Test ZFS add command manually:"
echo "      sudo zpool add [pool_name] cache /dev/sda1"
echo "      sudo zpool add [pool_name] log /dev/sda2"
echo ""
echo "   3. Force add if sector mismatch:"
echo "      sudo zpool add -f [pool_name] cache /dev/sda1"
echo "      sudo zpool add -f [pool_name] log /dev/sda2"
echo ""
echo "   4. RECOMMENDED: Recreate pool with proper ashift:"
echo "      The current pool has ashift=0 which causes compatibility issues."
echo "      For new pools, the script now automatically sets ashift=12 (4096 bytes)"
echo "      which is optimal for modern disks and cache devices."

echo ""
echo "=== Diagnostic completed ==="
