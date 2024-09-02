#!/bin/bash

# Variablen
KL_NR="FIB21" 
DMZ_NET="192.168.$((21 + 40)).0/24" # KL_NR ist hier auf 21 basierend auf "FIB21"
SERVER_IP="192.168.$((21 + 40)).2"
GATEWAY="10.132.48.1"
HOSTNAME="Server"

# a. Hostname ändern
echo "Ändere den Hostnamen zu $HOSTNAME"
hostnamectl set-hostname $HOSTNAME
echo "127.0.1.1 $HOSTNAME" | tee -a /etc/hosts

# b. Netzwerk konfigurieren (L2-DMZ-Network)
echo "Konfiguriere Netzwerkkarte ens3 mit IP $SERVER_IP"
ip addr add $SERVER_IP dev ens3
ip link set ens3 up

# c. Schnittstellen aktivieren
echo "Aktiviere Schnittstellen"
ip link set ens3 up

# d. Konfiguration überprüfen
echo "Überprüfe Netzwerkkonfiguration..."
ip addr show ens3
ip route show

# e. Routing-Tabelle überprüfen
echo "Überprüfe Routing-Tabelle"
ip route show

# f. Internetzugriff testen
echo "Teste Internetzugriff..."
ping -c 4 google.com

# g. Konnektivität zum Router und SSH-Server testen
echo "Teste Konnektivität zum Router"
ping -c 4 $GATEWAY

echo "Teste SSH-Server auf dem Server"
apt-get install -y openssh-server
systemctl start ssh
systemctl enable ssh
systemctl status ssh

echo "Teste SSH-Server auf dem Router"
ssh -o BatchMode=yes -o ConnectTimeout=5 $GATEWAY exit
if [ $? -eq 0 ]; then
  echo "SSH-Verbindung zum Router erfolgreich"
else
  echo "SSH-Verbindung zum Router fehlgeschlagen"
fi

# h. IP-Einstellungen in Konfigurationsdatei eintragen
echo "Trage IP-Einstellungen in Konfigurationsdatei ein"
echo -e "auto ens3\niface ens3 inet static\naddress $SERVER_IP\nnetmask 255.255.255.0\ngateway $GATEWAY" | tee -a /etc/network/interfaces

# i. sudo Rechte einrichten
echo "Richte sudo Rechte ein"
apt-get install -y sudo

# j. Offene Ports auf Router und Server prüfen
echo "Prüfe offene Ports auf dem Server"
ss -tuln

echo "Prüfe offene Ports auf dem Router"
ssh $GATEWAY "ss -tuln"

# k. Dokumentation der Befehle und Tests
LOGFILE="/var/log/server_vm_config.log"
echo "Dokumentiere Befehle und Tests in $LOGFILE"
{
    echo "Hostname: $HOSTNAME"
    echo "Netzwerkkonfiguration:"
    ip addr show ens3
    echo "Routing-Tabelle:"
    ip route show
    echo "Internetverbindungstest:"
    ping -c 4 google.com
    echo "Konnektivitätstest zum Router:"
    ping -c 4 $GATEWAY
    echo "SSH-Server Status:"
    systemctl status ssh
    echo "Offene Ports:"
    ss -tuln
} | tee -a $LOGFILE

echo "Konfiguration abgeschlossen!"
