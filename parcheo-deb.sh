#!/bin/bash
# parcheo-deb.sh - Parcheo automático para Debian/Ubuntu
# Compatible con Debian 10+ y Ubuntu 18.04+

set -euo pipefail

LOG="/var/log/parcheo-deb.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

log() {
    echo "[$DATE] $1" | tee -a "$LOG"
}

log "=== Inicio de parcheo ==="

# Actualizar lista de paquetes
log "Actualizando lista de paquetes..."
apt update -q 2>&1 | tee -a "$LOG"

# Comprobar si hay actualizaciones disponibles
UPDATES=$(apt list --upgradable 2>/dev/null | grep -c upgradable || true)
log "Paquetes pendientes de actualizar: $UPDATES"

if [ "$UPDATES" -gt 0 ]; then
    log "Aplicando actualizaciones..."
    DEBIAN_FRONTEND=noninteractive apt upgrade -y 2>&1 | tee -a "$LOG"
    log "Actualizaciones aplicadas correctamente."
else
    log "El sistema ya está al día. No hay nada que actualizar."
fi

# Limpieza de paquetes huérfanos
log "Limpiando paquetes obsoletos..."
apt autoremove -y 2>&1 | tee -a "$LOG"
apt clean 2>&1 | tee -a "$LOG"
log "Limpieza completada."

# Comprobar si se necesita reinicio
if [ -f /var/run/reboot-required ]; then
    log "AVISO: Se requiere reinicio del sistema para aplicar todos los cambios."
else
    log "No se necesita reinicio."
fi

log "=== Fin de parcheo ==="
