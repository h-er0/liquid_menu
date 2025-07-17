import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class LiquidMenu extends StatefulWidget {
  const LiquidMenu({super.key});

  @override
  State<LiquidMenu> createState() => _LiquidMenuState();
}

class _LiquidMenuState extends State<LiquidMenu> with TickerProviderStateMixin {
  List<MetaballCircle> _circles = [];
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  // Flag to track if initialization has occurred
  bool _isInit = false;
  // Flag to toggle menu visibility
  bool _showMenu = false;

  // Initializes metaball circles and their animations

  void _initializeCircles() {
    if (!_isInit) {
      // Define metaball circles with positions, radii, and scaling origins
      _circles = [
        // Circle starting from the menu button (top-left)
        MetaballCircle(
          position: Offset(34, MediaQuery.paddingOf(context).top + 30),
          scaleOrigin: Alignment.topLeft,
          baseRadius:
              37, // Sets initial size of the circle; small radius keeps container compact
          radius:
              37, // Initial radius matches baseRadius; small values may cause slightly blurred contours in V1 due to blur filter
          // Note: If radius is too small, the container may not appear due to rendering issues
          scaledRadius: 300, // Target radius when expanded
        ),
        // Circle from top-right outside the screen
        MetaballCircle(
          position: Offset(MediaQuery.sizeOf(context).width, -50),
          scaleOrigin: Alignment.center,
          scaledRadius: 250,
        ),
        // Circle from middle-right of the screen
        MetaballCircle(
          position: Offset(
            MediaQuery.sizeOf(context).width + 100,
            (MediaQuery.sizeOf(context).height / 2) + 100,
          ),
          scaleOrigin: Alignment.center,
          scaledRadius: 300,
        ),
        // Circle from top-left outside the screen
        MetaballCircle(
          position: Offset(-10, 50),
          scaleOrigin: Alignment.centerLeft,
          scaledRadius: 200,
        ),
        // Circle from middle-left of the screen
        MetaballCircle(
          position: Offset(-100, (MediaQuery.sizeOf(context).height / 2) + 100),
          scaleOrigin: Alignment.center,
          scaledRadius: 300,
        ),
        // Circle from bottom-left of the screen
        MetaballCircle(
          position: Offset(-30, MediaQuery.sizeOf(context).height + 50),
          scaledRadius: 500,
          scaleOrigin: Alignment.bottomLeft,
        ),
        // Circle from bottom-left outside the screen
        MetaballCircle(
          position: Offset(-10, MediaQuery.sizeOf(context).height + 10),
          scaledRadius: 500,
          scaleOrigin: Alignment.center,
        ),
      ];

      // Initialize animation controllers for each circle
      _controllers = _circles.map((circle) {
        return AnimationController(
          duration: const Duration(milliseconds: 1000),
          vsync: this,
        );
      }).toList();

      // Create animations to tween between base and scaled radii
      _animations = _circles.asMap().entries.map((entry) {
        final index = entry.key;
        final circle = entry.value;
        return Tween<double>(
            begin: circle.baseRadius,
            end: circle.scaledRadius,
          ).animate(
            CurvedAnimation(
              parent: _controllers[index],
              curve: Curves.easeInOut,
            ),
          )
          ..addListener(() {
            // Update circle's radius during animation
            _circles[index] = _circles[index].copyWithScaledRadius(
              _animations[index].value,
            );
          });
      }).toList();

      // Mark initialization as complete
      setState(() {
        _isInit = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize circles on first build
    // Note: Initialization is done in build() instead of initState() to avoid errors from accessing MediaQuery.of(context) before dependencies are ready.
    _initializeCircles();
    return Material(
      color: Colors.white,
      child: Stack(
        children: [
          // Background list view with dummy items
          SizedBox.expand(
            child: Scaffold(appBar: AppBar(), body: Container()),
          ),
          // Metaball animation layer with color filter
          AnimatedBuilder(
            animation: Listenable.merge(_animations),
            builder: (context, _) {
              return ClipRRect(
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    1, 0, 0, 0, 0,
                    0, 1, 0, 0, 0,
                    0, 0, 1, 0, 0,
                    0, 0, 0, 60, -6000, // Custom color matrix for effect
                  ]),
                  child: CustomPaint(
                    painter: MetaballShapesPainterV1(circles: _circles),
                    size: Size.infinite,
                  ),
                ),
              );
            },
          ),
          // Alternative using MetaballShapesPainterV2 for rendering metaball circles
          /* AnimatedBuilder(
            animation: Listenable.merge(_animations),
            builder: (context, _) {
              return ClipRRect(
                child: CustomPaint(
                  painter: MetaballShapesPainterV2(circles: _circles),
                  size: Size.infinite,
                ),
              );
            },
          ), */
          // Menu button (top-left) to open the menu
          Positioned(
            top: 10,
            left: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () {
                  if (!_showMenu) {
                    // Start animations to expand circles
                    for (var controller in _controllers) {
                      controller.forward();
                    }
                    setState(() {
                      _showMenu = true;
                    });
                  }
                },
                child: Container(
                  height: 40,
                  width: 40,
                  clipBehavior: Clip.none,
                  color: Colors.transparent,
                  child: AnimatedOpacity(
                    opacity: _showMenu ? 0 : 1.0,
                    duration: const Duration(milliseconds: 1000),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOut,
                      transform: Matrix4.translationValues(
                        _showMenu ? -70 : 0, // Slide left when menu is open
                        0,
                        0,
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          "assets/svg/menu_left.svg",
                          height: 24,
                          width: 24,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Close button (top-right) to close the menu
          AnimatedPositioned(
            top: 10,
            right: _showMenu ? 16 : -30,
            duration: const Duration(milliseconds: 850),
            child: SafeArea(
              child: GestureDetector(
                onTap: () {
                  if (_showMenu) {
                    // Reverse animations to shrink circles
                    for (var controller in _controllers) {
                      controller.reverse();
                    }
                    setState(() {
                      _showMenu = false;
                    });
                  }
                },
                child: SizedBox(
                  height: 40,
                  width: 40,
                  child: Center(
                    child: SvgPicture.asset(
                      "assets/svg/close.svg",
                      height: 30,
                      width: 30,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Menu items with staggered slide-in animation
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnimatedMenuItem("Home", 0),
                _buildAnimatedMenuItem("Categories", 1),
                _buildAnimatedMenuItem("About", 2),
                _buildAnimatedMenuItem("Contact us", 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Builds a menu item with animated slide-in effect
  Widget _buildAnimatedMenuItem(String text, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 1000 + index * 50), // Staggered timing
      curve: Curves.easeInOut,
      transform: Matrix4.translationValues(
        _showMenu ? 0 : -500 - (index * 20).toDouble(), // Slide in from left
        0,
        0,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}

// Custom painter for drawing metaball circles
class MetaballShapesPainterV1 extends CustomPainter {
  final List<MetaballCircle> circles;

  MetaballShapesPainterV1({required this.circles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final circle in circles) {
      final center = size.topLeft(circle.position);
      // Calculate alignment offset for scaling origin
      final alignmentOffset = Offset(
        circle.scaleOrigin.x,
        circle.scaleOrigin.y,
      );
      // Compute fixed point for scaling
      final fixedPoint = center + alignmentOffset * circle.baseRadius;
      // Adjust center to maintain fixed point during scaling
      final adjustedCenter = fixedPoint - alignmentOffset * circle.radius;

      // Draw circle with blur effect
      canvas.drawCircle(
        adjustedCenter,
        circle.radius,
        Paint()
          ..color = circle.color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30.0),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Repaint on every frame for smooth animation
  }
}

// Alternative painter with additional color effects (Figma version)
class MetaballShapesPainterV2 extends CustomPainter {
  final List<MetaballCircle> circles;

  MetaballShapesPainterV2({required this.circles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final circle in circles) {
      final center = size.topLeft(circle.position);
      // Calculate alignment offset for scaling origin
      final alignmentOffset = Offset(
        circle.scaleOrigin.x,
        circle.scaleOrigin.y,
      );
      // Compute fixed point for scaling
      final fixedPoint = center + alignmentOffset * circle.baseRadius;
      // Adjust center to maintain fixed point during scaling
      final adjustedCenter = fixedPoint - alignmentOffset * circle.radius;

      // Draw circle with blur effect
      canvas.drawCircle(
        adjustedCenter,
        circle.radius,
        Paint()
          ..color = circle.color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30.0),
      );
    }

    // Apply color dodge effect
    canvas.drawPaint(
      Paint()
        ..color = const Color(0xFF808080)
        ..blendMode = BlendMode.colorDodge,
    );

    // Apply color burn effect
    canvas.drawPaint(
      Paint()
        ..color = const Color(0xff010101)
        ..blendMode = BlendMode.colorBurn,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Repaint on every frame for smooth animation
  }
}

// Data class representing a metaball circle
class MetaballCircle {
  final Offset position; // Circle's position on the canvas
  final double baseRadius; // Initial radius
  final double radius; // Current radius (animated)
  final double scaledRadius; // Target radius when scaled
  final Color color; // Circle color
  final Alignment scaleOrigin; // Scaling anchor point

  const MetaballCircle({
    required this.position,
    this.baseRadius = 0,
    this.radius = 0,
    this.scaledRadius = 200,
    this.scaleOrigin = Alignment.center,
    this.color = Colors.black,
  });

  // Creates a copy of the circle with a new radius
  MetaballCircle copyWithScaledRadius(double newRadius) {
    return MetaballCircle(
      position: position,
      baseRadius: baseRadius,
      radius: newRadius,
      scaledRadius: scaledRadius,
      color: color,
      scaleOrigin: scaleOrigin,
    );
  }
}
