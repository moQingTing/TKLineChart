import UIKit

// MARK: - 基础图表绘制器
open class BaseChartPainter {
    nonisolated(unsafe) public static var maxScrollX: Double = 0.0
    
    public var datas: [CompleteKLineEntity]?
    public var mainState: MainState = .none
    public var scaleX: Double = 1.0
    public var scrollX: Double = 0.0
    public var selectX: Double = 0.0
    public var isLongPress: Bool = false
    public var isLine: Bool = false
    
    // 区域大小与位置
    public var mainRect: CGRect = .zero
    public var volRect: CGRect = .zero
    public var secondaryRect: CGRect = .zero
    public var mainDisplayMinHeight: Double = 150
    public var displayHeight: Double = 0
    public var width: Double = 0
    
    // 索引和值
    public var startIndex: Int = 0
    public var stopIndex: Int = 0
    public var mainMaxValue: Double = -Double.greatestFiniteMagnitude
    public var mainMinValue: Double = Double.greatestFiniteMagnitude
    public var volMaxValue: Double = -Double.greatestFiniteMagnitude
    public var volMinValue: Double = Double.greatestFiniteMagnitude
    public var translateX: Double = -Double.greatestFiniteMagnitude
    public var mainMaxIndex: Int = 0
    public var mainMinIndex: Int = 0
    public var mainHighMaxValue: Double = -Double.greatestFiniteMagnitude
    public var mainLowMinValue: Double = Double.greatestFiniteMagnitude
    public var itemCount: Int = 0
    public var dataLen: Double = 0.0
    public var pointWidth: Double = 0.0
    public var marginRight: Double = 0.0
    
    // 价格格式化回调
    public var priceFormatter: ((Double) -> NSAttributedString)?
    // 成交量/数量格式化回调
    public var volumeFormatter: ((Double) -> NSAttributedString)?
    
    // 时间格式化
    public var formats: [String] = [
        DateFormatUtil.yyyy, "-", DateFormatUtil.mm, "-", DateFormatUtil.dd,
        " ", DateFormatUtil.HH, ":", DateFormatUtil.nn
    ]
    
    public init(datas: [CompleteKLineEntity]?, scaleX: Double, scrollX: Double, isLongPress: Bool, 
                selectX: Double, mainState: MainState = .none, isLine: Bool = false) {
        self.datas = datas
        self.scaleX = scaleX
        self.scrollX = scrollX
        self.isLongPress = isLongPress
        self.selectX = selectX
        self.mainState = mainState
        self.isLine = isLine
        
        self.itemCount = datas?.count ?? 0
        self.pointWidth = 8.0  // 默认值
        self.dataLen = Double(itemCount) * pointWidth
        initFormats()
    }
    
    private func initFormats() {
        guard let datas = datas, datas.count >= 2 else { return }
        
        let firstTime = datas[0].timestamp
        let secondTime = datas[1].timestamp
        let time = secondTime - firstTime
        
        // 根据时间间隔确定格式
        if time >= 24 * 60 * 60 * 28 { // 月线
            formats = [DateFormatUtil.yy, "-", DateFormatUtil.mm]
        } else if time >= 24 * 60 * 60 { // 日线
            formats = [DateFormatUtil.yy, "-", DateFormatUtil.mm, "-", DateFormatUtil.dd]
        } else { // 小时线
            formats = [DateFormatUtil.mm, "-", DateFormatUtil.dd, " ", DateFormatUtil.HH, ":", DateFormatUtil.nn]
        }
    }
    
    open func initRect(_ size: CGSize) {
        // 子类实现
    }
    
    open func calculateValue() {
        // 子类实现
    }
    
    open func initChartRenderer() {
        // 子类实现
    }
    
    open func drawBg(_ canvas: CGContext, _ size: CGSize) {
        // 子类实现
    }
    
    open func drawGrid(_ canvas: CGContext) {
        // 子类实现
    }
    
    open func drawChart(_ canvas: CGContext, _ size: CGSize) {
        // 子类实现
    }
    
    open func drawRightText(_ canvas: CGContext) {
        // 子类实现
    }
    
    open func drawDate(_ canvas: CGContext, _ size: CGSize) {
        // 子类实现
    }
    
    open func drawText(_ canvas: CGContext, _ data: CompleteKLineEntity, _ x: Double) {
        // 子类实现
    }
    
    open func drawMaxAndMin(_ canvas: CGContext) {
        // 子类实现
    }
    
    open func drawCrossLineText(_ canvas: CGContext, _ size: CGSize) {
        // 子类实现
    }
    
    open func drawRealTimePrice(_ canvas: CGContext, _ size: CGSize) {
        // 子类实现
    }
    
    // MARK: - 辅助方法
    public func getMainMaxMinValue(_ item: CompleteKLineEntity, _ i: Int) {
        if isLine {
            mainMaxValue = max(mainMaxValue, item.close)
            mainMinValue = min(mainMinValue, item.close)
        } else {
            var maxPrice = item.high
            var minPrice = item.low
            
            switch mainState {
            case let .ma(p1, p2, p3):
                for p in [p1, p2, p3] {
                    if p > 0, let v = item.maPrices[p], v != 0 {
                        maxPrice = max(maxPrice, v)
                        minPrice = min(minPrice, v)
                    }
                }
            case .ema:
                // 目前 DataUtil 生成的是 MA、BOLL；EMA 如需参与范围，按已有字段扩展后加入
                break
            case .boll:
                if item.up != 0 {
                    maxPrice = max(item.up, item.high)
                }
                if item.dn != 0 {
                    minPrice = min(item.dn, item.low)
                }
            case .none:
                break
            }
            
            mainMaxValue = max(mainMaxValue, maxPrice)
            mainMinValue = min(mainMinValue, minPrice)
            
            if mainHighMaxValue < item.high {
                mainHighMaxValue = item.high
                mainMaxIndex = i
            }
            if mainLowMinValue > item.low {
                mainLowMinValue = item.low
                mainMinIndex = i
            }
        }
    }
    
