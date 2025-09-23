import UIKit

// MARK: - K线图主视图
public class TKLineChartView: UIView, UIGestureRecognizerDelegate {
    
    // MARK: - 属性
    public var datas: [CompleteKLineEntity]? {
        didSet {
            if datas != oldValue {
                // 只重绘，不自动滚动（滚动逻辑由updateData方法处理）
                setNeedsDisplay()
            }
        }
    }
    
    public var mainState: MainState = .none {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public var isLine: Bool = false {
        didSet {
            if isLine != oldValue {
                setNeedsDisplay()
            }
        }
    }
    
    public var chartColors: ChartColors = ChartColors() {
        didSet {
            if chartColors !== oldValue {
                setNeedsDisplay()
            }
        }
    }
    
    
    public var chartConfiguration: ChartConfiguration = ChartConfiguration() {
        didSet {
            if chartConfiguration !== oldValue {
                setNeedsDisplay()
            }
        }
    }
    
    public var secondaryStates: [SecondaryState] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public var fractionDigits: Int = 2 {
        didSet {
            if fractionDigits != oldValue {
                chartConfiguration.numberFractionDigits = fractionDigits
                setNeedsDisplay()
            }
        }
    }
    
    // MARK: - 私有属性
    private var scaleX: Double = 1.0
    private var scrollX: Double = 0.0
    private var selectX: Double = 0.0
    private var selectY: Double = 0.0
    private var isScale: Bool = false
    private var isDrag: Bool = false
    private var isLongPress: Bool = false
    private var lastScale: Double = 1.0
    private var userHasInteracted: Bool = false // 标记用户是否曾经交互过
    
    // 惯性滚动相关属性
    nonisolated(unsafe) private var decelerationTimer: Timer?
    private var decelerationVelocity: Double = 0.0
    private var decelerationDamping: Double = 0.95 // 阻尼系数
    
    // MARK: - 手势识别器
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var pinchGestureRecognizer: UIPinchGestureRecognizer!
    private var longPressGestureRecognizer: UILongPressGestureRecognizer!
    private var tapGestureRecognizer: UITapGestureRecognizer!
    
    // MARK: - 初始化
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = chartColors.bgColor
        setupGestureRecognizers()
    }
    
    
    private func setupGestureRecognizers() {
        // 拖拽手势
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGestureRecognizer.maximumNumberOfTouches = 1
        panGestureRecognizer.delegate = self
        addGestureRecognizer(panGestureRecognizer)
        
        // 缩放手势
        pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinchGestureRecognizer)
        
        // 长按手势
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGestureRecognizer.minimumPressDuration = 0.5
        addGestureRecognizer(longPressGestureRecognizer)
        
