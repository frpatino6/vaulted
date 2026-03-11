#!/bin/bash
# Inicia el emulador Android CON KVM.
# Uso: ./start-emulator.sh [gpu|cold]
#   sin args = GPU software. host = GPU real. cold = arranque limpio (si el sistema murió).

EMULATOR="/home/fernando/Android/Sdk/emulator/emulator"
AVD="Medium_Phone_API_36.1"

COLD=""
if [[ "$1" == "cold" ]]; then
  COLD="-no-snapshot-load"
  GPU="swiftshader_indirect"
else
  GPU="${1:-swiftshader_indirect}"
fi

adb emu kill 2>/dev/null && sleep 2
nohup sg kvm -c "$EMULATOR -avd $AVD -gpu $GPU $COLD" >> /tmp/emulator.log 2>&1 &
disown
echo "Emulador iniciando (KVM, gpu=$GPU${COLD:+ cold boot}). 30–60 s (cold: 1–2 min). Log: /tmp/emulator.log"
echo "Si el sistema murió otra vez: $0 cold"
