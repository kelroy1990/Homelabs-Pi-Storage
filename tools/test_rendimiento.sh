#!/bin/bash

echo "🚀 TESTS DE RENDIMIENTO ZFS CON L2ARC"
echo "====================================="

# Función para mostrar pools disponibles
show_available_pools() {
    echo "📁 POOLS ZFS DISPONIBLES:"
    echo "========================"
    local pools=$(zpool list -H -o name 2>/dev/null)
    if [ -z "$pools" ]; then
        echo "❌ No se encontraron pools ZFS"
        exit 1
    fi
    
    local i=1
    for pool in $pools; do
        local health=$(zpool list -H -o health "$pool" 2>/dev/null)
        local size=$(zpool list -H -o size "$pool" 2>/dev/null)
        local free=$(zpool list -H -o free "$pool" 2>/dev/null)
        echo "  $i. $pool (Estado: $health, Tamaño: $size, Libre: $free)"
        ((i++))
    done
    echo ""
}

# Función para mostrar datasets de un pool
show_available_datasets() {
    local pool="$1"
    echo "📂 DATASETS DISPONIBLES EN '$pool':"
    echo "=================================="
    local datasets=$(zfs list -H -o name -r "$pool" 2>/dev/null)
    if [ -z "$datasets" ]; then
        echo "❌ No se encontraron datasets en el pool '$pool'"
        return 1
    fi
    
    local i=1
    for dataset in $datasets; do
        local mountpoint=$(zfs get -H -o value mountpoint "$dataset" 2>/dev/null)
        local avail=$(zfs get -H -o value available "$dataset" 2>/dev/null)
        echo "  $i. $dataset (Montado en: $mountpoint, Disponible: $avail)"
        ((i++))
    done
    echo ""
}

# Seleccionar pool
show_available_pools
pools_array=($(zpool list -H -o name 2>/dev/null))
while true; do
    read -p "👉 Selecciona el pool para el test (1-${#pools_array[@]}): " pool_choice
    if [[ "$pool_choice" =~ ^[0-9]+$ ]] && [ "$pool_choice" -ge 1 ] && [ "$pool_choice" -le ${#pools_array[@]} ]; then
        POOL_NAME="${pools_array[$((pool_choice-1))]}"
        break
    else
        echo "❌ Selección inválida. Usa números del 1 al ${#pools_array[@]}."
    fi
done

echo ""
echo "✅ Pool seleccionado: $POOL_NAME"

# Seleccionar dataset (opcional)
echo ""
read -p "¿Quieres probar en un dataset específico o en el pool raíz? (d=dataset/r=raíz): " dataset_choice
if [[ "$dataset_choice" =~ ^[Dd]$ ]]; then
    show_available_datasets "$POOL_NAME"
    datasets_array=($(zfs list -H -o name -r "$POOL_NAME" 2>/dev/null))
    while true; do
        read -p "👉 Selecciona el dataset (1-${#datasets_array[@]}): " ds_choice
        if [[ "$ds_choice" =~ ^[0-9]+$ ]] && [ "$ds_choice" -ge 1 ] && [ "$ds_choice" -le ${#datasets_array[@]} ]; then
            TARGET_DATASET="${datasets_array[$((ds_choice-1))]}"
            POOL_PATH=$(zfs get -H -o value mountpoint "$TARGET_DATASET" 2>/dev/null)
            break
        else
            echo "❌ Selección inválida. Usa números del 1 al ${#datasets_array[@]}."
        fi
    done
    echo "✅ Dataset seleccionado: $TARGET_DATASET"
else
    TARGET_DATASET="$POOL_NAME"
    POOL_PATH=$(zfs get -H -o value mountpoint "$POOL_NAME" 2>/dev/null || echo "/$POOL_NAME")
fi

# Solicitar tamaño de test
echo ""
echo "📏 CONFIGURACIÓN DEL TAMAÑO DE TEST:"
echo "===================================="
available_space=$(zfs get -H -o value available "$TARGET_DATASET" 2>/dev/null | sed 's/[KMGT]//' | cut -d. -f1)
echo "💾 Espacio disponible en '$TARGET_DATASET': $(zfs get -H -o value available "$TARGET_DATASET" 2>/dev/null)"
echo ""
echo "💡 RECOMENDACIONES DE TAMAÑO:"
echo "   • 1-5GB: Test rápido y básico"
echo "   • 10-20GB: Test moderado (recomendado)"
echo "   • 50GB+: Test exhaustivo (puede tomar mucho tiempo)"
echo ""
while true; do
    read -p "👉 Ingresa el tamaño del test en GB (ej: 10): " test_size_gb
    if [[ "$test_size_gb" =~ ^[0-9]+$ ]] && [ "$test_size_gb" -gt 0 ]; then
        TEST_SIZE="${test_size_gb}G"
        break
    else
        echo "❌ Por favor ingresa un número válido mayor que 0"
    fi
done

# Solicitar tamaño de bloque
echo ""
echo "📦 CONFIGURACIÓN DEL TAMAÑO DE BLOQUE:"
echo "======================================"
echo "💡 INFORMACIÓN SOBRE TAMAÑOS DE BLOQUE:"
echo "   • 4K: Óptimo para bases de datos y aplicaciones transaccionales"
echo "   • 64K: Buen equilibrio para uso general"
echo "   • 1M: Óptimo para archivos grandes y streaming de video"
echo "   • 16M: Máximo rendimiento para transferencias masivas"
echo ""
echo "⚙️  OPCIONES DISPONIBLES:"
echo "   1. 4K (4096 bytes) - Base de datos/Transaccional"
echo "   2. 64K (65536 bytes) - Uso general balanceado"
echo "   3. 1M (1048576 bytes) - Archivos grandes (RECOMENDADO)"
echo "   4. 16M (16777216 bytes) - Transferencias masivas"
echo "   5. Personalizado"
echo ""

while true; do
    read -p "👉 Selecciona el tamaño de bloque (1-5): " block_choice
    case $block_choice in
        1)
            BLOCK_SIZE="4K"
            echo "✅ Seleccionado: 4K (óptimo para bases de datos)"
            break
            ;;
        2)
            BLOCK_SIZE="64K"
            echo "✅ Seleccionado: 64K (uso general)"
            break
            ;;
        3)
            BLOCK_SIZE="1M"
            echo "✅ Seleccionado: 1M (archivos grandes - recomendado)"
            break
            ;;
        4)
            BLOCK_SIZE="16M"
            echo "✅ Seleccionado: 16M (transferencias masivas)"
            break
            ;;
        5)
            echo "📝 EJEMPLOS DE TAMAÑOS PERSONALIZADOS:"
            echo "   • 512, 8K, 32K, 128K, 2M, 4M, 8M"
            while true; do
                read -p "Ingresa tamaño personalizado (ej: 32K, 2M): " custom_block
                if [[ "$custom_block" =~ ^[0-9]+[KMGT]?$ ]]; then
                    BLOCK_SIZE="$custom_block"
                    echo "✅ Seleccionado: $custom_block (personalizado)"
                    break 2
                else
                    echo "❌ Formato inválido. Usa números seguidos de K, M, G, T (ej: 32K, 2M)"
                fi
            done
            ;;
        *)
            echo "❌ Selección inválida. Usa números del 1 al 5."
            ;;
    esac
