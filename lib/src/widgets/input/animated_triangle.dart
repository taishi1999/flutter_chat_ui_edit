import 'dart:math';

import 'package:flutter/material.dart';

class AnimatedTriangle extends StatefulWidget {
  const AnimatedTriangle({
    super.key,
    required this.sliderFontValue,
  });

  final void Function(double) sliderFontValue;
  @override
  _AnimatedTriangleState createState() => _AnimatedTriangleState();
}

// ...

class _AnimatedTriangleState extends State<AnimatedTriangle>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Size> _animation;
  late Animation<double> _translateAnimation;
  double _sliderValue = 16;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    _animation = Tween<Size>(
      begin: Size(0, 200),
      end: Size(20, 200),
    ).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });

    _translateAnimation = Tween<double>(
      begin: 0,
      end: 20,
    ).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Transform.translate(
              offset: Offset(-10 + _translateAnimation.value, 0),
              child: CustomPaint(
                painter: TrianglePainter(),
                size: _animation.value,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Transform.translate(
              offset: Offset(-100 + _translateAnimation.value, 0),
              child: Transform.rotate(
                angle: -pi / 2,
                child: SizedBox(
                  height: 40,
                  width: 200,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 0,
                      activeTrackColor: Colors.black,
                      inactiveTrackColor: Colors.grey[300],
                      thumbColor: Colors.grey[800],
                      thumbShape: RoundSliderThumbShape(elevation: 5),
                      overlayColor: Colors.blue.withOpacity(0.3),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
                    ),
                    child: Slider(
                      value: _sliderValue,
                      min: 1,
                      max: 32,
                      onChangeStart: (value) {
                        _animationController.forward();
                      },
                      onChanged: (double value) {
                        setState(() {
                          _sliderValue = value;
                          widget.sliderFontValue(value);
                          //_animationController.forward();
                        });
                      },
                      onChangeEnd: (double value) {
                        _animationController.reverse();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ...

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final trianglePath = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    final paint = Paint()
      ..color = Colors.white.withOpacity(.8)
      //..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final shadowBlurSigma = 20.0;
    final shadowColor = Colors.black;

    canvas.drawShadow(trianglePath, shadowColor, shadowBlurSigma, true);
    canvas.drawPath(trianglePath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
