//
//  KlineChartData.swift
//  TKLineChartDemo
//
//  Created by AI Assistant on 2025/01/14.
//

import Foundation
import TKLineChart

/// OK交易所K线数据模型
class KlineChartData {
    var timestamp: Int = 0
    var open: Double = 0.0
    var high: Double = 0.0
    var low: Double = 0.0
    var close: Double = 0.0
    var volume: Double = 0.0
    var amount: Double = 0.0
    
    init() {}
    
    /// 从OK交易所API数据初始化
    /// OK交易所返回格式: [timestamp, open, high, low, close, volume, amount, confirm]
    init(array: [Any]) {
        if array.count >= 8 {
            // 安全地转换数据
            if let timestampStr = array[0] as? String {
                self.timestamp = Int(timestampStr) ?? 0
            } else if let timestampInt = array[0] as? Int {
                self.timestamp = timestampInt
            }
            
            if let openStr = array[1] as? String {
                self.open = Double(openStr) ?? 0.0
            } else if let openDouble = array[1] as? Double {
                self.open = openDouble
            }
            
            if let highStr = array[2] as? String {
                self.high = Double(highStr) ?? 0.0
            } else if let highDouble = array[2] as? Double {
                self.high = highDouble
            }
            
            if let lowStr = array[3] as? String {
                self.low = Double(lowStr) ?? 0.0
            } else if let lowDouble = array[3] as? Double {
                self.low = lowDouble
            }
            
            if let closeStr = array[4] as? String {
                self.close = Double(closeStr) ?? 0.0
            } else if let closeDouble = array[4] as? Double {
                self.close = closeDouble
            }
            
            if let volumeStr = array[5] as? String {
                self.volume = Double(volumeStr) ?? 0.0
            } else if let volumeDouble = array[5] as? Double {
                self.volume = volumeDouble
            }
            
            if let amountStr = array[6] as? String {
                self.amount = Double(amountStr) ?? 0.0
            } else if let amountDouble = array[6] as? Double {
                self.amount = amountDouble
            }
        }
    }
    
    /// 转换为CompleteKLineEntity
    func toCompleteKLineEntity() -> CompleteKLineEntity {
        let entity = CompleteKLineEntity()
        entity.timestamp = self.timestamp
        entity.open = self.open
        entity.high = self.high
        entity.low = self.low
        entity.close = self.close
        entity.volume = self.volume
        entity.amount = self.amount
        entity.count = Int(self.volume) // 使用成交量作为交易笔数
        
        return entity
    }
}
