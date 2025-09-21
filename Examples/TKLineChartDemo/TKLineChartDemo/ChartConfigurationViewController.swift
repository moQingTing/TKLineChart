import UIKit
import TKLineChart

/// 图表配置界面
class ChartConfigurationViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let config = ChartConfiguration()
    
    // 配置更改回调
    var onConfigurationChanged: ((ChartConfiguration) -> Void)?
    
    // MARK: - 蜡烛配置控件
    private let candleSectionLabel = UILabel()
    private let solidCandleSwitch = UISwitch()
    private let candleWidthSlider = UISlider()
    private let candleWidthLabel = UILabel()
    private let upColorButton = UIButton()
    private let downColorButton = UIButton()
    
    // MARK: - 移动平均线配置控件
    private let maSectionLabel = UILabel()
    private let ma5ColorButton = UIButton()
    private let ma10ColorButton = UIButton()
    private let ma20ColorButton = UIButton()
    private let ma30ColorButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        loadCurrentConfiguration()
    }
    
    private func setupUI() {
        title = "图表配置"
        view.backgroundColor = .systemBackground
        
        // 设置导航栏
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveTapped)
        )
        
        // 设置滚动视图
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        setupCandleSection()
        setupMASection()
    }
    
    private func setupCandleSection() {
        // 蜡烛配置标题
        candleSectionLabel.text = "蜡烛配置"
        candleSectionLabel.font = UIFont.boldSystemFont(ofSize: 18)
        candleSectionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(candleSectionLabel)
        
        // 实心蜡烛开关
        let solidCandleLabel = UILabel()
        solidCandleLabel.text = "实心蜡烛"
        solidCandleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(solidCandleLabel)
        
        solidCandleSwitch.translatesAutoresizingMaskIntoConstraints = false
        solidCandleSwitch.addTarget(self, action: #selector(solidCandleChanged), for: .valueChanged)
        contentView.addSubview(solidCandleSwitch)
        
        // 蜡烛宽度滑块
        let candleWidthTitleLabel = UILabel()
        candleWidthTitleLabel.text = "蜡烛宽度"
        candleWidthTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(candleWidthTitleLabel)
        
        candleWidthSlider.translatesAutoresizingMaskIntoConstraints = false
        candleWidthSlider.minimumValue = 2.0
        candleWidthSlider.maximumValue = 12.0
        candleWidthSlider.addTarget(self, action: #selector(candleWidthChanged), for: .valueChanged)
        contentView.addSubview(candleWidthSlider)
        
        candleWidthLabel.translatesAutoresizingMaskIntoConstraints = false
        candleWidthLabel.textAlignment = .right
        contentView.addSubview(candleWidthLabel)
        
        // 颜色按钮
        let upColorLabel = UILabel()
        upColorLabel.text = "上涨颜色"
        upColorLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(upColorLabel)
        
        upColorButton.translatesAutoresizingMaskIntoConstraints = false
        upColorButton.layer.cornerRadius = 8
        upColorButton.layer.borderWidth = 1
        upColorButton.layer.borderColor = UIColor.systemGray.cgColor
        upColorButton.addTarget(self, action: #selector(upColorTapped), for: .touchUpInside)
        contentView.addSubview(upColorButton)
        
        let downColorLabel = UILabel()
        downColorLabel.text = "下跌颜色"
        downColorLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(downColorLabel)
        
        downColorButton.translatesAutoresizingMaskIntoConstraints = false
        downColorButton.layer.cornerRadius = 8
        downColorButton.layer.borderWidth = 1
        downColorButton.layer.borderColor = UIColor.systemGray.cgColor
        downColorButton.addTarget(self, action: #selector(downColorTapped), for: .touchUpInside)
        contentView.addSubview(downColorButton)
    }
    
    private func setupMASection() {
        // MA配置标题
        maSectionLabel.text = "移动平均线配置"
        maSectionLabel.font = UIFont.boldSystemFont(ofSize: 18)
        maSectionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(maSectionLabel)
        
        // MA颜色按钮
        let ma5Label = UILabel()
        ma5Label.text = "MA5颜色"
        ma5Label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(ma5Label)
        
        ma5ColorButton.translatesAutoresizingMaskIntoConstraints = false
        ma5ColorButton.layer.cornerRadius = 8
        ma5ColorButton.layer.borderWidth = 1
        ma5ColorButton.layer.borderColor = UIColor.systemGray.cgColor
        ma5ColorButton.addTarget(self, action: #selector(ma5ColorTapped), for: .touchUpInside)
        contentView.addSubview(ma5ColorButton)
        
        let ma10Label = UILabel()
        ma10Label.text = "MA10颜色"
        ma10Label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(ma10Label)
        
        ma10ColorButton.translatesAutoresizingMaskIntoConstraints = false
        ma10ColorButton.layer.cornerRadius = 8
        ma10ColorButton.layer.borderWidth = 1
        ma10ColorButton.layer.borderColor = UIColor.systemGray.cgColor
        ma10ColorButton.addTarget(self, action: #selector(ma10ColorTapped), for: .touchUpInside)
        contentView.addSubview(ma10ColorButton)
        
        let ma20Label = UILabel()
        ma20Label.text = "MA20颜色"
        ma20Label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(ma20Label)
        
        ma20ColorButton.translatesAutoresizingMaskIntoConstraints = false
        ma20ColorButton.layer.cornerRadius = 8
        ma20ColorButton.layer.borderWidth = 1
        ma20ColorButton.layer.borderColor = UIColor.systemGray.cgColor
        ma20ColorButton.addTarget(self, action: #selector(ma20ColorTapped), for: .touchUpInside)
        contentView.addSubview(ma20ColorButton)
        
        let ma30Label = UILabel()
        ma30Label.text = "MA30颜色"
        ma30Label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(ma30Label)
        
        ma30ColorButton.translatesAutoresizingMaskIntoConstraints = false
        ma30ColorButton.layer.cornerRadius = 8
        ma30ColorButton.layer.borderWidth = 1
        ma30ColorButton.layer.borderColor = UIColor.systemGray.cgColor
        ma30ColorButton.addTarget(self, action: #selector(ma30ColorTapped), for: .touchUpInside)
        contentView.addSubview(ma30ColorButton)
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
            
            // 蜡烛配置约束
            candleSectionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            candleSectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            candleSectionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // 实心蜡烛开关约束
            solidCandleSwitch.topAnchor.constraint(equalTo: candleSectionLabel.bottomAnchor, constant: 20),
            solidCandleSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // 蜡烛宽度约束
            candleWidthSlider.topAnchor.constraint(equalTo: solidCandleSwitch.bottomAnchor, constant: 20),
            candleWidthSlider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            candleWidthSlider.trailingAnchor.constraint(equalTo: candleWidthLabel.leadingAnchor, constant: -10),
            
            candleWidthLabel.centerYAnchor.constraint(equalTo: candleWidthSlider.centerYAnchor),
            candleWidthLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            candleWidthLabel.widthAnchor.constraint(equalToConstant: 60),
            
            // 颜色按钮约束
            upColorButton.topAnchor.constraint(equalTo: candleWidthSlider.bottomAnchor, constant: 20),
            upColorButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            upColorButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            upColorButton.heightAnchor.constraint(equalToConstant: 44),
            
            downColorButton.topAnchor.constraint(equalTo: upColorButton.bottomAnchor, constant: 10),
            downColorButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            downColorButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            downColorButton.heightAnchor.constraint(equalToConstant: 44),
            
            // MA配置约束
            maSectionLabel.topAnchor.constraint(equalTo: downColorButton.bottomAnchor, constant: 30),
            maSectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            maSectionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            ma5ColorButton.topAnchor.constraint(equalTo: maSectionLabel.bottomAnchor, constant: 20),
            ma5ColorButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            ma5ColorButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            ma5ColorButton.heightAnchor.constraint(equalToConstant: 44),
            
            ma10ColorButton.topAnchor.constraint(equalTo: ma5ColorButton.bottomAnchor, constant: 10),
            ma10ColorButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            ma10ColorButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            ma10ColorButton.heightAnchor.constraint(equalToConstant: 44),
            
            ma20ColorButton.topAnchor.constraint(equalTo: ma10ColorButton.bottomAnchor, constant: 10),
            ma20ColorButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            ma20ColorButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            ma20ColorButton.heightAnchor.constraint(equalToConstant: 44),
            
            ma30ColorButton.topAnchor.constraint(equalTo: ma20ColorButton.bottomAnchor, constant: 10),
            ma30ColorButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            ma30ColorButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            ma30ColorButton.heightAnchor.constraint(equalToConstant: 44),
            
        ])
    }
    
    private func loadCurrentConfiguration() {
        // 加载当前配置
        solidCandleSwitch.isOn = config.candleStyle.isSolid
        candleWidthSlider.value = Float(config.candleStyle.width)
        candleWidthLabel.text = String(format: "%.1f", config.candleStyle.width)
        
        updateColorButtons()
    }
    
    private func updateColorButtons() {
        upColorButton.backgroundColor = config.candleStyle.upColor
        downColorButton.backgroundColor = config.candleStyle.downColor
        ma5ColorButton.backgroundColor = config.movingAverageStyle.ma5Color
        ma10ColorButton.backgroundColor = config.movingAverageStyle.ma10Color
        ma20ColorButton.backgroundColor = config.movingAverageStyle.ma20Color
        ma30ColorButton.backgroundColor = config.movingAverageStyle.ma30Color
    }
    
    
    // MARK: - 事件处理
    @objc private func solidCandleChanged() {
        config.candleStyle.isSolid = solidCandleSwitch.isOn
    }
    
    @objc private func candleWidthChanged() {
        config.candleStyle.width = Double(candleWidthSlider.value)
        candleWidthLabel.text = String(format: "%.1f", config.candleStyle.width)
    }
    
    @objc private func upColorTapped() {
        showColorPicker(for: \.upColor, in: \.candleStyle)
    }
    
    @objc private func downColorTapped() {
        showColorPicker(for: \.downColor, in: \.candleStyle)
    }
    
    @objc private func ma5ColorTapped() {
        showColorPicker(for: \.ma5Color, in: \.movingAverageStyle)
    }
    
    @objc private func ma10ColorTapped() {
        showColorPicker(for: \.ma10Color, in: \.movingAverageStyle)
    }
    
    @objc private func ma20ColorTapped() {
        showColorPicker(for: \.ma20Color, in: \.movingAverageStyle)
    }
    
    @objc private func ma30ColorTapped() {
        showColorPicker(for: \.ma30Color, in: \.movingAverageStyle)
    }
    
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        // 通知配置更改
        onConfigurationChanged?(config)
        dismiss(animated: true)
    }
    
    // MARK: - 颜色选择器
    private func showColorPicker(for keyPath: WritableKeyPath<ChartConfiguration.CandleStyle, UIColor>, in styleKeyPath: WritableKeyPath<ChartConfiguration, ChartConfiguration.CandleStyle>) {
        let colorPicker = UIColorPickerViewController()
        colorPicker.selectedColor = config[keyPath: styleKeyPath][keyPath: keyPath]
        colorPicker.delegate = self
        
        // 保存当前编辑的路径
        currentEditingPath = (styleKeyPath, keyPath)
        
        present(colorPicker, animated: true)
    }
    
    private func showColorPicker(for keyPath: WritableKeyPath<ChartConfiguration.MovingAverageStyle, UIColor>, in styleKeyPath: WritableKeyPath<ChartConfiguration, ChartConfiguration.MovingAverageStyle>) {
        let colorPicker = UIColorPickerViewController()
        colorPicker.selectedColor = config[keyPath: styleKeyPath][keyPath: keyPath]
        colorPicker.delegate = self
        
        // 保存当前编辑的路径
        currentEditingPath = (styleKeyPath, keyPath)
        
        present(colorPicker, animated: true)
    }
    
    private var currentEditingPath: Any?
}

// MARK: - UIColorPickerViewControllerDelegate
extension ChartConfigurationViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        // 这里可以根据需要实时更新颜色
        if !continuously {
            // 只在用户停止选择时更新
            updateColorButtons()
        }
    }
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        // 用户完成颜色选择
        updateColorButtons()
    }
}
