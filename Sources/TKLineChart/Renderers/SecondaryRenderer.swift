import UIKit

public class SecondaryRenderer: BaseChartRendererImpl<CompleteKLineEntity> {
    private let secondaryState: SecondaryState
    private let chartColors: ChartColors
    private let chartConfiguration: ChartConfiguration
    
    public init(chartRect: CGRect, maxValue: Double, minValue: Double, topPadding: Double,
                secondaryState: SecondaryState, chartColors: ChartColors,
                chartConfiguration: ChartConfiguration) {
        self.secondaryState = secondaryState
        self.chartColors = chartColors
        self.chartConfiguration = chartConfiguration
        
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
        let color = curPoint.macd >= 0 ? chartConfiguration.macdStyle.positiveColor : chartConfiguration.macdStyle.negativeColor
        
        // 根据MACD值的正负和变化趋势来判断空心/实心
        let isIncreasing = curPoint.macd > lastPoint.macd
        let isPositive = curPoint.macd >= 0
        
        // 红色MACD：增加时空心，减少时实心
        // 绿色MACD：增加时实心，减少时空心（与红色相反）
        let shouldBeHollow = isPositive ? !isIncreasing : isIncreasing
        
        canvas.setFillColor(color.cgColor)
        canvas.setStrokeColor(color.cgColor)
        canvas.setLineWidth(1.0)
        
        let rect = CGRect(x: curX - chartConfiguration.macdStyle.barWidth / 2, y: macdY, 
                         width: chartConfiguration.macdStyle.barWidth, height: abs(macdHeight))
        
        if shouldBeHollow {
            // 空心柱状图（只画边框）
            canvas.stroke(rect)
        } else {
            // 实心柱状图
            canvas.fill(rect)
        }
        
        // 绘制DIF和DEA线
        if lastPoint.dif != 0 {
            drawLine(lastPoint.dif, curPoint.dif, canvas: canvas, lastX: lastX, curX: curX, color: chartConfiguration.macdStyle.difColor, lineWidth: chartConfiguration.chartStyleConfig.lineStrokeWidth)
        }
        if lastPoint.dea != 0 {
            drawLine(lastPoint.dea, curPoint.dea, canvas: canvas, lastX: lastX, curX: curX, color: chartConfiguration.macdStyle.deaColor, lineWidth: chartConfiguration.chartStyleConfig.lineStrokeWidth)
        }
    }
    
    private func drawKDJ(_ lastPoint: CompleteKLineEntity, _ curPoint: CompleteKLineEntity,
                        canvas: CGContext, lastX: Double, curX: Double) {
        if lastPoint.k != 0 {
            drawLine(lastPoint.k, curPoint.k, canvas: canvas, lastX: lastX, curX: curX, color: chartConfiguration.kdjStyle.kColor, lineWidth: chartConfiguration.chartStyleConfig.lineStrokeWidth)
        }
        if lastPoint.d != 0 {
            drawLine(lastPoint.d, curPoint.d, canvas: canvas, lastX: lastX, curX: curX, color: chartConfiguration.kdjStyle.dColor, lineWidth: chartConfiguration.chartStyleConfig.lineStrokeWidth)
        }
        if lastPoint.j != 0 {
            drawLine(lastPoint.j, curPoint.j, canvas: canvas, lastX: lastX, curX: curX, color: chartConfiguration.kdjStyle.jColor, lineWidth: chartConfiguration.chartStyleConfig.lineStrokeWidth)
        }
    }
    
    private func drawRSI(_ lastPoint: CompleteKLineEntity, _ curPoint: CompleteKLineEntity,
                        canvas: CGContext, lastX: Double, curX: Double, period: Int) {
        let color = chartConfiguration.rsiStyle.rsiColors[period] ?? chartConfiguration.rsiStyle.rsi6Color
        if lastPoint.rsi != 0 || curPoint.rsi != 0 {
            drawLine(lastPoint.rsi, curPoint.rsi, canvas: canvas, lastX: lastX, curX: curX, color: color, lineWidth: chartConfiguration.chartStyleConfig.lineStrokeWidth)
        }
    }
    
