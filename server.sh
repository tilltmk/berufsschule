#!/bin/bash

# Variablen
KL_NR="21" # Aus FIB21 -> 21 extrahiert
DMZ_NET="192.168.$((KL_NR + 40)).0/24"
SERVER_IP="192.168.$((KL_NR + 40)).2"
GATEWAY="10.132.48.1"
HOSTNAME="server-tomczak"
NIC_NAME="02:01:04:52:00:03" # Die MAC-Adresse der NIC im Screenshot

# a. Hostname ändern
echo "Ändere den Hostnamen zu $HOSTNAME"
sudo hostnamectl set-hostname $HOSTNAME
echo "127.0.1.1 $HOSTNAME" | sudo tee -a /etc/hosts

# b. Netzwerk konfigurieren (L2-DMZ-Network)
echo "Konfiguriere Netzwerkkarte mit IP $SERVER_IP"
sudo ip addr add $SERVER_IP/24 dev $NIC_NAME
sudo ip link set $NIC_NAME up

# c. Schnittstellen aktivieren
echo "Aktiviere Schnittstellen"
sudo ip link set $NIC_NAME up

# d. Konfiguration überprüfen
echo "Überprüfe Netzwerkkonfiguration..."
ip addr show $NIC_NAME
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
sudo apt-get install -y openssh-server
sudo systemctl start ssh
sudo systemctl enable ssh
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
echo -e "auto $NIC_NAME\niface $NIC_NAME inet static\naddress $SERVER_IP\nnetmask 255.255.255.0\ngateway $GATEWAY" | sudo tee -a /etc/network/interfaces

# i. sudo Rechte einrichten
echo "Richte sudo Rechte ein"
sudo apt-get install -y sudo

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
    ip addr show $NIC_NAME
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
} | sudo tee -a $LOGFILE

echo "Konfiguration abgeschlossen!"
