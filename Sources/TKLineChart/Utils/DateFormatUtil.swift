import Foundation

public class DateFormatUtil {
    // MARK: - 日期格式常量
    public static let yyyy = "yyyy"
    public static let yy = "yy"
    public static let mm = "mm"
    public static let m = "m"
    public static let MM = "MM"
    public static let M = "M"
    public static let dd = "dd"
    public static let d = "d"
    public static let w = "w"
    public static let WW = "WW"
    public static let W = "W"
    public static let DD = "DD"
    public static let D = "D"
    public static let hh = "hh"
    public static let h = "h"
    public static let HH = "HH"
    public static let H = "H"
    public static let nn = "nn"
    public static let n = "n"
    public static let ss = "ss"
    public static let s = "s"
    public static let SSS = "SSS"
    public static let S = "S"
    public static let uuu = "uuu"
    public static let u = "u"
    public static let am = "am"
    public static let z = "z"
    public static let Z = "Z"
    
    // MARK: - 月份名称
    private static let monthShort = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                                   "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    
    private static let monthLong = ["January", "February", "March", "April", "May", "June",
                                  "July", "August", "September", "October", "November", "December"]
    
    // MARK: - 星期名称
    private static let dayShort = ["Mon", "Tue", "Wed", "Thur", "Fri", "Sat", "Sun"]
    
    private static let dayLong = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    // MARK: - 主要格式化方法
    public static func dateFormat(_ date: Date, _ formats: [String]) -> String {
        var result = ""
        
        for format in formats {
            if format == yyyy {
                result += _digits(date.year, 4)
            } else if format == yy {
                result += _digits(date.year % 100, 2)
            } else if format == mm {
                result += _digits(date.month, 2)
            } else if format == m {
                result += "\(date.month)"
            } else if format == MM {
                result += monthLong[date.month - 1]
            } else if format == M {
                result += monthShort[date.month - 1]
            } else if format == dd {
                result += _digits(date.day, 2)
            } else if format == d {
                result += "\(date.day)"
            } else if format == w {
                result += "\((date.day + 7) / 7)"
            } else if format == W {
                result += "\((dayInYear(date) + 7) / 7)"
            } else if format == WW {
                result += _digits((dayInYear(date) + 7) / 7, 2)
            } else if format == DD {
                result += dayLong[date.weekday - 1]
            } else if format == D {
                result += dayShort[date.weekday - 1]
            } else if format == HH {
                result += _digits(date.hour, 2)
            } else if format == H {
                result += "\(date.hour)"
            } else if format == hh {
                var hour = date.hour % 12
                if hour == 0 { hour = 12 }
                result += _digits(hour, 2)
            } else if format == h {
                var hour = date.hour % 12
                if hour == 0 { hour = 12 }
                result += "\(hour)"
            } else if format == am {
                result += date.hour < 12 ? "AM" : "PM"
            } else if format == nn {
                result += _digits(date.minute, 2)
            } else if format == n {
                result += "\(date.minute)"
            } else if format == ss {
                result += _digits(date.second, 2)
            } else if format == s {
                result += "\(date.second)"
            } else if format == SSS {
                result += _digits(date.millisecond, 3)
            } else if format == S {
                result += "\(date.second)"
            } else if format == uuu {
                result += _digits(date.microsecond, 2)
            } else if format == u {
                result += "\(date.microsecond)"
            } else if format == z {
                let timeZoneOffset = date.timeZoneOffset
                if timeZoneOffset == 0 {
                    result += "Z"
                } else {
                    if timeZoneOffset < 0 {
                        result += "-"
                        result += _digits((-timeZoneOffset / 3600) % 24, 2)
                        result += _digits((-timeZoneOffset / 60) % 60, 2)
                    } else {
                        result += "+"
                        result += _digits((timeZoneOffset / 3600) % 24, 2)
                        result += _digits((timeZoneOffset / 60) % 60, 2)
                    }
                }
            } else if format == Z {
                result += date.timeZoneName
            } else {
                result += format
            }
        }
        
        return result
    }
    
    // MARK: - 辅助方法
    private static func _digits(_ value: Int, _ length: Int) -> String {
        let str = "\(value)"
        if str.count < length {
            return String(repeating: "0", count: length - str.count) + str
        }
        return str
    }
    
    private static func dayInYear(_ date: Date) -> Int {
        let calendar = Calendar.current
        let startOfYear = calendar.date(from: DateComponents(year: date.year, month: 1, day: 1))!
        return calendar.dateComponents([.day], from: startOfYear, to: date).day ?? 0
    }
}

// MARK: - Date 扩展
extension Date {
    var year: Int {
        return Calendar.current.component(.year, from: self)
    }
    
    var month: Int {
        return Calendar.current.component(.month, from: self)
    }
    
    var day: Int {
        return Calendar.current.component(.day, from: self)
    }
    
    var hour: Int {
        return Calendar.current.component(.hour, from: self)
    }
    
    var minute: Int {
        return Calendar.current.component(.minute, from: self)
    }
    
    var second: Int {
        return Calendar.current.component(.second, from: self)
    }
    
    var millisecond: Int {
        return Calendar.current.component(.nanosecond, from: self) / 1000000
    }
    
    var microsecond: Int {
        return Calendar.current.component(.nanosecond, from: self) / 1000
    }
    
    var weekday: Int {
        return Calendar.current.component(.weekday, from: self)
    }
    
    var timeZoneOffset: Int {
        return TimeZone.current.secondsFromGMT(for: self)
    }
    
    var timeZoneName: String {
        return TimeZone.current.identifier
    }
}
