#!/bin/bash
# parcheo-rh.sh - Parcheo automático para Red Hat / CentOS / Rocky / AlmaLinux
# Compatible con RHEL 8+, CentOS Stream 8+, Rocky Linux 8+, AlmaLinux 8+

set -euo pipefail

LOG="/var/log/parcheo-rh.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

log() {
    echo "[$DATE] $1" | tee -a "$LOG"
}

log "=== Inicio de parcheo ==="

# Comprobar si hay actualizaciones disponibles
# dnf check-update devuelve 100 si hay updates, 0 si no hay, otro código si error
log "Comprobando actualizaciones disponibles..."
dnf check-update -q 2>&1 | tee -a "$LOG" || true
EXIT_CODE=${PIPESTATUS[0]}

if [ "$EXIT_CODE" -eq 100 ]; then
    log "Hay actualizaciones disponibles. Aplicando..."
    dnf upgrade -y 2>&1 | tee -a "$LOG"
    log "Actualizaciones aplicadas correctamente."
elif [ "$EXIT_CODE" -eq 0 ]; then
    log "El sistema ya está al día. No hay nada que actualizar."
else
    log "ERROR: dnf check-update devolvió código $EXIT_CODE"
    exit 1
fi

# Limpieza de paquetes huérfanos y caché
log "Limpiando paquetes obsoletos..."
dnf autoremove -y 2>&1 | tee -a "$LOG"
dnf clean all 2>&1 | tee -a "$LOG"
log "Limpieza completada."

# Comprobar si se necesita reinicio (requiere dnf-utils)
if command -v needs-restarting &>/dev/null; then
    if ! needs-restarting -r &>/dev/null; then
        log "AVISO: Se requiere reinicio del sistema para aplicar todos los cambios."
    else
        log "No se necesita reinicio."
    fi
else
    log "needs-restarting no disponible. Instala dnf-utils para detección de reinicio."
fi

log "=== Fin de parcheo ==="
