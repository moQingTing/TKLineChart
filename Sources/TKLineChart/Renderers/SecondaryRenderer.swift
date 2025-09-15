import UIKit

public class SecondaryRenderer: BaseChartRendererImpl<CompleteKLineEntity> {
    private let secondaryState: SecondaryState
    private let chartColors: ChartColors
    private let chartStyle: ChartStyle
    
    public init(chartRect: CGRect, maxValue: Double, minValue: Double, topPadding: Double,
                secondaryState: SecondaryState, chartStyle: ChartStyle, chartColors: ChartColors) {
        self.secondaryState = secondaryState
        self.chartColors = chartColors
        self.chartStyle = chartStyle
        
        super.init(chartRect: chartRect, maxValue: maxValue, minValue: minValue, topPadding: topPadding)
    }
    
    public override func drawChart(_ lastPoint: CompleteKLineEntity, _ curPoint: CompleteKLineEntity,
                                 lastX: Double, curX: Double, size: CGSize, canvas: CGContext) {
        switch secondaryState {
        case .macd:
            drawMACD(lastPoint, curPoint, canvas: canvas, lastX: lastX, curX: curX)
        case .kdj:
            drawKDJ(lastPoint, curPoint, canvas: canvas, lastX: lastX, curX: curX)
        case let .rsi(p):
            drawRSI(lastPoint, curPoint, canvas: canvas, lastX: lastX, curX: curX, period: p)
        case .wr(_):
            drawWR(lastPoint, curPoint, canvas: canvas, lastX: lastX, curX: curX)
        case let .vol(p1, p2):
            drawVolume(lastPoint, curPoint, canvas: canvas, lastX: lastX, curX: curX, p1: p1, p2: p2)
        }
    }
    
    private func drawMACD(_ lastPoint: CompleteKLineEntity, _ curPoint: CompleteKLineEntity,
canvas: CGContext, lastX: Double, curX: Double) {
        // 绘制MACD柱状图
        let macdHeight = getY(0) - getY(curPoint.macd)
        let macdY = getY(max(0, curPoint.macd))
        
        // 使用配置的颜色
        let config = ChartConfiguration.shared
        let color = curPoint.macd >= 0 ? config.macdStyle.positiveColor : config.macdStyle.negativeColor
        
        // 根据MACD值的正负和变化趋势来判断空心/实心
        let isIncreasing = curPoint.macd > lastPoint.macd
        let isPositive = curPoint.macd >= 0
        
        // 红色MACD：增加时空心，减少时实心
        // 绿色MACD：增加时实心，减少时空心（与红色相反）
        let shouldBeHollow = isPositive ? !isIncreasing : isIncreasing
        
        canvas.setFillColor(color.cgColor)
        canvas.setStrokeColor(color.cgColor)
        canvas.setLineWidth(1.0)
        
        let rect = CGRect(x: curX - chartStyle.macdWidth / 2, y: macdY, 
                         width: chartStyle.macdWidth, height: abs(macdHeight))
        
        if shouldBeHollow {
            // 空心柱状图（只画边框）
            canvas.stroke(rect)
        } else {
            // 实心柱状图
            canvas.fill(rect)
        }
        
        // 绘制DIF和DEA线
        if lastPoint.dif != 0 {
            drawLine(lastPoint.dif, curPoint.dif, canvas: canvas, lastX: lastX, curX: curX, color: config.macdStyle.difColor)
        }
        if lastPoint.dea != 0 {
            drawLine(lastPoint.dea, curPoint.dea, canvas: canvas, lastX: lastX, curX: curX, color: config.macdStyle.deaColor)
        }
    }
    
    private func drawKDJ(_ lastPoint: CompleteKLineEntity, _ curPoint: CompleteKLineEntity,
                        canvas: CGContext, lastX: Double, curX: Double) {
        let config = ChartConfiguration.shared
        
        if lastPoint.k != 0 {
            drawLine(lastPoint.k, curPoint.k, canvas: canvas, lastX: lastX, curX: curX, color: config.kdjStyle.kColor)
        }
        if lastPoint.d != 0 {
            drawLine(lastPoint.d, curPoint.d, canvas: canvas, lastX: lastX, curX: curX, color: config.kdjStyle.dColor)
        }
        if lastPoint.j != 0 {
            drawLine(lastPoint.j, curPoint.j, canvas: canvas, lastX: lastX, curX: curX, color: config.kdjStyle.jColor)
        }
    }
    
