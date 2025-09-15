import UIKit

public class ChartPainter: BaseChartPainter {
    
    private var mainRenderer: MainRenderer?
    private var volRenderer: VolRenderer?
    private var secondaryRenderer: SecondaryRenderer?
    
    // 副图相关
    private var secondaryChartRendererMap: [SecondaryState: any BaseChartRenderer] = [:]
    private var secondaryRectMap: [SecondaryState: CGRect] = [:]
    private var secondaryMaxMinMap: [SecondaryState: KMaxMinEntity] = [:]
    private let secondaryStates: [SecondaryState]
    
    private let chartColors: ChartColors
    
    public init(datas: [CompleteKLineEntity]?, scaleX: Double, scrollX: Double, isLongPress: Bool,
                selectX: Double, chartColors: ChartColors, chartStyle: ChartStyle,
                secondaryStates: [SecondaryState], mainState: MainState, isLine: Bool) {
        self.chartColors = chartColors
        self.secondaryStates = secondaryStates
        
        super.init(datas: datas, scaleX: scaleX, scrollX: scrollX, isLongPress: isLongPress,
                  selectX: selectX, chartStyle: chartStyle, mainState: mainState, isLine: isLine)
    }
    
    public override func initRect(_ size: CGSize) {
        super.initRect(size)
        
        width = Double(size.width)
        marginRight = ((width) / 5 - pointWidth) / scaleX
        
        // 计算主图和副图的高度分配
        let secondaryCount = secondaryStates.count
        
        if secondaryCount == 0 {
            // 没有副图时，主图占据全部高度
            displayHeight = Double(size.height) - chartStyle.topPadding - chartStyle.bottomDateHigh
            mainRect = CGRect(x: 0, y: chartStyle.topPadding, 
                             width: size.width, height: displayHeight)
        } else {
            // 有副图时，主图和副图共享总高度
            displayHeight = Double(size.height) - chartStyle.topPadding - chartStyle.bottomDateHigh
            
            // 计算主图和副图的高度分配
            // 确保主图至少占30%的高度，避免副图过多时主图过小
            let maxSecondaryRatio = min(chartStyle.singleSecondaryMaxHeightRatio * Double(secondaryCount), 0.7)
            let mainHeight = displayHeight * (1.0 - maxSecondaryRatio)
            let secondaryHeight = (displayHeight - mainHeight) / Double(secondaryCount)
            
            // 主图rect
            mainRect = CGRect(x: 0, y: chartStyle.topPadding, 
                             width: size.width, height: mainHeight)
            
            // 副图rect（多个副图垂直排列）
            var secondaryTop = mainRect.maxY
            for secondaryState in secondaryStates {
                let secondaryRect = CGRect(x: 0, y: secondaryTop, 
                                         width: size.width, height: secondaryHeight)
                secondaryRectMap[secondaryState] = secondaryRect
                secondaryTop += secondaryHeight
            }
        }
    }
    
    public override func calculateValue() {
        super.calculateValue()
        
        guard let datas = datas, !datas.isEmpty else { return }
        
        ChartPainter.maxScrollX = abs(getMinTranslateX())
        setTranslateXFromScrollX(scrollX)
        startIndex = indexOfTranslateX(xToTranslateX(0))
        stopIndex = indexOfTranslateX(xToTranslateX(width))
        
        for i in startIndex...stopIndex {
            guard i < datas.count else { break }
            let item = datas[i]
            getMainMaxMinValue(item, i)
        }
        
        // 计算副图最大最小（叠加显示时使用各自的数值范围）
        for secondaryState in secondaryStates {
            var maxMinEntity = secondaryMaxMinMap[secondaryState] ?? 
                              KMaxMinEntity(max: -Double.greatestFiniteMagnitude, min: Double.greatestFiniteMagnitude)
            for i in startIndex...stopIndex {
                guard i < datas.count else { break }
                let item = datas[i]
                getSecondaryMaxMinValue(item, secondaryState, &maxMinEntity)
            }
            secondaryMaxMinMap[secondaryState] = maxMinEntity
        }
    }
    
