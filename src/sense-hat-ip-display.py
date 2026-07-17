#!/usr/bin/env python3

import socket
import fcntl
import struct
import time
import signal
import sys
from sense_hat import SenseHat
import getpass


running = True


def main():
    sense = SenseHat()
    
    while running:
        ip = get_wlan0_ip()
        sense.show_message(ip)
        time.sleep(1)

    sense.clear()


def get_username():
    return getpass.getuser()


def get_wlan0_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Pack the interface name 'wlan0' into a 256-bit string buffer
        # 0x8915 is the SIOCGIFADDR constant to get interface address
        interface_bytes = struct.pack('256s', b'wlan0'[:15])
        ip_address = fcntl.ioctl(s.fileno(), 0x8915, interface_bytes)[20:24]
        return socket.inet_ntoa(ip_address)
    except OSError:
        return "offline"
    finally:
        s.close()


def display_output(sense, ip, username):
    sense.show_message(f'{username} {ip}')


def shutdown(signum, frame):
    global running
    running = False

signal.signal(signal.SIGTERM, shutdown)
signal.signal(signal.SIGINT, shutdown)


if __name__ == '__main__':
    main()




