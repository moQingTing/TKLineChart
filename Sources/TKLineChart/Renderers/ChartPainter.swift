import UIKit

public class ChartPainter: BaseChartPainter {
    nonisolated(unsafe) public static var lastRealTimeLabelRect: CGRect = .zero
    
    private var mainRenderer: MainRenderer?
    private var secondaryRenderer: SecondaryRenderer?
    
    // 副图相关
    private var secondaryChartRendererMap: [SecondaryState: BaseChartRendererImpl<CompleteKLineEntity>] = [:]
    private var secondaryRectMap: [SecondaryState: CGRect] = [:]
    private var secondaryMaxMinMap: [SecondaryState: KMaxMinEntity] = [:]
    private let secondaryStates: [SecondaryState]
    
    private let chartColors: ChartColors
    private let chartConfiguration: ChartConfiguration
    
    private let selectY: Double

    public init(datas: [CompleteKLineEntity]?, scaleX: Double, scrollX: Double, isLongPress: Bool,
                selectX: Double, selectY: Double, chartColors: ChartColors,
                secondaryStates: [SecondaryState], mainState: MainState, isLine: Bool,
                chartConfiguration: ChartConfiguration) {
        self.chartColors = chartColors
        self.chartConfiguration = chartConfiguration
        self.secondaryStates = secondaryStates
        self.selectY = selectY
        
        super.init(datas: datas, scaleX: scaleX, scrollX: scrollX, isLongPress: isLongPress,
                  selectX: selectX, mainState: mainState, isLine: isLine)
        
        // 传递价格和成交量格式化回调
        self.priceFormatter = chartConfiguration.priceFormatter
        self.volumeFormatter = chartConfiguration.volumeFormatter
    }
    
    public override func initRect(_ size: CGSize) {
        super.initRect(size)
        
        width = Double(size.width)
        // 恢复对实时价格 rightInset 的支持：在布局层面为右侧增加可配置留白
        // 注意：rightInset 是屏幕像素，这里需按 scaleX 转为内容坐标
        let rtInset = chartConfiguration.chartStyleConfig.realTimePriceStyle.rightInset / scaleX
        marginRight = ((width) / 5 - pointWidth) / scaleX + rtInset
        
        // 计算主图和副图的高度分配
        let secondaryCount = secondaryStates.count
        
        if secondaryCount == 0 {
            // 没有副图时，主图占据全部高度
            displayHeight = Double(size.height) - chartConfiguration.chartStyleConfig.topPadding - chartConfiguration.chartStyleConfig.bottomDateHigh
            mainRect = CGRect(x: 0, y: chartConfiguration.chartStyleConfig.topPadding, 
                             width: size.width, height: displayHeight)
        } else {
            // 有副图时，主图和副图共享总高度
            displayHeight = Double(size.height) - chartConfiguration.chartStyleConfig.topPadding - chartConfiguration.chartStyleConfig.bottomDateHigh
            
            // 计算主图和副图的高度分配
            // 确保主图至少占30%的高度，避免副图过多时主图过小
            let maxSecondaryRatio = min(chartConfiguration.chartStyleConfig.singleSecondaryMaxHeightRatio * Double(secondaryCount), 0.7)
            let mainHeight = displayHeight * (1.0 - maxSecondaryRatio)
            let secondaryHeight = (displayHeight - mainHeight) / Double(secondaryCount)
            
            // 主图rect
            mainRect = CGRect(x: 0, y: chartConfiguration.chartStyleConfig.topPadding, 
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
                                  topPadding: chartConfiguration.chartStyleConfig.topPadding, state: mainState, isLine: isLine,
                                  chartColors: chartColors,
                                  chartConfiguration: chartConfiguration)
        
        // 副图（多个副图分别显示）
        for (secondaryState, rect) in secondaryRectMap {
            let maxMinEntity = secondaryMaxMinMap[secondaryState] ?? 
                              KMaxMinEntity(max: Double.greatestFiniteMagnitude, min: -Double.greatestFiniteMagnitude)
            
            secondaryChartRendererMap[secondaryState] = SecondaryRenderer(
                chartRect: rect, maxValue: maxMinEntity.max, minValue: maxMinEntity.min,
                topPadding: chartConfiguration.chartStyleConfig.childPadding, secondaryState: secondaryState,
                chartColors: chartColors,
                chartConfiguration: chartConfiguration)
        }
    }
    
    public override func drawBg(_ canvas: CGContext, _ size: CGSize) {
        canvas.setFillColor(chartColors.bgColor.cgColor)
        let mainRect = CGRect(x: 0, y: 0, width: mainRect.width, height: mainRect.height + chartConfiguration.chartStyleConfig.topPadding)
        canvas.fill(mainRect)

        // 底部日期带背景使用 xAxisTextBgColor（黑色），以便白色日期文字可见
        let dateRect = CGRect(x: 0, y: size.height - chartConfiguration.chartStyleConfig.bottomDateHigh,
                             width: size.width, height: chartConfiguration.chartStyleConfig.bottomDateHigh)
        // canvas.setFillColor(chartColors.xAxisTextBgColor.cgColor)
        canvas.fill(dateRect)
    }
    
    public override func drawGrid(_ canvas: CGContext) {
        mainRenderer?.drawGrid(canvas, gridRows: chartConfiguration.chartStyleConfig.gridRows, gridColumns: chartConfiguration.chartStyleConfig.gridColumns)
        
        for (_, renderer) in secondaryChartRendererMap {
            renderer.drawGrid(canvas, gridRows: chartConfiguration.chartStyleConfig.gridRows, gridColumns: chartConfiguration.chartStyleConfig.gridColumns)
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
                renderer.drawChart(lastPoint, curPoint, lastX: lastX, curX: curX, size: size, canvas: canvas)
            }
        }
        
        if isLongPress {
            drawCrossLine(canvas, size)
        }
        
        canvas.restoreGState()
    }
    
