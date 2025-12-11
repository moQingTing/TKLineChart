import UIKit

public class MainRenderer: BaseChartRendererImpl<CompleteKLineEntity> {
    private var candleWidth: Double = 0.0
    private var candleLineWidth: Double = 0.0
    private let state: MainState
    private let isLine: Bool
    private let chartColors: ChartColors
    private let chartConfiguration: ChartConfiguration
    
    private let contentPadding: Double = 12.0
    
    public init(chartRect: CGRect, maxValue: Double, minValue: Double, topPadding: Double, 
                state: MainState, isLine: Bool, chartColors: ChartColors,
                chartConfiguration: ChartConfiguration) {
        self.state = state
        self.isLine = isLine
        self.chartColors = chartColors
        self.chartConfiguration = chartConfiguration
        
        // 为指标参数预留上padding空间，去掉底部留白
        let textPadding = chartConfiguration.chartStyleConfig.defaultTextSize + 4.0
        let adjustedChartRect = CGRect(
            x: chartRect.minX,
            y: chartRect.minY + CGFloat(textPadding),
            width: chartRect.width,
            height: max(0, chartRect.height - CGFloat(textPadding))
        )
        
        super.init(chartRect: adjustedChartRect, maxValue: maxValue, minValue: minValue, topPadding: topPadding, priceFormatter: chartConfiguration.priceFormatter)
        
        self.candleWidth = chartConfiguration.chartStyleConfig.candleWidth
        self.candleLineWidth = chartConfiguration.chartStyleConfig.candleLineWidth
        
        // 调整Y轴范围，增加内容边距
        let diff = maxValue - minValue
        let newScaleY = (Double(adjustedChartRect.height) - contentPadding) / diff
        let newDiff = Double(adjustedChartRect.height) / newScaleY
        let value = (newDiff - diff) / 2
        
        if newDiff > diff {
            self.scaleY = newScaleY
            self.maxValue += value
            self.minValue -= value
        }
    }
    
    public override func drawText(_ canvas: CGContext, data: CompleteKLineEntity, x: Double) {
        var textComponents: [NSAttributedString] = []
        
        switch state {
        case let .ma(p1, p2, p3):
            let periods = [p1, p2, p3]
            let maColors = chartConfiguration.movingAverageStyle.maColors
            for period in periods {
                guard period > 0, let v = data.maPrices[period], v != 0 else { continue }
                let color = maColors[period] ?? chartColors.kLineColor
                    let text = NSAttributedString(string: "MA(\(period)):\(format(v, fractionDigits: 0))    ",
                                                attributes: getTextStyle(color, fontSize: chartConfiguration.chartStyleConfig.defaultTextSize))
                textComponents.append(text)
            }
        case let .ema(p1, p2, p3):
            let periods = [p1, p2, p3]
            let colors = chartConfiguration.emaStyle.colors
            for period in periods {
                guard period > 0, let v = data.emaPrices[period], v != 0 else { continue }
                let color = colors[period] ?? chartColors.kLineColor
                    let text = NSAttributedString(string: "EMA(\(period)):\(format(v, fractionDigits: 0))    ",
                                                attributes: getTextStyle(color, fontSize: chartConfiguration.chartStyleConfig.defaultTextSize))
                textComponents.append(text)
            }
        case .boll:
            if data.mb != 0 {
                let text = NSAttributedString(string: "BOLL:\(format(data.mb, fractionDigits: 0))    ",
                                            attributes: getTextStyle(chartConfiguration.bollingerBandsStyle.middleColor, fontSize: chartConfiguration.chartStyleConfig.defaultTextSize))
                textComponents.append(text)
            }
            if data.up != 0 {
                let text = NSAttributedString(string: "UP:\(format(data.up, fractionDigits: 0))    ", 
                                            attributes: getTextStyle(chartConfiguration.bollingerBandsStyle.upperColor, fontSize: chartConfiguration.chartStyleConfig.defaultTextSize))
                textComponents.append(text)
            }
            if data.dn != 0 {
                let text = NSAttributedString(string: "LB:\(format(data.dn, fractionDigits: 0))    ", 
                                            attributes: getTextStyle(chartConfiguration.bollingerBandsStyle.lowerColor, fontSize: chartConfiguration.chartStyleConfig.defaultTextSize))
                textComponents.append(text)
            }
        case .none:
            break
        }
        
        guard !textComponents.isEmpty else { return }
        
        let combinedText = NSMutableAttributedString()
        for component in textComponents {
            combinedText.append(component)
        }
        
        let textSize = combinedText.size()
        
        // 指标参数显示在预留的padding区域中
        let textPadding = chartConfiguration.chartStyleConfig.defaultTextSize + 4.0
        
        // 顶部指标参数：显示在上padding区域
        let topY = Double(chartRect.minY) - textPadding + 2
        combinedText.draw(at: CGPoint(x: x, y: topY))
        
    }
    
