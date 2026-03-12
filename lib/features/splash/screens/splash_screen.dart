import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Controllers
  late AnimationController _cController;
  late AnimationController _pulseController;
  late AnimationController _wave1Controller;
  late AnimationController _wave2Controller;
  late AnimationController _wave3Controller;

  // Animations
  late Animation<double> _cFade;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseFade;
  late Animation<double> _wave1Fade;
  late Animation<double> _wave2Fade;
  late Animation<double> _wave3Fade;

  int _loopCount = 0;
  final int _maxLoops = 3;

  @override
  void initState() {
    super.initState();

    // 1. C comes in
    _cController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _cFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _cController, curve: Curves.easeIn));

    // 2. Pulse heartbeat
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeOut)), weight: 50.0),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50.0),
    ]).animate(_pulseController);
    _pulseFade = Tween<double>(begin: 0.0, end: 1.0).animate(_pulseController);

    // 3. Waves fade in consecutively
    _wave1Controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _wave1Fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _wave1Controller, curve: Curves.easeIn));

    _wave2Controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _wave2Fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _wave2Controller, curve: Curves.easeIn));

    _wave3Controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _wave3Fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _wave3Controller, curve: Curves.easeIn));

    _startSequence();
  }

  void _startSequence() async {
    // Wait a brief moment before starting
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) return;
    
    // Animate C in first
    await _cController.forward();
    
    // Start the looping pulse and waves
    _runLoop();
  }

  void _runLoop() async {
    if (!mounted) return;

    if (_loopCount >= _maxLoops) {
      // Loop finished 3 times, redirect explicitly to login
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // 1. Heartbeat pulse
    await _pulseController.forward();
    
    // 2. Waves consecutively
    await _wave1Controller.forward();
    await _wave2Controller.forward();
    await _wave3Controller.forward();
    
    // 3. Hold for a short duration while fully visible
    await Future.delayed(const Duration(milliseconds: 400));
    
    if (!mounted) return;

    // Reset pulse and waves for the next loop (except C remains)
    _pulseController.reset();
    _wave1Controller.reset();
    _wave2Controller.reset();
    _wave3Controller.reset();

    // Minor delay before starting the next loop beat
    await Future.delayed(const Duration(milliseconds: 300));

    _loopCount++;
    _runLoop();
  }

  @override
  void dispose() {
    _cController.dispose();
    _pulseController.dispose();
    _wave1Controller.dispose();
    _wave2Controller.dispose();
    _wave3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Assuming the exported images are exactly the same size including transparent space,
    // placing them in a Stack centered will perfectly align them like the whole logo.
    // Setting a fixed width constraint helps if the actual assets contain transparent padding.
    const double logoWidth = 200.0; 

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SizedBox(
          width: logoWidth,
          // Using aspect ratio or letting height be determined by image natural size
          child: Stack(
            alignment: Alignment.center,
            children: [
              // C
              FadeTransition(
                opacity: _cFade,
                child: Image.asset(
                  'assets/images/C.png',
                  width: logoWidth,
                  fit: BoxFit.contain,
                ),
              ),
              // Pulse
              FadeTransition(
                opacity: _pulseFade,
                child: ScaleTransition(
                  scale: _pulseScale,
                  child: Image.asset(
                    'assets/images/PULSE.png',
                    width: logoWidth,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Wave 1
              FadeTransition(
                opacity: _wave1Fade,
                child: Image.asset(
                  'assets/images/WAVE 1.png',
                  width: logoWidth,
                  fit: BoxFit.contain,
                ),
              ),
              // Wave 2
              FadeTransition(
                opacity: _wave2Fade,
                child: Image.asset(
                  'assets/images/WAVE 2.png',
                  width: logoWidth,
                  fit: BoxFit.contain,
                ),
              ),
              // Wave 3
              FadeTransition(
                opacity: _wave3Fade,
                child: Image.asset(
                  'assets/images/WAVE 3.png',
                  width: logoWidth,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