    public override func drawRightText(_ canvas: CGContext) {
        let textStyle = getTextStyle(chartColors.yAxisTextColor)
        mainRenderer?.drawRightText(canvas, textStyle: textStyle, gridRows: chartConfiguration.chartStyleConfig.gridRows)
        
        for (_, renderer) in secondaryChartRendererMap {
            renderer.drawRightText(canvas, textStyle: textStyle, gridRows: chartConfiguration.chartStyleConfig.gridRows)
        }
    }
    
    
    public override func drawDate(_ canvas: CGContext, _ size: CGSize) {
        let columnSpace = Double(size.width) / Double(chartConfiguration.chartStyleConfig.gridColumns)
        let startX = getX(startIndex) - pointWidth / 2
        let stopX = getX(stopIndex) + pointWidth / 2
        
        for i in 0...chartConfiguration.chartStyleConfig.gridColumns {
            let translateX = xToTranslateX(columnSpace * Double(i))
            if translateX >= startX && translateX <= stopX {
                let index = indexOfTranslateX(translateX)
                guard let datas = datas, index < datas.count else { continue }
                
                let dateText = DataUtil.getDate(datas[index].timestamp)
                let text = NSAttributedString(string: dateText, attributes: getTextStyle(chartColors.xAxisTextColor))
                let textSize = text.size()
                let y = Double(size.height) - (chartConfiguration.chartStyleConfig.bottomDateHigh - textSize.height) / 2 - textSize.height
                text.draw(at: CGPoint(x: columnSpace * Double(i) - textSize.width / 2, y: y))
            }
        }
    }
    
