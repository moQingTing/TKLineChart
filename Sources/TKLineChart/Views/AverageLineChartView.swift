import UIKit

public class AverageLineChartView: UIView {
    public var style: AverageLineChartStyle = AverageLineChartStyle() { didSet { setNeedsDisplay() } }
    public var values: [Double] = [] { didSet { setNeedsDisplay() } }
    public var selectedIndex: Int? { didSet { setNeedsDisplay() } }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = true
        backgroundColor = style.backgroundColor
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
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
        let range = max(maxV - minV, 1e-6)
        let stepX = availableWidth / CGFloat(max(values.count - 1, 1))

        var xs: [CGFloat] = []
        var ys: [CGFloat] = []
        for (i, v) in values.enumerated() {
            let x = style.padding.left + CGFloat(i) * stepX
            let y = style.padding.top + CGFloat(1 - (v - minV) / range) * availableHeight
            xs.append(x); ys.append(y)
        }
        return (xs, ys)
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
        var bubbleOrigin = CGPoint.zero
        if above {
            bubbleOrigin = CGPoint(
                x: center.x - size.width/2 - paddingH,
                y: max(style.padding.top,
                       center.y - verticalGap - size.height - paddingV*2)
            )
        } else {
            bubbleOrigin = CGPoint(
                x: center.x - size.width/2 - paddingH,
                y: min(bounds.height - style.padding.bottom - size.height - paddingV*2,
                       center.y + verticalGap)
            )
        }
        // 避免越右边界
        bubbleOrigin.x = max(style.padding.left,
                             min(bubbleOrigin.x, bounds.width - style.padding.right - size.width - paddingH*2))

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