    public override func drawChart(_ lastPoint: CompleteKLineEntity, _ curPoint: CompleteKLineEntity, 
                                 lastX: Double, curX: Double, size: CGSize, canvas: CGContext) {
        if !isLine {
            drawCandle(curPoint, canvas: canvas, curX: curX)
        }
        
        if isLine {
            drawLine(lastPoint.close, curPoint.close, canvas: canvas, lastX: lastX, curX: curX)
        } else {
            switch state {
            case let .ma(p1, p2, p3):
                drawMaLine(lastPoint, curPoint, canvas: canvas, lastX: lastX, curX: curX, periods: [p1, p2, p3])
            case let .ema(p1, p2, p3):
                drawEmaLine(lastPoint, curPoint, canvas: canvas, lastX: lastX, curX: curX, periods: [p1, p2, p3])
            case .boll:
                drawBollLine(lastPoint, curPoint, canvas: canvas, lastX: lastX, curX: curX)
            case .none:
                break
            }
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
        canvas.setLineWidth(CGFloat(chartConfiguration.chartStyleConfig.lineStrokeWidth))
        canvas.addPath(path)
        canvas.strokePath()
    }
    
    // 带颜色参数的drawLine方法，用于绘制MA、EMA等指标线
    public override func drawLine(_ lastPrice: Double, _ curPrice: Double, canvas: CGContext, lastX: Double, curX: Double, color: UIColor, lineWidth: Double = 1.0) {
        let lastY = getY(lastPrice)
        let curY = getY(curPrice)
        
        // 限制Y坐标在图表范围内，防止超出指标参数区域
        let clampedLastY = max(Double(chartRect.minY), min(Double(chartRect.maxY), lastY))
        let clampedCurY = max(Double(chartRect.minY), min(Double(chartRect.maxY), curY))
        
        canvas.setStrokeColor(color.cgColor)
        canvas.setLineWidth(CGFloat(lineWidth))  // 使用传入的线条宽度
        canvas.setLineCap(.round)  // 设置线条端点为圆形，避免裂缝
        canvas.setLineJoin(.round) // 设置线条连接点为圆形，避免折角裂缝
        canvas.move(to: CGPoint(x: lastX, y: clampedLastY))
        canvas.addLine(to: CGPoint(x: curX, y: clampedCurY))
        canvas.strokePath()
    }
    
    private func drawMaLine(_ lastPoint: CompleteKLineEntity, _ curPoint: CompleteKLineEntity,
                           canvas: CGContext, lastX: Double, curX: Double, periods: [Int]) {
        let maColors = chartConfiguration.movingAverageStyle.maColors
        for period in periods {
            guard period > 0 else { continue }
            guard let lastV = lastPoint.maPrices[period], let curV = curPoint.maPrices[period], lastV != 0 && curV != 0 else { continue }
            let color = maColors[period] ?? chartColors.kLineColor
            drawLine(lastV, curV, canvas: canvas, lastX: lastX, curX: curX, color: color, lineWidth: chartConfiguration.chartStyleConfig.lineStrokeWidth)
        }
    }

    private func drawEmaLine(_ lastPoint: CompleteKLineEntity, _ curPoint: CompleteKLineEntity,
                            canvas: CGContext, lastX: Double, curX: Double, periods: [Int]) {
        let colors = chartConfiguration.emaStyle.colors
        for period in periods {
            guard period > 0 else { continue }
            guard let lastV = lastPoint.emaPrices[period], let curV = curPoint.emaPrices[period], lastV != 0 && curV != 0 else { continue }
            let color = colors[period] ?? chartColors.kLineColor
            drawLine(lastV, curV, canvas: canvas, lastX: lastX, curX: curX, color: color, lineWidth: chartConfiguration.chartStyleConfig.lineStrokeWidth)
        }
    }
    
    private func drawBollLine(_ lastPoint: CompleteKLineEntity, _ curPoint: CompleteKLineEntity, 
                             canvas: CGContext, lastX: Double, curX: Double) {
        let config = chartConfiguration
        
        if lastPoint.up != 0 {
            drawLine(lastPoint.up, curPoint.up, canvas: canvas, lastX: lastX, curX: curX, color: config.bollingerBandsStyle.upperColor, lineWidth: chartConfiguration.chartStyleConfig.lineStrokeWidth)
        }
        if lastPoint.mb != 0 {
            drawLine(lastPoint.mb, curPoint.mb, canvas: canvas, lastX: lastX, curX: curX, color: config.bollingerBandsStyle.middleColor, lineWidth: chartConfiguration.chartStyleConfig.lineStrokeWidth)
        }
        if lastPoint.dn != 0 {
            drawLine(lastPoint.dn, curPoint.dn, canvas: canvas, lastX: lastX, curX: curX, color: config.bollingerBandsStyle.lowerColor, lineWidth: chartConfiguration.chartStyleConfig.lineStrokeWidth)
        }
    }
    
    private func drawCandle(_ curPoint: CompleteKLineEntity, canvas: CGContext, curX: Double) {
        let high = getY(curPoint.high)
        let low = getY(curPoint.low)
        let open = getY(curPoint.open)
        let close = getY(curPoint.close)
        
        let r = candleWidth / 2
        
        // 使用配置的颜色
        let isUp = curPoint.close > curPoint.open
        let color = isUp ? chartConfiguration.candleStyle.upColor : chartConfiguration.candleStyle.downColor
        
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
            
            if chartConfiguration.candleStyle.isSolid {
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
            let text = NSAttributedString(string: format(value, fractionDigits: 0), attributes: textStyle)
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
        // 计算包含上padding的完整边框区域（去掉底部留白）
        let textPadding = chartConfiguration.chartStyleConfig.defaultTextSize + 4.0
        let fullRect = CGRect(
            x: chartRect.minX,
            y: chartRect.minY - CGFloat(textPadding),
            width: chartRect.width,
            height: chartRect.height + CGFloat(textPadding)
        )
        
        let rowSpace = Double(chartRect.height) / Double(gridRows)
        
        // 使用 ChartConfiguration 中的网格配置
        let config = chartConfiguration
        canvas.setStrokeColor(config.backgroundStyle.gridColor.cgColor)
        canvas.setLineWidth(CGFloat(config.backgroundStyle.gridLineWidth))
        
        // 绘制水平网格线（只在图表内容区域内，从第二行开始，跳过第一行）
        for i in 1...gridRows {
            let y = Double(chartRect.minY) + Double(i) * rowSpace
            canvas.move(to: CGPoint(x: chartRect.minX, y: y))
            canvas.addLine(to: CGPoint(x: chartRect.maxX, y: y))
        }
        
        // 绘制垂直网格线（延伸到整个区域，包括上padding）
        let columnSpace = Double(chartRect.width) / Double(gridColumns)
        for i in 0...gridColumns {
            let x = Double(chartRect.minX) + Double(i) * columnSpace
            canvas.move(to: CGPoint(x: x, y: Double(fullRect.minY)))
            canvas.addLine(to: CGPoint(x: x, y: Double(fullRect.maxY)))
        }
        
        // 绘制边框线（包含整个区域，包括padding）
        // 上线：在指标参数文字上方
        let topBorderY = Double(fullRect.minY)
        canvas.move(to: CGPoint(x: fullRect.minX, y: topBorderY))
        canvas.addLine(to: CGPoint(x: fullRect.maxX, y: topBorderY))
        
        // 下线：在底部留白区域下方
        let bottomBorderY = Double(fullRect.maxY)
        canvas.move(to: CGPoint(x: fullRect.minX, y: bottomBorderY))
        canvas.addLine(to: CGPoint(x: fullRect.maxX, y: bottomBorderY))
        
        // 左右边框线
        canvas.move(to: CGPoint(x: fullRect.minX, y: topBorderY))
        canvas.addLine(to: CGPoint(x: fullRect.minX, y: bottomBorderY))
        
        canvas.move(to: CGPoint(x: fullRect.maxX, y: topBorderY))
        canvas.addLine(to: CGPoint(x: fullRect.maxX, y: bottomBorderY))
        
        canvas.strokePath()
    }
}