        // 点击手势（单击显示/隐藏所选点信息）
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGestureRecognizer)

        // 设置手势优先级
        panGestureRecognizer.require(toFail: longPressGestureRecognizer)
        // 点击与拖拽不冲突，允许同时识别。若希望点击优先，可在需要时调整delegate。
    }
    
    // MARK: - 绘制
    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        backgroundColor = chartColors.bgColor
        
        let painter = ChartPainter(
            datas: datas,
            scaleX: scaleX,
            scrollX: scrollX,
            isLongPress: isLongPress,
            selectX: selectX,
            selectY: selectY,
            chartColors: chartColors,
            secondaryStates: secondaryStates,
            mainState: mainState,
            isLine: isLine,
            chartConfiguration: chartConfiguration
        )
        
        painter.initRect(rect.size)
        painter.calculateValue()
        painter.initChartRenderer()
        
        painter.drawBg(context, rect.size)
        painter.drawGrid(context)
        
        if let datas = datas, !datas.isEmpty {
            painter.drawChart(context, rect.size)
            painter.drawRightText(context)
            painter.drawRealTimePrice(context, rect.size)
            painter.drawDate(context, rect.size)
            
            if isLongPress {
                painter.drawCrossLineText(context, rect.size)
            }
            
            painter.drawText(context, datas.last!, 5)
            painter.drawMaxAndMin(context)
        }
    }
    
    deinit {
        decelerationTimer?.invalidate()
        decelerationTimer = nil
    }
    
    // MARK: - 阻尼衰减惯性滚动
    private func startDeceleration(with velocity: CGFloat) {
        // 停止之前的惯性滚动
        stopDeceleration()
        
        // 只有当速度足够大时才启动惯性滚动
        if abs(velocity) > 50 {
            decelerationVelocity = Double(velocity) / scaleX / 20 // 调整初始速度
            decelerationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateDeceleration()
                }
            }
        }
    }
    
    private func stopDeceleration() {
        decelerationTimer?.invalidate()
        decelerationTimer = nil
        decelerationVelocity = 0.0
    }
    
    private func updateDeceleration() {
        // 应用阻尼衰减
        decelerationVelocity *= decelerationDamping
        
        // 当速度很小时停止惯性滚动
        if abs(decelerationVelocity) < 0.5 {
            stopDeceleration()
            return
        }
        
        // 更新滚动位置
        let newScrollX = scrollX + decelerationVelocity
        scrollX = max(0, min(ChartPainter.maxScrollX, newScrollX))
        setNeedsDisplay()
    }
    
    // MARK: - 手势处理
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        let velocity = gesture.velocity(in: self)
        
        switch gesture.state {
        case .began:
            isDrag = true
            // 开始拖拽时清除选中点
            isLongPress = false
            userHasInteracted = true // 标记用户已经开始交互
            // 停止惯性滚动
            stopDeceleration()
            
        case .changed:
            if !isLongPress {
                let deltaX = translation.x
                scrollX = max(0, min(ChartPainter.maxScrollX, scrollX + deltaX / scaleX))
                gesture.setTranslation(.zero, in: self)
                setNeedsDisplay()
            }
            
        case .ended, .cancelled:
            isDrag = false
            // 启动阻尼衰减惯性滚动
            startDeceleration(with: velocity.x)
            
        default:
            break
        }
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            isScale = true
            lastScale = scaleX
            
        case .changed:
            if gesture.scale > 0 {
                scaleX = max(0.5, min(2.2, lastScale * gesture.scale))
                setNeedsDisplay()
            }
            
        case .ended, .cancelled:
            isScale = false
            lastScale = scaleX
            
        default:
            break
        }
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: self)
        
        switch gesture.state {
        case .began:
            isLongPress = true
            selectX = Double(location.x)
            selectY = Double(location.y)
            setNeedsDisplay()
            
        case .changed:
            selectX = Double(location.x)
            selectY = Double(location.y)
            setNeedsDisplay()
            
        case .ended, .cancelled:
            isLongPress = false
            setNeedsDisplay()
            
        default:
            break
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        // 仅当命中实时价格标签矩形才回到最右
        let labelRect = ChartPainter.lastRealTimeLabelRect
        if !labelRect.isEmpty && labelRect.contains(location) {
            stopDeceleration()
            isLongPress = false
            // 回到设备右边：对于当前坐标系，最右端应为 scrollX = 0
            // 不需要计算 minTranslateX，保持现有缩放即可
            scrollX = 0
            // 将选中位置移动到设备右侧，避免视觉上仍停留在左侧
            selectX = Double(bounds.width) - 1.0
            userHasInteracted = false
            setNeedsDisplay()
            return
        }
        // 单击时总是显示并更新选中点到点击位置
        // 如果正在惯性滚动，需立即停止
        stopDeceleration()
        isLongPress = true
        userHasInteracted = true
        selectX = Double(location.x)
        selectY = Double(location.y)
        setNeedsDisplay()
    }
    
    // MARK: - 辅助方法
    private func resetScrollAndScale() {
        scrollX = 0.0
        selectX = 0.0
        scaleX = 1.0
        lastScale = 1.0
    }
    
    private func getMinScrollX() -> Double {
        return scaleX
    }
    
    // MARK: - 公共方法
    /// 智能更新数据：根据用户交互状态决定是否自动滚动到最新位置
    public func updateData(_ newData: [CompleteKLineEntity]) {
        let wasUserScrolling = isUserScrolling()
        
        // 保存当前的滚动位置
        let currentScrollX = scrollX
        let currentSelectX = selectX
        let currentScaleX = scaleX
        let currentLastScale = lastScale
        
        // 设置数据
        datas = newData
        
        // 根据用户交互状态决定是否自动滚动到最新位置
        if !wasUserScrolling {
            // 用户没有交互，正常滚动到最新位置
            resetScrollAndScale()
            userHasInteracted = false // 重置交互状态
        } else {
            // 用户有交互，恢复之前的滚动位置
            scrollX = currentScrollX
            selectX = currentSelectX
            scaleX = currentScaleX
            lastScale = currentLastScale
            
            // 数据更新后，重新检查用户是否在查看最新位置
            // 注意：这里需要在数据更新后调用，因为maxScrollX可能已经改变
            if isViewingLatestData() {
                userHasInteracted = false
            }
        }
        
        // 重绘图表
        setNeedsDisplay()
    }
    
    // MARK: - 私有方法
    /// 检查用户是否正在拖拽图表
    private func isUserDragging() -> Bool {
        return isDrag
    }
    
    /// 检查用户是否正在惯性滚动
    private func isUserScrolling() -> Bool {
        return isDrag || decelerationTimer != nil || userHasInteracted
    }
    
    /// 检查用户是否在查看最新数据区域（最后几个K线）
    private func isViewingLatestData() -> Bool {
        // 如果scrollX接近最大值，说明用户在查看最新数据
        let maxScrollX = ChartPainter.maxScrollX
        let threshold = maxScrollX * 0.1 // 允许10%的误差范围
        return scrollX >= (maxScrollX - threshold)
    }
    
    /// 重置用户交互状态（当用户滚动回到最新位置时调用）
    public func resetUserInteractionState() {
        userHasInteracted = false
    }
    
}