    public func getVolMaxMinValue(_ item: CompleteKLineEntity, _ p1: Int, _ p2: Int) {
        var vMax = item.volume
        var vMin = item.volume
        if p1 > 0, let v1 = item.volumeMAs[p1], v1 != 0 { vMax = max(vMax, v1); vMin = min(vMin, v1) }
        if p2 > 0, let v2 = item.volumeMAs[p2], v2 != 0 { vMax = max(vMax, v2); vMin = min(vMin, v2) }
        volMaxValue = max(volMaxValue, vMax)
        volMinValue = min(volMinValue, vMin)
    }
    
    public func getSecondaryMaxMinValue(_ item: CompleteKLineEntity, _ secondaryState: SecondaryState, _ maxMinEntity: inout KMaxMinEntity) {
        switch secondaryState {
        case .macd:
            maxMinEntity.max = max(maxMinEntity.max, max(item.macd, max(item.dif, item.dea)))
            maxMinEntity.min = min(maxMinEntity.min, min(item.macd, min(item.dif, item.dea)))
        case .kdj:
            maxMinEntity.max = max(maxMinEntity.max, max(item.k, max(item.d, item.j)))
            maxMinEntity.min = min(maxMinEntity.min, min(item.k, min(item.d, item.j)))
        case .rsi:
            maxMinEntity.max = max(maxMinEntity.max, item.rsi)
            maxMinEntity.min = min(maxMinEntity.min, item.rsi)
        case .wr:
            maxMinEntity.max = max(maxMinEntity.max, item.r)
            maxMinEntity.min = min(maxMinEntity.min, item.r)
        case let .vol(p1, p2):
            var vMax = item.volume
            var vMin = item.volume
            if p1 > 0, let v1 = item.volumeMAs[p1] { vMax = max(vMax, v1); vMin = min(vMin, v1) }
            if p2 > 0, let v2 = item.volumeMAs[p2] { vMax = max(vMax, v2); vMin = min(vMin, v2) }
            maxMinEntity.max = max(maxMinEntity.max, vMax)
            maxMinEntity.min = min(maxMinEntity.min, vMin)
        }
    }
    
    public func xToTranslateX(_ x: Double) -> Double {
        return -translateX + x / scaleX
    }
    
    public func indexOfTranslateX(_ translateX: Double) -> Int {
        return _indexOfTranslateX(translateX, 0, itemCount - 1)
    }
    
    private func _indexOfTranslateX(_ translateX: Double, _ start: Int, _ end: Int) -> Int {
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
            return _indexOfTranslateX(translateX, start, mid)
        } else if translateX > midValue {
            return _indexOfTranslateX(translateX, mid, end)
        } else {
            return mid
        }
    }
    
    public func getX(_ position: Int) -> Double {
        return Double(position) * pointWidth + pointWidth / 2
    }
    
    public func getItem(_ position: Int) -> CompleteKLineEntity? {
        guard let datas = datas, position >= 0 && position < datas.count else { return nil }
        return datas[position]
    }
    
    public func setTranslateXFromScrollX(_ scrollX: Double) {
        translateX = scrollX + getMinTranslateX()
    }
    
    public func getMinTranslateX() -> Double {
        guard let datas = datas, !datas.isEmpty else { return 0 }
        
        let w = width
        var x = -dataLen + w / scaleX - pointWidth / 2
        x = x >= 0 ? 0.0 : x
        
        // 数据不足一屏
        if x >= 0 {
            if w / scaleX - getX(datas.count) < marginRight {
                x -= marginRight - w / scaleX + getX(datas.count)
            } else {
                marginRight = w / scaleX - getX(datas.count)
            }
        } else if x < 0 {
            // 数据超过一屏
            x -= marginRight
        }
        
        return x >= 0 ? 0.0 : x
    }
    
    public func calculateSelectedX(_ selectX: Double) -> Int {
        var selectedIndex = indexOfTranslateX(xToTranslateX(selectX))
        if selectedIndex < startIndex {
            selectedIndex = startIndex
        }
        if selectedIndex > stopIndex {
            selectedIndex = stopIndex
        }
        return selectedIndex
    }
    
    public func translateXtoX(_ translateX: Double) -> Double {
        // 将内容坐标 translateX 映射为屏幕坐标 X
        // drawChart 中应用了：先平移 translateX*scaleX，再按 scaleX 缩放
        // 因此屏幕 X = (内容 X + 当前 translateX) * scaleX
        return (translateX + self.translateX) * scaleX
    }
    
    public func getTextStyle(_ color: UIColor) -> [NSAttributedString.Key: Any] {
        return [
            .font: UIFont.systemFont(ofSize: 9.0),  // 默认字体大小
            .foregroundColor: color
        ]
    }
    
    public func format(_ n: Double) -> NSAttributedString {
        if let formatter = priceFormatter {
            return formatter(n)
        }
        // 默认格式化：保留2位小数
        let text = NumberUtil.format(n, 2)
        return NSAttributedString(string: text, attributes: getTextStyle(UIColor.black))
    }
    
    public func formatVolume(_ n: Double) -> NSAttributedString {
        if let formatter = volumeFormatter {
            return formatter(n)
        }
        // 默认格式化：保留2位小数，带缩写（k/M/B/T）
        let text = NumberUtil.abbreviate(n, 2)
        return NSAttributedString(string: text, attributes: getTextStyle(UIColor.black))
    }
}
