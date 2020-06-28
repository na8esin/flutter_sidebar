import 'package:flutter/material.dart';

import 'package:flutter_sidebar/flutter_sidebar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const title = 'Flutter Sidebar Test';

    return MaterialApp(
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  static const _mobileThreshold = 700.0;
  bool isMobile = false;
  bool sidebarOpen = false;
  bool canBeDragged = false;

  AnimationController _animationController;
  Animation _animation;

  final List<Map<String, dynamic>> tabData = [
    {
      'title': 'Chapter A',
      'children': [
        {'title': 'Chapter A1'},
        {'title': 'Chapter A2'},
      ],
    },
    {
      'title': 'Chapter B',
      'children': [
        {'title': 'Chapter B1'},
        {
          'title': 'Chapter B2',
          'children': [
            {'title': 'Chapter B2a'},
            {'title': 'Chapter B2b'},
          ],
        },
      ],
    },
    {'title': 'Chapter C'},
  ];
  String tab;
  void setTab(String newTab) {
    setState(() {
      tab = newTab;
    });
  }

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _animation = CurvedAnimation(
        parent: _animationController, curve: Curves.easeInOutQuad);
    Future.delayed(Duration.zero, () {
      final mediaQuery = MediaQuery.of(context);
      setState(() {
        isMobile = mediaQuery.size.width < _mobileThreshold;
        sidebarOpen = !isMobile;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      sidebarOpen = !sidebarOpen;
      if (sidebarOpen)
        _animationController.forward();
      else
        _animationController.reverse();
    });
  }

  void onDragStart(DragStartDetails details) {
    bool isClosed = _animationController.isDismissed;

    bool isOpen = _animationController.isCompleted;

    canBeDragged = (isClosed && details.globalPosition.dx < 60) || isOpen;
  }

  void onDragUpdate(DragUpdateDetails details) {
    if (canBeDragged) {
      double delta = details.primaryDelta / 300;
      _animationController.value += delta;
    }
  }

  void onDragEnd(DragEndDetails details) {
    //I have no idea what it means, copied from Drawer
    double _kMinFlingVelocity = 365.0;

    if (_animationController.isDismissed || _animationController.isCompleted) {
      return;
    }
    if (details.velocity.pixelsPerSecond.dx.abs() >= _kMinFlingVelocity) {
      double visualVelocity = details.velocity.pixelsPerSecond.dx / 300;

      _animationController.fling(velocity: visualVelocity);
    } else if (_animationController.value < 0.5) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    const _textStyle = TextStyle(fontSize: 26);
    final sidebar = Sidebar(
      tabData,
      setTab: setTab,
    );
    final mainContent = Center(
      child: tab != null
          ? Text.rich(
              TextSpan(
                text: 'Selected tab: ',
                style: _textStyle,
                children: [
                  TextSpan(
                    text: '$tab',
                    style: _textStyle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : Text(
              'No tab selected',
              style: _textStyle,
            ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.menu), onPressed: _toggleSidebar),
        title: Text('Flutter Sidebar'),
      ),
      body: AnimatedBuilder(
        animation: _animation,
        builder: (_, __) => isMobile
            ? Stack(
                children: [
                  GestureDetector(
                    onHorizontalDragStart: onDragStart,
                    onHorizontalDragUpdate: onDragUpdate,
                    onHorizontalDragEnd: onDragEnd,
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                  mainContent,
                  if (_animation.value > 0)
                    Container(
                      color: Colors.black
                          .withAlpha((150 * _animation.value).toInt()),
                    ),
                  if (_animation.value == 1)
                    GestureDetector(
                      onTap: _toggleSidebar,
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ClipRect(
                    child: SizedOverflowBox(
                      size: Size(300 * _animation.value, double.infinity),
                      child: sidebar,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  ClipRect(
                    child: SizedOverflowBox(
                      size: Size(
                          300 * _animationController.value, double.infinity),
                      child: sidebar,
                    ),
                  ),
                  Expanded(child: mainContent),
                ],
              ),
      ),
    );
  }
}
