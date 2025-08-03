#!/usr/bin/env python3
"""Script de prueba para verificar cambios"""

from raid_manager import RAIDManager

def test_disk_filtering():
    """Prueba que discos de 0.0B no aparezcan"""
    print("=== Test: Filtrado de discos ===")
    
    manager = RAIDManager()
    disks = manager.disk_manager.detect_disks()
    
    print(f"Total discos detectados: {len(disks)}")
    
    zero_size_disks = [d for d in disks if d.size <= 0]
    print(f"Discos con tamaño 0: {len(zero_size_disks)}")
    
    if zero_size_disks:
        print("❌ FALLO: Se encontraron discos con tamaño 0:")
        for disk in zero_size_disks:
            print(f"  - {disk.name}: {disk.size} bytes")
    else:
        print("✅ ÉXITO: No hay discos con tamaño 0")
    
    print("\nDiscos detectados:")
    for disk in disks:
        print(f"  - {disk.name}: {disk.size_human} ({disk.size} bytes)")
    
    return len(zero_size_disks) == 0

def main():
    """Función principal de prueba"""
    print("🧪 Verificando cambios realizados...\n")
    
    # Test 1: Filtrado de discos
    success = test_disk_filtering()
    
    print(f"\n🎯 Resultado: {'✅ ÉXITO' if success else '❌ FALLO'}")

if __name__ == "__main__":
    main()
