import os
import fastf1
import can
import time

# List of driver numbers
drivers = ['55', '1', '16', '63', '11', '23', '81', '44', '4', '14',
           '22', '40', '27', '77', '2', '24', '10', '31', '20', '18']

# Create cache directory
os.makedirs('f1_cache', exist_ok=True)
fastf1.Cache.enable_cache('f1_cache')

# Load F1 session
session = fastf1.get_session(2023, 'Monza', 'Q')
session.load()

# Setup CAN bus on Virtual Channel 1
bus = can.Bus(interface='vector', channel='0', app_name='CANalyzer', bitrate=500000)

print("Starting telemetry streaming loop...")

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

            rpm_high = (rpm >> 8) & 0xFF
            rpm_low = rpm & 0xFF

            data = [speed, throttle, brake, gear & 0xFF, rpm_high, rpm_low, 0, 0]
            msg = can.Message(arbitration_id=0x123, data=data, is_extended_id=False)
            bus.send(msg)
            print(f"Sent (Driver {driver}): Speed={speed}, Throttle={throttle}, Brake={brake}, Gear={gear}, RPM={rpm}")
            time.sleep(0.1)
        except Exception as e:
            print(f"Error sending data for driver {driver} at index {i}: {e}")

    print(f"--- Finished streaming for driver {driver}, waiting before next driver ---")
    time.sleep(2)  # Distinct gap between drivers

bus.shutdown()
print("All telemetry data sent.")
