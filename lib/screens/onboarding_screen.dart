import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';

class OnboardingScreen extends StatelessWidget {
  final Function() onDone;

  const OnboardingScreen({super.key, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "Welcome to EyeConnect",
          body: "Your one-stop app for helping visually impaired individuals.",
          image: Image.asset('assets/images/welcome.png', height: 200),
        ),
        PageViewModel(
          title: "Connect Seamlessly",
          body:
              "Easily connect with volunteers or those in need via video calls.",
          image: Image.asset('assets/images/connect.png', height: 200),
        ),
        PageViewModel(
          title: "Get Started",
          body: "Sign up and start using the app today.",
          image: Image.asset('assets/images/get-started.png', height: 200),
        ),
      ],
      onDone: onDone,
      showSkipButton: true,
      skip: const Text("Skip"),
      next: const Icon(Icons.arrow_forward),
      done: const Text("Done", style: TextStyle(fontWeight: FontWeight.w600)),
      dotsDecorator: const DotsDecorator(
        size: Size.square(8.0),
        activeSize: Size(18.0, 8.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}
