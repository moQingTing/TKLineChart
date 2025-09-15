# TKLineChart

一个功能完整的 Swift K线图组件，基于 Flutter K线图实现，提供专业的金融图表功能。

## 功能特性

### 📊 图表类型
- **K线图（蜡烛图）** - 显示开盘、最高、最低、收盘价格
- **线图** - 平滑的价格曲线
- **深度图** - 买卖盘深度展示

### 📈 技术指标
- **移动平均线 (MA)** - MA5, MA10, MA20, MA30
- **布林带 (BOLL)** - 上轨、中轨、下轨
- **MACD** - 指数平滑移动平均线
- **KDJ** - 随机指标
- **RSI** - 相对强弱指标
- **WR** - 威廉指标
- **成交量** - 带MA5、MA10均线

### 🎨 交互功能
- **缩放** - 双指缩放查看细节
- **拖拽** - 水平滑动浏览历史数据
- **长按** - 显示详细数据信息
- **实时更新** - 支持实时数据更新

### 🎯 自定义样式
- **深色/浅色主题** - 自动适配系统主题
- **颜色配置** - 完全可自定义的颜色方案
- **样式配置** - 线宽、字体大小、网格等
- **多副图支持** - 可同时显示多个技术指标

## 安装

### Swift Package Manager

在 Xcode 中添加包依赖：

```
https://github.com/your-username/TKLineChart.git
```

## 快速开始

### 基础使用

```swift
import TKLineChart

class ViewController: UIViewController {
    @IBOutlet weak var kLineChartView: TKLineChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKLineChart()
        loadData()
    }
    
    private func setupKLineChart() {
        // 配置图表样式
        kLineChartView.chartStyle = ChartStyle()
        kLineChartView.chartColors = ChartColors(isDarkMode: false)
        kLineChartView.mainState = .ma
        kLineChartView.secondaryStates = [.vol, .macd]
        kLineChartView.fractionDigits = 2
    }
    
    private func loadData() {
        // 创建K线数据
        var kLineData: [CompleteKLineEntity] = []
        
        for i in 0..<100 {
            let entity = CompleteKLineEntity()
            entity.timestamp = Int(Date().timeIntervalSince1970) + i * 3600
            entity.open = 100 + Double.random(in: -5...5)
            entity.high = entity.open + Double.random(in: 0...3)
            entity.low = entity.open - Double.random(in: 0...3)
            entity.close = entity.low + Double.random(in: 0...(entity.high - entity.low))
            entity.volume = Double.random(in: 1000...10000)
            
            kLineData.append(entity)
        }
        
        // 计算技术指标
        DataUtil.calculate(kLineData)
        
        // 设置数据
        kLineChartView.datas = kLineData
    }
}
```

### 深度图使用

```swift
import TKLineChart

class ViewController: UIViewController {
    @IBOutlet weak var depthChartView: TKDepthChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDepthChart()
        loadDepthData()
    }
    
    private func setupDepthChart() {
        depthChartView.chartColors = ChartColors(isDarkMode: false)
        depthChartView.decimal = 2
    }
    
    private func loadDepthData() {
        var bids: [DepthEntity] = []
        var asks: [DepthEntity] = []
        
        let basePrice = 100.0
        for i in 0..<20 {
            let bidPrice = basePrice - Double(i) * 0.1
            let askPrice = basePrice + Double(i) * 0.1
            let bidAmount = Double.random(in: 100...1000)
            let askAmount = Double.random(in: 100...1000)
            
            bids.append(DepthEntity(price: bidPrice, amount: bidAmount))
            asks.append(DepthEntity(price: askPrice, amount: askAmount))
        }
        
        depthChartView.bids = bids
        depthChartView.asks = asks
    }
}
```

## 高级配置

### 自定义样式

```swift
// 创建自定义颜色配置
let customColors = ChartColors(isDarkMode: true)

// 创建自定义样式
let customStyle = ChartStyle()
customStyle.candleWidth = 8.0
customStyle.pointWidth = 10.0
customStyle.lineStrokeWidth = 2.0
customStyle.defaultTextSize = 10.0
customStyle.gridRows = 4
customStyle.gridColumns = 5

kLineChartView.chartColors = customColors
kLineChartView.chartStyle = customStyle
```

### 实时数据更新