    public override func initChartRenderer() {
        mainRenderer = MainRenderer(chartRect: mainRect, maxValue: mainMaxValue, minValue: mainMinValue,
                                  topPadding: chartStyle.topPadding, state: mainState, isLine: isLine,
                                  chartStyle: chartStyle, chartColors: chartColors)
        
        // 副图（多个副图分别显示）
        for (secondaryState, rect) in secondaryRectMap {
            let maxMinEntity = secondaryMaxMinMap[secondaryState] ?? 
                              KMaxMinEntity(max: Double.greatestFiniteMagnitude, min: -Double.greatestFiniteMagnitude)
            
            if secondaryState == .vol {
                secondaryChartRendererMap[secondaryState] = VolRenderer(
                    chartRect: rect, maxValue: maxMinEntity.max, minValue: maxMinEntity.min,
                    topPadding: chartStyle.childPadding, chartStyle: chartStyle, chartColors: chartColors)
            } else {
                secondaryChartRendererMap[secondaryState] = SecondaryRenderer(
                    chartRect: rect, maxValue: maxMinEntity.max, minValue: maxMinEntity.min,
                    topPadding: chartStyle.childPadding, secondaryState: secondaryState,
                    chartStyle: chartStyle, chartColors: chartColors)
            }
        }
    }
    
    public override func drawBg(_ canvas: CGContext, _ size: CGSize) {
        canvas.setFillColor(chartColors.bgColor.cgColor)
        
        let mainRect = CGRect(x: 0, y: 0, width: mainRect.width, height: mainRect.height + chartStyle.topPadding)
        canvas.fill(mainRect)
        
        let dateRect = CGRect(x: 0, y: size.height - chartStyle.bottomDateHigh, 
                             width: size.width, height: chartStyle.bottomDateHigh)
        canvas.fill(dateRect)
    }
    
    public override func drawGrid(_ canvas: CGContext) {
        mainRenderer?.drawGrid(canvas, gridRows: chartStyle.gridRows, gridColumns: chartStyle.gridColumns)
        
        for (_, renderer) in secondaryChartRendererMap {
            renderer.drawGrid(canvas, gridRows: chartStyle.gridRows, gridColumns: chartStyle.gridColumns)
        }
    }
    
    public override func drawChart(_ canvas: CGContext, _ size: CGSize) {
        canvas.saveGState()
        canvas.translateBy(x: CGFloat(translateX * scaleX), y: 0)
        canvas.scaleBy(x: CGFloat(scaleX), y: 1)
        
        guard let datas = datas else {
            canvas.restoreGState()
            return
        }
        
        for i in startIndex...stopIndex {
            guard i < datas.count else { break }
            
            let curPoint = datas[i]
            let lastPoint = i == 0 ? curPoint : datas[i - 1]
            let curX = getX(i)
            let lastX = i == 0 ? curX : getX(i - 1)
            
            // 绘制主图
            mainRenderer?.drawChart(lastPoint, curPoint, lastX: lastX, curX: curX, 
                                  size: size, canvas: canvas)
            
            // 绘制副图（多个副图分别绘制）
            for (_, renderer) in secondaryChartRendererMap {
                if let volRenderer = renderer as? VolRenderer {
                    volRenderer.drawChart(lastPoint, curPoint, lastX: lastX, curX: curX, 
                                        size: size, canvas: canvas)
                } else if let secondaryRenderer = renderer as? SecondaryRenderer {
                    secondaryRenderer.drawChart(lastPoint, curPoint, lastX: lastX, curX: curX, 
                                              size: size, canvas: canvas)
                }
            }
        }
        
        if isLongPress {
            drawCrossLine(canvas, size)
        }
        
        canvas.restoreGState()
    }
    
