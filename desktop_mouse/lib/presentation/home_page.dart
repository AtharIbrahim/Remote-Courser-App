import 'dart:io';
import 'package:desktop_mouse/concepts/fetch_ip_add.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Vaiables:
  String _pythonStatus = "Not started";
  String _serverStatus = "Not running";
  String _phoneConnection = "Not connected";
  final String _connectionPort = "5000";
  final List<String> _logs = [];
  String _ipAddress = "Fetching IP...";
  bool _showQrCode = false;
  Process? _pythonProcess;
  IO.Socket? _socket;

  // On Initial
  @override
  void initState() {
    super.initState();
    _initPython();
    _fetchIpAddress();
    _connectToSocket();
  }

  // Fetch Ip Address
  Future<void> _fetchIpAddress() async {
    String ipAddress = await FetchIpAddress.getIp();
    setState(() {
      _ipAddress = ipAddress;
    });
  }

  // Connect To Socket
  void _connectToSocket() {
    _socket = IO.io('http://$_ipAddress:$_connectionPort', <String, dynamic>{
      'transports': ['websocket'],
    });

    _socket?.on('mouse_move', (data) {
      setState(() {
        _logs.add("Mouse moved to: ${data['x']}, ${data['y']}");
      });
    });

    _socket?.on('mouse_click', (data) {
      setState(() {
        _logs.add("Mouse clicked at: ${data['x']}, ${data['y']}");
      });
    });

    _socket?.on('mouse_scroll', (data) {
      setState(() {
        _logs.add("Mouse scrolled at: ${data['x']}, ${data['y']}");
      });
    });

    _socket?.onConnect((_) {
      setState(() {
        _phoneConnection = "Connected";
      });
    });

    _socket?.onDisconnect((_) {
      setState(() {
        _phoneConnection = "Not connected";
      });
    });
  }

  // Run Python Script
  // Like we run python in cmd            Also we need packages of py if available then run, otherwise import those packages!
  // C:\> python script.py
  Future<void> _initPython() async {
    final pythonCmd = 'python';
    final pythonScript = 'server.py';
    final requiredPackages = ['python-socketio', 'aiohttp', 'pynput'];

    bool pythonAvailable = await _isCommandAvailable(pythonCmd, ['--version']);
    if (!pythonAvailable) {
      setState(() {
        _pythonStatus = "Python not available";
        _logs.add("Error: Python is not installed or not available in PATH.");
      });
      return;
    }
    setState(() {
      _pythonStatus = "Python available";
      _logs.add("Python is available.");
    });

    // Import Packages Also
    for (final pkg in requiredPackages) {
      bool installed = await _checkPythonPackage(pythonCmd, pkg);
      if (!installed) {
        setState(() {
          _logs.add("Package \"$pkg\" not found. Installing...");
        });
        bool success = await _installPythonPackage(pythonCmd, pkg);
        if (!success) {
          setState(() {
            _logs.add("Error: Failed to install package \"$pkg\".");
          });
          return;
        } else {
          setState(() {
            _logs.add("Installed package \"$pkg\".");
          });
        }
      } else {
        setState(() {
          _logs.add("Package \"$pkg\" is installed.");
        });
      }
    }

    setState(() {
      _logs.add("Starting Python script: $pythonScript");
    });

    // Finally Run py
    try {
      _pythonProcess = await Process.start(
        pythonCmd,
        [pythonScript],
        runInShell: true,
      );
      setState(() {
        _serverStatus = "Running";
      });
    } catch (e) {
      setState(() {
        _logs.add("Error: Failed to start Python process: $e");
        _serverStatus = "Failed to start";
      });
    }
  }

  // Get Run Result
  Future<bool> _isCommandAvailable(String cmd, List<String> args) async {
    try {
      final result = await Process.run(cmd, args, runInShell: true);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  // Function to check py import available in system or not!
  Future<bool> _checkPythonPackage(String pythonCmd, String package) async {
    try {
      final result = await Process.run(
        pythonCmd,
        ['-m', 'pip', 'show', package],
        runInShell: true,
      );
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  // if packages not import already in system then, intsall those in device!
  Future<bool> _installPythonPackage(String pythonCmd, String package) async {
    try {
      final result = await Process.run(
        pythonCmd,
        ['-m', 'pip', 'install', package],
        runInShell: true,
      );
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  // Function to stop py server
  void _stopPythonServer() async {
    try {
      if (_pythonProcess != null) {
        final result = await Process.run(
            'taskkill', ['/F', '/IM', 'python.exe'],
            runInShell: true);
        print("Taskkill result: ${result.stdout}");
        setState(() {
          _serverStatus = "Stopped";
          _logs.add("Python server stopped.");
        });
      }
    } catch (e) {
      setState(() {
        _logs.add("Error stopping Python server: $e");
      });
    }

    // Close WebSocket if it's still open
    if (_socket != null) {
      try {
        if (_socket!.connected) {
          await _socket!.close();
          setState(() {
            _logs.add("WebSocket connection closed.");
          });
        } else {
          setState(() {
            _logs.add("WebSocket was already closed.");
          });
        }
      } catch (e) {
        setState(() {
          _logs.add("Error closing WebSocket: $e");
        });
      }
    } else {
      setState(() {
        _logs.add("No WebSocket to close.");
      });
    }
  }

  // Function to restart py server
  void _restartPythonServer() async {
    _initPython();
    _fetchIpAddress();
    _connectToSocket();
  }

  // On Dispose
  @override
  void dispose() {
    _stopPythonServer();
    _socket?.disconnect();
    super.dispose();
  }

  // Main UI Build
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      // Toolbar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1C1E33),
                Color(0xFF1C1E33),
              ],
            ),
          ),
        ),
        title: Text(widget.title),
        // Toolbar Actions
        actions: [
          IconButton(
            icon:
                Icon(_showQrCode ? Icons.qr_code_2 : Icons.qr_code_2_outlined),
            onPressed: () {
              setState(() {
                _showQrCode = !_showQrCode; // Toggle QR code visibility
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined), // Stop server button
            // Call py server stop function
            onPressed: () {
              _stopPythonServer();
            },
          ),
          IconButton(
              icon: const Icon(Icons.restart_alt), // Restart server button
              // Call py server restart function
              onPressed: () {
                _restartPythonServer();
              }),
        ],
      ),

      // Body
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1C1E33),
              Color.fromARGB(255, 47, 49, 78),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_showQrCode) // Show QR code if toggled
                  Column(
                    children: [
                      QrImageView(
                        data:
                            "http://$_ipAddress:$_connectionPort", // QR code data (by running the get_ip.py script)
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Scan to connect",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                // Text(
                //   widget.title,
                //   style: Theme.of(context).textTheme.titleLarge?.copyWith(
                //         color: Colors.white,
                //         letterSpacing: 1.2,
                //       ),
                // ),
                const SizedBox(height: 20),
                // Status cards.
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    // For Python Status
                    _buildStatusCard("Python Status", _pythonStatus,
                        Colors.deepPurpleAccent, screenWidth),
                    // For Connection Status
                    _buildStatusCard("Server Status", _serverStatus,
                        Colors.greenAccent, screenWidth),
                    // For Connection Port #
                    _buildStatusCard("Connection Port", _connectionPort,
                        Colors.orangeAccent, screenWidth),
                    // For IP Address #
                    _buildStatusCard("Phone Connection", _phoneConnection,
                        Colors.lightBlueAccent, screenWidth),
                  ],
                ),
                const SizedBox(height: 20),
                // Log Box
                Text(
                  "Logs & Errors",
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 10),
                // Log Box Cont.....
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _logs.isEmpty
                        ? const Center(
                            child: Text("No logs yet...",
                                style: TextStyle(color: Colors.white54)))
                        : ListView.builder(
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              return Text(
                                _logs[index],
                                style: const TextStyle(color: Colors.white70),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a card widget for a status item.
  Widget _buildStatusCard(
      String title, String value, Color accentColor, double screenWidth) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.black.withOpacity(0.2),
      child: SizedBox(
        width: screenWidth * 0.4,
        height: 90,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Card Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              // Card Status
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
