import 'package:flutter/material.dart';

/// Premium background widget using the provided background image
/// Optimized for mobile onboarding and authentication screens
class AbstractBackground extends StatelessWidget {
  const AbstractBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Background image
          _buildBackgroundImage(),

          // Optional overlay for better text contrast if needed
          _buildOverlay(),
        ],
      ),
    );
  }

  /// Background image from assets
  Widget _buildBackgroundImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// Optional subtle overlay for better text readability
  Widget _buildOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.1), // Very subtle overlay
          ],
          stops: const [0.7, 1.0],
        ),
      ),
    );
  }
}

/// Animated version with subtle parallax effect
class AnimatedAbstractBackground extends StatefulWidget {
  const AnimatedAbstractBackground({super.key});

  @override
  State<AnimatedAbstractBackground> createState() =>
      _AnimatedAbstractBackgroundState();
}

class _AnimatedAbstractBackgroundState extends State<AnimatedAbstractBackground>
    with TickerProviderStateMixin {
  late AnimationController _parallaxController;
  late Animation<double> _parallaxAnimation;

  @override
  void initState() {
    super.initState();

    // Subtle parallax animation
    _parallaxController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);

    _parallaxAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _parallaxController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _parallaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated background with subtle parallax
        AnimatedBuilder(
          animation: _parallaxAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                _parallaxAnimation.value,
                _parallaxAnimation.value * 0.5,
              ),
              child: Transform.scale(
                scale:
                    1.05, // Slightly larger to prevent edge gaps during animation
                child: const AbstractBackground(),
              ),
            );
          },
        ),
      ],
    );
  }
}
