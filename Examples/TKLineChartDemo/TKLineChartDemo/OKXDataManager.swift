//
//  OKXDataManager.swift
//  TKLineChartDemo
//
//  Created by AI Assistant on 2025/01/14.
//

import Foundation
import TKLineChart

/// OK交易所数据管理器
class OKXDataManager {
    static let shared = OKXDataManager()
    
    /// ⚠️ 可能需要VPN 才能访问OKX API
    private let apiURL = "https://www.okx.com/api/v5"
    private var currentSymbol = "BTC-USDT"
    private var currentTimeframe = "1m" // 1分钟K线
    
    // 时间周期映射
    private let timeframeMap: [String: String] = [
        "1m": "1m",
        "5m": "5m", 
        "15m": "15m",
        "30m": "30m",
        "1h": "1H",
        "4h": "4H",
        "1d": "1D"
    ]
    
    private init() {}
    
    /// 获取K线数据
    /// - Parameters:
    ///   - symbol: 交易对，如 "BTC-USDT"
    ///   - timeframe: 时间周期
    ///   - limit: 数据条数
    ///   - completion: 完成回调
    func fetchKlineData(symbol: String, timeframe: String, limit: Int = 100, 
                       completion: @escaping (Result<[CompleteKLineEntity], Error>) -> Void) {
        
        guard let mappedTimeframe = timeframeMap[timeframe] else {
            completion(.failure(OKXError.invalidTimeframe))
            return
        }
        
        let urlString = "\(apiURL)/market/candles?instId=\(symbol)&bar=\(mappedTimeframe)&limit=\(limit)"
        guard let url = URL(string: urlString) else {
            completion(.failure(OKXError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(OKXError.noData))
                }
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                guard let jsonDict = json else {
                    DispatchQueue.main.async {
                        completion(.failure(OKXError.invalidJSON))
                    }
                    return
                }
                
                let code = jsonDict["code"] as? String ?? ""
                
                if code != "0" {
                    let msg = jsonDict["msg"] as? String ?? "未知错误"
                    DispatchQueue.main.async {
                        completion(.failure(OKXError.apiError(msg)))
                    }
                    return
                }
                
                guard let klineDataArray = jsonDict["data"] as? [[Any]] else {
                    DispatchQueue.main.async {
                        completion(.failure(OKXError.invalidDataFormat))
                    }
                    return
                }
                
                var entities: [CompleteKLineEntity] = []
                
                for dataArray in klineDataArray {
                    let kline = KlineChartData(array: dataArray)
                    let entity = kline.toCompleteKLineEntity()
                    entities.append(entity)
                }
                
                // 反转数据顺序（OK交易所返回的是最新的在前）
                entities.reverse()
                
                // 使用K线组件内置的技术指标计算
                DataUtil.calculate(entities)
                
                // 添加调试信息
                if entities.count > 0 {
                    let first = entities.first!
                    let last = entities.last!
                    print("OKX API返回数据: 总数=\(entities.count), 最早=\(first.timestamp), 最新=\(last.timestamp)")
                }
                
                DispatchQueue.main.async {
                    completion(.success(entities))
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
}

/// OK交易所错误类型
enum OKXError: Error {
    case invalidURL
    case noData
    case invalidTimeframe
    case invalidJSON
    case invalidDataFormat
    case apiError(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .noData:
            return "没有数据"
        case .invalidTimeframe:
            return "无效的时间周期"
        case .invalidJSON:
            return "JSON解析失败"
        case .invalidDataFormat:
            return "数据格式错误"
        case .apiError(let message):
            return "API错误: \(message)"
        }
    }
}
