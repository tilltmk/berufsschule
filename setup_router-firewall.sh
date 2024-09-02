#!/bin/bash

# Variables
KL_NR=FIB21 # Ersetzen Sie dies durch Ihre KL-Nr
LAN_NET="192.168.$KL_NR.0/24"
DMZ_NET="192.168.$((KL_NR + 40)).0/24"
GATEWAY="10.132.48.1"

# Funktion: Netzwerkschnittstellen konfigurieren
configure_network() {
    local interface=$1
    local ip_address=$2
    local network=$3

    echo "Konfiguriere $interface mit IP $ip_address im Netzwerk $network"
    sudo ip addr add $ip_address dev $interface
    sudo ip link set $interface up
}

# a. Konfiguration für Network 2 (L2-LAN-Network)
configure_network eth1 192.168.$KL_NR.2 $LAN_NET

# e. Konfiguration für Network 3 (L2-DMZ-Network)
configure_network eth2 192.168.$((KL_NR + 40)).2 $DMZ_NET

# f. Schnittstellen aktivieren
sudo ip link set eth1 up
sudo ip link set eth2 up

# g. Default Route hinzufügen
sudo ip route add default via $GATEWAY

# h. Internetverbindung prüfen
echo "Prüfe Internetverbindung..."
ping -c 4 google.com

# i. Überprüfen, ob die Konfiguration korrekt ist
echo "Überprüfe Netzwerkkonfiguration..."
ip addr show eth1
ip addr show eth2
ip route show

# j. IP-Einstellungen in Konfigurationsdatei eintragen (hier für Ubuntu/Debian, anpassen für andere Systeme)
echo -e "auto eth1\niface eth1 inet static\naddress 192.168.$KL_NR.2\nnetmask 255.255.255.0" | sudo tee -a /etc/network/interfaces
echo -e "auto eth2\niface eth2 inet static\naddress 192.168.$((KL_NR + 40)).2\nnetmask 255.255.255.0" | sudo tee -a /etc/network/interfaces
echo "gateway $GATEWAY" | sudo tee -a /etc/network/interfaces

# k. Routing-Tabelle überprüfen
echo "Überprüfe Routing-Tabelle..."
ip route show

# l. sudo Rechte aktivieren
echo "Aktiviere sudo für den Benutzer..."
sudo apt-get install -y sudo

# m. Benutzer über Verwendung informieren
echo "Benutzer informieren..."
echo "Verwendung von sudo: sudo <Befehl> um als root auszuführen."

# n. Dokumentieren der IP-Adressen und Einstellungen
echo "Dokumentiere IP-Adressen und Einstellungen..."
sudo ip addr show > /var/log/network_config.log
sudo ip route show >> /var/log/network_config.log

echo "Konfiguration abgeschlossen!"
