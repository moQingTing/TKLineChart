# 变更日志 (CHANGELOG)

本文档记录 TKLineChart 的所有重要变更。

## [未发布]

### ✨ 新增功能

#### 价格和成交量格式化回调支持

**功能描述：**
- 新增 `priceFormatter` 和 `volumeFormatter` 回调，支持外部自定义价格和成交量的显示格式
- 格式化回调返回 `NSAttributedString`，支持自定义颜色、字体等样式
- 价格和成交量格式化完全独立，互不干扰
- 移除了 `numberFractionDigits` 配置项，改为使用格式化回调

**使用方式：**

```swift
let chartConfiguration = ChartConfiguration()

// 配置价格格式化回调：自定义价格显示格式（返回 NSAttributedString 支持样式）
chartConfiguration.priceFormatter = { price in
    // 示例1：保留4位小数，默认样式
    let text = String(format: "%.4f", price)
    return NSAttributedString(
        string: text,
        attributes: [
            .font: UIFont.systemFont(ofSize: 9.0),
            .foregroundColor: UIColor.black
        ]
    )
    
    // 示例2：自定义颜色和字体
    // let text = NumberUtil.format(price, 4)
    // return NSAttributedString(
    //     string: text,
    //     attributes: [
    //         .font: UIFont.boldSystemFont(ofSize: 10.0),
    //         .foregroundColor: UIColor.systemBlue
    //     ]
    // )
    
    // 示例3：带货币符号，不同部分不同颜色
    // let priceText = String(format: "%.2f", price)
    // let attributed = NSMutableAttributedString(
    //     string: "¥\(priceText)",
    //     attributes: [.font: UIFont.systemFont(ofSize: 9.0)]
    // )
    // attributed.addAttribute(.foregroundColor, value: UIColor.red, range: NSRange(location: 0, length: 1))
    // attributed.addAttribute(.foregroundColor, value: UIColor.black, range: NSRange(location: 1, length: priceText.count))
    // return attributed
}

// 配置成交量格式化回调：自定义成交量显示格式（返回 NSAttributedString 支持样式）
chartConfiguration.volumeFormatter = { volume in
    // 示例1：使用默认缩写（k/M/B/T），默认样式
    let text = NumberUtil.abbreviate(volume, 2)
    return NSAttributedString(
        string: text,
        attributes: [
            .font: UIFont.systemFont(ofSize: 9.0),
            .foregroundColor: UIColor.black
        ]
    )
    
    // 示例2：自定义颜色
    // let text = NumberUtil.format(volume, 2)
    // return NSAttributedString(
    //     string: text,
    //     attributes: [
    //         .font: UIFont.systemFont(ofSize: 9.0),
    //         .foregroundColor: UIColor.systemGreen
    //     ]
    // )
}

// 应用到图表
chartView.chartConfiguration = chartConfiguration
```

**默认行为：**
- 如果 `priceFormatter` 为 `nil`，价格默认保留 2 位小数，使用默认文本样式
- 如果 `volumeFormatter` 为 `nil`，成交量默认保留 2 位小数，带 k/M/B/T 缩写，使用默认文本样式

**优势：**
- 返回 `NSAttributedString` 可以支持自定义颜色、字体、下划线等样式
- 可以实现更丰富的视觉效果，如不同数值范围使用不同颜色
- 支持富文本显示，提升用户体验

**影响范围：**
- 所有价格显示：K线价格、MA/EMA/BOLL 指标值、右侧刻度、实时价格、信息面板等
- 所有成交量显示：成交量柱状图、成交量MA、信息面板中的成交量和金额

**API 变更：**
- ✅ 新增：`ChartConfiguration.priceFormatter: ((Double) -> NSAttributedString)?`
- ✅ 新增：`ChartConfiguration.volumeFormatter: ((Double) -> NSAttributedString)?`
- ✅ 新增：`BaseChartPainter.formatVolume(_ n: Double) -> NSAttributedString`
- ✅ 新增：`BaseChartRenderer.formatVolume(_ n: Double) -> NSAttributedString`
- ✅ 更新：`BaseChartPainter.format(_ n: Double) -> NSAttributedString`（原返回 String）
- ✅ 更新：`BaseChartRenderer.format(_ n: Double) -> NSAttributedString`（原返回 String）
- ❌ 移除：`ChartConfiguration.numberFractionDigits: Int`
- ❌ 移除：`format(_ n: Double, fractionDigits: Int)` 中的 `fractionDigits` 参数

**向后兼容性：**
- `TKLineChartView.fractionDigits` 属性仍然可用，会自动转换为 `priceFormatter` 回调
- 未设置格式化回调时，使用默认格式化行为（与之前一致）

**示例代码：**
参考 `Examples/TKLineChartDemo` 中的 `SimpleExampleViewController` 和 `FullScreenChartViewController`。

---

## 历史版本

（后续版本变更将在此处记录）

