import os
import socket
import fastf1
import time
import struct

# UDP setup
UDP_IP = "127.0.0.1"  # localhost
UDP_PORT = 20001
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

print(f"Starting F1 telemetry UDP server on {UDP_IP}:{UDP_PORT}")

# List of driver numbers
drivers = ['55', '1', '16', '63', '11', '23', '81', '44', '4', '14',
           '22', '40', '27', '77', '2', '24', '10', '31', '20', '18']

# Cache directory
os.makedirs('f1_cache', exist_ok=True)
fastf1.Cache.enable_cache('f1_cache')

# Load F1 session
print("Loading F1 session data (Canada 2023)...")
session = fastf1.get_session(2023, 'Canada', 'R')
session.load()
print("Session loaded successfully!")

print("\nStarting telemetry streaming loop...")

for driver in drivers:
    print(f"\n--- Streaming data for driver {driver} ---")
    try:
        laps = session.laps.pick_driver(driver)
        fastest_lap = laps.pick_fastest()
        tel = fastest_lap.get_car_data().add_distance()
    except Exception as e:
        print(f"Could not load data for driver {driver}: {e}")
        continue

    for i in range(0, len(tel), 10):  # Reduce frequency to ~10 Hz
        try:
            speed = int(tel['Speed'].iloc[i])              # km/h
            throttle = int(tel['Throttle'].iloc[i])        # 0–100
            brake = int(tel['Brake'].iloc[i] * 100)        # 0–100 from 0.0–1.0

            # Bound to 8-bit range
            speed = max(0, min(speed, 255))
            throttle = max(0, min(throttle, 100))
            brake = max(0, min(brake, 100))

            gear = int(tel['Gear'].iloc[i]) if 'Gear' in tel else 0
            rpm = int(tel['RPM'].iloc[i]) if 'RPM' in tel else 0

            # Format data for UDP
            data = struct.pack('!BBBBHBxB', speed, throttle, brake, gear, rpm, int(driver), 0)
            sock.sendto(data, (UDP_IP, UDP_PORT))
            
            print(f"Sent (Driver {driver}): Speed={speed}, Throttle={throttle}, Brake={brake}, Gear={gear}, RPM={rpm}")
            time.sleep(0.1)
        except Exception as e:
            print(f"Error sending data for driver {driver} at index {i}: {e}")

    print(f"--- Finished streaming for driver {driver}, waiting before next driver ---")
    time.sleep(2)  # Distinct gap between drivers

print("All telemetry data sent.")
