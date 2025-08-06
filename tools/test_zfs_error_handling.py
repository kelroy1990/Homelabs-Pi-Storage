#!/usr/bin/env python3
"""
Prueba del manejo mejorado de errores para ZFS import
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from raid_manager import RAIDManager, SystemManager
from unittest.mock import patch, MagicMock
import subprocess

def test_zfs_error_diagnostics():
    """Prueba el manejo de errores mejorado para ZFS import"""
    
    print("\n🔧 Probando diagnóstico de errores ZFS...")
    
    # Crear instancia del RAID manager
    raid_manager = RAIDManager()
    
    # Diferentes tipos de errores ZFS para probar
    test_errors = [
        "cannot import 'test_pool': pool already imported",
        "cannot import 'test_pool': one or more devices is currently unavailable",
        "cannot import 'test_pool': pool was previously in use from another system",
        "cannot import 'test_pool': I/O error",
        "cannot import 'test_pool': invalid vdev specification"
    ]
    
    for i, error_msg in enumerate(test_errors, 1):
        print(f"\n📋 Prueba {i}: {error_msg}")
        
        # Simular un error de ZFS import con stderr detallado
        mock_error = subprocess.CalledProcessError(
            returncode=1,
            cmd=['sudo', 'zpool', 'import', '-f', 'test_pool'],
            stderr=error_msg.encode()
        )
        
        # Probar el diagnóstico
        try:
            raid_manager._diagnose_zfs_import_error(mock_error)
            print("✅ Diagnóstico completado correctamente")
        except Exception as e:
            print(f"❌ Error en diagnóstico: {e}")

def test_advanced_recovery():
    """Prueba las opciones de recuperación avanzada"""
    
    print("\n🔧 Probando recuperación avanzada de ZFS...")
    
    raid_manager = RAIDManager()
    
    # Simular entrada del usuario para las opciones de recuperación
    with patch('builtins.input', side_effect=['1', 'n']):  # Seleccionar opción 1, luego no continuar
        with patch.object(raid_manager.system_manager, 'run_command') as mock_run:
            mock_run.return_value = "test output"
            
            try:
                result = raid_manager._try_advanced_zfs_import('test_pool')
                print("✅ Recuperación avanzada ejecutada correctamente")
                print(f"Resultado: {result}")
            except Exception as e:
                print(f"❌ Error en recuperación avanzada: {e}")

def test_stderr_capture():
    """Prueba la captura mejorada de stderr"""
    
    print("\n🔧 Probando captura de stderr...")
    
    # Simular la creación de SystemManager con una consola mock
    with patch('raid_manager.UIConsole') as mock_console_class:
        mock_console = MagicMock()
        mock_console_class.return_value = mock_console
        
        system_manager = SystemManager(mock_console)
        
        # Simular un comando que falla con stderr
        with patch('subprocess.run') as mock_run:
            mock_process = MagicMock()
            mock_process.returncode = 1
            mock_process.stdout = "stdout output"
            mock_process.stderr = "detailed error message"
            mock_run.return_value = mock_process
            
            try:
                system_manager.run_command(['false'])  # Comando que siempre falla
                print("❌ Debería haber lanzado una excepción")
            except subprocess.CalledProcessError as e:
                if hasattr(e, 'stderr') and e.stderr:
                    print("✅ stderr capturado correctamente en la excepción")
                    print(f"stderr: {e.stderr}")
                else:
                    print("❌ stderr no capturado en la excepción")

if __name__ == "__main__":
    print("🚀 Iniciando pruebas del manejo mejorado de errores ZFS")
    
    test_zfs_error_diagnostics()
    test_advanced_recovery()
    test_stderr_capture()
    
    print("\n✅ Todas las pruebas de manejo de errores completadas")
    print("\n📋 Resumen de mejoras implementadas:")
    print("   • Captura detallada de stderr en errores ZFS")
    print("   • Diagnóstico automático de tipos de error")
    print("   • Sugerencias específicas de solución")
    print("   • Opciones de recuperación avanzada")
    print("   • Interfaz de usuario mejorada con Rich")