    private func drawWR(_ lastPoint: CompleteKLineEntity, _ curPoint: CompleteKLineEntity,
                       canvas: CGContext, lastX: Double, curX: Double) {
        if lastPoint.r != 0 {
            drawLine(lastPoint.r, curPoint.r, canvas: canvas, lastX: lastX, curX: curX, color: chartConfiguration.williamsRStyle.lineColor, lineWidth: chartConfiguration.chartStyleConfig.lineStrokeWidth)
        }
    }
    
    private func drawVolume(_ lastPoint: CompleteKLineEntity, _ curPoint: CompleteKLineEntity,
                           canvas: CGContext, lastX: Double, curX: Double, p1: Int, p2: Int) {
        // 绘制成交量柱状图
        let volumeHeight = getY(0) - getY(curPoint.volume)
        let volumeY = getY(curPoint.volume)
        
        // 使用配置的颜色
        let color = curPoint.close >= curPoint.open ? chartConfiguration.volumeStyle.upColor : chartConfiguration.volumeStyle.downColor
        
        canvas.setFillColor(color.cgColor)
        let rect = CGRect(x: curX - chartConfiguration.volumeStyle.barWidth / 2, y: volumeY,
                         width: chartConfiguration.volumeStyle.barWidth, height: volumeHeight)
        canvas.fill(rect)
        
        // 绘制成交量MA线（参数化）
        let colors = chartConfiguration.volumeStyle.maColors
        let lastV1 = lastPoint.volumeMAs[p1] ?? 0
        let curV1 = curPoint.volumeMAs[p1] ?? 0
        if p1 > 0, lastV1 != 0 || curV1 != 0 {
            drawLine(lastV1, curV1, canvas: canvas, lastX: lastX, curX: curX, color: colors[p1] ?? chartConfiguration.volumeStyle.ma5Color, lineWidth: chartConfiguration.chartStyleConfig.lineStrokeWidth)
        }
        let lastV2 = lastPoint.volumeMAs[p2] ?? 0
        let curV2 = curPoint.volumeMAs[p2] ?? 0
        if p2 > 0, lastV2 != 0 || curV2 != 0 {
            drawLine(lastV2, curV2, canvas: canvas, lastX: lastX, curX: curX, color: colors[p2] ?? chartConfiguration.volumeStyle.ma10Color, lineWidth: chartConfiguration.chartStyleConfig.lineStrokeWidth)
        }
    }
    
