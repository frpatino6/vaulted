#!/bin/bash
# Script para arreglar el emulador Android (KVM) y reiniciarlo
# Ejecutar: ./fix-emulator-and-start.sh
# Solo pedirá la contraseña UNA vez para sudo

set -e

EMULATOR="/home/fernando/Android/Sdk/emulator/emulator"
AVD="Medium_Phone_API_36.1"

echo "=== Arreglando emulador Android ==="

# 1. Añadir usuario al grupo kvm (necesario para aceleración por hardware)
echo "Añadiendo $USER al grupo kvm..."
sudo usermod -aG kvm "$USER"
echo "✓ Usuario añadido al grupo kvm"

# 2. Cerrar emulador si está corriendo
echo "Cerrando emulador actual..."
adb emu kill 2>/dev/null && echo "✓ Emulador cerrado" || true
sleep 2

# 3. Iniciar emulador con KVM (nohup para que sobreviva al cerrar la terminal)
echo "Iniciando emulador con aceleración por hardware..."
nohup sg kvm -c "$EMULATOR -avd $AVD" >> /tmp/emulator.log 2>&1 &
disown
echo "✓ Emulador iniciando (log en /tmp/emulator.log)"
echo ""
echo "Listo. La ventana del emulador aparecerá en unos 30-60 segundos."
echo "Puedes cerrar esta terminal, el emulador seguirá corriendo."
