import asyncio
import math
import random
import websockets

# Global state
sending = False  # Start/stop flag
clients = set()  # Track connected clients

def generate_emg_value(t):
    """
    Generate a simulated EMG-like waveform:
    - Low baseline noise (300–500)
    - Occasional sharp random spikes (up to 4095)
    """
    # Baseline noise (minor random jitter)
    baseline = random.randint(300, 500)

    # Random chance to trigger a spike
    if random.random() < 0.05:  # ~5% chance per sample (~1–2 Hz bursts)
        # Simulate a spike duration (5–30 samples)
        duration = random.randint(5, 30)
        # Randomly decaying spike amplitude
        spike_amplitude = random.uniform(3500, 4095)
        # Generate a smooth decaying spike shape
        spike_value = baseline + int(spike_amplitude * math.exp(-0.2 * (t % duration)))
        value = min(4095, spike_value)
    else:
        # Just baseline noise
        value = baseline + random.randint(-10, 10)

    # Clamp to valid range
    value = max(0, min(4095, int(value)))

    return value

async def send_emg():
    """Background task to send EMG-like values to clients"""
    global sending
    t = 0
    while True:
        if clients:
            if sending:
                value = generate_emg_value(t)
                data = f'{{"value":"{value}"}}'
                t += 1
            else:
                data = '{"value":"-"}'

            # Send to all connected clients
            await asyncio.gather(*[client.send(data) for client in clients])

        await asyncio.sleep(0.02)  # 50 Hz sampling rate (~20ms interval)

async def handler(websocket):
    """Handle new client connection"""
    global clients
    clients.add(websocket)
    print(f"Client connected: {websocket.remote_address}")
    try:
        async for message in websocket:
            print(f"Received from client: {message}")
    except websockets.ConnectionClosed:
        print(f"Client disconnected: {websocket.remote_address}")
    finally:
        clients.remove(websocket)

async def console_input():
    """Read commands from console"""
    global sending
    loop = asyncio.get_event_loop()
    while True:
        cmd = await loop.run_in_executor(None, input, "Enter command (start/stop/exit): ")
        if cmd.lower() == "start":
            sending = True
            print("Started sending EMG-like signal...")
        elif cmd.lower() == "stop":
            sending = False
            print("Stopped sending, now sending '-' instead.")
        elif cmd.lower() == "exit":
            print("Exiting server...")
            for client in list(clients):
                await client.close()
            asyncio.get_event_loop().stop()
            break

async def main():
    async with websockets.serve(handler, "0.0.0.0", 81):
        print("WebSocket server started on ws://localhost:81")
        await asyncio.gather(send_emg(), console_input())

if __name__ == "__main__":
    asyncio.run(main())
