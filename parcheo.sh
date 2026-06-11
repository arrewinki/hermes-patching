#!/bin/bash
# parcheo.sh - Parcheo automatico de la VM Hermes
# Cron job: todos los jueves a las 14:00
# Notificacion: arachiriwoki@gmail.com

LOG=$(mktemp)
RECIPIENT="arachiriwoki@gmail.com"
HOSTNAME=$(hostname)
DATE=$(date '+%Y-%m-%d %H:%M')

echo "=== Parcheo VM $HOSTNAME - $DATE ===" >> $LOG
echo "" >> $LOG

# Actualizar lista de paquetes
echo "[1/3] apt update..." >> $LOG
apt update -qq 2>&1 >> $LOG
echo "" >> $LOG

# Aplicar parches
echo "[2/3] apt upgrade..." >> $LOG
UPGRADE_OUTPUT=$(apt upgrade -y 2>&1)
echo "$UPGRADE_OUTPUT" >> $LOG
echo "" >> $LOG

# Limpiar paquetes viejos
echo "[3/3] apt autoremove..." >> $LOG
AUTOREMOVE_OUTPUT=$(apt autoremove -y 2>&1)
echo "$AUTOREMOVE_OUTPUT" >> $LOG
echo "" >> $LOG

# Comprobar si hay paquetes actualizados
UPGRADED=$(echo "$UPGRADE_OUTPUT" | grep -E "^[0-9]+ upgraded" | awk '{print $1}')
if [ -z "$UPGRADED" ]; then UPGRADED=0; fi

# Comprobar si necesita reinicio
REBOOT_NEEDED=""
if [ -f /var/run/reboot-required ]; then
    REBOOT_NEEDED="ATENCION: Se requiere reinicio para aplicar los cambios."
    echo "" >> $LOG
    echo "$REBOOT_NEEDED" >> $LOG
fi

# Construir asunto del correo
if [ "$UPGRADED" -gt 0 ]; then
    SUBJECT="[Hermes Patching] $HOSTNAME - $UPGRADED paquetes actualizados"
else
    SUBJECT="[Hermes Patching] $HOSTNAME - Sin cambios pendientes"
fi

# Enviar correo
cat $LOG | msmtp $RECIPIENT -a default --subject="$SUBJECT" 2>/dev/null || \
    echo -e "Subject: $SUBJECT\n\n$(cat $LOG)" | msmtp $RECIPIENT

# Limpiar
rm -f $LOG

echo "Parcheo completado. Correo enviado a $RECIPIENT"