import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  final Function(double) onSpeedChanged;
  final Function(String) onIpChanged; // Callback for IP address change

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
  String _ipAddress = ''; // Store the IP address

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Load saved settings (speed and IP address)
  }

  // Load the saved speed and IP address from SharedPreferences
  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _speed = prefs.getDouble('mouse_speed') ?? 1.0;
      _ipAddress = prefs.getString('pc_ip') ?? ''; // Load saved IP address
    });
  }

  // Save the new speed and IP address to SharedPreferences
  _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble('mouse_speed', _speed);
    prefs.setString('pc_ip', _ipAddress);
  }

  // Send the speed and IP address to the server and update the callback
  void _sendToServer() {
    widget.onSpeedChanged(_speed);
    widget.onIpChanged(_ipAddress); // Send IP address change
    // print("Sending speed and IP to server: Speed: $_speed, IP: $_ipAddress");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E0059),
        iconTheme: IconThemeData(
          color: Colors.white, // Change the back arrow color here
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Speed: ${_speed.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 16)),
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
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'PC IP Address',
                  hintText: 'Enter your PC\'s IP address',
                  border: InputBorder.none,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (newIp) {
                  setState(() {
                    _ipAddress = newIp;
                  });
                  _saveSettings();
                  _sendToServer();
                },
                controller: TextEditingController(text: _ipAddress),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
