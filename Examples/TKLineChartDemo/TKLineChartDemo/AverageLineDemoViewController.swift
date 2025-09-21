import UIKit
import TKLineChart

class AverageLineDemoViewController: UIViewController {
    private var chartView: AverageLineChartView!
    private var segmented: UISegmentedControl!
    private var allData: [[Double]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "均价折线图演示"

        chartView = AverageLineChartView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chartView)

        segmented = UISegmentedControl(items: ["1日", "7日", "30日"]) // 仅 Demo 使用
        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(changeRange), for: .valueChanged)
        segmented.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmented)

        NSLayoutConstraint.activate([
            chartView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            chartView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            chartView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            chartView.heightAnchor.constraint(equalToConstant: 320),

            segmented.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 16),
            segmented.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        // 生成三组模拟数据
        allData = [mock(96), mock(96*7), mock(96*30)]
        chartView.values = allData[0]
    }

    @objc private func changeRange() {
        chartView.values = allData[segmented.selectedSegmentIndex]
    }

    private func mock(_ n: Int) -> [Double] {
        var v: [Double] = []
        var base = 116000.0
        for _ in 0..<n {
            base += Double.random(in: -120...120)
            v.append(base)
        }
        return v
    }
}


