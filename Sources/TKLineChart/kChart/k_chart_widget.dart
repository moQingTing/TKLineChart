import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'chart_style.dart';
import 'entity/info_window_entity.dart';
import 'entity/k_line_entity.dart';
import 'renderer/chart_painter.dart';
import 'utils/data_util.dart';
import 'utils/date_format_util.dart';
import 'utils/number_util.dart';

enum MainState { ma, boll, none }

extension MainStateEx on MainState {
  String get name {
    switch (this) {
      case MainState.ma:
        return 'ma';
      case MainState.boll:
        return 'boll';
      case MainState.none:
        return 'none';
    }
  }
}

// enum VolState { vol, none }
enum SecondaryState { macd, kdj, rsi, wr, vol }

extension SecondaryStateEx on SecondaryState {
  String get name {
    switch (this) {
      case SecondaryState.macd:
        return 'macd';
      case SecondaryState.kdj:
        return 'kdj';
      case SecondaryState.rsi:
        return 'rsi';
      case SecondaryState.wr:
        return 'wr';
      case SecondaryState.vol:
        return 'vol';
    }
  }
}

class KChartWidget extends StatefulWidget {
  final List<KLineEntity>? datas;
  final MainState mainState;
  final bool isLine;
  final ChartColors chartColors;
  final ChartStyle chartStyle;
  final List<SecondaryState> secondaryStates;

  KChartWidget(this.datas,
      {super.key,
      this.mainState = MainState.none,
      required this.chartColors,
      required this.chartStyle,
      required this.secondaryStates,
      this.isLine = false,
      int fractionDigits = 2}) {
    NumberUtil.fractionDigits = fractionDigits;
  }

  @override
  KChartWidgetState createState() => KChartWidgetState();
}

