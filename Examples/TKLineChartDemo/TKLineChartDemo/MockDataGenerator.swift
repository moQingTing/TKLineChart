//
//  MockDataGenerator.swift
//  TKLineChartDemo
//
//  Created by Peter Mo on 2025/1/14.
//

import Foundation
import TKLineChart

// MARK: - 虚拟数据生成器
class MockDataGenerator {
    
    // MARK: - 属性
    private var basePrice: Double = 50000.0  // 基础价格
    private var currentPrice: Double = 50000.0
    private var dataCount: Int = 0
    private var lastTimestamp: Int = 0
    
    // MARK: - 初始化
    init() {
        // 设置初始时间戳为当前时间
        lastTimestamp = Int(Date().timeIntervalSince1970)
    }
    
    // MARK: - 生成初始历史数据
    func generateInitialData(count: Int = 100) -> [CompleteKLineEntity] {
        var entities: [CompleteKLineEntity] = []
        var currentPrice = basePrice
        
        // 生成过去100个数据点
        for i in 0..<count {
            let timestamp = lastTimestamp - (count - i) * 60 // 每分钟一个数据点
            let entity = generateKLineEntity(price: currentPrice, timestamp: timestamp)
            entities.append(entity)
            currentPrice = entity.close
        }
        
        dataCount = count
        self.currentPrice = currentPrice
        return entities
    }
    
    // MARK: - 生成新的实时数据
    func generateNewData() -> CompleteKLineEntity {
        let timestamp = lastTimestamp + 60 // 增加1分钟
        lastTimestamp = timestamp
        
        let entity = generateKLineEntity(price: currentPrice, timestamp: timestamp)
        currentPrice = entity.close
        dataCount += 1
        
        return entity
    }
    
    // MARK: - 生成K线实体
    private func generateKLineEntity(price: Double, timestamp: Int) -> CompleteKLineEntity {
        let entity = CompleteKLineEntity()
        
        // 生成价格波动 (-2% 到 +2%)
        let volatility = Double.random(in: -0.02...0.02)
        let newPrice = price * (1 + volatility)
        
        // 生成OHLC数据
        let open = currentPrice
        let close = newPrice
        
        // 确保高价是最高价，低价是最低价
        let baseHigh = max(open, close)
        let baseLow = min(open, close)
        
        // 高价应该 >= max(open, close)，低价应该 <= min(open, close)
        let high = baseHigh + Double.random(in: 0...baseHigh * 0.01) // 高价可能比最高价高0-1%
        let low = baseLow - Double.random(in: 0...baseLow * 0.01)    // 低价可能比最低价低0-1%
        
        // 生成成交量
        let volume = Double.random(in: 1000...10000)
        let amount = volume * (high + low) / 2
        
        // 设置基础数据
        entity.open = open
        entity.high = high
        entity.low = low
        entity.close = close
        entity.volume = volume
        entity.amount = amount
        entity.count = Int.random(in: 100...1000)
        entity.timestamp = timestamp
        
        // 生成技术指标数据
        generateTechnicalIndicators(for: entity)
        
        return entity
    }
    
    // MARK: - 生成技术指标
    private func generateTechnicalIndicators(for entity: CompleteKLineEntity) {
        // MA指标 (简单移动平均)
        entity.maPrices[5] = entity.close * Double.random(in: 0.98...1.02)
        entity.maPrices[10] = entity.close * Double.random(in: 0.97...1.03)
        entity.maPrices[20] = entity.close * Double.random(in: 0.95...1.05)
        entity.maPrices[30] = entity.close * Double.random(in: 0.93...1.07)
        entity.maPrices[60] = entity.close * Double.random(in: 0.90...1.10)
        
        // 布林带
        entity.mb = entity.close * Double.random(in: 0.98...1.02)
        entity.up = entity.mb * Double.random(in: 1.02...1.05)
        entity.dn = entity.mb * Double.random(in: 0.95...0.98)
        
        // 成交量MA（示例随机）
        entity.volumeMAs[5] = entity.volume * Double.random(in: 0.8...1.2)
        entity.volumeMAs[10] = entity.volume * Double.random(in: 0.7...1.3)
        
        // KDJ指标
        entity.k = Double.random(in: 0...100)
        entity.d = Double.random(in: 0...100)
        entity.j = Double.random(in: 0...100)
        
        // RSI指标
        entity.rsi = Double.random(in: 0...100)
        entity.rsiABSEma = Double.random(in: 0...100)
        entity.rsiMaxEma = Double.random(in: 0...100)
        
        // WR指标
        entity.r = Double.random(in: -100...0)
        
        // MACD指标
        entity.dif = Double.random(in: -100...100)
        entity.dea = Double.random(in: -100...100)
        entity.macd = entity.dif - entity.dea
        entity.emaPrices[12] = entity.close * Double.random(in: 0.95...1.05)
        entity.emaPrices[26] = entity.close * Double.random(in: 0.90...1.10)
    }
    
    // MARK: - 重置数据
    func reset() {
        currentPrice = basePrice
        dataCount = 0
        lastTimestamp = Int(Date().timeIntervalSince1970)
    }
    
    // MARK: - 获取当前价格
    func getCurrentPrice() -> Double {
        return currentPrice
    }
    
    // MARK: - 获取数据计数
    func getDataCount() -> Int {
        return dataCount
    }
}
