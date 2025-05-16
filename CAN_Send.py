import os
import fastf1
import can
import time

# Create cache directory
os.makedirs('f1_cache', exist_ok=True)
fastf1.Cache.enable_cache('f1_cache')

# Load F1 session
session = fastf1.get_session(2023, 'Monza', 'Q')
session.load()
laps = session.laps.pick_driver('HAM')
fastest_lap = laps.pick_fastest()
tel = fastest_lap.get_car_data().add_distance()

# Setup CAN bus on Virtual Channel 1
bus = can.Bus(interface='vector', channel='0', app_name='CANalyzer', bitrate=500000)

print("Starting to stream telemetry over CAN...")
for i in range(0, len(tel), 10):  # Reduce frequency to 10 Hz
    speed = int(tel['Speed'].iloc[i])              # km/h
    throttle = int(tel['Throttle'].iloc[i])        # 0–100
    brake = int(tel['Brake'].iloc[i] * 100)        # 0–100 from 0.0–1.0

    # Bound to 8-bit range
    speed = max(0, min(speed, 255))
    throttle = max(0, min(throttle, 100))
    brake = max(0, min(brake, 100))

    # Use remaining bytes for other telemetry (e.g., gear, RPM, etc.)
    gear = int(tel['Gear'].iloc[i]) if 'Gear' in tel else 0
    rpm = int(tel['RPM'].iloc[i]) if 'RPM' in tel else 0

    rpm_high = (rpm >> 8) & 0xFF
    rpm_low = rpm & 0xFF

    data = [speed, throttle, brake, gear & 0xFF, rpm_high, rpm_low, 0, 0]
    msg = can.Message(arbitration_id=0x123, data=data, is_extended_id=False)
    bus.send(msg)
    print(f"Sent: Speed={speed}, Throttle={throttle}, Brake={brake}, Gear={gear}, RPM={rpm}")
    time.sleep(0.1)

bus.shutdown()
print("Finished sending telemetry.")
