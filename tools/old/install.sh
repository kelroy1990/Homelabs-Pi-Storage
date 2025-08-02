#!/bin/bash
"""
Instalador para RAID Manager Python
"""

echo "🚀 Instalando RAID Manager Python..."

# Verificar Python 3
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 no encontrado. Instalando..."
    sudo apt update
    sudo apt install -y python3 python3-pip python3-venv
fi

# Crear entorno virtual
echo "📦 Creando entorno virtual..."
python3 -m venv raid_manager_env
source raid_manager_env/bin/activate

# Instalar dependencias
echo "📥 Instalando dependencias..."
pip install -r requirements.txt

# Hacer ejecutable
chmod +x raid_manager.py

# Crear enlace simbólico
echo "🔗 Creando enlace simbólico..."
sudo ln -sf "$(pwd)/raid_manager.py" /usr/local/bin/raid-manager

echo "✅ Instalación completada!"
echo ""
echo "💡 Uso:"
echo "   raid-manager              # Interfaz interactiva"
echo "   python3 raid_manager.py   # Ejecución directa"
echo ""
echo "📋 Para activar el entorno virtual manualmente:"
echo "   source $(pwd)/raid_manager_env/bin/activate"
