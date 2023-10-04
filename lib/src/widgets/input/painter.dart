/// Provides a widget and an associated controller for simple painting using touch.
library painter;

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart' hide Image;
import 'package:flutter/widgets.dart' hide Image;

/// A very simple widget that supports drawing using touch.
/// タッチによる描画をサポートする、非常にシンプルなウィジェットです。
class Painter extends StatefulWidget {
  final PainterController painterController;
  final VoidCallback? onPanStart;
  final VoidCallback? onPanEnd;
  final bool isLoadOnly;

  /// Creates an instance of this widget that operates on top of the supplied [PainterController].
  /// 指定した [PainterController] の上に動作するこのウィジェットのインスタンスを作成します。
  Painter({
    required PainterController painterController,
    VoidCallback? onPanStart,
    VoidCallback? onPanEnd,
    bool isLoadOnly = false,
  })  : this.painterController = painterController,
        this.onPanStart = onPanStart,
        this.onPanEnd = onPanEnd,
        this.isLoadOnly = isLoadOnly,
        super(key: new ValueKey<PainterController>(painterController));

  //final String test;

  @override
  _PainterState createState() => new _PainterState();
}

class _PainterState extends State<Painter> {
  bool _finished = false;
  bool _isLoadOnly = false;

  @override
  void initState() {
    super.initState();
    widget.painterController._widgetFinish = _finish;
    _isLoadOnly = widget.isLoadOnly;
  }

  Size _finish() {
    setState(() {
      _finished = true;
    });
    return context.size ?? const Size(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = new CustomPaint(
      willChange: true,
      painter: new _PainterPainter(widget.painterController._pathHistory,
          repaint: widget.painterController),
    );
    child = new ClipRect(child: child);
    if (!_finished && !_isLoadOnly) {
      child = new GestureDetector(
        child: child,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
      );
    }
    return new Container(
      child: child,
      width: double.infinity,
      height: double.infinity,
    );
  }

  void _onPanStart(DragStartDetails start) {
    print('painter._onPanStart');
    final Offset pos = (context.findRenderObject() as RenderBox)
        .globalToLocal(start.globalPosition);
    widget.painterController._pathHistory.add(pos);
    widget.painterController._notifyListeners();
    //chatに発火
    widget.onPanStart!();
  }

  void _onPanUpdate(DragUpdateDetails update) {
    final Offset pos = (context.findRenderObject() as RenderBox)
        .globalToLocal(update.globalPosition);
    widget.painterController._pathHistory.updateCurrent(pos);
    widget.painterController._notifyListeners();
  }

  void _onPanEnd(DragEndDetails end) {
    widget.painterController._pathHistory.endCurrent();
    widget.onPanEnd!();
    widget.painterController._notifyListeners();
  }
}

class _PainterPainter extends CustomPainter {
  final _PathHistory _path;

  _PainterPainter(this._path, {Listenable? repaint}) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    _path.draw(canvas, size);
  }

  @override
  bool shouldRepaint(_PainterPainter oldDelegate) {
    return false;
  }
}

class _PathHistory {
  List<MapEntry<Path, Paint>> _paths;
  List<MapEntry<Path, Paint>> undoPaths = <MapEntry<Path, Paint>>[];
  List<List<Offset>> _offsets;
  List<List<Offset>> undoOffsets = [];

  Paint currentPaint;
  Paint _backgroundPaint;
  bool _inDrag;

  bool get isEmpty => _paths.isEmpty;

  bool get isUndoPathEmpty => undoPaths.isEmpty;

  _PathHistory()
      : _paths = <MapEntry<Path, Paint>>[],
        _offsets = [],
        _inDrag = false,
        _backgroundPaint = new Paint()..blendMode = BlendMode.dstOver,
        currentPaint = new Paint()
          ..color = Colors.black
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.fill;

  void setBackgroundColor(Color backgroundColor) {
    _backgroundPaint.color = backgroundColor;
  }

  void undo() {
    if (!_inDrag && _paths.length > 0) {
      //paths.last
      undoPaths.add(_paths.last);
      _paths.removeLast();
      undoOffsets.add(_offsets.last);
      _offsets.removeLast();
    }
  }

  void redo() {
    if (!_inDrag && undoPaths.length > 0) {
      _paths.add(undoPaths.last);
      undoPaths.removeLast();
      _offsets.add(undoOffsets.last);
      undoOffsets.removeLast();
    }
  }

  void clear() {
    if (!_inDrag) {
      _paths.clear();
      undoPaths.clear();
      _offsets.clear();
      undoOffsets.clear();
    }
  }

