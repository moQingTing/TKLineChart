import UIKit

/// 均价折线图样式（蓝色主题/圆角折线/同色渐变/气泡），所有字段均可自定义。
/// 使用方式：
/// let style = AverageLineChartStyle(lineColor: .systemBlue, ...)
/// chartView.style = style
public struct AverageLineChartStyle {
    /// 折线颜色（推荐与品牌主色一致）
    public var lineColor: UIColor
    /// 折线宽度（pt）。示例图为较粗效果，2.5~3.0 更接近。
    public var lineWidth: CGFloat
    /// 渐变起始透明度（贴近折线处）。0~1，数值越大越实。
    public var gradientStartAlpha: CGFloat
    /// 渐变结束透明度（靠近底部处）。通常取很小的值实现“由实到虚”。
    public var gradientEndAlpha: CGFloat
    /// 背景颜色（默认纯白）。
    public var backgroundColor: UIColor
    /// 绘图内边距：top 要给气泡留位置；bottom 要给渐变收尾留空间。
    public var padding: UIEdgeInsets
    /// 是否显示网格（该折线图默认极简关闭）。
    public var showGrid: Bool
    /// 网格线颜色（当 showGrid=true 才生效）。
    public var gridColor: UIColor
    /// 价格格式化器（默认：美元且保留 1 位小数，带千分位）。
    /// 你可以改为人民币或其他格式。
    public var priceFormatter: (Double) -> String
    /// 气泡中文字颜色（通常与 lineColor 同色系）。
    public var balloonTextColor: UIColor
    /// 气泡背景色（建议使用 lineColor 的低透明度实现轻微高亮）。
    public var balloonBgColor: UIColor
    /// 气泡圆角（pt）。
    public var balloonCornerRadius: CGFloat
    /// 气泡字体（默认 14 加粗）。
    public var balloonFont: UIFont
    /// 选中点小圆点半径（pt）。
    public var pointRadius: CGFloat

    /// 初始化样式
    /// - Parameters:
    ///   - lineColor: 折线颜色
    ///   - lineWidth: 折线宽度（pt）
    ///   - gradientStartAlpha: 渐变起始透明度（靠近折线）
    ///   - gradientEndAlpha: 渐变结束透明度（靠近底部）
    ///   - backgroundColor: 背景色
    ///   - padding: 绘图区内边距
    ///   - showGrid: 是否显示网格
    ///   - gridColor: 网格线颜色
    ///   - priceFormatter: 价格格式化器，用于气泡文本
    ///   - balloonTextColor: 气泡文字颜色
    ///   - balloonBgColor: 气泡背景颜色
    ///   - balloonCornerRadius: 气泡圆角
    ///   - balloonFont: 气泡字体
    ///   - pointRadius: 选中点半径
    public init(
        lineColor: UIColor = UIColor.systemBlue,
        lineWidth: CGFloat = 2.5,
        gradientStartAlpha: CGFloat = 0.25,
        gradientEndAlpha: CGFloat = 0.02,
        backgroundColor: UIColor = .white,
        padding: UIEdgeInsets = UIEdgeInsets(top: 20, left: 16, bottom: 24, right: 16),
        showGrid: Bool = false,
        gridColor: UIColor = UIColor(white: 0.92, alpha: 1.0),
        priceFormatter: @escaping (Double) -> String = { value in
            let f = NumberFormatter()
            f.numberStyle = .currency
            f.currencySymbol = "$"
            f.minimumFractionDigits = 1
            f.maximumFractionDigits = 1
            return f.string(from: NSNumber(value: value)) ?? "$0.0"
        },
        balloonTextColor: UIColor = .systemBlue,
        balloonBgColor: UIColor = UIColor.systemBlue.withAlphaComponent(0.12),
        balloonCornerRadius: CGFloat = 12,
        balloonFont: UIFont = UIFont.systemFont(ofSize: 14, weight: .semibold),
        pointRadius: CGFloat = 4
    ) {
        self.lineColor = lineColor
        self.lineWidth = lineWidth
        self.gradientStartAlpha = gradientStartAlpha
        self.gradientEndAlpha = gradientEndAlpha
        self.backgroundColor = backgroundColor
        self.padding = padding
        self.showGrid = showGrid
        self.gridColor = gridColor
        self.priceFormatter = priceFormatter
        self.balloonTextColor = balloonTextColor
        self.balloonBgColor = balloonBgColor
        self.balloonCornerRadius = balloonCornerRadius
        self.balloonFont = balloonFont
        self.pointRadius = pointRadius
    }
}


