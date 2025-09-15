import Foundation

public class DataUtil {
    // public static let maPricePeriods: [Int] = [5, 10, 20, 30]
    
    // MARK: - 获取日期字符串
    public static func getDate(_ timestamp: Int) -> String {
        // 兼容毫秒/秒时间戳
        let seconds: TimeInterval
        if timestamp > 1_000_000_000_000 { // 毫秒级
            seconds = TimeInterval(timestamp) / 1000.0
        } else {
            seconds = TimeInterval(timestamp)
        }
        let date = Date(timeIntervalSince1970: seconds)
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

    // 根据主图单选 + 副图多选的参数化计算
    public static func calculate(_ dataList: [CompleteKLineEntity], main: MainState, seconds: [SecondaryState]) {
        guard !dataList.isEmpty else { return }

        // 收集主图所需的价格 MA 周期
        var needMaPeriods: Set<Int> = []
        var needEmaPeriods: Set<Int> = []
        switch main {
        case let .ma(p1, p2, p3):
            needMaPeriods.formUnion([p1, p2, p3])
        case let .boll(p, _):
            needMaPeriods.insert(p)
        case let .ema(p1, p2, p3):
            needEmaPeriods.formUnion([p1, p2, p3])
        case .none:
            break
        }

        if !needMaPeriods.isEmpty {
            _calcMAPeriods(dataList, periods: Array(needMaPeriods))
        }
        if !needEmaPeriods.isEmpty {
            _calcEMAPeriods(dataList, periods: Array(needEmaPeriods))
        }

        // 主图
        switch main {
        case .none:
            break
        case .ma:
            // 已计算
            break
        case .ema:
            // 已计算
            break
        case let .boll(p, k):
            _calcBOLL(dataList, period: p, k: k)
        }

        // 副图
        for s in seconds {
            switch s {
            case let .vol(p1, p2):
                _calcVolumeMA(dataList, p1: p1, p2: p2)
            case let .macd(p1, p2, p3):
                _calcMACD_params(dataList, p1: p1, p2: p2, p3: p3)
            case let .kdj(p1, p2, p3):
                _calcKDJ_params(dataList, p1: p1, p2: p2, p3: p3)
            case let .rsi(p):
                _calcRSI_params(dataList, period: p)
            case let .wr(p):
                _calcWR_params(dataList, period: p)
            }
        }
    }

    // 仅计算指定周期价格 EMA，写入 emaPrices
    private static func _calcEMAPeriods(_ dataList: [CompleteKLineEntity], periods: [Int]) {
        let ps = periods.filter { $0 > 1 }.sorted()
        guard !ps.isEmpty else { return }
        var emaPrev: [Int: Double] = [:]
        for p in ps { emaPrev[p] = 0 }
        for i in 0..<dataList.count {
            let close = dataList[i].close
            for p in ps {
                let k = 2.0 / Double(p + 1)
                if i == 0 {
                    emaPrev[p] = close
                } else {
                    emaPrev[p] = (close - (emaPrev[p] ?? 0)) * k + (emaPrev[p] ?? 0)
                }
                dataList[i].emaPrices[p] = emaPrev[p] ?? 0
            }
        }
    }

    // 仅计算指定周期价格 MA，写入 maPrices，并兼容同步到 MA5/10/20/30 字段
    private static func _calcMAPeriods(_ dataList: [CompleteKLineEntity], periods: [Int]) {
        let ps = periods.filter { $0 > 0 }.sorted()
        guard !ps.isEmpty else { return }
        var sums: [Int: Double] = [:]
        for p in ps { sums[p] = 0 }
        for i in 0..<dataList.count {
            let c = dataList[i].close
            for p in ps {
                sums[p, default: 0] += c
                if i == p - 1 {
                    dataList[i].maPrices[p] = (sums[p] ?? 0) / Double(p)
                } else if i >= p {
                    sums[p, default: 0] -= dataList[i - p].close
                    dataList[i].maPrices[p] = (sums[p] ?? 0) / Double(p)
                } else {
                    dataList[i].maPrices[p] = 0
                }
            }
            // 不再同步回固定字段，统一通过 maPrices 访问
        }
    }

    // 参数化 BOLL（依赖指定 period 的 MA）
    private static func _calcBOLL(_ dataList: [CompleteKLineEntity], period: Int, k: Int) {
        guard period > 1 else { return }
        for i in 0..<dataList.count {
            let e = dataList[i]
            if i < period - 1 {
                e.mb = 0; e.up = 0; e.dn = 0
                continue
            }
            let n = period
            var md: Double = 0
            let ma = e.maPrices[period] ?? 0
            for j in (i - n + 1)...i {
                let diff = dataList[j].close - ma
                md += diff * diff
            }
            md = sqrt(md / Double(n))
            e.mb = ma
            e.up = ma + Double(k) * md
            e.dn = ma - Double(k) * md
        }
    }

    // 参数化 MACD(p1,p2,p3)
    private static func _calcMACD_params(_ dataList: [CompleteKLineEntity], p1: Int, p2: Int, p3: Int) {
        guard p1 > 0, p2 > 0, p3 > 0 else { return }
        var ema1: Double = 0
        var ema2: Double = 0
        var dif: Double = 0
        var dea: Double = 0
        for i in 0..<dataList.count {
            let c = dataList[i].close
            if i == 0 {
                ema1 = c; ema2 = c
            } else {
                ema1 = ema1 * Double(p1 - 1) / Double(p1 + 1) + c * 2 / Double(p1 + 1)
                ema2 = ema2 * Double(p2 - 1) / Double(p2 + 1) + c * 2 / Double(p2 + 1)
            }
            dif = ema1 - ema2
            dea = dea * Double(p3 - 1) / Double(p3) + dif / Double(p3)
            dataList[i].dif = dif
            dataList[i].dea = dea
            dataList[i].macd = (dif - dea) * 2
            dataList[i].emaPrices[p1] = ema1
            dataList[i].emaPrices[p2] = ema2
        }
    }

    // 参数化 RSI(period)
    private static func _calcRSI_params(_ dataList: [CompleteKLineEntity], period: Int) {
        guard period > 1 else { return }
        var rsi: Double = 0
        var rsiABSEma: Double = 0
        var rsiMaxEma: Double = 0
        for i in 0..<dataList.count {
            let c = dataList[i].close
            if i == 0 {
                rsi = 0; rsiABSEma = 0; rsiMaxEma = 0
            } else {
                let inc = max(0, c - dataList[i - 1].close)
                let absd = abs(c - dataList[i - 1].close)
                rsiMaxEma = (inc + Double(period - 1) * rsiMaxEma) / Double(period)
                rsiABSEma = (absd + Double(period - 1) * rsiABSEma) / Double(period)
                rsi = rsiABSEma == 0 ? 0 : (rsiMaxEma / rsiABSEma) * 100
            }
            if i < period - 1 { rsi = 0 }
            if rsi.isNaN { rsi = 0 }
            dataList[i].rsi = rsi
            dataList[i].rsiABSEma = rsiABSEma
            dataList[i].rsiMaxEma = rsiMaxEma
        }
    }

    // 参数化 KDJ(p1,p2,p3)
    private static func _calcKDJ_params(_ dataList: [CompleteKLineEntity], p1: Int, p2: Int, p3: Int) {
        guard p1 > 0, p2 > 0, p3 > 0 else { return }
        var k: Double = 0
        var d: Double = 0
        for i in 0..<dataList.count {
            let c = dataList[i].close
            let start = max(0, i - (p1 - 1))
            var h = -Double.greatestFiniteMagnitude
            var l = Double.greatestFiniteMagnitude
            for j in start...i { h = max(h, dataList[j].high); l = min(l, dataList[j].low) }
            let rsv = (h - l) == 0 ? 0 : 100 * (c - l) / (h - l)
            if i == 0 { k = 50; d = 50 }
            k = (rsv + Double(p2 - 1) * k) / Double(p2)
            d = (k + Double(p3 - 1) * d) / Double(p3)
            if i < p1 - 1 {
                dataList[i].k = 0; dataList[i].d = 0; dataList[i].j = 0
            } else if i == p1 - 1 || i == p1 {
                dataList[i].k = k; dataList[i].d = 0; dataList[i].j = 0
            } else {
                dataList[i].k = k; dataList[i].d = d; dataList[i].j = 3 * k - 2 * d
            }
        }
    }

    // 参数化 WR(period)
    private static func _calcWR_params(_ dataList: [CompleteKLineEntity], period: Int) {
        guard period > 1 else { return }
        for i in 0..<dataList.count {
            let start = max(0, i - (period - 1))
            var h = -Double.greatestFiniteMagnitude
            var l = Double.greatestFiniteMagnitude
            for j in start...i { h = max(h, dataList[j].high); l = min(l, dataList[j].low) }
            if i < period - 1 {
                dataList[i].r = 0
            } else {
                dataList[i].r = (h - l) == 0 ? 0 : 100 * (h - dataList[i].close) / (h - l)
            }
        }
    }
    
    // 参数化 成交量MA(p1,p2)
    private static func _calcVolumeMA(_ dataList: [CompleteKLineEntity], p1: Int, p2: Int) {
        guard p1 > 0, p2 > 0 else { return }
        var sum1: Double = 0
        var sum2: Double = 0
        for i in 0..<dataList.count {
            let v = dataList[i].volume
            sum1 += v
            sum2 += v
            if i == p1 - 1 {
                dataList[i].volumeMAs[p1] = sum1 / Double(p1)
            } else if i >= p1 {
                sum1 -= dataList[i - p1].volume
                dataList[i].volumeMAs[p1] = sum1 / Double(p1)
            } else {
                dataList[i].volumeMAs[p1] = 0
            }
            if i == p2 - 1 {
                dataList[i].volumeMAs[p2] = sum2 / Double(p2)
            } else if i >= p2 {
                sum2 -= dataList[i - p2].volume
                dataList[i].volumeMAs[p2] = sum2 / Double(p2)
            } else {
                dataList[i].volumeMAs[p2] = 0
            }
        }
    }
    
    // MARK: - 计算移动平均线
    private static func _calcMA(_ dataList: [CompleteKLineEntity], isLast: Bool = false) {
        // 兼容旧全量计算入口：使用常见默认周期
        let periods = [5, 10, 20, 30].filter { $0 > 0 }.sorted()
        guard !periods.isEmpty else { return }
        var sums: [Int: Double] = [:]
        for p in periods { sums[p] = 0 }
        var start = 0
        if isLast && dataList.count > 1 {
            start = dataList.count - 1
            // 使用通用窗口求和初始化，不再依赖 MA5/10/20/30 等固定字段
            for p in periods {
                var s: Double = 0
                let endExclusive = dataList.count - 1
                let begin = max(0, endExclusive - (p - 1))
                if begin < endExclusive {
                    for j in begin..<endExclusive { s += dataList[j].close }
                }
                sums[p] = s
            }
        }
        for i in start..<dataList.count {
            let e = dataList[i]
            let c = e.close
            for p in periods {
                sums[p, default: 0] += c
                if i == p - 1 {
                    e.maPrices[p] = (sums[p] ?? 0) / Double(p)
                } else if i >= p {
                    sums[p, default: 0] -= dataList[i - p].close
                    e.maPrices[p] = (sums[p] ?? 0) / Double(p)
                } else {
                    e.maPrices[p] = 0
                }
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
                    let m = entity.maPrices[20] ?? 0
                    let value = c - m
                    md += value * value
                }
                
                md = md / Double(n)
                md = sqrt(md)
                
                entity.mb = entity.maPrices[20] ?? 0
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
            ema12 = data.emaPrices[12] ?? 0
            ema26 = data.emaPrices[26] ?? 0
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
            entity.emaPrices[12] = ema12
            entity.emaPrices[26] = ema26
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
            volumeMa5 = (data.volumeMAs[5] ?? 0) * 5
            volumeMa10 = (data.volumeMAs[10] ?? 0) * 10
        }
        
        for index in i..<dataList.count {
            let entry = dataList[index]
            
            volumeMa5 += entry.volume
            volumeMa10 += entry.volume
            
            if index == 4 {
                entry.volumeMAs[5] = volumeMa5 / 5
            } else if index > 4 {
                volumeMa5 -= dataList[index - 5].volume
                entry.volumeMAs[5] = volumeMa5 / 5
            } else {
                entry.volumeMAs[5] = 0
            }
            
            if index == 9 {
                entry.volumeMAs[10] = volumeMa10 / 10
            } else if index > 9 {
                volumeMa10 -= dataList[index - 10].volume
                entry.volumeMAs[10] = volumeMa10 / 10
            } else {
                entry.volumeMAs[10] = 0
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
