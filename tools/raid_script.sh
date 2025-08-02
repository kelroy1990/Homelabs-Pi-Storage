#!/bin/bash

# RAID Configuration Script for Raspberry Pi / Script de Configuración RAID para Raspberry Pi
# Supports BTRFS and ZFS / Soporta BTRFS y ZFS

set -e

# Colors for output / Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variable for language selection
SCRIPT_LANGUAGE="en"
export SCRIPT_LANGUAGE

# Language selection function / Función de selección de idioma
select_language() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    RAID Configuration Script                   ║"
    echo "║                   Script de Configuración RAID                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Please select your preferred language / Por favor selecciona tu idioma preferido:"
    echo ""
    echo "  1. English"
    echo "  2. Español"
    echo ""
    
    while true; do
        read -p "Language choice / Elección de idioma (1-2): " lang_choice
        case $lang_choice in
            1)
                SCRIPT_LANGUAGE="en"
                export SCRIPT_LANGUAGE
                echo "Language set to English"
                break
                ;;
            2)
                SCRIPT_LANGUAGE="es"
                export SCRIPT_LANGUAGE
                echo "Idioma establecido en Español"
                break
                ;;
            *)
                echo "Invalid option. Please select 1 or 2 / Opción inválida. Selecciona 1 o 2"
                ;;
        esac
    done
    echo ""
    sleep 1
}

# Multilingual text messages / Mensajes de texto multiidioma
get_text() {
    local key="$1"
    
    case "$key" in
        "script_title")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "RAID Configuration Script for Raspberry Pi"
            else
                echo "Script de Configuración RAID para Raspberry Pi"
            fi
            ;;
        "root_warning")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Do not run this script as root. Use sudo when necessary."
            else
                echo "No ejecutes este script como root. Usa sudo cuando sea necesario."
            fi
            ;;
        "checking_requirements")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Checking System Requirements"
            else
                echo "Verificando Requisitos del Sistema"
            fi
            ;;
        "updating_packages")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Updating package list..."
            else
                echo "Actualizando lista de paquetes..."
            fi
            ;;
        "btrfs_available")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "✓ BTRFS: Available"
            else
                echo "✓ BTRFS: Disponible"
            fi
            ;;
        "btrfs_not_available")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "✗ BTRFS: Not available"
            else
                echo "✗ BTRFS: No disponible"
            fi
            ;;
        "zfs_available")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "✓ ZFS: Available"
            else
                echo "✓ ZFS: Disponible"
            fi
            ;;
        "zfs_not_available")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "✗ ZFS: Not available"
            else
                echo "✗ ZFS: No disponible"
            fi
            ;;
        "no_raid_tools")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "No RAID tools available in the system"
            else
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    echo "No RAID tools available on the system"
                else
                    echo "No hay herramientas RAID disponibles en el sistema"
                fi
            fi
            ;;
        "will_install_packages")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Required packages will be installed..."
            else
                echo "Se instalarán los paquetes necesarios..."
            fi
            ;;
        "packages_to_install")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Packages to be installed:"
            else
                echo "Paquetes que se instalarán:"
            fi
            ;;
        "zfs_install_warning")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "⚠️  ZFS may take up to 10 minutes to install due to kernel module compilation"
            else
                echo "⚠️  ZFS puede tardar hasta 10 minutos en instalarse debido a la compilación de módulos del kernel"
            fi
            ;;
        "installation_progress_shown")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "⚠️  You will see the installation progress on screen"
            else
                echo "⚠️  Durante la instalación verás el progreso en pantalla"
            fi
            ;;
        "continue_installation")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Do you want to continue with the installation?"
            else
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    echo "Do you want to continue with the installation?"
                else
                    echo "¿Deseas continuar con la instalación?"
                fi
            fi
            ;;
        "installation_cancelled")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Installation cancelled by user"
            else
                echo "Instalación cancelada por el usuario"
            fi
            ;;
        "starting_installation")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Starting package installation..."
            else
                echo "Iniciando instalación de paquetes..."
            fi
            ;;
        "installing_zfs")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "🔄 Installing ZFS (this may take several minutes)..."
            else
                echo "🔄 Instalando ZFS (esto puede tomar varios minutos)..."
            fi
            ;;
        "zfs_progress")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "📦 ZFS Installation Progress:"
            else
                echo "📦 Progreso de instalación ZFS:"
            fi
            ;;
        "zfs_installed_successfully")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "✅ ZFS installed successfully"
            else
                echo "✅ ZFS instalado exitosamente"
            fi
            ;;
        "error_installing_zfs")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "❌ Error installing ZFS"
            else
                echo "❌ Error instalando ZFS"
            fi
            ;;
        "please_respond_yn")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Please answer y or n."
            else
                echo "Por favor responde y o n."
            fi
            ;;
        "installation_cancelled")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Installation cancelled by user"
            else
                echo "Instalación cancelada por el usuario"
            fi
            ;;
        "raid_completed")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "RAID configuration completed successfully!"
            else
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    echo "¡RAID configuration completed successfully!"
                else
                    echo "¡Configuración RAID completada exitosamente!"
                fi
            fi
            ;;
        "raid_mounted_at")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "RAID is mounted at:"
            else
                echo "El RAID está montado en:"
            fi
            ;;
        "detect_existing_raid")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Detecting Existing RAID Configurations"
            else
                echo "Detección de Configuraciones RAID Existentes"
            fi
            ;;
        "available_options")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "🛠️  AVAILABLE OPTIONS:"
            else
                echo "🛠️  OPCIONES DISPONIBLES:"
            fi
            ;;
        "continue_new_raid")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Continue with new RAID configuration"
            else
                echo "Continuar con configuración de nuevo RAID"
            fi
            ;;
        "exit_script")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Exit script"
            else
                echo "Salir del script"
            fi
            ;;
        "no_raid_detected")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "ℹ️  No existing RAID configurations detected."
            else
                echo "ℹ️  No se detectaron configuraciones RAID existentes."
            fi
            ;;
        "system_ready_new_raid")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "   System is ready to configure a new RAID."
            else
                echo "   El sistema está listo para configurar un nuevo RAID."
            fi
            ;;
        "manage_zfs_pools")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Manage ZFS pools and datasets"
            else
                echo "Gestionar pools y datasets ZFS"
            fi
            ;;
        "delete_zfs_pools")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Delete specific ZFS pools"
            else
                echo "Eliminar pools ZFS específicos"
            fi
            ;;
        "delete_btrfs_filesystems")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Delete specific BTRFS filesystems"
            else
                echo "Eliminar filesystems BTRFS específicos"
            fi
            ;;
        "manage_mdadm_arrays")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Manage MDADM arrays (information only)"
            else
                echo "Gestionar arrays MDADM (información solamente)"
            fi
            ;;
        "manage_lvm_groups")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Manage LVM Volume Groups (information only)"
            else
                echo "Gestionar Volume Groups LVM (información solamente)"
            fi
            ;;
        "continue_new_raid")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Continue with new RAID configuration"
            else
                echo "Continuar con configuración de nuevo RAID"
            fi
            ;;
        "exit_script")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Exit script"
            else
                echo "Salir del script"
            fi
            ;;
        "invalid_option")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "❌ Invalid option. Please select a valid number."
            else
                echo "❌ Opción inválida. Selecciona un número válido."
            fi
            ;;
        "select_option")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "👉 Select an option"
            else
                echo "👉 Selecciona una opción"
            fi
            ;;
        "continuing_new_raid")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Continuing with new RAID configuration..."
            else
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    echo "Continuing with new RAID configuration..."
                else
                    echo "Continuando con configuración de nuevo RAID..."
                fi
            fi
            ;;
        "exiting_script")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Exiting script..."
            else
                echo "Saliendo del script..."
            fi
            ;;
        "manage_mdadm_arrays")
            if [ "$SCRIPT_LANGUAGE" = "es" ]; then
                echo "Gestionar arrays MDADM (información solamente)"
            else
                echo "Manage MDADM arrays (information only)"
            fi
            ;;
        "manage_lvm_groups")
            if [ "$SCRIPT_LANGUAGE" = "es" ]; then
                echo "Gestionar Volume Groups LVM (información solamente)"
            else
                echo "Manage LVM Volume Groups (information only)"
            fi
            ;;
        "delete_btrfs_filesystems")
            if [ "$SCRIPT_LANGUAGE" = "es" ]; then
                echo "Eliminar filesystems BTRFS específicos"
            else
                echo "Delete specific BTRFS filesystems"
            fi
            ;;
        "mdadm_management_info")
            if [ "$SCRIPT_LANGUAGE" = "es" ]; then
                echo "Para gestionar arrays MDADM, usa herramientas específicas como:"
            else
                echo "To manage MDADM arrays, use specific tools like:"
            fi
            ;;
        "lvm_management_info")
            if [ "$SCRIPT_LANGUAGE" = "es" ]; then
                echo "Para gestionar LVM, usa herramientas específicas como:"
            else
                echo "To manage LVM, use specific tools like:"
            fi
            ;;
        "continue_detection")
            if [ "$SCRIPT_LANGUAGE" = "es" ]; then
                echo "¿Continuar con la detección de configuraciones?"
            else
                echo "Continue with configuration detection?"
            fi
            ;;
        "sector_config_detected")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "[INFO] 📊 Detected sector configuration:"
            else
                echo "[INFO] 📊 Configuración de sectores detectada:"
            fi
            ;;
        "max_sector_size_hdds")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "[INFO]    Maximum sector size in HDDs:"
            else
                echo "[INFO]    Tamaño de sector máximo en HDDs:"
            fi
            ;;
        "pool_ashift")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "[INFO]    Pool ashift:"
            else
                echo "[INFO]    Ashift del pool:"
            fi
            ;;
        "compatibility_cache_devices")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "[INFO]    ✅ This ensures compatibility with SSD cache devices (4096 bytes)"
            else
                echo "[INFO]    ✅ Esto garantiza compatibilidad con cache devices SSD (4096 bytes)"
            fi
            ;;
        "config_for_pool")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "[INFO] 📊 Configuration for pool"
            else
                echo "[INFO] 📊 Configuración para pool"
            fi
            ;;
        "ensures_compatibility_future")
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "[INFO]    ✅ Ensures compatibility with future cache devices"
            else
                echo "[INFO]    ✅ Garantiza compatibilidad con cache devices futuro"
            fi
            ;;
        *)
            echo "$key" # Fallback to key itself
            ;;
    esac
}

# Functions for displaying messages / Funciones para mostrar mensajes
show_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

show_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

show_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_title() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Function to get user confirmation / Función para obtener confirmación del usuario
confirm() {
    local prompt="$1"
    local yn_text
    
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        yn_text="(y/n)"
    else
        yn_text="(s/n)"
    fi
    
    while true; do
        read -p "$prompt $yn_text: " yn
        case $yn in
            [YySs]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "$(get_text "please_respond_yn")";;
        esac
    done
}

