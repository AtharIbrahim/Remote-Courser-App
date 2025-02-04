import 'package:flutter/material.dart';
import 'package:mouse_app/presentation/splash_screen.dart';

void main() {
  runApp(MouseApp());
}

class MouseApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
  //
}
