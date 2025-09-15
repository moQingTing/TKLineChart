import Foundation

public class DataUtil {
    
    // MARK: - 获取日期字符串
    public static func getDate(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return DateFormatUtil.dateFormat(date, [
            DateFormatUtil.yyyy, "-", DateFormatUtil.mm, "-", DateFormatUtil.dd,
            " ", DateFormatUtil.HH, ":", DateFormatUtil.nn
        ])
    }
    
    // MARK: - 计算所有技术指标
    public static func calculate(_ dataList: [CompleteKLineEntity]) {
        guard !dataList.isEmpty else { return }
        
        _calcMA(dataList)
        _calcBOLL(dataList)
        _calcVolumeMA(dataList)
        _calcKDJ(dataList)
        _calcMACD(dataList)
        _calcRSI(dataList)
        _calcWR(dataList)
    }
    
    // MARK: - 计算移动平均线
    private static func _calcMA(_ dataList: [CompleteKLineEntity], isLast: Bool = false) {
        var ma5: Double = 0
        var ma10: Double = 0
        var ma20: Double = 0
        var ma30: Double = 0
        
        var i = 0
        if isLast && dataList.count > 1 {
            i = dataList.count - 1
            let data = dataList[dataList.count - 2]
            ma5 = data.MA5Price * 5
            ma10 = data.MA10Price * 10
            ma20 = data.MA20Price * 20
            ma30 = data.MA30Price * 30
        }
        
        for index in i..<dataList.count {
            let entity = dataList[index]
            let closePrice = entity.close
            
            ma5 += closePrice
            ma10 += closePrice
            ma20 += closePrice
            ma30 += closePrice
            
            if index == 4 {
                entity.MA5Price = ma5 / 5
            } else if index >= 5 {
                ma5 -= dataList[index - 5].close
                entity.MA5Price = ma5 / 5
            } else {
                entity.MA5Price = 0
            }
            
            if index == 9 {
                entity.MA10Price = ma10 / 10
            } else if index >= 10 {
                ma10 -= dataList[index - 10].close
                entity.MA10Price = ma10 / 10
            } else {
                entity.MA10Price = 0
            }
            
            if index == 19 {
                entity.MA20Price = ma20 / 20
            } else if index >= 20 {
                ma20 -= dataList[index - 20].close
                entity.MA20Price = ma20 / 20
            } else {
                entity.MA20Price = 0
            }
            
            if index == 29 {
                entity.MA30Price = ma30 / 30
            } else if index >= 30 {
                ma30 -= dataList[index - 30].close
                entity.MA30Price = ma30 / 30
            } else {
                entity.MA30Price = 0
            }
        }
    }
    
    // MARK: - 计算布林带
    private static func _calcBOLL(_ dataList: [CompleteKLineEntity], isLast: Bool = false) {
        var i = 0
        if isLast && dataList.count > 1 {
            i = dataList.count - 1
        }
        
        for index in i..<dataList.count {
            let entity = dataList[index]
            
            if index < 19 {
                entity.mb = 0
                entity.up = 0
                entity.dn = 0
            } else {
                let n = 20
                var md: Double = 0
                
                for j in (index - n + 1)...index {
                    let c = dataList[j].close
                    let m = entity.MA20Price
                    let value = c - m
                    md += value * value
                }
                
                md = md / Double(n)
                md = sqrt(md)
                
                entity.mb = entity.MA20Price
                entity.up = entity.mb + 2.0 * md
                entity.dn = entity.mb - 2.0 * md
            }
        }
    }
    
    // MARK: - 计算MACD 标准的参数： MACD (12,26,9)
    private static func _calcMACD(_ dataList: [CompleteKLineEntity], isLast: Bool = false) {
        var ema12: Double = 0
        var ema26: Double = 0
        var dif: Double = 0
        var dea: Double = 0
        var macd: Double = 0
        
        var i = 0
        if isLast && dataList.count > 1 {
            i = dataList.count - 1
            let data = dataList[dataList.count - 2]
            dif = data.dif
            dea = data.dea
            macd = data.macd
            ema12 = data.ema12
            ema26 = data.ema26
        }
        
        for index in i..<dataList.count {
            let entity = dataList[index]
            let closePrice = entity.close
            
            if index == 0 {
                ema12 = closePrice
                ema26 = closePrice
            } else {
                // EMA（12） = 前一日EMA（12） X 11/13 + 今日收盘价 X 2/13
                ema12 = ema12 * 11 / 13 + closePrice * 2 / 13
                // EMA（26） = 前一日EMA（26） X 25/27 + 今日收盘价 X 2/27
                ema26 = ema26 * 25 / 27 + closePrice * 2 / 27
            }
            
            // DIF = EMA（12） - EMA（26）
            // 今日DEA = （前一日DEA X 8/10 + 今日DIF X 2/10）
            // 用（DIF-DEA）*2即为MACD柱状图
            dif = ema12 - ema26
            // 9天DEA
            dea = dea * 8 / 10 + dif * 2 / 10
            macd = (dif - dea) * 2
            
            entity.dif = dif
            entity.dea = dea
            entity.macd = macd
            entity.ema12 = ema12
            entity.ema26 = ema26
        }
    }
    
