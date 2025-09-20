## TKLineChart

一个纯 Swift 的专业 K 线图/深度图组件，支持主图与多副图指标、手势交互与实时更新。本文档为"引用指南"，帮助你快速集成到项目中。

> 🙏 **致谢**: 本项目参考了 [flutter_k_chart](https://github.com/gwhcn/flutter_k_chart) 的设计思路与实现方案，感谢原作者 [@gwhcn](https://github.com/gwhcn) 的贡献。

### 兼容性
- **iOS**: 13.0+
- **Swift**: 5.7+
- **包管理**: Swift Package Manager (SPM)

## 安装（Swift Package Manager）
在 Xcode 中选择 File → Add Packages…，输入仓库地址并添加：

```
https://github.com/moQingTing/TKLineChart
```

添加完成后，在目标的 Frameworks, Libraries, and Embedded Content 中确认已包含 `TKLineChart`。

## 快速集成
### 1) 创建并放置视图
```swift
import TKLineChart

let chartView = TKLineChartView()
chartView.translatesAutoresizingMaskIntoConstraints = false
view.addSubview(chartView)
NSLayoutConstraint.activate([
    chartView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
    chartView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
    chartView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
    chartView.heightAnchor.constraint(equalToConstant: 360)
])
```

### 2) 基本配置
```swift
chartView.chartColors = ChartColors(isDarkMode: false)
chartView.chartStyle = ChartStyle()
chartView.fractionDigits = 2

// 主图：MA/EMA/BOLL 三选一（带参数）
chartView.mainState = .ema(5, 10, 20)

// 副图：可多选（示例：成交量与 MACD）
chartView.secondaryStates = [
    .vol(5, 10),
    .macd(12, 26, 9)
]
```

### 3) 准备数据并计算指标
```swift
var data: [CompleteKLineEntity] = []
// 生成/加载 K 线数据（OHLCV 与时间戳必填）
for i in 0..<120 {
    let e = CompleteKLineEntity(
        open: 100 + Double.random(in: -2...2),
        high: 105,
        low: 95,
        close: 100 + Double.random(in: -2...2),
        volume: Double.random(in: 1000...6000),
        timestamp: Int(Date().timeIntervalSince1970) + i*60
    )
    data.append(e)
}

// 计算主图与副图指标（必须在 updateData 之前执行）
DataUtil.calculate(data, main: chartView.mainState, seconds: chartView.secondaryStates)

// 刷新图表
chartView.updateData(data)
```

### 4) 实时更新（可选）
```swift
// 拉到一根新K线（新时间戳）或更新最后一根（相同时间戳）后：
DataUtil.calculate(data, main: chartView.mainState, seconds: chartView.secondaryStates)
chartView.updateData(data)
```

## 常见用法
- **切换线图/蜡烛图**
```swift
chartView.isLine = true // or false
```

- **切换主图指标（单选）**
```swift
chartView.mainState = .boll(20, 2)
DataUtil.calculate(data, main: chartView.mainState, seconds: chartView.secondaryStates)
chartView.updateData(data)
```

- **切换副图指标（多选）**
```swift
chartView.secondaryStates = [.vol(5, 10), .macd(12, 26, 9), .rsi(14)]
DataUtil.calculate(data, main: chartView.mainState, seconds: chartView.secondaryStates)
chartView.updateData(data)
```

## 指标一览
- **主图**: `.ma(Int,Int,Int)`, `.ema(Int,Int,Int)`, `.boll(Int,Int)`, `.none`
- **副图**: `.vol(Int,Int)`, `.macd(Int,Int,Int)`, `.kdj(Int,Int,Int)`, `.rsi(Int)`, `.wr(Int)`

## 深度图（可选）
```swift
let depthView = TKDepthChartView()
depthView.chartColors = ChartColors(isDarkMode: false)
depthView.decimal = 2
depthView.bids = [DepthEntity(price: 99.8, amount: 120)]
depthView.asks = [DepthEntity(price: 100.2, amount: 130)]
```

## 自定义主题与样式
```swift
// 内置主题（示例：币安风格）
ChartConfiguration.shared.currentTheme = .binance

// 或者手动调整样式/颜色
var style = ChartStyle()
style.singleSecondaryMaxHeightRatio = 0.18
var colors = ChartColors(isDarkMode: false)
chartView.chartStyle = style
chartView.chartColors = colors
```

## 示例与演示
- 示例 App: `Examples/TKLineChartDemo`
- 运行后可查看：
  - 指标切换（主图单选、副图多选）
  - 横屏全屏展示与滚动指标栏
  - 模拟数据与实时更新

## 贡献与支持
- 欢迎提 Issue/PR，一起完善指标、性能和动画。
- 如果这个库对你有帮助，欢迎点 Star 支持！

## 请喝咖啡 ☕️

如果这个项目对你有帮助，欢迎请我喝杯咖啡，支持我继续开发更多好用的组件！

<div align="center">
  <img src="images/0e5e143c1524158b418eecc882c02878.jpg" alt="微信赞赏" width="200" />
  <img src="images/aaa625d4a14d2439b20af36c96ac998f.jpg" alt="支付宝赞赏" width="200" />
</div>

🙏 **感谢支持！**

## 许可证
本项目采用 MIT License。

## 致谢
感谢 [flutter_k_chart](https://github.com/gwhcn/flutter_k_chart) 项目提供的设计思路与实现参考。
