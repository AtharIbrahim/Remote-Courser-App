import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mouse_app/presentation/mouse_control_screen.dart';
import 'package:mouse_app/presentation/qr_scanner.dart';
import 'package:mouse_app/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class Settings extends StatefulWidget {
  final Function(double) onSpeedChanged;
  final Function(String) onIpChanged;

  const Settings({
    super.key,
    required this.onSpeedChanged,
    required this.onIpChanged,
  });

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  // Variables:
  double _speed = 1.0;
  String _ipAddress = '';
  late TextEditingController _ipController;
  bool _isRgbOn = true; // Default value

  // On Initial
  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController();

    _loadSettings();
  }

  // Load the Save Settings
  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _speed = prefs.getDouble('mouse_speed') ?? 1.0;
      _ipAddress = prefs.getString('pc_ip') ?? '';
      _ipController.text = _ipAddress;
      _isRgbOn = prefs.getBool('rgb_effect') ?? true; // Load RGB state
    });
  }

  // Function To Save The App Settings!
  _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble('mouse_speed', _speed);
    prefs.setString('pc_ip', _ipAddress);
    prefs.setBool('rgb_effect', _isRgbOn); // Save RGB state
  }

  // Pass the changes to the py server
  void _sendToServer() {
    widget.onSpeedChanged(_speed);
    widget.onIpChanged(_ipAddress);
  }

  // Add QR scanning function
  Future<void> _scanQRCode() async {
    // Check camera permission
    if (await Permission.camera.request().isGranted) {
      final scannedData = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QRScanScreen(),
        ),
      );

      if (scannedData != null) {
        // Parse the scanned data to extract IP address
        try {
          final uri = Uri.parse(scannedData);
          setState(() {
            _ipAddress = uri.host;
            _ipController.text = uri.host;
          });
          _saveSettings();
          _sendToServer();
        } catch (e) {
          // Handle Errors
        }
      }
    } else {}
  }

  // Main UI Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      // Toolbar
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
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
        iconTheme: const IconThemeData(color: Colors.white),
        // Toolbar Back Arrow
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            // Custom navigation logic here
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MouseControlScreen(),
              ),
            );
          },
        ),
      ),
      // Body
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Speed: ${_speed.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16)),
            Slider(
              thumbColor: const Color.fromRGBO(28, 30, 51, 1),
              activeColor: const Color.fromARGB(255, 47, 49, 78),
              inactiveColor: Theme.of(context).colorScheme.secondary,
              value: _speed,
              min: 0.1,
              max: 3.0,
              // Call Functions
              onChanged: (newSpeed) {
                setState(() {
                  _speed = newSpeed;
                });
                _saveSettings();
                _sendToServer();
              },
            ),
            const SizedBox(height: 20),
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              // Ip Input Field
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'PC IP Address',
                        hintText: 'Enter your PC\'s IP address',
                        border: InputBorder.none,
                      ),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      onChanged: (newIp) {
                        setState(() {
                          _ipAddress = newIp;
                        });
                        _saveSettings();
                        _sendToServer();
                      },
                      controller: _ipController,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _scanQRCode,
                    color: const Color(0xFF2E0059),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Switch Dark/Light Modes
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // dark Mode
                  const Text("Dark Mode"),

                  // Switch Toggle
                  CupertinoSwitch(
                    value: Provider.of<ThemeProvider>(context, listen: false)
                        .isDarkMode,
                    onChanged: (value) =>
                        Provider.of<ThemeProvider>(context, listen: false)
                            .toggleTheme(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // On/OFF BG Modes
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // dark Mode
                  const Text("Edge RGB"),

                  // Switch Toggle
                  CupertinoSwitch(
                    value: _isRgbOn,
                    onChanged: (value) {
                      setState(() {
                        _isRgbOn = value;
                      });
                      _saveSettings();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Theme Selection
            Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 24.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  // color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/bg1.jpg',
                    ), // Path to your image
                    fit: BoxFit
                        .cover, // Adjusts how the image fits inside the container
                    opacity: 0.6,
                  ),
                ),
                child: Stack(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Theme Text
                        const Text(
                          "BG Theme",
                          style: TextStyle(
                            // color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}
