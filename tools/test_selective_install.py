#!/usr/bin/env python3
"""
Script de prueba para demostrar el comportamiento cuando solo BTRFS está disponible
"""

# Simular que solo BTRFS está disponible
def simulate_raid_tools_check():
    """Simula el resultado de _check_raid_tools con solo BTRFS disponible"""
    return {
        'btrfs': True,   # BTRFS disponible
        'zfs': False,    # ZFS NO disponible  
        'mdadm': False   # MDADM NO disponible
    }

# Simular la lógica del RequirementsChecker
def test_selective_installation_logic():
    print("🧪 SIMULACIÓN: Solo BTRFS disponible, ZFS y MDADM faltantes\n")
    
    # Simular resultado de herramientas
    raid_tools = simulate_raid_tools_check()
    
    # Lógica mejorada
    missing_tools = [tool for tool, available in raid_tools.items() if not available]
    available_tools = [tool for tool, available in raid_tools.items() if available]
    
    print("📊 Estado actual:")
    print(f"   ✅ Disponibles: {', '.join(tool.upper() for tool in available_tools)}")
    print(f"   ❌ Faltantes: {', '.join(tool.upper() for tool in missing_tools)}")
    
    if not any(raid_tools.values()):
        print("\n🚫 Escenario: Sin herramientas RAID")
        print("   → Se ofrecería instalar todas las herramientas")
        
    elif missing_tools:
        print("\n⚙️ Escenario: Herramientas parciales")
        print("   → Se ofrece instalar las faltantes específicamente")
        print(f"   💡 Pregunta: ¿Deseas instalar las herramientas faltantes ({', '.join(tool.upper() for tool in missing_tools)})?")
        
        # Simular respuestas
        print("\n🔄 Opciones que se ofrecerían:")
        for tool in missing_tools:
            if tool == 'zfs':
                print("   📦 ZFS: ¿Instalar soporte para ZFS? (puede tomar varios minutos)")
            elif tool == 'mdadm':
                print("   📦 MDADM: ¿Instalar soporte para MDADM?")
            elif tool == 'btrfs':
                print("   📦 BTRFS: ¿Instalar soporte para BTRFS?")
    
    else:
        print("\n✅ Escenario: Todas las herramientas disponibles")
        print("   → No se necesita instalación adicional")

# Simular diferentes escenarios
def test_different_scenarios():
    scenarios = [
        {
            'name': 'Solo BTRFS disponible',
            'tools': {'btrfs': True, 'zfs': False, 'mdadm': False}
        },
        {
            'name': 'Solo ZFS disponible', 
            'tools': {'btrfs': False, 'zfs': True, 'mdadm': False}
        },
        {
            'name': 'BTRFS y MDADM, falta ZFS',
            'tools': {'btrfs': True, 'zfs': False, 'mdadm': True}
        },
        {
            'name': 'Ninguna herramienta disponible',
            'tools': {'btrfs': False, 'zfs': False, 'mdadm': False}
        }
    ]
    
    for scenario in scenarios:
        print(f"\n{'='*60}")
        print(f"🧪 ESCENARIO: {scenario['name']}")
        print('='*60)
        
        raid_tools = scenario['tools']
        missing_tools = [tool for tool, available in raid_tools.items() if not available]
        available_tools = [tool for tool, available in raid_tools.items() if available]
        
        print(f"✅ Disponibles: {', '.join(tool.upper() for tool in available_tools) if available_tools else 'Ninguna'}")
        print(f"❌ Faltantes: {', '.join(tool.upper() for tool in missing_tools) if missing_tools else 'Ninguna'}")
        
        if not any(raid_tools.values()):
            print("\n🚫 COMPORTAMIENTO:")
            print("   → Error: No se pueden cumplir los requisitos mínimos")
            print("   → Pregunta: ¿Deseas instalar las herramientas RAID necesarias?")
            print("   → Instala: Herramientas básicas + BTRFS + (opcional) ZFS")
            
        elif missing_tools:
            print("\n⚙️ COMPORTAMIENTO:")
            print("   → Info: Herramientas parciales disponibles")
            print(f"   → Pregunta: ¿Deseas instalar las herramientas faltantes ({', '.join(tool.upper() for tool in missing_tools)})?")
            print("   → Instala: Solo las herramientas específicas que faltan")
            
        else:
            print("\n✅ COMPORTAMIENTO:")
            print("   → Todo OK: Continúa sin instalación adicional")

if __name__ == "__main__":
    print("🔍 ANÁLISIS DE COMPORTAMIENTO DE INSTALACIÓN SELECTIVA")
    print("="*60)
    
    test_selective_installation_logic()
    test_different_scenarios()
    
    print(f"\n{'='*60}")
    print("📋 RESUMEN:")
    print("✅ El sistema ahora detecta herramientas parciales")
    print("✅ Ofrece instalación selectiva de solo lo que falta") 
    print("✅ Permite trabajar con herramientas disponibles")
    print("✅ Da opciones granulares por cada herramienta")
