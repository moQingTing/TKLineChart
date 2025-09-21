import UIKit
import TKLineChart

class FullScreenChartViewController: UIViewController {
    // MARK: - 传入参数
    var initialData: [CompleteKLineEntity] = []
    var symbol: String = "BTC-USDT"
    var initialMainState: MainState = .none
    var initialSecondaryStates: [SecondaryState] = []
    var initialIsLine: Bool = false
    var initialChartColors: ChartColors = ChartColors(isDarkMode: false)
    var initialChartConfiguration: ChartConfiguration = ChartConfiguration()

    // MARK: - UI
    private var chartView: TKLineChartView!
    private var headerView: UIStackView!
    private var priceLabel: UILabel!
    private var changeLabel: UILabel!
    private var highLowLabel: UILabel!
    private var volLabel: UILabel!
    private var rightIndicatorStackView: UIStackView!
    private var mainButtons: [UIButton] = []
    private var secondaryButtons: [UIButton] = []
    private var secondaryScrollView: UIScrollView!
    private var secondaryButtonsStack: UIStackView!
    private var closeButton: UIButton!

    // 指标默认参数（与示例页保持一致）
    private let defaultMA = (5, 10, 20)
    private let defaultEMA = (5, 10, 20)
    private let defaultBOLL = (20, 2)
    private let defaultVOL = (5, 10)
    private let defaultMACD = (12, 26, 9)
    private let defaultRSI = 14
    private let defaultWR = 14
    
    // 配置相关
    private var chartConfiguration: ChartConfiguration!

    override var prefersStatusBarHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // 初始化配置
        chartConfiguration = initialChartConfiguration
        
