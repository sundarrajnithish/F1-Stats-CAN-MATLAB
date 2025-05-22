import socket
import struct
import time
import random

# UDP settings
UDP_IP = "127.0.0.1"  # localhost
UDP_PORT = 20001
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

print(f"Starting test UDP sender on {UDP_IP}:{UDP_PORT}")
print("Sending simulated F1 telemetry data for 30 seconds...")
print("Make sure F1_Telemetry_UDP.m is running in MATLAB")

# Continuously send data for 30 seconds
start_time = time.time()
driver = 44  # Start with Lewis Hamilton's number

while time.time() - start_time < 30:
    # Generate random telemetry data
    speed = random.randint(80, 320)
    throttle = random.randint(0, 100)
    brake = random.randint(0, 100)
    gear = random.randint(1, 8)
    rpm = random.randint(5000, 13000)
    
    # Format data for UDP
    # Network byte order (big-endian): speed, throttle, brake, gear, rpm, driver, unused
    data = struct.pack('!BBBBHBxB', speed, throttle, brake, gear, rpm, driver, 0)
    sock.sendto(data, (UDP_IP, UDP_PORT))
    
    print(f"Sent: Speed={speed}, Throttle={throttle}, Brake={brake}, Gear={gear}, RPM={rpm}, Driver={driver}")
    time.sleep(0.1)  # 10 Hz update rate
    
    # Change driver occasionally
    if random.random() < 0.02:  # ~2% chance each update
        driver_options = [1, 4, 11, 16, 44, 55, 63, 81]
        driver = random.choice(driver_options)
        print(f"\n--- Switching to driver #{driver} ---\n")

print("Test complete. UDP data transmission stopped.")
