import UIKit

// MARK: - 图表配置管理器
public class ChartConfiguration {
    nonisolated(unsafe) public static let shared = ChartConfiguration()
    
    private init() {}
    
    // MARK: - 蜡烛样式配置
    public struct CandleStyle {
        // 蜡烛宽度
        public var width: Double = 6.0
        // 蜡烛线宽
        public var lineWidth: Double = 0.8
        // 是否实心蜡烛
        public var isSolid: Bool = true
        // 上涨颜色（红涨）
        public var upColor: UIColor = UIColor(red: 0.988, green: 0.376, blue: 0.376, alpha: 1.0)
        // 下跌颜色（绿跌）
        public var downColor: UIColor = UIColor(red: 0.220, green: 0.898, blue: 0.800, alpha: 1.0)
        // 影线颜色
        public var shadowColor: UIColor = UIColor(red: 0.376, green: 0.451, blue: 0.557, alpha: 1.0)
    }
    
    // MARK: - 移动平均线配置
    public struct MovingAverageStyle {
        // MA线颜色配置
        public var ma5Color: UIColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // 黄色
        public var ma10Color: UIColor = UIColor(red: 0.8, green: 0.0, blue: 0.8, alpha: 1.0) // 紫色
        public var ma20Color: UIColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0) // 蓝色
        public var ma30Color: UIColor = UIColor(red: 0.5, green: 0.0, blue: 0.5, alpha: 1.0) // 深紫色
        // 线宽
        public var lineWidth: Double = 1.0

