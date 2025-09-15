import UIKit

// MARK: - 图表颜色配置
public class ChartColors {
    public let isDarkMode: Bool
    
    public init(isDarkMode: Bool = false) {
        self.isDarkMode = isDarkMode
    }
    
    // 背景颜色
    public var bgColor: UIColor {
        return isDarkMode ? UIColor(red: 0.075, green: 0.090, blue: 0.137, alpha: 1.0) : UIColor.white
    }
    
    // 曲线颜色
    public var kLineColor: UIColor {
        return UIColor(red: 0.220, green: 0.898, blue: 0.800, alpha: 1.0)
    }
    
    // 坐标轴交叉线颜色
    public var xyLineColor: UIColor {
        return UIColor.gray.withAlphaComponent(0.5)
    }
    
    // 网格线颜色
    public var gridColor: UIColor {
        return UIColor.gray.withAlphaComponent(0.2)
    }
    
    // 曲线阴影渐变颜色
    public var kLineShadowColors: [UIColor] {
        return [
            kLineColor.withAlphaComponent(0.6),
            kLineColor.withAlphaComponent(0.1)
        ]
    }
    
    // MA线颜色
    public var ma5Color: UIColor {
        return UIColor.yellow.withAlphaComponent(0.6)
    }
    
    public var ma10Color: UIColor {
        return UIColor.systemPink.withAlphaComponent(0.6)
    }
    
    public var ma30Color: UIColor {
        return UIColor.purple.withAlphaComponent(0.6)
    }
    
    // 涨跌颜色 - 国际标准：红涨绿跌
    public var upColor: UIColor {
        return UIColor(red: 0.988, green: 0.376, blue: 0.376, alpha: 1.0) // 红色表示上涨
    }
    
    public var downColor: UIColor {
        return UIColor(red: 0.220, green: 0.898, blue: 0.800, alpha: 1.0) // 绿色表示下跌
    }
    
    // 成交量颜色
    public var volColor: UIColor {
        return UIColor(red: 0.278, green: 0.161, blue: 0.682, alpha: 1.0)
    }
    
    // MACD颜色
    public var macdColor: UIColor {
        return UIColor(red: 0.278, green: 0.161, blue: 0.682, alpha: 1.0)
    }
    
    public var difColor: UIColor {
        return UIColor(red: 0.788, green: 0.722, blue: 0.522, alpha: 1.0)
    }
    
    public var deaColor: UIColor {
        return UIColor(red: 0.424, green: 0.690, blue: 0.651, alpha: 1.0)
    }
    
    // KDJ颜色
    public var kColor: UIColor {
        return UIColor(red: 0.788, green: 0.722, blue: 0.522, alpha: 1.0)
    }
    
    public var dColor: UIColor {
        return UIColor(red: 0.424, green: 0.690, blue: 0.651, alpha: 1.0)
    }
    
    public var jColor: UIColor {
        return UIColor(red: 0.600, green: 0.475, blue: 0.776, alpha: 1.0)
    }
    
    // RSI颜色
    public var rsiColor: UIColor {
        return UIColor(red: 0.788, green: 0.722, blue: 0.522, alpha: 1.0)
    }
    
    // 文字颜色
    public var yAxisTextColor: UIColor {
        return UIColor(red: 0.376, green: 0.451, blue: 0.557, alpha: 1.0)
    }
    
    public var xAxisTextColor: UIColor {
        return UIColor(red: 0.376, green: 0.451, blue: 0.557, alpha: 1.0)
    }

    // 选中价格文字颜色
    public var selectedPriceTextColor: UIColor {
        return UIColor.white
    }

    // 选中价格文字背景颜色
    public var selectedPriceTextBgColor: UIColor {
        return UIColor.black
    }

    public var maxMinTextColor: UIColor {
        return UIColor(red: 0.376, green: 0.451, blue: 0.557, alpha: 1.0)
    }
    