  void add(Offset startPoint) {
    if (!_inDrag) {
      _inDrag = true;
      final Path path = new Path();
      path.moveTo(startPoint.dx, startPoint.dy);
      _paths.add(new MapEntry<Path, Paint>(path, currentPaint));
      _offsets.add([startPoint]);
      //点の描画
      path.addOval(Rect.fromCircle(
        center: Offset(startPoint.dx, startPoint.dy),
        radius: 1,
      ));
    }
  }

  void updateCurrent(Offset nextPoint) {
    if (_inDrag) {
      final Path path = _paths.last.key;
      path.lineTo(nextPoint.dx, nextPoint.dy);
      _offsets.last.add(nextPoint);
    }
  }

  void endCurrent() {
    _inDrag = false;
  }

  void draw(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    for (MapEntry<Path, Paint> path in _paths) {
      final Paint p = path.value;
      canvas.drawPath(path.key, p);
    }
    canvas.drawRect(
      new Rect.fromLTWH(0.0, 0.0, size.width, size.height),
      _backgroundPaint,
    );
    canvas.restore();
  }
}

/// Container that holds the size of a finished drawing and the drawed data as [Picture].
class PictureDetails {
  /// The drawings data as [Picture].
  final Picture picture;

  /// The width of the drawing.
  final int width;

  /// The height of the drawing.
  final int height;

  /// Creates an immutable instance with the given drawing information.
  const PictureDetails(this.picture, this.width, this.height);

  /// Converts the [picture] to an [Image].
  Future<Image> toImage() => picture.toImage(width, height);

  /// Converts the [picture] to a PNG and returns the bytes of the PNG.
  ///
  /// This might throw a [FlutterError], if flutter is not able to convert
  /// the intermediate [Image] to a PNG.
  Future<Uint8List> toPNG() async {
    final Image image = await toImage();
    final ByteData? data = await image.toByteData(format: ImageByteFormat.png);
    if (data != null) {
      var a = data.buffer.asUint8List();
      print('data.buffer.asUint8List(): $a');
      return data.buffer.asUint8List();
    } else {
      throw new FlutterError('Flutter failed to convert an Image to bytes!');
    }
  }
}

/// [Painter]ウィジェットで使用し、描画をコントロールする。
class PainterController extends ChangeNotifier {
  Color _drawColor = new Color.fromARGB(255, 0, 0, 0);
  Color _backgroundColor = new Color.fromARGB(255, 255, 255, 255);
  bool _eraseMode = false;
  bool _isEmpty = true;
  bool _isUndoPathEmpty = true;

  double _thickness = 1.0;
  PictureDetails? _cached;
  _PathHistory _pathHistory;
  ValueGetter<Size>? _widgetFinish;

  // Mapdataから取得した高さ.
  double _heightFromMapData = 0;

  /// [Painter] ウィジェットで使用するために新しいインスタンスを作成する。
  PainterController() : _pathHistory = new _PathHistory();

  /// 高さの取得.
  double get heightFromMapData => _heightFromMapData;

  /// まだ何も描画されていない場合、true を返す。
  bool get isEmpty => _pathHistory.isEmpty;

  bool get isUndoPathEmpty => _pathHistory.isUndoPathEmpty;

  set isEmpty(bool enabled) {
    _isEmpty = enabled;
  }

  set isUndoPathEmpty(bool enabled) {
    _isUndoPathEmpty = enabled;
  }

  /// [PainterController] が現在消去モードである場合に true を返します。
  /// それ以外の場合は false を返します。
  bool get eraseMode => _eraseMode;

  /// true に設定すると、false で再度呼び出されるまで、消去モードが有効になります。
  set eraseMode(bool enabled) {
    _eraseMode = enabled;

    _updatePaint();
  }

  // set isEmpty(bool enabled) {
  //   _pathHistory.isEmpty = enabled;
  //   _updatePaint();
  // }

  /// 現在の描画色を取得する。
  Color get drawColor => _drawColor;

  /// 描画色を設定します。
  set drawColor(Color color) {
    _drawColor = color;
    _updatePaint();
  }

  /// 現在の背景色を取得する。
  Color get backgroundColor => _backgroundColor;

  /// 背景色を更新する。
  set backgroundColor(Color color) {
    _backgroundColor = color;
    _updatePaint();
  }

  /// 描画に使用される現在の厚さを返します。
  double get thickness => _thickness;

  /// 描画の太さを設定します。
  set thickness(double t) {
    _thickness = t;
    _updatePaint();
  }

