#!/bin/bash
# parcheo-rh.sh - Parcheo automatico para Red Hat 8+
# Uso: ejecutar como root o con sudo

LOG=$(mktemp)
REBOOT_NEEDED=false
HOSTNAME=$(hostname)
FECHA=$(date '+%Y-%m-%d %H:%M')

echo "=== Parcheo VM: $HOSTNAME ===" > "$LOG"
echo "Fecha: $FECHA" >> "$LOG"
echo "" >> "$LOG"

# Actualizar lista de paquetes
echo ">>> dnf check-update..." >> "$LOG"
dnf check-update >> "$LOG" 2>&1
CHECK_EXIT=$?

# 0 = sin updates, 100 = hay updates, otro = error
if [ $CHECK_EXIT -eq 0 ]; then
    echo "" >> "$LOG"
    echo "No hay paquetes pendientes de actualizar." >> "$LOG"
    PARCHES_APLICADOS=false
elif [ $CHECK_EXIT -eq 100 ]; then
    echo "" >> "$LOG"
    echo ">>> Aplicando actualizaciones..." >> "$LOG"
    dnf upgrade -y >> "$LOG" 2>&1
    if [ $? -eq 0 ]; then
        echo "Actualizaciones aplicadas correctamente." >> "$LOG"
        PARCHES_APLICADOS=true
    else
        echo "ERROR al aplicar actualizaciones." >> "$LOG"
        PARCHES_APLICADOS=false
    fi
else
    echo "ERROR ejecutando dnf check-update (exit code: $CHECK_EXIT)" >> "$LOG"
    PARCHES_APLICADOS=false
fi

# Limpieza de paquetes huerfanos
echo "" >> "$LOG"
echo ">>> Limpieza de paquetes no necesarios..." >> "$LOG"
dnf autoremove -y >> "$LOG" 2>&1

# Limpiar cache de dnf
echo "" >> "$LOG"
echo ">>> Limpiando cache de dnf..." >> "$LOG"
dnf clean all >> "$LOG" 2>&1

# Comprobar si necesita reinicio
if needs-restarting -r >> /dev/null 2>&1; then
    REBOOT_NEEDED=false
    echo "" >> "$LOG"
    echo "Reinicio: NO necesario." >> "$LOG"
else
    REBOOT_NEEDED=true
    echo "" >> "$LOG"
    echo "Reinicio: NECESARIO (hay kernel o servicios criticos actualizados)." >> "$LOG"
fi

# Resumen para el correo
echo "" >> "$LOG"
echo "=== RESUMEN ===" >> "$LOG"
echo "Host: $HOSTNAME" >> "$LOG"
echo "Fecha: $FECHA" >> "$LOG"
echo "Parches aplicados: $PARCHES_APLICADOS" >> "$LOG"
echo "Reinicio necesario: $REBOOT_NEEDED" >> "$LOG"

# Enviar correo con el resultado
ASUNTO="[Parcheo RH] $HOSTNAME - $FECHA"
cat "$LOG" | msmtp arachiriwoki@gmail.com -s "$ASUNTO" -- \
    || (echo "To: arachiriwoki@gmail.com
Subject: $ASUNTO

$(cat $LOG)" | msmtp arachiriwoki@gmail.com)

# Mostrar log por pantalla tambien
cat "$LOG"
rm -f "$LOG"
