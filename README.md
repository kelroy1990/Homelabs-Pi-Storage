# CM5 Expansion Board - NAS/Server Platform

## Introduction

As member of the HomeLabs Club community i really like all of the Raspberry Pi ecosystem, so i decided to work on an expansion board for the Raspberry Pi CM5 that turns it into a proper NAS/server platform with low power consumption. After months of development, I think it's ready to share with the community.

While this started as a personal project inspired by the Raspberry Pi ecosystem and my passion for servers and homelab setups, the non-profit association Homelabs Club is planning to make this available commercially in a near future.

<img width="1258" height="900" alt="Image" src="https://github.com/user-attachments/assets/fe63dd70-395e-488b-9fd2-77ce4abf1d53" />

## Hardware Features

**CM5 Compatibility:**
Works with both SD card and eMMC versions of the CM5
Built-in SD card slot accessible from inside the board
Internal USB-C port allows direct programming of CM5's eMMC or SD card

**Sensors**
- Current Sensor for the whole board, report directly by linux command "sensors"

**Networking:**
- 2.5G Ethernet port (Note: This NIC doesn't have a pre-burned MAC address, so the system will generate a random one at boot. We can set a static one in linux, this allow us to make this as we prefer)
- 1G Ethernet port  

**Connectivity:**
- HDMI output
- 2x USB 3.0 ports
- 40-pin GPIO header (standard Pi layout)

**Storage:**
- 2x NVMe M.2 slots
- 6x SATA ports for HDDs

**Power & Control:**
- Hardware power button
- 2x 4-pin fan headers for case cooling
- Dedicated CM5 cooling connector
- CR2035 battery holder for RTC power


..... And a lot of LEDs, of course.
## Power Requirements

The board needs a 16-21V DC power supply with at least 150W capacity. I recommend going with 180W to be safe, especially if you're planning to run multiple drives.

It must be a DC barrel jack with a **5.5x2.5mm** conector, it's really easy and cheap to find. The best option its fo find a cheap laptop DC power supply adapter.

For example, i am using my old ASUS laptop DC power supply, and it work like a rock¡¡

## Thermal Considerations

This thing gets hot. The CM5 absolutely needs active cooling - I'm using a heatsink with a fan. The board itself has heatsinks on the main power components, but you'll want good airflow through your case. The fan headers help with this.

## Block Diagram

<img width="1234" height="829" alt="Image" src="https://github.com/user-attachments/assets/d3859c8f-c12a-436b-bfab-53c1821d4049" />

The CM5 has its limitations - I've tried to balance the available resources as best as possible, but there will definitely be bottlenecks. That's part of the fun though, figuring out what those limits are and how to work around them :)

## Photos

It's a sleek black PCB - 6 layers of pure awesomeness! The board quality turned out really nice.

<img width="960" height="1280" alt="Image" src="https://github.com/user-attachments/assets/557cb8e6-bf2f-4416-8299-f08cd01a677e" />

<img width="960" height="1280" alt="Image" src="https://github.com/user-attachments/assets/931082d8-f6ba-448f-a69c-8374061074e9" />

## Community Project

I've released the STEP files for anyone who wants to design cases. We're 3D printing and building complete NAS units with community designs - it's been pretty cool to see what people come up with.

<img width="1291" height="847" alt="Image" src="https://github.com/user-attachments/assets/64b88542-87f6-4cef-a693-cce6eb76e5e7" />

<img width="658" height="628" alt="Image" src="https://github.com/user-attachments/assets/de17574a-11bd-4f3f-aa0b-16d5202f0aa0" />

## Notes

A few things I learned during development:

- Don't skimp on the power supply - drives spinning up can cause voltage drops
- Case airflow is critical, especially around the CM5 area


This has been a challenging and super fun project to work on. But honestly, the most exciting part will be seeing what the community creates around this board!