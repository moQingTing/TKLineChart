//
//  SimpleExampleViewController.swift
//  TKLineChartDemo
//
//  Created by Peter Mo on 2025/1/14.
//

import UIKit
import TKLineChart

class SimpleExampleViewController: UIViewController {
    
    // MARK: - UI组件
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var kLineChartView: TKLineChartView!
    private var averageLineChartView: AverageLineChartView!
    // 区间涨跌面板
    private var periodScrollView: UIScrollView!
    private var periodStackView: UIStackView!
    private var periodLabels: [UILabel] = []
    private var percentageLabels: [UILabel] = []
    private var controlStackView: UIStackView!
    private var startStopButton: UIButton!
    private var resetButton: UIButton!
    private var mainStateSegmentedControl: UISegmentedControl!
    private var secondaryStateStackView: UIStackView!
    private var secondaryStateButtons: [UIButton] = []
    private var secondaryHeightSlider: UISlider!
    private var secondaryHeightLabel: UILabel!
    private var symbolSegmentedControl: UISegmentedControl!
    private var timeframeSegmentedControl: UISegmentedControl!
    private var isLineButton: UIButton!
    private var statusLabel: UILabel!
    
    // Loading view
    private var loadingView: UIView!
    private var loadingIndicator: UIActivityIndicatorView!
    private var loadingLabel: UILabel!
    
    // MARK: - 数据相关
    private var okxDataManager = OKXDataManager.shared
    private var kLineData: [CompleteKLineEntity] = []
    private var timer: Timer?
    private var isRealTimeUpdating: Bool = false
    private var currentSymbol = "BTC-USDT"
    private var currentTimeframe = "1m"
    
    
    
    // 指标默认参数
    private let defaultMA = (5, 10, 20)
    private let defaultEMA = (5, 10, 20)
    private let defaultBOLL = (20, 2)
    private let defaultVOL = (5, 10)
    private let defaultMACD = (12, 26, 9)
    private let defaultRSI = 14
    private let defaultKDJ = (9, 3, 3)
    private let defaultWR = 14
    
    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // MARK: - 配置相关
         let chartConfiguration = ChartConfiguration()
         chartConfiguration.applyBinanceTheme()
         
         // 配置价格格式化回调：保留4位小数
         chartConfiguration.priceFormatter = { price in
             return String(format: "%.4f", price)
         }
         
         // 配置成交量格式化回调：保留2位小数，带缩写
         chartConfiguration.volumeFormatter = { volume in
             return NumberUtil.abbreviate(volume, 2)
         }
         
         self.kLineChartView.chartConfiguration = chartConfiguration
        // 页面显示后再异步加载数据
        if kLineData.isEmpty {
            setupData()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateChartFrame()
    }
    
    deinit {
        stopRealTimeUpdate()
    }
    
    // MARK: - UI设置
    private func setupUI() {
        view.backgroundColor = UIColor.white
        title = "TKLineChart 示例"
        
        // 添加返回按钮
        setupNavigationBar()
        
        // 创建滚动视图
        setupScrollView()
        
        // 创建K线图
        kLineChartView = TKLineChartView()
        kLineChartView.translatesAutoresizingMaskIntoConstraints = false
        kLineChartView.backgroundColor = UIColor.white
        // 设置图表配置

        // 先创建控制面板（内部会创建并添加 statusLabel），以便指标条的约束引用到 statusLabel
        setupControlPanel()
        
        contentView.addSubview(kLineChartView)

        // 创建均价折线图（演示：使用K线收盘价）
        averageLineChartView = AverageLineChartView()
        averageLineChartView.translatesAutoresizingMaskIntoConstraints = false
        averageLineChartView.style = AverageLineChartStyle(
            lineColor: UIColor.systemBlue,
            lineWidth: 2.5,
            gradientStartAlpha: 0.25,
            gradientEndAlpha: 0.02,
            backgroundColor: UIColor.white,
            padding: UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16),
            showGrid: false
        )
        contentView.addSubview(averageLineChartView)
        
