import Foundation

// MARK: - 基础K线实体
public class KLineEntity {
    public var open: Double = 0
    public var high: Double = 0
    public var low: Double = 0
    public var close: Double = 0
    public var volume: Double = 0
    public var amount: Double = 0
    public var count: Int = 0
    public var timestamp: Int = 0 // 时间戳
    
    public init() {}
    
    public init(open: Double, high: Double, low: Double, close: Double, volume: Double, timestamp: Int) {
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
        self.timestamp = timestamp
    }
    
    public convenience init(from json: [String: Any]) {
        self.init()
        self.open = json["open"] as? Double ?? 0
        self.high = json["high"] as? Double ?? 0
        self.low = json["low"] as? Double ?? 0
        self.close = json["close"] as? Double ?? 0
        self.volume = json["vol"] as? Double ?? 0
        self.amount = json["amount"] as? Double ?? 0
        self.count = json["count"] as? Int ?? 0
        self.timestamp = json["id"] as? Int ?? 0
    }
    
    public func toJson() -> [String: Any] {
        return [
            "id": timestamp,
            "open": open,
            "close": close,
            "high": high,
            "low": low,
            "vol": volume,
            "amount": amount,
            "count": count
        ]
    }
}

// MARK: - 技术指标协议
public protocol CandleEntity {
    // 参数化价格均线：key 为周期，value 为对应均线
    var maPrices: [Int: Double] { get set }
    var up: Double { get set }      // 布林带上轨
    var mb: Double { get set }      // 布林带中轨
    var dn: Double { get set }      // 布林带下轨
}

public protocol VolumeEntity {
    // 参数化成交量均线：key 为周期，value 为对应均量
    var volumeMAs: [Int: Double] { get set }
}

public protocol KDJEntity {
    var k: Double { get set }
    var d: Double { get set }
    var j: Double { get set }
}

public protocol RSIEntity {
    var rsi: Double { get set }
    var rsiABSEma: Double { get set }
    var rsiMaxEma: Double { get set }
}

public protocol WREntity {
    var r: Double { get set } // %R值
}

public protocol MACDEntity {
    var dea: Double { get set }
    var dif: Double { get set }
    var macd: Double { get set }
    var emaPrices: [Int: Double] { get set }
}

// MARK: - 完整的K线实体
public class CompleteKLineEntity: KLineEntity, CandleEntity, VolumeEntity, KDJEntity, RSIEntity, WREntity, MACDEntity, Equatable {
    // CandleEntity
    public var up: Double = 0
    public var mb: Double = 0
    public var dn: Double = 0
    
    // VolumeEntity
    public var volumeMAs: [Int: Double] = [:]
    
    // KDJEntity
    public var k: Double = 0
    public var d: Double = 0
    public var j: Double = 0
    
    // RSIEntity
    public var rsi: Double = 0
    public var rsiABSEma: Double = 0
    public var rsiMaxEma: Double = 0
    
    // WREntity
    public var r: Double = 0
    
    // MACDEntity
    public var dea: Double = 0
    public var dif: Double = 0
    public var macd: Double = 0
    
    // 动态价格均线字典（MA/EMA 皆可存放）：key 为周期（如 5/10/20/12/26），value 为对应均线值
    public var maPrices: [Int: Double] = [:]
    // EMA 动态字典（如需与 MA 分离存放）
    public var emaPrices: [Int: Double] = [:]
    
    public override init() {
        super.init()
    }
    
    public override init(open: Double, high: Double, low: Double, close: Double, volume: Double, timestamp: Int) {
        super.init(open: open, high: high, low: low, close: close, volume: volume, timestamp: timestamp)
    }
    
    public convenience init(from json: [String: Any]) {
        self.init()
        self.open = json["open"] as? Double ?? 0
        self.high = json["high"] as? Double ?? 0
        self.low = json["low"] as? Double ?? 0
        self.close = json["close"] as? Double ?? 0
        self.volume = json["vol"] as? Double ?? 0
        self.amount = json["amount"] as? Double ?? 0
        self.count = json["count"] as? Int ?? 0
        self.timestamp = json["id"] as? Int ?? 0
    }
    
    public static func == (lhs: CompleteKLineEntity, rhs: CompleteKLineEntity) -> Bool {
        return lhs.timestamp == rhs.timestamp &&
               lhs.open == rhs.open &&
               lhs.high == rhs.high &&
               lhs.low == rhs.low &&
               lhs.close == rhs.close &&
               lhs.volume == rhs.volume
    }
}

// MARK: - 其他实体类
public class DepthEntity: Equatable {
    public let price: Double
    public let amount: Double
    
    public init(price: Double, amount: Double) {
        self.price = price
        self.amount = amount
    }
    
    public static func == (lhs: DepthEntity, rhs: DepthEntity) -> Bool {
        return lhs.price == rhs.price && lhs.amount == rhs.amount
    }
}

public class InfoWindowEntity {
    public let kLineEntity: KLineEntity
    public let isLeft: Bool
    
    public init(kLineEntity: KLineEntity, isLeft: Bool) {
        self.kLineEntity = kLineEntity
        self.isLeft = isLeft
    }
}

public class KMaxMinEntity {
    public var max: Double
    public var min: Double
    
    public init(max: Double, min: Double) {
        self.max = max
        self.min = min
    }
}