// MARK: - 手势代理：与 UITableView 垂直滚动解冲突
extension TKLineChartView {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // 仅限制拖拽手势：横向才由图表处理；纵向交给父级（如 UITableView）
        if let pan = panGestureRecognizer, gestureRecognizer === pan {
            let v = pan.velocity(in: self)
            return abs(v.x) > abs(v.y)
        }
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // 拖拽手势不与其他手势并发，避免横向拖拽时表格也滚动
        if let pan = panGestureRecognizer, (gestureRecognizer === pan || otherGestureRecognizer === pan) {
            return false
        }
        // 其余手势可与父级滚动并存（例如点击/长按不阻塞表格滚动）
        return true
    }
}

// MARK: - 深度图视图
public class TKDepthChartView: UIView {
    
    // MARK: - 属性
    public var bids: [DepthEntity] = [] {
        didSet {
            if bids != oldValue {
                setNeedsDisplay()
            }
        }
    }
    
    public var asks: [DepthEntity] = [] {
        didSet {
            if asks != oldValue {
                setNeedsDisplay()
            }
        }
    }
    
    public var decimal: Int = 2 {
        didSet {
            if decimal != oldValue {
                setNeedsDisplay()
            }
        }
    }
    
    public var chartColors: ChartColors = ChartColors() {
        didSet {
            if chartColors !== oldValue {
                setNeedsDisplay()
            }
        }
    }
    
    // MARK: - 私有属性
    private var pressOffset: CGPoint?
    private var isLongPress: Bool = false
    
    // MARK: - 手势识别器
    private var longPressGestureRecognizer: UILongPressGestureRecognizer!
    private var tapGestureRecognizer: UITapGestureRecognizer!
    
