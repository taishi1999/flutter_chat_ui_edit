import 'package:flutter/material.dart';
import 'dart:math';
import 'package:vector_math/vector_math_64.dart' as vec;

class MovableWidget extends StatefulWidget {
  final Offset initPos;
  final Size initSize;
  final Function(Offset) onMoved;
  final Function onSelected;
  String Enteredtext = '';
  final Function(bool) onMoveStart;

  MovableWidget(
      {required Key key,
      required this.initPos,
      required this.initSize,
      required this.onMoved,
      required this.onSelected,
      required this.Enteredtext,
      required this.onMoveStart})
      : super(key: key);

  @override
  _MovableWidgetState createState() => _MovableWidgetState();
}

class _MovableWidgetState extends State<MovableWidget> {
  Offset position = Offset.zero;
  Size size = Size.zero;
  bool isSelected = true;
  String enteredtext = '';
  //Offset _offset = Offset.zero;
  //Offset _offset = Offset(100, 200);
  Offset _initialFocalPoint = Offset.zero;
  Offset _sessionOffset = Offset.zero;

  double _scale = 1.0;
  double _initialScale = 1.0;
  double _radians = 0.0;
  double _initialRotate = 0.0;

  double threshold = 10;

  Widget _toolCase(Widget child) {
    return Container(
      width: 24,
      height: 24,
      child: IconTheme(
        data: Theme.of(context).iconTheme.copyWith(
              color: Colors.white,
              size: 24 * 0.6,
            ),
        child: child,
      ),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    position = widget.initPos;
    size = widget.initSize;
    enteredtext = widget.Enteredtext;
    position += Offset(size.width / 2, size.height / 2);
    _instances.add(this);

    // Reset isSelected for all other MovableWidgets
    //print('widget.key: $k');
    _MovableWidgetState.resetSelectionExcept(widget.key as Key);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // left: (position + _sessionOffset).dx,
      // top: (position + _sessionOffset).dy,
      left: (position + _sessionOffset).dx - size.width / 2 * _scale,
      top: (position + _sessionOffset).dy - size.height / 2 * _scale,
      child: Transform.rotate(
        angle: _radians,
        // child: Container(
        //   width: 100,
        //   height: 100,
        //   child: Center(
        //     child: Text('$enteredtext'),
        //   ),
        //   color: isSelected ? Colors.blue : null,
        // ),
        child: Stack(
          children: [
            Container(
              width: size.width * _scale,
              height: size.height * _scale,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  //constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 1,
                      color: isSelected ? Colors.grey : Colors.transparent,
                    ),
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        isSelected = true;
                      });
                      // Reset isSelected for all other MovableWidgets
                      var k = widget.key;
                      print('widget.key: $k');
                      widget.onSelected();
                      _MovableWidgetState.resetSelectionExcept(
                          widget.key as Key);
                    },
                    onScaleStart: (details) {
                      _initialFocalPoint = details.focalPoint;
                      _initialScale = _scale;
                      _initialRotate = _radians;
                      widget.onMoveStart(true);
                    },
                    onScaleUpdate: (details) {
                      double relativePlusRadian =
                          (details.rotation + 2 * pi) % (2 * pi);
                      double AbsolutePlusRadian =
                          ((_initialRotate + relativePlusRadian) + 2 * pi) %
                              (2 * pi);
                      double angle = vec.degrees(AbsolutePlusRadian);
                      //if (isSelected) {
                      setState(() {
                        _sessionOffset =
                            details.focalPoint - _initialFocalPoint;
                        //_disableScroll = true;
                        _scale = _initialScale * details.scale;
                        _radians = _initialRotate + details.rotation;
                        isSelected = true;

                        if (angle <= threshold || angle >= 360 - threshold) {
                          _radians = 0;
                        }
                        // position = Offset(
                        //   position.dx + details.delta.dx,
                        //   position.dy + details.delta.dy,
                        // );
                      });
                      widget.onMoved(position);
                      widget.onSelected();
                      _MovableWidgetState.resetSelectionExcept(
                          widget.key as Key);
                      //}
                    },
                    onScaleEnd: (details) {
                      setState(() {
                        position += _sessionOffset;
                        _sessionOffset = Offset.zero;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(),
                        child: FittedBox(
                          child: Text(
                            enteredtext,
                          ),
                        ),
                        // child: FittedBox(
                        //   fit: BoxFit.fill,
                        //   child: Text(
                        //     enteredtext,
                        //   ),
                        // ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 1,
              left: 1,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  //onTap: () => widget.onDel?.call(),
                  child: isSelected
                      ? _toolCase(const Icon(Icons.clear))
                      : Container(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void resetSelectionExcept(Key key) {
    //print('Key: $key');
    _MovableWidgetState.instances
        .where((movableWidget) => movableWidget.widget.key != key)
        .forEach((movableWidget) => movableWidget.deselect(key));
  }

  void deselect(Key key) {
    //print('選択されてないKey: $key');
    setState(() {
      isSelected = false;
    });
  }

  static Iterable<_MovableWidgetState> get instances => _instances;

  static final List<_MovableWidgetState> _instances = [];

  @override
  void dispose() {
    _instances.remove(this);
    super.dispose();
  }
}
