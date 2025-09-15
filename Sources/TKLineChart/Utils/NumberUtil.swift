import Foundation

public class NumberUtil {
    nonisolated(unsafe) private static var _fractionDigits: Int = 2
    
    public static var fractionDigits: Int {
        get { return _fractionDigits }
        set { _fractionDigits = newValue }
    }
    
    public static func volFormat(_ n: Double) -> String {
        if abs(n) >= 1_000 && abs(n) < 1_000_000 {
            let d = n / 1_000
            return trimTrailingZeros(String(format: "%.2f", d)) + "k"
        } else if abs(n) >= 1_000_000 && abs(n) < 1_000_000_000 {
            let d = n / 1_000_000
            return trimTrailingZeros(String(format: "%.2f", d)) + "M"
        } else if abs(n) >= 1_000_000_000 && abs(n) < 1_000_000_000_000 {
            let d = n / 1_000_000_000
            return trimTrailingZeros(String(format: "%.2f", d)) + "B"
        } else if abs(n) >= 1_000_000_000_000 {
            let d = n / 1_000_000_000_000
            return trimTrailingZeros(String(format: "%.2f", d)) + "T"
        }
        return trimTrailingZeros(String(format: "%.2f", n))
    }
    
    public static func format(_ price: Double) -> String {
        return formatNum(price, _fractionDigits)
    }
    
    /// 取小数点后几位
    /// - Parameters:
    ///   - num: 数值
    ///   - location: 几位
    public static func formatNum(_ num: Double, _ location: Int) -> String {
        let numStr = String(num)
        let components = numStr.components(separatedBy: ".")
        
        if components.count == 1 {
            // 整数
            return String(format: "%.\(location)f", num)
        } else {
            let decimalPart = components[1]
            if decimalPart.count < location {
                return String(format: "%.\(location)f", num)
            } else {
                let truncatedDecimal = String(decimalPart.prefix(location))
                return "\(components[0]).\(truncatedDecimal)"
            }
        }
    }

    // 通用缩写：1000->1k, 1_000_000->1M, 1_000_000_000->1B, 1_000_000_000_000->1T
    public static func abbreviate(_ n: Double) -> String {
        return volFormat(n)
    }

    private static func trimTrailingZeros(_ s: String) -> String {
        var str = s
        while str.contains(".") && (str.hasSuffix("0") || str.hasSuffix(".")) {
            if str.hasSuffix("0") { str.removeLast() }
            if str.hasSuffix(".") { str.removeLast() }
        }
        return str
    }
}
