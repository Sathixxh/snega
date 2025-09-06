

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';


class ConfettiSample extends StatelessWidget {
  const ConfettiSample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Confetti',
        home: Scaffold(
          appBar: AppBar(title: Text("Lottie Animation")),
          body: Center(
            child: Lottie.asset('assets/Christmaswindchimes.json'),
          ),
        ),
      );
}
  








// class MyApp extends StatefulWidget {
//   @override
//   _MyAppState createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   late ConfettiController _controllerCenter;
//   late ConfettiController _controllerCenterRight;
//   late ConfettiController _controllerCenterLeft;
//   late ConfettiController _controllerTopCenter;
//   late ConfettiController _controllerBottomCenter;

//   bool _isBlastCompleted = false; // To track the state of the confetti blast

//   @override
//   void initState() {
//     super.initState();
//     _controllerCenter =
//         ConfettiController(duration: const Duration(seconds: 2));
//     _controllerCenterRight =
//         ConfettiController(duration: const Duration(seconds: 2));
//     _controllerCenterLeft =
//         ConfettiController(duration: const Duration(seconds: 2));
//     _controllerTopCenter =
//         ConfettiController(duration: const Duration(seconds: 2));
//     _controllerBottomCenter =
//         ConfettiController(duration: const Duration(seconds: 2));
// _handleBlast();

//   }

//   @override
//   void dispose() {
//     _controllerCenter.dispose();
//     _controllerCenterRight.dispose();
//     _controllerCenterLeft.dispose();
//     _controllerTopCenter.dispose();
//     _controllerBottomCenter.dispose();

//     super.dispose();
//   }

//   /// A custom Path to paint stars.
//   Path drawStar(Size size) {
//     // Method to convert degrees to radians
//     double degToRad(double deg) => deg * (pi / 180.0);

//     const numberOfPoints = 5;
//     final halfWidth = size.width / 2;
//     final externalRadius = halfWidth;
//     final internalRadius = halfWidth / 2.5;
//     final degreesPerStep = degToRad(360 / numberOfPoints);
//     final halfDegreesPerStep = degreesPerStep / 2;
//     final path = Path();
//     final fullAngle = degToRad(360);
//     path.moveTo(size.width, halfWidth);

//     for (double step = 0; step < fullAngle; step += degreesPerStep) {
//       path.lineTo(halfWidth + externalRadius * cos(step),
//           halfWidth + externalRadius * sin(step));
//       path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
//           halfWidth + internalRadius * sin(step + halfDegreesPerStep));
//     }
//     path.close();
//     return path;
//   }

// void _handleBlast() {
//   _controllerCenter.play();

//   // Disable re-tapping
//   setState(() {
//     _isBlastCompleted = true;
//   });

//   // Wait for 5 seconds, then stop confetti and navigate
//   Future.delayed(const Duration(seconds: 5), () {
//     _controllerCenter.stop();

//     // Navigate to HomeScreen
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) =>  HomeScreen()),
//     );
//   });
// }


//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Stack(
//         children: <Widget>[
//           //CENTER -- Blast
//           Align(
//             alignment: Alignment.center,
//             child: ConfettiWidget(
//               confettiController: _controllerCenter,
//               blastDirectionality: BlastDirectionality
//                   .explosive, // don't specify a direction, blast randomly
//               shouldLoop:
//                   true, // start again as soon as the animation is finished
//               colors: const [
//                 Colors.green,
//                 Colors.blue,
//                 Colors.pink,
//                 Colors.orange,
//                 Colors.purple
//               ], // manually specify the colors to be used
//               createParticlePath: drawStar, // define a custom shape/path.
//             ),
//           ),
         
//         ],
//       ),
//     );
//   }


// }

