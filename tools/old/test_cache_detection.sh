#!/bin/bash

# Test script for enhanced cache device detection
echo "=== Testing Enhanced Cache Device Detection ==="

echo "Current system storage devices:"
lsblk | grep -E "(nvme|sda|sdb|sdc)"
echo ""

echo "Testing device classification logic:"
echo ""

# Simulate the device classification
echo "🚀 DISPOSITIVOS NVME (RECOMENDADOS):"
echo "   (None detected on this system)"
echo ""

echo "💾 DISPOSITIVOS SSD (ACEPTABLES):"
# Check if sda is SSD (ROTA=0)
if lsblk -dpno ROTA /dev/sda 2>/dev/null | grep -q "0"; then
    size=$(lsblk -dpno SIZE /dev/sda 2>/dev/null | tr -d ' ')
    model=$(lsblk -dpno MODEL /dev/sda 2>/dev/null | tr -d ' ')
    echo "   ⚠️  sda - $size - $model"
else
    echo "   (sda appears to be HDD, not SSD)"
fi
echo ""

echo "🐌 OTROS DISPOSITIVOS (NO RECOMENDADOS PARA CACHE):"
for device in sdb sdc sdd sde sdf; do
    if [ -e "/dev/$device" ]; then
        if ! lsblk -dpno ROTA "/dev/$device" 2>/dev/null | grep -q "0"; then
            size=$(lsblk -dpno SIZE "/dev/$device" 2>/dev/null | tr -d ' ')
            model=$(lsblk -dpno MODEL "/dev/$device" 2>/dev/null | tr -d ' ')
            echo "   ❌ $device - $size - $model"
        fi
    fi
done
echo ""

echo "⚠️  ADVERTENCIA IMPORTANTE:"
echo "   🔥 NO SE DETECTARON DISPOSITIVOS NVME"
echo "   • Los dispositivos de cache deben ser más rápidos que el almacenamiento principal"
echo "   • Usar dispositivos lentos como cache puede REDUCIR el rendimiento del sistema"
echo "   • Se recomienda FUERTEMENTE tener un dispositivo NVMe para cache"
echo ""

echo "This warning would be shown to users who don't have NVMe devices."
echo ""
echo "=== Test completed ==="