class KChartWidgetState extends State<KChartWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double mScaleX = 1.0, mScrollX = 0.0, mSelectX = 0.0;
  late StreamController<InfoWindowEntity?> mInfoWindowStream;
  double mWidth = 0;

  late AnimationController _scrollXController;
  bool _isDisposed = false;

  double getMinScrollX() {
    return mScaleX;
  }

  double _lastScale = 1.0;
  bool isScale = false, isDrag = false, isLongPress = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('KChartWidgetState initState $mScrollX');
    }
    mInfoWindowStream = StreamController();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 850), vsync: this);

    _animation = Tween(begin: 0.9, end: 0.1).animate(_controller)
      ..addListener(() {
        if (!_isDisposed) {
          setState(() {});
        }
      });

    _scrollXController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 100),
        lowerBound: double.negativeInfinity,
        upperBound: double.infinity);
    _scrollListener();
  }

  void _scrollListener() {
    if (_isDisposed) return;

    _scrollXController.addListener(() {
      if (_isDisposed) return;

      mScrollX = _scrollXController.value;
      if (mScrollX <= 0) {
        mScrollX = 0;
        _stopAnimation();
      } else if (mScrollX >= ChartPainter.maxScrollX) {
        mScrollX = ChartPainter.maxScrollX;
        _stopAnimation();
      } else {
        notifyChanged();
      }
    });

    _scrollXController.addStatusListener((status) {
      if (_isDisposed) return;

      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        isDrag = false;
        notifyChanged();
      }
    });
  }

  void _stopAnimation() {
    if (_isDisposed) return;

    if (_scrollXController.isAnimating) {
      _scrollXController.stop();
      isDrag = false;
      notifyChanged();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDisposed) {
      mWidth = MediaQuery.of(context).size.width;
    }
  }

  @override
  void didUpdateWidget(KChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDisposed && oldWidget.datas != widget.datas) {
      mScrollX = mSelectX = 0.0;
      mScaleX = 1.0;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    mInfoWindowStream.close();
    _controller.dispose();
    _scrollXController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      // print('mScrollX $mScrollX');
    }
    if (widget.datas == null) {
      mScrollX = mSelectX = 0.0;
      mScaleX = 1.0;
    }

    return RawGestureDetector(
      gestures: {
        // 为了解决缩放和水平滚动冲突
        CustomScaleGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<CustomScaleGestureRecognizer>(
          () =>
              CustomScaleGestureRecognizer(_shouldInterceptParentScrollByScale),
          (CustomScaleGestureRecognizer instance) {
            instance
              ..onStart = _onScaleStart
              ..onUpdate = _onScaleUpdate
              ..onEnd = _onScaleEnd;
          },
        ),
        // 为了解决缩放和水平滚动冲突
        CustomHorizontalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
                CustomHorizontalDragGestureRecognizer>(
          () => CustomHorizontalDragGestureRecognizer(
              __shouldInterceptParentScrollByDrag),
          (CustomHorizontalDragGestureRecognizer instance) {
            instance
              ..onDown = _onHorizontalDragDown
              ..onUpdate = _onHorizontalDragUpdate
              ..onEnd = _onHorizontalDragEnd
              ..onCancel = _onHorizontalDragCancel;
          },
        ),
        CustomLongGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<CustomLongGestureRecognizer>(
                () => CustomLongGestureRecognizer(),
                (CustomLongGestureRecognizer instance) {
          instance
            ..onLongPressStart = _onLongPressStart
            ..onLongPressMoveUpdate = _onLongPressMoveUpdate
            ..onLongPressEnd = _onLongPressEnd;
        })
      },
      child: Listener(
        onPointerSignal: (PointerSignalEvent event) {
          if (event is PointerScrollEvent) {
            // Handle horizontal scroll
            _onHorizontalDragUpdate(DragUpdateDetails(
              delta: Offset(event.scrollDelta.dx, 0),
              primaryDelta: event.scrollDelta.dx,
              globalPosition: event.position,
            ));
          }
        },
        child: Stack(
          children: <Widget>[
            CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: ChartPainter(
                  chartStyle: widget.chartStyle,
                  chartColors: widget.chartColors,
                  secondaryStates: widget.secondaryStates,
                  datas: widget.datas,
                  scaleX: mScaleX,
                  scrollX: mScrollX,
                  selectX: mSelectX,
                  isLongPass: isLongPress,
                  mainState: widget.mainState,
                  isLine: widget.isLine,
                  sink: mInfoWindowStream.sink,
                  opacity: _animation.value,
                  controller: _controller),
            ),
            _buildInfoDialog()
          ],
        ),
      ),
    );
  }

  void notifyChanged() {
    if (!_isDisposed) {
      setState(() {});
    }
  }

  // List<String> infoNames = ["Date", "Open", "High", "Low", "Close", "Change", "Change%", "Vol"];
  List<String> infoNames = [
    "Date",
    "Open",
    "High",
    "Low",
    "Close",
    "Change%",
    "Vol"
  ];

  Widget _buildInfoDialog() {
    return StreamBuilder<InfoWindowEntity?>(
        stream: mInfoWindowStream.stream,
        builder: (context, snapshot) {
          if (!isLongPress ||
              widget.isLine == true ||
              !snapshot.hasData ||
              snapshot.data == null) {
            return Container();
          }
          List? infos;
          KLineEntity entity = snapshot.data!.kLineEntity;
          double upDown = entity.close - entity.open;
          double upDownPercent = upDown / entity.open * 100;
          infos ??= [
            DataUtil.getDate(entity.id),
            NumberUtil.format(entity.open),
            NumberUtil.format(entity.high),
            NumberUtil.format(entity.low),
            NumberUtil.format(entity.close),
            // "${upDown > 0 ? "+" : ""}${NumberUtil.format(upDown)}",
            "${upDownPercent > 0 ? "+" : ''}${upDownPercent.toStringAsFixed(2)}%",
            NumberUtil.volFormat(entity.vol)
          ];
          return Align(
            alignment:
                snapshot.data!.isLeft ? Alignment.topLeft : Alignment.topRight,
            child: Container(
              margin: const EdgeInsets.only(left: 10, right: 10, top: 25),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                  color: widget.chartColors.markerBgColor,
                  border: Border.all(
                      color: widget.chartColors.markerBorderColor, width: 0.5)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(infoNames.length,
                    (i) => _buildItem(infos![i].toString(), infoNames[i])),
              ),
            ),
          );
        });
  }

  Widget _buildItem(String info, String infoName) {
    Color color = Colors.white;
    if (info.startsWith("+")) {
      color = widget.chartColors.upColor;
    } else if (info.startsWith("-")) {
      color = widget.chartColors.dnColor;
    } else {
      color = Colors.white;
    }
    return Container(
      constraints: const BoxConstraints(
          minWidth: 95, maxWidth: 110, maxHeight: 14.0, minHeight: 14.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(infoName,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.chartStyle.defaultTextSize)),
          const SizedBox(width: 5),
          Text(info,
              style: TextStyle(
                  color: color, fontSize: widget.chartStyle.defaultTextSize)),
        ],
      ),
    );
  }

  void _onHorizontalDragDown(DragDownDetails details) {
    if (kDebugMode) {
      print('KChartWidgetState onHorizontalDragDown');
    }
    _stopAnimation();
    isDrag = true;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (kDebugMode) {
      print('KChartWidgetState onHorizontalDragUpdate');
    }
    if (isLongPress) return;
    mScrollX = (details.primaryDelta! / mScaleX + mScrollX)
        .clamp(0.0, ChartPainter.maxScrollX)
        .toDouble();
    notifyChanged();
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (kDebugMode) {
      print('KChartWidgetState onHorizontalDragEnd');
    }
    isDrag = false;
    final Tolerance tolerance = Tolerance(
      velocity: 1.0 / (0.050 * WidgetsBinding.instance.window.devicePixelRatio),
      // logical pixels per second
      distance: 1.0 /
          WidgetsBinding.instance.window.devicePixelRatio, // logical pixels
    );
    if (details.primaryVelocity == null) return;
    ClampingScrollSimulation simulation = ClampingScrollSimulation(
      position: mScrollX,
      velocity: details.primaryVelocity!,
      tolerance: tolerance,
    );
    _scrollXController.animateWith(simulation);
  }

  void _onHorizontalDragCancel() {
    isDrag = false;
  }

  void _onLongPressStart(LongPressStartDetails details) {
    isLongPress = true;
    if (mSelectX != details.globalPosition.dx) {
      mSelectX = details.globalPosition.dx;
      notifyChanged();
    }
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (mSelectX != details.globalPosition.dx) {
      mSelectX = details.globalPosition.dx;
      notifyChanged();
    }
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    isLongPress = false;
    mInfoWindowStream.add(null);
    notifyChanged();
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (kDebugMode) {
      print('KChartWidgetState onScaleStart');
    }
    // if(isDrag)return;
    isScale = true;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (kDebugMode) {
      print('KChartWidgetState onScaleUpdate');
    }
    // if (isDrag || isLongPress) return;
    if (details.scale > 0) {
      mScaleX = (_lastScale * details.scale).clamp(0.5, 2.2);
      notifyChanged();
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (kDebugMode) {
      print('KChartWidgetState onScaleEnd');
    }
    _lastScale = mScaleX;
    isScale = false;
  }

  bool _shouldInterceptParentScrollByScale() {
    //拦截父组件的滚动
    return isScale;
  }

  bool __shouldInterceptParentScrollByDrag() {
    //拦截父组件的滚动
    return isDrag;
  }
}

