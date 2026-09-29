#!/bin/bash
# Installs the lidar on/off command and the boot service on the TurtleBot3's Raspberry Pi.
# Run from this folder: sudo ./install.sh
set -e

if [ "$EUID" -ne 0 ]; then
  echo "Run with sudo: sudo ./install.sh"
  exit 1
fi

cd "$(dirname "$0")"

echo "Installing uhubctl..."
apt-get install -y uhubctl

echo "Installing lidar command..."
install -m 755 lidar /usr/local/bin/lidar

echo "Installing boot service..."
install -m 644 lidar-off.service /etc/systemd/system/lidar-off.service
systemctl daemon-reload
systemctl enable lidar-off.service

echo
echo "Done. Reboot to test: sudo reboot"
echo "Afterwards: sudo lidar on  ->  ros2 launch turtlebot3_bringup robot.launch.py"
