import 'package:flutter/material.dart';
import 'package:test_some_features/side_bar.dart';

class CustomManagementSystem extends StatefulWidget {
  const CustomManagementSystem({
    super.key,
    this.appBar,
    this.sideBar,
    required this.body,
    this.backgroundColor,
    this.mobileThreshold = 768.0,
  });

  final AppBar? appBar;
  final SideBar? sideBar;
  final Widget body;
  final Color? backgroundColor;
  final double mobileThreshold;

  @override
  State<CustomManagementSystem> createState() => _CustomManagementSystemState();
}

class _CustomManagementSystemState extends State<CustomManagementSystem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation _animation;
  bool _isMobile = false;
  bool _isOpenSidebar = false;
  bool _canDragged = false;
  double _screenWidth = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutQuad,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.of(context);
    if (_screenWidth == mediaQuery.size.width) {
      return;
    }

    setState(() {
      _isMobile = mediaQuery.size.width < widget.mobileThreshold;
      _isOpenSidebar = !_isMobile;
      _animationController.value = _isMobile ? 0 : 1;
      _screenWidth = mediaQuery.size.width;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isOpenSidebar = !_isOpenSidebar;
      if (_isOpenSidebar) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _onDragStart(DragStartDetails details) {
    final isClosed = _animationController.isDismissed;
    final isOpen = _animationController.isCompleted;
    _canDragged = (isClosed && details.globalPosition.dx < 60) || isOpen;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_canDragged) {
      final delta =
          (details.primaryDelta ?? 0.0) / (widget.sideBar?.width ?? 1.0);
      _animationController.value += delta;
    }
  }

  void _dragCloseDrawer(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0.0;
    if (delta < 0) {
      _isOpenSidebar = false;
      _animationController.reverse();
    }
  }

  void _onDragEnd(DragEndDetails details) async {
    const minFlingVelocity = 365.0;

    if (details.velocity.pixelsPerSecond.dx.abs() >= minFlingVelocity) {
      final visualVelocity =
          details.velocity.pixelsPerSecond.dx / (widget.sideBar?.width ?? 1.0);

      await _animationController.fling(velocity: visualVelocity);
      if (_animationController.isCompleted) {
        setState(() {
          _isOpenSidebar = true;
        });
      } else {
        setState(() {
          _isOpenSidebar = false;
        });
      }
    } else {
      if (_animationController.value < 0.5) {
        _animationController.reverse();
        setState(() {
          _isOpenSidebar = false;
        });
      } else {
        _animationController.forward();
        setState(() {
          _isOpenSidebar = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: AnimatedBuilder(
        animation: _animation,
        builder: (_, __) =>
        widget.sideBar == null
            ? Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: widget.body,
                    ),
                  ),
                ],
              )
            : _isMobile
                ? Stack(
                    children: [
                      GestureDetector(
                        onHorizontalDragStart: _onDragStart,
                        onHorizontalDragUpdate: _onDragUpdate,
                        onHorizontalDragEnd: _onDragEnd,
                      ),
                      widget.body,
                      if (_animation.value > 0)
                        Container(
                          color: Colors.black
                              .withAlpha((150 * _animation.value).toInt()),
                        ),
                      if (_animation.value == 1)
                        GestureDetector(
                          onTap: _toggleSidebar,
                          onHorizontalDragUpdate: _dragCloseDrawer,
                        ),
                      ClipRect(
                        child: SizedOverflowBox(
                          size: Size(
                              (widget.sideBar?.width ?? 1.0) * _animation.value,
                              double.infinity),
                          child: widget.sideBar,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      widget.sideBar != null
                          ? ClipRect(
                              child: SizedOverflowBox(
                                size: Size(
                                    (widget.sideBar?.width ?? 1.0) *
                                        _animation.value,
                                    double.infinity),
                                child: widget.sideBar,
                              ),
                            )
                          : const SizedBox(),

                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: widget.body,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

// final leading = sideBar != null
//       ? IconButton(
//     icon: const Icon(Icons.menu),
//     onPressed: _toggleSidebar,
//   )
//
}