        setupChart()
        setupRightIndicators()
        setupCloseButton()
        applyInitialValues()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        forceLandscape()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        forcePortraitBack()
    }

    // MARK: - 布局
    private func setupChart() {
        // 顶部市场信息栏
        setupHeader()

        chartView = TKLineChartView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.backgroundColor = .white
        chartView.chartConfiguration = initialChartConfiguration
        view.addSubview(chartView)

        NSLayoutConstraint.activate([
            chartView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            chartView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            chartView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
    }

    private func setupHeader() {
        let titleLabel = UILabel()
        titleLabel.text = symbol.replacingOccurrences(of: "-", with: "/")
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label

        priceLabel = UILabel()
        priceLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        priceLabel.textColor = .label

        changeLabel = UILabel()
        changeLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)

        highLowLabel = UILabel()
        highLowLabel.font = UIFont.systemFont(ofSize: 12)
        highLowLabel.textColor = .secondaryLabel

        volLabel = UILabel()
        volLabel.font = UIFont.systemFont(ofSize: 12)
        volLabel.textColor = .secondaryLabel

        let leftCol = UIStackView(arrangedSubviews: [titleLabel, priceLabel, changeLabel])
        leftCol.axis = .horizontal
        leftCol.spacing = 2

        let rightCol = UIStackView(arrangedSubviews: [highLowLabel, volLabel])
        rightCol.axis = .vertical
        rightCol.alignment = .trailing
        rightCol.spacing = 2

        let container = UIStackView(arrangedSubviews: [leftCol, UIView(), rightCol])
        container.axis = .horizontal
        container.alignment = .center
        container.spacing = 8
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        headerView = container

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 100),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60)
        ])
    }

    private func setupRightIndicators() {
        rightIndicatorStackView = UIStackView()
        rightIndicatorStackView.axis = .vertical
        rightIndicatorStackView.alignment = .fill
        rightIndicatorStackView.spacing = 10
        rightIndicatorStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rightIndicatorStackView)

        // 标题：主图
        let mainTitle = makeGroupTitleLabel(text: "主图")
        rightIndicatorStackView.addArrangedSubview(mainTitle)

        let mainKeys = ["MA","EMA","BOLL"]
        for key in mainKeys {
            let btn = makeIndicatorButton(title: key)
            btn.addTarget(self, action: #selector(mainIndicatorTapped(_:)), for: .touchUpInside)
            mainButtons.append(btn)
            rightIndicatorStackView.addArrangedSubview(btn)
        }
        for btn in mainButtons {
            btn.setContentCompressionResistancePriority(.required, for: .vertical)
        }

        // 分隔
        let divider = UIView()
        divider.backgroundColor = UIColor.systemGray4
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        rightIndicatorStackView.addArrangedSubview(divider)

        // 标题：副图
        let secTitle = makeGroupTitleLabel(text: "副图")
        rightIndicatorStackView.addArrangedSubview(secTitle)

        // 副图按钮列表可滚动
        secondaryScrollView = UIScrollView()
        secondaryScrollView.translatesAutoresizingMaskIntoConstraints = false
        secondaryScrollView.showsVerticalScrollIndicator = true
        secondaryScrollView.alwaysBounceVertical = true
        secondaryScrollView.setContentHuggingPriority(.defaultLow, for: .vertical)
        // 更易被压缩，避免把主图按钮挤没
        secondaryScrollView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        rightIndicatorStackView.addArrangedSubview(secondaryScrollView)

        secondaryButtonsStack = UIStackView()
        secondaryButtonsStack.axis = .vertical
        secondaryButtonsStack.alignment = .fill
        secondaryButtonsStack.spacing = 10
        secondaryButtonsStack.translatesAutoresizingMaskIntoConstraints = false
        secondaryScrollView.addSubview(secondaryButtonsStack)

        NSLayoutConstraint.activate([
            secondaryButtonsStack.topAnchor.constraint(equalTo: secondaryScrollView.contentLayoutGuide.topAnchor),
            secondaryButtonsStack.leadingAnchor.constraint(equalTo: secondaryScrollView.contentLayoutGuide.leadingAnchor),
            secondaryButtonsStack.trailingAnchor.constraint(equalTo: secondaryScrollView.contentLayoutGuide.trailingAnchor),
            secondaryButtonsStack.bottomAnchor.constraint(equalTo: secondaryScrollView.contentLayoutGuide.bottomAnchor),
            secondaryButtonsStack.widthAnchor.constraint(equalTo: secondaryScrollView.frameLayoutGuide.widthAnchor)
        ])

        let secKeys = ["VOL","MACD","KDJ","RSI","WR"]
        for key in secKeys {
            let btn = makeIndicatorButton(title: key)
            btn.addTarget(self, action: #selector(secondaryIndicatorTapped(_:)), for: .touchUpInside)
            secondaryButtons.append(btn)
            secondaryButtonsStack.addArrangedSubview(btn)
        }

        NSLayoutConstraint.activate([
            rightIndicatorStackView.topAnchor.constraint(equalTo: chartView.topAnchor),
            rightIndicatorStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            rightIndicatorStackView.bottomAnchor.constraint(lessThanOrEqualTo: chartView.bottomAnchor)
        ])

        // 让图表占据除右栏外的宽度
        chartView.trailingAnchor.constraint(equalTo: rightIndicatorStackView.leadingAnchor, constant: -10).isActive = true

        // 右栏限制最大高度等于图表，内部副图列表滚动
        rightIndicatorStackView.heightAnchor.constraint(lessThanOrEqualTo: chartView.heightAnchor).isActive = true
        // 固定右侧栏宽度，避免被压缩为 0
        rightIndicatorStackView.widthAnchor.constraint(equalToConstant: 96).isActive = true
        // 滚动区高度更灵活：至少 120，高度不超过图表
        secondaryScrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
        secondaryScrollView.heightAnchor.constraint(lessThanOrEqualTo: chartView.heightAnchor).isActive = true
    }

    private func setupCloseButton() {
        closeButton = UIButton(type: .system)
        closeButton.setTitle("关闭", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = 14
        closeButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
    }

    private func applyInitialValues() {
        chartView.chartColors = initialChartColors
        chartView.chartConfiguration = initialChartConfiguration
        chartView.isLine = initialIsLine
        chartView.mainState = initialMainState
        chartView.secondaryStates = initialSecondaryStates
        chartView.updateData(initialData)

        // 根据初始状态高亮
        updateMainButtonsSelection()
        updateSecondaryButtonsSelection()

        // 刷新顶部行情
        updateTickerLabels()
    }

    // MARK: - 事件
    @objc private func mainIndicatorTapped(_ sender: UIButton) {
        guard let key = sender.title(for: .normal) else { return }
        // 单选：取消其他主图按钮
        for btn in mainButtons { setButton(btn, selected: btn == sender) }

        if key == "MA" { chartView.mainState = .ma(defaultMA.0, defaultMA.1, defaultMA.2) }
        if key == "EMA" { chartView.mainState = .ema(defaultEMA.0, defaultEMA.1, defaultEMA.2) }
        if key == "BOLL" { chartView.mainState = .boll(defaultBOLL.0, defaultBOLL.1) }

        DataUtil.calculate(self.initialData, main: self.chartView.mainState, seconds: self.chartView.secondaryStates)
        chartView.updateData(initialData)
        updateTickerLabels()
    }

    @objc private func secondaryIndicatorTapped(_ sender: UIButton) {
        guard let key = sender.title(for: .normal) else { return }
        var set = Set<SecondaryState>(chartView.secondaryStates)
        if key == "VOL" { toggle(&set, .vol(defaultVOL.0, defaultVOL.1)) }
        if key == "MACD" { toggle(&set, .macd(defaultMACD.0, defaultMACD.1, defaultMACD.2)) }
        if key == "KDJ" { toggle(&set, .kdj(9, 3, 3)) }
        if key == "RSI" { toggle(&set, .rsi(defaultRSI)) }
        if key == "WR" { toggle(&set, .wr(defaultWR)) }
        chartView.secondaryStates = Array(set)

        // 高亮多选按钮
        updateSecondaryButtonsSelection()

        DataUtil.calculate(self.initialData, main: self.chartView.mainState, seconds: self.chartView.secondaryStates)
        chartView.updateData(initialData)
        updateTickerLabels()
    }

    private func toggle(_ set: inout Set<SecondaryState>, _ item: SecondaryState) {
        if set.contains(item) { set.remove(item) } else { set.insert(item) }
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }

    // MARK: - 方向控制（进入横屏，退出还原）
    private func forceLandscape() {
        let value = UIInterfaceOrientation.landscapeRight.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }

    private func forcePortraitBack() {
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeRight
    }

    // MARK: - 辅助（按钮样式与组标题）
    private func makeIndicatorButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.5)
        btn.layer.cornerRadius = 8
        btn.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        return btn
    }

    private func setButton(_ button: UIButton, selected: Bool) {
        if selected {
            button.backgroundColor = UIColor.systemBlue
            button.setTitleColor(.white, for: .normal)
        } else {
            button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.5)
            button.setTitleColor(.white, for: .normal)
        }
    }

    private func makeGroupTitleLabel(text: String) -> UILabel {
        let lb = UILabel()
        lb.text = text
        lb.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        lb.textColor = UIColor.secondaryLabel
        return lb
    }

    private func updateMainButtonsSelection() {
        for btn in mainButtons {
            let key = btn.title(for: .normal)
            var selected = false
            switch initialMainState {
            case .ma:
                selected = (key == "MA")
            case .ema:
                selected = (key == "EMA")
            case .boll:
                selected = (key == "BOLL")
            default:
                selected = false
            }
            setButton(btn, selected: selected)
        }
    }

    private func updateSecondaryButtonsSelection() {
        for btn in secondaryButtons {
            guard let key = btn.title(for: .normal) else { continue }
            var isOn = false
            switch key {
            case "VOL":
                isOn = chartView.secondaryStates.contains(.vol(defaultVOL.0, defaultVOL.1))
            case "MACD":
                isOn = chartView.secondaryStates.contains(.macd(defaultMACD.0, defaultMACD.1, defaultMACD.2))
            case "KDJ":
                isOn = chartView.secondaryStates.contains(.kdj(9, 3, 3))
            case "RSI":
                isOn = chartView.secondaryStates.contains(.rsi(defaultRSI))
            case "WR":
                isOn = chartView.secondaryStates.contains(.wr(defaultWR))
            default:
                isOn = false
            }
            setButton(btn, selected: isOn)
        }
    }

    // 依据已有或伪造数据刷新行情顶栏
    private func updateTickerLabels() {
        // 取最后一根收盘价
        let last = initialData.last?.close ?? 117177.12
        let open24h = initialData.dropLast().last?.close ?? (last * 0.985)
        let high = initialData.map { $0.high }.max() ?? max(last, open24h)
        let low = initialData.map { $0.low }.min() ?? min(last, open24h)
        let vol = initialData.map { $0.volume }.reduce(0, +)

        priceLabel.text = String(format: "%.2f", last)
        let change = open24h == 0 ? 0 : (last - open24h) / open24h * 100
        changeLabel.text = String(format: "%@%.2f%%", change >= 0 ? "+" : "", change)
        changeLabel.textColor = change >= 0 ? chartConfiguration.candleStyle.upColor : chartConfiguration.candleStyle.downColor
        highLowLabel.text = String(format: "24h 高: %.2f  低: %.2f", high, low)
        volLabel.text = String(format: "24h 量: %.2f", vol)
    }
}