    public override func drawRightText(_ canvas: CGContext) {
        let textStyle = getTextStyle(chartColors.yAxisTextColor)
        mainRenderer?.drawRightText(canvas, textStyle: textStyle, gridRows: chartStyle.gridRows)
        
        for (_, renderer) in secondaryChartRendererMap {
            renderer.drawRightText(canvas, textStyle: textStyle, gridRows: chartStyle.gridRows)
        }
    }
    
    
    public override func drawDate(_ canvas: CGContext, _ size: CGSize) {
        let columnSpace = Double(size.width) / Double(chartStyle.gridColumns)
        let startX = getX(startIndex) - pointWidth / 2
        let stopX = getX(stopIndex) + pointWidth / 2
        
        for i in 0...chartStyle.gridColumns {
            let translateX = xToTranslateX(columnSpace * Double(i))
            if translateX >= startX && translateX <= stopX {
                let index = indexOfTranslateX(translateX)
                guard let datas = datas, index < datas.count else { continue }
                
                let dateText = DataUtil.getDate(datas[index].timestamp)
                let text = NSAttributedString(string: dateText, attributes: getTextStyle(chartColors.xAxisTextColor))
                let textSize = text.size()
                let y = Double(size.height) - (chartStyle.bottomDateHigh - textSize.height) / 2 - textSize.height
                text.draw(at: CGPoint(x: columnSpace * Double(i) - textSize.width / 2, y: y))
            }
        }
    }
    
    public override func drawCrossLineText(_ canvas: CGContext, _ size: CGSize) {
        let index = calculateSelectedX(selectX)
        guard let point = getItem(index) else { return }
        
        let text = NSAttributedString(string: format(point.close), attributes: getTextStyle(.white))
        let textHeight = text.size().height
        let textWidth = text.size().width
        
        let w1: Double = 5
        let w2: Double = 3
        let r = textHeight / 2 + w2
        let y = mainRenderer?.getY(point.close) ?? 0
        let x: Double
        let isLeft: Bool
        
        if translateXtoX(getX(index)) < width / 2 {
            isLeft = false
            x = 1
            // 绘制右侧信息框
            drawInfoBox(canvas, x: x, y: y, width: textWidth + 2 * w1 + w2, height: 2 * r, isLeft: false)
            text.draw(at: CGPoint(x: x + w1, y: y - textHeight / 2))
        } else {
            isLeft = true
            x = width - textWidth - 1 - 2 * w1 - w2
            // 绘制左侧信息框
            drawInfoBox(canvas, x: x, y: y, width: textWidth + 2 * w1 + w2, height: 2 * r, isLeft: true)
            text.draw(at: CGPoint(x: x + w1 + w2, y: y - textHeight / 2))
        }
        
        // 绘制日期信息
        let dateText = DataUtil.getDate(point.timestamp)
        let dateTextAttr = NSAttributedString(string: dateText, attributes: getTextStyle(.white))
        let dateTextWidth = dateTextAttr.size().width
        let dateX = translateXtoX(getX(index))
        let dateY = Double(size.height) - chartStyle.bottomDateHigh
        
        let adjustedDateX: Double
        if dateX < dateTextWidth + 2 * w1 {
            adjustedDateX = 1 + dateTextWidth / 2 + w1
        } else if width - dateX < dateTextWidth + 2 * w1 {
            adjustedDateX = width - 1 - dateTextWidth / 2 - w1
        } else {
            adjustedDateX = dateX
        }
        
        let baseLine = textHeight / 2
        let dateRect = CGRect(x: adjustedDateX - dateTextWidth / 2 - w1, y: dateY,
                             width: dateTextWidth + 2 * w1, height: baseLine + r)
        
        canvas.setFillColor(chartColors.markerBgColor.cgColor)
        canvas.setStrokeColor(chartColors.markerBorderColor.cgColor)
        canvas.setLineWidth(0.5)
        canvas.fill(dateRect)
        canvas.stroke(dateRect)
        
        dateTextAttr.draw(at: CGPoint(x: adjustedDateX - dateTextWidth / 2, y: dateY))
    }
    