        // 创建loading view
        setupLoadingView()
        
        // 设置约束
        setupConstraints()
    }
    
    private func setupLoadingView() {
        // 创建loading view容器
        loadingView = UIView()
        loadingView.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.isHidden = true
        view.addSubview(loadingView)
        
        // 创建loading指示器
        loadingIndicator = UIActivityIndicatorView(style: .large)
        loadingIndicator.color = UIColor.systemBlue
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingView.addSubview(loadingIndicator)
        
        // 创建loading文字
        loadingLabel = UILabel()
        loadingLabel.text = "正在加载数据..."
        loadingLabel.textColor = UIColor.systemBlue
        loadingLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        loadingLabel.textAlignment = .center
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingView.addSubview(loadingLabel)
        
        // 设置loading view约束
        NSLayoutConstraint.activate([
            // loading view覆盖整个屏幕
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // loading指示器居中
            loadingIndicator.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor, constant: -20),
            
            // loading文字在指示器下方
            loadingLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 16),
            loadingLabel.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            loadingLabel.leadingAnchor.constraint(greaterThanOrEqualTo: loadingView.leadingAnchor, constant: 20),
            loadingLabel.trailingAnchor.constraint(lessThanOrEqualTo: loadingView.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Loading View 控制
    private func showLoadingView(message: String = "正在加载数据...") {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.loadingLabel.text = message
            self.loadingView.isHidden = false
            self.loadingIndicator.startAnimating()
        }
    }
    
    private func hideLoadingView() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.loadingIndicator.stopAnimating()
            self.loadingView.isHidden = true
        }
    }

    private func applyIndicatorSelection(key: String) {
        // 主图互斥：MA/EMA/BOLL（带参数）
        if key == "MA" { kLineChartView.mainState = .ma(defaultMA.0, defaultMA.1, defaultMA.2) }
        if key == "EMA" { kLineChartView.mainState = .ema(defaultEMA.0, defaultEMA.1, defaultEMA.2) }
        if key == "BOLL" { kLineChartView.mainState = .boll(defaultBOLL.0, defaultBOLL.1) }

        // 副图多选：VOL/MACD/RSI（带参数）
        var set = Set<SecondaryState>(kLineChartView.secondaryStates)
        if key == "VOL" { set = toggle(set, .vol(defaultVOL.0, defaultVOL.1)) }
        if key == "MACD" { set = toggle(set, .macd(defaultMACD.0, defaultMACD.1, defaultMACD.2)) }
        if key == "RSI" { set = toggle(set, .rsi(defaultRSI)) }
        kLineChartView.secondaryStates = Array(set)
        // 指标切换后立即重算并刷新
        DataUtil.calculate(self.kLineData, main: self.kLineChartView.mainState, seconds: self.kLineChartView.secondaryStates)
        kLineChartView.updateData(self.kLineData)
        updateChartFrame()
    }

    private func toggle(_ set: Set<SecondaryState>, _ item: SecondaryState) -> Set<SecondaryState> {
        var s = set
        if s.contains(item) { s.remove(item) } else { s.insert(item) }
        return s
    }
    
    private func setupScrollView() {
        // 创建滚动视图
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        
        // 创建内容视图
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
    }
    
    private func setupNavigationBar() {
        // 添加返回按钮
        let backButton = UIBarButtonItem(
            title: "返回",
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.leftBarButtonItem = backButton
        
        // 设置导航栏样式
        navigationController?.navigationBar.tintColor = UIColor.systemBlue
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.black
        ]
    }
    
    private func setupControlPanel() {
        // 交易对选择器
        symbolSegmentedControl = UISegmentedControl(items: ["BTC-USDT", "ETH-USDT", "BNB-USDT"])
        symbolSegmentedControl.selectedSegmentIndex = 0
        symbolSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        // 时间周期选择器
        timeframeSegmentedControl = UISegmentedControl(items: ["1m", "5m", "15m", "1h", "4h", "1d"])
        timeframeSegmentedControl.selectedSegmentIndex = 0
        timeframeSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        // 主图状态选择器
        mainStateSegmentedControl = UISegmentedControl(items: ["无", "MA", "EMA", "BOLL"])
        mainStateSegmentedControl.selectedSegmentIndex = 0
        mainStateSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        // 副图状态选择器（支持多选）
        setupSecondaryStateButtons()
        
        // 副图高度配置
        setupSecondaryHeightControl()
        
        // 线图/蜡烛图切换按钮
        isLineButton = createStyledButton(title: "切换为线图", backgroundColor: UIColor.systemBlue)
        
        // 开始/停止按钮
        startStopButton = createStyledButton(title: "开始实时更新", backgroundColor: UIColor.systemGreen)
        
        // 重置按钮
        resetButton = createStyledButton(title: "重置数据", backgroundColor: UIColor.systemOrange)
        
        // 配置按钮
        let configButton = createStyledButton(title: "图表配置", backgroundColor: UIColor.systemPurple)
        configButton.addTarget(self, action: #selector(configButtonTapped), for: .touchUpInside)

        // 全屏按钮
        let fullscreenButton = createStyledButton(title: "全屏K线", backgroundColor: UIColor.systemIndigo)
        fullscreenButton.addTarget(self, action: #selector(fullscreenButtonTapped), for: .touchUpInside)
        
        // 状态标签
        statusLabel = UILabel()
        statusLabel.text = "数据点数: 0"
        statusLabel.textAlignment = .center
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.backgroundColor = UIColor.systemGray6
        statusLabel.layer.cornerRadius = 8
        statusLabel.layer.masksToBounds = true
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建堆栈视图
        controlStackView = UIStackView(arrangedSubviews: [
            symbolSegmentedControl,
            timeframeSegmentedControl,
            mainStateSegmentedControl,
            secondaryStateStackView,
            createSecondaryHeightStackView(),
            isLineButton,
            startStopButton,
            resetButton,
            fullscreenButton,
            configButton
        ])
        controlStackView.axis = .vertical
        controlStackView.spacing = 12
        controlStackView.distribution = .fill
        controlStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 将状态标签添加到内容视图的顶部
        contentView.addSubview(statusLabel)
        contentView.addSubview(controlStackView)
    }
    
    private func createStyledButton(title: String, backgroundColor: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = backgroundColor
        button.setTitleColor(UIColor.white, for: .normal)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置按钮高度约束（使用优先级避免冲突）
        let heightConstraint = button.heightAnchor.constraint(equalToConstant: 50)
        heightConstraint.priority = UILayoutPriority(999)
        heightConstraint.isActive = true
        
        // 添加阴影效果
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.1
        button.layer.shadowRadius = 4
        
        return button
    }
    
    private func setupSecondaryStateButtons() {
        // 创建副图状态按钮
        let buttonTitles = ["MACD", "KDJ", "RSI", "WR", "VOL"]
        let buttonStates: [SecondaryState] = [
            .macd(defaultMACD.0, defaultMACD.1, defaultMACD.2),
            .kdj(defaultKDJ.0, defaultKDJ.1, defaultKDJ.2),
            .rsi(defaultRSI),
            .wr(defaultWR),
            .vol(defaultVOL.0, defaultVOL.1)
        ]
        
        secondaryStateButtons = []
        for (index, title) in buttonTitles.enumerated() {
            let button = createSecondaryStateButton(title: title, state: buttonStates[index], index: index)
            secondaryStateButtons.append(button)
        }
        
        // 创建副图状态堆栈视图
        secondaryStateStackView = UIStackView(arrangedSubviews: secondaryStateButtons)
        secondaryStateStackView.axis = .horizontal
        secondaryStateStackView.spacing = 8
        secondaryStateStackView.distribution = .fillEqually
        secondaryStateStackView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func createSecondaryStateButton(title: String, state: SecondaryState, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = UIColor.systemGray5
        button.setTitleColor(UIColor.label, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置按钮高度
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        // 添加点击事件
        button.addTarget(self, action: #selector(secondaryStateButtonTapped(_:)), for: .touchUpInside)
        
        // 存储状态信息（使用传入的索引）
        button.tag = index
        
        return button
    }
    
    @objc private func secondaryStateButtonTapped(_ sender: UIButton) {
        // 切换按钮选中状态
        sender.isSelected.toggle()
        
        // 更新按钮外观
        if sender.isSelected {
            sender.backgroundColor = UIColor.systemBlue
            sender.setTitleColor(UIColor.white, for: .normal)
        } else {
            sender.backgroundColor = UIColor.systemGray5
            sender.setTitleColor(UIColor.label, for: .normal)
        }
        
        // 更新副图状态
        updateSecondaryStates()
    }
    
    private func updateSecondaryStates() {
        var secondaryStates: [SecondaryState] = []
        let buttonStates: [SecondaryState] = [
            .macd(defaultMACD.0, defaultMACD.1, defaultMACD.2),
            .kdj(defaultKDJ.0, defaultKDJ.1, defaultKDJ.2),
            .rsi(defaultRSI),
            .wr(defaultWR),
            .vol(defaultVOL.0, defaultVOL.1)
        ]
        
        for button in secondaryStateButtons {
            if button.isSelected {
                let index = button.tag
                if index < buttonStates.count {
                    secondaryStates.append(buttonStates[index])
                }
            }
        }
        
        kLineChartView.secondaryStates = secondaryStates
        
        // 副图状态改变时，更新图表布局
        updateChartFrame()
    }
    
    private func setupSecondaryHeightControl() {
        // 创建副图高度标签
        secondaryHeightLabel = UILabel()
        secondaryHeightLabel.text = "单个副图固定高度: 15%"
        secondaryHeightLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        secondaryHeightLabel.textAlignment = .center
        secondaryHeightLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建副图高度滑块
        secondaryHeightSlider = UISlider()
        secondaryHeightSlider.minimumValue = 0.05  // 5%
        secondaryHeightSlider.maximumValue = 0.3   // 30%
        secondaryHeightSlider.value = 0.15         // 默认15%
        secondaryHeightSlider.translatesAutoresizingMaskIntoConstraints = false
        secondaryHeightSlider.addTarget(self, action: #selector(secondaryHeightChanged), for: .valueChanged)
    }
    
    private func createSecondaryHeightStackView() -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: [secondaryHeightLabel, secondaryHeightSlider])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }
    
    @objc private func secondaryHeightChanged() {
        let ratio = Double(secondaryHeightSlider.value)
        kLineChartView.chartConfiguration.chartStyleConfig.singleSecondaryMaxHeightRatio = ratio
        
        // 更新标签显示
        let percentage = Int(ratio * 100)
        secondaryHeightLabel.text = "单个副图固定高度: \(percentage)%"
        
        // 更新图表布局
        updateChartFrame()
    }
    
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 滚动视图约束
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 内容视图约束
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // 状态标签约束（放在顶部）
            statusLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            statusLabel.heightAnchor.constraint(equalToConstant: 40),
            
            // K线图约束（置于状态标签下方）
            kLineChartView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            kLineChartView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            kLineChartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            kLineChartView.heightAnchor.constraint(equalToConstant: 400),

            // 均价折线图约束（演示）
            averageLineChartView.topAnchor.constraint(equalTo: kLineChartView.bottomAnchor, constant: 16),
            averageLineChartView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            averageLineChartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            averageLineChartView.heightAnchor.constraint(equalToConstant: 220),
            
            // 控制面板约束（放在均价折线图之后）
            controlStackView.topAnchor.constraint(equalTo: averageLineChartView.bottomAnchor, constant: 20),
            controlStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            controlStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            controlStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
    }
    
    
    private func updateChartFrame() {
        // 确保图表在布局更新后重新绘制
        kLineChartView.setNeedsDisplay()
    }
    
    // MARK: - 数据设置
    private func setupData() {
        // 显示loading view
        showLoadingView()
        
        // 在后台线程异步加载数据
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.loadInitialData()
        }
    }
    
    private func loadInitialData() {
        // 检查网络连接
        guard isNetworkAvailable() else {
            DispatchQueue.main.async { [weak self] in
                self?.statusLabel.text = "网络连接不可用，使用模拟数据"
                self?.showLoadingView(message: "正在生成模拟数据...")
            }
            loadMockDataAsync()
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.text = "正在加载数据..."
        }
        
        okxDataManager.fetchKlineData(symbol: currentSymbol, timeframe: currentTimeframe, limit: 100) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self?.kLineData = data
                    if let self = self {
                        // 在后台线程计算技术指标
                        DispatchQueue.global(qos: .userInitiated).async {
                            DataUtil.calculate(self.kLineData, main: self.kLineChartView.mainState, seconds: self.kLineChartView.secondaryStates)
                            
                            // 回到主线程更新UI
                            DispatchQueue.main.async {
                                self.kLineChartView.updateData(self.kLineData)
                                // 使用收盘价刷新均价折线图
                                self.averageLineChartView.values = self.kLineData.map { $0.close }
                                self.updateStatusLabel()
                                self.hideLoadingView()
                            }
                        }
                    }
                    
                    // 添加调试信息
                    if let first = data.first, let last = data.last {
                        print("初始数据加载完成: 总数=\(data.count), 最早=\(first.timestamp), 最新=\(last.timestamp)")
                    }
                case .failure(let error):
                    print("加载数据失败: \(error.localizedDescription)")
                    self?.statusLabel.text = "网络请求失败，使用模拟数据"
                    self?.showLoadingView(message: "正在生成模拟数据...")
                    self?.loadMockDataAsync()
                }
            }
        }
    }
    
    private func isNetworkAvailable() -> Bool {
        // 简单的网络检查
        guard let url = URL(string: "https://www.okx.com") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5.0
        
        var isReachable = false
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.dataTask(with: request) { _, response, _ in
            isReachable = (response as? HTTPURLResponse)?.statusCode == 200
            semaphore.signal()
        }.resume()
        
        _ = semaphore.wait(timeout: .now() + 5.0)
        return isReachable
    }
    
    private func loadMockData() {
        // 使用模拟数据
        let mockGenerator = MockDataGenerator()
        kLineData = mockGenerator.generateInitialData(count: 100)
        kLineChartView.updateData(kLineData)
        updateStatusLabel()
        statusLabel.text = "使用模拟数据 (网络不可用)"
    }
    
    private func loadMockDataAsync() {
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.text = "正在生成模拟数据..."
        }
        
        // 在后台线程生成模拟数据
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let mockGenerator = MockDataGenerator()
            let data = mockGenerator.generateInitialData(count: 100)
            
            // 回到主线程更新UI
            DispatchQueue.main.async {
                self.kLineData = data
                self.kLineChartView.updateData(self.kLineData)
                self.averageLineChartView.values = self.kLineData.map { $0.close }
                self.updateStatusLabel()
                self.statusLabel.text = "使用模拟数据 (网络不可用)"
                self.hideLoadingView()
            }
        }
    }
    
    
    private func updateStatusLabel() {
        let count = kLineData.count
        let price = kLineData.last?.close ?? 0.0
        statusLabel.text = String(format: "数据点数: %d | 当前价格: %.2f | %@", count, price, currentSymbol)
        updatePeriodChanges()
    }

    // 计算并更新区间涨跌
    private func updatePeriodChanges() {
        let chartConfiguration = kLineChartView.chartConfiguration
        guard !kLineData.isEmpty else { return }
        let periods = [0,7,30,90,180,365]
        let latest = kLineData.last!
        for (idx, days) in periods.enumerated() {
            guard idx < percentageLabels.count else { continue }
            let label = percentageLabels[idx]
            if days == 0 {
                // 相对昨日（或上一根）
                let ref = kLineData.dropLast().last?.close ?? latest.close
                let pct = ref == 0 ? 0 : (latest.close - ref) / ref * 100
                label.text = String(format: "%@%.2f%%", pct >= 0 ? "+" : "", pct)
                label.textColor = pct >= 0 ? chartConfiguration.candleStyle.upColor : chartConfiguration.candleStyle.downColor
                continue
            }
            // 找到days天前最接近的数据（简单用索引回溯）
            let lookback = max(0, kLineData.count - 1 - days)
            let ref = kLineData[lookback].close
            let pct = ref == 0 ? 0 : (latest.close - ref) / ref * 100
            label.text = String(format: "%@%.2f%%", pct >= 0 ? "+" : "", pct)
            label.textColor = pct >= 0 ? chartConfiguration.candleStyle.upColor : chartConfiguration.candleStyle.downColor
        }
    }
    
    // MARK: - 动作设置
    private func setupActions() {
        symbolSegmentedControl.addTarget(self, action: #selector(symbolChanged), for: .valueChanged)
        timeframeSegmentedControl.addTarget(self, action: #selector(timeframeChanged), for: .valueChanged)
        mainStateSegmentedControl.addTarget(self, action: #selector(mainStateChanged), for: .valueChanged)
        isLineButton.addTarget(self, action: #selector(toggleLineChart), for: .touchUpInside)
        startStopButton.addTarget(self, action: #selector(toggleRealTimeUpdate), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(resetData), for: .touchUpInside)
    }
    
    // MARK: - 动作处理
    @objc private func symbolChanged() {
        let symbols = ["BTC-USDT", "ETH-USDT", "BNB-USDT"]
        currentSymbol = symbols[symbolSegmentedControl.selectedSegmentIndex]
        stopRealTimeUpdate()
        loadInitialData()
    }
    
    @objc private func timeframeChanged() {
        let timeframes = ["1m", "5m", "15m", "1h", "4h", "1d"]
        currentTimeframe = timeframes[timeframeSegmentedControl.selectedSegmentIndex]
        stopRealTimeUpdate()
        loadInitialData()
    }
    
    @objc private func mainStateChanged() {
        switch mainStateSegmentedControl.selectedSegmentIndex {
        case 0:
            kLineChartView.mainState = .none
        case 1:
            kLineChartView.mainState = .ma(defaultMA.0, defaultMA.1, defaultMA.2)
        case 2:
            kLineChartView.mainState = .ema(defaultEMA.0, defaultEMA.1, defaultEMA.2)
        case 3:
            kLineChartView.mainState = .boll(defaultBOLL.0, defaultBOLL.1)
        default:
            kLineChartView.mainState = .none
        }
        // 主图切换后立即重算并刷新，保证 EMA 等即时可见
        DataUtil.calculate(self.kLineData, main: self.kLineChartView.mainState, seconds: self.kLineChartView.secondaryStates)
        kLineChartView.updateData(self.kLineData)
    }
    
    
    @objc private func toggleLineChart() {
        kLineChartView.isLine.toggle()
        isLineButton.setTitle(kLineChartView.isLine ? "切换为蜡烛图" : "切换为线图", for: .normal)
    }
    
    @objc private func toggleRealTimeUpdate() {
        if isRealTimeUpdating {
            stopRealTimeUpdate()
        } else {
            startRealTimeUpdate()
        }
    }
    
    @objc private func resetData() {
        stopRealTimeUpdate()
        loadInitialData()
    }
    
    // MARK: - 实时更新
    private func startRealTimeUpdate() {
        isRealTimeUpdating = true
        startStopButton.setTitle("停止实时更新", for: .normal)
        startStopButton.backgroundColor = UIColor.systemRed
        
        // 每2秒更新一次数据
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.addNewData()
            }
        }
    }
    
    private func stopRealTimeUpdate() {
        isRealTimeUpdating = false
        startStopButton.setTitle("开始实时更新", for: .normal)
        startStopButton.backgroundColor = UIColor.systemGreen
        timer?.invalidate()
        timer = nil
    }
    
    private func addNewData() {
        // 检查网络连接
        guard isNetworkAvailable() else {
            print("网络不可用，停止实时更新")
            stopRealTimeUpdate()
            statusLabel.text = "网络不可用，已停止实时更新"
            return
        }
        
        // 获取最新的K线数据
        okxDataManager.fetchKlineData(symbol: currentSymbol, timeframe: currentTimeframe, limit: 1) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let newData):
                    if let newEntity = newData.first {
                        guard let self = self else { return }
                        
                        // 检查是否是新数据（时间戳不同）
                        if let lastEntity = self.kLineData.last, lastEntity.timestamp != newEntity.timestamp {
                            // 新数据应该追加到数组末尾（时间序列的后面）
                            self.kLineData.append(newEntity)
                            
                            // 保持最多200个数据点，移除最旧的数据
                            if self.kLineData.count > 200 {
                                self.kLineData.removeFirst()
                            }
                            
                            // 重新计算技术指标（参数化）
                            DataUtil.calculate(self.kLineData, main: self.kLineChartView.mainState, seconds: self.kLineChartView.secondaryStates)
                            
                            // 使用智能更新方法：K线图内部会自动判断用户交互状态
                            self.kLineChartView.updateData(self.kLineData)
                            self.averageLineChartView.values = self.kLineData.map { $0.close }
                            self.updateStatusLabel()
                            
                            print("新增数据: 时间戳=\(newEntity.timestamp), 价格=\(newEntity.close), 数据总数=\(self.kLineData.count)")
                        } else {
                            // 如果是相同时间戳的数据，更新最后一条数据
                            if let lastIndex = self.kLineData.indices.last {
                                self.kLineData[lastIndex] = newEntity
                                
                                // 重新计算技术指标（参数化）
                                DataUtil.calculate(self.kLineData, main: self.kLineChartView.mainState, seconds: self.kLineChartView.secondaryStates)
                                
                                // 使用智能更新方法：K线图内部会自动判断用户交互状态
                                self.kLineChartView.updateData(self.kLineData)
                                self.averageLineChartView.values = self.kLineData.map { $0.close }
                                self.updateStatusLabel()
                                
                                print("更新数据: 时间戳=\(newEntity.timestamp), 价格=\(newEntity.close)")
                            }
                        }
                    }
                case .failure(let error):
                    print("获取新数据失败: \(error.localizedDescription)")
                    // 网络错误时停止实时更新
                    self?.stopRealTimeUpdate()
                    self?.statusLabel.text = "网络错误，已停止实时更新"
                }
            }
        }
    }
    
    // MARK: - 配置按钮事件
    @objc private func configButtonTapped() {
        let configVC = ChartConfigurationViewController()
        
        // 设置配置更改回调
        configVC.onConfigurationChanged = { [weak self] newConfig in
            self?.kLineChartView.chartConfiguration = newConfig
        }
        
        let navController = UINavigationController(rootViewController: configVC)
        present(navController, animated: true)
    }

    // MARK: - 全屏按钮
    @objc private func fullscreenButtonTapped() {
        let vc = FullScreenChartViewController()
        let chartConfiguration = kLineChartView.chartConfiguration
        vc.modalPresentationStyle = .fullScreen
        // 传递当前图表状态与数据
        vc.initialData = self.kLineData
        vc.initialMainState = self.kLineChartView.mainState
        vc.initialSecondaryStates = self.kLineChartView.secondaryStates
        vc.initialIsLine = self.kLineChartView.isLine
        vc.initialChartColors = self.kLineChartView.chartColors
        vc.initialChartConfiguration = self.kLineChartView.chartConfiguration
        present(vc, animated: true)
    }
    
    // MARK: - 返回按钮事件
    @objc private func backButtonTapped() {
        // 停止实时更新
        stopRealTimeUpdate()
        
        // 返回上一页
        if let navigationController = navigationController {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}
