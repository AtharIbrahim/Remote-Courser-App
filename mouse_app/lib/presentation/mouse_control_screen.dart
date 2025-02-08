import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mouse_app/presentation/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class MouseControlScreen extends StatefulWidget {
  @override
  _MouseControlScreenState createState() => _MouseControlScreenState();
}

class _MouseControlScreenState extends State<MouseControlScreen>
    with TickerProviderStateMixin {
  // Vaiables:
  late IO.Socket socket;
  double speedMultiplier = 1.0;
  String ipAddress = '';
  String _connectionStatusMessage = "Connecting...";

  // On Initial
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load the saved settings (speed and IP address)
  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      speedMultiplier = prefs.getDouble('mouse_speed') ?? 1.0;
      ipAddress = prefs.getString('pc_ip') ?? '192.168.100.13'; // Default IP
    });
    // call the function to connect to the server
    connectToServer();
  }

  // Connect to the server using the saved IP address
  void connectToServer() {
    socket = IO.io(
      'http://$ipAddress:5000', // Use the saved IP address
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    // On Connection
    socket.onConnect((_) {
      setState(() {
        _connectionStatusMessage = "Connected to server at $ipAddress";
      });
    });

    // On Disconnection
    socket.onDisconnect((_) {
      setState(() {
        _connectionStatusMessage = "Disconnected from server";
      });
    });

    // On Error
    socket.onConnectError((error) {
      setState(() {
        _connectionStatusMessage = "Connection error";
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
    // Call the function to reload the speed
    _saveSettings();
  }

  // Save the updated settings to SharedPreferences
  void _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble('mouse_speed', speedMultiplier);
    prefs.setString('pc_ip', ipAddress); // Save the IP address
  }

  // Main UI Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Toolbar
      appBar: AppBar(
        title: const Text(
          'Cursor Control',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1C1E33),
                Color.fromARGB(255, 47, 49, 78),
              ],
            ),
          ),
        ),
        // Toolbar Actions
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
            ),
            onPressed: () {
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

      // Body
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 46, 8, 8),
              child: Container(
                color: Theme.of(context).colorScheme.background,
                // color: Colors.transparent,
                child: Center(
                    //
                    ),
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

  // On Dispose
  @override
  void dispose() {
    socket.disconnect();
    _animationController.dispose();
    super.dispose();
  }
}
