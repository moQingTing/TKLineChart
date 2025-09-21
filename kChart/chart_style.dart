import 'package:flutter/material.dart' show Color, Colors;

import '../../common/style/app_color.dart';

class ChartColors {
  /// 暗模式
  final bool isDarkMode;

  ChartColors(this.isDarkMode);

  //背景颜色
  Color get bgColor =>
      isDarkMode ? const Color(0xff131723) : const Color(0xffffffff);

  /// 曲线颜色
  Color get kLineColor => const Color(0xff38E5CC);

  /// yx轴交叉线颜色
  Color get xyLineColor => Colors.grey.withOpacity(0.5);

  // 网格线颜色
  Color get gridColor => Colors.grey.withOpacity(0.2);

  //曲线阴影渐变颜色
  List<Color> get kLineShadowColor => [
    kLineColor.withOpacity(0.6),
    kLineColor.withOpacity(0.1)
      ];

  /// ma5 颜色
  Color get ma5Color => Colors.yellow.withOpacity(0.6);

  Color get ma10Color => Colors.pink.withOpacity(0.6);

  Color get ma30Color => Colors.deepPurple.withOpacity(0.6);

  Color get upColor => const Color(0xff38E5CC);

  Color get dnColor => const Color(0xFFFC6060);

  Color get volColor => const Color(0xff4729AE);

  Color get macdColor => const Color(0xff4729AE);

  Color get difColor => const Color(0xffC9B885);

  Color get deaColor => const Color(0xff6CB0A6);

  Color get kColor => const Color(0xffC9B885);

  Color get dColor => const Color(0xff6CB0A6);

  Color get jColor => const Color(0xff9979C6);

  Color get rsiColor => const Color(0xffC9B885);

  //右边y轴刻度
  Color get yAxisTextColor => const Color(0xff60738E);

  //下方时间刻度
  Color get xAxisTextColor => const Color(0xff60738E);

  //最大最小值的颜色
  Color get maxMinTextColor => const Color(0xff60738E);

  //深度颜色
  Color get depthBuyColor => const Color(0xff38E5CC);

  Color get depthSellColor => const Color(0xFFFC6060);

  /// 深度渐变颜色
  List<Color> get depthSellColors => [
        const Color(0xFFFC6060).withAlpha(20),
        const Color(0xFFFC6060).withAlpha(1)
      ];
  List<Color> get depthBuyColors =>
      [const Color(0xff38E5CC).withAlpha(20), const Color(0xff38E5CC).withAlpha(1)];

  /// 深度字体颜色
  Color get depthTextColor => Colors.black;

  //选中后显示值边框颜色
  Color get markerBorderColor => const Color(0xff6C7A86);

  //选中后显示值背景的填充颜色
  Color get markerBgColor => const Color(0xff0D1722);

  //实时线颜色等
  Color get realTimeBgColor =>kLineColor;

  Color get rightRealTimeTextColor => const Color(0xffffffff);

  Color get realTimeTextBorderColor => const Color(0xff6C7A86);

  Color get realTimeTextColor => const Color(0xffffffff);

  //实时线
  Color get realTimeLineColor => kLineColor;

  Color get realTimeLongLineColor => kLineColor;

  /// 闪点颜色
  Color get pointColor => Colors.white;
}

class ChartStyle {
  ChartStyle();

  //点与点的距离
  double pointWidth = 8.0;

  //蜡烛宽度
  double candleWidth = 6.0;

  //蜡烛中间线的宽度
  double candleLineWidth = .8;

  //vol柱子宽度
  double volWidth = 6.5;

  //macd柱子宽度
  double macdWidth = 6.5;

  //垂直交叉线宽度
  double vCrossWidth = 0.5;

  //水平交叉线宽度
  double hCrossWidth = 0.5;

  //网格
  int gridRows = 2, gridColumns = 3;

  //网格线宽
  double gridStrokeWidth = 0.5;

  double topPadding = 15.0, bottomDateHigh = 15.0, childPadding = 15.0;

  double defaultTextSize = 8.0;

  /// 曲线宽度
  double lineStrokeWidth = 1.0;

  /// 虚线宽度
  double dashWidth = 4.0;

  /// 虚线之间间距
  double dashSpace = 4.0;

  /// 是否显示虚线
  bool isShowDashLine = true;
}

class TradeKlineChartStyle extends ChartStyle {
  @override
  double get lineStrokeWidth => 2.0;

  @override
  bool get isShowDashLine => false;
}