```swift
// 更新最后一条数据
private func updateRealTimeData() {
    guard var datas = kLineChartView.datas, !datas.isEmpty else { return }
    
    let lastEntity = datas.last!
    lastEntity.close += Double.random(in: -0.5...0.5)
    lastEntity.high = max(lastEntity.high, lastEntity.close)
    lastEntity.low = min(lastEntity.low, lastEntity.close)
    lastEntity.volume += Double.random(in: 100...500)
    
    // 重新计算技术指标
    DataUtil.updateLastData(datas)
    
    // 刷新图表
    kLineChartView.setNeedsDisplay()
}

// 添加新数据
private func addNewData() {
    guard var datas = kLineChartView.datas else { return }
    
    let newEntity = CompleteKLineEntity()
    newEntity.timestamp = Int(Date().timeIntervalSince1970)
    newEntity.open = 100.0
    newEntity.high = 101.0
    newEntity.low = 99.0
    newEntity.close = 100.5
    newEntity.volume = 1000
    
    DataUtil.addLastData(&datas, newEntity)
    kLineChartView.datas = datas
}
```

## API 参考

### TKLineChartView

主要的K线图视图组件。

#### 属性

- `datas: [CompleteKLineEntity]?` - K线数据数组
- `mainState: MainState` - 主图状态（MA、BOLL、None）
- `secondaryStates: [SecondaryState]` - 副图状态数组
- `isLine: Bool` - 是否显示为线图
- `chartColors: ChartColors` - 颜色配置
- `chartStyle: ChartStyle` - 样式配置
- `fractionDigits: Int` - 小数位数

### TKDepthChartView

深度图视图组件。

#### 属性

- `bids: [DepthEntity]` - 买入深度数据
- `asks: [DepthEntity]` - 卖出深度数据
- `decimal: Int` - 价格小数位数
- `chartColors: ChartColors` - 颜色配置

### 数据模型

#### CompleteKLineEntity

完整的K线实体，包含所有技术指标。

```swift
public class CompleteKLineEntity: KLineEntity {
    // 基础数据
    public var open: Double
    public var high: Double
    public var low: Double
    public var close: Double
    public var volume: Double
    public var timestamp: Int
    
    // 移动平均线
    public var MA5Price: Double
    public var MA10Price: Double
    public var MA20Price: Double
    public var MA30Price: Double
    
    // 布林带
    public var up: Double    // 上轨
    public var mb: Double    // 中轨
    public var dn: Double    // 下轨
    
    // MACD
    public var dif: Double
    public var dea: Double
    public var macd: Double
    
    // KDJ
    public var k: Double
    public var d: Double
    public var j: Double
    
    // RSI
    public var rsi: Double
    
    // WR
    public var r: Double
    
    // 成交量MA
    public var MA5Volume: Double
    public var MA10Volume: Double
}
```

#### DepthEntity

深度图数据实体。

```swift
public class DepthEntity {
    public let price: Double   // 价格
    public let amount: Double  // 数量
}
```

### 工具类

#### DataUtil

数据计算工具类。

```swift
public class DataUtil {
    // 计算所有技术指标
    public static func calculate(_ dataList: [CompleteKLineEntity])
    
    // 添加新数据并计算指标
    public static func addLastData(_ dataList: inout [CompleteKLineEntity], _ data: CompleteKLineEntity)
    
    // 更新最后一条数据
    public static func updateLastData(_ dataList: [CompleteKLineEntity])
    
    // 获取日期字符串
    public static func getDate(_ timestamp: Int) -> String
}
```

#### NumberUtil

数字格式化工具类。

```swift
public class NumberUtil {
    // 格式化价格
    public static func format(_ price: Double) -> String
    
    // 格式化成交量
    public static func volFormat(_ volume: Double) -> String
    
    // 设置小数位数
    public static var fractionDigits: Int
}
```

## 性能优化

### 大数据量处理

对于大量数据，建议：

1. **分页加载** - 只显示当前可见区域的数据
2. **数据采样** - 在缩放级别较低时使用采样数据
3. **异步计算** - 在后台线程计算技术指标

```swift
// 示例：分页加载
private func loadDataInPages() {
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        let pageSize = 1000
        var allData: [CompleteKLineEntity] = []
        
        for page in 0..<10 {
            let pageData = self?.loadPageData(page: page, size: pageSize) ?? []
            allData.append(contentsOf: pageData)
        }
        
        // 计算技术指标
        DataUtil.calculate(allData)
        
        DispatchQueue.main.async {
            self?.kLineChartView.datas = allData
        }
    }
}
```

## 注意事项

1. **内存管理** - 大量数据时注意内存使用
2. **线程安全** - 数据更新应在主线程进行
3. **性能考虑** - 避免频繁的setNeedsDisplay调用
4. **数据完整性** - 确保K线数据的OHLC逻辑正确

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

## 更新日志

### v1.0.0
- 初始版本发布
- 支持K线图、线图、深度图
- 支持主要技术指标
- 支持手势交互
- 支持自定义样式
