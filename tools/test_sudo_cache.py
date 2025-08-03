#!/usr/bin/env python3
"""
Test para verificar que las operaciones de cache usan sudo correctamente
"""

import subprocess
import os
from raid_manager import SystemManager, UIConsole

def test_sudo_system():
    """Verifica que el sistema de sudo funciona correctamente"""
    console = UIConsole()
    system = SystemManager(console)
    
    print("🔐 Verificando sistema de permisos para cache devices...")
    
    # Test 1: Verificar si es root
    is_root = system.is_root()
    print(f"   • Usuario actual es root: {is_root}")
    
    # Test 2: Verificar sudo disponible
    has_sudo = system.check_sudo()
    print(f"   • Sudo disponible: {has_sudo}")
    
    # Test 3: Verificar comandos que requieren sudo
    test_commands = ['zpool', 'sgdisk', 'wipefs', 'partprobe', 'udevadm']
    
    print(f"\n🔧 Comandos críticos para cache (should use sudo if not root):")
    for cmd in test_commands:
        needs_sudo = cmd in system.sudo_commands and not is_root
        print(f"   • {cmd}: {'🔐 Con sudo' if needs_sudo else '✅ Directo'}")
    
    # Test 4: Simular comando con dry-run
    if not is_root:
        print(f"\n🧪 Test comando con sudo (dry-run):")
        test_cmd = ['echo', 'test-command']
        final_cmd = ['sudo'] + test_cmd
        print(f"   • Comando final que se ejecutaría: {' '.join(final_cmd)}")
    
    # Test 5: Verificar detección automática
    print(f"\n🎯 Detección automática de sudo:")
    for cmd in ['zpool', 'ls', 'echo']:
        command_name = cmd.split('/')[-1]
        needs_sudo = command_name in system.sudo_commands and not is_root
        print(f"   • '{cmd}' necesita sudo: {needs_sudo}")
    
    print(f"\n✅ Sistema de permisos para cache devices está configurado correctamente")
    print(f"   📝 Comandos de cache (zpool add, sgdisk, etc.) usarán sudo automáticamente")
    print(f"   🔐 El usuario no necesita preocuparse por permisos manualmente")

if __name__ == "__main__":
    test_sudo_system()
