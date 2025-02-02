import 'package:flutter/material.dart';
import 'package:mouse_app/presentation/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(MouseApp());
}

class MouseApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MouseControlScreen(),
    );
  }
}

class MouseControlScreen extends StatefulWidget {
  @override
  _MouseControlScreenState createState() => _MouseControlScreenState();
}

class _MouseControlScreenState extends State<MouseControlScreen> {
  late IO.Socket socket;
  double speedMultiplier = 1.0; // Default speed multiplier
  String ipAddress = ''; // Store the IP address
  String _connectionStatusMessage = "Connecting...";

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Load saved settings (speed and IP address)
  }

  // Load the saved settings (speed and IP address)
  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      speedMultiplier = prefs.getDouble('mouse_speed') ?? 1.0;
      ipAddress = prefs.getString('pc_ip') ?? '192.168.100.13'; // Default IP
    });
    connectToServer(); // Connect to the server using the saved IP address
  }

  // Connect to the server using the saved IP address
  void connectToServer() {
    // Disconnect any previous connection.
    // if (socket == null) {
    //   socket.disconnect();
    // }

    socket = IO.io(
      'http://$ipAddress:5000', // Use the saved IP address
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    // Listen for connection events.
    socket.onConnect((_) {
      setState(() {
        _connectionStatusMessage = "Connected to server at $ipAddress";
      });
    });

    socket.onDisconnect((_) {
      setState(() {
        _connectionStatusMessage = "Disconnected from server";
      });
    });

    socket.onConnectError((error) {
      setState(() {
        _connectionStatusMessage = "Connection error: $error";
      });
    });
  }

  // Send events to the server
  void sendEvent(String event, dynamic data) {
    socket.emit(event, data);
  }

  // Update the speed multiplier and reload the speed
  void setSpeed(double speed) {
    setState(() {
      speedMultiplier = speed;
    });
    _saveSettings();
  }

  // Save the updated settings to SharedPreferences
  void _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble('mouse_speed', speedMultiplier);
    prefs.setString('pc_ip', ipAddress); // Save the IP address
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cursor Control',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
            ),
            onPressed: () {
              // Navigate to the settings screen and pass the callbacks.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Settings(
                    onSpeedChanged: setSpeed,
                    onIpChanged: (newIp) {
                      setState(() {
                        ipAddress = newIp; // Update IP address.
                      });
                      _saveSettings(); // Save updated IP address.
                      connectToServer(); // Reconnect using the new IP address.
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Gesture Detector for mouse control events.
          GestureDetector(
            onPanUpdate: (details) {
              double dx = details.delta.dx * speedMultiplier;
              double dy = details.delta.dy * speedMultiplier;
              sendEvent('MOVE', {'dx': dx, 'dy': dy});
            },
            onTap: () {
              sendEvent('LEFT_CLICK', null);
            },
            onDoubleTap: () {
              sendEvent('RIGHT_CLICK', null);
            },
            child: Container(
              color: Colors.white,
              child: Center(
                  //
                  ),
            ),
          ),
          // Optionally, you can add a connection status banner at the top.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color:
                  _connectionStatusMessage.toLowerCase().contains("connected")
                      ? Colors.greenAccent
                      : Colors.redAccent,
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Text(
                  _connectionStatusMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }
}
