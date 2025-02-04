import socketio
from aiohttp import web
from pynput.mouse import Controller, Button
import asyncio
import signal
import sys

# Create a Socket.IO server instance
sio = socketio.AsyncServer(async_mode='aiohttp')
mouse = Controller()

# Create a web app and attach the Socket.IO server
app = web.Application()
sio.attach(app)

# Event for client connection
@sio.event
async def connect(sid, environ):
    print(f"Client connected: {sid}")

# Event for client disconnection
@sio.event
async def disconnect(sid):
    print(f"Client disconnected: {sid}")

# Event to handle mouse movement
@sio.event
async def MOVE(sid, data):
    scale_factor = 3  # Adjust this value to control speed (e.g., 2, 3, 5)
    dx = data.get('dx', 0) * scale_factor
    dy = data.get('dy', 0) * scale_factor
    mouse.move(dx, dy)

# Event to handle left click
@sio.event
async def LEFT_CLICK(sid, data=None):
    mouse.click(Button.left)
    print("Left click")

# Event to handle right click
@sio.event
async def RIGHT_CLICK(sid, data=None):
    mouse.click(Button.right)
    print("Right click")

# Function to clean up connections when shutting down
async def cleanup(app):
    print("Cleaning up resources...")
    # Disconnect clients gracefully
    await sio.disconnect_all_clients()
    print("All clients disconnected.")
    # Optionally, you can add more cleanup logic, like stopping the mouse controller
    mouse.stop()  # If you want to stop the mouse controller


# Register cleanup function on shutdown
app.on_cleanup.append(cleanup)

# Graceful shutdown on keyboard interrupt or process termination
def shutdown_handler(signal, frame):
    print("\nServer is shutting down...")
    asyncio.ensure_future(app.cleanup())  # Cleanup the app before shutdown
    sys.exit(0)

# Register signal handlers for graceful shutdown
signal.signal(signal.SIGINT, shutdown_handler)
signal.signal(signal.SIGTERM, shutdown_handler)

# Run the app with proper error handling for graceful shutdown
if __name__ == "__main__":
    try:
        print("Starting server...")
        web.run_app(app, host='0.0.0.0', port=5000)
    except KeyboardInterrupt:
        print("\nServer stopped by user.")