    private func drawInfoBox(_ canvas: CGContext, x: Double, y: Double, width: Double, height: Double, isLeft: Bool) {
        let path = CGMutablePath()
        let w1: Double = 5
        let w2: Double = 3
        let r = height / 2
        
        if isLeft {
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x + w2, y: y + r))
            path.addLine(to: CGPoint(x: x + width, y: y + r))
            path.addLine(to: CGPoint(x: x + width, y: y - r))
            path.addLine(to: CGPoint(x: x + w2, y: y - r))
            path.closeSubpath()
        } else {
            path.move(to: CGPoint(x: x, y: y - r))
            path.addLine(to: CGPoint(x: x, y: y + r))
            path.addLine(to: CGPoint(x: x + width, y: y + r))
            path.addLine(to: CGPoint(x: x + width + w2, y: y))
            path.addLine(to: CGPoint(x: x + width, y: y - r))
            path.closeSubpath()
        }
        
        canvas.setFillColor(chartColors.markerBgColor.cgColor)
        canvas.setStrokeColor(chartColors.markerBorderColor.cgColor)
        canvas.setLineWidth(0.5)
        canvas.addPath(path)
        canvas.fillPath()
        canvas.addPath(path)
        canvas.strokePath()
    }
    
    public override func drawText(_ canvas: CGContext, _ data: CompleteKLineEntity, _ x: Double) {
        let dataToShow = isLongPress ? (getItem(calculateSelectedX(selectX)) ?? data) : data
        mainRenderer?.drawText(canvas, data: dataToShow, x: x)
        
        for (_, renderer) in secondaryChartRendererMap {
            if let mainRenderer = renderer as? MainRenderer {
                mainRenderer.drawText(canvas, data: dataToShow, x: x)
            } else if let volRenderer = renderer as? VolRenderer {
                volRenderer.drawText(canvas, data: dataToShow, x: x)
            } else if let secondaryRenderer = renderer as? SecondaryRenderer {
                secondaryRenderer.drawText(canvas, data: dataToShow, x: x)
            }
        }
    }
    
    public override func drawMaxAndMin(_ canvas: CGContext) {
        guard !isLine else { return }
        
        // 绘制最大值和最小值
        let minX = translateXtoX(getX(mainMinIndex))
        let minY = mainRenderer?.getY(mainLowMinValue) ?? 0
        
        if minX < width / 2 {
            let text = NSAttributedString(string: "── \(format(mainLowMinValue))", 
                                        attributes: getTextStyle(chartColors.maxMinTextColor))
            text.draw(at: CGPoint(x: minX, y: minY - text.size().height / 2))
        } else {
            let text = NSAttributedString(string: "\(format(mainLowMinValue)) ──", 
                                        attributes: getTextStyle(chartColors.maxMinTextColor))
            text.draw(at: CGPoint(x: minX - text.size().width, y: minY - text.size().height / 2))
        }
        
        let maxX = translateXtoX(getX(mainMaxIndex))
        let maxY = mainRenderer?.getY(mainHighMaxValue) ?? 0
        
        if maxX < width / 2 {
            let text = NSAttributedString(string: "── \(format(mainHighMaxValue))", 
                                        attributes: getTextStyle(chartColors.maxMinTextColor))
            text.draw(at: CGPoint(x: maxX, y: maxY - text.size().height / 2))
        } else {
            let text = NSAttributedString(string: "\(format(mainHighMaxValue)) ──", 
                                        attributes: getTextStyle(chartColors.maxMinTextColor))
            text.draw(at: CGPoint(x: maxX - text.size().width, y: maxY - text.size().height / 2))
        }
    }
    
    private func drawCrossLine(_ canvas: CGContext, _ size: CGSize) {
        let index = calculateSelectedX(selectX)
        guard let point = getItem(index) else { return }
        
        canvas.setStrokeColor(chartColors.xyLineColor.cgColor)
        canvas.setLineWidth(CGFloat(chartStyle.vCrossWidth))
        
        let x = getX(index)
        let y = mainRenderer?.getY(point.close) ?? 0
        
        // 绘制竖线
        canvas.move(to: CGPoint(x: x, y: chartStyle.topPadding))
        canvas.addLine(to: CGPoint(x: x, y: Double(size.height) - chartStyle.bottomDateHigh))
        canvas.strokePath()
        
        // 绘制横线
        canvas.setLineWidth(CGFloat(chartStyle.hCrossWidth))
        canvas.move(to: CGPoint(x: -translateX, y: y))
        canvas.addLine(to: CGPoint(x: -translateX + width / scaleX, y: y))
        canvas.strokePath()
        
        // 绘制交叉点
        canvas.setFillColor(chartColors.pointColor.cgColor)
        canvas.fillEllipse(in: CGRect(x: x - 2, y: y - 2, width: 4, height: 4))
    }
    
    public override func drawRealTimePrice(_ canvas: CGContext, _ size: CGSize) {
        guard marginRight != 0, let datas = datas, !datas.isEmpty else { return }
        
        let point = datas.last!
        let text = NSAttributedString(string: format(point.close), 
                                    attributes: getTextStyle(chartColors.rightRealTimeTextColor))
        let textPadding: Double = 5
        let y = mainRenderer?.getY(point.close) ?? 0
        
        let max = (abs(translateX) + marginRight - abs(getMinTranslateX()) + pointWidth) * scaleX
        var x = width - max
        if !isLine { x += pointWidth / 2 }
        
        let dashWidth = chartStyle.dashWidth
        let dashSpace = chartStyle.dashSpace
        var startX: Double = 0
        let space = dashSpace + dashWidth
        
        if text.size().width < max {
            if chartStyle.isShowDashLine {
                // 绘制虚线
                while startX < (max - text.size().width - textPadding - textPadding) {
                    canvas.setStrokeColor(chartColors.realTimeLineColor.cgColor)
                    canvas.setLineWidth(1.0)
                    canvas.move(to: CGPoint(x: x + startX, y: y))
                    canvas.addLine(to: CGPoint(x: x + startX + dashWidth, y: y))
                    canvas.strokePath()
                    startX += space
                }
            }
            
            // 绘制价格背景
            let left = width - text.size().width
            let top = y - text.size().height / 2
            let radius: Double = 2
            
            let rect = CGRect(x: left - textPadding, y: top, 
                             width: text.size().width + 2 * textPadding, height: text.size().height)
            let roundedRect = UIBezierPath(roundedRect: rect, cornerRadius: CGFloat(radius))
            
            canvas.setFillColor(chartColors.realTimeBgColor.cgColor)
            canvas.addPath(roundedRect.cgPath)
            canvas.fillPath()
            
            text.draw(at: CGPoint(x: left, y: top))
        } else {
            // 价格显示在图表上
            startX = 0
            let adjustedY: Double
            if point.close > mainMaxValue {
                adjustedY = mainRenderer?.getY(mainMaxValue) ?? y
            } else if point.close < mainMinValue {
                adjustedY = mainRenderer?.getY(mainMinValue) ?? y
            } else {
                adjustedY = y
            }
            
            if chartStyle.isShowDashLine {
                // 绘制长虚线
                while startX < width {
                    canvas.setStrokeColor(chartColors.realTimeLongLineColor.cgColor)
                    canvas.setLineWidth(1.0)
                    canvas.move(to: CGPoint(x: startX, y: adjustedY))
                    canvas.addLine(to: CGPoint(x: startX + dashWidth, y: adjustedY))
                    canvas.strokePath()
                    startX += space
                }
            }
            
            // 绘制带三角形的价格标签
            let padding: Double = 3
            let triangleHeight: Double = 8
            let triangleWidth: Double = 5
            
            let left = width - text.size().width * 2.5
            let top = adjustedY - text.size().height / 2 - padding
            let right = left + text.size().width + padding * 2 + triangleWidth + padding
            let bottom = top + text.size().height + padding * 2
            let rectRadius = (bottom - top) / 2
            
            let rect = CGRect(x: left, y: top, width: right - left, height: bottom - top)
            let roundedRect = UIBezierPath(roundedRect: rect, cornerRadius: CGFloat(rectRadius))
            
            canvas.setFillColor(chartColors.realTimeBgColor.cgColor)
            canvas.setStrokeColor(chartColors.realTimeTextBorderColor.cgColor)
            canvas.setLineWidth(1.0)
            canvas.addPath(roundedRect.cgPath)
            canvas.fillPath()
            canvas.addPath(roundedRect.cgPath)
            canvas.strokePath()
            
            text.draw(at: CGPoint(x: left + padding, y: adjustedY - text.size().height / 2))
            
            // 绘制三角形
            let trianglePath = CGMutablePath()
            let dx = text.size().width + left + padding + padding
            let dy = top + (bottom - top - triangleHeight) / 2
            trianglePath.move(to: CGPoint(x: dx, y: dy))
            trianglePath.addLine(to: CGPoint(x: dx + triangleWidth, y: dy + triangleHeight / 2))
            trianglePath.addLine(to: CGPoint(x: dx, y: dy + triangleHeight))
            trianglePath.closeSubpath()
            
            canvas.setFillColor(chartColors.realTimeTextColor.cgColor)
            canvas.addPath(trianglePath)
            canvas.fillPath()
        }
    }
}
