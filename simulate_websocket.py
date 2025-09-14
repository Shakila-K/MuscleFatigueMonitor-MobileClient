import asyncio
import math
import websockets

# Global state
sending = False  # Start/stop flag
clients = set()  # Track connected clients

async def send_sine():
    """Background task to send sine wave values to clients"""
    global sending
    t = 0
    while True:
        if clients:
            if sending:
                # Generate sine wave values in 0–4096 range (like ESP32 ADC)
                value = int(2048 + 2047 * math.sin(t / 10))
                data = f'{{"value":"{value}"}}'
                t += 1
            else:
                # When stopped, send {"value":"-"}
                data = '{"value":"-"}'

            # Send to all connected clients
            await asyncio.gather(*[client.send(data) for client in clients])

        await asyncio.sleep(0.05)  # ~50 ms update interval (like ESP32)

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
            print("Started sending sine values...")
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
        await asyncio.gather(send_sine(), console_input())

if __name__ == "__main__":
    asyncio.run(main())