    public override func drawCrossLineText(_ canvas: CGContext, _ size: CGSize) {
        let index = calculateSelectedX(selectX)
        guard let point = getItem(index) else { return }
        
        // 根据主图Y坐标反算价格，使点击点不是固定close，而是主图纵坐标对应值
        let selectedPrice: Double
        if let mainRenderer = mainRenderer {
            // 反推价格：value = maxValue - (y - minY) / scaleY
            let yInMain = min(max(selectY, Double(mainRenderer.chartRect.minY)), Double(mainRenderer.chartRect.maxY))
            selectedPrice = mainRenderer.maxValue - (yInMain - Double(mainRenderer.chartRect.minY)) / mainRenderer.scaleY
        } else {
            selectedPrice = point.close
        }
        
        // 选中价格文字颜色：白色
        let textColor = chartColors.selectedPriceTextColor
        let text = NSAttributedString(string: format(selectedPrice), attributes: getTextStyle(textColor))
        let textHeight = text.size().height
        let textWidth = text.size().width
        
        let w1: Double = 5
        let w2: Double = 3
        let r = textHeight / 2 + w2
        let y: Double
        if let mainRenderer = mainRenderer {
            y = mainRenderer.getY(selectedPrice)
        } else {
            y = 0
        }
        let x: Double
        let isLeft: Bool
        
        // 根据点击位置决定信息面板显示在左侧还是右侧
        // 点击在左侧时，信息面板显示在右侧；点击在右侧时，信息面板显示在左侧
        if translateXtoX(getX(index)) < width / 2 {
            isLeft = false  // 点击在左侧，信息面板显示在右侧
        } else {
            isLeft = true   // 点击在右侧，信息面板显示在左侧
        }
        
        // 价格标签始终显示在右侧,价格显示的横坐标位置
        x = width - textWidth - 1 - 2 * w1 - w2
        // 绘制价格右侧框
        drawInfoBox(canvas, x: x, y: y, width: textWidth + 2 * w1 + w2, height: 2 * r, isLeft: false)
        text.draw(at: CGPoint(x: x + w1 + w2/2, y: y - textHeight / 2))
        
        // 绘制日期信息（严格居中于竖线底部）
        let dateText = DataUtil.getDate(point.timestamp)
        // 底部时间文字颜色：白色
        let dateTextAttr = NSAttributedString(string: dateText, attributes: getTextStyle(textColor))
        let dateTextWidth = dateTextAttr.size().width
        let bandTop = Double(size.height) - chartConfiguration.chartStyleConfig.bottomDateHigh
        let baseLine = textHeight / 2
        let extraHeight: Double = 4 // 时间背景额外高度
        let rectHeight = baseLine + r + extraHeight
        let rectWidth = dateTextWidth + 2 * w1
        
        // 目标中心点：与竖线相同的屏幕X
        let targetCenterX = translateXtoX(getX(index))
        
        // 优先使用“居中于竖线”的矩形X
        var rectX = targetCenterX - rectWidth / 2
        // 边界保护：完整气泡不越界
        if rectX < 0 { rectX = 0 }
        if rectX + rectWidth > width { rectX = width - rectWidth }
        
        // 在底部日期带内垂直居中
        var dateY = bandTop + (chartConfiguration.chartStyleConfig.bottomDateHigh - rectHeight) / 2
        if dateY < bandTop { dateY = bandTop }
        if dateY + rectHeight > bandTop + chartConfiguration.chartStyleConfig.bottomDateHigh { dateY = bandTop + chartConfiguration.chartStyleConfig.bottomDateHigh - rectHeight }
        
        // 复用 drawInfoBox 方法绘制时间背景框
        drawInfoBox(canvas, x: rectX, y: dateY + rectHeight / 2, width: rectWidth, height: rectHeight, isLeft: false)
        
        // 文本在矩形内部水平、垂直居中
        let dateSize = dateTextAttr.size()
        let dateTextX = rectX + (rectWidth - dateSize.width) / 2
        let dateTextY = dateY + (rectHeight - dateSize.height) / 2
        dateTextAttr.draw(at: CGPoint(x: dateTextX, y: dateTextY))
        // 选中信息面板
        drawSelectedInfoPanel(canvas, size, point, isLeft: isLeft,priceTextX: x)
    }

