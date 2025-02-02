import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart'; // For QR code generation
import 'dart:io';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Desktop Mouse Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 16.0),
        ),
      ),
      home: const MyHomePage(title: 'Desktop Mouse Controller'),
    );
  }
}

/// The home page widget that shows the status and logs.
class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

/// The state for [MyHomePage] that manages the Python server process and UI updates.
class _MyHomePageState extends State<MyHomePage> {
  // Status strings and logs.
  String _pythonStatus = "Not started";
  String _serverStatus = "Not running";
  String _phoneConnection = "Not connected";
  final String _connectionPort = "5000"; // as per your Python server
  final List<String> _logs = [];
  String _ipAddress = "Fetching IP..."; // IP address of the system
  bool _showQrCode = false; // Toggle for showing/hiding QR code

  Process? _pythonProcess;

  @override
  void initState() {
    super.initState();
    _initPython();
    _fetchIpAddress(); // Fetch IP address when the app starts
  }

  /// Fetches the IP address of the system using a Python script.
  Future<void> _fetchIpAddress() async {
    try {
      final result =
          await Process.run('python', ['get_ip.py'], runInShell: true);
      if (result.exitCode == 0) {
        setState(() {
          _ipAddress = result.stdout.toString().trim();
        });
      } else {
        setState(() {
          _ipAddress = "Failed to fetch IP";
        });
      }
    } catch (e) {
      setState(() {
        _ipAddress = "Error: $e";
      });
    }
  }

  /// Initializes the Python environment and starts the Python server.
  Future<void> _initPython() async {
    final pythonCmd = 'python'; // Change to 'python3' if needed.
    final pythonScript = 'server.py';
    final requiredPackages = ['python-socketio', 'aiohttp', 'pynput'];

    // 1. Check that Python is installed.
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

    // 2. Check and install missing Python packages.
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

    // 3. Start the Python script.
    setState(() {
      _logs.add("Starting Python script: $pythonScript");
    });

    try {
      _pythonProcess = await Process.start(
        pythonCmd,
        [pythonScript],
        runInShell: true,
      );
      setState(() {
        _serverStatus = "Running";
      });

      // Listen to stdout from the Python process.
      _pythonProcess!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        debugPrint("Python stdout: $line");
        setState(() {
          _logs.add("Python: $line");
        });
        final lowerLine = line.toLowerCase();
        if (lowerLine.contains("client connected:")) {
          final parts = line.split("Client connected:");
          if (parts.length > 1) {
            String clientId = parts[1].trim();
            setState(() {
              _phoneConnection = "Connected: $clientId";
            });
          } else {
            setState(() {
              _phoneConnection = "Connected";
            });
          }
        } else if (lowerLine.contains("client disconnected:")) {
          setState(() {
            _phoneConnection = "Not connected";
          });
        }
      });

      // Listen to stderr from the Python process.
      _pythonProcess!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        debugPrint("Python stderr: $line");
        setState(() {
          _logs.add("Error: $line");
        });
      });
    } catch (e) {
      setState(() {
        _logs.add("Error: Failed to start Python process: $e");
        _serverStatus = "Failed to start";
      });
    }
  }

  /// Checks if a command is available by running it with the provided arguments.
  Future<bool> _isCommandAvailable(String cmd, List<String> args) async {
    try {
      final result = await Process.run(cmd, args, runInShell: true);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Checks if a given Python package is installed using `pip show <package>`.
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

  /// Installs a Python package using pip.
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

  @override
  void dispose() {
    // Terminate the Python process when closing the app.
    _pythonProcess?.kill();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            const Color.from(alpha: 1, red: 0.051, green: 0.051, blue: 0.169),
        title: Text(widget.title),
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
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E0059), Color(0xFF0D0D2B)],
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
                        data: "http://$_ipAddress:$_connectionPort",
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
                    _buildStatusCard("Python Status", _pythonStatus,
                        Colors.deepPurpleAccent, screenWidth),
                    _buildStatusCard("Server Status", _serverStatus,
                        Colors.greenAccent, screenWidth),
                    _buildStatusCard("Connection Port", _connectionPort,
                        Colors.orangeAccent, screenWidth),
                    _buildStatusCard("Phone Connection", _phoneConnection,
                        Colors.lightBlueAccent, screenWidth),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Logs & Errors",
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 10),
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
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