# Function to check and install system requirements / Función para verificar e instalar requisitos del sistema
check_and_install_requirements() {
    show_title "$(get_text "checking_requirements")"
    
    # Update package list / Actualizar lista de paquetes
    show_message "$(get_text "updating_packages")"
    sudo apt update > /dev/null 2>&1
    
    local packages_to_install=()
    local missing_packages=""
    
    # Check basic tools / Verificar herramientas básicas
    if ! command -v lsblk &> /dev/null; then
        packages_to_install+=("util-linux")
        missing_packages="$missing_packages util-linux"
    fi
    
    if ! command -v parted &> /dev/null; then
        packages_to_install+=("parted")
        missing_packages="$missing_packages parted"
    fi
    
    if ! command -v wipefs &> /dev/null; then
        packages_to_install+=("util-linux")
        missing_packages="$missing_packages util-linux"
    fi
    
    # Check BTRFS / Verificar BTRFS
    local btrfs_available=false
    if command -v mkfs.btrfs &> /dev/null && command -v btrfs &> /dev/null; then
        btrfs_available=true
        show_message "$(get_text "btrfs_available")"
    else
        show_warning "$(get_text "btrfs_not_available")"
        packages_to_install+=("btrfs-progs")
        missing_packages="$missing_packages btrfs-progs"
    fi
    
    # Check ZFS / Verificar ZFS
    local zfs_available=false
    if command -v zpool &> /dev/null && command -v zfs &> /dev/null; then
        zfs_available=true
        show_message "$(get_text "zfs_available")"
    else
        show_warning "$(get_text "zfs_not_available")"
        packages_to_install+=("zfsutils-linux")
        missing_packages="$missing_packages zfsutils-linux"
    fi
    
    # Check mdadm (useful for cleanup) / Verificar mdadm (útil para limpieza)
    if ! command -v mdadm &> /dev/null; then
        packages_to_install+=("mdadm")
        missing_packages="$missing_packages mdadm"
    fi
    
    # If no RAID tools available, we cannot continue / Si no hay herramientas RAID disponibles, no podemos continuar
    if [ "$btrfs_available" = false ] && [ "$zfs_available" = false ]; then
        show_error "$(get_text "no_raid_tools")"
        show_message "$(get_text "will_install_packages")"
    fi
    
    # Install missing packages if necessary / Instalar paquetes faltantes si es necesario
    if [ ${#packages_to_install[@]} -gt 0 ]; then
        show_message "$(get_text "packages_to_install")$missing_packages"
        
        # Check if ZFS is in the list / Verificar si ZFS está en la lista
        local installing_zfs=false
        for package in "${packages_to_install[@]}"; do
            if [ "$package" = "zfsutils-linux" ]; then
                installing_zfs=true
                break
            fi
        done
        
        if [ "$installing_zfs" = true ]; then
            show_warning "$(get_text "zfs_install_warning")"
            show_warning "$(get_text "installation_progress_shown")"
            
            if ! confirm "$(get_text "continue_installation")"; then
                show_message "$(get_text "installation_cancelled")"
                exit 0
            fi
        fi
        
        show_message "$(get_text "starting_installation")"
        echo "----------------------------------------"
        
        # Install packages with visible output / Instalar paquetes con output visible
        for package in "${packages_to_install[@]}"; do
            if [ "$package" = "zfsutils-linux" ]; then
                show_message "$(get_text "installing_zfs")"
                echo "$(get_text "zfs_progress")"
                if sudo apt install -y "$package"; then
                    show_message "$(get_text "zfs_installed_successfully")"
                else
                    show_error "$(get_text "error_installing_zfs")"
                    exit 1
                fi
            else
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    show_message "🔄 Installing $package..."
                    if sudo apt install -y "$package" > /dev/null 2>&1; then
                        show_message "✅ $package installed successfully"
                    else
                        show_error "❌ Error installing $package"
                        exit 1
                    fi
                else
                    show_message "🔄 Instalando $package..."
                    if sudo apt install -y "$package" > /dev/null 2>&1; then
                        show_message "✅ $package instalado exitosamente"
                    else
                        show_error "❌ Error instalando $package"
                        exit 1
                    fi
                fi
            fi
        done
        
        echo "----------------------------------------"
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_message "✅ All packages installed successfully"
        else
            show_message "✅ Todos los paquetes se instalaron correctamente"
        fi
        
        # Verificar que ZFS esté funcionando si se instaló
        if [ "$installing_zfs" = true ]; then
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                show_message "🔄 Verifying ZFS functionality..."
            else
                show_message "🔄 Verificando funcionamiento de ZFS..."
            fi
            
            # Cargar módulo ZFS si no está cargado
            if ! lsmod | grep -q "^zfs "; then
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    show_message "Loading ZFS module..."
                else
                    show_message "Cargando módulo ZFS..."
                fi
                sudo modprobe zfs
                sleep 2
            fi
            
            # Verificar que los comandos funcionen
            if zpool status > /dev/null 2>&1 && zfs version > /dev/null 2>&1; then
                local zfs_version=$(zfs version | head -1 | awk '{print $2}')
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    show_message "✅ ZFS working correctly (version: $zfs_version)"
                else
                    show_message "✅ ZFS funcionando correctamente (versión: $zfs_version)"
                fi
            else
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    show_error "❌ ZFS is not working correctly"
                    show_message "A system restart may be necessary"
                    if confirm "Do you want to continue anyway? (may fail)"; then
                        show_warning "Continuing with possibly non-functional ZFS..."
                    else
                        exit 1
                    fi
                else
                    show_error "❌ ZFS no está funcionando correctamente"
                    show_message "Puede ser necesario reiniciar el sistema"
                    if confirm "¿Deseas continuar de todas formas? (puede fallar)"; then
                        show_warning "Continuando con ZFS posiblemente no funcional..."
                    else
                        exit 1
                    fi
                fi
            fi
        fi
        
        # Breve pausa para que el usuario vea el resultado
        sleep 1
    else
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_message "✅ All requirements are available"
        else
            show_message "✅ Todos los requisitos están disponibles"
        fi
    fi
    
    # Mostrar resumen final de herramientas disponibles
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_message "Available RAID tools:"
    else
        show_message "Herramientas RAID disponibles:"
    fi
    if command -v mkfs.btrfs &> /dev/null; then
        local btrfs_version=$(btrfs --version 2>/dev/null | awk '{print $2}' || echo "desconocida")
        echo "  ✓ BTRFS (versión: $btrfs_version)"
    fi
    
    if command -v zpool &> /dev/null; then
        local zfs_version=$(zfs version 2>/dev/null | head -1 | awk '{print $2}' || echo "desconocida")
        echo "  ✓ ZFS (versión: $zfs_version)"
    fi
    
    echo ""
}

# Function to detect all existing RAID configurations / Función para detectar todas las configuraciones RAID existentes
detect_existing_raid_configurations() {
    show_title "$(get_text "detect_existing_raid")"
    
    local zfs_found=false
    local btrfs_found=false
    local mdadm_found=false
    local lvm_found=false
    local any_raid_found=false
    
    # 1. DETECTAR ZFS
    if command -v zpool &> /dev/null; then
        # Verificar que el módulo ZFS esté cargado
        if ! lsmod | grep -q "^zfs "; then
            sudo modprobe zfs 2>/dev/null || true
            sleep 1
        fi
        
        local existing_pools=$(zpool list -H -o name 2>/dev/null)
        if [ -n "$existing_pools" ]; then
            zfs_found=true
            any_raid_found=true
            
            echo ""
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "🔷 DETECTED ZFS POOLS:"
            else
                echo "🔷 POOLS ZFS DETECTADOS:"
            fi
            for pool in $existing_pools; do
                local pool_health=$(zpool list -H -o health "$pool" 2>/dev/null)
                local pool_size=$(zpool list -H -o size "$pool" 2>/dev/null)
                local pool_used=$(zpool list -H -o allocated "$pool" 2>/dev/null)
                local pool_free=$(zpool list -H -o free "$pool" 2>/dev/null)
                
                echo "  📦 Pool: $pool"
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    echo "     💚 Status: $pool_health"
                    echo "     📏 Size: $pool_size (Used: $pool_used, Free: $pool_free)"
                else
                    echo "     💚 Estado: $pool_health"
                    echo "     📏 Tamaño: $pool_size (Usado: $pool_used, Libre: $pool_free)"
                fi
                
                # Mostrar datasets existentes
                local datasets=$(zfs list -H -o name -r "$pool" 2>/dev/null | grep -v "^${pool}$")
                if [ -n "$datasets" ]; then
                    local dataset_count=$(echo "$datasets" | wc -l)
                    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                        echo "     📁 Datasets: $dataset_count"
                    else
                        echo "     📁 Datasets: $dataset_count"
                    fi
                    for dataset in $datasets; do
                        local used=$(zfs list -H -o used "$dataset" 2>/dev/null)
                        local mountpoint=$(zfs list -H -o mountpoint "$dataset" 2>/dev/null)
                        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                            echo "       • $dataset (Used: $used, Mount: $mountpoint)"
                        else
                            echo "       • $dataset (Usado: $used, Montaje: $mountpoint)"
                        fi
                    done
                else
                    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                        echo "     📁 No datasets (root pool only)"
                    else
                        echo "     📁 Sin datasets (solo pool raíz)"
                    fi
                fi
                
                # Mostrar dispositivos del pool
                local pool_devices=$(zpool status "$pool" 2>/dev/null | grep -E "^\s+[a-z]" | awk '{print $1}' | grep -v "raidz\|mirror\|spare\|log\|cache\|replacing" | head -3)
                if [ -n "$pool_devices" ]; then
                    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                        echo "     💿 Devices: $(echo $pool_devices | tr '\n' ' ' | sed 's/ *$//')..."
                    else
                        echo "     💿 Dispositivos: $(echo $pool_devices | tr '\n' ' ' | sed 's/ *$//')..."
                    fi
                fi
                echo ""
            done
        fi
    fi
    
    # 2. DETECTAR BTRFS
    if command -v btrfs &> /dev/null; then
        local btrfs_devices=()
        local btrfs_info=()
        
        # Buscar en todos los dispositivos
        for device in $(lsblk -dpno NAME | grep -E "sd[a-z]|nvme"); do
            if btrfs filesystem show "$device" 2>/dev/null | grep -q "uuid:"; then
                local device_name=$(basename "$device")
                local btrfs_uuid=$(btrfs filesystem show "$device" 2>/dev/null | grep "uuid:" | awk '{print $4}')
                local size=$(lsblk -dpno SIZE "$device" | tr -d ' ')
                local mount_point=$(mount | grep "$device" | awk '{print $3}' | head -1)
                
                btrfs_devices+=("$device_name")
                if [ -n "$mount_point" ]; then
                    btrfs_info+=("$device_name:$size:$mount_point:$btrfs_uuid")
                else
                    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                        btrfs_info+=("$device_name:$size:not_mounted:$btrfs_uuid")
                    else
                        btrfs_info+=("$device_name:$size:no_montado:$btrfs_uuid")
                    fi
                fi
            fi
        done
        
        if [ ${#btrfs_devices[@]} -gt 0 ]; then
            btrfs_found=true
            any_raid_found=true
            
            echo ""
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "🟠 DETECTED BTRFS FILESYSTEMS:"
            else
                echo "🟠 FILESYSTEMS BTRFS DETECTADOS:"
            fi
            for info in "${btrfs_info[@]}"; do
                IFS=':' read -r device size mount_point uuid <<< "$info"
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    echo "  📦 Device: $device"
                    echo "     📏 Size: $size"
                    echo "     📁 Mount: $mount_point"
                    echo "     🆔 UUID: $uuid"
                else
                    echo "  📦 Dispositivo: $device"
                    echo "     📏 Tamaño: $size"
                    echo "     📁 Montaje: $mount_point"
                    echo "     🆔 UUID: $uuid"
                fi
                
                # Mostrar información adicional de BTRFS si está montado
                if [ "$mount_point" != "no_montado" ] && [ "$mount_point" != "not_mounted" ]; then
                    local used=$(df -h "$mount_point" 2>/dev/null | tail -1 | awk '{print $3}')
                    local available=$(df -h "$mount_point" 2>/dev/null | tail -1 | awk '{print $4}')
                    if [ -n "$used" ]; then
                        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                            echo "     📊 Used: $used, Available: $available"
                        else
                            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                                echo "     📊 Used: $used, Available: $available"
                            else
                                echo "     📊 Usado: $used, Disponible: $available"
                            fi
                        fi
                    fi
                    
                    # Verificar subvolúmenes
                    local subvolumes=$(btrfs subvolume list "$mount_point" 2>/dev/null | wc -l)
                    if [ "$subvolumes" -gt 0 ]; then
                        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                            echo "     📂 Subvolumes: $subvolumes"
                        else
                            echo "     📂 Subvolúmenes: $subvolumes"
                        fi
                    fi
                fi
                echo ""
            done
        fi
    fi
    
    # 3. DETECTAR MDADM (Linux Software RAID)
    if command -v mdadm &> /dev/null; then
        local mdadm_arrays=$(cat /proc/mdstat 2>/dev/null | grep "^md" | awk '{print $1}')
        if [ -n "$mdadm_arrays" ]; then
            mdadm_found=true
            any_raid_found=true
            
            echo ""
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "🔴 DETECTED MDADM ARRAYS:"
            else
                echo "🔴 ARRAYS MDADM DETECTADOS:"
            fi
            for array in $mdadm_arrays; do
                local array_info=$(mdadm --detail "/dev/$array" 2>/dev/null)
                if [ -n "$array_info" ]; then
                    local raid_level=$(echo "$array_info" | grep "Raid Level" | awk '{print $4}')
                    local array_size=$(echo "$array_info" | grep "Array Size" | awk '{print $4$5}')
                    local state=$(echo "$array_info" | grep "State" | awk '{print $3}')
                    local num_devices=$(echo "$array_info" | grep "Total Devices" | awk '{print $4}')
                    
                    echo "  📦 Array: /dev/$array"
                    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                        echo "     🔧 RAID Level: $raid_level"
                        echo "     📏 Size: $array_size"
                        echo "     💚 Status: $state"
                        echo "     💿 Devices: $num_devices"
                    else
                        echo "     🔧 Nivel RAID: $raid_level"
                        echo "     📏 Tamaño: $array_size"
                        echo "     💚 Estado: $state"
                        echo "     💿 Dispositivos: $num_devices"
                    fi
                    
                    # Mostrar dispositivos del array
                    local devices=$(echo "$array_info" | grep "/dev/" | grep -v "failed\|spare" | awk '{print $7}' | head -3)
                    if [ -n "$devices" ]; then
                        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                            echo "     💿 Members: $(echo $devices | tr '\n' ' ' | sed 's/ *$//')..."
                        else
                            echo "     💿 Miembros: $(echo $devices | tr '\n' ' ' | sed 's/ *$//')..."
                        fi
                    fi
                    echo ""
                fi
            done
        fi
    fi
    
    # 4. DETECTAR LVM
    if command -v vgdisplay &> /dev/null; then
        local volume_groups=$(vgdisplay 2>/dev/null | grep "VG Name" | awk '{print $3}')
        if [ -n "$volume_groups" ]; then
            lvm_found=true
            any_raid_found=true
            
            echo ""
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "🟣 DETECTED LVM VOLUME GROUPS:"
            else
                echo "🟣 VOLUME GROUPS LVM DETECTADOS:"
            fi
            for vg in $volume_groups; do
                local vg_info=$(vgdisplay "$vg" 2>/dev/null)
                if [ -n "$vg_info" ]; then
                    local vg_size=$(echo "$vg_info" | grep "VG Size" | awk '{print $3$4}')
                    local vg_free=$(echo "$vg_info" | grep "Free  PE" | awk '{print $5$6}')
                    local pv_count=$(echo "$vg_info" | grep "Cur PV" | awk '{print $3}')
                    local lv_count=$(echo "$vg_info" | grep "Cur LV" | awk '{print $3}')
                    
                    echo "  📦 Volume Group: $vg"
                    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                        echo "     📏 Size: $vg_size"
                        echo "     💾 Free: $vg_free"
                        echo "     💿 Physical Volumes: $pv_count"
                        echo "     📁 Logical Volumes: $lv_count"
                    else
                        echo "     📏 Tamaño: $vg_size"
                        echo "     💾 Libre: $vg_free"
                        echo "     💿 Physical Volumes: $pv_count"
                        echo "     📁 Logical Volumes: $lv_count"
                    fi
                    
                    # Mostrar logical volumes
                    local logical_volumes=$(lvdisplay "$vg" 2>/dev/null | grep "LV Name" | awk '{print $3}' | head -3)
                    if [ -n "$logical_volumes" ]; then
                        echo "     📂 LVs: $(echo $logical_volumes | tr '\n' ' ' | sed 's/ *$//')..."
                    fi
                    echo ""
                fi
            done
        fi
    fi
    
    # SHOW SUMMARY AND OPTIONS / MOSTRAR RESUMEN Y OPCIONES
    if [ "$any_raid_found" = true ]; then
        echo "═══════════════════════════════════════════════════════════════════"
        echo ""
        echo "$(get_text "available_options")"
        
        local option_number=1
        
        if [ "$zfs_found" = true ]; then
            echo "   $option_number. $(get_text "manage_zfs_pools")"
            zfs_option=$option_number
            ((option_number++))
            
            echo "   $option_number. $(get_text "delete_zfs_pools")"
            zfs_delete_option=$option_number
            ((option_number++))
        fi
        
        if [ "$btrfs_found" = true ]; then
            echo "   $option_number. $(get_text "delete_btrfs_filesystems")"
            btrfs_option=$option_number
            ((option_number++))
        fi
        
        if [ "$mdadm_found" = true ]; then
            echo "   $option_number. $(get_text "manage_mdadm_arrays")"
            mdadm_option=$option_number
            ((option_number++))
        fi
        
        if [ "$lvm_found" = true ]; then
            echo "   $option_number. $(get_text "manage_lvm_groups")"
            lvm_option=$option_number
            ((option_number++))
        fi
        
        echo "   $option_number. $(get_text "continuing_new_raid")"
        continue_option=$option_number
        ((option_number++))
        
        echo "   $option_number. $(get_text "exiting_script")"
        exit_option=$option_number
        echo ""
        
        while true; do
            read -p "👉 $(get_text "select_option") (1-$exit_option): " choice
            
            if [ "$zfs_found" = true ] && [ "$choice" = "$zfs_option" ]; then
                manage_existing_pools_datasets
                return 1  # Indica que se gestionaron configuraciones existentes
            elif [ "$zfs_found" = true ] && [ "$choice" = "$zfs_delete_option" ]; then
                delete_existing_zfs_pools
                return 1  # Indica que se eliminaron pools
            elif [ "$btrfs_found" = true ] && [ "$choice" = "$btrfs_option" ]; then
                local btrfs_devices_array=()
                for info in "${btrfs_info[@]}"; do
                    IFS=':' read -r device size mount_point uuid <<< "$info"
                    btrfs_devices_array+=("$device")
                done
                delete_existing_btrfs "${btrfs_devices_array[@]}"
                return 1  # Indica que se eliminaron filesystems
            elif [ "$mdadm_found" = true ] && [ "$choice" = "$mdadm_option" ]; then
                show_mdadm_details
                echo ""
                echo "$(get_text "mdadm_management_info")"
                echo "  • mdadm --detail /dev/mdX"
                echo "  • mdadm --stop /dev/mdX"
                echo "  • mdadm --manage /dev/mdX --fail /dev/sdX"
                echo ""
                if confirm "$(get_text "continue_detection")"; then
                    detect_existing_raid_configurations
                    return $?
                else
                    return 1
                fi
            elif [ "$lvm_found" = true ] && [ "$choice" = "$lvm_option" ]; then
                show_lvm_details
                echo ""
                echo "$(get_text "lvm_management_info")"
                echo "  • lvdisplay, vgdisplay, pvdisplay"
                echo "  • lvextend, lvreduce"
                echo "  • vgextend, vgreduce"
                echo ""
                if confirm "$(get_text "continue_detection")"; then
                    detect_existing_raid_configurations
                    return $?
                else
                    return 1
                fi
            elif [ "$choice" = "$continue_option" ]; then
                show_message "$(get_text "continuing_new_raid")..."
                return 0  # Continúa con el flujo normal
            elif [ "$choice" = "$exit_option" ]; then
                show_message "$(get_text "exiting_script")..."
                exit 0
            else
                echo "❌ $(get_text "invalid_option")."
            fi
        done
    else
        echo ""
        echo "$(get_text "no_raid_detected")"
        echo "$(get_text "system_ready_new_raid")"
        echo ""
        return 0  # Continue with normal configuration / Continúa con configuración normal
    fi
}

# Función para mostrar detalles de arrays MDADM
show_mdadm_details() {
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_title "MDADM Array Details"
    else
        show_title "Detalles de Arrays MDADM"
    fi
    
    local mdadm_arrays=$(cat /proc/mdstat 2>/dev/null | grep "^md" | awk '{print $1}')
    if [ -z "$mdadm_arrays" ]; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_warning "No MDADM arrays found"
        else
            show_warning "No se encontraron arrays MDADM"
        fi
        return 0
    fi
    
    for array in $mdadm_arrays; do
        echo ""
        echo "📦 ARRAY: /dev/$array"
        echo "═══════════════════════════════════════════"
        
        # Información detallada del array
        local array_info=$(mdadm --detail "/dev/$array" 2>/dev/null)
        if [ -n "$array_info" ]; then
            echo "$array_info"
        else
            echo "❌ No se pudo obtener información detallada del array"
        fi
        
        echo ""
        echo "📊 ESTADO EN /proc/mdstat:"
        echo "═══════════════════════════════════════════"
        cat /proc/mdstat | grep -A 3 "^$array"
        echo ""
    done
}

# Función para mostrar detalles de Volume Groups LVM
show_lvm_details() {
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_title "LVM Volume Group Details"
    else
        show_title "Detalles de Volume Groups LVM"
    fi
    
    local volume_groups=$(vgdisplay 2>/dev/null | grep "VG Name" | awk '{print $3}')
    if [ -z "$volume_groups" ]; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_warning "No LVM Volume Groups found"
        else
            show_warning "No se encontraron Volume Groups LVM"
        fi
        return 0
    fi
    
    for vg in $volume_groups; do
        echo ""
        echo "📦 VOLUME GROUP: $vg"
        echo "═══════════════════════════════════════════"
        
        # Información detallada del VG
        vgdisplay "$vg" 2>/dev/null
        
        echo ""
        echo "📁 LOGICAL VOLUMES EN $vg:"
        echo "═══════════════════════════════════════════"
        lvdisplay "$vg" 2>/dev/null
        
        echo ""
        echo "💿 PHYSICAL VOLUMES EN $vg:"
        echo "═══════════════════════════════════════════"
        pvdisplay 2>/dev/null | grep -A 10 "$vg" | head -15
        echo ""
    done
}

# Función para eliminar pools ZFS existentes
delete_existing_zfs_pools() {
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_title "Delete Existing ZFS Pools"
    else
        show_title "Eliminación de Pools ZFS Existentes"
    fi
    
    local existing_pools=$(zpool list -H -o name 2>/dev/null)
    if [ -z "$existing_pools" ]; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_warning "No ZFS pools found for deletion"
        else
            show_warning "No se encontraron pools ZFS para eliminar"
        fi
        return 0
    fi
    
    local pools_array=($existing_pools)
    
    echo "⚠️  ADVERTENCIA: Esta operación eliminará completamente los pools seleccionados"
    echo "🔥 TODOS LOS DATOS SE PERDERÁN PERMANENTEMENTE"
    echo ""
    
    echo "Pools ZFS disponibles para eliminar:"
    for i in "${!pools_array[@]}"; do
        local pool="${pools_array[$i]}"
        local pool_health=$(zpool list -H -o health "$pool" 2>/dev/null)
        local pool_size=$(zpool list -H -o size "$pool" 2>/dev/null)
        local pool_used=$(zpool list -H -o allocated "$pool" 2>/dev/null)
        
        echo "  $((i+1)). $pool"
        echo "     💚 Estado: $pool_health | 📊 Tamaño: $pool_size | 📈 Usado: $pool_used"
        
        # Mostrar datasets
        local datasets=$(zfs list -H -o name -r "$pool" 2>/dev/null | grep -v "^${pool}$")
        if [ -n "$datasets" ]; then
            local dataset_count=$(echo "$datasets" | wc -l)
            echo "     📁 Datasets: $dataset_count"
        fi
    done
    
    echo ""
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        echo "Deletion options:"
        echo "  • Pool number (e.g., 1, 2, 3)"
        echo "  • Multiple pools separated by spaces (e.g., 1 3 4)"
        echo "  • 'all' - Delete ALL pools (DANGEROUS!)"
        echo "  • 'cancel' - Cancel operation"
    else
        echo "Opciones de eliminación:"
        echo "  • Número del pool (ej: 1, 2, 3)"
        echo "  • Múltiples pools separados por espacios (ej: 1 3 4)"
        echo "  • 'all' - Eliminar TODOS los pools (¡PELIGROSO!)"
        echo "  • 'cancel' - Cancelar operación"
    fi
    echo ""
    
    while true; do
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            read -p "👉 Pools to delete: " choice
        else
            read -p "👉 Pools a eliminar: " choice
        fi
        
        if [ "$choice" = "cancel" ]; then
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                show_message "Operation cancelled by user"
            else
                show_message "Operación cancelada por el usuario"
            fi
            return 0
        elif [ "$choice" = "all" ]; then
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                show_warning "⚠️  WARNING! You are going to delete ALL ZFS pools"
                show_warning "⚠️  This includes: ${pools_array[*]}"
                
                if confirm "Are you ABSOLUTELY SURE to delete ALL pools?"; then
                    for pool in "${pools_array[@]}"; do
                        echo ""
                        destroy_zfs_pool_safely "$pool"
                    done
                    show_message "✅ All pools have been processed"
                    return 0
                else
                    show_message "Mass deletion cancelled"
                    continue
                fi
            else
                show_warning "⚠️  ¡ADVERTENCIA! Vas a eliminar TODOS los pools ZFS"
                show_warning "⚠️  Esto incluye: ${pools_array[*]}"
                
                if confirm "¿Estás ABSOLUTAMENTE SEGURO de eliminar TODOS los pools?"; then
                    for pool in "${pools_array[@]}"; do
                        echo ""
                        destroy_zfs_pool_safely "$pool"
                    done
                    show_message "✅ Todos los pools han sido procesados"
                    return 0
                else
                    show_message "Eliminación masiva cancelada"
                    continue
                fi
            fi
        elif [[ "$choice" =~ ^[0-9\ ]+$ ]]; then
            # Validar selecciones
            local valid_selections=()
            local invalid_found=false
            
            for num in $choice; do
                if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#pools_array[@]} ]; then
                    local pool_index=$((num-1))
                    local pool_name="${pools_array[$pool_index]}"
                    if [[ ! " ${valid_selections[*]} " =~ " ${pool_name} " ]]; then
                        valid_selections+=("$pool_name")
                    fi
                else
                    echo "❌ Selección inválida: $num (usa números del 1 al ${#pools_array[@]})"
                    invalid_found=true
                fi
            done
            
            if [ "$invalid_found" = true ]; then
                continue
            fi
            
            if [ ${#valid_selections[@]} -eq 0 ]; then
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    show_error "No valid pools selected"
                else
                    show_error "No se seleccionaron pools válidos"
                fi
                continue
            fi
            
            # Mostrar resumen de pools a eliminar
            echo ""
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                show_warning "Pools selected for deletion:"
            else
                show_warning "Pools seleccionados para eliminación:"
            fi
            for pool in "${valid_selections[@]}"; do
                local pool_size=$(zpool list -H -o size "$pool" 2>/dev/null)
                local pool_used=$(zpool list -H -o allocated "$pool" 2>/dev/null)
                echo "  🗑️  $pool (Tamaño: $pool_size, Usado: $pool_used)"
            done
            
            echo ""
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                if confirm "Do you confirm the deletion of these ${#valid_selections[@]} pools?"; then
                    for pool in "${valid_selections[@]}"; do
                        echo ""
                        destroy_zfs_pool_safely "$pool"
                    done
                    show_message "✅ Selected pools have been processed"
                    return 0
                else
                    show_message "Deletion cancelled"
                    continue
                fi
            else
                if confirm "¿Confirmas la eliminación de estos ${#valid_selections[@]} pools?"; then
                    for pool in "${valid_selections[@]}"; do
                        echo ""
                        destroy_zfs_pool_safely "$pool"
                    done
                    show_message "✅ Pools seleccionados han sido procesados"
                    return 0
                else
                    show_message "Eliminación cancelada"
                    continue
                fi
            fi
        else
            echo "❌ Opción inválida. Usa números, 'all' o 'cancel'"
        fi
    done
}

# Función para detectar y gestionar filesystems BTRFS existentes
detect_and_manage_btrfs() {
    if ! command -v btrfs &> /dev/null; then
        return 0
    fi
    
    # Buscar filesystems BTRFS existentes
    local btrfs_devices=()
    local btrfs_info=()
    
    # Buscar en todos los dispositivos
    for device in $(lsblk -dpno NAME | grep -E "sd[a-z]|nvme"); do
        if btrfs filesystem show "$device" 2>/dev/null | grep -q "uuid:"; then
            local device_name=$(basename "$device")
            local btrfs_uuid=$(btrfs filesystem show "$device" 2>/dev/null | grep "uuid:" | awk '{print $4}')
            local size=$(lsblk -dpno SIZE "$device" | tr -d ' ')
            local mount_point=$(mount | grep "$device" | awk '{print $3}' | head -1)
            
            btrfs_devices+=("$device_name")
            if [ -n "$mount_point" ]; then
                btrfs_info+=("$device_name:$size:$mount_point:$btrfs_uuid")
            else
                btrfs_info+=("$device_name:$size:no_montado:$btrfs_uuid")
            fi
        fi
    done
    
    if [ ${#btrfs_devices[@]} -gt 0 ]; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_title "Existing BTRFS Filesystems Detected"
        else
            show_title "Filesystems BTRFS Existentes Detectados"
        fi
        echo ""
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            echo "The following BTRFS filesystems were found:"
        else
            echo "Se encontraron los siguientes filesystems BTRFS:"
        fi
        
        for info in "${btrfs_info[@]}"; do
            IFS=':' read -r device size mount_point uuid <<< "$info"
            echo "  📦 Dispositivo: $device"
            echo "     📏 Tamaño: $size"
            echo "     📁 Montaje: $mount_point"
            echo "     🆔 UUID: $uuid"
            echo ""
        done
        
        echo "🛠️  OPCIONES PARA BTRFS:"
        echo "   1. Eliminar filesystems BTRFS específicos"
        echo "   2. Continuar sin modificar BTRFS"
        echo ""
        
        while true; do
            read -p "👉 Selecciona una opción (1-2): " choice
            case $choice in
                1)
                    delete_existing_btrfs "${btrfs_devices[@]}"
                    break
                    ;;
                2)
                    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                        show_message "Continuing without modifying BTRFS filesystems..."
                    else
                        show_message "Continuando sin modificar filesystems BTRFS..."
                    fi
                    break
                    ;;
                *)
                    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                        echo "❌ Invalid option. Select 1 or 2."
                    else
                        echo "❌ Opción inválida. Selecciona 1 o 2."
                    fi
                    ;;
            esac
        done
    fi
    
    return 0
}

# Función para eliminar filesystems BTRFS existentes
delete_existing_btrfs() {
    local btrfs_devices=("$@")
    
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_title "Delete BTRFS Filesystems"
    else
        show_title "Eliminación de Filesystems BTRFS"
    fi
    
    echo "⚠️  ADVERTENCIA: Esta operación eliminará completamente los filesystems seleccionados"
    echo "🔥 TODOS LOS DATOS SE PERDERÁN PERMANENTEMENTE"
    echo ""
    
    echo "Filesystems BTRFS disponibles para eliminar:"
    for i in "${!btrfs_devices[@]}"; do
        local device="${btrfs_devices[$i]}"
        local size=$(lsblk -dpno SIZE "/dev/$device" | tr -d ' ')
        local mount_point=$(mount | grep "/dev/$device" | awk '{print $3}' | head -1)
        local uuid=$(btrfs filesystem show "/dev/$device" 2>/dev/null | grep "uuid:" | awk '{print $4}')
        
        echo "  $((i+1)). $device"
        echo "     📏 Tamaño: $size"
        if [ -n "$mount_point" ]; then
            echo "     📁 Montado en: $mount_point"
        else
            echo "     📁 No montado"
        fi
        echo "     🆔 UUID: $uuid"
    done
    
    echo ""
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        echo "Deletion options:"
        echo "  • Device number (e.g., 1, 2, 3)"
        echo "  • Multiple devices separated by spaces (e.g., 1 3)"
        echo "  • 'all' - Delete ALL BTRFS filesystems"
        echo "  • 'cancel' - Cancel operation"
    else
        echo "Opciones de eliminación:"
        echo "  • Número del dispositivo (ej: 1, 2, 3)"
        echo "  • Múltiples dispositivos separados por espacios (ej: 1 3)"
        echo "  • 'all' - Eliminar TODOS los filesystems BTRFS"
        echo "  • 'cancel' - Cancelar operación"
    fi
    echo ""
    
    while true; do
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            read -p "👉 Filesystems to delete: " choice
        else
            read -p "👉 Filesystems a eliminar: " choice
        fi
        
        if [ "$choice" = "cancel" ]; then
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                show_message "Operation cancelled by user"
            else
                show_message "Operación cancelada por el usuario"
            fi
            return 0
        elif [ "$choice" = "all" ]; then
            show_warning "⚠️  ¡ADVERTENCIA! Vas a eliminar TODOS los filesystems BTRFS"
            show_warning "⚠️  Esto incluye: ${btrfs_devices[*]}"
            
            if confirm "¿Estás ABSOLUTAMENTE SEGURO de eliminar TODOS los filesystems BTRFS?"; then
                # Agrupar dispositivos por UUID para manejar arrays multi-disco
                local processed_uuids=()
                
                for device in "${btrfs_devices[@]}"; do
                    local device_uuid=$(sudo btrfs filesystem show "/dev/$device" 2>/dev/null | grep "uuid:" | awk '{print $4}')
                    
                    # Verificar si ya procesamos este UUID
                    if [[ ! " ${processed_uuids[*]} " =~ " ${device_uuid} " ]]; then
                        processed_uuids+=("$device_uuid")
                        
                        # Obtener todos los dispositivos del array con este UUID
                        local array_devices=$(sudo btrfs filesystem show "/dev/$device" 2>/dev/null | grep "devid" | awk '{print $NF}' | sed 's|/dev/||')
                        
                        echo ""
                        show_warning "🗑️  Eliminando array BTRFS (UUID: $device_uuid)"
                        show_message "📀 Dispositivos del array: $array_devices"
                        
                        # Usar el primer dispositivo para la eliminación (que limpiará todo el array)
                        destroy_btrfs_array_safely "$device" "$device_uuid"
                    fi
                done
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    show_message "✅ All BTRFS filesystems have been processed"
                else
                    show_message "✅ Todos los filesystems BTRFS han sido procesados"
                fi
                return 0
            else
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    show_message "Mass deletion cancelled"
                else
                    show_message "Eliminación masiva cancelada"
                fi
                continue
            fi
        elif [[ "$choice" =~ ^[0-9\ ]+$ ]]; then
            # Validar selecciones
            local valid_selections=()
            local invalid_found=false
            
            for num in $choice; do
                if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#btrfs_devices[@]} ]; then
                    local device_index=$((num-1))
                    local device_name="${btrfs_devices[$device_index]}"
                    if [[ ! " ${valid_selections[*]} " =~ " ${device_name} " ]]; then
                        valid_selections+=("$device_name")
                    fi
                else
                    echo "❌ Selección inválida: $num (usa números del 1 al ${#btrfs_devices[@]})"
                    invalid_found=true
                fi
            done
            
            if [ "$invalid_found" = true ]; then
                continue
            fi
            
            if [ ${#valid_selections[@]} -eq 0 ]; then
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    show_error "No valid devices selected"
                else
                    show_error "No se seleccionaron dispositivos válidos"
                fi
                continue
            fi
            
            # Mostrar resumen de dispositivos a eliminar
            echo ""
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                show_warning "BTRFS filesystems selected for deletion:"
            else
                show_warning "Filesystems BTRFS seleccionados para eliminación:"
            fi
            for device in "${valid_selections[@]}"; do
                local size=$(lsblk -dpno SIZE "/dev/$device" | tr -d ' ')
                echo "  🗑️  $device (Tamaño: $size)"
            done
            
            echo ""
            if confirm "¿Confirmas la eliminación de estos ${#valid_selections[@]} filesystems?"; then
                # Agrupar dispositivos por UUID para manejar arrays multi-disco
                local processed_uuids=()
                
                for device in "${valid_selections[@]}"; do
                    local device_uuid=$(sudo btrfs filesystem show "/dev/$device" 2>/dev/null | grep "uuid:" | awk '{print $4}')
                    
                    # Verificar si ya procesamos este UUID
                    if [[ ! " ${processed_uuids[*]} " =~ " ${device_uuid} " ]]; then
                        processed_uuids+=("$device_uuid")
                        
                        # Obtener información del array
                        local btrfs_info=$(sudo btrfs filesystem show "/dev/$device" 2>/dev/null)
                        local total_devices=$(echo "$btrfs_info" | grep "Total devices" | awk '{print $3}')
                        
                        echo ""
                        if [ "$total_devices" -gt 1 ]; then
                            # Es un array multi-disco, usar la función de array
                            destroy_btrfs_array_safely "$device" "$device_uuid"
                        else
                            # Es un disco individual, usar la función tradicional
                            destroy_btrfs_safely "$device"
                        fi
                    fi
                done
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    show_message "✅ Selected BTRFS filesystems have been processed"
                else
                    show_message "✅ Filesystems BTRFS seleccionados han sido procesados"
                fi
                return 0
            else
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    show_message "Deletion cancelled"
                else
                    show_message "Eliminación cancelada"
                fi
                continue
            fi
        else
            echo "❌ Opción inválida. Usa números, 'all' o 'cancel'"
        fi
    done
}

# Función para gestionar datasets de pools existentes
manage_existing_pools_datasets() {
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_title "Dataset Management in Existing Pools"
    else
        show_title "Gestión de Datasets en Pools Existentes"
    fi
    
    local existing_pools=$(zpool list -H -o name 2>/dev/null)
    local pools_array=($existing_pools)
    
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        echo "Select the pool where you want to manage datasets:"
    else
        echo "Selecciona el pool donde quieres gestionar datasets:"
    fi
    for i in "${!pools_array[@]}"; do
        local pool="${pools_array[$i]}"
        local pool_health=$(zpool list -H -o health "$pool" 2>/dev/null)
        local pool_free=$(zpool list -H -o free "$pool" 2>/dev/null)
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            echo "  $((i+1)). $pool (Health: $pool_health, Free: $pool_free)"
        else
            echo "  $((i+1)). $pool (Estado: $pool_health, Libre: $pool_free)"
        fi
    done
    echo ""
    
    while true; do
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            read -p "👉 Select pool (1-${#pools_array[@]}): " pool_choice
        else
            read -p "👉 Selecciona pool (1-${#pools_array[@]}): " pool_choice
        fi
        if [[ "$pool_choice" =~ ^[0-9]+$ ]] && [ "$pool_choice" -ge 1 ] && [ "$pool_choice" -le ${#pools_array[@]} ]; then
            local selected_pool="${pools_array[$((pool_choice-1))]}"
            create_datasets_in_pool "$selected_pool"
            break
        else
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "❌ Invalid selection. Use numbers from 1 to ${#pools_array[@]}."
            else
                echo "❌ Selección inválida. Usa números del 1 al ${#pools_array[@]}."
            fi
        fi
    done
    
    # Preguntar si quiere gestionar otro pool
    if [ ${#pools_array[@]} -gt 1 ]; then
        if confirm "¿Deseas gestionar datasets en otro pool?"; then
            manage_existing_pools_datasets
        fi
    fi
}

# Función para eliminar datasets de un pool específico
delete_dataset_from_pool() {
    local pool_name="$1"
    
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_title "Delete Datasets in Pool '$pool_name'"
    else
        show_title "Eliminación de Datasets en Pool '$pool_name'"
    fi
    
    # Obtener datasets existentes (excluyendo el pool raíz)
    local existing_datasets=$(zfs list -H -o name -r "$pool_name" 2>/dev/null | grep -v "^${pool_name}$")
    
    if [ -z "$existing_datasets" ]; then
        show_warning "No hay datasets para eliminar en el pool '$pool_name'"
        echo "Solo existe el pool raíz que no puede ser eliminado desde aquí."
        return 0
    fi
    
    # Convertir a array para manejo más fácil
    local datasets_array=()
    while IFS= read -r dataset; do
        datasets_array+=("$dataset")
    done <<< "$existing_datasets"
    
    echo ""
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        echo "⚠️  WARNING: Dataset deletion is PERMANENT"
        echo "🔥 ALL DATA from the selected dataset will be lost"
    else
        echo "⚠️  ADVERTENCIA: La eliminación de datasets es PERMANENTE"
        echo "🔥 TODOS LOS DATOS del dataset seleccionado se perderán"
    fi
    echo ""
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        echo "📁 Datasets available for deletion:"
    else
        echo "📁 Datasets disponibles para eliminar:"
    fi
    
    for i in "${!datasets_array[@]}"; do
        local dataset="${datasets_array[$i]}"
        local used=$(zfs list -H -o used "$dataset" 2>/dev/null)
        local mountpoint=$(zfs list -H -o mountpoint "$dataset" 2>/dev/null)
        local compression=$(zfs get -H -o value compression "$dataset" 2>/dev/null)
        
        echo "  $((i+1)). $dataset"
        echo "     📊 Usado: $used | 📁 Montaje: $mountpoint | 🗜️ Compresión: $compression"
        
        # Mostrar snapshots si existen
        local snapshots=$(zfs list -t snapshot -H -o name "$dataset" 2>/dev/null | wc -l)
        if [ "$snapshots" -gt 0 ]; then
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "     📸 Snapshots: $snapshots (will also be deleted)"
            else
                echo "     📸 Snapshots: $snapshots (también serán eliminados)"
            fi
        fi
        echo ""
    done
    
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        echo "Deletion options:"
        echo "  • Dataset number (e.g., 1, 2, 3)"
        echo "  • Multiple datasets separated by spaces (e.g., 1 3 4)"
        echo "  • 'all' - Delete ALL datasets (DANGEROUS!)"
        echo "  • 'cancel' - Cancel operation"
    else
        echo "Opciones de eliminación:"
        echo "  • Número del dataset (ej: 1, 2, 3)"
        echo "  • Múltiples datasets separados por espacios (ej: 1 3 4)"
        echo "  • 'all' - Eliminar TODOS los datasets (¡PELIGROSO!)"
        echo "  • 'cancel' - Cancelar operación"
    fi
    echo ""
    
    while true; do
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            read -p "👉 Datasets to delete: " choice
        else
            read -p "👉 Datasets a eliminar: " choice
        fi
        
        if [ "$choice" = "cancel" ]; then
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                show_message "Deletion cancelled by user"
            else
                show_message "Eliminación cancelada por el usuario"
            fi
            return 0
        elif [ "$choice" = "all" ]; then
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                show_warning "⚠️  WARNING! You are going to delete ALL datasets"
                show_warning "⚠️  This includes: ${datasets_array[*]}"
                echo ""
                echo "🔥 THIS WILL PERMANENTLY DELETE:"
                for dataset in "${datasets_array[@]}"; do
                    local used=$(zfs list -H -o used "$dataset" 2>/dev/null)
                    echo "   • $dataset (Used: $used)"
                done
                echo ""
                
                if confirm "Are you ABSOLUTELY SURE to delete ALL datasets?"; then
                    # Eliminar en orden inverso para manejar dependencias
                    for ((i=${#datasets_array[@]}-1; i>=0; i--)); do
                        local dataset="${datasets_array[$i]}"
                        echo ""
                        delete_dataset_safely "$dataset"
                    done
                    show_message "✅ All datasets have been processed"
                    return 0
                else
                    show_message "Mass deletion cancelled"
                    continue
                fi
            else
                show_warning "⚠️  ¡ADVERTENCIA! Vas a eliminar TODOS los datasets"
                show_warning "⚠️  Esto incluye: ${datasets_array[*]}"
                echo ""
                echo "🔥 ESTO ELIMINARÁ PERMANENTEMENTE:"
                for dataset in "${datasets_array[@]}"; do
                    local used=$(zfs list -H -o used "$dataset" 2>/dev/null)
                    echo "   • $dataset (Usado: $used)"
                done
                echo ""
                
                if confirm "¿Estás ABSOLUTAMENTE SEGURO de eliminar TODOS los datasets?"; then
                    # Eliminar en orden inverso para manejar dependencias
                    for ((i=${#datasets_array[@]}-1; i>=0; i--)); do
                        local dataset="${datasets_array[$i]}"
                        echo ""
                        delete_dataset_safely "$dataset"
                    done
                    show_message "✅ Todos los datasets han sido procesados"
                    return 0
                else
                    show_message "Eliminación masiva cancelada"
                    continue
                fi
            fi
        elif [[ "$choice" =~ ^[0-9\ ]+$ ]]; then
            # Validar selecciones
            local valid_selections=()
            local invalid_found=false
            
            for num in $choice; do
                if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#datasets_array[@]} ]; then
                    local dataset_index=$((num-1))
                    local dataset_name="${datasets_array[$dataset_index]}"
                    if [[ ! " ${valid_selections[*]} " =~ " ${dataset_name} " ]]; then
                        valid_selections+=("$dataset_name")
                    fi
                else
                    echo "❌ Selección inválida: $num (usa números del 1 al ${#datasets_array[@]})"
                    invalid_found=true
                fi
            done
            
            if [ "$invalid_found" = true ]; then
                continue
            fi
            
            if [ ${#valid_selections[@]} -eq 0 ]; then
                show_error "No se seleccionaron datasets válidos"
                continue
            fi
            
            # Mostrar resumen de datasets a eliminar
            echo ""
            show_warning "Datasets seleccionados para eliminación:"
            for dataset in "${valid_selections[@]}"; do
                local used=$(zfs list -H -o used "$dataset" 2>/dev/null)
                local snapshots=$(zfs list -t snapshot -H -o name "$dataset" 2>/dev/null | wc -l)
                echo "  🗑️  $dataset (Usado: $used)"
                if [ "$snapshots" -gt 0 ]; then
                    echo "      📸 Incluye $snapshots snapshots"
                fi
            done
            
            echo ""
            if confirm "¿Confirmas la eliminación de estos ${#valid_selections[@]} datasets?"; then
                # Ordenar datasets para eliminar los más profundos primero
                # (importante para evitar errores de dependencias)
                local sorted_selections=($(printf '%s\n' "${valid_selections[@]}" | sort -r))
                
                for dataset in "${sorted_selections[@]}"; do
                    echo ""
                    delete_dataset_safely "$dataset"
                done
                show_message "✅ Datasets seleccionados han sido procesados"
                return 0
            else
                show_message "Eliminación cancelada"
                continue
            fi
        else
            echo "❌ Opción inválida. Usa números, 'all' o 'cancel'"
        fi
    done
}

# Función para eliminar un dataset de forma segura
delete_dataset_safely() {
    local dataset="$1"
    
    if [ -z "$dataset" ]; then
        show_error "Nombre de dataset no especificado"
        return 1
    fi
    
    # Verificar que el dataset existe
    if ! zfs list "$dataset" >/dev/null 2>&1; then
        show_warning "Dataset '$dataset' no encontrado"
        return 0
    fi
    
    show_warning "🗑️  Eliminando dataset: '$dataset'"
    
    # Mostrar información del dataset antes de eliminar
    local used=$(zfs list -H -o used "$dataset" 2>/dev/null)
    local mountpoint=$(zfs list -H -o mountpoint "$dataset" 2>/dev/null)
    local compression=$(zfs get -H -o value compression "$dataset" 2>/dev/null)
    
    echo "   📊 Datos a eliminar: $used"
    echo "   📁 Punto de montaje: $mountpoint"
    echo "   🗜️  Compresión: $compression"
    
    # Verificar y mostrar snapshots
    local snapshots=$(zfs list -t snapshot -H -o name "$dataset" 2>/dev/null)
    if [ -n "$snapshots" ]; then
        local snapshot_count=$(echo "$snapshots" | wc -l)
        echo "   📸 Snapshots a eliminar: $snapshot_count"
        for snapshot in $snapshots; do
            local snap_used=$(zfs list -t snapshot -H -o used "$snapshot" 2>/dev/null)
            echo "      • $snapshot (Usado: $snap_used)"
        done
    fi
    
    # Verificar si tiene datasets hijos
    local child_datasets=$(zfs list -H -o name -r "$dataset" 2>/dev/null | grep -v "^${dataset}$")
    if [ -n "$child_datasets" ]; then
        echo "   📂 Datasets hijos que también serán eliminados:"
        for child in $child_datasets; do
            local child_used=$(zfs list -H -o used "$child" 2>/dev/null)
            echo "      • $child (Usado: $child_used)"
        done
    fi
    
    echo ""
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_warning "⚠️  THIS ACTION WILL PERMANENTLY DELETE:"
        show_warning "    • The dataset '$dataset' and all its data"
        if [ -n "$snapshots" ]; then
            show_warning "    • All dataset snapshots"
        fi
        if [ -n "$child_datasets" ]; then
            show_warning "    • All child datasets and their data"
        fi
    else
        show_warning "⚠️  ESTA ACCIÓN ELIMINARÁ PERMANENTEMENTE:"
        show_warning "    • El dataset '$dataset' y todos sus datos"
        if [ -n "$snapshots" ]; then
            show_warning "    • Todos los snapshots del dataset"
        fi
        if [ -n "$child_datasets" ]; then
            show_warning "    • Todos los datasets hijos y sus datos"
        fi
    fi
    echo ""
    
    # Proceder con la eliminación
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_message "🔄 Deleting dataset '$dataset'..."
    else
        show_message "🔄 Eliminando dataset '$dataset'..."
    fi
    
    # 1. Desmontar el dataset si está montado
    if [ "$mountpoint" != "none" ] && [ "$mountpoint" != "-" ]; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_message "Unmounting dataset..."
        else
            show_message "Desmontando dataset..."
        fi
        sudo zfs unmount "$dataset" 2>/dev/null || true
    fi
    
    # 2. Eliminar el dataset con todos sus snapshots y descendientes
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_message "Destroying dataset and dependencies..."
    else
        show_message "Destruyendo dataset y dependencias..."
    fi
    if sudo zfs destroy -r "$dataset" 2>/dev/null; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_message "✅ Dataset '$dataset' deleted successfully"
        else
            show_message "✅ Dataset '$dataset' eliminado exitosamente"
        fi
    else
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_warning "⚠️  Standard attempt failed, trying forced deletion..."
            
            # Intentar eliminación forzada
            if sudo zfs destroy -f -r "$dataset" 2>/dev/null; then
                show_message "✅ Dataset '$dataset' forcibly deleted"
            else
                show_error "❌ Could not delete dataset '$dataset'"
                show_error "    Possible causes:"
                show_error "    • Dataset in use by some process"
                show_error "    • Snapshot or clone dependencies"
                show_error "    • Insufficient permissions"
                return 1
            fi
        else
            show_warning "⚠️  Intento estándar falló, intentando eliminación forzada..."
            
            # Intentar eliminación forzada
            if sudo zfs destroy -f -r "$dataset" 2>/dev/null; then
                show_message "✅ Dataset '$dataset' eliminado forzadamente"
            else
                show_error "❌ No se pudo eliminar el dataset '$dataset'"
                show_error "    Posibles causas:"
                show_error "    • Dataset en uso por algún proceso"
                show_error "    • Dependencias de snapshots o clones"
                show_error "    • Permisos insuficientes"
                return 1
            fi
        fi
    fi
    
    return 0
}

# Función para crear datasets en un pool específico (reutilizable)
create_datasets_in_pool() {
    local pool_name="$1"
    
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_title "Dataset Management in Pool '$pool_name'"
    else
        show_title "Gestión de Datasets en Pool '$pool_name'"
    fi
    echo ""
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        echo "💡 DATASET INFORMATION:"
    else
        echo "💡 INFORMACIÓN SOBRE DATASETS:"
    fi
    echo "   Los datasets son subdivisiones lógicas dentro del pool ZFS."
    echo "   Beneficios:"
    echo "   • Organización de datos (data, backups, media, etc.)"
    echo "   • Cuotas de espacio independientes"
    echo "   • Snapshots y backups granulares"
    echo "   • Diferentes configuraciones de compresión"
    echo "   • Puntos de montaje personalizados"
    echo ""
    echo "   Ejemplo: $pool_name/data, $pool_name/backups, $pool_name/media"
    echo ""
    
    # Mostrar datasets existentes
    local existing_datasets=$(zfs list -H -o name -r "$pool_name" 2>/dev/null | grep -v "^${pool_name}$")
    if [ -n "$existing_datasets" ]; then
        echo "📁 Datasets existentes en '$pool_name':"
        for dataset in $existing_datasets; do
            local used=$(zfs list -H -o used "$dataset" 2>/dev/null)
            local mountpoint=$(zfs list -H -o mountpoint "$dataset" 2>/dev/null)
            local compression=$(zfs get -H -o value compression "$dataset" 2>/dev/null)
            echo "  ✓ $dataset"
            echo "     📊 Usado: $used | 📁 Montaje: $mountpoint | 🗜️ Compresión: $compression"
        done
        echo ""
    fi
    
    echo "📋 DATASETS COMUNES SUGERIDOS:"
    echo "   1. data     - Datos principales y documentos"
    echo "   2. media    - Videos, fotos, música"
    echo "   3. backups  - Copias de seguridad"
    echo "   4. temp     - Archivos temporales"
    echo "   5. vm       - Máquinas virtuales"
    echo "   6. docker   - Contenedores Docker"
    echo "   7. homes    - Directorios de usuario"
    echo ""
    
    local datasets_created=()
    
    while true; do
        echo "Opciones:"
        echo "  • Nombre del dataset (ej: data, media, backups)"
        echo "  • 'suggested' - Crear datasets comunes (data, media, backups)"
        echo "  • 'list' - Mostrar datasets actuales"
        echo "  • 'delete' - Eliminar dataset existente"
        echo "  • 'done' - Finalizar gestión de datasets"
        echo ""
        
        read -p "👉 Dataset a crear/gestionar: " dataset_choice
        
        if [ "$dataset_choice" = "done" ]; then
            break
        elif [ "$dataset_choice" = "list" ]; then
            # Mostrar datasets actuales
            local current_datasets=$(zfs list -H -o name -r "$pool_name" 2>/dev/null | grep -v "^${pool_name}$")
            if [ -n "$current_datasets" ]; then
                echo ""
                echo "📁 Datasets actuales en '$pool_name':"
                for dataset in $current_datasets; do
                    local used=$(zfs list -H -o used "$dataset" 2>/dev/null)
                    local avail=$(zfs list -H -o avail "$dataset" 2>/dev/null)
                    local mountpoint=$(zfs list -H -o mountpoint "$dataset" 2>/dev/null)
                    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                        echo "  ✓ $dataset (Used: $used, Available: $avail, Mount: $mountpoint)"
                    else
                        echo "  ✓ $dataset (Usado: $used, Disponible: $avail, Montaje: $mountpoint)"
                    fi
                done
                echo ""
            else
                echo "  (no hay datasets creados aún)"
                echo ""
            fi
        elif [ "$dataset_choice" = "delete" ]; then
            delete_dataset_from_pool "$pool_name"
        elif [ "$dataset_choice" = "suggested" ]; then
            local suggested_datasets=("data" "media" "backups")
            
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                show_message "Creating suggested datasets: ${suggested_datasets[*]}"
            else
                show_message "Creando datasets sugeridos: ${suggested_datasets[*]}"
            fi
            
            for dataset in "${suggested_datasets[@]}"; do
                # Verificar si ya existe
                if zfs list "$pool_name/$dataset" >/dev/null 2>&1; then
                    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                        show_message "ℹ️  Dataset '$pool_name/$dataset' already exists"
                    else
                        show_message "ℹ️  Dataset '$pool_name/$dataset' ya existe"
                    fi
                    continue
                fi
                
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    show_message "Creating dataset: $pool_name/$dataset"
                else
                    show_message "Creando dataset: $pool_name/$dataset"
                fi
                
                if sudo zfs create "$pool_name/$dataset"; then
                    datasets_created+=("$dataset")
                    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                        show_message "✅ Dataset '$pool_name/$dataset' created successfully"
                    else
                        show_message "✅ Dataset '$pool_name/$dataset' creado exitosamente"
                    fi
                    
                    # Configurar montaje automático
                    sudo zfs set mountpoint="/$pool_name/$dataset" "$pool_name/$dataset"
                    
                    # Configuraciones específicas por tipo
                    case $dataset in
                        "media")
                            # Optimizar para archivos grandes
                            sudo zfs set recordsize=1M "$pool_name/$dataset"
                            sudo zfs set compression=lz4 "$pool_name/$dataset"
                            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                                show_message "  📺 Optimized for multimedia files"
                            else
                                show_message "  📺 Optimizado para archivos multimedia"
                            fi
                            ;;
                        "backups")
                            # Máxima compresión para backups
                            sudo zfs set compression=gzip "$pool_name/$dataset"
                            sudo zfs set dedup=on "$pool_name/$dataset" 2>/dev/null || true
                            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                                show_message "  💾 Optimized for backups (high compression)"
                            else
                                show_message "  💾 Optimizado para backups (alta compresión)"
                            fi
                            ;;
                        "data")
                            # Balance entre compresión y rendimiento
                            sudo zfs set compression=lz4 "$pool_name/$dataset"
                            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                                show_message "  📁 Optimized for general data"
                            else
                                show_message "  📁 Optimizado para datos generales"
                            fi
                            ;;
                    esac
                else
                    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                        show_error "❌ Error creating dataset '$pool_name/$dataset'"
                    else
                        show_error "❌ Error creando dataset '$pool_name/$dataset'"
                    fi
                fi
            done
            
        elif [ -n "$dataset_choice" ] && [[ "$dataset_choice" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            # Crear dataset individual
            if zfs list "$pool_name/$dataset_choice" >/dev/null 2>&1; then
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    show_message "ℹ️  Dataset '$pool_name/$dataset_choice' already exists"
                else
                    show_message "ℹ️  Dataset '$pool_name/$dataset_choice' ya existe"
                fi
                continue
            fi
            
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                show_message "Creating dataset: $pool_name/$dataset_choice"
            else
                show_message "Creando dataset: $pool_name/$dataset_choice"
            fi
            
            if sudo zfs create "$pool_name/$dataset_choice"; then
                datasets_created+=("$dataset_choice")
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    show_message "✅ Dataset '$pool_name/$dataset_choice' created successfully"
                else
                    show_message "✅ Dataset '$pool_name/$dataset_choice' creado exitosamente"
                fi
                
                # Configurar montaje
                sudo zfs set mountpoint="/$pool_name/$dataset_choice" "$pool_name/$dataset_choice"
                
                # Preguntar por configuraciones específicas
                echo ""
                echo "⚙️  CONFIGURACIONES OPCIONALES para '$dataset_choice':"
                
                if confirm "¿Configurar compresión? (recomendado)"; then
                    echo "Tipos de compresión:"
                    echo "1. lz4 - Rápida, buen balance (recomendado)"
                    echo "2. gzip - Alta compresión, más lenta"
                    echo "3. off - Sin compresión"
                    
                    read -p "Selecciona (1-3) [1]: " compression_choice
                    compression_choice=${compression_choice:-1}
                    
                    case $compression_choice in
                        1) sudo zfs set compression=lz4 "$pool_name/$dataset_choice";;
                        2) sudo zfs set compression=gzip "$pool_name/$dataset_choice";;
                        3) sudo zfs set compression=off "$pool_name/$dataset_choice";;
                    esac
                    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                        show_message "  🗜️  Compression configured"
                    else
                        show_message "  🗜️  Compresión configurada"
                    fi
                fi
                
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    if confirm "Set space quota?"; then
                        read -p "Quota in GB (e.g., 100): " quota_gb
                        if [[ "$quota_gb" =~ ^[0-9]+$ ]] && [ "$quota_gb" -gt 0 ]; then
                            sudo zfs set quota="${quota_gb}G" "$pool_name/$dataset_choice"
                            show_message "  📏 Quota set: ${quota_gb}GB"
                        fi
                    fi
                else
                    if confirm "¿Establecer cuota de espacio?"; then
                        read -p "Cuota en GB (ej: 100): " quota_gb
                        if [[ "$quota_gb" =~ ^[0-9]+$ ]] && [ "$quota_gb" -gt 0 ]; then
                            sudo zfs set quota="${quota_gb}G" "$pool_name/$dataset_choice"
                            show_message "  📏 Cuota establecida: ${quota_gb}GB"
                        fi
                    fi
                fi
                
            else
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    show_error "❌ Error creating dataset '$pool_name/$dataset_choice'"
                else
                    show_error "❌ Error creando dataset '$pool_name/$dataset_choice'"
                fi
            fi
            
        else
            if [ -z "$dataset_choice" ]; then
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    show_error "❌ Dataset name cannot be empty"
                else
                    show_error "❌ El nombre del dataset no puede estar vacío"
                fi
            else
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    show_error "❌ Invalid name. Use only letters, numbers, hyphens and underscores"
                else
                    show_error "❌ Nombre inválido. Usa solo letras, números, guiones y guiones bajos"
                fi
            fi
        fi
        
        echo ""
    done
    
    # Mostrar resumen de datasets creados en esta sesión
    if [ ${#datasets_created[@]} -gt 0 ]; then
        echo ""
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_message "📊 SUMMARY OF DATASETS CREATED IN THIS SESSION:"
        else
            show_message "📊 RESUMEN DE DATASETS CREADOS EN ESTA SESIÓN:"
        fi
        for dataset in "${datasets_created[@]}"; do
            local mountpoint=$(zfs get -H -o value mountpoint "$pool_name/$dataset" 2>/dev/null)
            local compression=$(zfs get -H -o value compression "$pool_name/$dataset" 2>/dev/null)
            local quota=$(zfs get -H -o value quota "$pool_name/$dataset" 2>/dev/null)
            
            echo "  ✅ $pool_name/$dataset"
            echo "     📁 Montaje: $mountpoint"
            echo "     🗜️  Compresión: $compression"
            if [ "$quota" != "none" ]; then
                echo "     📏 Cuota: $quota"
            fi
            echo ""
        done
    fi
}

# Función para verificar si un disco está en uso por RAID
check_disk_raid_status() {
    local disk="$1"
    local raid_info=""
    
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
                raid_profile=$(sudo btrfs filesystem usage "$mount_point" 2>/dev/null | grep "Data," | head -1 | awk '{print $1}' | cut -d',' -f2 | cut -d':' -f1)
                if [ -z "$raid_profile" ]; then
                    raid_profile="single"
                fi
            fi
            
            # Construir información del RAID
            if [ "$total_devices" -gt 1 ]; then
                if [ -n "$mount_point" ]; then
                    raid_info="BTRFS RAID ($raid_profile, $total_devices discos: $device_list) - Montado en: $mount_point"
                else
                    raid_info="BTRFS RAID ($total_devices discos: $device_list)"
                fi
            else
                if [ -n "$mount_point" ]; then
                    raid_info="BTRFS (Single disk) - Montado en: $mount_point"
                else
                    raid_info="BTRFS (Single disk)"
                fi
            fi
        fi
    fi
    
    # Verificar ZFS - método corregido con sed
    if command -v zpool &> /dev/null; then
        # Obtener lista de todos los pools
        local all_pools=$(zpool list -H -o name 2>/dev/null)
        
        for pool in $all_pools; do
            if [ -n "$pool" ]; then
                # Obtener dispositivos del pool usando sed (funciona mejor)
                local pool_devices=$(zpool status "$pool" 2>/dev/null | sed -n '/^\s*sd[a-z]/p' | awk '{print $1}')
                
                # Verificar si el disco está en la lista
                if echo "$pool_devices" | grep -q "^${disk}$"; then
                    local pool_health=$(zpool list -H -o health "$pool" 2>/dev/null)
                    local pool_size=$(zpool list -H -o size "$pool" 2>/dev/null)
                    local pool_type=$(zpool status "$pool" 2>/dev/null | grep -o 'raidz[0-9]*-[0-9]*\|mirror-[0-9]*' | head -1)
                    
                    # Si no hay pool_type específico, es un stripe
                    if [ -z "$pool_type" ]; then
                        pool_type="stripe"
                    fi
                    
                    raid_info="ZFS Pool: $pool ($pool_type, $pool_health, $pool_size)"
                    break
                fi
                
                # También verificar otros tipos de dispositivos (nvme, etc.)
                if [ -z "$raid_info" ]; then
                    local all_devices=$(zpool status "$pool" 2>/dev/null | sed -n '/^\s*[a-z]/p' | grep -v 'raidz\|mirror\|spare\|log\|cache\|replacing' | awk '{print $1}')
                    if echo "$all_devices" | grep -q "^${disk}$"; then
                        local pool_health=$(zpool list -H -o health "$pool" 2>/dev/null)
                        local pool_size=$(zpool list -H -o size "$pool" 2>/dev/null)
                        local pool_type=$(zpool status "$pool" 2>/dev/null | grep -o 'raidz[0-9]*-[0-9]*\|mirror-[0-9]*' | head -1)
                        
                        # Si no hay pool_type específico, es un stripe
                        if [ -z "$pool_type" ]; then
                            pool_type="stripe"
                        fi
                        
                        raid_info="ZFS Pool: $pool ($pool_type, $pool_health, $pool_size)"
                        break
                    fi
                fi
                
                # También verificar particiones (sdc1, sdc9, etc.)
                local disk_partitions=$(lsblk -ln -o NAME "/dev/$disk" 2>/dev/null | grep -v "^${disk##*/}$")
                for partition in $disk_partitions; do
                    if echo "$pool_devices $all_devices" | grep -q "^${partition}$"; then
                        local pool_health=$(zpool list -H -o health "$pool" 2>/dev/null)
                        local pool_size=$(zpool list -H -o size "$pool" 2>/dev/null)
                        local pool_type=$(zpool status "$pool" 2>/dev/null | grep -o 'raidz[0-9]*-[0-9]*\|mirror-[0-9]*' | head -1)
                        
                        # Si no hay pool_type específico, es un stripe
                        if [ -z "$pool_type" ]; then
                            pool_type="stripe"
                        fi
                        
                        raid_info="ZFS Pool: $pool ($pool_type, $pool_health, $pool_size)"
                        break 2
                    fi
                done
            fi
        done
    fi
    
    # Verificar mdadm (Linux Software RAID)
    if command -v mdadm &> /dev/null; then
        local md_array=$(mdadm --examine "/dev/$disk" 2>/dev/null | grep "Array UUID" | awk '{print $4}')
        if [ -n "$md_array" ]; then
            local md_name=$(mdadm --examine "/dev/$disk" 2>/dev/null | grep "Name" | awk '{print $3}')
            raid_info="mdadm RAID: $md_name (UUID: $md_array)"
        fi
    fi
    
    # Verificar LVM
    if command -v pvdisplay &> /dev/null; then
        if pvdisplay "/dev/$disk" 2>/dev/null | grep -q "PV Name"; then
            local vg_name=$(pvdisplay "/dev/$disk" 2>/dev/null | grep "VG Name" | awk '{print $3}')
            raid_info="LVM Physical Volume (VG: $vg_name)"
        fi
    fi
    
    # Verificar si tiene particiones montadas (que no sean ZFS)
    if mount | grep -q "/dev/$disk" && [ -z "$(echo "$raid_info" | grep ZFS)" ]; then
        local mount_points=$(mount | grep "/dev/$disk" | awk '{print $3}' | tr '\n' ' ')
        if [ -n "$raid_info" ]; then
            raid_info="$raid_info, Montado en: $mount_points"
        else
            raid_info="Montado en: $mount_points"
        fi
    fi
    
    echo "$raid_info"
}

# Función para eliminar pools ZFS específicos de forma segura
destroy_zfs_pool_safely() {
    local pool_name="$1"
    local force="${2:-false}"
    
    if [ -z "$pool_name" ]; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_error "ZFS pool name not specified"
        else
            show_error "Nombre de pool ZFS no especificado"
        fi
        return 1
    fi
    
    # Verificar que el pool existe
    if ! zpool list -H -o name 2>/dev/null | grep -q "^${pool_name}$"; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_warning "ZFS pool '$pool_name' not found"
        else
            show_warning "Pool ZFS '$pool_name' no encontrado"
        fi
        return 0
    fi
    
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_warning "🗑️  Preparing deletion of ZFS pool: '$pool_name'"
    else
        show_warning "🗑️  Preparando eliminación del pool ZFS: '$pool_name'"
    fi
    
    # Mostrar información del pool antes de eliminar
    local pool_size=$(zpool list -H -o size "$pool_name" 2>/dev/null)
    local pool_health=$(zpool list -H -o health "$pool_name" 2>/dev/null)
    local pool_devices=$(zpool status "$pool_name" 2>/dev/null | grep -E "^\s+[a-z]" | awk '{print $1}' | grep -v "raidz\|mirror\|spare\|log\|cache\|replacing")
    
    echo "   📊 Tamaño: $pool_size"
    echo "   💚 Estado: $pool_health"
    echo "   💿 Dispositivos: $(echo $pool_devices | tr '\n' ' ')"
    
    # Mostrar datasets que se eliminarán
    local datasets=$(zfs list -H -o name -r "$pool_name" 2>/dev/null)
    if [ -n "$datasets" ]; then
        echo "   📁 Datasets que se eliminarán:"
        for dataset in $datasets; do
            local used=$(zfs list -H -o used "$dataset" 2>/dev/null)
            echo "      • $dataset (Usado: $used)"
        done
    fi
    
    # Mostrar snapshots que se eliminarán
    local snapshots=$(zfs list -t snapshot -H -o name -r "$pool_name" 2>/dev/null)
    if [ -n "$snapshots" ]; then
        echo "   📸 Snapshots que se eliminarán:"
        for snapshot in $snapshots; do
            echo "      • $snapshot"
        done
    fi
    
    echo ""
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_warning "⚠️  THIS ACTION WILL PERMANENTLY DELETE:"
        show_warning "    • The complete ZFS pool '$pool_name'"
        show_warning "    • All datasets and their data"
        show_warning "    • All snapshots"
        show_warning "    • Automatic mount configuration"
    else
        show_warning "⚠️  ESTA ACCIÓN ELIMINARÁ PERMANENTEMENTE:"
        show_warning "    • El pool ZFS '$pool_name' completo"
        show_warning "    • Todos los datasets y sus datos"
        show_warning "    • Todos los snapshots"
        show_warning "    • Configuración de montaje automático"
    fi
    echo ""
    
    if [ "$force" != "true" ]; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            if ! confirm "Are you COMPLETELY SURE to delete pool '$pool_name'?"; then
                show_message "Deletion cancelled by user"
                return 1
            fi
        else
            if ! confirm "¿Estás COMPLETAMENTE SEGURO de eliminar el pool '$pool_name'?"; then
                show_message "Eliminación cancelada por el usuario"
                return 1
            fi
        fi
    fi
    
    # Proceder con la eliminación
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_message "🔄 Deleting ZFS pool '$pool_name'..."
    else
        show_message "🔄 Eliminando pool ZFS '$pool_name'..."
    fi
    
    # 1. Desmontार todos los datasets
    if [ -n "$datasets" ]; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_message "Unmounting datasets..."
        else
            show_message "Desmontando datasets..."
        fi
        for dataset in $datasets; do
            sudo zfs unmount "$dataset" 2>/dev/null || true
        done
    fi
    
    # 2. Intentar exportar el pool primero
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_message "Exporting pool..."
    else
        show_message "Exportando pool..."
    fi
    sudo zpool export "$pool_name" 2>/dev/null || true
    sleep 1
    
    # 3. Destruir el pool
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_message "Destroying pool..."
    else
        show_message "Destruyendo pool..."
    fi
    if sudo zpool destroy -f "$pool_name" 2>/dev/null; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_message "✅ ZFS pool '$pool_name' deleted successfully"
        else
            show_message "✅ Pool ZFS '$pool_name' eliminado exitosamente"
        fi
    else
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_warning "⚠️  Standard attempt failed, forcing deletion..."
        else
            show_warning "⚠️  Intento estándar falló, forzando eliminación..."
        fi
        
        # Intentar importar y destruir forzadamente
        sudo zpool import "$pool_name" 2>/dev/null || true
        sleep 1
        
        if sudo zpool destroy -f "$pool_name" 2>/dev/null; then
            show_message "✅ Pool ZFS '$pool_name' eliminado forzadamente"
        else
            show_error "❌ No se pudo eliminar el pool '$pool_name'"
            return 1
        fi
    fi
    
    # 4. Limpiar referencias en servicios de sistema
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_message "Cleaning system configuration..."
    else
        show_message "Limpiando configuración del sistema..."
    fi
    
    # Limpiar cache de zpool
    sudo rm -f /etc/zfs/zpool.cache 2>/dev/null || true
    
    # Regenerar cache
    sudo zpool import -a 2>/dev/null || true
    
    return 0
}

# Función para eliminar filesystem BTRFS de forma segura
destroy_btrfs_safely() {
    local disk="$1"
    local force="${2:-false}"
    
    if [ -z "$disk" ]; then
        show_error "Disco no especificado para eliminación BTRFS"
        return 1
    fi
    
    # Verificar que es BTRFS
    if ! btrfs filesystem show "/dev/$disk" 2>/dev/null | grep -q "uuid:"; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_warning "No BTRFS filesystem found on /dev/$disk"
        else
            show_warning "No se encontró filesystem BTRFS en /dev/$disk"
        fi
        return 0
    fi
    
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_warning "🗑️  Preparing deletion of BTRFS filesystem on: /dev/$disk"
    else
        show_warning "🗑️  Preparando eliminación del filesystem BTRFS en: /dev/$disk"
    fi
    
    # Obtener información del filesystem
    local btrfs_uuid=$(btrfs filesystem show "/dev/$disk" 2>/dev/null | grep "uuid:" | awk '{print $4}')
    local btrfs_size=$(lsblk -dpno SIZE "/dev/$disk" | tr -d ' ')
    local mount_point=$(mount | grep "/dev/$disk" | awk '{print $3}' | head -1)
    
    echo "   📊 Tamaño: $btrfs_size"
    echo "   🆔 UUID: $btrfs_uuid"
    if [ -n "$mount_point" ]; then
        echo "   📁 Montado en: $mount_point"
    fi
    
    # Mostrar subvolúmenes si existen
    if [ -n "$mount_point" ]; then
        local subvolumes=$(btrfs subvolume list "$mount_point" 2>/dev/null | awk '{print $9}')
        if [ -n "$subvolumes" ]; then
            echo "   📂 Subvolúmenes que se eliminarán:"
            for subvol in $subvolumes; do
                echo "      • $subvol"
            done
        fi
    fi
    
    echo ""
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_warning "⚠️  THIS ACTION WILL PERMANENTLY DELETE:"
        show_warning "    • The complete BTRFS filesystem on /dev/$disk"
        show_warning "    • All data and subvolumes"
        show_warning "    • Automatic mount entries in /etc/fstab"
    else
        show_warning "⚠️  ESTA ACCIÓN ELIMINARÁ PERMANENTEMENTE:"
        show_warning "    • El filesystem BTRFS completo en /dev/$disk"
        show_warning "    • Todos los datos y subvolúmenes"
        show_warning "    • Entradas de montaje automático en /etc/fstab"
    fi
    echo ""
    
    if [ "$force" != "true" ]; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            if ! confirm "Are you COMPLETELY SURE to delete BTRFS on /dev/$disk?"; then
                show_message "Deletion cancelled by user"
                return 1
            fi
        else
            if ! confirm "¿Estás COMPLETAMENTE SEGURO de eliminar el BTRFS en /dev/$disk?"; then
                show_message "Eliminación cancelada por el usuario"
                return 1
            fi
        fi
    fi
    
    # Proceder con la eliminación
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_message "🔄 Deleting BTRFS filesystem on /dev/$disk..."
    else
        show_message "🔄 Eliminando filesystem BTRFS en /dev/$disk..."
    fi
    
    # 1. Desmontar el filesystem
    if [ -n "$mount_point" ]; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_message "Unmounting $mount_point..."
        else
            show_message "Desmontando $mount_point..."
        fi
        sudo umount "$mount_point" 2>/dev/null || sudo umount -f "$mount_point" 2>/dev/null || true
    fi
    
    # Desmontar cualquier partición del disco
    sudo umount "/dev/$disk"* 2>/dev/null || true
    
    # 2. Eliminar entradas de /etc/fstab específicas de BTRFS de forma segura
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_message "Removing BTRFS entries from /etc/fstab..."
    else
        show_message "Eliminando entradas BTRFS de /etc/fstab..."
    fi
    if [ -n "$btrfs_uuid" ]; then
        # Crear backup de fstab con timestamp
        local backup_file="/etc/fstab.backup.$(date +%Y%m%d-%H%M%S)"
        sudo cp /etc/fstab "$backup_file" 2>/dev/null || true
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_message "📋 fstab backup created: $backup_file"
        else
            show_message "📋 Backup de fstab creado: $backup_file"
        fi
        
        # Verificar qué entradas existen antes de eliminar
        local existing_entries=$(grep -E "UUID=$btrfs_uuid" /etc/fstab 2>/dev/null | grep -i btrfs || true)
        if [ -n "$existing_entries" ]; then
            show_message "📝 Entradas BTRFS encontradas en /etc/fstab:"
            echo "$existing_entries" | while read -r entry; do
                echo "   • $entry"
            done
            
            # Eliminar entradas por UUID solo si el tipo de filesystem es btrfs
            # Usar patrones más específicos para mayor seguridad
            sudo sed -i "/^[[:space:]]*UUID=$btrfs_uuid[[:space:]].*[[:space:]]btrfs[[:space:]]/d" /etc/fstab 2>/dev/null || true
            sudo sed -i "/^[[:space:]]*UUID=$btrfs_uuid[[:space:]].*[[:space:]]btrfs$/d" /etc/fstab 2>/dev/null || true
            
            # Verificar si las entradas fueron eliminadas
            local remaining_entries=$(grep -E "UUID=$btrfs_uuid" /etc/fstab 2>/dev/null | grep -i btrfs || true)
            if [ -z "$remaining_entries" ]; then
                show_message "✅ Entradas BTRFS eliminadas exitosamente de /etc/fstab"
            else
                show_warning "⚠️  Algunas entradas BTRFS permanecen en /etc/fstab:"
                echo "$remaining_entries" | while read -r entry; do
                    echo "   • $entry"
                done
            fi
        else
            show_message "ℹ️  No se encontraron entradas BTRFS automount en /etc/fstab para UUID: $btrfs_uuid"
        fi
    fi
    
    # También verificar entradas por device path (menos común pero posible)
    local device_entries=$(grep -E "/dev/$disk" /etc/fstab 2>/dev/null | grep -i btrfs || true)
    if [ -n "$device_entries" ]; then
        show_message "📝 Entradas por device path encontradas:"
        echo "$device_entries" | while read -r entry; do
            echo "   • $entry"
        done
        
        # Eliminar por device path pero solo líneas que contengan btrfs
        sudo sed -i "\|^[[:space:]]*/dev/$disk[[:space:]].*[[:space:]]btrfs[[:space:]]|d" /etc/fstab 2>/dev/null || true
        sudo sed -i "\|^[[:space:]]*/dev/$disk[0-9]*[[:space:]].*[[:space:]]btrfs[[:space:]]|d" /etc/fstab 2>/dev/null || true
        
        # Verificar si fueron eliminadas
        local remaining_device_entries=$(grep -E "/dev/$disk" /etc/fstab 2>/dev/null | grep -i btrfs || true)
        if [ -z "$remaining_device_entries" ]; then
            show_message "✅ Entradas por device path eliminadas exitosamente"
        fi
    fi
    
    # 3. Limpiar metadatos BTRFS
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_message "Cleaning BTRFS metadata..."
    else
        show_message "Limpiando metadatos BTRFS..."
    fi
    sudo wipefs -af "/dev/$disk" 2>/dev/null || true
    
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_message "✅ BTRFS filesystem on /dev/$disk deleted successfully"
    else
        show_message "✅ Filesystem BTRFS en /dev/$disk eliminado exitosamente"
    fi
    return 0
}

# Función para eliminar array BTRFS completo de forma segura
destroy_btrfs_array_safely() {
    local primary_disk="$1"
    local array_uuid="$2"
    
    if [ -z "$primary_disk" ] || [ -z "$array_uuid" ]; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_error "Incorrect parameters for BTRFS array deletion"
        else
            show_error "Parámetros incorrectos para eliminación de array BTRFS"
        fi
        return 1
    fi
    
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_warning "🗑️  Deleting complete BTRFS array (UUID: $array_uuid)"
    else
        show_warning "🗑️  Eliminando array BTRFS completo (UUID: $array_uuid)"
    fi
    
    # Obtener información completa del array
    local btrfs_info=$(sudo btrfs filesystem show "/dev/$primary_disk" 2>/dev/null)
    local total_devices=$(echo "$btrfs_info" | grep "Total devices" | awk '{print $3}')
    local all_devices=$(echo "$btrfs_info" | grep "devid" | awk '{print $NF}' | sed 's|/dev/||')
    local mount_point=$(mount | grep "UUID=$array_uuid" | awk '{print $3}' | head -1)
    
    echo "   📊 Total de dispositivos: $total_devices"
    echo "   📀 Dispositivos: $all_devices"
    if [ -n "$mount_point" ]; then
        echo "   📁 Montado en: $mount_point"
    fi
    
    # Obtener tipo de RAID si está montado
    local raid_profile=""
    if [ -n "$mount_point" ]; then
        raid_profile=$(sudo btrfs filesystem usage "$mount_point" 2>/dev/null | grep "Data," | head -1 | awk '{print $1}' | cut -d',' -f2 | cut -d':' -f1)
        if [ -n "$raid_profile" ]; then
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "   🔧 RAID Configuration: $raid_profile"
            else
                echo "   🔧 Configuración RAID: $raid_profile"
            fi
        fi
    fi
    
    echo ""
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_warning "⚠️  THIS ACTION WILL PERMANENTLY DELETE:"
        show_warning "    • The entire BTRFS array ($total_devices devices)"
        show_warning "    • All data and subvolumes"
        show_warning "    • Automatic mount entries in /etc/fstab"
    else
        show_warning "⚠️  ESTA ACCIÓN ELIMINARÁ PERMANENTEMENTE:"
        show_warning "    • Todo el array BTRFS ($total_devices dispositivos)"
        show_warning "    • Todos los datos y subvolúmenes"
        show_warning "    • Entradas de montaje automático en /etc/fstab"
    fi
    echo ""
    
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        if ! confirm "Are you COMPLETELY SURE to delete this complete BTRFS array?"; then
            show_message "Deletion cancelled by user"
            return 1
        fi
    else
        if ! confirm "¿Estás COMPLETAMENTE SEGURO de eliminar este array BTRFS completo?"; then
            show_message "Eliminación cancelada por el usuario"
            return 1
        fi
    fi
    
    # Proceder con la eliminación del array completo
    show_message "🔄 Eliminando array BTRFS..."
    
    # 1. Desmontar el filesystem
    if [ -n "$mount_point" ]; then
        show_message "Desmontando $mount_point..."
        sudo umount "$mount_point" 2>/dev/null || sudo umount -f "$mount_point" 2>/dev/null || true
    fi
    
    # Desmontar todos los dispositivos del array
    for device in $all_devices; do
        sudo umount "/dev/$device"* 2>/dev/null || true
    done
    
    # 2. Eliminar entradas de /etc/fstab para el array completo
    show_message "Eliminando entradas del array BTRFS de /etc/fstab..."
    local backup_file="/etc/fstab.backup.$(date +%Y%m%d-%H%M%S)"
    sudo cp /etc/fstab "$backup_file" 2>/dev/null || true
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_message "📋 fstab backup created: $backup_file"
    else
        show_message "📋 Backup de fstab creado: $backup_file"
    fi
    
    # Verificar entradas existentes
    local existing_entries=$(grep -E "UUID=$array_uuid" /etc/fstab 2>/dev/null | grep -i btrfs || true)
    if [ -n "$existing_entries" ]; then
        show_message "📝 Eliminando entradas del array BTRFS:"
        echo "$existing_entries" | while read -r entry; do
            echo "   • $entry"
        done
        
        # Eliminar entradas por UUID del array
        sudo sed -i "/^[[:space:]]*UUID=$array_uuid[[:space:]].*[[:space:]]btrfs[[:space:]]/d" /etc/fstab 2>/dev/null || true
        sudo sed -i "/^[[:space:]]*UUID=$array_uuid[[:space:]].*[[:space:]]btrfs$/d" /etc/fstab 2>/dev/null || true
        
        # Verificar eliminación
        local remaining_entries=$(grep -E "UUID=$array_uuid" /etc/fstab 2>/dev/null | grep -i btrfs || true)
        if [ -z "$remaining_entries" ]; then
            show_message "✅ Entradas del array eliminadas exitosamente de /etc/fstab"
        else
            show_warning "⚠️  Algunas entradas del array permanecen en /etc/fstab"
        fi
    else
        show_message "ℹ️  No se encontraron entradas automount para este array"
    fi
    
    # 3. Limpiar metadatos BTRFS de todos los dispositivos
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_message "Cleaning BTRFS metadata from all devices..."
    else
        show_message "Limpiando metadatos BTRFS de todos los dispositivos..."
    fi
    for device in $all_devices; do
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_message "  Cleaning /dev/$device..."
        else
            show_message "  Limpiando /dev/$device..."
        fi
        sudo wipefs -af "/dev/$device" 2>/dev/null || true
    done
    
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_message "✅ Complete BTRFS array deleted successfully"
        show_message "   📀 Devices cleaned: $all_devices"
    else
        show_message "✅ Array BTRFS completo eliminado exitosamente"
        show_message "   📀 Dispositivos limpiados: $all_devices"
    fi
    return 0
}

# Función para limpiar disco de configuraciones RAID anteriores
clean_disk() {
    local disk="$1"
    
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_message "Cleaning disk /dev/$disk..."
    else
        show_message "Limpiando disco /dev/$disk..."
    fi
    
    # Desmontar si está montado
    if mount | grep -q "/dev/$disk"; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_message "Unmounting /dev/$disk..."
        else
            show_message "Desmontando /dev/$disk..."
        fi
        sudo umount "/dev/$disk"* 2>/dev/null || true
    fi
    
    # Verificar y destruir pools ZFS que usen este disco
    if command -v zpool &> /dev/null; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_message "Checking ZFS pools using /dev/$disk..."
        else
            show_message "Verificando pools ZFS que usan /dev/$disk..."
        fi
        
        # Obtener lista de todos los pools
        local all_pools=$(zpool list -H -o name 2>/dev/null)
        local pools_to_destroy=()
        
        for pool in $all_pools; do
            if [ -n "$pool" ]; then
                # Verificar si este disco está en el pool
                if zpool status "$pool" 2>/dev/null | sed -n '/^\s*sd[a-z]/p' | awk '{print $1}' | grep -q "^${disk}$"; then
                    pools_to_destroy+=("$pool")
                elif zpool status "$pool" 2>/dev/null | sed -n '/^\s*[a-z]/p' | grep -v 'raidz\|mirror\|spare\|log\|cache\|replacing' | awk '{print $1}' | grep -q "^${disk}$"; then
                    pools_to_destroy+=("$pool")
                fi
                
                # También verificar particiones
                local disk_partitions=$(lsblk -ln -o NAME "/dev/$disk" 2>/dev/null | grep -v "^${disk##*/}$")
                for partition in $disk_partitions; do
                    if zpool status "$pool" 2>/dev/null | grep -q "$partition"; then
                        pools_to_destroy+=("$pool")
                        break
                    fi
                done
            fi
        done
        
        # Eliminar duplicados de pools
        local unique_pools=($(printf "%s\n" "${pools_to_destroy[@]}" | sort -u))
        
        # Destruir pools encontrados usando la función segura
        for pool in "${unique_pools[@]}"; do
            if [ -n "$pool" ]; then
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    show_warning "🗑️  Detected ZFS pool '$pool' using disk /dev/$disk"
                else
                    show_warning "🗑️  Detectado pool ZFS '$pool' usando el disco /dev/$disk"
                fi
                
                # Usar la función de eliminación segura
                if ! destroy_zfs_pool_safely "$pool" "true"; then
                    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                        show_error "❌ Error deleting pool '$pool'"
                        show_message "Continuing with manual cleanup..."
                        show_warning "⚠️  Trying emergency method..."
                    else
                        show_error "❌ Error eliminando el pool '$pool'"
                        show_message "Continuando con limpieza manual..."
                        show_warning "⚠️  Intentando método de emergencia..."
                    fi
                    
                    # Fallback a método anterior si la función segura falla
                    sudo zpool export "$pool" 2>/dev/null || true
                    sleep 1
                    sudo zpool destroy -f "$pool" 2>/dev/null || true
                fi
            fi
        done
        
        # Limpiar etiquetas ZFS residuales en el disco y particiones
        sudo zpool labelclear -f "/dev/$disk" 2>/dev/null || true
        
        # Limpiar particiones ZFS si existen
        local disk_partitions=$(lsblk -ln -o NAME "/dev/$disk" 2>/dev/null | grep -v "^${disk##*/}$")
        for partition in $disk_partitions; do
            local full_partition="/dev/${partition}"
            sudo zpool labelclear -f "$full_partition" 2>/dev/null || true
        done
    fi
    
    # Verificar y limpiar BTRFS usando la función segura
    if command -v btrfs &> /dev/null; then
        if btrfs filesystem show "/dev/$disk" 2>/dev/null | grep -q "uuid:"; then
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                show_warning "🗑️  Detected BTRFS filesystem on /dev/$disk"
            else
                show_warning "🗑️  Detectado filesystem BTRFS en /dev/$disk"
            fi
            
            # Usar la función de eliminación segura para BTRFS
            if ! destroy_btrfs_safely "$disk" "true"; then
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    show_error "❌ Error deleting BTRFS filesystem"
                    show_message "Continuing with manual cleanup..."
                else
                    show_error "❌ Error eliminando filesystem BTRFS"
                    show_message "Continuando con limpieza manual..."
                fi
                
                # Fallback a limpieza básica
                sudo wipefs -a "/dev/$disk" 2>/dev/null || true
            fi
        fi
    fi
    
    # Limpiar metadatos mdadm
    if command -v mdadm &> /dev/null; then
        sudo mdadm --zero-superblock "/dev/$disk" 2>/dev/null || true
    fi
    
    # Limpiar metadatos LVM
    if command -v pvremove &> /dev/null; then
        sudo pvremove -ff "/dev/$disk" 2>/dev/null || true
    fi
    
    # Limpiar tabla de particiones y metadatos completamente
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_message "🧹 Cleaning partition table and metadata from /dev/$disk..."
    else
        show_message "🧹 Limpiando tabla de particiones y metadatos de /dev/$disk..."
    fi
    
    # Limpiar los primeros 100MB y los últimos 100MB del disco
    sudo dd if=/dev/zero of="/dev/$disk" bs=1M count=100 2>/dev/null || true
    
    # Obtener el tamaño del disco y limpiar el final también
    local disk_size=$(lsblk -dpno SIZE "/dev/$disk" --bytes 2>/dev/null || echo "0")
    if [ "$disk_size" -gt 104857600 ]; then  # Si es mayor a 100MB
        local seek_pos=$(( (disk_size / 1048576) - 100 ))  # 100MB antes del final
        sudo dd if=/dev/zero of="/dev/$disk" bs=1M seek="$seek_pos" count=100 2>/dev/null || true
    fi
    
    # Limpiar con wipefs para asegurar que no queden metadatos
    sudo wipefs -af "/dev/$disk" 2>/dev/null || true
    
    # Forzar actualización de la tabla de particiones
    sudo partprobe "/dev/$disk" 2>/dev/null || true
    sudo udevadm settle 2>/dev/null || true
    
    # Esperar un poco más para que el sistema reconozca los cambios
    sleep 3
    
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_message "✅ Disk /dev/$disk completely cleaned"
    else
        show_message "✅ Disco /dev/$disk limpiado completamente"
    fi
}

# Función para detectar discos disponibles
detect_disks() {
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_title "Detecting available disks"
    else
        show_title "Detectando discos disponibles"
    fi
    
    # Obtener lista de discos, excluyendo dispositivos del sistema
    AVAILABLE_DISKS=()
    DISK_RAID_STATUS=()
    
    # Obtener disco raíz
    ROOT_DISK=$(lsblk -no PKNAME $(findmnt -n -o SOURCE /))
    
    # Obtener discos con particiones montadas en puntos críticos del sistema
    SYSTEM_DISKS=()
    SYSTEM_DISKS+=("$ROOT_DISK")
    
    # Detectar discos que contienen particiones del sistema
    while IFS= read -r device mount_point; do        
        # Excluir puntos de montaje críticos del sistema
        if [[ "$mount_point" == "/" ]] || [[ "$mount_point" == "/boot"* ]] || \
           [[ "$mount_point" == "/usr"* ]] || [[ "$mount_point" == "/var"* ]] || \
           [[ "$mount_point" == "/etc"* ]] || [[ "$mount_point" == "/lib"* ]] || \
           [[ "$mount_point" == "/bin"* ]] || [[ "$mount_point" == "/sbin"* ]]; then
            
            # Extraer el disco base del device
            local base_disk=$(lsblk -no PKNAME "$device" 2>/dev/null || echo "$device" | sed 's|/dev/||' | sed 's/[0-9]*$//')
            if [ -n "$base_disk" ] && [[ ! " ${SYSTEM_DISKS[*]} " =~ " ${base_disk} " ]]; then
                SYSTEM_DISKS+=("$base_disk")
            fi
        fi
    done < <(findmnt -rn -o SOURCE,TARGET | grep -E "^/dev/")
    
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_message "📋 System disks excluded: ${SYSTEM_DISKS[*]}"
    else
        show_message "📋 Discos del sistema excluidos: ${SYSTEM_DISKS[*]}"
    fi
    
    while IFS= read -r disk; do
        # Excluir discos del sistema, dispositivos loop, y particiones
        if [[ ! " ${SYSTEM_DISKS[*]} " =~ " ${disk} " ]] && \
           [[ "$disk" != loop* ]] && [[ "$disk" != ram* ]] && \
           [[ "$disk" != *boot* ]] && [[ ! "$disk" =~ [0-9]$ ]]; then
            
            # Verificar que sea un disco completo, no una partición
            if lsblk -dpno TYPE "/dev/$disk" 2>/dev/null | grep -q "disk"; then
                AVAILABLE_DISKS+=("$disk")
                # Verificar estado RAID del disco
                raid_status=$(check_disk_raid_status "$disk")
                DISK_RAID_STATUS+=("$raid_status")
            fi
        fi
    done < <(lsblk -dpno NAME | sed 's|/dev/||' | grep -v '^$')
    
    if [ ${#AVAILABLE_DISKS[@]} -eq 0 ]; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_error "No available disks found for RAID"
        else
            show_error "No se encontraron discos disponibles para RAID"
        fi
        exit 1
    fi
    
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_message "Found disks:"
    else
        show_message "Discos encontrados:"
    fi
    local disks_with_raid=false
    
    for i in "${!AVAILABLE_DISKS[@]}"; do
        disk="/dev/${AVAILABLE_DISKS[$i]}"
        size=$(lsblk -dpno SIZE "$disk" | tr -d ' ')
        model=$(lsblk -dpno MODEL "$disk" | tr -d ' ')
        status="${DISK_RAID_STATUS[$i]}"
        
        if [ -n "$status" ]; then
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo -e "  $((i+1)). ${AVAILABLE_DISKS[$i]} - $size - $model ${RED}[IN USE: $status]${NC}"
            else
                echo -e "  $((i+1)). ${AVAILABLE_DISKS[$i]} - $size - $model ${RED}[EN USO: $status]${NC}"
            fi
            disks_with_raid=true
        else
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "  $((i+1)). ${AVAILABLE_DISKS[$i]} - $size - $model [FREE]"
            else
                echo "  $((i+1)). ${AVAILABLE_DISKS[$i]} - $size - $model [LIBRE]"
            fi
        fi
    done
    
    # Si hay discos en RAID existentes, preguntar al usuario
    if [ "$disks_with_raid" = true ]; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_warning "ATTENTION! Some disks are being used in existing RAID configurations."
            show_warning "If you continue, you will have the option to clean these disks before creating the new RAID."
            show_warning "This will DESTROY all data on those disks."
            
            if ! confirm "Do you want to continue with the configuration?"; then
                show_message "Configuration cancelled by user"
                exit 0
            fi
        else
            show_warning "¡ATENCIÓN! Algunos discos están siendo utilizados en configuraciones RAID existentes."
            show_warning "Si continúas, tendrás la opción de limpiar estos discos antes de crear el nuevo RAID."
            show_warning "Esto DESTRUIRÁ todos los datos en esos discos."
            
            if ! confirm "¿Deseas continuar con la configuración?"; then
                show_message "Configuración cancelada por el usuario"
                exit 0
            fi
        fi
    fi
    
    # Detectar NVME
    NVME_DISK=""
    for disk in "${AVAILABLE_DISKS[@]}"; do
        if [[ "$disk" == nvme* ]]; then
            NVME_DISK="$disk"
            show_message "Detectado disco NVME: $NVME_DISK"
            break
        fi
    done
}

# Función para seleccionar tipo de filesystem
select_filesystem() {
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_title "Filesystem Selection"
        echo "Select the type of RAID filesystem:"
    else
        show_title "Selección de Sistema de Archivos"
        echo "Selecciona el tipo de sistema de archivos RAID:"
    fi
    echo "1. BTRFS"
    echo "2. ZFS"
    
    while true; do
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            read -p "Select an option (1-2): " choice
        else
            read -p "Selecciona una opción (1-2): " choice
        fi
        case $choice in
            1)
                FILESYSTEM_TYPE="btrfs"
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    show_warning "NOTE: In BTRFS, RAID 5/6 is still experimental"
                else
                    show_warning "NOTA: En BTRFS, RAID 5/6 aún es experimental"
                fi
                break
                ;;
            2)
                FILESYSTEM_TYPE="zfs"
                break
                ;;
            *)
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    echo "Invalid option. Please select 1 or 2."
                else
                    echo "Opción inválida. Por favor selecciona 1 o 2."
                fi
                ;;
        esac
    done
}

# Función para mostrar tipos de RAID
show_raid_types() {
    if [ "$FILESYSTEM_TYPE" = "btrfs" ]; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            echo "Available BTRFS RAID types:"
        else
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Available RAID types in BTRFS:"
            else
                echo "Tipos de RAID disponibles en BTRFS:"
            fi
        fi
        echo "1. RAID 0 (stripe) - No redundancy, maximum performance and capacity"
        echo "2. RAID 1 (mirror) - Data mirrored across drives, 50% capacity"
        echo "3. RAID 5 - Single drive fault tolerance with parity (EXPERIMENTAL)"
        echo "4. RAID 6 - Dual drive fault tolerance with parity (EXPERIMENTAL)"
        echo "5. RAID 10 - Combination of RAID 0 and 1, requires 4+ drives"
    else
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            echo "Available ZFS RAID types:"
        else
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Available RAID types in ZFS:"
            else
                echo "Tipos de RAID disponibles en ZFS:"
            fi
        fi
        echo "1. Stripe - No redundancy, maximum performance"
        echo "2. Mirror - Data mirrored across drives"
        echo "3. RAIDZ1 - Single parity, equivalent to RAID 5"
        echo "4. RAIDZ2 - Double parity, equivalent to RAID 6"
        echo "5. RAIDZ3 - Triple parity, requires 4+ drives"
    fi
}

# Función para calcular capacidad del RAID
calculate_raid_capacity() {
    local raid_type="$1"
    local disk_sizes=("${@:2}")
    local total_capacity=0
    local min_size=${disk_sizes[0]}
    local num_disks=${#disk_sizes[@]}
    
    # Encontrar el disco más pequeño
    for size in "${disk_sizes[@]}"; do
        if [ "$size" -lt "$min_size" ]; then
            min_size=$size
        fi
        total_capacity=$((total_capacity + size))
    done
    
    # Calcular capacidad según tipo de RAID
    case $raid_type in
        "raid0"|"stripe")
            RAID_CAPACITY=$total_capacity
            ;;
        "raid1"|"mirror")
            RAID_CAPACITY=$min_size
            ;;
        "raid5"|"raidz1")
            RAID_CAPACITY=$(( min_size * (num_disks - 1) ))
            ;;
        "raid6"|"raidz2")
            RAID_CAPACITY=$(( min_size * (num_disks - 2) ))
            ;;
        "raid10")
            RAID_CAPACITY=$(( min_size * (num_disks / 2) ))
            ;;
        "raidz3")
            RAID_CAPACITY=$(( min_size * (num_disks - 3) ))
            ;;
    esac
    
    # Mostrar información si hay discos de diferente tamaño
    local sizes_differ=false
    for size in "${disk_sizes[@]}"; do
        if [ "$size" -ne "${disk_sizes[0]}" ]; then
            sizes_differ=true
            break
        fi
    done
    
    if [ "$sizes_differ" = true ]; then
        show_warning "¡ATENCIÓN! Los discos tienen diferentes tamaños:"
        for i in "${!SELECTED_DISKS[@]}"; do
            local disk_gb=$(( ${disk_sizes[$i]} / 1024 / 1024 / 1024 ))
            local disk_formatted=$(format_capacity "$disk_gb")
            echo "  ${SELECTED_DISKS[$i]}: ${disk_formatted}"
        done
        local raid_capacity_gb=$(( RAID_CAPACITY / 1024 / 1024 / 1024 ))
        local raid_capacity_formatted=$(format_capacity "$raid_capacity_gb")
        echo "Capacidad del RAID resultante: ${raid_capacity_formatted}"
        echo "Se utilizará el tamaño del disco más pequeño como referencia."
        
        if ! confirm "¿Deseas continuar con esta configuración?"; then
            show_message "Configuración cancelada por el usuario"
            exit 0
        fi
    fi
}

# Función para formatear capacidad en la unidad más apropiada
format_capacity() {
    local size_gb="$1"
    
    if [ "$size_gb" -ge 1024 ]; then
        local size_tb=$((size_gb / 1024))
        local remainder=$((size_gb % 1024))
        
        if [ "$remainder" -eq 0 ]; then
            echo "${size_tb}TB"
        else
            # Calcular decimales para mostrar X.X TB
            local decimal=$((remainder * 10 / 1024))
            echo "${size_tb}.${decimal}TB"
        fi
    else
        echo "${size_gb}GB"
    fi
}

# Función para mostrar vista previa de la configuración RAID
show_raid_preview() {
    local raid_type="$1"
    local selected_disks=("${@:2}")
    local num_disks=${#selected_disks[@]}
    
    if [ $num_disks -eq 0 ]; then
        return 0
    fi
    
    # Calcular tamaños
    local disk_sizes=()
    local total_raw_gb=0
    local min_size_bytes=""
    
    for disk in "${selected_disks[@]}"; do
        local size_bytes=$(lsblk -dpno SIZE "/dev/$disk" --bytes)
        disk_sizes+=("$size_bytes")
        
        if [ -z "$min_size_bytes" ] || [ "$size_bytes" -lt "$min_size_bytes" ]; then
            min_size_bytes="$size_bytes"
        fi
        
        local size_gb=$((size_bytes / 1024 / 1024 / 1024))
        total_raw_gb=$((total_raw_gb + size_gb))
    done
    
    local min_size_gb=$((min_size_bytes / 1024 / 1024 / 1024))
    local usable_gb=0
    local redundancy_level=""
    local failure_tolerance=""
    local performance_note=""
    
    # Calcular capacidad y características según tipo de RAID
    case "$raid_type" in
        "raid0"|"stripe")
            usable_gb=$total_raw_gb
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                redundancy_level="❌ NO REDUNDANCY"
                failure_tolerance="⚠️  1 disk failure = TOTAL LOSS"
                performance_note="🚀 Maximum performance (read and write)"
            else
                redundancy_level="❌ SIN REDUNDANCIA"
                failure_tolerance="⚠️  Fallo de 1 disco = PÉRDIDA TOTAL"
                performance_note="🚀 Máximo rendimiento (lectura y escritura)"
            fi
            ;;
        "raid1"|"mirror")
            usable_gb=$min_size_gb
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                redundancy_level="✅ FULL MIRROR"
                failure_tolerance="✅ Tolerates failure of up to $((num_disks-1)) disk(s)"
                performance_note="⚡ Good read performance, normal write"
            else
                redundancy_level="✅ ESPEJO COMPLETO"
                failure_tolerance="✅ Tolera fallo de hasta $((num_disks-1)) disco(s)"
                performance_note="⚡ Buen rendimiento de lectura, escritura normal"
            fi
            ;;
        "raid5"|"raidz1")
            usable_gb=$((min_size_gb * (num_disks - 1)))
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                redundancy_level="✅ SINGLE PARITY"
                failure_tolerance="✅ Tolerates 1 disk failure"
                performance_note="⚡ Good balanced performance"
            else
                redundancy_level="✅ PARIDAD SIMPLE"
                failure_tolerance="✅ Tolera fallo de 1 disco"
                performance_note="⚡ Buen rendimiento balanceado"
            fi
            ;;
        "raid6"|"raidz2")
            usable_gb=$((min_size_gb * (num_disks - 2)))
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                redundancy_level="✅ DOUBLE PARITY"
                failure_tolerance="✅ Tolerates up to 2 disk failures"
                performance_note="⚡ Moderate performance"
            else
                redundancy_level="✅ PARIDAD DOBLE"
                failure_tolerance="✅ Tolera fallo de hasta 2 discos"
                performance_note="⚡ Rendimiento moderado"
            fi
            ;;
        "raid10")
            usable_gb=$((min_size_gb * (num_disks / 2)))
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                redundancy_level="✅ MIRROR + STRIPING"
                failure_tolerance="✅ Tolerates 1 disk failure per mirror"
                performance_note="🚀 High performance (read and write)"
            else
                redundancy_level="✅ ESPEJO + STRIPING"
                failure_tolerance="✅ Tolera fallo de 1 disco por espejo"
                performance_note="🚀 Alto rendimiento (lectura y escritura)"
            fi
            ;;
        "raidz3")
            usable_gb=$((min_size_gb * (num_disks - 3)))
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                redundancy_level="✅ TRIPLE PARITY"
                failure_tolerance="✅ Tolerates up to 3 disk failures"
                performance_note="⚡ Conservative performance"
            else
                redundancy_level="✅ PARIDAD TRIPLE"
                failure_tolerance="✅ Tolera fallo de hasta 3 discos"
                performance_note="⚡ Rendimiento conservador"
            fi
            ;;
    esac
    
    local efficiency=$((usable_gb * 100 / total_raw_gb))
    
    # Formatear capacidades
    local min_size_formatted=$(format_capacity "$min_size_gb")
    local total_raw_formatted=$(format_capacity "$total_raw_gb")
    local usable_formatted=$(format_capacity "$usable_gb")
    
    echo ""
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        echo "🎯 RESULTING RAID CONFIGURATION:"
        echo "════════════════════════════════════════════════════════════════"
        echo "📦 CAPACITY:"
        echo "   Disks: $num_disks x ${min_size_formatted}"
        echo "   Total raw capacity: ${total_raw_formatted}"
        echo "   Usable capacity: ${usable_formatted}"
        echo "   Storage efficiency: ${efficiency}%"
        echo ""
        echo "🔒 DATA PROTECTION:"
        echo "   $redundancy_level"
        echo "   $failure_tolerance"
        echo ""
        echo "⚡ PERFORMANCE:"
        echo "   $performance_note"
    else
        echo "🎯 CONFIGURACIÓN RAID RESULTANTE:"
        echo "════════════════════════════════════════════════════════════════"
        echo "📦 CAPACIDAD:"
        echo "   Discos: $num_disks x ${min_size_formatted}"
        echo "   Capacidad bruta total: ${total_raw_formatted}"
        echo "   Capacidad utilizable: ${usable_formatted}"
        echo "   Eficiencia de almacenamiento: ${efficiency}%"
        echo ""
        echo "🔒 PROTECCIÓN DE DATOS:"
        echo "   $redundancy_level"
        echo "   $failure_tolerance"
        echo ""
        echo "⚡ RENDIMIENTO:"
        echo "   $performance_note"
    fi
    
    # Verificar si hay diferencias de tamaño significativas
    local max_size_bytes=$(printf '%s\n' "${disk_sizes[@]}" | sort -nr | head -1)
    local size_diff=$((max_size_bytes - min_size_bytes))
    local size_variance=$((size_diff * 100 / max_size_bytes))
    
    if [ $size_variance -gt 10 ]; then
        local max_size_gb=$((max_size_bytes / 1024 / 1024 / 1024))
        local wasted_gb=$(((max_size_gb - min_size_gb) * num_disks))
        
        local min_size_formatted=$(format_capacity "$min_size_gb")
        local max_size_formatted=$(format_capacity "$max_size_gb")
        local wasted_formatted=$(format_capacity "$wasted_gb")
        
        echo ""
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            echo "⚠️  WARNING - SIZE DIFFERENCE:"
            echo "   Smallest disk: ${min_size_formatted}"
            echo "   Largest disk: ${max_size_formatted}"
            echo "   Wasted space: ~${wasted_formatted}"
            echo "   💡 It's recommended to use similarly sized disks"
        else
            echo "⚠️  ADVERTENCIA - DIFERENCIA DE TAMAÑOS:"
            echo "   Disco más pequeño: ${min_size_formatted}"
            echo "   Disco más grande: ${max_size_formatted}"
            echo "   Espacio desperdiciado: ~${wasted_formatted}"
            echo "   💡 Se recomienda usar discos de tamaño similar"
        fi
    fi
    
    # Advertencias específicas
    if [[ "$raid_type" == "raid5" || "$raid_type" == "raid6" ]] && [ "$FILESYSTEM_TYPE" = "btrfs" ]; then
        echo ""
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            echo "⚠️  BTRFS WARNING:"
            echo "   RAID 5/6 in BTRFS is EXPERIMENTAL and may cause corruption"
        else
            echo "⚠️  ADVERTENCIA BTRFS:"
            echo "   RAID 5/6 en BTRFS es EXPERIMENTAL y puede causar corrupción"
        fi
        echo "   💡 Considera usar ZFS para RAID 5/6, o RAID 1/10 en BTRFS"
    fi
    
    echo "════════════════════════════════════════════════════════════════"
}

# Función para seleccionar discos
select_disks() {
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_title "Disk Selection"
    else
        show_title "Selección de Discos"
    fi
    
    local min_disks=2
    case $RAID_TYPE in
        "raid5"|"raidz1") min_disks=3;;
        "raid6"|"raidz2") min_disks=4;;
        "raid10") min_disks=4;;
        "raidz3") min_disks=4;;
    esac
    
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_message "Select disks for RAID (minimum $min_disks disks):"
        echo ""
        echo "📖 SELECTION INSTRUCTIONS:"
        echo "   Individual selection: Write disk number (ex: 3)"
        echo "   Multiple selection:   Write numbers separated by spaces (ex: 3 4 5 6)"
        echo "   Range selection:      Write range with dash (ex: 3-6)"
        echo "   Toggle selection:     Write disk number again to add/remove"
        echo ""
        echo "🎯 SPECIAL COMMANDS:"
        echo "   'clear' - Clear all selection"
        echo "   'done'  - Finish selection and continue"
        echo ""
        echo "💡 TIP: You can modify your selection at any time by entering more disk numbers"
    else
        show_message "Selecciona los discos para el RAID (mínimo $min_disks discos):"
        echo ""
        echo "📖 INSTRUCCIONES DE SELECCIÓN:"
        echo "   Selección individual: Escribe el número del disco (ej: 3)"
        echo "   Selección múltiple:   Escribe números separados por espacios (ej: 3 4 5 6)"
        echo "   Selección por rango:  Escribe rango con guión (ej: 3-6)"
        echo "   Alternar selección:   Vuelve a escribir el número del disco para agregar/quitar"
        echo ""
        echo "🎯 COMANDOS ESPECIALES:"
        echo "   'clear' - Limpiar toda la selección"
        echo "   'done'  - Finalizar selección y continuar"
        echo ""
        echo "💡 CONSEJO: Puedes modificar tu selección en cualquier momento ingresando más números de disco"
    fi
    echo ""
    
    SELECTED_DISKS=()
    SELECTED_DISK_SIZES=()
    DISKS_TO_CLEAN=()
    
    while true; do
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            echo "Available disks:"
        else
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Available disks:"
            else
                echo "Discos disponibles:"
            fi
        fi
        for i in "${!AVAILABLE_DISKS[@]}"; do
            disk="/dev/${AVAILABLE_DISKS[$i]}"
            size=$(lsblk -dpno SIZE "$disk" | tr -d ' ')
            status="${DISK_RAID_STATUS[$i]}"
            
            if [ -n "$status" ]; then
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    echo -e "  $((i+1)). ${AVAILABLE_DISKS[$i]} - $size ${RED}[IN USE: $status]${NC}"
                else
                    echo -e "  $((i+1)). ${AVAILABLE_DISKS[$i]} - $size ${RED}[EN USO: $status]${NC}"
                fi
            else
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    echo "  $((i+1)). ${AVAILABLE_DISKS[$i]} - $size [FREE]"
                else
                    echo "  $((i+1)). ${AVAILABLE_DISKS[$i]} - $size [LIBRE]"
                fi
            fi
        done
        
        echo ""
        if [ ${#SELECTED_DISKS[@]} -gt 0 ]; then
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "✅ Selected disks (${#SELECTED_DISKS[@]}/${#AVAILABLE_DISKS[@]}): ${SELECTED_DISKS[*]}"
            else
                echo "✅ Discos seleccionados (${#SELECTED_DISKS[@]}/${#AVAILABLE_DISKS[@]}): ${SELECTED_DISKS[*]}"
            fi
            
            # Mostrar vista previa de la configuración RAID
            show_raid_preview "$RAID_TYPE" "${SELECTED_DISKS[@]}"
        else
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "⭕ Selected disks: none"
            else
                echo "⭕ Discos seleccionados: ninguno"
            fi
        fi
        echo ""
        
        # Show available commands reminder
        if [ ${#SELECTED_DISKS[@]} -ge $min_disks ]; then
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "💡 AVAILABLE COMMANDS:"
                echo "   • 'done' - Finish selection and continue"
                echo "   • 'clear' - Clear all selected disks"
                echo "   • Add more disks: Enter disk number (ex: 1, 2)"
                echo "   • Remove disks: Enter selected disk number again"
                echo "   • Use ranges: Enter range (ex: 1-2)"
            else
                echo "💡 COMANDOS DISPONIBLES:"
                echo "   • 'done' - Finalizar selección y continuar"
                echo "   • 'clear' - Limpiar todos los discos seleccionados"
                echo "   • Agregar más discos: Ingresa número de disco (ej: 1, 2)"
                echo "   • Quitar discos: Ingresa número de disco seleccionado otra vez"
                echo "   • Usar rangos: Ingresa rango (ej: 1-2)"
            fi
        else
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "💡 AVAILABLE COMMANDS:"
                echo "   • Enter disk numbers: Individual (ex: 3), multiple (ex: 3 4 5), ranges (ex: 3-6)"
                echo "   • 'clear' - Reset selection"
                echo "   • Need minimum $min_disks disks to continue"
            else
                echo "💡 COMANDOS DISPONIBLES:"
                echo "   • Ingresa números de disco: Individual (ej: 3), múltiple (ej: 3 4 5), rangos (ej: 3-6)"
                echo "   • 'clear' - Resetear selección"
                echo "   • Se necesitan mínimo $min_disks discos para continuar"
            fi
        fi
        echo ""
        
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            read -p "👉 Selection: " choice
        else
            read -p "👉 Selección: " choice
        fi
        
        if [ "$choice" = "done" ]; then
            if [ ${#SELECTED_DISKS[@]} -ge $min_disks ]; then
                break
            else
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    show_error "❌ You need at least $min_disks disks for this RAID"
                else
                    show_error "❌ Necesitas al menos $min_disks discos para este RAID"
                fi
            fi
        elif [ "$choice" = "clear" ]; then
            SELECTED_DISKS=()
            SELECTED_DISK_SIZES=()
            DISKS_TO_CLEAN=()
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                show_message "🧹 Selection cleared"
            else
                show_message "🧹 Selección limpiada"
            fi
        elif [[ "$choice" =~ ^[0-9]+(-[0-9]+)?$ ]]; then
            # Manejar rangos (ej: 3-6)
            if [[ "$choice" =~ - ]]; then
                local start=$(echo "$choice" | cut -d'-' -f1)
                local end=$(echo "$choice" | cut -d'-' -f2)
                
                if [ "$start" -ge 1 ] && [ "$end" -le ${#AVAILABLE_DISKS[@]} ] && [ "$start" -le "$end" ]; then
                    for ((i=start; i<=end; i++)); do
                        local disk_index=$((i-1))
                        local disk="${AVAILABLE_DISKS[$disk_index]}"
                        local disk_status="${DISK_RAID_STATUS[$disk_index]}"
                        
                        # Procesar disco (similar a la lógica individual)
                        if [[ ! " ${SELECTED_DISKS[*]} " =~ " ${disk} " ]]; then
                            if [ -n "$disk_status" ]; then
                                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                                    show_warning "⚠️  Disk $disk is in use: $disk_status"
                                    if confirm "Clean $disk and add it?"; then
                                        SELECTED_DISKS+=("$disk")
                                        disk_size=$(lsblk -dpno SIZE "/dev/$disk" --bytes)
                                        SELECTED_DISK_SIZES+=("$disk_size")
                                        DISKS_TO_CLEAN+=("$disk")
                                    fi
                                else
                                    show_warning "⚠️  Disco $disk está en uso: $disk_status"
                                    if confirm "¿Limpiar $disk y agregarlo?"; then
                                        SELECTED_DISKS+=("$disk")
                                        disk_size=$(lsblk -dpno SIZE "/dev/$disk" --bytes)
                                        SELECTED_DISK_SIZES+=("$disk_size")
                                        DISKS_TO_CLEAN+=("$disk")
                                    fi
                                fi
                            else
                                SELECTED_DISKS+=("$disk")
                                disk_size=$(lsblk -dpno SIZE "/dev/$disk" --bytes)
                                SELECTED_DISK_SIZES+=("$disk_size")
                            fi
                        fi
                    done
                    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                        show_message "✅ Processed range $start-$end"
                    else
                        show_message "✅ Procesado rango $start-$end"
                    fi
                else
                    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                        echo "❌ Invalid range. Use format: start-end (ex: 3-6)"
                    else
                        echo "❌ Rango inválido. Usa formato: inicio-fin (ej: 3-6)"
                    fi
                fi
            else
                # Selección individual (lógica original)
                if [ "$choice" -ge 1 ] && [ "$choice" -le ${#AVAILABLE_DISKS[@]} ]; then
                    disk_index=$((choice-1))
                    disk="${AVAILABLE_DISKS[$disk_index]}"
                    disk_status="${DISK_RAID_STATUS[$disk_index]}"
                    
                    # Verificar si ya está seleccionado
                    if [[ " ${SELECTED_DISKS[*]} " =~ " ${disk} " ]]; then
                        # Quitar de la selección
                        new_selected=()
                        new_sizes=()
                        new_to_clean=()
                        for i in "${!SELECTED_DISKS[@]}"; do
                            if [ "${SELECTED_DISKS[$i]}" != "$disk" ]; then
                                new_selected+=("${SELECTED_DISKS[$i]}")
                                new_sizes+=("${SELECTED_DISK_SIZES[$i]}")
                            fi
                        done
                        SELECTED_DISKS=("${new_selected[@]}")
                        SELECTED_DISK_SIZES=("${new_sizes[@]}")
                        # Remover de discos a limpiar si estaba ahí
                        for i in "${!DISKS_TO_CLEAN[@]}"; do
                            if [ "${DISKS_TO_CLEAN[$i]}" != "$disk" ]; then
                                new_to_clean+=("${DISKS_TO_CLEAN[$i]}")
                            fi
                        done
                        DISKS_TO_CLEAN=("${new_to_clean[@]}")
                        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                            show_message "➖ Removed: $disk"
                        else
                            show_message "➖ Removido: $disk"
                        fi
                    else
                        # Verificar si el disco está en uso
                        if [ -n "$disk_status" ]; then
                            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                                show_warning "⚠️  Disk $disk is in use: $disk_status"
                                show_warning "⚠️  If you continue, this disk will be completely cleaned and ALL data will be lost."
                                
                                if confirm "Do you want to clean this disk and use it for the new RAID?"; then
                                    SELECTED_DISKS+=("$disk")
                                    disk_size=$(lsblk -dpno SIZE "/dev/$disk" --bytes)
                                    SELECTED_DISK_SIZES+=("$disk_size")
                                    DISKS_TO_CLEAN+=("$disk")
                                    show_message "✅ Added (will be cleaned): $disk"
                                else
                                    show_message "❌ Disk $disk not selected"
                                fi
                            else
                                show_warning "⚠️  El disco $disk está en uso: $disk_status"
                                show_warning "⚠️  Si continúas, este disco será completamente limpiado y se perderán TODOS los datos."
                                
                                if confirm "¿Deseas limpiar este disco y usarlo para el nuevo RAID?"; then
                                    SELECTED_DISKS+=("$disk")
                                    disk_size=$(lsblk -dpno SIZE "/dev/$disk" --bytes)
                                    SELECTED_DISK_SIZES+=("$disk_size")
                                    DISKS_TO_CLEAN+=("$disk")
                                    show_message "✅ Agregado (se limpiará): $disk"
                                else
                                    show_message "❌ Disco $disk no seleccionado"
                                fi
                            fi
                        else
                            # Agregar a la selección (disco libre)
                            SELECTED_DISKS+=("$disk")
                            disk_size=$(lsblk -dpno SIZE "/dev/$disk" --bytes)
                            SELECTED_DISK_SIZES+=("$disk_size")
                            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                                show_message "✅ Added: $disk"
                            else
                                show_message "✅ Agregado: $disk"
                            fi
                        fi
                    fi
                else
                    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                        echo "❌ Invalid number. Use 1-${#AVAILABLE_DISKS[@]}"
                    else
                        echo "❌ Número inválido. Usa 1-${#AVAILABLE_DISKS[@]}"
                    fi
                fi
            fi
        elif [[ "$choice" =~ ^[0-9\ ]+$ ]]; then
            # Manejar múltiples números separados por espacios (ej: 3 4 5 6)
            for num in $choice; do
                if [ "$num" -ge 1 ] && [ "$num" -le ${#AVAILABLE_DISKS[@]} ]; then
                    disk_index=$((num-1))
                    disk="${AVAILABLE_DISKS[$disk_index]}"
                    disk_status="${DISK_RAID_STATUS[$disk_index]}"
                    
                    if [[ ! " ${SELECTED_DISKS[*]} " =~ " ${disk} " ]]; then
                        if [ -n "$disk_status" ]; then
                            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                                show_warning "⚠️  Disk $disk is in use: $disk_status"
                                if confirm "Clean $disk and add it?"; then
                                    SELECTED_DISKS+=("$disk")
                                    disk_size=$(lsblk -dpno SIZE "/dev/$disk" --bytes)
                                    SELECTED_DISK_SIZES+=("$disk_size")
                                    DISKS_TO_CLEAN+=("$disk")
                                    show_message "✅ Added (will be cleaned): $disk"
                                fi
                            else
                                show_warning "⚠️  Disco $disk está en uso: $disk_status"
                                if confirm "¿Limpiar $disk y agregarlo?"; then
                                    SELECTED_DISKS+=("$disk")
                                    disk_size=$(lsblk -dpno SIZE "/dev/$disk" --bytes)
                                    SELECTED_DISK_SIZES+=("$disk_size")
                                    DISKS_TO_CLEAN+=("$disk")
                                    show_message "✅ Agregado (se limpiará): $disk"
                                fi
                            fi
                        else
                            SELECTED_DISKS+=("$disk")
                            disk_size=$(lsblk -dpno SIZE "/dev/$disk" --bytes)
                            SELECTED_DISK_SIZES+=("$disk_size")
                            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                                show_message "✅ Added: $disk"
                            else
                                show_message "✅ Agregado: $disk"
                            fi
                        fi
                    else
                        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                            show_message "ℹ️  $disk was already selected"
                        else
                            show_message "ℹ️  $disk ya estaba seleccionado"
                        fi
                    fi
                else
                    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                        echo "❌ Invalid number: $num (use 1-${#AVAILABLE_DISKS[@]})"
                    else
                        echo "❌ Número inválido: $num (usa 1-${#AVAILABLE_DISKS[@]})"
                    fi
                fi
            done
        else
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "Invalid option"
            else
                echo "Opción inválida"
            fi
        fi
    done
    
    # Si hay discos para limpiar, mostrar resumen y confirmar
    if [ ${#DISKS_TO_CLEAN[@]} -gt 0 ]; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_warning "SUMMARY OF DISKS TO CLEAN:"
        else
            show_warning "RESUMEN DE DISCOS A LIMPIAR:"
        fi
        for disk in "${DISKS_TO_CLEAN[@]}"; do
            # Encontrar el índice del disco para mostrar su estado
            for i in "${!AVAILABLE_DISKS[@]}"; do
                if [ "${AVAILABLE_DISKS[$i]}" = "$disk" ]; then
                    echo -e "  - $disk: ${DISK_RAID_STATUS[$i]}"
                    break
                fi
            done
        done
        
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_warning "ALL DATA ON THESE DISKS WILL BE PERMANENTLY LOST!"
            
            if ! confirm "Are you completely sure you want to continue?"; then
                show_message "Operation cancelled by user"
                exit 0
            fi
        else
            show_warning "¡TODOS LOS DATOS EN ESTOS DISCOS SE PERDERÁN PERMANENTEMENTE!"
            
            if ! confirm "¿Estás completamente seguro de que deseas continuar?"; then
                show_message "Operación cancelada por el usuario"
                exit 0
            fi
        fi
        
        # Proceder con la limpieza
        for disk in "${DISKS_TO_CLEAN[@]}"; do
            clean_disk "$disk"
        done
        
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_message "All disks have been cleaned successfully"
        else
            show_message "Todos los discos han sido limpiados exitosamente"
        fi
    fi
    
    # Calcular capacidad del RAID
    calculate_raid_capacity "$RAID_TYPE" "${SELECTED_DISK_SIZES[@]}"
}

# Función para configurar BTRFS
setup_btrfs() {
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_title "Configuring BTRFS RAID"
    else
        show_title "Configurando BTRFS RAID"
    fi
    
    # Seleccionar tipo de RAID
    show_raid_types
    while true; do
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            read -p "Select RAID type (1-5): " choice
        else
            read -p "Selecciona el tipo de RAID (1-5): " choice
        fi
        case $choice in
            1) RAID_TYPE="raid0"; break;;
            2) RAID_TYPE="raid1"; break;;
            3) RAID_TYPE="raid5"; 
               if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                   show_warning "RAID 5 is experimental in BTRFS"
                   if confirm "Do you want to continue?"; then break; else continue; fi
               else
                   show_warning "RAID 5 es experimental en BTRFS"
                   if confirm "¿Deseas continuar?"; then break; else continue; fi
               fi;;
            4) RAID_TYPE="raid6";
               if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                   show_warning "RAID 6 is experimental in BTRFS"
                   if confirm "Do you want to continue?"; then break; else continue; fi
               else
                   show_warning "RAID 6 es experimental en BTRFS"
                   if confirm "¿Deseas continuar?"; then break; else continue; fi
               fi;;
            5) RAID_TYPE="raid10"; break;;
            *) 
               if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                   echo "Invalid option"
               else
                   echo "Opción inválida"
               fi;;
        esac
    done
    
    select_disks
    
    # Solicitar punto de montaje
    read -p "Ingresa la ruta donde quieres montar el RAID (ej: /mnt/raid): " MOUNT_POINT
    
    if [ ! -d "$MOUNT_POINT" ]; then
        if confirm "El directorio $MOUNT_POINT no existe. ¿Deseas crearlo?"; then
            sudo mkdir -p "$MOUNT_POINT"
            show_message "Directorio $MOUNT_POINT creado"
        else
            show_error "Se necesita un punto de montaje válido"
            exit 1
        fi
    fi
    
    # Crear el filesystem BTRFS
    show_message "Creando filesystem BTRFS..."
    
    device_list=""
    for disk in "${SELECTED_DISKS[@]}"; do
        device_list="$device_list /dev/$disk"
    done
    
    sudo mkfs.btrfs -f -d "$RAID_TYPE" -m "$RAID_TYPE" $device_list
    
    # Montar el filesystem
    sudo mount "/dev/${SELECTED_DISKS[0]}" "$MOUNT_POINT"
    
    show_message "BTRFS RAID configurado exitosamente"
    FILESYSTEM_UUID=$(sudo blkid -s UUID -o value "/dev/${SELECTED_DISKS[0]}")
}

# Función para obtener RAM del sistema
get_system_ram() {
    local ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local ram_gb=$((ram_kb / 1024 / 1024))
    echo $ram_gb
}

# Función para configurar ZFS
setup_zfs() {
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_title "Configuring ZFS RAID"
    else
        show_title "Configurando ZFS RAID"
    fi
    
    # Verificar que ZFS esté disponible (debería estarlo después de check_and_install_requirements)
    if ! command -v zpool &> /dev/null; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_error "ZFS is not available. This should not happen after requirements verification."
        else
            show_error "ZFS no está disponible. Esto no debería suceder después de la verificación de requisitos."
        fi
        exit 1
    fi
    
    # Verificar que el módulo ZFS esté cargado
    if ! lsmod | grep -q "^zfs "; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_message "Loading ZFS module..."
        else
            show_message "Cargando módulo ZFS..."
        fi
        sudo modprobe zfs
        sleep 2
        
        if ! lsmod | grep -q "^zfs "; then
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                show_error "Could not load ZFS module"
            else
                show_error "No se pudo cargar el módulo ZFS"
            fi
            exit 1
        fi
    fi
    
    # Seleccionar tipo de RAID
    show_raid_types
    while true; do
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            read -p "Select RAID type (1-5): " choice
        else
            read -p "Selecciona el tipo de RAID (1-5): " choice
        fi
        case $choice in
            1) RAID_TYPE="stripe"; break;;
            2) RAID_TYPE="mirror"; break;;
            3) RAID_TYPE="raidz1"; break;;
            4) RAID_TYPE="raidz2"; break;;
            5) RAID_TYPE="raidz3"; break;;
            *) echo "Opción inválida";;
        esac
    done
    
    select_disks
    
    # Solicitar nombre del pool
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        read -p "Enter ZFS pool name: " POOL_NAME
    else
        read -p "Ingresa el nombre del pool ZFS: " POOL_NAME
    fi
    
    # Configurar ARC
    local system_ram=$(get_system_ram)
    local recommended_arc=$((system_ram / 4))
    if [ $recommended_arc -lt 1 ]; then
        recommended_arc=1
    fi
    
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_message "System RAM: ${system_ram}GB"
        show_message "Recommended ARC: ${recommended_arc}GB"
        
        read -p "How many GB do you want to assign to ARC? [$recommended_arc]: " arc_size
    else
        show_message "RAM del sistema: ${system_ram}GB"
        show_message "ARC recomendado: ${recommended_arc}GB"
        
        read -p "¿Cuántos GB quieres asignar al ARC? [$recommended_arc]: " arc_size
    fi
    arc_size=${arc_size:-$recommended_arc}
    
    # Detectar ashift óptimo considerando compatibilidad futura
    local optimal_ashift=12  # Default para compatibilidad con cache devices
    local max_sector_size=512
    local has_4k_sectors=false
    
    # Detectar el tamaño de sector más grande entre los discos seleccionados
    for disk in "${SELECTED_DISKS[@]}"; do
        if [ -b "/dev/$disk" ]; then
            local sector_size=$(sudo blockdev --getpbsz "/dev/$disk" 2>/dev/null)
            if [ -n "$sector_size" ]; then
                if [ "$sector_size" -gt "$max_sector_size" ]; then
                    max_sector_size=$sector_size
                fi
                if [ "$sector_size" -eq 4096 ]; then
                    has_4k_sectors=true
                fi
            fi
        fi
    done
    
    # Estrategia de ashift optimizada para compatibilidad
    if [ "$max_sector_size" -le 512 ] && [ "$has_4k_sectors" = false ]; then
        # Solo discos 512-byte: usar ashift=12 por compatibilidad con cache futuro
        optimal_ashift=12
        show_message "[INFO] 🔧 Usando ashift=12 para compatibilidad con cache devices SSD"
    else
        # Calcular ashift basado en el tamaño de sector más grande
        case $max_sector_size in
            512) optimal_ashift=12 ;;     # Forzar 12 para compatibilidad
            1024) optimal_ashift=10 ;;    # 2^10 = 1024 bytes  
            2048) optimal_ashift=11 ;;    # 2^11 = 2048 bytes
            4096) optimal_ashift=12 ;;    # 2^12 = 4096 bytes (óptimo)
            8192) optimal_ashift=13 ;;    # 2^13 = 8192 bytes
            *) optimal_ashift=12 ;;       # Default seguro
        esac
    fi
    
    show_message "$(get_text "sector_config_detected")"
    show_message "$(get_text "max_sector_size_hdds") ${max_sector_size} bytes"
    show_message "$(get_text "pool_ashift") ${optimal_ashift} (2^${optimal_ashift} = $((2**optimal_ashift)) bytes)"
    show_message "$(get_text "compatibility_cache_devices")"
    
    # Crear el pool ZFS
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_message "Creating ZFS pool..."
    else
        show_message "Creando pool ZFS..."
    fi
    
    # Preparar discos (limpiar filesystems existentes)
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_message "Preparing disks (wiping existing filesystems)..."
    else
        show_message "Preparando discos (limpiando filesystems existentes)..."
    fi
    
    for disk in "${SELECTED_DISKS[@]}"; do
        clean_disk "$disk"
    done
    
    device_list=""
    for disk in "${SELECTED_DISKS[@]}"; do
        device_list="$device_list /dev/$disk"
    done
    
    case $RAID_TYPE in
        "stripe")
            sudo zpool create -f -o ashift=$optimal_ashift "$POOL_NAME" $device_list
            ;;
        "mirror")
            sudo zpool create -f -o ashift=$optimal_ashift "$POOL_NAME" mirror $device_list
            ;;
        "raidz1")
            sudo zpool create -f -o ashift=$optimal_ashift "$POOL_NAME" raidz $device_list
            ;;
        "raidz2")
            sudo zpool create -f -o ashift=$optimal_ashift "$POOL_NAME" raidz2 $device_list
            ;;
        "raidz3")
            sudo zpool create -f -o ashift=$optimal_ashift "$POOL_NAME" raidz3 $device_list
            ;;
    esac
    
    # Configurar ARC
    echo $((arc_size * 1024 * 1024 * 1024)) | sudo tee /sys/module/zfs/parameters/zfs_arc_max > /dev/null
    
    # Hacer persistente la configuración del ARC
    sudo mkdir -p /etc/modprobe.d
    echo "options zfs zfs_arc_max=$((arc_size * 1024 * 1024 * 1024))" | sudo tee /etc/modprobe.d/zfs.conf > /dev/null
    
    MOUNT_POINT="/$POOL_NAME"
    
    # Configurar NVME para cache y log si está disponible
    if [ -n "$NVME_DISK" ] && [[ ! " ${SELECTED_DISKS[*]} " =~ " ${NVME_DISK} " ]]; then
        if confirm "¿Deseas usar el NVME ($NVME_DISK) para ARC2 (L2ARC) y SLOG?"; then
            show_message "Particionando NVME para cache y log..."
            
            # Crear particiones en el NVME
            sudo parted "/dev/$NVME_DISK" --script mklabel gpt
            sudo parted "/dev/$NVME_DISK" --script mkpart primary 0% 50%
            sudo parted "/dev/$NVME_DISK" --script mkpart primary 50% 100%
            
            sleep 2
            
            # Agregar cache y log al pool
            sudo zpool add "$POOL_NAME" cache "/dev/${NVME_DISK}p1"
            sudo zpool add "$POOL_NAME" log "/dev/${NVME_DISK}p2"
            
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                show_message "NVME configured as cache and log"
            else
                show_message "NVME configurado como cache y log"
            fi
        fi
    fi
    
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_message "ZFS pool configured successfully"
    else
        show_message "ZFS pool configurado exitosamente"
    fi
    
    # Crear datasets dentro del pool principal usando la función reutilizable
    echo ""
    if confirm "¿Deseas crear datasets dentro del pool '$POOL_NAME'?"; then
        create_datasets_in_pool "$POOL_NAME"
    fi
    
    # Preguntar por pools adicionales solo si hay discos restantes
    remaining_disks=()
    for disk in "${AVAILABLE_DISKS[@]}"; do
        if [[ ! " ${SELECTED_DISKS[*]} " =~ " ${disk} " ]] && [ "$disk" != "$NVME_DISK" ]; then
            # Verificar que el disco no sea demasiado pequeño (ignorar mmcblk0boot)
            if [[ ! "$disk" =~ mmcblk.*boot ]]; then
                remaining_disks+=("$disk")
            fi
        fi
    done
    
    if [ ${#remaining_disks[@]} -gt 0 ]; then
        echo ""
        show_message "Discos disponibles restantes:"
        for disk in "${remaining_disks[@]}"; do
            size=$(lsblk -dpno SIZE "/dev/$disk" | tr -d ' ')
            model=$(lsblk -dpno MODEL "/dev/$disk" | tr -d ' ')
            echo "  - $disk ($size, $model)"
        done
        
        echo ""
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            echo "💡 ADDITIONAL POOLS INFORMATION:"
        else
            echo "💡 INFORMACIÓN SOBRE POOLS ADICIONALES:"
        fi
        echo "   Los pools adicionales son independientes del pool principal."
        echo "   Útiles para:"
        echo "   • Separar datos por uso (backup, cache, temp)"
        echo "   • Diferentes niveles de redundancia"
        echo "   • Optimizar rendimiento por tipo de carga"
        echo ""
        echo "   Ejemplo: Pool principal para datos + Pool SSD para cache"
        echo ""
        
        if confirm "¿Deseas crear pools ZFS adicionales con los discos restantes?"; then
            # Implementar creación de pools adicionales
            while [ ${#remaining_disks[@]} -gt 0 ]; do
                echo ""
                show_title "Configuración de Pool Adicional"
                
                read -p "Nombre del nuevo pool: " additional_pool_name
                
                if [ -z "$additional_pool_name" ]; then
                    show_error "El nombre del pool no puede estar vacío"
                    continue
                fi
                
                # Verificar que el nombre no exista
                if zpool list -H -o name 2>/dev/null | grep -q "^${additional_pool_name}$"; then
                    show_error "Ya existe un pool con el nombre '$additional_pool_name'"
                    continue
                fi
                
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    echo "Available disks for pool '$additional_pool_name':"
                else
                    echo "Discos disponibles para el pool '$additional_pool_name':"
                fi
                for i in "${!remaining_disks[@]}"; do
                    disk="${remaining_disks[$i]}"
                    size=$(lsblk -dpno SIZE "/dev/$disk" | tr -d ' ')
                    model=$(lsblk -dpno MODEL "/dev/$disk" | tr -d ' ')
                    echo "  $((i+1)). $disk - $size - $model"
                done
                
                echo ""
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    echo "Available RAID types:"
                else
                    echo "Tipos de RAID disponibles:"
                fi
                echo "1. Stripe - Sin redundancia, máximo rendimiento"
                echo "2. Mirror - Datos duplicados entre discos"
                echo "3. RAIDZ1 - Un disco de paridad (mínimo 3 discos)"
                echo "4. RAIDZ2 - Dos discos de paridad (mínimo 4 discos)"
                
                read -p "Selecciona tipo de RAID (1-4): " raid_choice
                
                local additional_raid_type=""
                local min_disks_needed=1
                
                case $raid_choice in
                    1) additional_raid_type="stripe"; min_disks_needed=1;;
                    2) additional_raid_type="mirror"; min_disks_needed=2;;
                    3) additional_raid_type="raidz1"; min_disks_needed=3;;
                    4) additional_raid_type="raidz2"; min_disks_needed=4;;
                    *) 
                        show_error "Opción inválida"
                        continue
                        ;;
                esac
                
                if [ ${#remaining_disks[@]} -lt $min_disks_needed ]; then
                    show_error "Se necesitan al menos $min_disks_needed discos para $additional_raid_type"
                    continue
                fi
                
                # Selección simple para pools adicionales
                selected_additional_disks=()
                echo ""
                echo "Selecciona discos para '$additional_pool_name' (mínimo $min_disks_needed):"
                echo "Ingresa números separados por espacios (ej: 1 2 3):"
                
                read -p "Selección: " disk_selection
                
                selected_additional_disks=()
                for num in $disk_selection; do
                    if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#remaining_disks[@]} ]; then
                        idx=$((num-1))
                        selected_additional_disks+=("${remaining_disks[$idx]}")
                    fi
                done
                
                if [ ${#selected_additional_disks[@]} -lt $min_disks_needed ]; then
                    show_error "Se necesitan al menos $min_disks_needed discos"
                    continue
                fi
                
                # Crear el pool adicional
                show_message "Creando pool adicional '$additional_pool_name'..."
                
                # Detectar ashift óptimo para el pool adicional
                local additional_optimal_ashift=12  # Default para compatibilidad
                local additional_max_sector_size=512
                local additional_has_4k_sectors=false
                
                # Detectar el tamaño de sector más grande entre los discos seleccionados
                for disk in "${selected_additional_disks[@]}"; do
                    if [ -b "/dev/$disk" ]; then
                        local sector_size=$(sudo blockdev --getpbsz "/dev/$disk" 2>/dev/null)
                        if [ -n "$sector_size" ]; then
                            if [ "$sector_size" -gt "$additional_max_sector_size" ]; then
                                additional_max_sector_size=$sector_size
                            fi
                            if [ "$sector_size" -eq 4096 ]; then
                                additional_has_4k_sectors=true
                            fi
                        fi
                    fi
                done
                
                # Estrategia de ashift optimizada para compatibilidad
                if [ "$additional_max_sector_size" -le 512 ] && [ "$additional_has_4k_sectors" = false ]; then
                    # Solo discos 512-byte: usar ashift=12 por compatibilidad
                    additional_optimal_ashift=12
                    show_message "[INFO] 🔧 Usando ashift=12 para compatibilidad con cache devices"
                else
                    # Calcular ashift basado en el tamaño de sector más grande
                    case $additional_max_sector_size in
                        512) additional_optimal_ashift=12 ;;     # Forzar 12 para compatibilidad
                        1024) additional_optimal_ashift=10 ;;
                        2048) additional_optimal_ashift=11 ;;
                        4096) additional_optimal_ashift=12 ;;
                        8192) additional_optimal_ashift=13 ;;
                        *) additional_optimal_ashift=12 ;;
                    esac
                fi
                
                show_message "$(get_text "config_for_pool") '$additional_pool_name':"
                show_message "$(get_text "max_sector_size_hdds") ${additional_max_sector_size} bytes" 
                show_message "$(get_text "pool_ashift") ${additional_optimal_ashift} (2^${additional_optimal_ashift} = $((2**additional_optimal_ashift)) bytes)"
                show_message "$(get_text "ensures_compatibility_future")"
                
                # Limpiar discos seleccionados antes de crear el pool
                for disk in "${selected_additional_disks[@]}"; do
                    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                        show_message "🧹 Cleaning disk /dev/$disk before using it..."
                    else
                        show_message "🧹 Limpiando disco /dev/$disk antes de usarlo..."
                    fi
                    clean_disk "$disk"
                done
                
                local device_list=""
                for disk in "${selected_additional_disks[@]}"; do
                    device_list="$device_list /dev/$disk"
                done
                
                case $additional_raid_type in
                    "stripe")
                        sudo zpool create -f -o ashift=$additional_optimal_ashift "$additional_pool_name" $device_list
                        ;;
                    "mirror")
                        sudo zpool create -f -o ashift=$additional_optimal_ashift "$additional_pool_name" mirror $device_list
                        ;;
                    "raidz1")
                        sudo zpool create -f -o ashift=$additional_optimal_ashift "$additional_pool_name" raidz $device_list
                        ;;
                    "raidz2")
                        sudo zpool create -f -o ashift=$additional_optimal_ashift "$additional_pool_name" raidz2 $device_list
                        ;;
                esac
                
                if [ $? -eq 0 ]; then
                    show_message "✅ Pool '$additional_pool_name' creado exitosamente"
                    
                    # Remover discos usados de la lista de disponibles
                    new_remaining=()
                    for disk in "${remaining_disks[@]}"; do
                        if [[ ! " ${selected_additional_disks[*]} " =~ " ${disk} " ]]; then
                            new_remaining+=("$disk")
                        fi
                    done
                    remaining_disks=("${new_remaining[@]}")
                    
                    if [ ${#remaining_disks[@]} -eq 0 ]; then
                        show_message "No quedan más discos disponibles"
                        break
                    fi
                    
                    if ! confirm "¿Crear otro pool adicional?"; then
                        break
                    fi
                else
                    show_error "❌ Error creando el pool '$additional_pool_name'"
                fi
            done
        fi
    else
        show_message "ℹ️  No hay discos adicionales disponibles para más pools"
    fi
}

# Función para mostrar resumen
show_summary() {
    show_title "Resumen de Configuración"
    
    echo "Sistema de archivos: $FILESYSTEM_TYPE"
    echo "Tipo de RAID: $RAID_TYPE"
    echo "Discos utilizados: ${SELECTED_DISKS[*]}"
    echo "Punto de montaje: $MOUNT_POINT"
    
    if [ "$FILESYSTEM_TYPE" = "zfs" ]; then
        echo "Nombre del pool: $POOL_NAME"
        echo "ARC configurado: ${arc_size}GB"
    fi
    
    local raid_capacity_gb=$(( RAID_CAPACITY / 1024 / 1024 / 1024 ))
    local raid_capacity_formatted=$(format_capacity "$raid_capacity_gb")
    echo "Capacidad aproximada del RAID: ${raid_capacity_formatted}"
}

# Función para configurar montaje automático
setup_auto_mount() {
    if confirm "¿Deseas montar automáticamente al iniciar el sistema?"; then
        if [ "$FILESYSTEM_TYPE" = "btrfs" ]; then
            # Agregar entrada a /etc/fstab para BTRFS
            echo "UUID=$FILESYSTEM_UUID $MOUNT_POINT btrfs defaults 0 0" | sudo tee -a /etc/fstab
            show_message "Montaje automático configurado en /etc/fstab"
        else
            # Para ZFS, habilitar el servicio de importación automática
            sudo systemctl enable zfs-import-cache
            sudo systemctl enable zfs-mount
            sudo systemctl enable zfs.target
            show_message "Servicios ZFS habilitados para montaje automático"
        fi
    fi
}

# Función principal
main() {
    # Select language first / Seleccionar idioma primero
    select_language
    
    show_title "$(get_text "script_title")"
    
    # Check if running as root or with sudo / Verificar si se ejecuta como root o con sudo
    if [ "$EUID" -eq 0 ]; then
        show_error "$(get_text "root_warning")"
        exit 1
    fi
    
    # Check and install requirements / Verificar e instalar requisitos
    check_and_install_requirements
    
    # Detect existing RAID configurations (ZFS, BTRFS, MDADM, LVM)
    # Detectar configuraciones RAID existentes (ZFS, BTRFS, MDADM, LVM)
    if detect_existing_raid_configurations; then
        # Continue with normal configuration / Continúa con configuración normal
        detect_disks
        select_filesystem
        
        if [ "$FILESYSTEM_TYPE" = "btrfs" ]; then
            setup_btrfs
        else
            setup_zfs
        fi
        
        show_summary
        setup_auto_mount
        
        show_message "$(get_text "raid_completed")"
        show_message "$(get_text "raid_mounted_at") $MOUNT_POINT"
        
        # Offer dataset management after creating the pool
        # Ofrecer gestión de datasets después de crear el pool
        offer_post_creation_dataset_management
    fi
    # If detected existing RAID configurations and user chose to manage them,
    # the detect_existing_raid_configurations function already handled everything
    # Si detectó configuraciones RAID existentes y el usuario eligió gestionarlas, 
    # la función detect_existing_raid_configurations ya manejó todo
}

# Función para ofrecer gestión de datasets después de crear un pool
offer_post_creation_dataset_management() {
    if [ "$FILESYSTEM_TYPE" = "zfs" ] && [ -n "$POOL_NAME" ]; then
        echo ""
        show_title "Gestión Post-Creación"
        echo ""
        echo "🎉 ¡Pool ZFS '$POOL_NAME' creado exitosamente!"
        echo ""
        
        # Configurar atime primero (recomendado)
        configure_atime_settings "$POOL_NAME"
        
        while true; do
            echo ""
            echo "🛠️  OPCIONES ADICIONALES:"
            echo "   1. 🚀 Configurar dispositivos de cache (L2ARC/SLOG) - RECOMENDADO"
            echo "   2. 📁 Gestionar datasets en '$POOL_NAME'"
            echo "   3. 📸 Crear snapshots iniciales"
            echo "   4. 📊 Ver estado completo del pool"
            echo "   5. ⚙️  Reconfigurar atime"
            echo "   6. ✅ Finalizar"
            echo ""
            if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                echo "💡 NOTE: Cache devices (option 1) must be SSD or NVMe"
            else
                echo "💡 NOTA: Los dispositivos de cache (opción 1) deben ser SSD o NVMe"
            fi
            echo "   ⚠️  NO usar discos mecánicos - pueden empeorar el rendimiento"
            echo ""
            
            read -p "👉 Selecciona una opción (1-6): " choice
            case $choice in
                1)
                    echo ""
                    setup_cache_devices "$POOL_NAME"
                    ;;
                2)
                    echo ""
                    create_datasets_in_pool "$POOL_NAME"
                    ;;
                3)
                    create_initial_snapshots "$POOL_NAME"
                    ;;
                4)
                    if [ -z "$POOL_NAME" ]; then
                        show_error "Error: POOL_NAME no está definido. Esto no debería ocurrir."
                        echo "Información de debug:"
                        echo "  FILESYSTEM_TYPE: $FILESYSTEM_TYPE"
                        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                            echo "  Available pools: $(zpool list -H -o name 2>/dev/null | tr '\n' ' ')"
                        else
                            echo "  Pools disponibles: $(zpool list -H -o name 2>/dev/null | tr '\n' ' ')"
                        fi
                        read -p "Presiona Enter para continuar..."
                    else
                        show_pool_status "$POOL_NAME"
                    fi
                    ;;
                5)
                    echo ""
                    configure_atime_settings "$POOL_NAME"
                    ;;
                6)
                    show_message "¡Configuración completada!"
                    echo ""
                    echo "📊 RESUMEN FINAL:"
                    echo "   Pool ZFS: $POOL_NAME"
                    echo "   Estado: $(zpool list -H -o health "$POOL_NAME" 2>/dev/null || echo 'Desconocido')"
                    echo "   Tamaño: $(zpool list -H -o size "$POOL_NAME" 2>/dev/null || echo 'Desconocido')"
                    echo "   Usado: $(zpool list -H -o alloc "$POOL_NAME" 2>/dev/null || echo 'Desconocido')"
                    echo "   Libre: $(zpool list -H -o free "$POOL_NAME" 2>/dev/null || echo 'Desconocido')"
                    echo ""
                    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                        echo "✅ ZFS RAID configuration completed successfully!"
                    else
                        echo "✅ Configuración de RAID ZFS completada exitosamente!"
                    fi
                    break
                    ;;
                *)
                    echo "❌ Opción inválida. Selecciona 1, 2, 3, 4, 5 o 6."
                    ;;
            esac
            echo ""
        done
    fi
    
    # Asegurar que las variables estén definidas para evitar errores
    if [ -z "$POOL_NAME" ] && [ "$FILESYSTEM_TYPE" = "zfs" ]; then
        echo "⚠️  ADVERTENCIA: POOL_NAME no está definido al final de la gestión post-creación."
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            echo "   This could indicate a problem in the script."
        else
            echo "   Esto podría indicar un problema en el script."
        fi
    fi
}