    private func drawRSI(_ lastPoint: CompleteKLineEntity, _ curPoint: CompleteKLineEntity,
                        canvas: CGContext, lastX: Double, curX: Double, period: Int) {
        let config = ChartConfiguration.shared
        let color = config.rsiStyle.rsiColors[period] ?? config.rsiStyle.rsi6Color
        if lastPoint.rsi != 0 || curPoint.rsi != 0 {
            drawLine(lastPoint.rsi, curPoint.rsi, canvas: canvas, lastX: lastX, curX: curX, color: color)
        }
    }
    
    private func drawWR(_ lastPoint: CompleteKLineEntity, _ curPoint: CompleteKLineEntity,
                       canvas: CGContext, lastX: Double, curX: Double) {
        let config = ChartConfiguration.shared
        
        if lastPoint.r != 0 {
            drawLine(lastPoint.r, curPoint.r, canvas: canvas, lastX: lastX, curX: curX, color: config.williamsRStyle.lineColor)
        }
    }
    
    private func drawVolume(_ lastPoint: CompleteKLineEntity, _ curPoint: CompleteKLineEntity,
                           canvas: CGContext, lastX: Double, curX: Double, p1: Int, p2: Int) {
        // 绘制成交量柱状图
        let volumeHeight = getY(0) - getY(curPoint.volume)
        let volumeY = getY(curPoint.volume)
        
        // 使用配置的颜色
        let config = ChartConfiguration.shared
        let color = curPoint.close >= curPoint.open ? config.volumeStyle.upColor : config.volumeStyle.downColor
        
        canvas.setFillColor(color.cgColor)
        let rect = CGRect(x: curX - chartStyle.volWidth / 2, y: volumeY,
                         width: chartStyle.volWidth, height: volumeHeight)
        canvas.fill(rect)
        
        // 绘制成交量MA线（参数化）
        let colors = config.volumeStyle.maColors
        let lastV1 = lastPoint.volumeMAs[p1] ?? 0
        let curV1 = curPoint.volumeMAs[p1] ?? 0
        if p1 > 0, lastV1 != 0 || curV1 != 0 {
            drawLine(lastV1, curV1, canvas: canvas, lastX: lastX, curX: curX, color: colors[p1] ?? config.volumeStyle.ma5Color)
        }
        let lastV2 = lastPoint.volumeMAs[p2] ?? 0
        let curV2 = curPoint.volumeMAs[p2] ?? 0
        if p2 > 0, lastV2 != 0 || curV2 != 0 {
            drawLine(lastV2, curV2, canvas: canvas, lastX: lastX, curX: curX, color: colors[p2] ?? config.volumeStyle.ma10Color)
        }
    }
    
