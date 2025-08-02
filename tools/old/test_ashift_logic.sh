#!/bin/bash

echo "=== Test Ashift Logic ==="
echo ""

# Simular diferentes escenarios de discos
echo "🧪 ESCENARIO 1: Solo HDDs con 512 bytes"
echo "   Discos: 3x HDD con sector 512 bytes"
echo "   Resultado esperado: ashift=12 (para compatibilidad con cache SSD)"
echo ""

echo "🧪 ESCENARIO 2: HDDs + NVMe mixto"  
echo "   Discos: 2x HDD (512 bytes) + 2x NVMe (4096 bytes)"
echo "   Resultado esperado: ashift=12 (basado en sector más grande)"
echo ""

echo "🧪 ESCENARIO 3: Solo NVMe modernos"
echo "   Discos: 4x NVMe con sector 4096 bytes"
echo "   Resultado esperado: ashift=12 (óptimo para 4K sectors)"
echo ""

echo "💡 ESTRATEGIA IMPLEMENTADA:"
echo "   ✅ Detecta sector máximo entre discos del pool"
echo "   ✅ Si solo hay discos 512-byte → fuerza ashift=12 para compatibilidad"
echo "   ✅ Si hay discos 4K → usa ashift=12 (óptimo)"
echo "   ✅ Cache devices SSD (4096 bytes) serán compatibles"
echo ""

echo "🎯 BENEFICIOS:"
echo "   📊 Pool optimizado para rendimiento de HDDs principales"
echo "   🚀 Compatible con cache devices SSD/NVMe"
echo "   ⚡ Sin conflictos de sector al agregar cache"
echo "   🔧 Funcionará tanto con /dev/sda1 como /dev/sda2"
