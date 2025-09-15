import Foundation

public class NumberUtil {
    nonisolated(unsafe) private static var _fractionDigits: Int = 2
    
    public static var fractionDigits: Int {
        get { return _fractionDigits }
        set { _fractionDigits = newValue }
    }
    
    public static func volFormat(_ n: Double) -> String {
        if n > 10000 && n < 999999 {
            let d = n / 1000
            return String(format: "%.2fK", d)
        } else if n > 1000000 {
            let d = n / 1000000
            return String(format: "%.2fM", d)
        }
        return String(format: "%.2f", n)
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
}
