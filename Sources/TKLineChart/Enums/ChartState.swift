import Foundation

// MARK: - 主图状态（带参数的枚举不使用 CaseIterable/rawValue）
public enum MainState: Hashable {
    case ma(Int, Int, Int)
    case ema(Int, Int, Int)
    case boll(Int, Int)
    case none
}

// MARK: - 副图状态
public enum SecondaryState: Hashable {
    case kdj(Int, Int, Int)
    case macd(Int, Int, Int)
    case rsi(Int)
    case wr(Int)
    // 成交量 MA5 和 MA10
    case vol(Int, Int)
}