    public override func drawText(_ canvas: CGContext, data: CompleteKLineEntity, x: Double) {
        var textComponents: [NSAttributedString] = []
        
        switch secondaryState {
        case .macd:
            if data.dif != 0 {
                let text = NSAttributedString(string: "DIF:\(format(data.dif))    ",
                                            attributes: getTextStyle(chartColors.difColor, fontSize: chartStyle.defaultTextSize))
                textComponents.append(text)
            }
            if data.dea != 0 {
                let text = NSAttributedString(string: "DEA:\(format(data.dea))    ",
                                            attributes: getTextStyle(chartColors.deaColor, fontSize: chartStyle.defaultTextSize))
                textComponents.append(text)
            }
            if data.macd != 0 {
                let text = NSAttributedString(string: "MACD:\(format(data.macd))    ",
                                            attributes: getTextStyle(chartColors.macdColor, fontSize: chartStyle.defaultTextSize))
                textComponents.append(text)
            }
            
        case .kdj:
            if data.k != 0 {
                let text = NSAttributedString(string: "K:\(format(data.k))    ",
                                            attributes: getTextStyle(chartColors.kColor, fontSize: chartStyle.defaultTextSize))
                textComponents.append(text)
            }
            if data.d != 0 {
                let text = NSAttributedString(string: "D:\(format(data.d))    ",
                                            attributes: getTextStyle(chartColors.dColor, fontSize: chartStyle.defaultTextSize))
                textComponents.append(text)
            }
            if data.j != 0 {
                let text = NSAttributedString(string: "J:\(format(data.j))    ",
                                            attributes: getTextStyle(chartColors.jColor, fontSize: chartStyle.defaultTextSize))
                textComponents.append(text)
            }
            
        case let .rsi(period):
            if data.rsi != 0 {
                let color = ChartConfiguration.shared.rsiStyle.rsiColors[period] ?? chartColors.rsiColor
                let text = NSAttributedString(string: "RSI(\(period)):\(format(data.rsi))    ",
                                            attributes: getTextStyle(color, fontSize: chartStyle.defaultTextSize))
                textComponents.append(text)
            }
            
        case let .wr(period):
            if data.r != 0 {
                let text = NSAttributedString(string: "WR(\(period)):\(format(data.r))    ",
                                            attributes: getTextStyle(chartColors.rsiColor, fontSize: chartStyle.defaultTextSize))
                textComponents.append(text)
            }
            
        case let .vol(p1, p2):
            // VOL 当前成交量
            let volText = NSAttributedString(string: "VOL: \(NumberUtil.volFormat(data.volume))    ",
                                            attributes: getTextStyle(chartColors.volColor, fontSize: chartStyle.defaultTextSize))
            textComponents.append(volText)

            // 成交量MA(p1)
            let v1 = data.volumeMAs[p1] ?? 0
            if p1 > 0, v1 != 0 {
                let color1 = ChartConfiguration.shared.volumeStyle.maColors[p1] ?? ChartConfiguration.shared.volumeStyle.ma5Color
                let ma1Text = NSAttributedString(string: "MA(\(p1)): \(NumberUtil.volFormat(v1))    ",
                                                attributes: getTextStyle(color1, fontSize: chartStyle.defaultTextSize))
                textComponents.append(ma1Text)
            }

            // 成交量MA(p2)
            let v2 = data.volumeMAs[p2] ?? 0
            if p2 > 0, v2 != 0 {
                let color2 = ChartConfiguration.shared.volumeStyle.maColors[p2] ?? ChartConfiguration.shared.volumeStyle.ma10Color
                let ma2Text = NSAttributedString(string: "MA(\(p2)): \(NumberUtil.volFormat(v2))    ",
                                                attributes: getTextStyle(color2, fontSize: chartStyle.defaultTextSize))
                textComponents.append(ma2Text)
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
    
    public override func drawRightText(_ canvas: CGContext, textStyle: [NSAttributedString.Key: Any], gridRows: Int) {
        let rowSpace = Double(chartRect.height) / Double(gridRows)
        
        for i in 0...gridRows {
            let position = Double(gridRows - i) * rowSpace
            let value = position / scaleY + minValue
            
            let text = NSAttributedString(string: format(value), attributes: textStyle)
            let textSize = text.size()
            
            // 修复纵坐标数值显示位置：顶部数值显示在顶部，底部数值显示在底部
            let y: Double
            if i == 0 {
                // 顶部第一个数值，显示在图表顶部
                y = Double(chartRect.minY) + 2
            } else if i == gridRows {
                // 底部最后一个数值，显示在图表底部
                y = Double(chartRect.maxY) - textSize.height - 2
            } else {
                // 中间数值，显示在对应位置
                y = getY(value) - textSize.height / 2
            }
            
            text.draw(at: CGPoint(x: Double(chartRect.width) - textSize.width, y: y))
        }
    }
    
    public override func drawGrid(_ canvas: CGContext, gridRows: Int, gridColumns: Int) {
        let rowSpace = Double(chartRect.height) / Double(gridRows)
        
        canvas.setStrokeColor(chartColors.gridColor.cgColor)
        canvas.setLineWidth(CGFloat(chartStyle.gridStrokeWidth))
        
        // 绘制水平网格线（只绘制顶部和底部，去掉中间线）
        // 顶部网格线
        let topY = Double(chartRect.minY)
        canvas.move(to: CGPoint(x: chartRect.minX, y: topY))
        canvas.addLine(to: CGPoint(x: chartRect.maxX, y: topY))
        
        // 底部网格线
        let bottomY = Double(chartRect.maxY)
        canvas.move(to: CGPoint(x: chartRect.minX, y: bottomY))
        canvas.addLine(to: CGPoint(x: chartRect.maxX, y: bottomY))
        
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