    // 深度图颜色 - 国际标准：红色买单，绿色卖单
    public var depthBuyColor: UIColor {
        return UIColor(red: 0.988, green: 0.376, blue: 0.376, alpha: 1.0) // 红色买单
    }
    
    public var depthSellColor: UIColor {
        return UIColor(red: 0.220, green: 0.898, blue: 0.800, alpha: 1.0) // 绿色卖单
    }
    
    public var depthSellColors: [UIColor] {
        return [
            UIColor(red: 0.988, green: 0.376, blue: 0.376, alpha: 0.08),
            UIColor(red: 0.988, green: 0.376, blue: 0.376, alpha: 0.004)
        ]
    }
    
    public var depthBuyColors: [UIColor] {
        return [
            UIColor(red: 0.220, green: 0.898, blue: 0.800, alpha: 0.08),
            UIColor(red: 0.220, green: 0.898, blue: 0.800, alpha: 0.004)
        ]
    }
    
    public var depthTextColor: UIColor {
        return UIColor.black
    }
    
    // 选中显示颜色
    public var markerBorderColor: UIColor {
        return UIColor(red: 0.424, green: 0.478, blue: 0.525, alpha: 1.0)
    }
    
    public var markerBgColor: UIColor {
        return UIColor(red: 0.051, green: 0.090, blue: 0.133, alpha: 1.0)
    }
    
    // 实时线颜色
    public var realTimeBgColor: UIColor {
        return kLineColor
    }
    
    public var rightRealTimeTextColor: UIColor {
        return UIColor.white
    }
    
    public var realTimeTextBorderColor: UIColor {
        return UIColor(red: 0.424, green: 0.478, blue: 0.525, alpha: 1.0)
    }
    
    public var realTimeTextColor: UIColor {
        return UIColor.white
    }
    
    public var realTimeLineColor: UIColor {
        return kLineColor
    }
    
    public var realTimeLongLineColor: UIColor {
        return kLineColor
    }
    
    // 闪点颜色
    public var pointColor: UIColor {
        return UIColor.white
    }
}

// MARK: - 图表样式配置
public class ChartStyle {
    // 点与点的距离
    public var pointWidth: Double = 8.0
    
    // 蜡烛宽度
    public var candleWidth: Double = 6.0
    
    // 蜡烛中间线的宽度
    public var candleLineWidth: Double = 0.8
    
    // 成交量柱子宽度
    public var volWidth: Double = 6.5
    
    // MACD柱子宽度
    public var macdWidth: Double = 6.5
    
    // 垂直交叉线宽度
    public var vCrossWidth: Double = 0.5
    
    // 水平交叉线宽度
    public var hCrossWidth: Double = 0.5
    
    // 网格
    public var gridRows: Int = 2
    public var gridColumns: Int = 3
    
    // 网格线宽
    public var gridStrokeWidth: Double = 0.5
    
    public var topPadding: Double = 15.0
    public var bottomDateHigh: Double = 15.0
    public var childPadding: Double = 15.0
    
    public var defaultTextSize: Double = 8.0
    
    // 曲线宽度
    public var lineStrokeWidth: Double = 1.0
    
    // 虚线宽度
    public var dashWidth: Double = 4.0
    
    // 虚线之间间距
    public var dashSpace: Double = 4.0
    
    // 是否显示虚线
    public var isShowDashLine: Bool = true
    
    // 单个副图的最大高度比例（相对于总显示高度的比例，0.0-1.0）
    // 例如：0.15 表示每个副图最多占据15%的高度
    public var singleSecondaryMaxHeightRatio: Double = 0.15
    
    public init() {}
}

// MARK: - 交易K线图样式
public class TradeKlineChartStyle: ChartStyle {
    public override var lineStrokeWidth: Double {
        get { return 2.0 }
        set { super.lineStrokeWidth = newValue }
    }
    
    public override var isShowDashLine: Bool {
        get { return false }
        set { super.isShowDashLine = newValue }
    }
}
