import socketio
from aiohttp import web
from pynput.mouse import Controller, Button

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
    # print(f"Moved: dx={dx}, dy={dy}")


# Event to handle left click
@sio.event
async def LEFT_CLICK(sid, data=None):  # Make data optional
    mouse.click(Button.left)
    print("Left click")

@sio.event
async def RIGHT_CLICK(sid, data=None):  # Make data optional
    mouse.click(Button.right)
    print("Right click")


# Run the app
if __name__ == "__main__":
    web.run_app(app, host='0.0.0.0', port=5000)
