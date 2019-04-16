import UIKit

let chartHeight: CGFloat = 305
let spaceHeight: CGFloat = 42
let miniHeight: CGFloat = 35
let chartCellHeight = chartHeight + spaceHeight + miniHeight

class ChartCell: UITableViewCell, FrameDelegate {
    let scrollView: UIScrollView
    
    var selectedDayIndex: Int?
    let chart: ChartRef
    let mini: ChartRef

    init(_ i: Int, scrollView: UIScrollView) {
        self.scrollView = scrollView
        let chart = loadChart(i)
        let mini = loadChart(i) // todo: copy
        self.chart = ChartRef(value: chart)
        self.mini = ChartRef(value: mini)
        
        super.init(style: .default, reuseIdentifier: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var chartView: MetalBezierView = {
        let v = MetalBezierView(chart: chart, frameProvider: frameView)
        v.configureWithDevice(MTLCreateSystemDefaultDevice()!)
        contentView.addSubview(v)
        return v
    }()
    
    lazy var miniView: MetalBezierView = {
        let v = MetalBezierView(chart: mini, frameProvider: frameView)
        v.configureWithDevice(MTLCreateSystemDefaultDevice()!)
        contentView.insertSubview(v, at: 0)
        return v
    }()
    
    lazy var frameView: FrameView = {
        let v = FrameView(scrollView: scrollView)
        v.delegate = self
        contentView.addSubview(v)
        return v
    }()

    lazy var zoomButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("zoom", for: .normal)
        b.addTarget(self, action: #selector(zoomTapped), for: .touchUpInside)
        contentView.addSubview(b)
        return b
    }()

    func redraw() {
        layoutIfNeeded()
        chartView.draw()
        miniView.draw()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let w = contentView.bounds.width
        let miniOffset: CGFloat = 10
        

        chartView.frame = CGRect(x: 0, y: 0, width: w, height: chartHeight)
        miniView.frame = CGRect(x: miniOffset, y: chartHeight + spaceHeight, width: w - 2*miniOffset, height: miniHeight)
        frameView.frame = CGRect(x: miniView.frame.origin.x, y: miniView.frame.origin.y - borderHeight, width: miniView.frame.width, height: miniView.frame.height + 2*borderHeight)
        zoomButton.frame = CGRect(x: w - 100, y: 0, width: 100, height: 50)
        
        changeFrame(offset: frameView.currentFrame().offset, width: frameView.currentFrame().length)
    }
    
    var zoomed = false
    
    @objc func zoomTapped() {
//        chartView.change()
        zoomed = !zoomed
        if zoomed {
            let f = frameView.currentFrame()
            
            selectedDayIndex = Int(max(0, (f.offset + f.length/2)*365 - 1))
            zoomIn()
        } else {
            zoomOut()
        }
    }

    //        srcOffset
    //        srcWidth
    //        dstOffset
    //        dstWidth
    //        chartView
    func zoomIn() {
        guard let dayIndex = selectedDayIndex else { return }
        
        let chartParams = chart.value.setDetailedAndPretendBrief(dayIndex..<dayIndex+1, currentFrame: frameView.currentFrame())
        let miniParams = mini.value.setDetailedAndPretendBrief(dayIndex-3..<dayIndex+4, currentFrame: Frame(offset: 0, length: 1))
        
        run(views: [(chartView, chartParams), (miniView, miniParams)]) {
            self.chart.value.setBrief()
            self.chart.value.setDetailed(dayIndex-3..<dayIndex+4)
        }
    }
    
    func zoomOut() {
        let chartParams = chart.value.animationParamsToReturnToBrief(frameToReturn: frameView.currentFrame())
        let miniParams = mini.value.animationParamsToReturnToBrief(frameToReturn: Frame(offset: 0, length: 1))
        run(views: [(chartView, chartParams), (miniView, miniParams)]) {
            self.chart.value.setBrief()
            self.mini.value.setBrief()
        }
    }
    
//    func zoomIn() {
//        guard let dayIndex = selectedDayIndex else { return }
//        chart.value.setDetailed(dayIndex..<dayIndex+1)
//        mini.value.setDetailed(dayIndex-3..<dayIndex+4)
////        chart.value.setBrief()
////        mini.value.setBrief()
//    }
//
//    func zoomOut() {
//        chart.value.setBrief()
//        mini.value.setBrief()
//    }

    func changeFrame(offset: CGFloat, width: CGFloat) {
        chartView.changeFrame(offset: offset, width: width)
    }
    
}

let animationDuration: TimeInterval = 0.5
let timingFunction: (Double) -> Double = { (t: Double) -> Double in
    return t < 0.5 ? 4*t*t*t : (t-1)*(2*t-2)*(2*t-2)+1
}

func run(views: [(MetalBezierView, Animation<Animated>.Params)], completion: @escaping () -> Void) {
    let startTime = CACurrentMediaTime()
    let endTime = startTime + animationDuration
    
    zip(views, [{ print("run compl"); completion() }] + Array(repeating: {}, count: 10)).forEach {
        let ((v, p), c) = $0
        v.animate(Animation(params: p, startTime: startTime, endTime: endTime, timingFunction: timingFunction, completion: c))
    }
}

//func zoomIn(dayIndex: DayIndex) {
//    setDetailedAndPretendBrief(chart, dayIndex..<dayIndex+1)
//    setDetailedAndPretendBrief(mini, dayIndex-3..<dayIndex+4)
//    animateToDetailed()
//}
//
//func zoomOut() {
//    animateToNotDetailed {
//        setNotDetailed(chart, from: dayIndex, to: dayIndex)
//        setNotDetailed(mini, from: dayIndex-3, to: dayIndex+3)
//    }
//}
//
//func animateToDetailed() {
//    stopPretendingAnimation: stepPoint: src -> dst
//    zoomInChart: stepChart: src -> dst (new offset + width)
//    zoomInMini: stepMini: src -> dst (new offset + width)
//}
//
//func animateToNotDetailed(completion) {
//    startPretendingAnimation: stepPoint: src -> dst
//    zoomOutChart: stepChart: src -> dst (old offset + width)
//    zoomOutMini: stepMini: src -> dst (old offset + width)
//
//    onFinish { completion() }
//}
