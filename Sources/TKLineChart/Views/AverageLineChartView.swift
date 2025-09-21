import UIKit

public class AverageLineChartView: UIView, UIGestureRecognizerDelegate {
    public var style: AverageLineChartStyle = AverageLineChartStyle() { didSet { setNeedsDisplay() } }
    public var values: [Double] = [] { 
        didSet { 
            // 重置滑动位置
            currentOffset = 0
            setNeedsDisplay() 
        } 
    }
    public var selectedIndex: Int? { didSet { setNeedsDisplay() } }
    
    // 滑动相关属性
    private var panGesture: UIPanGestureRecognizer!
    private var startOffset: CGFloat = 0
    private var currentOffset: CGFloat = 0
    private var maxOffset: CGFloat = 0

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        isOpaque = true
        backgroundColor = style.backgroundColor
        
        // 添加点击手势
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
        
        // 添加滑动手势
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        addGestureRecognizer(panGesture)
    }

    @objc private func handleTap(_ g: UITapGestureRecognizer) {
        guard !values.isEmpty else { return }
        let p = g.location(in: self)
        let (xs, _) = computePoints()
        var nearest = 0
        var minDist = CGFloat.greatestFiniteMagnitude
        for (i, x) in xs.enumerated() {
            let d = abs(x - p.x)
            if d < minDist { minDist = d; nearest = i }
        }
        selectedIndex = nearest
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard !values.isEmpty else { return }
        
        let translation = gesture.translation(in: self)
        
        switch gesture.state {
        case .began:
            startOffset = currentOffset
            
        case .changed:
            let newOffset = startOffset + translation.x
            // 限制滑动范围
            currentOffset = Swift.max(0, Swift.min(newOffset, maxOffset))
            setNeedsDisplay()
            
        case .ended, .cancelled:
            // 可以在这里添加惯性滑动逻辑
            break
            
        default:
            break
        }
    }
    
    // MARK: - 公共方法
    
    /// 重置滑动位置到最左边
    public func resetScrollPosition() {
        currentOffset = 0
        setNeedsDisplay()
    }
    
    /// 滑动到最右边
    public func scrollToEnd() {
        currentOffset = maxOffset
        setNeedsDisplay()
    }
    
    /// 设置滑动位置（0.0 到 1.0，0.0 表示最左边，1.0 表示最右边）
    public func setScrollPosition(_ position: CGFloat) {
        let clampedPosition = Swift.max(0, Swift.min(1, position))
        currentOffset = clampedPosition * maxOffset
        setNeedsDisplay()
    }
    
    /// 获取当前滑动位置（0.0 到 1.0）
    public func getScrollPosition() -> CGFloat {
        guard maxOffset > 0 else { return 0 }
        return currentOffset / maxOffset
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // 允许与父视图的滚动手势同时识别
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
    
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == self.panGesture else { return true }
        
        // 检查滑动方向，只有水平滑动才处理
        let translation = self.panGesture.translation(in: self)
        let horizontalMovement = abs(translation.x)
        let verticalMovement = abs(translation.y)
        
        // 如果水平移动大于垂直移动，则处理滑动手势
        // 否则让父视图处理垂直滚动
        return horizontalMovement > verticalMovement
    }

    public override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), values.count >= 2 else { return }
        backgroundColor = style.backgroundColor

        let (xs, ys) = computePoints()

        // 渐变填充
        let path = CGMutablePath()
        path.move(to: CGPoint(x: xs[0], y: ys[0]))
        for i in 1..<xs.count { path.addLine(to: CGPoint(x: xs[i], y: ys[i])) }
        path.addLine(to: CGPoint(x: xs.last!, y: bounds.height - style.padding.bottom))
        path.addLine(to: CGPoint(x: xs.first!, y: bounds.height - style.padding.bottom))
        path.closeSubpath()

        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        let colors = [style.lineColor.withAlphaComponent(style.gradientStartAlpha).cgColor,
                      style.lineColor.withAlphaComponent(style.gradientEndAlpha).cgColor] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0,1])!
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: 0, y: style.padding.top),
                               end: CGPoint(x: 0, y: bounds.height - style.padding.bottom),
                               options: [])
        ctx.restoreGState()

        // 折线（圆角）
        ctx.setStrokeColor(style.lineColor.cgColor)
        ctx.setLineWidth(style.lineWidth)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: xs[0], y: ys[0]))
        for i in 1..<xs.count { ctx.addLine(to: CGPoint(x: xs[i], y: ys[i])) }
        ctx.strokePath()

        // 选中点气泡（若有）
        if let idx = selectedIndex {
            drawBalloon(ctx: ctx, index: idx, xs: xs, ys: ys, above: true)
        }

        // 极值标注：当前显示区域的最大值（上方气泡）与最小值（下方气泡）
        if let maxIdx = maxIndex(), let minIdx = minIndex() {
            drawCircle(ctx: ctx, center: CGPoint(x: xs[maxIdx], y: ys[maxIdx]))
            drawBalloon(ctx: ctx, index: maxIdx, xs: xs, ys: ys, above: true)

            if minIdx != maxIdx {
                drawCircle(ctx: ctx, center: CGPoint(x: xs[minIdx], y: ys[minIdx]))
                drawBalloon(ctx: ctx, index: minIdx, xs: xs, ys: ys, above: false)
            }
        }
    }

    private func computePoints() -> ([CGFloat], [CGFloat]) {
        let availableWidth = bounds.width - style.padding.left - style.padding.right
        let availableHeight = bounds.height - style.padding.top - style.padding.bottom
        let minV = values.min() ?? 0
        let maxV = values.max() ?? 0
        
        // 智能计算纵坐标范围
        let (displayMinV, displayMaxV) = calculateDisplayRange(min: minV, max: maxV)
        let displayRange = displayMaxV - displayMinV
        
        // 计算滑动相关的参数
        let totalWidth = CGFloat(values.count) * (availableWidth / CGFloat(Swift.max(values.count - 1, 1)))
        maxOffset = Swift.max(0, totalWidth - availableWidth)
        
        let stepX = availableWidth / CGFloat(Swift.max(values.count - 1, 1))

        var xs: [CGFloat] = []
        var ys: [CGFloat] = []
        for (i, v) in values.enumerated() {
            // 应用滑动偏移
            let x = style.padding.left + CGFloat(i) * stepX - currentOffset
            // 根据实际数值范围计算y坐标（从顶部开始，向下绘制）
            let normalizedValue = (v - displayMinV) / displayRange
            let y = style.padding.top + CGFloat(1 - normalizedValue) * availableHeight
            xs.append(x); ys.append(y)
        }
        return (xs, ys)
    }
    
    /// 智能计算显示范围，确保折线不贴边显示
    private func calculateDisplayRange(min: Double, max: Double) -> (min: Double, max: Double) {
        let range = max - min
        
        // 如果数值范围很小，使用固定值
        if range < 1e-6 {
            let padding = Swift.max(1.0, Swift.max(abs(min), abs(max)) * 0.1)
            return (min - padding, max + padding)
        }
        
        // 根据数值范围大小动态调整填充比例
        let paddingRatio: Double
        if range < 1 {
            paddingRatio = 0.5  // 小数值范围，使用50%填充
        } else if range < 10 {
            paddingRatio = 0.4  // 中等数值范围，使用40%填充
        } else if range < 100 {
            paddingRatio = 0.3  // 较大数值范围，使用30%填充
        } else {
            paddingRatio = 0.25 // 大数值范围，使用25%填充
        }
        
        let padding = range * paddingRatio
        
        // 确保最小值不会贴到图表底部
        let displayMin = min - padding
        
        // 确保最大值不会贴到图表顶部
        let displayMax = max + padding
        
        return (displayMin, displayMax)
    }

    private func drawBalloon(ctx: CGContext, index: Int, xs: [CGFloat], ys: [CGFloat], above: Bool) {
        guard index >= 0 && index < values.count else { return }
        let center = CGPoint(x: xs[index], y: ys[index])

        // 点
        drawCircle(ctx: ctx, center: center)

        // 文本
        let text = style.priceFormatter(values[index])
        let attrs: [NSAttributedString.Key: Any] = [
            .font: style.balloonFont,
            .foregroundColor: style.balloonTextColor
        ]
        let size = (text as NSString).size(withAttributes: attrs)
        let paddingH: CGFloat = 10
        let paddingV: CGFloat = 6
        // 根据 above 参数决定气泡绘制在点的上方或下方
        let verticalGap: CGFloat = 8
        let bubbleWidth = size.width + paddingH * 2
        let bubbleHeight = size.height + paddingV * 2
        
        var bubbleOrigin = CGPoint.zero
        if above {
            // 最大值气泡：在点的正上方居中
            bubbleOrigin = CGPoint(
                x: center.x - bubbleWidth / 2,  // 水平居中
                y: max(style.padding.top,
                       center.y - verticalGap - bubbleHeight)  // 在点上方
            )
        } else {
            // 最小值气泡：在点的正下方居中
            bubbleOrigin = CGPoint(
                x: center.x - bubbleWidth / 2,  // 水平居中
                y: min(bounds.height - style.padding.bottom - bubbleHeight,
                       center.y + verticalGap)  // 在点下方
            )
        }
        
        // 边界检查：确保气泡不超出左右边界
        bubbleOrigin.x = max(style.padding.left,
                             min(bubbleOrigin.x, bounds.width - style.padding.right - bubbleWidth))

        let bubbleRect = CGRect(x: bubbleOrigin.x, y: bubbleOrigin.y,
                                width: size.width + paddingH*2, height: size.height + paddingV*2)
        let path = UIBezierPath(roundedRect: bubbleRect, cornerRadius: style.balloonCornerRadius)
        ctx.setFillColor(style.balloonBgColor.cgColor)
        ctx.addPath(path.cgPath)
        ctx.fillPath()
        (text as NSString).draw(in: CGRect(x: bubbleRect.minX + paddingH,
                                           y: bubbleRect.minY + paddingV,
                                           width: size.width,
                                           height: size.height), withAttributes: attrs)
    }

    private func maxIndex() -> Int? {
        guard let maxVal = values.max() else { return nil }
        return values.firstIndex(of: maxVal)
    }

    private func minIndex() -> Int? {
        guard let minVal = values.min() else { return nil }
        return values.firstIndex(of: minVal)
    }

    private func drawCircle(ctx: CGContext, center: CGPoint) {
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.setStrokeColor(style.lineColor.cgColor)
        ctx.setLineWidth(2)
        let r = style.pointRadius
        ctx.fillEllipse(in: CGRect(x: center.x - r/2, y: center.y - r/2, width: r, height: r))
        ctx.strokeEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: 2*r, height: 2*r))
    }
}