        // 通用周期到颜色映射，便于按任意周期取色
        public var maColors: [Int: UIColor] {
            return [
                5: ma5Color,
                10: ma10Color,
                20: ma20Color,
                30: ma30Color,
                // 如需 MA60，可单独配置；默认复用 MA30 配色
                60: ma30Color
            ]
        }
    }

    // MARK: - 指数移动平均线配置（独立于 MA）
    public struct EMAStyle {
        // 可按周期自定义颜色
        public var colors: [Int: UIColor] = [
            5: UIColor(red: 0.95, green: 0.55, blue: 0.15, alpha: 1.0),   // 橙色
            10: UIColor(red: 0.20, green: 0.65, blue: 0.85, alpha: 1.0),  // 天蓝
            12: UIColor(red: 0.90, green: 0.25, blue: 0.25, alpha: 1.0),  // 红
            20: UIColor(red: 0.25, green: 0.80, blue: 0.45, alpha: 1.0),  // 绿
            26: UIColor(red: 0.55, green: 0.35, blue: 0.80, alpha: 1.0),  // 紫
            30: UIColor(red: 0.10, green: 0.45, blue: 0.90, alpha: 1.0),  // 蓝
            60: UIColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0)   // 灰
        ]
        public var lineWidth: Double = 1.0
    }
    
    // MARK: - 布林带配置
    public struct BollingerBandsStyle {
        // 上轨颜色
        public var upperColor: UIColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // 黄色
        // 中轨颜色
        public var middleColor: UIColor = UIColor(red: 0.8, green: 0.0, blue: 0.8, alpha: 1.0) // 紫色
        // 下轨颜色
        public var lowerColor: UIColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // 黄色
        // 线宽
        public var lineWidth: Double = 1.0
        // 填充颜色透明度
        public var fillAlpha: CGFloat = 0.1
    }
    
    // MARK: - MACD配置
    public struct MACDStyle {
        // DIF线颜色
        public var difColor: UIColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // 黄色
        // DEA线颜色
        public var deaColor: UIColor = UIColor(red: 0.8, green: 0.0, blue: 0.8, alpha: 1.0) // 紫色
        // MACD柱状图颜色（正值）
        public var positiveColor: UIColor = UIColor(red: 0.988, green: 0.376, blue: 0.376, alpha: 1.0) // 红色
        // MACD柱状图颜色（负值）
        public var negativeColor: UIColor = UIColor(red: 0.220, green: 0.898, blue: 0.800, alpha: 1.0) // 绿色
        // 线宽
        public var lineWidth: Double = 1.0
        // 柱状图宽度
        public var barWidth: Double = 6.5
    }
    
    // MARK: - KDJ配置
    public struct KDJStyle {
        // K线颜色
        public var kColor: UIColor = UIColor(red: 0.8, green: 0.0, blue: 0.8, alpha: 1.0) // 紫色
        // D线颜色
        public var dColor: UIColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // 黄色
        // J线颜色
        public var jColor: UIColor = UIColor(red: 1.0, green: 0.4, blue: 0.8, alpha: 1.0) // 粉色
        // 线宽
        public var lineWidth: Double = 1.0
    }
    
    // MARK: - RSI配置
    public struct RSIStyle {
        // RSI线颜色
        public var rsi6Color: UIColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // 黄色
        public var rsi12Color: UIColor = UIColor(red: 1.0, green: 0.4, blue: 0.8, alpha: 1.0) // 粉色
        public var rsi24Color: UIColor = UIColor(red: 0.8, green: 0.0, blue: 0.8, alpha: 1.0) // 紫色
        // 线宽
        public var lineWidth: Double = 1.0
        // 超买超卖线颜色
        public var overboughtColor: UIColor = UIColor.red.withAlphaComponent(0.3)
        public var oversoldColor: UIColor = UIColor.green.withAlphaComponent(0.3)
        // 通用周期颜色映射 + 默认周期
        public var rsiColors: [Int: UIColor] {
            return [6: rsi6Color, 12: rsi12Color, 24: rsi24Color]
        }
        public var rsiDefaultPeriod: Int = 14
    }
    
    // MARK: - 成交量配置
    public struct VolumeStyle {
        // 上涨成交量颜色
        public var upColor: UIColor = UIColor(red: 0.988, green: 0.376, blue: 0.376, alpha: 1.0) // 红色
        // 下跌成交量颜色
        public var downColor: UIColor = UIColor(red: 0.220, green: 0.898, blue: 0.800, alpha: 1.0) // 绿色
        // 柱状图宽度
        public var barWidth: Double = 6.5
        // 成交量MA线颜色
        public var ma5Color: UIColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // 黄色
        public var ma10Color: UIColor = UIColor(red: 0.8, green: 0.0, blue: 0.8, alpha: 1.0) // 紫色
        // 参数化周期颜色映射
        public var maColors: [Int: UIColor] { return [5: ma5Color, 10: ma10Color] }
    }
    
    // MARK: - OBV配置
    public struct OBVStyle {
        // OBV线颜色
        public var lineColor: UIColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // 黄色
        // 线宽
        public var lineWidth: Double = 1.0
    }
    
    // MARK: - Williams %R配置
    public struct WilliamsRStyle {
        // Williams %R线颜色
        public var lineColor: UIColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // 黄色
        // 线宽
        public var lineWidth: Double = 1.0
        // 超买超卖线颜色
        public var overboughtColor: UIColor = UIColor.red.withAlphaComponent(0.3)
        public var oversoldColor: UIColor = UIColor.green.withAlphaComponent(0.3)
    }
    
    // MARK: - 背景和网格配置
    public struct BackgroundStyle {
        // 背景颜色
        public var backgroundColor: UIColor = UIColor.white
        // 网格颜色
        public var gridColor: UIColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        // 网格线宽
        public var gridLineWidth: Double = 0.5
        // 网格行数
        public var gridRows: Int = 2
        // 网格列数
        public var gridColumns: Int = 3
    }
    
    // MARK: - 文字配置
    public struct TextStyle {
        // 文字颜色
        public var textColor: UIColor = UIColor(red: 0.376, green: 0.451, blue: 0.557, alpha: 1.0)
        // 文字大小
        public var fontSize: Double = 8.0
        // 价格文字颜色
        public var priceTextColor: UIColor = UIColor(red: 0.376, green: 0.451, blue: 0.557, alpha: 1.0)
        // 时间文字颜色
        public var timeTextColor: UIColor = UIColor(red: 0.376, green: 0.451, blue: 0.557, alpha: 1.0)
    }

    // MARK: - 信息面板本地化文本
    public struct InfoPanelTexts {
        public var time: String = "时间"
        public var open: String = "开"
        public var high: String = "高"
        public var low: String = "低"
        public var close: String = "收"
        public var change: String = "涨幅"
        public var amplitude: String = "振幅"
        public var volume: String = "量"
        public var amount: String = "额"
    }

    // MARK: - 信息面板样式
    public struct InfoPanelStyle {
        // 浅灰半透明背景
        public var backgroundColor: UIColor = UIColor(white: 0.95, alpha: 0.9)
        // 文本颜色（默认黑色）
        public var textColor: UIColor = UIColor.black
        // 圆角半径
        public var cornerRadius: Double = 8.0
        // 边框颜色（沿用现有marker边框色更统一）
        public var borderColor: UIColor = UIColor(red: 0.424, green: 0.478, blue: 0.525, alpha: 1.0)
        public init() {}
        public init(backgroundColor: UIColor, textColor: UIColor, cornerRadius: Double, borderColor: UIColor) {
            self.backgroundColor = backgroundColor
            self.textColor = textColor
            self.cornerRadius = cornerRadius
            self.borderColor = borderColor
        }
    }
    
    // MARK: - 实时数据配置
    public struct RealTimeStyle {
        // 实时线颜色
        public var lineColor: UIColor = UIColor(red: 0.220, green: 0.898, blue: 0.800, alpha: 1.0)
        // 实时线宽度
        public var lineWidth: Double = 1.0
        // 实时价格框背景色
        public var priceBoxBgColor: UIColor = UIColor.white
        // 实时价格框边框色
        public var priceBoxBorderColor: UIColor = UIColor(red: 0.424, green: 0.478, blue: 0.525, alpha: 1.0)
        // 实时价格文字颜色
        public var priceTextColor: UIColor = UIColor.black
    }
    
    // MARK: - 配置实例
    public var candleStyle = CandleStyle()
    public var movingAverageStyle = MovingAverageStyle()
    public var bollingerBandsStyle = BollingerBandsStyle()
    public var macdStyle = MACDStyle()
    public var kdjStyle = KDJStyle()
    public var rsiStyle = RSIStyle()
    public var volumeStyle = VolumeStyle()
    public var obvStyle = OBVStyle()
    public var williamsRStyle = WilliamsRStyle()
    public var backgroundStyle = BackgroundStyle()
    public var textStyle = TextStyle()
    public var realTimeStyle = RealTimeStyle()
    public var infoPanelTexts = InfoPanelTexts()
    public var infoPanelStyle = InfoPanelStyle()
    public var emaStyle = EMAStyle()
    // 数字格式：全局小数位（价格/指标等），可外部配置
    public var numberFractionDigits: Int = 2

    // MARK: - 信息面板多语言预设
    public enum InfoPanelLocalePreset {
        case zhHans   // 简体中文
        case zhHant   // 繁體中文
        case en       // English
        case ja       // 日本語
        case ko       // 한국어
    }

    public static func infoPanelPreset(_ preset: InfoPanelLocalePreset) -> InfoPanelTexts {
        switch preset {
        case .zhHans:
            return InfoPanelTexts(
                time: "时间", open: "开", high: "高", low: "低", close: "收",
                change: "涨幅", amplitude: "振幅", volume: "量", amount: "额"
            )
        case .zhHant:
            return InfoPanelTexts(
                time: "時間", open: "開", high: "高", low: "低", close: "收",
                change: "漲幅", amplitude: "振幅", volume: "量", amount: "額"
            )
        case .en:
            return InfoPanelTexts(
                time: "Time", open: "Open", high: "High", low: "Low", close: "Close",
                change: "Change", amplitude: "Amplitude", volume: "Vol", amount: "Amount"
            )
        case .ja:
            return InfoPanelTexts(
                time: "時間", open: "始値", high: "高値", low: "安値", close: "終値",
                change: "騰落", amplitude: "変動幅", volume: "出来高", amount: "金額"
            )
        case .ko:
            return InfoPanelTexts(
                time: "시간", open: "시가", high: "고가", low: "저가", close: "종가",
                change: "등락", amplitude: "변동폭", volume: "거래량", amount: "거래대금"
            )
        }
    }

    // 便捷方法：按预设切换信息面板语言
    public func applyInfoPanelLocale(_ preset: InfoPanelLocalePreset) {
        self.infoPanelTexts = ChartConfiguration.infoPanelPreset(preset)
    }
    
    // MARK: - 预设主题
    public enum Theme {
        case light
        case dark
        case binance
        case custom
    }
    
    public var currentTheme: Theme = .binance {
        didSet {
            applyTheme(currentTheme)
        }
    }
    
    // MARK: - 应用主题
    private func applyTheme(_ theme: Theme) {
        switch theme {
        case .light:
            applyLightTheme()
        case .dark:
            applyDarkTheme()
        case .binance:
            applyBinanceTheme()
        case .custom:
            break // 保持当前配置
        }
    }
    
    private func applyLightTheme() {
        backgroundStyle.backgroundColor = UIColor.white
        backgroundStyle.gridColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        textStyle.textColor = UIColor.black
        textStyle.priceTextColor = UIColor.black
        textStyle.timeTextColor = UIColor.black
    }
    
    private func applyDarkTheme() {
        backgroundStyle.backgroundColor = UIColor(red: 0.075, green: 0.090, blue: 0.137, alpha: 1.0)
        backgroundStyle.gridColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        textStyle.textColor = UIColor.white
        textStyle.priceTextColor = UIColor.white
        textStyle.timeTextColor = UIColor.white
    }
    
    private func applyBinanceTheme() {
        // 应用币安主题（基于图片分析）
        candleStyle.upColor = UIColor(red: 0.988, green: 0.376, blue: 0.376, alpha: 1.0) // 红色上涨
        candleStyle.downColor = UIColor(red: 0.220, green: 0.898, blue: 0.800, alpha: 1.0) // 绿色下跌
        candleStyle.isSolid = true // 实心蜡烛
        
        movingAverageStyle.ma5Color = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // 黄色
        movingAverageStyle.ma10Color = UIColor(red: 0.8, green: 0.0, blue: 0.8, alpha: 1.0) // 紫色
        movingAverageStyle.ma20Color = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0) // 蓝色
        
        macdStyle.difColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // 黄色
        macdStyle.deaColor = UIColor(red: 0.8, green: 0.0, blue: 0.8, alpha: 1.0) // 紫色
        macdStyle.positiveColor = UIColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 1.0) // 绿色
        macdStyle.negativeColor = UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0) // 红色
        
        kdjStyle.kColor = UIColor(red: 0.8, green: 0.0, blue: 0.8, alpha: 1.0) // 紫色
        kdjStyle.dColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // 黄色
        kdjStyle.jColor = UIColor(red: 1.0, green: 0.4, blue: 0.8, alpha: 1.0) // 粉色
        
        rsiStyle.rsi6Color = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // 黄色
        rsiStyle.rsi12Color = UIColor(red: 1.0, green: 0.4, blue: 0.8, alpha: 1.0) // 粉色
        rsiStyle.rsi24Color = UIColor(red: 0.8, green: 0.0, blue: 0.8, alpha: 1.0) // 紫色
        
        obvStyle.lineColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // 黄色
        williamsRStyle.lineColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // 黄色
        
        volumeStyle.upColor = UIColor(red: 0.988, green: 0.376, blue: 0.376, alpha: 1.0) // 红色
        volumeStyle.downColor = UIColor(red: 0.220, green: 0.898, blue: 0.800, alpha: 1.0) // 绿色
        volumeStyle.ma5Color = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // 黄色
        volumeStyle.ma10Color = UIColor(red: 0.8, green: 0.0, blue: 0.8, alpha: 1.0) // 紫色
        
        backgroundStyle.backgroundColor = UIColor.white
        backgroundStyle.gridColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        textStyle.textColor = UIColor(red: 0.376, green: 0.451, blue: 0.557, alpha: 1.0)
        textStyle.priceTextColor = UIColor(red: 0.376, green: 0.451, blue: 0.557, alpha: 1.0)
        textStyle.timeTextColor = UIColor(red: 0.376, green: 0.451, blue: 0.557, alpha: 1.0)
    }
    
    // MARK: - 配置保存和加载
    public func saveConfiguration() {
        // 这里可以实现配置的持久化保存
        // 可以使用UserDefaults、Core Data或其他存储方式
    }
    
    public func loadConfiguration() {
        // 这里可以实现配置的加载
        // 从存储中恢复用户的自定义配置
    }
    
    // MARK: - 重置为默认配置
    public func resetToDefault() {
        currentTheme = .binance
        applyTheme(.binance)
    }
}
