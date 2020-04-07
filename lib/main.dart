import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(),
        body: Center(
          child: StickyTag(),
        ),
      ),
    );
  }
}

class StickyTag extends StatefulWidget {
  final double maxContactDistance;
  final double size;
  final Color color;

  const StickyTag({Key key, this.maxContactDistance: 300, this.size: 30, this.color:Colors.red})
      : super(key: key);

  @override
  _StickyTagState createState() => _StickyTagState();
}

class _StickyTagState extends State<StickyTag> {
  Offset _touchPosition;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanEnd: (e) {
        setState(() {});
      },
      onPanUpdate: (e) {
        setState(() {
          _touchPosition = e.localPosition;
        });
      },
      child: Container(
        height: widget.size,
        width: widget.size,
        color: Colors.black,
        child: CustomPaint(
          painter: _StickyTagPainter(_touchPosition, widget.maxContactDistance,widget.color),
        ),
      ),
    );
  }
}

class _StickyTagPainter extends CustomPainter {
  Offset endPointer;
  double maxDistance;
  final Color color;

  double _smallPointerSize;
  double _distance;
  double _slantRange; //倾斜角大小

  _StickyTagPainter(this.endPointer, this.maxDistance, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    double bigPointerSize = min(size.width, size.height) / 2;
    Offset c = Offset(size.width / 2, size.height / 2);
    endPointer ??= c;
    double distanceX = endPointer.dx; // X轴上的偏移量
    double distanceY = endPointer.dy; // y轴上的偏移量
    _slantRange = atan(distanceX / distanceY);
    _distance = sqrt(distanceX * distanceX + distanceY * distanceY);
    _smallPointerSize = bigPointerSize * (1 - _distance / maxDistance);

    Offset bezierContorlNode =
        Offset(endPointer.dx / 2, endPointer.dy / 2); // 贝塞尔曲线控制点的位置
    double startArmDx = cos(_slantRange) * _smallPointerSize;
    double startArmDy = sin(_slantRange) * _smallPointerSize;
    Offset startPoint1 = Offset(
      startArmDx,
      -startArmDy,
    );

    Offset startPoint2 = Offset(-startArmDx, startArmDy);
    double endArmDx = cos(_slantRange) * bigPointerSize;
    double endArmDy = sin(_slantRange) * bigPointerSize;
    Offset endPoint1 = Offset(
      endArmDx + endPointer.dx,
      -endArmDy + endPointer.dy,
    );
    Offset endPoint2 =
        Offset(-endArmDx + endPointer.dx, endArmDy + endPointer.dy);

    Paint paint = Paint()
      ..color = this.color;

    canvas.translate(c.dx, c.dy); // 把canvas原点移到中间
    canvas.drawCircle(Offset(0, 0), _smallPointerSize, paint); // 绘制小圆
    canvas.drawCircle(endPointer, bigPointerSize, paint); // 绘制大圆

    Path path = Path()
      ..moveTo(startPoint1.dx, startPoint1.dy)
      ..lineTo(startPoint2.dx, startPoint2.dy)
      ..quadraticBezierTo(bezierContorlNode.dx, bezierContorlNode.dy,
          endPoint2.dx, endPoint2.dy)
      ..lineTo(endPoint1.dx, endPoint1.dy)
      ..quadraticBezierTo(bezierContorlNode.dx, bezierContorlNode.dy,
          startPoint1.dx, startPoint1.dy);
    canvas.drawPath(path, paint);  // 绘制粘性区域
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
