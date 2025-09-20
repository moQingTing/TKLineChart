import Foundation

public class NumberUtil {
    
    public static func volFormat(_ n: Double,_ fractionDigits:Int) -> String {
        if abs(n) >= 1_000 && abs(n) < 1_000_000 {
            let d = n / 1_000
            return trimTrailingZeros(formatWithGrouping(d, fractionDigits: fractionDigits)) + "k"
        } else if abs(n) >= 1_000_000 && abs(n) < 1_000_000_000 {
            let d = n / 1_000_000
            return trimTrailingZeros(formatWithGrouping(d, fractionDigits: fractionDigits)) + "M"
        } else if abs(n) >= 1_000_000_000 && abs(n) < 1_000_000_000_000 {
            let d = n / 1_000_000_000
            return trimTrailingZeros(formatWithGrouping(d, fractionDigits: fractionDigits)) + "B"
        } else if abs(n) >= 1_000_000_000_000 {
            let d = n / 1_000_000_000_000
            return trimTrailingZeros(formatWithGrouping(d, fractionDigits: fractionDigits)) + "T"
        }
        return trimTrailingZeros(formatWithGrouping(n, fractionDigits: fractionDigits))
    }
    
    public static func format(_ price: Double,_ fractionDigits:Int) -> String {
        return formatWithGrouping(price, fractionDigits: fractionDigits)
    }
    
    /// 取小数点后几位
    /// - Parameters:
    ///   - num: 数值
    ///   - location: 几位
    public static func formatNum(_ num: Double, _ location: Int) -> String {
        return formatWithGrouping(num, fractionDigits: location)
    }

    // 通用缩写：1000->1k, 1_000_000->1M, 1_000_000_000->1B, 1_000_000_000_000->1T
    public static func abbreviate(_ n: Double,_ fractionDigits:Int) -> String {
        return volFormat(n,fractionDigits)
    }

    private static func trimTrailingZeros(_ s: String) -> String {
        var str = s
        while str.contains(".") && (str.hasSuffix("0") || str.hasSuffix(".")) {
            if str.hasSuffix("0") { str.removeLast() }
            if str.hasSuffix(".") { str.removeLast() }
        }
        return str
    }

    private static func formatWithGrouping(_ n: Double, fractionDigits: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.usesGroupingSeparator = true
        f.groupingSeparator = ","
        f.minimumFractionDigits = fractionDigits
        f.maximumFractionDigits = fractionDigits
        if let s = f.string(from: NSNumber(value: n)) {
            return s
        }
        return String(format: "%.*f", fractionDigits, n)
    }
}