done

echo ""
echo "🎯 CONFIGURACIÓN DEL TEST:"
echo "========================="
echo "   Pool: $POOL_NAME"
echo "   Dataset/Ubicación: $TARGET_DATASET"
echo "   Punto de montaje: $POOL_PATH"
echo "   Tamaño del test: $TEST_SIZE"
echo "   Tamaño de bloque: $BLOCK_SIZE"
echo ""
echo "💡 INTERPRETACIÓN DE RESULTADOS:"
echo "   • Bloques pequeños (4K-64K): Miden IOPS y latencia"
echo "   • Bloques grandes (1M-16M): Miden throughput máximo"
echo "   • L2ARC es más efectivo con patrones de acceso repetitivos"
echo ""
read -p "¿Continuar con esta configuración? (y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "❌ Test cancelado"
    exit 0
fi

echo ""
echo "🔍 Ubicación de test: ${POOL_PATH}"
echo "📊 Target: $TARGET_DATASET"
echo ""

# Verificar que el directorio existe y es accesible
if [ ! -d "${POOL_PATH}" ]; then
    echo "❌ Error: El directorio ${POOL_PATH} no existe"
    echo "Creando punto de montaje..."
    sudo mkdir -p "${POOL_PATH}" 2>/dev/null || true
fi

echo "📊 ESTADO INICIAL DEL ARC/L2ARC:"
echo "--------------------------------"
cat /proc/spl/kstat/zfs/arcstats | grep -E "^(hits|misses|l2_size|l2_hits|l2_misses)" | head -5

echo ""
echo "🔥 TEST 1: Escritura inicial con datos aleatorios (llenar cache)"
echo "================================================================"
echo "Creando archivo de test de ${TEST_SIZE} con datos ALEATORIOS..."
echo "⚠️  Usando /dev/urandom para datos no comprimibles (más realista)"

# Calcular count basado en el tamaño solicitado y el tamaño de bloque seleccionado
# Convertir el tamaño de test a bytes y dividir por el tamaño de bloque
total_bytes=$((test_size_gb * 1024 * 1024 * 1024))  # GB a bytes

