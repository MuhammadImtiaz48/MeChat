import 'package:flutter/material.dart';
import 'package:imtiaz/firebase_Services/splash_services.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  SplashServices splashServices = SplashServices();
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<Color?> _gradientColorAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );
    
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _gradientColorAnimation = ColorTween(
      begin: const Color(0xFF6A11CB),
      end: const Color(0xFF2575FC),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );
    
    // Start animation after frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });

    splashServices.checkLoginStatus(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: SweepGradient(
                center: Alignment.center,
                startAngle: 0.0,
                endAngle: 3.14 * 2,
                colors: [
                  _gradientColorAnimation.value!,
                  _gradientColorAnimation.value!.withGreen(150).withOpacity(0.8),
                  _gradientColorAnimation.value!.withBlue(200).withOpacity(0.9),
                  _gradientColorAnimation.value!,
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
                transform: GradientRotation(_controller.value * 3.14 * 2),
              ),
            ),
            alignment: Alignment.center,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated logo with pulsing effect
                    AnimatedLogo(controller: _controller),
                    const SizedBox(height: 30),
                    // Text with slide animation
                    SlideTransition(
                      position: _textSlideAnimation,
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.white.withOpacity(0.7),
                            ],
                            stops: const [0.5, 1.0],
                          ).createShader(bounds);
                        },
                        child: const Text(
                          "MeChat",
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Subtitle with fade animation
                    FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _controller,
                          curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
                        ),
                      ),
                      child: const Text(
                        "Connect • Communicate • Collaborate",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AnimatedLogo extends StatelessWidget {
  final AnimationController controller;
  
  const AnimatedLogo({super.key, required this.controller});
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer ring pulse effect
        ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 1.8).animate(
            CurvedAnimation(
              parent: controller,
              curve: const Interval(0.0, 0.5, curve: Curves.fastOutSlowIn),
            ),
          ),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.3, end: 0.0).animate(
              CurvedAnimation(
                parent: controller,
                curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
              ),
            ),
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        // Middle ring pulse effect
        ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 1.5).animate(
            CurvedAnimation(
              parent: controller,
              curve: const Interval(0.1, 0.6, curve: Curves.fastOutSlowIn),
            ),
          ),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.4, end: 0.0).animate(
              CurvedAnimation(
                parent: controller,
                curve: const Interval(0.1, 0.6, curve: Curves.easeOut),
              ),
            ),
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        // Main logo
        RotationTransition(
          turns: Tween<double>(begin: -0.2, end: 0.0).animate(
            CurvedAnimation(
              parent: controller,
              curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
            ),
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.5, end: 1.0).animate(
              CurvedAnimation(
                parent: controller,
                curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
              ),
            ),
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  center: Alignment(-0.3, -0.3),
                  radius: 0.9,
                  colors: [
                    Color(0xFF6A11CB),
                    Color(0xFF2575FC),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2575FC).withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chat_rounded,
                size: 70,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // Floating particles
        ...List.generate(5, (index) {
          return Positioned(
            left: 40 + index * 15,
            top: 30 + index * 10,
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: controller,
                  curve: Interval(0.3 + index * 0.1, 1.0, curve: Curves.easeIn),
                ),
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                  CurvedAnimation(
                    parent: controller,
                    curve: Interval(0.3 + index * 0.1, 1.0, curve: Curves.elasticOut),
                  ),
                ),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}