    public override func drawText(_ canvas: CGContext, data: CompleteKLineEntity, x: Double) {
        var textComponents: [NSAttributedString] = []
        
        switch secondaryState {
        case .macd:
            if data.dif != 0 {
                let text = NSAttributedString(string: "DIF:\(format(data.dif, fractionDigits: chartConfiguration.numberFractionDigits))    ",
                                            attributes: getTextStyle(chartColors.difColor, fontSize: chartConfiguration.chartStyleConfig.defaultTextSize))
                textComponents.append(text)
            }
            if data.dea != 0 {
                let text = NSAttributedString(string: "DEA:\(format(data.dea, fractionDigits: chartConfiguration.numberFractionDigits))    ",
                                            attributes: getTextStyle(chartColors.deaColor, fontSize: chartConfiguration.chartStyleConfig.defaultTextSize))
                textComponents.append(text)
            }
            if data.macd != 0 {
                let text = NSAttributedString(string: "MACD:\(format(data.macd, fractionDigits: chartConfiguration.numberFractionDigits))    ",
                                            attributes: getTextStyle(chartColors.macdColor, fontSize: chartConfiguration.chartStyleConfig.defaultTextSize))
                textComponents.append(text)
            }
            
        case .kdj:
            if data.k != 0 {
                let text = NSAttributedString(string: "K:\(format(data.k, fractionDigits: chartConfiguration.numberFractionDigits))    ",
                                            attributes: getTextStyle(chartColors.kColor, fontSize: chartConfiguration.chartStyleConfig.defaultTextSize))
                textComponents.append(text)
            }
            if data.d != 0 {
                let text = NSAttributedString(string: "D:\(format(data.d, fractionDigits: chartConfiguration.numberFractionDigits))    ",
                                            attributes: getTextStyle(chartColors.dColor, fontSize: chartConfiguration.chartStyleConfig.defaultTextSize))
                textComponents.append(text)
            }
            if data.j != 0 {
                let text = NSAttributedString(string: "J:\(format(data.j, fractionDigits: chartConfiguration.numberFractionDigits))    ",
                                            attributes: getTextStyle(chartColors.jColor, fontSize: chartConfiguration.chartStyleConfig.defaultTextSize))
                textComponents.append(text)
            }
            
        case let .rsi(period):
            if data.rsi != 0 {
                let color = chartConfiguration.rsiStyle.rsiColors[period] ?? chartColors.rsiColor
                let text = NSAttributedString(string: "RSI(\(period)):\(format(data.rsi, fractionDigits: chartConfiguration.numberFractionDigits))    ",
                                            attributes: getTextStyle(color, fontSize: chartConfiguration.chartStyleConfig.defaultTextSize))
                textComponents.append(text)
            }
            
        case let .wr(period):
            if data.r != 0 {
                let text = NSAttributedString(string: "WR(\(period)):\(format(data.r, fractionDigits: chartConfiguration.numberFractionDigits))    ",
                                            attributes: getTextStyle(chartColors.rsiColor, fontSize: chartConfiguration.chartStyleConfig.defaultTextSize))
                textComponents.append(text)
            }
            
        case let .vol(p1, p2):
            // VOL 当前成交量
            let volText = NSAttributedString(string: "VOL: \(NumberUtil.volFormat(data.volume, chartConfiguration.numberFractionDigits))    ",
                                            attributes: getTextStyle(chartColors.volColor, fontSize: chartConfiguration.chartStyleConfig.defaultTextSize))
            textComponents.append(volText)

            // 成交量MA(p1)
            let v1 = data.volumeMAs[p1] ?? 0
            if p1 > 0, v1 != 0 {
                let color1 = chartConfiguration.volumeStyle.maColors[p1] ?? chartConfiguration.volumeStyle.ma5Color
                let ma1Text = NSAttributedString(string: "MA(\(p1)): \(NumberUtil.volFormat(v1, chartConfiguration.numberFractionDigits))    ",
                                                attributes: getTextStyle(color1, fontSize: chartConfiguration.chartStyleConfig.defaultTextSize))
                textComponents.append(ma1Text)
            }

            // 成交量MA(p2)
            let v2 = data.volumeMAs[p2] ?? 0
            if p2 > 0, v2 != 0 {
                let color2 = chartConfiguration.volumeStyle.maColors[p2] ?? chartConfiguration.volumeStyle.ma10Color
                let ma2Text = NSAttributedString(string: "MA(\(p2)): \(NumberUtil.volFormat(v2, chartConfiguration.numberFractionDigits))    ",
                                                attributes: getTextStyle(color2, fontSize: chartConfiguration.chartStyleConfig.defaultTextSize))
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
        // 只显示顶部和底部的数值，简化副图显示
        let rowSpace = Double(chartRect.height) / Double(gridRows)
        
        // 顶部数值（最大值）
        let topPosition = 0.0
        let topValue = topPosition / scaleY + minValue
        let topText = NSAttributedString(string: format(topValue, fractionDigits: chartConfiguration.numberFractionDigits), attributes: textStyle)
        let topTextSize = topText.size()
        let topY = Double(chartRect.minY) + 2
        topText.draw(at: CGPoint(x: Double(chartRect.width) - topTextSize.width, y: topY))
        
        // 底部数值（最小值）
        let bottomPosition = Double(gridRows) * rowSpace
        let bottomValue = bottomPosition / scaleY + minValue
        let bottomText = NSAttributedString(string: format(bottomValue, fractionDigits: chartConfiguration.numberFractionDigits), attributes: textStyle)
        let bottomTextSize = bottomText.size()
        let bottomY = Double(chartRect.maxY) - bottomTextSize.height - 2
        bottomText.draw(at: CGPoint(x: Double(chartRect.width) - bottomTextSize.width, y: bottomY))
    }
    
    public override func drawGrid(_ canvas: CGContext, gridRows: Int, gridColumns: Int) {
        let rowSpace = Double(chartRect.height) / Double(gridRows)
        
        // 使用 ChartConfiguration 中的网格配置
        canvas.setStrokeColor(chartConfiguration.backgroundStyle.gridColor.cgColor)
        canvas.setLineWidth(CGFloat(chartConfiguration.backgroundStyle.gridLineWidth))
        
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