# Convertir BLOCK_SIZE a bytes para el cálculo
case "$BLOCK_SIZE" in
    *K|*k) block_bytes=$((${BLOCK_SIZE%[Kk]} * 1024)) ;;
    *M|*m) block_bytes=$((${BLOCK_SIZE%[Mm]} * 1024 * 1024)) ;;
    *G|*g) block_bytes=$((${BLOCK_SIZE%[Gg]} * 1024 * 1024 * 1024)) ;;
    *) block_bytes="$BLOCK_SIZE" ;;  # Asumir bytes si no hay sufijo
esac

count=$((total_bytes / block_bytes))

echo "📊 Cálculo: ${test_size_gb}GB ÷ ${BLOCK_SIZE} = ${count} bloques"
time sudo dd if=/dev/urandom of=${POOL_PATH}/testfile bs=${BLOCK_SIZE} count=${count} status=progress
sudo sync
echo "✅ Archivo de datos aleatorios creado"

echo ""
echo "📈 ESTADO DEL ARC DESPUÉS DE ESCRITURA:"
cat /proc/spl/kstat/zfs/arcstats | grep -E "^(l2_size|l2_asize)" | head -2

echo ""
echo "🔥 TEST 2: Primera lectura (llenará L2ARC si es necesario)"
echo "========================================================="
echo "Primera lectura completa..."
time dd if=${POOL_PATH}/testfile of=/dev/null bs=${BLOCK_SIZE} status=progress

echo ""
echo "📈 ESTADO DEL L2ARC DESPUÉS DE PRIMERA LECTURA:"
cat /proc/spl/kstat/zfs/arcstats | grep -E "^(l2_size|l2_hits|l2_misses|l2_asize)" | head -4

echo ""
echo "🔥 TEST 3: Segunda lectura (debería usar L2ARC)"
echo "==============================================="
echo "Limpiando ARC principal para forzar uso de L2ARC..."
sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'  # Limpia page cache del sistema
echo "Segunda lectura (desde L2ARC)..."
time dd if=${POOL_PATH}/testfile of=/dev/null bs=${BLOCK_SIZE} status=progress

echo ""
echo "📊 ESTADÍSTICAS FINALES DEL L2ARC:"
echo "=================================="
cat /proc/spl/kstat/zfs/arcstats | grep -E "^l2_" | grep -E "(hits|misses|size|read_bytes|write_bytes)" | head -8

echo ""
echo "🎯 TEST 4: Rendimiento de lectura aleatoria"
echo "==========================================="
echo "Test con fio (lectura aleatoria 4K)..."

# Calcular tamaño para fio (usar 1/4 del tamaño del test principal para ser más rápido)
fio_size_mb=$((test_size_gb * 256))  # 1GB = 1024MB, usamos 1/4 del test principal
if [ $fio_size_mb -lt 128 ]; then
    fio_size_mb=128  # Mínimo 128MB para fio
fi

# Crear script fio temporal con datos aleatorios
cat > /tmp/zfs_test.fio << EOF
[random-read-test]
ioengine=libaio
rw=randread
bs=4k
numjobs=4
iodepth=32
size=${fio_size_mb}M
filename=${POOL_PATH}/fio_testfile
runtime=30
time_based=1
name=zfs-l2arc-test
group_reporting=1
randrepeat=0
norandommap=1
create_on_open=1
EOF

echo "Ejecutando fio test (tamaño: ${fio_size_mb}MB)..."
if command -v fio >/dev/null 2>&1; then
    sudo fio /tmp/zfs_test.fio
else
    echo "⚠️  fio no está instalado. Instalando..."
    sudo apt update && sudo apt install -y fio
    echo "Ejecutando test después de instalación..."
    sudo fio /tmp/zfs_test.fio
fi

echo ""
echo "📊 RESUMEN FINAL:"
echo "================"
echo "L2ARC Hits vs Misses:"
cat /proc/spl/kstat/zfs/arcstats | grep -E "^(l2_hits|l2_misses)" | head -2

echo ""
echo "🧹 LIMPIEZA:"
echo "============"
echo "Eliminando archivos de test..."
sudo rm -f ${POOL_PATH}/testfile ${POOL_PATH}/fio_testfile /tmp/zfs_test.fio

echo ""
echo "✅ Tests completados!"
echo "📊 RESUMEN DE LA CONFIGURACIÓN:"
echo "   Pool testado: $POOL_NAME"
echo "   Dataset: $TARGET_DATASET"
echo "   Tamaño del test: $TEST_SIZE"
echo "   Tamaño de bloque: $BLOCK_SIZE"
echo "   Ubicación: $POOL_PATH"
echo ""
echo "📈 INTERPRETACIÓN DE RESULTADOS:"
echo "   • l2_hits > l2_misses = L2ARC funcionando correctamente"
echo "   • Bloques grandes ($BLOCK_SIZE) optimizan para throughput"
echo "   • Compara tiempos entre primera y segunda lectura"
echo ""
echo "Revisa las estadísticas de l2_hits para ver si el L2ARC está funcionando."