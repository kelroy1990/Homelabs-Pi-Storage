#!/bin/bash

trap "echo -e '\n[*] Deteniendo...'; pkill -P $$; exit 0" SIGINT SIGTERM

CORES=$(nproc)
PUNTOS=("/mnt/ssd_fast" "/mnt/raid0")  # Añade "/" si quieres incluir la microSD

estresar_cpu() {
    echo "[+] Estresando CPU con $CORES núcleos..."
    for i in $(seq 1 "$CORES"); do
        while :; do :; done &
    done
}

estresar_discos_continuamente() {
    echo "[+] Estresando discos continuamente..."

    for MNT in "${PUNTOS[@]}"; do
        if [ -d "$MNT" ] && [ -w "$MNT" ]; then
            FILE="$MNT/stressfile_$$"
            echo "  --> Iniciando carga en $MNT"

            (
                while true; do
                    echo "    [*] Escribiendo 500MB en $FILE"
                    dd if=/dev/zero of="$FILE" bs=1M count=500 status=none

                    echo "    [*] Leyendo 500MB desde $FILE"
                    dd if="$FILE" of=/dev/null bs=1M status=none
                done
            ) &
        else
            echo "[!] No se puede escribir en $MNT — ¿montado y con permisos?"
        fi
    done
}

estresar_cpu
estresar_discos_continuamente

echo "[*] Estrés en curso. Ctrl+C para detener."
wait
