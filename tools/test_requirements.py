#!/usr/bin/env python3
"""
Script de prueba para verificar la funcionalidad de verificación de requisitos
"""

import sys
import os

# Añadir el directorio actual al path para importar raid_manager
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    from raid_manager import RequirementsChecker, UIConsole, SystemManager
    
    def test_requirements():
        """Prueba la verificación de requisitos"""
        print("🧪 Iniciando prueba de verificación de requisitos...")
        
        # Crear instancias
        console = UIConsole()
        system = SystemManager(console)
        checker = RequirementsChecker(console, system)
        
        # Ejecutar verificación
        result = checker.check_all_requirements()
        
        print(f"\n🔍 Resultado de la verificación: {'✅ ÉXITO' if result else '❌ FALLO'}")
        
        return result
    
    if __name__ == "__main__":
        print("=" * 60)
        print("PRUEBA DE VERIFICACIÓN DE REQUISITOS")
        print("=" * 60)
        
        success = test_requirements()
        
        print("\n" + "=" * 60)
        print("PRUEBA COMPLETADA")
        print("=" * 60)
        
        sys.exit(0 if success else 1)
        
except ImportError as e:
    print(f"❌ Error importando raid_manager: {e}")
    print("💡 Asegúrate de que raid_manager.py está en el mismo directorio")
    sys.exit(1)
except Exception as e:
    print(f"❌ Error inesperado: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