# Función para configurar atime en ZFS
configure_atime_settings() {
    local pool_name="$1"
    
    show_title "Configuración de Atime en ZFS"
    echo ""
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        echo "💡 ATIME INFORMATION:"
    else
        echo "💡 INFORMACIÓN SOBRE ATIME:"
    fi
    echo "   atime (access time) registra la última vez que se accedió a un archivo."
    echo "   En sistemas con muchas operaciones de lectura, puede impactar el rendimiento."
    echo ""
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        echo "📊 AVAILABLE OPTIONS IN ZFS:"
    else
        echo "📊 OPCIONES DISPONIBLES EN ZFS:"
    fi
    echo "   1. off        - No registrar atime (RECOMENDADO para rendimiento)"
    echo "   2. on         - Registrar atime completo (puede reducir rendimiento)"
    echo ""
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        echo "💡 RECOMMENDATION: Option 1 (off) for maximum performance"
    else
        echo "💡 RECOMENDACIÓN: Opción 1 (off) para máximo rendimiento"
    fi
    echo "   ⚠️  NOTA: ZFS solo soporta 'on' u 'off' (no soporta 'relatime')"
    echo "   La mayoría de aplicaciones no necesitan atime y deshabilitarlo"
    echo "   mejora significativamente el rendimiento de lectura."
    echo ""
    
    while true; do
        read -p "👉 Selecciona configuración de atime (1-2) [1]: " atime_choice
        atime_choice=${atime_choice:-1}
        
        case $atime_choice in
            1)
                local atime_setting="off"
                local description="Deshabilitado (máximo rendimiento)"
                break
                ;;
            2)
                local atime_setting="on"
                local description="Habilitado (impacto en rendimiento)"
                break
                ;;
            *)
                echo "❌ Opción inválida. Selecciona 1 o 2."
                ;;
        esac
    done
    
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        show_message "Configuring atime=$atime_setting on pool '$pool_name'..."
    else
        show_message "Configurando atime=$atime_setting en el pool '$pool_name'..."
    fi
    
    # Aplicar configuración al pool raíz
    if sudo zfs set atime="$atime_setting" "$pool_name"; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_message "✅ atime configured as '$atime_setting' on '$pool_name'"
        else
            show_message "✅ atime configurado como '$atime_setting' en '$pool_name'"
        fi
    else
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_error "❌ Error configuring atime on '$pool_name'"
        else
            show_error "❌ Error configurando atime en '$pool_name'"
        fi
        return 1
    fi
    
    # Aplicar a todos los datasets existentes
    local datasets=$(zfs list -H -o name -r "$pool_name" 2>/dev/null | grep -v "^${pool_name}$")
    if [ -n "$datasets" ]; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            show_message "Applying configuration to existing datasets..."
        else
            show_message "Aplicando configuración a datasets existentes..."
        fi
        for dataset in $datasets; do
            if sudo zfs set atime="$atime_setting" "$dataset"; then
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    show_message "  ✅ $dataset configured"
                else
                    show_message "  ✅ $dataset configurado"
                fi
            else
                if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                    show_warning "  ⚠️  Error configuring $dataset"
                else
                    show_warning "  ⚠️  Error configurando $dataset"
                fi
            fi
        done
    fi
    
    echo ""
    show_message "📊 CONFIGURACIÓN ATIME COMPLETADA:"
    echo "   Pool: $pool_name"
    echo "   Configuración: $atime_setting ($description)"
    echo "   Aplicado a: pool y todos los datasets existentes"
    echo ""
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        echo "💡 Note: New datasets will automatically inherit this configuration"
    else
        echo "💡 Nota: Los nuevos datasets heredarán esta configuración automáticamente"
    fi
}

