import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart'; // Add this

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
  double _speed = 1.0;
  String _ipAddress = '';
  late TextEditingController _ipController; // Add controller

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController();
    _loadSettings();
  }

  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _speed = prefs.getDouble('mouse_speed') ?? 1.0;
      _ipAddress = prefs.getString('pc_ip') ?? '';
      _ipController.text = _ipAddress; // Initialize controller text
    });
  }

  _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble('mouse_speed', _speed);
    prefs.setString('pc_ip', _ipAddress);
  }

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid QR code: $scannedData')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission required')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E0059),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Speed: ${_speed.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16)),
            Slider(
              thumbColor: const Color(0xFF2E0059),
              activeColor: const Color(0xFF2E0059),
              value: _speed,
              min: 0.1,
              max: 3.0,
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
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
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
          ],
        ),
      ),
    );
  }
}

// Add QR scanning screen
class QRScanScreen extends StatefulWidget {
  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  MobileScannerController cameraController = MobileScannerController();

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              Navigator.pop(context, barcode.rawValue);
            }
          }
        },
      ),
    );
  }
}
