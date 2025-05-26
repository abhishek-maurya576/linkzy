import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedParticlesBackground extends StatefulWidget {
  final int numberOfParticles;
  final List<Color> colors;
  final bool animateGradient;

  const AnimatedParticlesBackground({
    Key? key,
    this.numberOfParticles = 50,
    required this.colors,
    this.animateGradient = true,
  }) : super(key: key);

  @override
  AnimatedParticlesBackgroundState createState() => AnimatedParticlesBackgroundState();
}

class AnimatedParticlesBackgroundState extends State<AnimatedParticlesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  final Random _random = Random();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Initialize with empty list, will populate in didChangeDependencies
    _particles = [];

    _controller.addListener(() {
      if (!_initialized || _particles.isEmpty) return;

      for (final particle in _particles) {
        particle.position += particle.speed;
        
        // Check if particle is out of bounds
        _checkBounds(particle);
      }
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Now it's safe to access MediaQuery
    if (!_initialized) {
      _initializeParticles();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initializeParticles() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    _particles = List.generate(
      widget.numberOfParticles, 
      (_) => _createParticle(screenWidth, screenHeight)
    );
  }

  Particle _createParticle(double screenWidth, double screenHeight) {
    final size = _random.nextDouble() * 10 + 2;
    final color = widget.colors[_random.nextInt(widget.colors.length)];
    final position = Offset(
      _random.nextDouble() * screenWidth,
      _random.nextDouble() * screenHeight,
    );
    final speed = Offset(
      (_random.nextDouble() - 0.5) * 2,
      (_random.nextDouble() - 0.5) * 2,
    );
    final opacity = _random.nextDouble() * 0.6 + 0.2;

    return Particle(
      color: color,
      position: position,
      size: size,
      speed: speed,
      opacity: opacity,
    );
  }

  void _checkBounds(Particle particle) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (particle.position.dx <= 0 || particle.position.dx >= screenWidth) {
      particle.speed = Offset(-particle.speed.dx, particle.speed.dy);
    }

    if (particle.position.dy <= 0 || particle.position.dy >= screenHeight) {
      particle.speed = Offset(particle.speed.dx, -particle.speed.dy);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If not initialized yet, show a simple container with the first color
    if (!_initialized || _particles.isEmpty) {
      return Container(
        color: widget.colors.first,
      );
    }

    return Stack(
      children: [
        // Animated gradient background
        if (widget.animateGradient) 
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final angle = _controller.value * 2 * pi;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(cos(angle), sin(angle)),
                    end: Alignment(-cos(angle), -sin(angle)),
                    colors: widget.colors,
                  ),
                ),
              );
            },
          ),
        // Particles overlay
        CustomPaint(
          painter: ParticlePainter(particles: _particles),
          size: Size.infinite,
        ),
      ],
    );
  }
}

class Particle {
  Color color;
  Offset position;
  double size;
  Offset speed;
  double opacity;

  Particle({
    required this.color,
    required this.position,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(particle.position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
} 