    private func drawSelectedInfoPanel(_ canvas: CGContext, _ size: CGSize, _ point: CompleteKLineEntity, isLeft: Bool,priceTextX:Double) {
        guard let mainRenderer = mainRenderer else { return }
        let infoStyle = chartConfiguration.infoPanelStyle
        let padding: Double = 8
        let lineSpace: Double = 4
        // 面板字体统一黑色
        let valueColor = infoStyle.textColor
        let labelColor = infoStyle.textColor
        let upColor = chartConfiguration.candleStyle.upColor
        let downColor = chartConfiguration.candleStyle.downColor

        let change = point.close - point.open
        let changePct = point.open == 0 ? 0 : change / point.open * 100
        let amplitudePct = point.open == 0 ? 0 : (point.high - point.low) / point.open * 100

        let timeText = NSAttributedString(string: DataUtil.getDate(point.timestamp), attributes: getTextStyle(valueColor))
        let openText = NSAttributedString(string: format(point.open), attributes: getTextStyle(valueColor))
        let highText = NSAttributedString(string: format(point.high), attributes: getTextStyle(valueColor))
        let lowText = NSAttributedString(string: format(point.low), attributes: getTextStyle(valueColor))
        let closeText = NSAttributedString(string: format(point.close), attributes: getTextStyle(valueColor))
        let changeColor = change >= 0 ? upColor : downColor
        let changeText = NSAttributedString(string: "\(format(change)) (\(String(format: "%.2f", changePct))%)", attributes: getTextStyle(changeColor))
        let amplitudeText = NSAttributedString(string: String(format: "%.2f%%", amplitudePct), attributes: getTextStyle(valueColor))
        let volumeText = NSAttributedString(string: formatVolume(point.volume), attributes: getTextStyle(valueColor))
        let amountText = NSAttributedString(string: formatVolume(point.amount), attributes: getTextStyle(valueColor))

        let i18n = chartConfiguration.infoPanelTexts
        let labels = [
            NSAttributedString(string: i18n.time, attributes: getTextStyle(labelColor)),
            NSAttributedString(string: i18n.open, attributes: getTextStyle(labelColor)),
            NSAttributedString(string: i18n.high, attributes: getTextStyle(labelColor)),
            NSAttributedString(string: i18n.low, attributes: getTextStyle(labelColor)),
            NSAttributedString(string: i18n.close, attributes: getTextStyle(labelColor)),
            NSAttributedString(string: i18n.change, attributes: getTextStyle(labelColor)),
            NSAttributedString(string: i18n.amplitude, attributes: getTextStyle(labelColor)),
            NSAttributedString(string: i18n.volume, attributes: getTextStyle(labelColor)),
            NSAttributedString(string: i18n.amount, attributes: getTextStyle(labelColor))
        ]
        let values = [timeText, openText, highText, lowText, closeText, changeText, amplitudeText, volumeText, amountText]

        var labelMaxW: Double = 0
        var valueMaxW: Double = 0
        for l in labels { labelMaxW = max(labelMaxW, l.size().width) }
        for v in values { valueMaxW = max(valueMaxW, v.size().width) }
        let contentW = labelMaxW + 10 + valueMaxW
        let lineH = values.first?.size().height ?? 12
        let contentH = Double(values.count) * (lineH + lineSpace) - lineSpace
        let rectW = contentW + padding * 2
        let rectH = contentH + padding * 2

        let leftX = Double(mainRenderer.chartRect.minX) + 8
        let rightX = Double(mainRenderer.chartRect.maxX) - rectW - 8
        var panelX = isLeft ? leftX : rightX
        let panelY = Double(mainRenderer.chartRect.minY) + 8
        
        // 当信息面板显示在右侧时，需要为价格标签预留空间
        let priceLabelReservedWidth: Double = Double(mainRenderer.chartRect.maxX) - priceTextX
        let maxRightX = Double(mainRenderer.chartRect.maxX) - priceLabelReservedWidth
        
        // 如果信息面板在右侧且会与价格标签重叠，则调整位置
        if !isLeft && panelX < maxRightX {
            panelX = maxRightX - rectW
        }

        let rect = CGRect(x: panelX, y: panelY, width: rectW, height: rectH)
        let rounded = UIBezierPath(roundedRect: rect, cornerRadius: CGFloat(infoStyle.cornerRadius))
        canvas.setFillColor(infoStyle.backgroundColor.cgColor)
        // 无边框
        canvas.addPath(rounded.cgPath)
        canvas.fillPath()

        var cursorY = panelY + padding
        // 列右边界（用于右对齐数值）
        let valueRightX = panelX + padding + labelMaxW + 10 + valueMaxW
        for i in 0..<values.count {
            let l = labels[i]
            let v = values[i]
            // 标题（标签）左对齐
            l.draw(at: CGPoint(x: panelX + padding, y: cursorY))
            // 数值右对齐
            v.draw(at: CGPoint(x: valueRightX - v.size().width, y: cursorY))
            cursorY += lineH + lineSpace
        }
    }
    
    private func drawInfoBox(_ canvas: CGContext, x: Double, y: Double, width: Double, height: Double, isLeft: Bool) {
        let r = height / 2
        let rect = CGRect(x: x, y: y - r, width: width, height: height)
        let rounded = UIBezierPath(roundedRect: rect, cornerRadius: 4)
        
        canvas.setFillColor(chartColors.markerBgColor.cgColor)
        canvas.addPath(rounded.cgPath)
        canvas.fillPath()
        
        canvas.setStrokeColor(chartColors.markerBorderColor.cgColor)
        canvas.setLineWidth(0.5)
        canvas.addPath(rounded.cgPath)
        canvas.strokePath()
    }
    
