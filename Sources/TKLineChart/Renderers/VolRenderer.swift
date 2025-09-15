import UIKit

public class VolRenderer: BaseChartRendererImpl<CompleteKLineEntity> {
    private let chartColors: ChartColors
    private let chartStyle: ChartStyle
    
    public init(chartRect: CGRect, maxValue: Double, minValue: Double, topPadding: Double,
                chartStyle: ChartStyle, chartColors: ChartColors) {
        self.chartColors = chartColors
        self.chartStyle = chartStyle
        
        super.init(chartRect: chartRect, maxValue: maxValue, minValue: minValue, topPadding: topPadding)
    }
    
    public override func drawChart(_ lastPoint: CompleteKLineEntity, _ curPoint: CompleteKLineEntity,
                                 lastX: Double, curX: Double, size: CGSize, canvas: CGContext) {
        drawVolume(lastPoint, curPoint, canvas: canvas, lastX: lastX, curX: curX)
    }
    
    private func drawVolume(_ lastPoint: CompleteKLineEntity, _ curPoint: CompleteKLineEntity,
                           canvas: CGContext, lastX: Double, curX: Double) {
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
        
        // 绘制成交量MA线
        if lastPoint.MA5Volume != 0 {
            drawLine(lastPoint.MA5Volume, curPoint.MA5Volume, canvas: canvas, lastX: lastX, curX: curX, color: config.volumeStyle.ma5Color)
        }
        if lastPoint.MA10Volume != 0 {
            drawLine(lastPoint.MA10Volume, curPoint.MA10Volume, canvas: canvas, lastX: lastX, curX: curX, color: config.volumeStyle.ma10Color)
        }
    }
    
    public override func drawText(_ canvas: CGContext, data: CompleteKLineEntity, x: Double) {
        var textComponents: [NSAttributedString] = []
        
        let volText = NSAttributedString(string: "VOL:\(NumberUtil.volFormat(data.volume))    ",
                                       attributes: getTextStyle(chartColors.volColor, fontSize: chartStyle.defaultTextSize))
        textComponents.append(volText)
        
        if data.MA5Volume != 0 {
            let text = NSAttributedString(string: "MA5:\(NumberUtil.volFormat(data.MA5Volume))    ",
                                        attributes: getTextStyle(chartColors.ma5Color, fontSize: chartStyle.defaultTextSize))
            textComponents.append(text)
        }
        if data.MA10Volume != 0 {
            let text = NSAttributedString(string: "MA10:\(NumberUtil.volFormat(data.MA10Volume))    ",
                                        attributes: getTextStyle(chartColors.ma10Color, fontSize: chartStyle.defaultTextSize))
            textComponents.append(text)
        }
        
        guard !textComponents.isEmpty else { return }
        
        let combinedText = NSMutableAttributedString()
        for component in textComponents {
            combinedText.append(component)
        }
        
        let textSize = combinedText.size()
        // 修复位置计算：在图表内部，贴着顶部网格线显示指标参数
        let y = Double(chartRect.minY) + 5
        combinedText.draw(at: CGPoint(x: x, y: y))
    }
    
    public override func drawRightText(_ canvas: CGContext, textStyle: [NSAttributedString.Key: Any], gridRows: Int) {
        let rowSpace = Double(chartRect.height) / Double(gridRows)
        
        for i in 0...gridRows {
            let position = Double(gridRows - i) * rowSpace
            let value = position / scaleY + minValue
            
            let text = NSAttributedString(string: NumberUtil.volFormat(value), attributes: textStyle)
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
