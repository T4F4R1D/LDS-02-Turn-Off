# TurtleBot3 Lidar Power Control (LDS-02, Raspberry Pi 4)

Keep a TurtleBot3's LDS-02 lidar completely powered off after the robot boots, and turn it on with one command over SSH.

## The problem

The LDS-02 (LD08) lidar's motor spins whenever it has power. Its driver ([`ld08_driver`](https://github.com/ROBOTIS-GIT/ld08_driver)) only reads data and has no command to stop the motor, so stopping or never launching the driver doesn't stop the spinning. The only way to stop it is to cut its power.

> The LDS-01 and LDS-03 are different: their drivers send a stop command when the driver shuts down. This repo is for the LDS-02.

## How it works

- The lidar is powered from the Pi's USB port through its adapter board.
- [`uhubctl`](https://github.com/mvp/uhubctl) switches the Pi's USB power off and on.
- The Pi 4 **cannot switch one port at a time**: all four ports go off together. That also disconnects the OpenCR, so USB power is only switched while bringup is **not** running.
- A startup service turns USB power off as soon as the lidar appears during boot.

## Files

| File | What it does |
|---|---|
| `lidar` | `sudo lidar off` cuts USB power; `sudo lidar on` restores it and waits for the lidar and OpenCR to reconnect. `off` refuses to run while bringup is active. |
| `lidar-off.service` | Runs `lidar off` automatically at every boot. |
| `install.sh` | Installs `uhubctl`, the command, and the service. |

## Requirements

- TurtleBot3 with an **LDS-02** lidar (`echo $LDS_MODEL` prints `LDS-02`)
- **Raspberry Pi 4** (`cat /proc/device-tree/model`)
- Internet access on the Pi to install `uhubctl`

## Install

1. Copy this repo onto the robot's Pi (clone it or `scp` the folder).
2. SSH in as the robot's normal user (not root), go to the folder and run:
   ```bash
   chmod +x install.sh
   sudo ./install.sh
   ```
3. Reboot to test: `sudo reboot`

### Optional: test before installing


sudo apt install -y uhubctl
sudo uhubctl -l 1-1 -a off && sudo uhubctl -l 2 -a off   # lidar should stop
sudo uhubctl -l 1-1 -a on  && sudo uhubctl -l 2 -a on    # lidar should restart
```
Your SSH connection stays up: on the Pi 4, Ethernet and Wi-Fi don't go through these USB ports.

## Daily use

```bash
ssh <user>@<robot-ip>
sudo lidar on
ros2 launch turtlebot3_bringup robot.launch.py

# when finished: Ctrl+C to stop bringup, then
sudo lidar off
```

## What to expect at boot

The Pi's firmware turns USB power on during startup, so the lidar **spins briefly at every boot** until the service switches it off. On our Pi 4 this took about **39 seconds** from power-on, down from 1 min 14 s when the service ran at the end of startup.

Eliminating that spin completely requires hardware: a relay or MOSFET on the lidar's USB 5V line, controlled by a Pi GPIO pin and open by default.

## Troubleshooting

- **Check the service ran:** `systemctl status lidar-off.service --no-pager` should show `USB power off: lidar stopped`.
- **Lidar spins again after the service ran:** run `sudo uhubctl` and check the port state. The `-r 10` repeat and the 3-second `sleep` in the service are there to prevent this.
- **`lidar off` says bringup is running:** stop bringup first. If something starts bringup automatically at boot, find it with `systemctl list-unit-files | grep -i turtle` and `crontab -l`.
- **See what slows boot:** `systemd-analyze` and `systemd-analyze blame | head -10`.

## Side effects

- **Every** USB device on the Pi (camera, keyboard, etc.) stays off until `sudo lidar on`.
- On a shared lab robot, let others know the lidar and OpenCR start powered off.

## Uninstall

```bash
sudo systemctl disable lidar-off.service
sudo rm /etc/systemd/system/lidar-off.service /usr/local/bin/lidar
sudo systemctl daemon-reload
```

## Tested on

- TurtleBot3 with LDS-02 lidar
- Raspberry Pi 4 Model B Rev 1.5