# Función para configurar dispositivos de cache (L2ARC y SLOG)
setup_cache_devices() {
    local pool_name="$1"
    
    show_title "Configuración de Dispositivos de Cache para '$pool_name'"
    echo ""
    echo "⚠️  ADVERTENCIA CRÍTICA SOBRE DISPOSITIVOS DE CACHE:"
    echo "   🔥 SOLO USAR SSD O NVME - NUNCA DISCOS MECÁNICOS"
    echo "   🚫 Los discos mecánicos (HDD) como cache EMPEORARÁN el rendimiento"
    echo "   ✅ Los dispositivos de cache deben ser MÁS RÁPIDOS que el almacenamiento principal"
    echo ""
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        echo "💡 CACHE DEVICES INFORMATION:"
    else
        echo "💡 INFORMACIÓN SOBRE DISPOSITIVOS DE CACHE:"
    fi
    echo ""
    echo "🚀 L2ARC (Level 2 Adaptive Replacement Cache):"
    echo "   • Cache de segundo nivel para lecturas frecuentes"
    echo "   • Ideal: SSD rápido (NVMe > SATA SSD > USB 3.0)"
    echo "   • Mejora rendimiento de lectura en datasets accedidos frecuentemente"
    echo "   • No es crítico - si falla, el pool sigue funcionando"
    echo ""
    echo "📝 SLOG (Separate Intent Log):"
    echo "   • Log de transacciones para escrituras síncronas"
    echo "   • Ideal: SSD con baja latencia y alta resistencia (NVMe con power-loss protection)"
    echo "   • Mejora rendimiento de escrituras síncronas (bases de datos, VMs)"
    echo "   • Crítico para integridad - usar dispositivos confiables"
    echo ""
    echo "⚠️  RECOMENDACIÓN IMPORTANTE:"
    echo "   🔥 USAR DISPOSITIVOS NVME ES ALTAMENTE RECOMENDADO PARA CACHE"
    echo "   • NVMe ofrece la latencia más baja y mayor throughput"
    echo "   • Usar dispositivos lentos (USB, HDD) como cache puede EMPEORAR el rendimiento"
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        echo "   • If you don't have NVMe available, consider skipping cache configuration"
    else
        echo "   • Si no tienes NVMe disponible, considera omitir la configuración de cache"
    fi
    echo ""
    
    # Detectar dispositivos disponibles con clasificación por tipo
    local pool_devices=$(zpool status "$pool_name" 2>/dev/null | grep -E "^\s+[a-z]" | awk '{print $1}' | grep -v "raidz\|mirror\|spare\|log\|cache\|replacing")
    local available_cache_devices=()
    local nvme_devices=()
    local ssd_devices=()
    local other_devices=()
    
    # Obtener lista de todos los discos disponibles y clasificarlos
    local available_cache_devices=()
    local nvme_devices=()
    local ssd_devices=()
    local other_devices=()
    local in_use_devices=()
    
    while IFS= read -r disk; do
        local disk_name=$(basename "$disk")
        
        # Excluir dispositivos del sistema y de arranque
        if [[ "$disk_name" == "mmcblk0"* ]] || [[ "$disk_name" == *"boot"* ]]; then
            continue
        fi
        
        # Verificar que el dispositivo tenga tamaño válido
        local size_raw=$(lsblk -dpno SIZE "/dev/$disk_name" 2>/dev/null | tr -d ' ')
        if [[ "$size_raw" == "0B" ]] || [[ -z "$size_raw" ]]; then
            continue
        fi
        
        # Verificar que no sea el disco del sistema operativo
        local mount_check=$(lsblk -no MOUNTPOINT "/dev/$disk_name" 2>/dev/null | grep -E "^/$|^/boot|^/home")
        if [ -n "$mount_check" ]; then
            continue
        fi
        
        # Excluir discos ya en uso por el pool principal
        if echo "$pool_devices" | grep -q "^${disk_name}$"; then
            continue
        fi
        
        # Verificar estado de uso del dispositivo
        local raid_status=$(check_disk_raid_status "$disk_name")
        local usage_status=""
        
        if [ -n "$raid_status" ]; then
            # Dispositivo en uso - agregar a lista de dispositivos en uso
            usage_status="EN_USO"
            in_use_devices+=("$disk_name:$raid_status")
        else
            # Dispositivo disponible
            usage_status="DISPONIBLE"
        fi
        
        # Agregar a la lista general y clasificar por tipo
        available_cache_devices+=("$disk_name:$usage_status")
        
        if [[ "$disk_name" == nvme* ]]; then
            nvme_devices+=("$disk_name:$usage_status")
        elif lsblk -dpno ROTA "/dev/$disk_name" 2>/dev/null | grep -q "0"; then
            # ROTA=0 significa SSD
            ssd_devices+=("$disk_name:$usage_status")
        else
            other_devices+=("$disk_name:$usage_status")
        fi
        
    done < <(lsblk -dpno NAME | grep -v "^/dev/loop")
    
    # Mostrar dispositivos disponibles clasificados por tipo
    echo "📀 DISPOSITIVOS PARA CACHE:"
    echo ""
    
    if [ ${#nvme_devices[@]} -gt 0 ]; then
        echo "🚀 DISPOSITIVOS NVME (RECOMENDADOS):"
        for device_info in "${nvme_devices[@]}"; do
            local device_name=$(echo "$device_info" | cut -d: -f1)
            local usage_status=$(echo "$device_info" | cut -d: -f2)
            local size=$(lsblk -dpno SIZE "/dev/$device_name" 2>/dev/null | tr -d ' ')
            local model=$(lsblk -dpno MODEL "/dev/$device_name" 2>/dev/null | tr -d ' ')
            
            if [ "$usage_status" = "DISPONIBLE" ]; then
                echo "   ✅ $device_name - $size - $model"
            else
                echo "   ⚠️  $device_name - $size - $model (EN USO: $usage_status - se puede limpiar)"
            fi
        done
        echo ""
    fi
    
    if [ ${#ssd_devices[@]} -gt 0 ]; then
        echo "💾 DISPOSITIVOS SSD (ACEPTABLES):"
        for device_info in "${ssd_devices[@]}"; do
            local device_name=$(echo "$device_info" | cut -d: -f1)
            local usage_status=$(echo "$device_info" | cut -d: -f2)
            local size=$(lsblk -dpno SIZE "/dev/$device_name" 2>/dev/null | tr -d ' ')
            local model=$(lsblk -dpno MODEL "/dev/$device_name" 2>/dev/null | tr -d ' ')
            
            if [ "$usage_status" = "DISPONIBLE" ]; then
                echo "   ⚠️  $device_name - $size - $model"
            else
                echo "   ⚠️  $device_name - $size - $model (EN USO: $usage_status - se puede limpiar)"
            fi
        done
        echo ""
    fi
    
    if [ ${#other_devices[@]} -gt 0 ]; then
        echo "🐌 OTROS DISPOSITIVOS (NO RECOMENDADOS PARA CACHE):"
        for device_info in "${other_devices[@]}"; do
            local device_name=$(echo "$device_info" | cut -d: -f1)
            local usage_status=$(echo "$device_info" | cut -d: -f2)
            local size=$(lsblk -dpno SIZE "/dev/$device_name" 2>/dev/null | tr -d ' ')
            local model=$(lsblk -dpno MODEL "/dev/$device_name" 2>/dev/null | tr -d ' ')
            
            if [ "$usage_status" = "DISPONIBLE" ]; then
                echo "   ❌ $device_name - $size - $model"
            else
                echo "   ❌ $device_name - $size - $model (EN USO: $usage_status - se puede limpiar)"
            fi
        done
        echo ""
    fi
    
    # Mostrar información sobre dispositivos en uso
    if [ ${#in_use_devices[@]} -gt 0 ]; then
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            echo "💡 DEVICES IN USE INFORMATION:"
        else
            echo "💡 INFORMACIÓN SOBRE DISPOSITIVOS EN USO:"
        fi
        echo "   • Los dispositivos marcados como 'EN USO' pueden ser limpiados y reutilizados"
        echo "   • ⚠️  ADVERTENCIA: Limpiar un dispositivo DESTRUIRÁ todos los datos"
        echo "   • Se te pedirá confirmación antes de proceder con dispositivos en uso"
        echo ""
    fi
    
    # Verificar dispositivos disponibles y mostrar recomendación apropiada
    if [ ${#nvme_devices[@]} -eq 0 ] && [ ${#ssd_devices[@]} -eq 0 ]; then
        # No hay NVMe ni SSD - advertencia crítica
        echo "⚠️  ADVERTENCIA CRÍTICA:"
        echo "   🔥 NO SE DETECTARON DISPOSITIVOS NVMe O SSD ADECUADOS"
        echo "   • Los dispositivos de cache deben ser más rápidos que el almacenamiento principal"
        echo "   • Usar dispositivos lentos como cache puede REDUCIR el rendimiento del sistema"
        echo "   • Se recomienda FUERTEMENTE conseguir un dispositivo NVMe o SSD para cache"
        echo ""
        
        if ! confirm "¿Deseas continuar sin dispositivos rápidos (MUY NO RECOMENDADO)?"; then
            show_message "Configuración de cache cancelada - se recomienda conseguir un dispositivo NVMe o SSD"
            return 0
        fi
        echo ""
    elif [ ${#nvme_devices[@]} -eq 0 ] && [ ${#ssd_devices[@]} -gt 0 ]; then
        # Solo hay SSD, no NVMe - recomendación suave
        if [ "$SCRIPT_LANGUAGE" = "en" ]; then
            echo "💡 RECOMMENDATION:"
        else
            echo "💡 RECOMENDACIÓN:"
        fi
        echo "   ✅ Se detectaron dispositivos SSD (aceptables para cache)"
        echo "   🚀 Para rendimiento óptimo, considera usar NVMe en el futuro"
        echo "   📊 Los SSD son adecuados para la mayoría de casos de uso"
        echo ""
    fi
    
    if [ ${#available_cache_devices[@]} -eq 0 ]; then
        show_warning "No se encontraron dispositivos disponibles para cache"
        show_message "Todos los dispositivos están en uso o no son adecuados"
        return 0
    fi
    
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        echo "️  CONFIGURATION OPTIONS:"
    else
        echo "️  OPCIONES DE CONFIGURACIÓN:"
    fi
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        echo "   1. Configure only L2ARC (read cache)"
        echo "   2. Configure only SLOG (write log)"
        echo "   3. Configure both L2ARC and SLOG"
        echo "   4. Configure partitions on one device (L2ARC + SLOG)"
        echo "   5. Cancel configuration"
    else
        echo "   1. Configurar solo L2ARC (cache de lectura)"
        echo "   2. Configurar solo SLOG (log de escritura)"
        echo "   3. Configurar ambos L2ARC y SLOG"
        echo "   4. Configurar particiones en un dispositivo (L2ARC + SLOG)"
        echo "   5. Cancelar configuración"
    fi
    echo ""
    
    while true; do
        read -p "👉 Selecciona una opción (1-5): " config_choice
        case $config_choice in
            1)
                if setup_l2arc_only "$pool_name" "${available_cache_devices[@]}"; then
                    break
                else
                    echo ""
                    echo "️  OPCIONES DE CONFIGURACIÓN:"
                    echo "   1. Configurar solo L2ARC (cache de lectura)"
                    echo "   2. Configurar solo SLOG (log de escritura)"
                    echo "   3. Configurar ambos L2ARC y SLOG"
                    echo "   4. Configurar particiones en un dispositivo (L2ARC + SLOG)"
                    echo "   5. Cancelar configuración"
                    echo ""
                fi
                ;;
            2)
                if setup_slog_only "$pool_name" "${available_cache_devices[@]}"; then
                    break
                else
                    echo ""
                    echo "️  OPCIONES DE CONFIGURACIÓN:"
                    echo "   1. Configurar solo L2ARC (cache de lectura)"
                    echo "   2. Configurar solo SLOG (log de escritura)"
                    echo "   3. Configurar ambos L2ARC y SLOG"
                    echo "   4. Configurar particiones en un dispositivo (L2ARC + SLOG)"
                    echo "   5. Cancelar configuración"
                    echo ""
                fi
                ;;
            3)
                if setup_l2arc_and_slog_separate "$pool_name" "${available_cache_devices[@]}"; then
                    break
                else
                    echo ""
                    echo "️  OPCIONES DE CONFIGURACIÓN:"
                    echo "   1. Configurar solo L2ARC (cache de lectura)"
                    echo "   2. Configurar solo SLOG (log de escritura)"
                    echo "   3. Configurar ambos L2ARC y SLOG"
                    echo "   4. Configurar particiones en un dispositivo (L2ARC + SLOG)"
                    echo "   5. Cancelar configuración"
                    echo ""
                fi
                ;;
            4)
                if setup_partitioned_cache "$pool_name" "${available_cache_devices[@]}"; then
                    break
                else
                    echo ""
                    echo "️  OPCIONES DE CONFIGURACIÓN:"
                    echo "   1. Configurar solo L2ARC (cache de lectura)"
                    echo "   2. Configurar solo SLOG (log de escritura)"
                    echo "   3. Configurar ambos L2ARC y SLOG"
                    echo "   4. Configurar particiones en un dispositivo (L2ARC + SLOG)"
                    echo "   5. Cancelar configuración"
                    echo ""
                fi
                ;;
            5)
                show_message "Configuración de cache cancelada"
                return 0
                ;;
            *)
                echo "❌ Opción inválida. Selecciona 1, 2, 3, 4 o 5."
                echo ""
                echo "️  OPCIONES DE CONFIGURACIÓN:"
                echo "   1. Configurar solo L2ARC (cache de lectura)"
                echo "   2. Configurar solo SLOG (log de escritura)"
                echo "   3. Configurar ambos L2ARC y SLOG"
                echo "   4. Configurar particiones en un dispositivo (L2ARC + SLOG)"
                echo "   5. Cancelar configuración"
                echo ""
                ;;
        esac
    done
}

# Función para configurar solo L2ARC
setup_l2arc_only() {
    local pool_name="$1"
    shift
    local available_devices=("$@")
    
    show_title "Configuración de L2ARC para '$pool_name'"
    echo ""
    echo "📖 Selecciona el dispositivo para L2ARC (cache de lectura):"
    
    for i in "${!available_devices[@]}"; do
        local device_info="${available_devices[$i]}"
        local device_name=$(echo "$device_info" | cut -d: -f1)
        local usage_status=$(echo "$device_info" | cut -d: -f2)
        local size=$(lsblk -dpno SIZE "/dev/$device_name" | tr -d ' ')
        local model=$(lsblk -dpno MODEL "/dev/$device_name" | tr -d ' ')
        
        if [ "$usage_status" = "DISPONIBLE" ]; then
            echo "  $((i+1)). $device_name - $size - $model"
        else
            echo "  $((i+1)). $device_name - $size - $model (EN USO: $usage_status)"
        fi
    done
    
    while true; do
        read -p "👉 Selecciona dispositivo (1-${#available_devices[@]}): " device_choice
        if [[ "$device_choice" =~ ^[0-9]+$ ]] && [ "$device_choice" -ge 1 ] && [ "$device_choice" -le ${#available_devices[@]} ]; then
            local device_info="${available_devices[$((device_choice-1))]}"
            local selected_device=$(echo "$device_info" | cut -d: -f1)
            local usage_status=$(echo "$device_info" | cut -d: -f2)
            
            # Verificar si el dispositivo está en uso
            if [ "$usage_status" != "DISPONIBLE" ]; then
                echo ""
                echo "⚠️  ADVERTENCIA: El dispositivo $selected_device está EN USO"
                echo "   📁 Uso actual: $usage_status"
                echo "   💀 Limpiar este dispositivo DESTRUIRÁ todos los datos"
                echo ""
                if ! confirm "¿Estás SEGURO de que quieres limpiar y usar $selected_device para L2ARC?"; then
                    echo "Selecciona otro dispositivo..."
                    continue
                fi
            fi
            
            # Verificar si es un disco mecánico
            if ! lsblk -dpno ROTA "/dev/$selected_device" 2>/dev/null | grep -q "0"; then
                echo ""
                echo "🚨 ADVERTENCIA: El dispositivo $selected_device parece ser un DISCO MECÁNICO"
                echo "   ❌ Los discos mecánicos NO deben usarse como cache"
                echo "   📉 Esto EMPEORARÁ significativamente el rendimiento del sistema"
                echo "   ✅ Usa solo SSD o NVMe para cache"
                echo ""
                if ! confirm "¿Estás SEGURO de que quieres usar este disco mecánico? (MUY NO RECOMENDADO)"; then
                    echo "Selecciona otro dispositivo..."
                    continue
                fi
                echo ""
                if ! confirm "⚠️  ÚLTIMA ADVERTENCIA: ¿Realmente quieres proceder con un disco mecánico?"; then
                    echo "Selecciona otro dispositivo..."
                    continue
                fi
            fi
            break
        else
            echo "❌ Selección inválida. Usa números del 1 al ${#available_devices[@]}."
        fi
    done
    
    # Confirmar y aplicar
    echo ""
    show_warning "⚠️  Esto limpiará completamente el dispositivo /dev/$selected_device"
    if confirm "¿Continuar con la configuración de L2ARC en /dev/$selected_device?"; then
        show_message "Preparando dispositivo /dev/$selected_device para L2ARC..."
        
        # Limpiar dispositivo
        clean_disk "$selected_device"
        
        # Agregar como L2ARC
        show_message "Agregando /dev/$selected_device como L2ARC al pool '$pool_name'..."
        if sudo zpool add "$pool_name" cache "/dev/$selected_device"; then
            show_message "✅ L2ARC configurado exitosamente"
            echo ""
            show_message "📊 CONFIGURACIÓN L2ARC COMPLETADA:"
            echo "   Pool: $pool_name"
            echo "   Dispositivo L2ARC: /dev/$selected_device"
            echo "   Función: Cache de lectura (mejora acceso a datos frecuentes)"
            echo "   💡 Cache devices no requieren compatibilidad de ashift"
            return 0
        else
            show_error "❌ Error configurando L2ARC"
            return 1
        fi
    else
        show_message "Configuración de L2ARC cancelada"
        return 1
    fi
}

# Función para configurar solo SLOG
setup_slog_only() {
    local pool_name="$1"
    shift
    local available_devices=("$@")
    
    show_title "Configuración de SLOG para '$pool_name'"
    echo ""
    echo "⚠️  IMPORTANTE - REQUISITOS PARA SLOG:"
    echo "   • Usar SSD de alta calidad con protección contra cortes de energía"
    echo "   • Evitar dispositivos USB o SD para SLOG"
    echo "   • Preferir NVMe > SATA SSD > otros"
    echo ""
    echo "📖 Selecciona el dispositivo para SLOG (log de escritura):"
    
    for i in "${!available_devices[@]}"; do
        local device_info="${available_devices[$i]}"
        local device_name=$(echo "$device_info" | cut -d: -f1)
        local usage_status=$(echo "$device_info" | cut -d: -f2)
        local size=$(lsblk -dpno SIZE "/dev/$device_name" | tr -d ' ')
        local model=$(lsblk -dpno MODEL "/dev/$device_name" | tr -d ' ')
        local recommendation=""
        
        if [[ "$device_name" == nvme* ]]; then
            recommendation=" ⭐ RECOMENDADO"
        elif lsblk -dpno ROTA "/dev/$device_name" | grep -q "0"; then
            recommendation=" ✅ ADECUADO"
        else
            recommendation=" ⚠️  NO RECOMENDADO (HDD)"
        fi
        
        if [ "$usage_status" = "DISPONIBLE" ]; then
            echo "  $((i+1)). $device_name - $size - $model$recommendation"
        else
            echo "  $((i+1)). $device_name - $size - $model$recommendation (EN USO: $usage_status)"
        fi
    done
    
    while true; do
        read -p "👉 Selecciona dispositivo (1-${#available_devices[@]}): " device_choice
        if [[ "$device_choice" =~ ^[0-9]+$ ]] && [ "$device_choice" -ge 1 ] && [ "$device_choice" -le ${#available_devices[@]} ]; then
            local device_info="${available_devices[$((device_choice-1))]}"
            local selected_device=$(echo "$device_info" | cut -d: -f1)
            local usage_status=$(echo "$device_info" | cut -d: -f2)
            
            # Verificar si el dispositivo está en uso
            if [ "$usage_status" != "DISPONIBLE" ]; then
                echo ""
                echo "⚠️  ADVERTENCIA CRÍTICA: El dispositivo $selected_device está EN USO"
                echo "   📁 Uso actual: $usage_status"
                echo "   💀 Limpiar este dispositivo DESTRUIRÁ todos los datos"
                echo "   🔧 SLOG es crítico - asegúrate de que puedes perder estos datos"
                echo ""
                if ! confirm "¿Estás SEGURO de que quieres limpiar y usar $selected_device para SLOG?"; then
                    echo "Selecciona otro dispositivo..."
                    continue
                fi
            fi
            break
        else
            echo "❌ Selección inválida. Usa números del 1 al ${#available_devices[@]}."
        fi
    done
    
    # Verificar si es adecuado para SLOG
    if ! [[ "$selected_device" == nvme* ]] && lsblk -dpno ROTA "/dev/$selected_device" | grep -q "1"; then
        echo ""
        echo "🚨 ADVERTENCIA CRÍTICA: El dispositivo $selected_device es un DISCO MECÁNICO"
        echo "   ❌ Los discos mecánicos NO deben usarse como SLOG"
        echo "   💀 Esto puede causar PÉRDIDA DE DATOS y rendimiento EXTREMADAMENTE pobre"
        echo "   🔧 SLOG requiere dispositivos de baja latencia (SSD/NVMe)"
        echo "   ⚡ Un SLOG lento puede bloquear TODAS las escrituras del sistema"
        echo ""
        if ! confirm "¿Estás SEGURO de que quieres usar este disco mecánico para SLOG? (PELIGROSO)"; then
            show_message "Configuración cancelada por el usuario"
            return 0
        fi
        echo ""
        if ! confirm "⚠️  ÚLTIMA ADVERTENCIA: ¿Realmente quieres proceder? (PUEDE CAUSAR PROBLEMAS GRAVES)"; then
            show_message "Configuración cancelada por el usuario"
            return 0
        fi
    fi
    
    # Confirmar y aplicar
    echo ""
    show_warning "⚠️  Esto limpiará completamente el dispositivo /dev/$selected_device"
    if confirm "¿Continuar con la configuración de SLOG en /dev/$selected_device?"; then
        show_message "Preparando dispositivo /dev/$selected_device para SLOG..."
        
        # Limpiar dispositivo
        clean_disk "$selected_device"
        
        # Agregar como SLOG
        show_message "Agregando /dev/$selected_device como SLOG al pool '$pool_name'..."
        if sudo zpool add "$pool_name" log "/dev/$selected_device"; then
            show_message "✅ SLOG configurado exitosamente"
            echo ""
            show_message "📊 CONFIGURACIÓN SLOG COMPLETADA:"
            echo "   Pool: $pool_name"
            echo "   Dispositivo SLOG: /dev/$selected_device"
            echo "   Función: Log de escritura (mejora escrituras síncronas)"
            echo "   💡 Cache devices no requieren compatibilidad de ashift"
            return 0
        else
            show_error "❌ Error configurando SLOG"
            return 1
        fi
    else
        show_message "Configuración de SLOG cancelada"
        return 1
    fi
}

# Función para configurar L2ARC y SLOG en dispositivos separados
setup_l2arc_and_slog_separate() {
    local pool_name="$1"
    shift
    local available_devices=("$@")
    
    if [ ${#available_devices[@]} -lt 2 ]; then
        show_error "Se necesitan al menos 2 dispositivos disponibles para configurar L2ARC y SLOG por separado"
        return 1
    fi
    
    show_title "Configuración de L2ARC y SLOG Separados para '$pool_name'"
    echo ""
    echo "📖 Selecciona dispositivos para L2ARC y SLOG:"
    echo ""
    
    # Mostrar dispositivos con recomendaciones
    for i in "${!available_devices[@]}"; do
        local device_info="${available_devices[$i]}"
        local device_name=$(echo "$device_info" | cut -d: -f1)
        local usage_status=$(echo "$device_info" | cut -d: -f2)
        local size=$(lsblk -dpno SIZE "/dev/$device_name" | tr -d ' ')
        local model=$(lsblk -dpno MODEL "/dev/$device_name" | tr -d ' ')
        local recommendation=""
        
        if [[ "$device_name" == nvme* ]]; then
            recommendation=" ⭐ EXCELENTE para SLOG, BUENO para L2ARC"
        elif lsblk -dpno ROTA "/dev/$device_name" | grep -q "0"; then
            recommendation=" ✅ BUENO para L2ARC, REGULAR para SLOG"
        else
            recommendation=" ⚠️  SOLO para L2ARC (NO para SLOG)"
        fi
        
        if [ "$usage_status" = "DISPONIBLE" ]; then
            echo "  $((i+1)). $device_name - $size - $model$recommendation"
        else
            echo "  $((i+1)). $device_name - $size - $model$recommendation (EN USO: $usage_status)"
        fi
    done
    
    # Seleccionar dispositivo para L2ARC
    echo ""
    echo "🚀 SELECCIÓN DE L2ARC:"
    while true; do
        read -p "👉 Dispositivo para L2ARC (1-${#available_devices[@]}): " l2arc_choice
        if [[ "$l2arc_choice" =~ ^[0-9]+$ ]] && [ "$l2arc_choice" -ge 1 ] && [ "$l2arc_choice" -le ${#available_devices[@]} ]; then
            local device_info="${available_devices[$((l2arc_choice-1))]}"
            local l2arc_device=$(echo "$device_info" | cut -d: -f1)
            local l2arc_usage=$(echo "$device_info" | cut -d: -f2)
            
            # Verificar si el dispositivo L2ARC está en uso
            if [ "$l2arc_usage" != "DISPONIBLE" ]; then
                echo ""
                echo "⚠️  ADVERTENCIA: El dispositivo $l2arc_device está EN USO"
                echo "   📁 Uso actual: $l2arc_usage"
                echo "   💀 Limpiar este dispositivo DESTRUIRÁ todos los datos"
                echo ""
                if ! confirm "¿Continuar con $l2arc_device para L2ARC?"; then
                    echo "Selecciona otro dispositivo..."
                    continue
                fi
            fi
            break
        else
            echo "❌ Selección inválida. Usa números del 1 al ${#available_devices[@]}."
        fi
    done
    
    # Seleccionar dispositivo para SLOG (excluyendo el ya seleccionado)
    echo ""
    echo "📝 SELECCIÓN DE SLOG:"
    echo "Dispositivos disponibles (excluyendo $l2arc_device):"
    local slog_devices=()
    for i in "${!available_devices[@]}"; do
        local device_info="${available_devices[$i]}"
        local device_name=$(echo "$device_info" | cut -d: -f1)
        local usage_status=$(echo "$device_info" | cut -d: -f2)
        
        if [ "$device_name" != "$l2arc_device" ]; then
            slog_devices+=("$device_info")
            local size=$(lsblk -dpno SIZE "/dev/$device_name" | tr -d ' ')
            local model=$(lsblk -dpno MODEL "/dev/$device_name" | tr -d ' ')
            local recommendation=""
            
            if [[ "$device_name" == nvme* ]]; then
                recommendation=" ⭐ RECOMENDADO"
            elif lsblk -dpno ROTA "/dev/$device_name" | grep -q "0"; then
                recommendation=" ✅ ADECUADO"
            else
                recommendation=" ⚠️  NO RECOMENDADO"
            fi
            
            if [ "$usage_status" = "DISPONIBLE" ]; then
                echo "  ${#slog_devices[@]}. $device_name - $size - $model$recommendation"
            else
                echo "  ${#slog_devices[@]}. $device_name - $size - $model$recommendation (EN USO: $usage_status)"
            fi
        fi
    done
    
    while true; do
        read -p "👉 Dispositivo para SLOG (1-${#slog_devices[@]}): " slog_choice
        if [[ "$slog_choice" =~ ^[0-9]+$ ]] && [ "$slog_choice" -ge 1 ] && [ "$slog_choice" -le ${#slog_devices[@]} ]; then
            local device_info="${slog_devices[$((slog_choice-1))]}"
            local slog_device=$(echo "$device_info" | cut -d: -f1)
            local slog_usage=$(echo "$device_info" | cut -d: -f2)
            
            # Verificar si el dispositivo SLOG está en uso
            if [ "$slog_usage" != "DISPONIBLE" ]; then
                echo ""
                echo "⚠️  ADVERTENCIA CRÍTICA: El dispositivo $slog_device está EN USO"
                echo "   📁 Uso actual: $slog_usage"
                echo "   💀 Limpiar este dispositivo DESTRUIRÁ todos los datos"
                echo "   🔧 SLOG es crítico para integridad de datos"
                echo ""
                if ! confirm "¿Continuar con $slog_device para SLOG?"; then
                    echo "Selecciona otro dispositivo..."
                    continue
                fi
            fi
            break
        else
            echo "❌ Selección inválida. Usa números del 1 al ${#slog_devices[@]}."
        fi
    done
    
    # Verificar SLOG si es HDD
    if ! [[ "$slog_device" == nvme* ]] && lsblk -dpno ROTA "/dev/$slog_device" | grep -q "1"; then
        show_warning "⚠️  ADVERTENCIA: Dispositivo SLOG seleccionado es HDD"
        if ! confirm "¿Continuar con HDD para SLOG? (no recomendado)"; then
            show_message "Configuración cancelada"
            return 0
        fi
    fi
    
    # Mostrar resumen y confirmar
    echo ""
    show_message "📊 RESUMEN DE CONFIGURACIÓN:"
    echo "   Pool: $pool_name"
    echo "   L2ARC: /dev/$l2arc_device (cache de lectura)"
    echo "   SLOG: /dev/$slog_device (log de escritura)"
    echo ""
    
    show_warning "⚠️  Esto limpiará completamente ambos dispositivos"
    if confirm "¿Continuar con la configuración?"; then
        # Configurar L2ARC
        show_message "Preparando /dev/$l2arc_device para L2ARC..."
        clean_disk "$l2arc_device"
        
        # Verificar compatibilidad de tamaño de sector para L2ARC
        show_message "Verificando compatibilidad de sector para L2ARC..."
        local pool_sector_size=$(zpool get ashift "$pool_name" -H -o value 2>/dev/null | head -n 1)
        local l2arc_sector_size=$(sudo blockdev --getpbsz "/dev/$l2arc_device" 2>/dev/null)
        local l2arc_force=""
        
        if [ -n "$pool_sector_size" ] && [ -n "$l2arc_sector_size" ]; then
            local pool_bytes=$((2 ** pool_sector_size))
            if [ "$l2arc_sector_size" -ne "$pool_bytes" ]; then
                echo "   ⚠️  Pool: ${pool_bytes} bytes | L2ARC: ${l2arc_sector_size} bytes"
                if confirm "¿Forzar L2ARC?"; then
                    l2arc_force="-f"
                else
                    show_message "Configuración cancelada"
                    return 1
                fi
            fi
        fi
        
        show_message "Agregando L2ARC al pool..."
        if ! sudo zpool add $l2arc_force "$pool_name" cache "/dev/$l2arc_device"; then
            show_error "❌ Error configurando L2ARC"
            return 1
        fi
        
        # Configurar SLOG
        show_message "Preparando /dev/$slog_device para SLOG..."
        clean_disk "$slog_device"
        
        # Verificar compatibilidad de tamaño de sector para SLOG
        show_message "Verificando compatibilidad de sector para SLOG..."
        local slog_sector_size=$(sudo blockdev --getpbsz "/dev/$slog_device" 2>/dev/null)
        local slog_force=""
        
        if [ -n "$pool_sector_size" ] && [ -n "$slog_sector_size" ]; then
            local pool_bytes=$((2 ** pool_sector_size))
            if [ "$slog_sector_size" -ne "$pool_bytes" ]; then
                echo "   ⚠️  Pool: ${pool_bytes} bytes | SLOG: ${slog_sector_size} bytes"
                if confirm "¿Forzar SLOG? (RIESGOSO para integridad)"; then
                    slog_force="-f"
                else
                    show_message "Configuración cancelada"
                    return 1
                fi
            fi
        fi
        
        show_message "Agregando SLOG al pool..."
        if ! sudo zpool add $slog_force "$pool_name" log "/dev/$slog_device"; then
            show_error "❌ Error configurando SLOG"
            return 1
        fi
        
        show_message "✅ L2ARC y SLOG configurados exitosamente"
        echo ""
        show_message "📊 CONFIGURACIÓN COMPLETADA:"
        echo "   Pool: $pool_name"
        echo "   L2ARC: /dev/$l2arc_device (mejora lecturas frecuentes)"
        echo "   SLOG: /dev/$slog_device (mejora escrituras síncronas)"
        return 0
    else
        show_message "Configuración cancelada"
        return 1
    fi
}

# Función para configurar particiones L2ARC + SLOG en un dispositivo
setup_partitioned_cache() {
    local pool_name="$1"
    shift
    local available_devices=("$@")
    
    show_title "Configuración de L2ARC + SLOG Particionado para '$pool_name'"
    echo ""
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        echo "💡 PARTITION CONFIGURATION:"
    else
        echo "💡 CONFIGURACIÓN PARTICIONADA:"
    fi
    echo "   Esta opción crea particiones en un solo dispositivo:"
    echo "   • 80% del espacio para L2ARC (cache de lectura)"
    echo "   • 20% del espacio para SLOG (log de escritura)"
    echo ""
    echo "⚠️  RECOMENDACIONES:"
    echo "   • Usar solo con SSD de alta calidad (preferiblemente NVMe)"
    echo "   • El dispositivo debe tener al menos 8GB de espacio"
    echo "   • No recomendado para HDD o dispositivos USB"
    echo ""
    
    # Mostrar dispositivos recomendados
    echo "💾 DISPOSITIVOS DISPONIBLES:"
    for i in "${!available_devices[@]}"; do
        local device_info="${available_devices[$i]}"
        local device_name=$(echo "$device_info" | cut -d: -f1)
        local usage_status=$(echo "$device_info" | cut -d: -f2)
        local size=$(lsblk -dpno SIZE "/dev/$device_name" | tr -d ' ')
        local size_bytes=$(lsblk -dpno SIZE "/dev/$device_name" --bytes)
        local model=$(lsblk -dpno MODEL "/dev/$device_name" | tr -d ' ')
        local recommendation=""
        
        if [[ "$device_name" == nvme* ]]; then
            recommendation=" ⭐ EXCELENTE"
        elif lsblk -dpno ROTA "/dev/$device_name" | grep -q "0"; then
            if [ "$size_bytes" -gt 8589934592 ]; then  # 8GB
                recommendation=" ✅ ADECUADO"
            else
                recommendation=" ⚠️  PEQUEÑO (mín 8GB recomendado)"
            fi
        else
            recommendation=" ❌ NO RECOMENDADO (HDD)"
        fi
        
        if [ "$usage_status" = "DISPONIBLE" ]; then
            echo "  $((i+1)). $device_name - $size - $model$recommendation"
        else
            echo "  $((i+1)). $device_name - $size - $model$recommendation (EN USO: $usage_status)"
        fi
    done
    
    while true; do
        read -p "👉 Selecciona dispositivo (1-${#available_devices[@]}): " device_choice
        if [[ "$device_choice" =~ ^[0-9]+$ ]] && [ "$device_choice" -ge 1 ] && [ "$device_choice" -le ${#available_devices[@]} ]; then
            local device_info="${available_devices[$((device_choice-1))]}"
            local selected_device=$(echo "$device_info" | cut -d: -f1)
            local usage_status=$(echo "$device_info" | cut -d: -f2)
            
            # Verificar si el dispositivo está en uso
            if [ "$usage_status" != "DISPONIBLE" ]; then
                echo ""
                echo "⚠️  ADVERTENCIA: El dispositivo $selected_device está EN USO"
                echo "   📁 Uso actual: $usage_status"
                echo "   💀 Crear particiones DESTRUIRÁ todos los datos"
                echo ""
                if ! confirm "¿Estás SEGURO de que quieres limpiar y particionar $selected_device?"; then
                    echo "Selecciona otro dispositivo..."
                    continue
                fi
            fi
            break
        else
            echo "❌ Selección inválida. Usa números del 1 al ${#available_devices[@]}."
        fi
    done
    
    # Verificar si el dispositivo es adecuado
    local size_bytes=$(lsblk -dpno SIZE "/dev/$selected_device" --bytes)
    if [ "$size_bytes" -lt 8589934592 ]; then  # 8GB
        show_warning "⚠️  El dispositivo es menor a 8GB, puede no ser óptimo"
        if ! confirm "¿Continuar de todas formas?"; then
            show_message "Configuración cancelada"
            return 0
        fi
    fi
    
    if ! [[ "$selected_device" == nvme* ]] && lsblk -dpno ROTA "/dev/$selected_device" | grep -q "1"; then
        show_warning "⚠️  ADVERTENCIA: El dispositivo seleccionado es un HDD"
        show_warning "   No es recomendado usar HDD para particionado L2ARC+SLOG"
        if ! confirm "¿Estás seguro de continuar?"; then
            show_message "Configuración cancelada"
            return 0
        fi
    fi
    
    # Mostrar resumen
    local size_gb=$(( size_bytes / 1024 / 1024 / 1024 ))
    local l2arc_size=$(( size_gb * 80 / 100 ))
    local slog_size=$(( size_gb * 20 / 100 ))
    
    echo ""
    show_message "📊 CONFIGURACIÓN PLANIFICADA:"
    echo "   Dispositivo: /dev/$selected_device ($size_gb GB)"
    echo "   Partición L2ARC: ~${l2arc_size}GB (80%)"
    echo "   Partición SLOG: ~${slog_size}GB (20%)"
    echo ""
    
    show_warning "⚠️  Esto destruirá todos los datos en /dev/$selected_device"
    if confirm "¿Continuar con el particionado?"; then
        echo ""
        show_message "🔍 VERIFICACIÓN PREVIA DEL POOL:"
        echo "   Pool: $pool_name"
        echo "   Estado: $(zpool get health "$pool_name" -H -o value 2>/dev/null || echo "DESCONOCIDO")"
        echo "   Versión: $(zpool get version "$pool_name" -H -o value 2>/dev/null || echo "DESCONOCIDA")"
        echo ""
        
        show_message "Preparando dispositivo /dev/$selected_device..."
        
        # Limpiar dispositivo
        if ! clean_disk "$selected_device"; then
            show_error "❌ Error limpiando el dispositivo"
            show_message "Regresando al menú anterior..."
            return 1
        fi
        
        # Crear tabla de particiones GPT
        show_message "Creando tabla de particiones..."
        if ! sudo parted "/dev/$selected_device" --script mklabel gpt; then
            show_error "❌ Error creando tabla de particiones"
            show_message "Regresando al menú anterior..."
            return 1
        fi
        
        # Crear partición L2ARC (80%)
        show_message "Creando partición L2ARC (80% del espacio)..."
        if ! sudo parted "/dev/$selected_device" --script mkpart l2arc ext4 1MiB 80%; then
            show_error "❌ Error creando partición L2ARC"
            show_message "Regresando al menú anterior..."
            return 1
        fi
        
        # Crear partición SLOG (20%)
        show_message "Creando partición SLOG (20% del espacio)..."
        if ! sudo parted "/dev/$selected_device" --script mkpart slog ext4 80% 100%; then
            show_error "❌ Error creando partición SLOG"
            show_message "Regresando al menú anterior..."
            return 1
        fi
        
        # Esperar que el kernel reconozca las particiones
        sudo partprobe "/dev/$selected_device"
        sleep 3
        
        # Determinar nombres de particiones
        local l2arc_partition="${selected_device}1"
        local slog_partition="${selected_device}2"
        
        # Si es NVMe, las particiones tienen formato diferente
        if [[ "$selected_device" == nvme* ]]; then
            l2arc_partition="${selected_device}p1"
            slog_partition="${selected_device}p2"
        fi
        
        # Verificar que las particiones existen
        if [ ! -b "/dev/$l2arc_partition" ] || [ ! -b "/dev/$slog_partition" ]; then
            show_error "❌ Error: Las particiones no se crearon correctamente"
            show_message "Regresando al menú anterior..."
            return 1
        fi
        
        # Agregar L2ARC y SLOG
        echo ""
        show_message "🔧 Agregando L2ARC y SLOG al pool en un solo comando..."
        echo "   💡 Cache devices no requieren compatibilidad de ashift"
        echo "   Comando: zpool add '$pool_name' cache '/dev/$l2arc_partition' log '/dev/$slog_partition'"
        
        # Verificar que ambas particiones existen y son accesibles
        if [ ! -b "/dev/$l2arc_partition" ]; then
            show_error "❌ Partición L2ARC /dev/$l2arc_partition no existe"
            return 1
        fi
        
        if [ -n "$pool_sector_size" ] && [ -n "$cache_sector_size" ]; then
            local pool_bytes=$((2 ** pool_sector_size))
            echo "   Pool sector size: ${pool_bytes} bytes (ashift=$pool_sector_size)"
            echo "   Cache sector size: ${cache_sector_size} bytes"
            
            if [ "$cache_sector_size" -ne "$pool_bytes" ]; then
                echo ""
                show_error "⚠️  INCOMPATIBILIDAD DE TAMAÑO DE SECTOR:"
                echo "   📊 Pool '$pool_name': ${pool_bytes} bytes"
                echo "   💾 Cache device: ${cache_sector_size} bytes"
                echo ""
                show_message "[INFO] 🔍 CAUSA DEL PROBLEMA:"
                echo "   El pool fue creado con ashift=$pool_sector_size"
                if [ "$pool_sector_size" -eq 0 ]; then
                    echo "   ⚠️  ashift=0 indica pool creado sin configuración óptima"
                    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
                        echo "   💡 For new pools, the script now uses automatic ashift"
                    else
                        echo "   💡 Para nuevos pools, el script ahora usa ashift automático"
                    fi
                    echo "   � Recomendación: Recrear pool con ashift=12 para compatibilidad"
                fi
                echo ""
                echo "�💡 OPCIONES DISPONIBLES:"
                echo "   1. Continuar SIN cache (recomendado)"
                echo "   2. Forzar adición con -f (puede causar problemas)"
                echo "   3. Usar un dispositivo con sector compatible"
                echo "   4. Recrear pool con ashift correcto (óptimo a largo plazo)"
                echo ""
                
                read -p "👉 Selecciona opción (1-3): " sector_choice
                case $sector_choice in
                    1)
                        show_message "Configuración cancelada - pool funcionará sin cache"
                        return 1
                        ;;
                    2)
                        show_warning "⚠️  Usando -f para forzar la adición..."
                        local force_flag="-f"
                        ;;
                    3)
                        show_message "Configuración cancelada - selecciona otro dispositivo"
                        return 1
                        ;;
                    *)
                        show_message "Opción inválida - cancelando configuración"
                        return 1
                        ;;
                esac
            else
                echo "   ✅ Tamaños de sector compatibles"
                local force_flag=""
            fi
        else
            echo "   ⚠️  No se pudo verificar tamaño de sector completamente"
            echo "   Intentando adición normal..."
            local force_flag=""
        fi
        
        # Agregar L2ARC
        echo ""
        show_message "🔧 Agregando L2ARC y SLOG al pool en un solo comando..."
        echo "   Comando: zpool add $force_flag '$pool_name' cache '/dev/$l2arc_partition' log '/dev/$slog_partition'"
        
        # Verificar que ambas particiones existen y son accesibles
        if [ ! -b "/dev/$l2arc_partition" ]; then
            show_error "❌ Partición L2ARC /dev/$l2arc_partition no existe"
            return 1
        fi
        
        if [ ! -b "/dev/$slog_partition" ]; then
            show_error "❌ Partición SLOG /dev/$slog_partition no existe"
            return 1
        fi
        
        # Mostrar información de ambas particiones antes de agregar
        echo "   Partición L2ARC: $(lsblk -no SIZE,FSTYPE "/dev/$l2arc_partition" 2>/dev/null || echo "sin formato")"
        echo "   Partición SLOG: $(lsblk -no SIZE,FSTYPE "/dev/$slog_partition" 2>/dev/null || echo "sin formato")"
        
        if sudo zpool add "$pool_name" cache "/dev/$l2arc_partition" log "/dev/$slog_partition" 2>&1; then
            show_message "✅ L2ARC y SLOG agregados exitosamente en un solo comando"
            echo ""
            show_message "📊 CONFIGURACIÓN COMPLETADA:"
            echo "   Pool: $pool_name"
            echo "   Dispositivo base: /dev/$selected_device"
            echo "   L2ARC: /dev/$l2arc_partition (~${l2arc_size}GB)"
            echo "   SLOG: /dev/$slog_partition (~${slog_size}GB)"
            echo "   Función: Cache de lectura + Log de escritura optimizados"
            echo "   💡 Ambos dispositivos agregados en comando único"
            return 0
        else
            local exit_code=$?
            show_error "❌ Error agregando L2ARC y SLOG (código: $exit_code)"
            echo ""
            echo "� INFORMACIÓN DE DIAGNÓSTICO:"
            echo "   • Pool status:"
            zpool status "$pool_name" | head -n 10
            echo "   • Dispositivo L2ARC:"
            lsblk "/dev/$l2arc_partition" 2>/dev/null || echo "     No se puede leer la partición"
            echo "   • Dispositivo SLOG:"
            lsblk "/dev/$slog_partition" 2>/dev/null || echo "     No se puede leer la partición"
            echo "   • Posibles causas:"
            echo "     - Partición ya en uso"
            echo "     - Permisos insuficientes"
            echo "     - Pool en estado degradado"
            echo "   💡 Cache devices no requieren compatibilidad de ashift"
            show_message "Regresando al menú anterior..."
            return 1
        fi
    else
        show_message "Configuración cancelada"
        return 1
    fi
}

# Función para crear snapshots iniciales
create_initial_snapshots() {
        
        if sudo zpool add $force_flag "$pool_name" log "/dev/$slog_partition" 2>&1; then
            show_message "✅ SLOG agregado exitosamente"
        else
            local exit_code=$?
            show_error "❌ Error agregando SLOG (código: $exit_code)"
            echo ""
            echo "� INFORMACIÓN DE DIAGNÓSTICO:"
            echo "   • Pool status:"
            zpool status "$pool_name" | head -n 10
            echo "   • Dispositivo SLOG:"
            lsblk "/dev/$slog_partition" 2>/dev/null || echo "     No se puede leer la partición"
            echo "   • Posibles causas:"
            echo "     - Sector size incompatible"
            echo "     - Partición ya en uso"
            echo "     - Permisos insuficientes"
            echo "     - Pool en estado degradado"
            show_message "Regresando al menú anterior..."
            return 1
        fi
}

# Función para crear snapshots iniciales
create_initial_snapshots() {
    local pool_name="$1"
    
    show_title "Creación de Snapshots Iniciales"
    echo ""
    if [ "$SCRIPT_LANGUAGE" = "en" ]; then
        echo "💡 Snapshots are instant copies of datasets that take no initial space."
    else
        echo "💡 Los snapshots son copias instantáneas de datasets que no ocupan espacio inicial."
    fi
    echo "   Son útiles para:"
    echo "   • Backups rápidos antes de cambios importantes"
    echo "   • Restauración rápida a estados anteriores"
    echo "   • Bases para replicación de datos"
    echo ""
    
    # Obtener datasets del pool
    local datasets=$(zfs list -H -o name -r "$pool_name" 2>/dev/null)
    
    if [ -n "$datasets" ]; then
        echo "📁 Datasets disponibles para snapshot:"
        for dataset in $datasets; do
            echo "  • $dataset"
        done
        echo ""
        
        if confirm "¿Crear snapshot inicial de todos los datasets?"; then
            local timestamp=$(date +"%Y%m%d-%H%M%S")
            local snapshot_name="inicial-$timestamp"
            
            for dataset in $datasets; do
                show_message "Creando snapshot: $dataset@$snapshot_name"
                if sudo zfs snapshot "$dataset@$snapshot_name"; then
                    show_message "✅ Snapshot creado: $dataset@$snapshot_name"
                else
                    show_error "❌ Error creando snapshot de $dataset"
                fi
            done
            
            echo ""
            show_message "📊 Snapshots creados:"
            sudo zfs list -t snapshot -o name,used,creation | grep "@$snapshot_name"
        fi
    else
        show_warning "No se encontraron datasets en el pool '$pool_name'"
    fi
}

# Función para mostrar estado completo del pool
show_pool_status() {
    local pool_name="$1"
    
    # Debugging para identificar el problema
    if [ -z "$pool_name" ]; then
        show_error "Error crítico: show_pool_status llamado sin parámetro de pool_name"
        echo "Información de debug:"
        echo "  Parámetros recibidos: '$@'"
        echo "  Número de parámetros: $#"
        echo "  Variable global POOL_NAME: '$POOL_NAME'"
        echo "  Pools disponibles: $(zpool list -H -o name 2>/dev/null | tr '\n' ' ')"
        read -p "Presiona Enter para continuar..."
        return 1
    fi
    
    show_title "Estado Completo del Pool '$pool_name'"
    echo ""
    
    # Estado del pool
    echo "🏊 ESTADO DEL POOL:"
    sudo zpool status "$pool_name"
    echo ""
    
    # Información del pool
    echo "📊 INFORMACIÓN DEL POOL:"
    sudo zpool list "$pool_name"
    echo ""
    
    # Datasets
    echo "📁 DATASETS:"
    sudo zfs list -r "$pool_name"
    echo ""
    
    # Snapshots (si existen)
    local snapshots=$(zfs list -t snapshot -H -o name 2>/dev/null | grep "^$pool_name")
    if [ -n "$snapshots" ]; then
        echo "📸 SNAPSHOTS:"
        sudo zfs list -t snapshot -r "$pool_name"
        echo ""
    fi
    
    # Propiedades del pool
    echo "⚙️  PROPIEDADES PRINCIPALES:"
    echo "ARC Max: $(cat /sys/module/zfs/parameters/zfs_arc_max 2>/dev/null || echo 'No configurado')"
    sudo zpool get all "$pool_name" | grep -E "ashift|feature|autoreplace|failmode"
}

# Ejecutar función principal
main "$@"