  /// 保存用情報を取得.
  Map<String, dynamic> toMap() {
    late double lowestPathPoint = 0;
    late double highestPathPoint = double.infinity;
    for (var i = 0; i < _pathHistory._paths.length; i++) {
      final paint = _pathHistory._paths[i].value;
      for (final offset in _pathHistory._offsets[i]) {
        if (offset.dy - paint.strokeWidth / 2 < highestPathPoint) {
          highestPathPoint =
              offset.dy - paint.strokeWidth / 2; // より小さい値が見つかれば更新
        }
        //下向きの高さの最大値
        if (lowestPathPoint < offset.dy + paint.strokeWidth / 2) {
          lowestPathPoint = offset.dy + paint.strokeWidth / 2;
        }
      }
    }

    final listResult = [];
    for (var i = 0; i < _pathHistory._paths.length; i++) {
      final paint = _pathHistory._paths[i].value;
      final listType = ListType(paint);
      for (final offset in _pathHistory._offsets[i]) {
        listType.addOffset(offset);
        // if (offset.dy - paint.strokeWidth / 2 < highestPathPoint) {
        //   highestPathPoint =
        //       offset.dy - paint.strokeWidth / 2; // より小さい値が見つかれば更新
        // }
      }

      listResult.add(listType.toMap(highestPathPoint));
    }

    /// 高さを↑で計算して↓でセット.
    return {
      'height': lowestPathPoint - highestPathPoint + 16,
      'list': listResult,
    };
  }

  /// 保存用情報から復元新旧フォーマット対応版.
  PainterController fromMetaData(dynamic metadata) =>
      (metadata is List) ? fromList(metadata) : fromMap(metadata);

  /// 保存用情報から復元旧フォーマットのデータがない環境では不要 .
  PainterController fromList(List<dynamic> list) => fromMap({
        'height': 77, // エラー回避のため旧データは仮で77で固定.
        'list': list,
      });

  /// 保存用情報から復元新フォーマット .
  PainterController fromMap(Map<String, dynamic> mapMetadata) {
    _heightFromMapData = mapMetadata['height'].toDouble();

    // CustomPaint fromList(List<dynamic> list) {
    for (final Map<String, dynamic> map in mapMetadata['list']) {
      final listType = ListType.fromMap(map);
      final paint = listType.getPaint();
      drawColor = paint.color;
      thickness = paint.strokeWidth;
      _pathHistory.currentPaint = paint;
      var isAdded = false;
      for (final offset in listType.getOffsetList()) {
        if (isAdded) {
          _pathHistory.updateCurrent(offset);
        } else {
          _pathHistory.add(offset);
          isAdded = true;
        }
      }
      _pathHistory.endCurrent();
    }
    isEmpty = false;
    _notifyListeners();
    return this;
  }

  void _updatePaint() {
    final paint = Paint();
    if (_eraseMode) {
      paint.blendMode = BlendMode.clear;
      paint.color = const Color.fromARGB(0, 255, 0, 0);
    } else {
      paint.color = drawColor;
      paint.blendMode = BlendMode.srcOver;
    }
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = thickness;
    paint.strokeCap = StrokeCap.round;
    paint.strokeJoin = StrokeJoin.round;
    _pathHistory.currentPaint = paint;
    _pathHistory.setBackgroundColor(backgroundColor);
    notifyListeners();
  }

  /// 最後の描画動作を元に戻す（ただし、背景色の変更は不可）。
  /// 画像がすでに完成している場合は、この操作は無効で何も行いません。
  void undo() {
    if (!isFinished()) {
      print('undo実行');
      _pathHistory.undo();
      notifyListeners();
    }
  }

  void redo() {
    if (!isFinished()) {
      _pathHistory.redo();
      notifyListeners();
    }
  }

  void _notifyListeners() {
    notifyListeners();
  }

  /// すべての描画アクションを削除しますが、背景には影響を与えません。
  /// 画像がすでに完成している場合は、この操作は無効で何も行いません。
  void clear() {
    if (!isFinished()) {
      _pathHistory.clear();
      notifyListeners();
    }
  }

  /// 描画を終了し、描画された[PictureDetails]を返します。
  /// 描画はキャッシュされ、以後このメソッドを呼び出すと、キャッシュされた
  /// 描画が返されます。
  ///
  /// This might throw a [StateError] if this PainterController is not attached
  /// to a widget, or the associated widget's [Size.isEmpty].
  /// この PainterController がウィジェットに接続されていない場合、[StateError] が
  /// スローされることがあります。がウィジェットに接続されていない場合、
  /// または関連するウィジェットの [Size.isEmpty] の場合、[State Error] をスローします。
  PictureDetails finish() {
    if (!isFinished()) {
      if (_widgetFinish != null) {
        _cached = _render(_widgetFinish!());
      } else {
        throw new StateError(
          'Called finish on a PainterController that was not connected to a widget yet!',
        );
      }
    }
    return _cached!;
  }

