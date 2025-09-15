import UIKit

public class MainRenderer: BaseChartRendererImpl<CompleteKLineEntity> {
    private var candleWidth: Double = 0.0
    private var candleLineWidth: Double = 0.0
    private let state: MainState
    private let isLine: Bool
    private let chartColors: ChartColors
    private let chartStyle: ChartStyle
    
    private let contentPadding: Double = 12.0
    
    public init(chartRect: CGRect, maxValue: Double, minValue: Double, topPadding: Double, 
                state: MainState, isLine: Bool, chartStyle: ChartStyle, chartColors: ChartColors) {
        self.state = state
        self.isLine = isLine
        self.chartColors = chartColors
        self.chartStyle = chartStyle
        
        super.init(chartRect: chartRect, maxValue: maxValue, minValue: minValue, topPadding: topPadding)
        
        self.candleWidth = chartStyle.candleWidth
        self.candleLineWidth = chartStyle.candleLineWidth
        
        // 调整Y轴范围，增加内容边距
        let diff = maxValue - minValue
        let newScaleY = (Double(chartRect.height) - contentPadding) / diff
        let newDiff = Double(chartRect.height) / newScaleY
        let value = (newDiff - diff) / 2
        
        if newDiff > diff {
            self.scaleY = newScaleY
            self.maxValue += value
            self.minValue -= value
        }
    }
    
    public override func drawText(_ canvas: CGContext, data: CompleteKLineEntity, x: Double) {
        var textComponents: [NSAttributedString] = []
        
        if state == .ma {
            if data.MA5Price != 0 {
                let text = NSAttributedString(string: "MA5:\(format(data.MA5Price))    ", 
                                            attributes: getTextStyle(chartColors.ma5Color, fontSize: chartStyle.defaultTextSize))
                textComponents.append(text)
            }
            if data.MA10Price != 0 {
                let text = NSAttributedString(string: "MA10:\(format(data.MA10Price))    ", 
                                            attributes: getTextStyle(chartColors.ma10Color, fontSize: chartStyle.defaultTextSize))
                textComponents.append(text)
            }
            if data.MA30Price != 0 {
                let text = NSAttributedString(string: "MA30:\(format(data.MA30Price))    ", 
                                            attributes: getTextStyle(chartColors.ma30Color, fontSize: chartStyle.defaultTextSize))
                textComponents.append(text)
            }
        } else if state == .boll {
            if data.mb != 0 {
                let text = NSAttributedString(string: "BOLL:\(format(data.mb))    ", 
                                            attributes: getTextStyle(chartColors.ma5Color, fontSize: chartStyle.defaultTextSize))
                textComponents.append(text)
            }
            if data.up != 0 {
                let text = NSAttributedString(string: "UP:\(format(data.up))    ", 
                                            attributes: getTextStyle(chartColors.ma10Color, fontSize: chartStyle.defaultTextSize))
                textComponents.append(text)
            }
            if data.dn != 0 {
                let text = NSAttributedString(string: "LB:\(format(data.dn))    ", 
                                            attributes: getTextStyle(chartColors.ma30Color, fontSize: chartStyle.defaultTextSize))
                textComponents.append(text)
            }
        }
        
        guard !textComponents.isEmpty else { return }
        
        let combinedText = NSMutableAttributedString()
        for component in textComponents {
            combinedText.append(component)
        }
        
        let textSize = combinedText.size()
        // 修复位置计算：在图表内部，贴着顶部网格线显示指标参数
        let y = Double(chartRect.minY) + 2
        combinedText.draw(at: CGPoint(x: x, y: y))
    }
    
    public override func drawChart(_ lastPoint: CompleteKLineEntity, _ curPoint: CompleteKLineEntity, 
                                 lastX: Double, curX: Double, size: CGSize, canvas: CGContext) {
        if !isLine {
            drawCandle(curPoint, canvas: canvas, curX: curX)
        }
        
        if isLine {
            drawLine(lastPoint.close, curPoint.close, canvas: canvas, lastX: lastX, curX: curX)
        } else if state == .ma {
            drawMaLine(lastPoint, curPoint, canvas: canvas, lastX: lastX, curX: curX)
        } else if state == .boll {
            drawBollLine(lastPoint, curPoint, canvas: canvas, lastX: lastX, curX: curX)
        }
    }
    