    // MARK: - 计算成交量移动平均线
    private static func _calcVolumeMA(_ dataList: [CompleteKLineEntity], isLast: Bool = false) {
        var volumeMa5: Double = 0
        var volumeMa10: Double = 0
        
        var i = 0
        if isLast && dataList.count > 1 {
            i = dataList.count - 1
            let data = dataList[dataList.count - 2]
            volumeMa5 = data.MA5Volume * 5
            volumeMa10 = data.MA10Volume * 10
        }
        
        for index in i..<dataList.count {
            let entry = dataList[index]
            
            volumeMa5 += entry.volume
            volumeMa10 += entry.volume
            
            if index == 4 {
                entry.MA5Volume = volumeMa5 / 5
            } else if index > 4 {
                volumeMa5 -= dataList[index - 5].volume
                entry.MA5Volume = volumeMa5 / 5
            } else {
                entry.MA5Volume = 0
            }
            
            if index == 9 {
                entry.MA10Volume = volumeMa10 / 10
            } else if index > 9 {
                volumeMa10 -= dataList[index - 10].volume
                entry.MA10Volume = volumeMa10 / 10
            } else {
                entry.MA10Volume = 0
            }
        }
    }
    
    // MARK: - 计算RSI
    private static func _calcRSI(_ dataList: [CompleteKLineEntity], isLast: Bool = false) {
        var rsi: Double = 0
        var rsiABSEma: Double = 0
        var rsiMaxEma: Double = 0
        
        var i = 0
        if isLast && dataList.count > 1 {
            i = dataList.count - 1
            let data = dataList[dataList.count - 2]
            rsi = data.rsi
            rsiABSEma = data.rsiABSEma
            rsiMaxEma = data.rsiMaxEma
        }
        
        for index in i..<dataList.count {
            let entity = dataList[index]
            let closePrice = entity.close
            
            if index == 0 {
                rsi = 0
                rsiABSEma = 0
                rsiMaxEma = 0
            } else {
                let Rmax = max(0, closePrice - dataList[index - 1].close)
                let RAbs = abs(closePrice - dataList[index - 1].close)
                
                rsiMaxEma = (Rmax + (14 - 1) * rsiMaxEma) / 14
                rsiABSEma = (RAbs + (14 - 1) * rsiABSEma) / 14
                rsi = (rsiMaxEma / rsiABSEma) * 100
            }
            
            if index < 13 { rsi = 0 }
            if rsi.isNaN { rsi = 0 }
            
            entity.rsi = rsi
            entity.rsiABSEma = rsiABSEma
            entity.rsiMaxEma = rsiMaxEma
        }
    }
    
    // MARK: - 计算KDJ
    private static func _calcKDJ(_ dataList: [CompleteKLineEntity], isLast: Bool = false) {
        var k: Double = 0
        var d: Double = 0
        
        var i = 0
        if isLast && dataList.count > 1 {
            i = dataList.count - 1
            let data = dataList[dataList.count - 2]
            k = data.k
            d = data.d
        }
        
        for index in i..<dataList.count {
            let entity = dataList[index]
            let closePrice = entity.close
            
            var startIndex = index - 13
            if startIndex < 0 {
                startIndex = 0
            }
            
            var max14: Double = -Double.greatestFiniteMagnitude
            var min14: Double = Double.greatestFiniteMagnitude
            
            for j in startIndex...index {
                max14 = max(max14, dataList[j].high)
                min14 = min(min14, dataList[j].low)
            }
            
            let rsv = 100 * (closePrice - min14) / (max14 - min14)
            let validRsv = rsv.isNaN ? 0 : rsv
            
            if index == 0 {
                k = 50
                d = 50
            } else {
                k = (validRsv + 2 * k) / 3
                d = (k + 2 * d) / 3
            }
            
            if index < 13 {
                entity.k = 0
                entity.d = 0
                entity.j = 0
            } else if index == 13 || index == 14 {
                entity.k = k
                entity.d = 0
                entity.j = 0
            } else {
                entity.k = k
                entity.d = d
                entity.j = 3 * k - 2 * d
            }
        }
    }
    
    // MARK: - 计算WR
    private static func _calcWR(_ dataList: [CompleteKLineEntity], isLast: Bool = false) {
        var i = 0
        if isLast && dataList.count > 1 {
            i = dataList.count - 1
        }
        
        for index in i..<dataList.count {
            let entity = dataList[index]
            
            var startIndex = index - 14
            if startIndex < 0 {
                startIndex = 0
            }
            
            var max14: Double = -Double.greatestFiniteMagnitude
            var min14: Double = Double.greatestFiniteMagnitude
            
            for j in startIndex...index {
                max14 = max(max14, dataList[j].high)
                min14 = min(min14, dataList[j].low)
            }
            
            if index < 13 {
                entity.r = 0
            } else {
                if (max14 - min14) == 0 {
                    entity.r = 0
                } else {
                    entity.r = 100 * (max14 - dataList[index].close) / (max14 - min14)
                }
            }
        }
    }
    
    // MARK: - 增量更新时计算最后一个数据
    public static func addLastData(_ dataList: inout [CompleteKLineEntity], _ data: CompleteKLineEntity) {
        dataList.append(data)
        _calcMA(dataList, isLast: true)
        _calcBOLL(dataList, isLast: true)
        _calcVolumeMA(dataList, isLast: true)
        _calcKDJ(dataList, isLast: true)
        _calcMACD(dataList, isLast: true)
        _calcRSI(dataList, isLast: true)
        _calcWR(dataList, isLast: true)
    }
    
    // MARK: - 更新最后一条数据
    public static func updateLastData(_ dataList: [CompleteKLineEntity]) {
        guard !dataList.isEmpty else { return }
        
        _calcMA(dataList, isLast: true)
        _calcBOLL(dataList, isLast: true)
        _calcVolumeMA(dataList, isLast: true)
        _calcKDJ(dataList, isLast: true)
        _calcMACD(dataList, isLast: true)
        _calcRSI(dataList, isLast: true)
        _calcWR(dataList, isLast: true)
    }
}
