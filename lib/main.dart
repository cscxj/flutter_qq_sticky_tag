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
  bool isShow = true;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            InkWell(
              onTap: (){
                setState(() {
                 isShow = true;
                });
              },
              child: Icon(Icons.refresh), 
            )
          ],
        ),
        body: Center(
          child: isShow
              ? StickyTag(
                  onLoosen: () {
                    setState(() {
                      isShow = false;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.all(Radius.circular(100))),
                    padding: EdgeInsets.all(6),
                    child: Text(
                      '66',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                )
              : Container(),
        ),
      ),
    );
  }
}

class StickyTag extends StatefulWidget {
  final double maxContactDistance; // 粘性区域最大长度
  final double size; // 粘性区域的大小
  final Color color; // 粘性区域的颜色
  final Widget child; // 要显示的小控件
  final Function onLoosen; // 松手事件

  const StickyTag(
      {Key key,
      this.maxContactDistance: 150,
      this.size: 30,
      this.color: Colors.red,
      this.child,
      this.onLoosen})
      : super(key: key);

  @override
  _StickyTagState createState() => _StickyTagState();
}

class _StickyTagState extends State<StickyTag> with TickerProviderStateMixin {
  Offset _touchPosition;
  AnimationController _animationController;
  Animation<Offset> _animation; // 三段回弹动画
  Animation<Offset> _animation2;
  Animation<Offset> _animation3;

  @override
  void initState() {
    super.initState();
    _touchPosition = Offset(0, 0);
  }

  @override
  void dispose() {
    super.dispose();
    _animationController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onPanEnd: (e) {
          if (_touchPosition.distance >
              widget.maxContactDistance - widget.size) {
            widget.onLoosen();
            setState(() {
              _touchPosition = Offset(0, 0);
            });
            return;
          } else {
            _animationController?.dispose();
            _animationController = AnimationController(
                vsync: this, duration: Duration(milliseconds: 300))
              ..addListener(() {
                setState(() {
                  _touchPosition =
                      _animation.value + _animation2.value + _animation3.value;
                });
              });
            _animation = Tween(begin: _touchPosition, end: -_touchPosition / 2)
                .animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(0.0, 4 / 7, curve: Curves.linear)));
            _animation2 =
                Tween(begin: Offset(0, 0), end: _touchPosition * 3 / 4).animate(
                    CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(4 / 7, 6 / 7, curve: Curves.linear)));
            _animation3 = Tween(begin: Offset(0, 0), end: -_touchPosition / 4)
                .animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(6 / 7, 1.0, curve: Curves.linear)));
            _animationController.forward();
          }
        },
        onPanUpdate: (e) {
          setState(() {
            // e.localPostion是触摸点相对控件左上角的位置，要求出相对于中心的位置
            _touchPosition = Offset(e.localPosition.dx - widget.size / 2,
                e.localPosition.dy - widget.size / 2);
          });
        },
        child: Container(
          height: widget.size,
          width: widget.size,
          child: CustomPaint(
            painter: _StickyTagPainter(
                _touchPosition, widget.maxContactDistance, widget.color),
            child: Stack(
              overflow: Overflow.visible,
              children: <Widget>[
                Positioned(
                    left: _touchPosition.dx,
                    top: _touchPosition.dy,
                    child: widget.child)
              ],
            ),
          ),
        ));
  }
}

class _StickyTagPainter extends CustomPainter {
  Offset fingerPosition;
  double maxDistance;
  final Color color;

  double _smallPointerSize;
  double _distance;
  double _slantRange; //倾斜角大小

  _StickyTagPainter(this.fingerPosition, this.maxDistance, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (fingerPosition.distance > maxDistance - size.width) {
      return;
    }
    double bigPointerSize = min(size.width, size.height) / 2;

    Offset c = Offset(size.width / 2, size.height / 2);
    fingerPosition ??= Offset(0, 0);
    double distanceX = fingerPosition.dx; // X轴上的偏移量
    double distanceY = fingerPosition.dy; // y轴上的偏移量
    _slantRange = atan(distanceX / distanceY);
    _distance = sqrt(distanceX * distanceX + distanceY * distanceY);
    _smallPointerSize = bigPointerSize * (1 - _distance / maxDistance);

    Offset bezierContorlNode =
        Offset(fingerPosition.dx / 2, fingerPosition.dy / 2); // 贝塞尔曲线控制点的位置
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
      endArmDx + fingerPosition.dx,
      -endArmDy + fingerPosition.dy,
    );
    Offset endPoint2 =
        Offset(-endArmDx + fingerPosition.dx, endArmDy + fingerPosition.dy);

    Paint paint = Paint()..color = this.color;

    canvas.translate(c.dx, c.dy); // 把canvas原点移到中间
    canvas.drawCircle(Offset(0, 0), _smallPointerSize, paint); // 绘制小圆
    canvas.drawCircle(fingerPosition, bigPointerSize, paint); // 绘制大圆

    Path path = Path()
      ..moveTo(startPoint1.dx, startPoint1.dy)
      ..lineTo(startPoint2.dx, startPoint2.dy)
      ..quadraticBezierTo(bezierContorlNode.dx, bezierContorlNode.dy,
          endPoint2.dx, endPoint2.dy)
      ..lineTo(endPoint1.dx, endPoint1.dy)
      ..quadraticBezierTo(bezierContorlNode.dx, bezierContorlNode.dy,
          startPoint1.dx, startPoint1.dy);
    canvas.drawPath(path, paint); // 绘制粘性区域
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
