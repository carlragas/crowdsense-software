import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_notification_modal.dart';
import '../../auth/screens/login_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';

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
  late AnimationController _assemblyFadeOutController;

  // Animations
  late Animation<double> _cFade;
  late Animation<double> _pulseClip;
  late Animation<double> _wave1Fade;
  late Animation<double> _wave2Fade;
  late Animation<double> _wave3Fade;
  late Animation<double> _assemblyFade;

  int _loopCount = 0;
  final int _maxLoops = 3; // Default static loops if no future provided
  
  bool _isAuthMode = false;
  Future<dynamic>? _authFuture;
  bool _authCompleted = false;
  String _targetRoute = '/login';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read route arguments to see if an auth future and custom target route were passed
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      if (args.containsKey('authFuture')) {
        _isAuthMode = true;
        _authFuture = args['authFuture'];
        _authFuture?.then((_) {
          if (mounted) {
            setState(() {
              _authCompleted = true;
            });
          }
        }).catchError((error) {
           if (mounted) {
            setState(() {
              _authCompleted = true; // Stop loop
              _targetRoute = '/login'; // Re-route to login
            });
            String errorMsg = error.toString().replaceFirst('Exception: ', '');
            CustomNotificationModal.show(
              context: context,
              title: "Authentication Error",
              message: errorMsg,
              isSuccess: false,
            );
          }
        });
      }
      if (args.containsKey('nextRoute')) {
        _targetRoute = args['nextRoute'];
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // 1. C comes in
    _cController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _cFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _cController, curve: Curves.easeIn));

    // 2. Pulse heartbeat (ECG Wipe Left to Right)
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseClip = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

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

    // 4. Assembly fade out
    _assemblyFadeOutController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _assemblyFade = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _assemblyFadeOutController, curve: Curves.easeOut));

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
  
  bool _shouldFinishAnimation() {
    if (_isAuthMode) {
      // In auth mode: Requires a minimum of 2 loops AND the future to be complete
      return _loopCount >= 2 && _authCompleted;
    } else {
      // Standard static mode: Finishes after 3 max loops
      return _loopCount >= _maxLoops;
    }
  }

  void _runLoop() async {
    if (!mounted) return;

    if (_shouldFinishAnimation()) {
      // Loop finished conditions met. Hold for 1.5 seconds.
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (!mounted) return;
      
      // Fade out the entire assembly
      await _assemblyFadeOutController.forward();
      
      if (!mounted) return;

      // Navigate with custom diagonal wipe transition
      _navigateToTarget();
      return;
    }

    // 1. ECG Pulse wipe left to right
    await _pulseController.forward();
    
    // 2. Waves consecutively
    await _wave1Controller.forward();
    await _wave2Controller.forward();
    await _wave3Controller.forward();
    
    // 3. Hold for a short duration while fully visible
    await Future.delayed(const Duration(milliseconds: 400));
    
    if (!mounted) return;

    _loopCount++;

    // Reset pulse and waves for the next loop (if we are going to run another loop)
    if (!_shouldFinishAnimation()) {
      _pulseController.reset();
      _wave1Controller.reset();
      _wave2Controller.reset();
      _wave3Controller.reset();

      // Minor delay before starting the next loop beat
      await Future.delayed(const Duration(milliseconds: 300));
    }

    _runLoop();
  }

  void _navigateToTarget() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1000),
        // If target is login, do not animate its internal children on entry to allow the wipe to handle the reveal
        pageBuilder: (context, animation, secondaryAnimation) {
          switch (_targetRoute) {
            case '/login':
              return const LoginScreen(animate: false);
            case '/dashboard':
              return const DashboardScreen();
            default:
              return const LoginScreen(animate: false); // Fallback
          }
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // A diagonal wipe transition from top-left to bottom-right
          final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeInOut);

          return Stack(
            children: [
              // Keep the splash screen solid background underneath the transition
              Container(color: Theme.of(context).scaffoldBackgroundColor),
              
              ClipPath(
                clipper: _DiagonalWipeClipper(progress: curvedAnimation.value),
                child: child,
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _cController.dispose();
    _pulseController.dispose();
    _wave1Controller.dispose();
    _wave2Controller.dispose();
    _wave3Controller.dispose();
    _assemblyFadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double logoWidth = 200.0; 

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SizedBox(
          width: logoWidth,
          child: FadeTransition(
            opacity: _assemblyFade, // Wraps the entire stack
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
                // Pulse Wipe (Left to Right)
                AnimatedBuilder(
                  animation: _pulseClip,
                  builder: (context, child) {
                    return ClipRect(
                      clipper: _LeftToRightClipper(progress: _pulseClip.value),
                      child: child,
                    );
                  },
                  child: Image.asset(
                    'assets/images/PULSE.png',
                    width: logoWidth,
                    fit: BoxFit.contain,
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
      ),
    );
  }
}

class _LeftToRightClipper extends CustomClipper<Rect> {
  final double progress;
  
  _LeftToRightClipper({required this.progress});
  
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * progress, size.height);
  }
  
  @override
  bool shouldReclip(_LeftToRightClipper oldClipper) => progress != oldClipper.progress;
}

class _DiagonalWipeClipper extends CustomClipper<Path> {
  final double progress;

  _DiagonalWipeClipper({required this.progress});

  @override
  Path getClip(Size size) {
    final Path path = Path();
    
    // We want a line that sweeps diagonally. 
    // To cover the rectangle corner to corner, the line y = -x + c where c goes from 0 to width+height.
    double currentDistance = (size.width + size.height) * progress;
    
    path.lineTo(math.min(size.width, currentDistance), 0);
    
    if (currentDistance > size.width) {
      path.lineTo(size.width, currentDistance - size.width);
    }
    
    path.lineTo(0, math.min(size.height, currentDistance));
    
    if (currentDistance > size.height) {
      path.lineTo(currentDistance - size.height, size.height);
      // Clean up the shape by connecting the necessary points
      path.lineTo(math.min(size.width, currentDistance), 0);
      path.lineTo(0, math.min(size.height, currentDistance));
    }

    path.close();

    // A simpler way to do a diagonal reveal is using a polygon
    final Path polygonPath = Path();
    
    if (progress <= 0.0) {
      return polygonPath; // empty
    }
    if (progress >= 1.0) {
      polygonPath.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      return polygonPath;
    }

    // Top-left to bottom-right sweep
    double d = (size.width + size.height) * progress;

    polygonPath.moveTo(0, 0);
    
    if (d <= size.width) {
      polygonPath.lineTo(d, 0);
      polygonPath.lineTo(0, d);
    } else if (d <= size.height) {
      polygonPath.lineTo(d, 0);
      polygonPath.lineTo(0, d);
    } else {
      polygonPath.lineTo(size.width, 0);
      polygonPath.lineTo(size.width, d - size.width);
      polygonPath.lineTo(d - size.height, size.height);
      polygonPath.lineTo(0, size.height);
    }
    
    polygonPath.close();

    return polygonPath;
  }

  @override
  bool shouldReclip(_DiagonalWipeClipper oldClipper) => progress != oldClipper.progress;
}
