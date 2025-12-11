import UIKit

// MARK: - 基础图表渲染器协议
public protocol BaseChartRenderer {
    associatedtype DataType
    
    var maxValue: Double { get set }
    var minValue: Double { get set }
    var scaleY: Double { get set }
    var topPadding: Double { get set }
    var chartRect: CGRect { get set }
    
    func getY(_ y: Double) -> Double
    func format(_ n: Double, fractionDigits: Int) -> String
    func drawGrid(_ canvas: CGContext, gridRows: Int, gridColumns: Int)
    func drawText(_ canvas: CGContext, data: DataType, x: Double)
    func drawRightText(_ canvas: CGContext, textStyle: [NSAttributedString.Key: Any], gridRows: Int)
    func drawChart(_ lastPoint: DataType, _ curPoint: DataType, lastX: Double, curX: Double, size: CGSize, canvas: CGContext)
    func drawLine(_ lastPrice: Double, _ curPrice: Double, canvas: CGContext, lastX: Double, curX: Double, color: UIColor, lineWidth: Double)
}

// MARK: - 基础图表渲染器实现
open class BaseChartRendererImpl<T>: BaseChartRenderer {
    public typealias DataType = T
    
    public var maxValue: Double
    public var minValue: Double
    public var scaleY: Double = 1
    public var topPadding: Double
    public var chartRect: CGRect
    
    // 价格格式化回调
    public var priceFormatter: ((Double) -> String)?
    
    // 移除这些属性，因为CGContext不能作为实例变量存储
    
    public init(chartRect: CGRect, maxValue: Double, minValue: Double, topPadding: Double, priceFormatter: ((Double) -> String)? = nil) {
        self.chartRect = chartRect
        self.maxValue = maxValue
        self.minValue = minValue
        self.topPadding = topPadding
        self.priceFormatter = priceFormatter
        
        // 初始化完成
        
        if maxValue == minValue {
            self.maxValue += 0.5
            self.minValue -= 0.5
        }
        self.scaleY = Double(chartRect.height) / (maxValue - minValue)
    }
    
    public func getY(_ y: Double) -> Double {
        return (maxValue - y) * scaleY + Double(chartRect.minY)
    }
    
    public func format(_ n: Double, fractionDigits: Int) -> String {
        if let formatter = priceFormatter {
            return formatter(n)
        }
        // 默认格式化：保留2位小数
        return NumberUtil.format(n, 2)
    }
    
    open func drawGrid(_ canvas: CGContext, gridRows: Int, gridColumns: Int) {
        // 子类实现
    }
    
    open func drawText(_ canvas: CGContext, data: T, x: Double) {
        // 子类实现
    }
    
    open func drawRightText(_ canvas: CGContext, textStyle: [NSAttributedString.Key: Any], gridRows: Int) {
        // 子类实现
    }
    
    open func drawChart(_ lastPoint: T, _ curPoint: T, lastX: Double, curX: Double, size: CGSize, canvas: CGContext) {
        // 子类实现
    }
    
    public func drawLine(_ lastPrice: Double, _ curPrice: Double, canvas: CGContext, lastX: Double, curX: Double, color: UIColor, lineWidth: Double = 1.0) {
        let lastY = getY(lastPrice)
        let curY = getY(curPrice)
        
        canvas.setStrokeColor(color.cgColor)
        canvas.setLineWidth(CGFloat(lineWidth))  // 使用传入的线条宽度
        canvas.setLineCap(.round)  // 设置线条端点为圆形，避免裂缝
        canvas.setLineJoin(.round) // 设置线条连接点为圆形，避免折角裂缝
        canvas.move(to: CGPoint(x: lastX, y: lastY))
        canvas.addLine(to: CGPoint(x: curX, y: curY))
        canvas.strokePath()
    }
    
    public func getTextStyle(_ color: UIColor, fontSize: Double) -> [NSAttributedString.Key: Any] {
        return [
            .font: UIFont.systemFont(ofSize: CGFloat(fontSize)),
            .foregroundColor: color
        ]
    }
}