  PictureDetails _render(Size size) {
    if (size.isEmpty) {
      throw new StateError('Tried to render a picture with an invalid size!');
    } else {
      final PictureRecorder recorder = new PictureRecorder();
      final Canvas canvas = new Canvas(recorder);
      _pathHistory.draw(canvas, size);
      return new PictureDetails(
        recorder.endRecording(),
        size.width.floor(),
        size.height.floor(),
      );
    }
  }

  /// この描画が終了した場合、true を返す。
  ///
  /// Trying to modify a finished drawing is a no-op.
  bool isFinished() {
    return _cached != null;
  }
}

/// 保存・復元時のList用クラス.
class ListType {
  ListType(Paint paint) {
    setPaint(paint);
  }
  ListType.fromMap(Map<String, dynamic> map) {
    _paint = ListTypePaint.fromMap(map['paint']);
    for (Map<String, dynamic> offsetMap in map['offsetList']) {
      _offsetList.add(ListTypeOffset.fromMap(offsetMap));
    }
  }

  ListTypePaint? _paint;
  final List<ListTypeOffset> _offsetList = [];

  Paint getPaint() => _paint!.toPaint();

  void setPaint(Paint paint) {
    _paint = ListTypePaint(paint);
  }

  List<Offset> getOffsetList() {
    final offsetList = <Offset>[];
    for (final offset in _offsetList) {
      offsetList.add(offset.toOffset());
    }
    return offsetList;
  }

  void addOffset(Offset offset) {
    _offsetList.add(ListTypeOffset(offset));
  }

  Map<String, dynamic> toMap(double highestPathPoint) {
    final offsetMap = [];
    for (var offset in _offsetList) {
      offsetMap.add(offset.toMap(highestPathPoint));
    }
    return {
      'paint': _paint!.toMap(),
      'offsetList': offsetMap,
    };
  }
}

/// 保存・復元時のList用Paintサブクラス.
class ListTypePaint {
  ListTypePaint(Paint paint) {
    _color = paint.color;
    _strokeWidth = paint.strokeWidth;
    _strokeCap = paint.strokeCap;
    _strokeJoin = paint.strokeJoin;
    _style = paint.style;
    _blendMode = paint.blendMode;
  }

  ListTypePaint.fromMap(Map<String, dynamic> map) {
    if (map.containsKey('color')) {
      _color = Color(map['color']);
    }
    if (map.containsKey('strokeWidth')) {
      _strokeWidth = map['strokeWidth'].toDouble();
    }
    if (map.containsKey('strokeCap')) {
      _strokeCap = StrokeCap.values.byName(map['strokeCap']);
    }
    if (map.containsKey('strokeJoin')) {
      _strokeJoin = StrokeJoin.values.byName(map['strokeJoin']);
    }
    if (map.containsKey('style')) {
      _style = PaintingStyle.values.byName(map['style']);
    }
    if (map.containsKey('blendMode')) {
      _blendMode = BlendMode.values.byName(map['blendMode']);
    }
  }

  Color _color = Colors.black;
  double _strokeWidth = 2.0;
  StrokeCap _strokeCap = StrokeCap.round;
  StrokeJoin _strokeJoin = StrokeJoin.round;
  PaintingStyle _style = PaintingStyle.fill;
  BlendMode _blendMode = BlendMode.srcOver;

  Paint toPaint() {
    final paint = Paint();
    paint.color = _color;
    paint.strokeWidth = _strokeWidth;
    paint.strokeCap = _strokeCap;
    paint.strokeJoin = _strokeJoin;
    paint.style = _style;
    paint.blendMode = _blendMode;
    return paint;
  }

  Map<String, dynamic> toMap() => {
        'color': _color.value,
        'strokeWidth': _strokeWidth.toDouble(),
        'strokeCap': _strokeCap.name,
        'strokeJoin': _strokeJoin.name,
        'style': _style.name,
        'blendMode': _blendMode.name,
      };
}

/// 保存・復元時のList用Offsetサブクラス.
class ListTypeOffset {
  ListTypeOffset(Offset offset) {
    _dx = offset.dx;
    _dy = offset.dy;
  }
  ListTypeOffset.fromMap(Map<String, dynamic> map) {
    _dx = map['dx']!;
    _dy = map['dy']!;
  }

  double _dx = 0;
  double _dy = 0;

  Offset toOffset() => Offset(_dx, _dy);

  Map<String, double> toMap(double highestPathPoint) =>
      {'dx': _dx, 'dy': _dy - highestPathPoint + 8};
}
