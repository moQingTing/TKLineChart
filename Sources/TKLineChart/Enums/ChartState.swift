import Foundation

// MARK: - 主图状态
public enum MainState: String, CaseIterable {
    case ma = "ma"
    case boll = "boll"
    case none = "none"
    
    public var name: String {
        return self.rawValue
    }
}

// MARK: - 副图状态
public enum SecondaryState: String, CaseIterable {
    case macd = "macd"
    case kdj = "kdj"
    case rsi = "rsi"
    case wr = "wr"
    case vol = "vol"
    
    public var name: String {
        return self.rawValue
    }
}