    public override func drawText(_ canvas: CGContext, _ data: CompleteKLineEntity, _ x: Double) {
        let dataToShow = isLongPress ? (getItem(calculateSelectedX(selectX)) ?? data) : data
        mainRenderer?.drawText(canvas, data: dataToShow, x: x)
        
        for (_, renderer) in secondaryChartRendererMap {
            renderer.drawText(canvas, data: dataToShow, x: x)
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
        
        // 使用配置的交叉线颜色
        let crossLineColor = chartConfiguration.chartStyleConfig.crossLineColor
        canvas.setStrokeColor(crossLineColor.cgColor)
        canvas.setLineWidth(CGFloat(chartConfiguration.chartStyleConfig.vCrossWidth))
        // 使用虚线样式
        if chartConfiguration.chartStyleConfig.dashWidth > 0 && chartConfiguration.chartStyleConfig.dashSpace > 0 {
            canvas.setLineDash(phase: 0, lengths: [CGFloat(chartConfiguration.chartStyleConfig.dashWidth), CGFloat(chartConfiguration.chartStyleConfig.dashSpace)])
        }
        
        let x = getX(index)
        let y: Double
        if let mainRenderer = mainRenderer {
            let yInMain = min(max(selectY, Double(mainRenderer.chartRect.minY)), Double(mainRenderer.chartRect.maxY))
            let price = mainRenderer.maxValue - (yInMain - Double(mainRenderer.chartRect.minY)) / mainRenderer.scaleY
            y = mainRenderer.getY(price)
        } else {
            y = 0
        }
        
        // 绘制竖线
        canvas.move(to: CGPoint(x: x, y: chartConfiguration.chartStyleConfig.topPadding))
        canvas.addLine(to: CGPoint(x: x, y: Double(size.height) - chartConfiguration.chartStyleConfig.bottomDateHigh))
        canvas.strokePath()
        
        // 绘制横线
        canvas.setLineWidth(CGFloat(chartConfiguration.chartStyleConfig.hCrossWidth))
        canvas.move(to: CGPoint(x: -translateX, y: y))
        canvas.addLine(to: CGPoint(x: -translateX + width / scaleX, y: y))
        canvas.strokePath()
        
        // 绘制交叉点（使用配置的交叉点颜色）
        let crossPointColor = chartConfiguration.chartStyleConfig.crossPointColor
        canvas.setFillColor(crossPointColor.cgColor)
        canvas.fillEllipse(in: CGRect(x: x - 2, y: y - 2, width: 4, height: 4))
        // 取消虚线设置，避免影响后续绘制
        canvas.setLineDash(phase: 0, lengths: [])
    }
    
    public override func drawRealTimePrice(_ canvas: CGContext, _ size: CGSize) {
        guard marginRight != 0, let datas = datas, !datas.isEmpty else { return }
        // 默认清空
        ChartPainter.lastRealTimeLabelRect = .zero

        let point = datas.last!
        // 实时价格文字（使用样式配置）
        let rt = chartConfiguration.chartStyleConfig.realTimePriceStyle
        let text = NSAttributedString(string: format(point.close), 
                                    attributes: getTextStyle(rt.labelTextColor))
        let textPadding: Double = rt.labelTextPadding
        let y = mainRenderer?.getY(point.close) ?? 0
        
        let max = (abs(translateX) + marginRight - abs(getMinTranslateX()) + pointWidth) * scaleX
        var x = width - max
        if !isLine { x += pointWidth / 2 }
        
        // 虚线参数（来自样式配置）
        var dashWidth = rt.dashWidth
        var dashSpace = rt.dashSpace
        if dashSpace < 1.0 { dashSpace = 1.0 }
        var startX: Double = 0
        let space = dashSpace + dashWidth
        
        if text.size().width < max {
            if chartConfiguration.chartStyleConfig.isShowDashLine {
                // 绘制虚线（使用样式颜色和宽度）
                while startX < (max - text.size().width - textPadding - textPadding) {
                    canvas.setStrokeColor(rt.lineColor.cgColor)
                    canvas.setLineWidth(rt.dashLineWidth)
                    canvas.move(to: CGPoint(x: x + startX, y: y))
                    canvas.addLine(to: CGPoint(x: x + startX + dashWidth, y: y))
                    canvas.strokePath()
                    startX += space
                }
            }
            
            // 绘制价格背景（使用样式配置）
            // 纠正越界：背景矩形右对齐在屏幕内
            let extraPadding: Double = 4.0  // 额外的内间距
            let rectWidth = text.size().width + 2 * (textPadding + extraPadding)
            let edgeInset: Double = 1.0 // 防边框被遮住
            var left = width - rectWidth - edgeInset
            if left < 0 { left = 0 }
            let top = y - text.size().height / 2 - rt.labelExtraHeight / 2
            let radius: Double = rt.labelCornerRadius
            
            let rect = CGRect(x: left, y: top, 
                             width: rectWidth, height: text.size().height + rt.labelExtraHeight)
            let roundedRect = UIBezierPath(roundedRect: rect, cornerRadius: CGFloat(radius))
            ChartPainter.lastRealTimeLabelRect = rect
            
            canvas.setFillColor(rt.labelBgColor.cgColor)
            canvas.addPath(roundedRect.cgPath)
            canvas.fillPath()
            canvas.setStrokeColor(rt.labelBorderColor.cgColor)
            canvas.setLineWidth(0.5)
            canvas.addPath(roundedRect.cgPath)
            canvas.strokePath()
            
            let textY = Double(rect.midY) - text.size().height / 2
            text.draw(at: CGPoint(x: left + textPadding + extraPadding, y: textY))
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
            
            if chartConfiguration.chartStyleConfig.isShowDashLine {
                // 绘制长虚线（使用样式颜色和宽度）
                while startX < width {
                    canvas.setStrokeColor(rt.lineColor.cgColor)
                    canvas.setLineWidth(rt.dashLineWidth)
                    canvas.move(to: CGPoint(x: startX, y: adjustedY))
                    canvas.addLine(to: CGPoint(x: startX + dashWidth, y: adjustedY))
                    canvas.strokePath()
                    startX += space
                }
            }
            
            // 绘制带三角形的价格标签（使用样式配置）
            let padding: Double = Swift.max(3.0, textPadding / 2)
            let extraPadding: Double = 4.0  // 额外的左右内间距
            let triangleHeight: Double = rt.triangleHeight
            let triangleWidth: Double = rt.triangleWidth
            
            var left = width - text.size().width * 2.5
            let top = adjustedY - text.size().height / 2 - padding - rt.labelExtraHeight / 2
            var right = left + text.size().width + padding * 2 + triangleWidth + padding + extraPadding * 2
            let bottom = top + text.size().height + padding * 2 + rt.labelExtraHeight
            let rectRadius = (bottom - top) / 2
            // 右侧防裁剪
            let edgeInset2: Double = 1.0
            if right > width - edgeInset2 {
                let shift = right - (width - edgeInset2)
                left -= shift
                right -= shift
            }
            
            let rect = CGRect(x: left, y: top, width: right - left, height: bottom - top)
            let roundedRect = UIBezierPath(roundedRect: rect, cornerRadius: CGFloat(rectRadius))
            ChartPainter.lastRealTimeLabelRect = rect
            
            canvas.setFillColor(rt.labelBgColor.cgColor)
            canvas.setStrokeColor(rt.labelBorderColor.cgColor)
            canvas.setLineWidth(1.0)
            canvas.addPath(roundedRect.cgPath)
            canvas.fillPath()
            canvas.addPath(roundedRect.cgPath)
            canvas.strokePath()
            
            let textY = Double(rect.midY) - text.size().height / 2
            text.draw(at: CGPoint(x: left + padding + extraPadding, y: textY))
            
            // 绘制三角形
            let trianglePath = CGMutablePath()
            let dx = text.size().width + left + padding + extraPadding + padding
            let dy = top + (bottom - top - triangleHeight) / 2
            trianglePath.move(to: CGPoint(x: dx, y: dy))
            trianglePath.addLine(to: CGPoint(x: dx + triangleWidth, y: dy + triangleHeight / 2))
            trianglePath.addLine(to: CGPoint(x: dx, y: dy + triangleHeight))
            trianglePath.closeSubpath()
            
            canvas.setFillColor(rt.labelBorderColor.cgColor)
            canvas.addPath(trianglePath)
            canvas.fillPath()
        }
    }
}