class CustomScaleGestureRecognizer extends ScaleGestureRecognizer {
  final bool Function() shouldInterceptParentScroll;
  CustomScaleGestureRecognizer(this.shouldInterceptParentScroll);

  @override
  void rejectGesture(int pointer) {
    // 解决了缩放和水平滚动时父组件也滚动问题，但是缩放有时就不起效了
    // if(shouldInterceptParentScroll()){
    //   if (kDebugMode) {
    //     print('shouldInterceptParentScroll Scale ${shouldInterceptParentScroll()}');
    //   }
    //   super.rejectGesture(pointer);
    // }else{
    //   acceptGesture(pointer);
    // }
    acceptGesture(pointer);
  }
}

class CustomHorizontalDragGestureRecognizer
    extends HorizontalDragGestureRecognizer {
  final bool Function() shouldInterceptParentScroll;

  CustomHorizontalDragGestureRecognizer(this.shouldInterceptParentScroll);

  @override
  void rejectGesture(int pointer) {
    // 解决了缩放和水平滚动时父组件也滚动问题，但是缩放有时就不起效了
    // if(shouldInterceptParentScroll()){
    //   if (kDebugMode) {
    //     print('shouldInterceptParentScroll Drag ${shouldInterceptParentScroll()}');
    //   }
    //   super.rejectGesture(pointer);
    // }else{
    //   acceptGesture(pointer);
    // }

    acceptGesture(pointer);
  }
}

class CustomLongGestureRecognizer extends LongPressGestureRecognizer {
  CustomLongGestureRecognizer();
}
