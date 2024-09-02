#!/bin/bash

# Variablen
KL_NR="21"  # Nur die Nummer, basierend auf FIB21
DMZ_NET="192.168.$((KL_NR + 40)).0/24"
SERVER_IP="192.168.$((KL_NR + 40)).2"
GATEWAY="10.132.48.1"
HOSTNAME="Server"

# a. Hostname ändern
echo "Ändere den Hostnamen zu $HOSTNAME"
hostnamectl set-hostname $HOSTNAME
echo "127.0.1.1 $HOSTNAME" >> /etc/hosts

# b. Netzwerk konfigurieren (L2-DMZ-Network)
echo "Konfiguriere Netzwerkkarte ens3 mit IP $SERVER_IP"
ip addr add $SERVER_IP/24 dev ens3
ip link set ens3 up

# c. Schnittstellen aktivieren (falls nicht schon aktiviert)
echo "Aktiviere Schnittstelle ens3"
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
ping -c 4 8.8.8.8  # Ping an einen öffentlichen DNS-Server

# g. Konnektivität zum Router und SSH-Server testen
echo "Teste Konnektivität zum Router"
ping -c 4 $GATEWAY

echo "Teste SSH-Server auf dem Server"
apt-get update
apt-get install -y openssh-server
systemctl start ssh
systemctl enable ssh
systemctl status ssh

echo "Teste SSH-Verbindung zum Router"
ssh -o BatchMode=yes -o ConnectTimeout=5 $GATEWAY exit
if [ $? -eq 0 ]; then
  echo "SSH-Verbindung zum Router erfolgreich"
else
  echo "SSH-Verbindung zum Router fehlgeschlagen"
fi

# h. IP-Einstellungen in Konfigurationsdatei eintragen
echo "Trage IP-Einstellungen in Konfigurationsdatei ein"
echo -e "auto ens3\niface ens3 inet static\naddress $SERVER_IP\nnetmask 255.255.255.0\ngateway $GATEWAY" >> /etc/network/interfaces

# i. sudo Rechte einrichten (falls benötigt)
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
    ping -c 4 8.8.8.8
    echo "Konnektivitätstest zum Router:"
    ping -c 4 $GATEWAY
    echo "SSH-Server Status:"
    systemctl status ssh
    echo "Offene Ports:"
    ss -tuln
} >> $LOGFILE

echo "Konfiguration abgeschlossen!"