    private func drawLine(_ lastPrice: Double, _ curPrice: Double, canvas: CGContext, lastX: Double, curX: Double) {
        let lastY = getY(lastPrice)
        let curY = getY(curPrice)
        
        // 创建路径
        let path = CGMutablePath()
        let adjustedLastX = lastX == curX ? 0 : lastX
        path.move(to: CGPoint(x: adjustedLastX, y: lastY))
        
        // 使用贝塞尔曲线平滑连接
        let controlPoint1X = (adjustedLastX + curX) / 2
        let controlPoint1Y = lastY
        let controlPoint2X = (adjustedLastX + curX) / 2
        let controlPoint2Y = curY
        
        path.addCurve(to: CGPoint(x: curX, y: curY),
                     control1: CGPoint(x: controlPoint1X, y: controlPoint1Y),
                     control2: CGPoint(x: controlPoint2X, y: controlPoint2Y))
        
        // 绘制阴影填充
        let fillPath = CGMutablePath()
        fillPath.move(to: CGPoint(x: adjustedLastX, y: Double(chartRect.maxY)))
        fillPath.addLine(to: CGPoint(x: adjustedLastX, y: lastY))
        fillPath.addCurve(to: CGPoint(x: curX, y: curY),
                         control1: CGPoint(x: controlPoint1X, y: controlPoint1Y),
                         control2: CGPoint(x: controlPoint2X, y: controlPoint2Y))
        fillPath.addLine(to: CGPoint(x: curX, y: Double(chartRect.maxY)))
        fillPath.closeSubpath()
        
        // 创建渐变
        let colors = chartColors.kLineShadowColors.map { $0.cgColor }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0])!
        
        canvas.saveGState()
        canvas.addPath(fillPath)
        canvas.clip()
        canvas.drawLinearGradient(gradient,
                                start: CGPoint(x: 0, y: Double(chartRect.minY)),
                                end: CGPoint(x: 0, y: Double(chartRect.maxY)),
                                options: [])
        canvas.restoreGState()
        
        // 绘制线条
        canvas.setStrokeColor(chartColors.kLineColor.cgColor)
        canvas.setLineWidth(CGFloat(chartStyle.lineStrokeWidth))
        canvas.addPath(path)
        canvas.strokePath()
    }
    
    private func drawMaLine(_ lastPoint: CompleteKLineEntity, _ curPoint: CompleteKLineEntity, 
                           canvas: CGContext, lastX: Double, curX: Double) {
        let config = ChartConfiguration.shared
        
        if lastPoint.MA5Price != 0 {
            drawLine(lastPoint.MA5Price, curPoint.MA5Price, canvas: canvas, lastX: lastX, curX: curX, color: config.movingAverageStyle.ma5Color)
        }
        if lastPoint.MA10Price != 0 {
            drawLine(lastPoint.MA10Price, curPoint.MA10Price, canvas: canvas, lastX: lastX, curX: curX, color: config.movingAverageStyle.ma10Color)
        }
        if lastPoint.MA30Price != 0 {
            drawLine(lastPoint.MA30Price, curPoint.MA30Price, canvas: canvas, lastX: lastX, curX: curX, color: config.movingAverageStyle.ma30Color)
        }
    }
    
    private func drawBollLine(_ lastPoint: CompleteKLineEntity, _ curPoint: CompleteKLineEntity, 
                             canvas: CGContext, lastX: Double, curX: Double) {
        let config = ChartConfiguration.shared
        
        if lastPoint.up != 0 {
            drawLine(lastPoint.up, curPoint.up, canvas: canvas, lastX: lastX, curX: curX, color: config.bollingerBandsStyle.upperColor)
        }
        if lastPoint.mb != 0 {
            drawLine(lastPoint.mb, curPoint.mb, canvas: canvas, lastX: lastX, curX: curX, color: config.bollingerBandsStyle.middleColor)
        }
        if lastPoint.dn != 0 {
            drawLine(lastPoint.dn, curPoint.dn, canvas: canvas, lastX: lastX, curX: curX, color: config.bollingerBandsStyle.lowerColor)
        }
    }
    
    private func drawCandle(_ curPoint: CompleteKLineEntity, canvas: CGContext, curX: Double) {
        let high = getY(curPoint.high)
        let low = getY(curPoint.low)
        let open = getY(curPoint.open)
        let close = getY(curPoint.close)
        
        let r = candleWidth / 2
        
        // 使用配置的颜色
        let config = ChartConfiguration.shared
        let isUp = curPoint.close > curPoint.open
        let color = isUp ? config.candleStyle.upColor : config.candleStyle.downColor
        
        canvas.setFillColor(color.cgColor)
        canvas.setStrokeColor(color.cgColor)
        canvas.setLineWidth(CGFloat(candleLineWidth))
        
        let entityTop = min(open, close)
        let entityBottom = max(open, close)
        
        // 绘制影线 - 影线颜色跟随蜡烛颜色
        canvas.setStrokeColor(color.cgColor)
        if high < entityTop {
            // 上影线
            canvas.move(to: CGPoint(x: curX, y: high))
            canvas.addLine(to: CGPoint(x: curX, y: entityTop))
        }
        
        if low > entityBottom {
            // 下影线
            canvas.move(to: CGPoint(x: curX, y: entityBottom))
            canvas.addLine(to: CGPoint(x: curX, y: low))
        }
        canvas.strokePath()
        
        // 绘制实体
        canvas.setStrokeColor(color.cgColor)
        if curPoint.open != curPoint.close {
            let rect = CGRect(x: curX - r, y: entityTop, width: candleWidth, height: entityBottom - entityTop)
            
            if config.candleStyle.isSolid {
                // 实心蜡烛
                canvas.fill(rect)
                canvas.stroke(rect)
            } else {
                // 空心蜡烛
                canvas.stroke(rect)
            }
        } else {
            // 开盘价等于收盘价（十字星）
            canvas.move(to: CGPoint(x: curX - r, y: open))
            canvas.addLine(to: CGPoint(x: curX + r, y: open))
            canvas.strokePath()
        }
    }
    
    public override func drawRightText(_ canvas: CGContext, textStyle: [NSAttributedString.Key: Any], gridRows: Int) {
        let rowSpace = Double(chartRect.height) / Double(gridRows)
        
        for i in 0...gridRows {
            let position: Double
            if i == 0 {
                position = Double(gridRows - i) * rowSpace - contentPadding / 2
            } else if i == gridRows {
                position = Double(gridRows - i) * rowSpace + contentPadding / 2
            } else {
                position = Double(gridRows - i) * rowSpace
            }
            
            let value = position / scaleY + minValue
            let text = NSAttributedString(string: format(value), attributes: textStyle)
            let textSize = text.size()
            
            let y: Double
            if i == 0 || i == gridRows {
                y = getY(value) - textSize.height / 2
            } else {
                y = getY(value) - textSize.height
            }
            
            text.draw(at: CGPoint(x: Double(chartRect.width) - textSize.width, y: y))
        }
    }
    
    public override func drawGrid(_ canvas: CGContext, gridRows: Int, gridColumns: Int) {
        let rowSpace = Double(chartRect.height) / Double(gridRows)
        
        canvas.setStrokeColor(chartColors.gridColor.cgColor)
        canvas.setLineWidth(CGFloat(chartStyle.gridStrokeWidth))
        
        // 绘制水平网格线
        for i in 0...gridRows {
            let y = Double(chartRect.minY) + Double(i) * rowSpace
            canvas.move(to: CGPoint(x: chartRect.minX, y: y))
            canvas.addLine(to: CGPoint(x: chartRect.maxX, y: y))
        }
        
        // 绘制垂直网格线
        let columnSpace = Double(chartRect.width) / Double(gridColumns)
        for i in 0...gridColumns {
            let x = Double(chartRect.minX) + Double(i) * columnSpace
            canvas.move(to: CGPoint(x: x, y: chartRect.minY))
            canvas.addLine(to: CGPoint(x: x, y: chartRect.maxY))
        }
        
        canvas.strokePath()
    }
}