    // MARK: - 初始化
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = chartColors.bgColor
        setupGestureRecognizers()
    }
    
    private func setupGestureRecognizers() {
        // 长按手势
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGestureRecognizer.minimumPressDuration = 0.3
        addGestureRecognizer(longPressGestureRecognizer)
        
        // 点击手势
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    // MARK: - 绘制
    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        backgroundColor = chartColors.bgColor
        
        if !bids.isEmpty && !asks.isEmpty {
            drawDepthChart(context, rect: rect)
        }
    }
    
    private func drawDepthChart(_ context: CGContext, rect: CGRect) {
        let paddingBottom: Double = 18.0
        let drawHeight = Double(rect.height) - paddingBottom
        let drawWidth = Double(rect.width) / 2
        
        // 计算最大成交量
        let maxVolume = max(bids.first?.amount ?? 0, asks.last?.amount ?? 0) * 1.05
        let multiple = maxVolume / 4 // 4条线
        
        // 绘制买入区域
        drawBuyArea(context, rect: rect, drawWidth: drawWidth, drawHeight: drawHeight, maxVolume: maxVolume)
        
        // 绘制卖出区域
        drawSellArea(context, rect: rect, drawWidth: drawWidth, drawHeight: drawHeight, maxVolume: maxVolume)
        
        // 绘制文字
        drawText(context, rect: rect, drawWidth: drawWidth, drawHeight: drawHeight, maxVolume: maxVolume, multiple: multiple)
        
        // 绘制选中信息
        if isLongPress, let pressOffset = pressOffset {
            drawSelectView(context, rect: rect, drawWidth: drawWidth, drawHeight: drawHeight, pressOffset: pressOffset)
        }
    }
    
    private func drawBuyArea(_ context: CGContext, rect: CGRect, drawWidth: Double, drawHeight: Double, maxVolume: Double) {
        guard !bids.isEmpty else { return }
        
        let pointWidth = drawWidth / Double(max(bids.count - 1, 1))
        let path = CGMutablePath()
        
        // 创建买入路径
        for (index, bid) in bids.enumerated() {
            let x = Double(index) * pointWidth
            let y = drawHeight - (drawHeight * bid.amount / maxVolume)
            
            if index == 0 {
                path.move(to: CGPoint(x: 0, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        // 闭合路径形成填充区域
        if !bids.isEmpty {
            let lastX = Double(bids.count - 1) * pointWidth
            let lastY = drawHeight - (drawHeight * bids.last!.amount / maxVolume)
            path.addLine(to: CGPoint(x: lastX, y: drawHeight))
            path.addLine(to: CGPoint(x: 0, y: drawHeight))
            path.closeSubpath()
        }
        
        // 绘制填充
        let colors = chartColors.depthBuyColors.map { $0.cgColor }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0])!
        
        context.saveGState()
        context.addPath(path)
        context.clip()
        context.drawLinearGradient(gradient,
                                 start: CGPoint(x: 0, y: 0),
                                 end: CGPoint(x: 0, y: drawHeight),
                                 options: [])
        context.restoreGState()
        
        // 绘制线条
        context.setStrokeColor(chartColors.depthBuyColor.cgColor)
        context.setLineWidth(1.0)
        context.addPath(path)
        context.strokePath()
    }
    
    private func drawSellArea(_ context: CGContext, rect: CGRect, drawWidth: Double, drawHeight: Double, maxVolume: Double) {
        guard !asks.isEmpty else { return }
        
        let pointWidth = drawWidth / Double(max(asks.count - 1, 1))
        let path = CGMutablePath()
        
        // 创建卖出路径
        for (index, ask) in asks.enumerated() {
            let x = drawWidth + Double(index) * pointWidth
            let y = drawHeight - (drawHeight * ask.amount / maxVolume)
            
            if index == 0 {
                path.move(to: CGPoint(x: drawWidth, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        // 闭合路径形成填充区域
        if !asks.isEmpty {
            let lastX = drawWidth + Double(asks.count - 1) * pointWidth
            let lastY = drawHeight - (drawHeight * asks.last!.amount / maxVolume)
            path.addLine(to: CGPoint(x: lastX, y: drawHeight))
            path.addLine(to: CGPoint(x: drawWidth, y: drawHeight))
            path.closeSubpath()
        }
        
        // 绘制填充
        let colors = chartColors.depthSellColors.map { $0.cgColor }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0])!
        
        context.saveGState()
        context.addPath(path)
        context.clip()
        context.drawLinearGradient(gradient,
                                 start: CGPoint(x: drawWidth, y: 0),
                                 end: CGPoint(x: drawWidth, y: drawHeight),
                                 options: [])
        context.restoreGState()
        
        // 绘制线条
        context.setStrokeColor(chartColors.depthSellColor.cgColor)
        context.setLineWidth(1.0)
        context.addPath(path)
        context.strokePath()
    }
    
    private func drawText(_ context: CGContext, rect: CGRect, drawWidth: Double, drawHeight: Double, maxVolume: Double, multiple: Double) {
        let lineCount = 4
        
        // 绘制右侧刻度
        for j in 0..<lineCount {
            let value = maxVolume - multiple * Double(j)
            let text = String(format: "%.\(decimal)f", value)
            let textSize = text.size(withAttributes: [.font: UIFont.systemFont(ofSize: 10)])
            let y = drawHeight / Double(lineCount) * Double(j) + textSize.height / 2
            text.draw(at: CGPoint(x: Double(rect.width) - textSize.width, y: y),
                     withAttributes: [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: chartColors.depthTextColor])
        }
        
        // 绘制底部价格
        if !bids.isEmpty {
            let startText = String(format: "%.\(decimal)f", bids.first!.price)
            let startSize = startText.size(withAttributes: [.font: UIFont.systemFont(ofSize: 10)])
            let startY = Double(rect.height) - 18 + (18 - startSize.height) / 2
            startText.draw(at: CGPoint(x: 0, y: startY),
                          withAttributes: [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: chartColors.depthTextColor])
        }
        
        if !asks.isEmpty {
            let endText = String(format: "%.\(decimal)f", asks.last!.price)
            let endSize = endText.size(withAttributes: [.font: UIFont.systemFont(ofSize: 10)])
            let endY = Double(rect.height) - 18 + (18 - endSize.height) / 2
            endText.draw(at: CGPoint(x: Double(rect.width) - endSize.width, y: endY),
                        withAttributes: [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: chartColors.depthTextColor])
        }
        
        // 绘制中间价格
        if !bids.isEmpty && !asks.isEmpty {
            let center = (bids.last!.price + asks.first!.price) / 2
            let centerText = String(format: "%.\(decimal)f", center)
            let centerSize = centerText.size(withAttributes: [.font: UIFont.systemFont(ofSize: 10)])
            let centerY = Double(rect.height) - 18 + (18 - centerSize.height) / 2
            centerText.draw(at: CGPoint(x: drawWidth - centerSize.width / 2, y: centerY),
                           withAttributes: [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: chartColors.depthTextColor])
        }
    }
    
    private func drawSelectView(_ context: CGContext, rect: CGRect, drawWidth: Double, drawHeight: Double, pressOffset: CGPoint) {
        let maxVolume = max(bids.first?.amount ?? 0, asks.last?.amount ?? 0) * 1.05
        
        if pressOffset.x <= drawWidth {
            // 买入区域
            let index = indexOfTranslateX(pressOffset.x, 0, bids.count, getBuyX)
            if index < bids.count {
                drawSelectInfo(context, rect: rect, drawWidth: drawWidth, drawHeight: drawHeight,
                              entity: bids[index], isLeft: true, maxVolume: maxVolume)
            }
        } else {
            // 卖出区域
            let index = indexOfTranslateX(pressOffset.x - drawWidth, 0, asks.count, getSellX)
            if index < asks.count {
                drawSelectInfo(context, rect: rect, drawWidth: drawWidth, drawHeight: drawHeight,
                              entity: asks[index], isLeft: false, maxVolume: maxVolume)
            }
        }
    }
    
    private func drawSelectInfo(_ context: CGContext, rect: CGRect, drawWidth: Double, drawHeight: Double,
                               entity: DepthEntity, isLeft: Bool, maxVolume: Double) {
        let pointWidth = drawWidth / Double(max((isLeft ? bids : asks).count - 1, 1))
        let dx = isLeft ? Double(entity.price) * pointWidth : drawWidth + Double(entity.price) * pointWidth
        let y = drawHeight - (drawHeight * entity.amount / maxVolume)
        
        // 绘制选中点
        let radius: Double = 8.0
        let color = isLeft ? chartColors.depthBuyColor : chartColors.depthSellColor
        
        context.setFillColor(color.cgColor)
        context.fillEllipse(in: CGRect(x: dx - radius/3, y: y - radius/3, width: radius*2/3, height: radius*2/3))
        
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(1.0)
        context.strokeEllipse(in: CGRect(x: dx - radius, y: y - radius, width: radius*2, height: radius*2))
        
        // 绘制价格标签
        let priceText = String(format: "%.\(decimal)f", entity.price)
        let priceSize = priceText.size(withAttributes: [.font: UIFont.systemFont(ofSize: 10)])
        let left = max(0, min(Double(rect.width) - priceSize.width, dx - priceSize.width / 2))
        let bottomRect = CGRect(x: left - 3, y: drawHeight + 3,
                               width: priceSize.width + 6, height: 18)
        
        context.setFillColor(chartColors.markerBgColor.cgColor)
        context.setStrokeColor(chartColors.markerBorderColor.cgColor)
        context.setLineWidth(0.5)
        context.fill(bottomRect)
        context.stroke(bottomRect)
        
        priceText.draw(at: CGPoint(x: left, y: drawHeight + 3 + (18 - priceSize.height) / 2),
                      withAttributes: [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: chartColors.depthTextColor])
        
        // 绘制数量标签
        let amountText = String(format: "%.\(decimal)f", entity.amount)
        let amountSize = amountText.size(withAttributes: [.font: UIFont.systemFont(ofSize: 10)])
        let rightRectTop = max(0, min(drawHeight - amountSize.height, y - amountSize.height / 2))
        let rightRect = CGRect(x: rect.width - amountSize.width - 6, y: rightRectTop - 3,
                              width: amountSize.width + 6, height: amountSize.height + 6)
        
        context.fill(rightRect)
        context.stroke(rightRect)
        
        amountText.draw(at: CGPoint(x: rect.width - amountSize.width - 3, y: rightRectTop),
                       withAttributes: [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: chartColors.depthTextColor])
    }
    
    // MARK: - 辅助方法
    private func indexOfTranslateX(_ translateX: Double, _ start: Int, _ end: Int, _ getX: (Int) -> Double) -> Int {
        if end == start || end == -1 {
            return start
        }
        if end - start == 1 {
            let startValue = getX(start)
            let endValue = getX(end)
            return abs(translateX - startValue) < abs(translateX - endValue) ? start : end
        }
        let mid = start + (end - start) / 2
        let midValue = getX(mid)
        if translateX < midValue {
            return indexOfTranslateX(translateX, start, mid, getX)
        } else if translateX > midValue {
            return indexOfTranslateX(translateX, mid, end, getX)
        } else {
            return mid
        }
    }
    
    private func getBuyX(_ position: Int) -> Double {
        let pointWidth = (Double(bounds.width) / 2) / Double(max(bids.count - 1, 1))
        return Double(position) * pointWidth
    }
    
    private func getSellX(_ position: Int) -> Double {
        let pointWidth = (Double(bounds.width) / 2) / Double(max(asks.count - 1, 1))
        return Double(bounds.width) / 2 + Double(position) * pointWidth
    }
    
    // MARK: - 手势处理
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: self)
        
        switch gesture.state {
        case .began:
            pressOffset = location
            isLongPress = true
            setNeedsDisplay()
            
        case .changed:
            pressOffset = location
            setNeedsDisplay()
            
        case .ended, .cancelled:
            isLongPress = false
            setNeedsDisplay()
            
        default:
            break
        }
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        if isLongPress {
            isLongPress = false
            setNeedsDisplay()
        }
    }

}
