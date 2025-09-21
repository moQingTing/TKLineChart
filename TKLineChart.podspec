Pod::Spec.new do |spec|
  spec.name         = "TKLineChart"
  spec.version      = "2.0.0"
  spec.summary      = "一个纯 Swift 的专业 K 线图/深度图组件"
  spec.description  = <<-DESC
  TKLineChart 是一个纯 Swift 的专业 K 线图/深度图组件，支持主图与多副图指标、手势交互与实时更新。
  
  主要特性：
  - 支持蜡烛图和线图显示
  - 多种技术指标（MA、EMA、BOLL、MACD、KDJ、RSI、WR等）
  - 完全可定制的颜色和样式配置
  - 手势交互支持（缩放、平移、长按）
  - 实时数据更新
  - 深度图支持
  - 横屏全屏模式
  DESC

  spec.homepage     = "https://github.com/moQingTing/TKLineChart"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "moQingTing" => "moqingting@example.com" }
  
  spec.platform     = :ios, "13.0"
  spec.swift_version = "5.7"
  
  spec.source       = { :git => "https://github.com/moQingTing/TKLineChart.git", :tag => "#{spec.version}" }
  
  spec.source_files = "Sources/TKLineChart/**/*.swift"
  spec.resources    = "Sources/TKLineChart/**/*.{png,jpg,jpeg,json,storyboard,xib}"
  
  spec.frameworks   = "UIKit", "Foundation", "CoreGraphics"
  spec.requires_arc = true
  
  # 依赖项（如果有的话）
  # spec.dependency 'SomeOtherPod', '~> 1.0'
  
  # 子模块（如果有的话）
  # spec.subspec 'SubModule' do |subspec|
  #   subspec.source_files = 'Sources/TKLineChart/SubModule/**/*.swift'
  # end
  
  # 测试规范
  spec.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'Tests/TKLineChartTests/**/*.swift'
    test_spec.frameworks = 'XCTest'
  end
  
  # 文档
  spec.documentation_url = 'https://github.com/moQingTing/TKLineChart'
  
  # 社交媒体链接
  spec.social_media_url = 'https://github.com/moQingTing'
  
  # 准备命令（如果需要的话）
  # spec.prepare_command = 'echo "Preparing TKLineChart..."'
end
