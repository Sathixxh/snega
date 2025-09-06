import 'package:flutter/material.dart';
import 'package:mywebapp/widgets/navbar.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NavBar(),
        Expanded(
          child: Center(
            child: Text(
              'Hi, I\'m Satheesh\nFlutter Developer',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32),
            ),
          ),
        ),
      ],
    );
  }
}
