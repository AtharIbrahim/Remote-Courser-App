import 'package:flutter/material.dart';

class SimpleRgb extends StatelessWidget {
  // RGB Variables
  final AnimationController animationController;
  const SimpleRgb({
    super.key,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: // Neon RGB Edge Effect
          AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                width: 12, // Thickness of the neon border
                color: Colors.transparent,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.lerp(
                    Colors.red,
                    Colors.blue,
                    animationController.value,
                  )!
                      .withOpacity(0.8),
                  blurRadius: 20, // Glow intensity
                  spreadRadius: 3,
                ),
                BoxShadow(
                  color: Color.lerp(
                    Colors.blue,
                    Colors.green,
                    animationController.value,
                  )!
                      .withOpacity(0.8),
                  blurRadius: 20, // Glow intensity
                  spreadRadius: 3,
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                      Colors.red, Colors.blue, animationController.value)!,
                  Color.lerp(
                      Colors.blue, Colors.green, animationController.value)!,
                  Color.lerp(
                      Colors.green, Colors.red, animationController.value)!,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: Container(), // Required to show the border
          );
        },
      ),
    );
  }
}
