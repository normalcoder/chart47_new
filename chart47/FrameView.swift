import UIKit

protocol FrameDelegate: class {
    func changeFrame(offset: CGFloat, width: CGFloat)
}

let minWidth: CGFloat = 30
let borderHeight: CGFloat = 1

class FrameView: UIView, MiddleViewDelegate, FrameProvider {
    let scrollView: UIScrollView
    weak var delegate: FrameDelegate?
    
    var offsetRatio: CGFloat = 0.75
    var widthRatio: CGFloat = 0.25
    
    let shadowColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.3)

    init(scrollView: UIScrollView) {
        self.scrollView = scrollView
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var leftShadow: UIView = {
        let v = UIView()
        v.backgroundColor = shadowColor
        addSubview(v)
        return v
    }()
    
    lazy var rightShadow: UIView = {
        let v = UIView()
        v.backgroundColor = shadowColor
        insertSubview(v, at: 0)
        return v
    }()
    
    lazy var middleView: MiddleView = {
        let v = MiddleView(scrollView: scrollView)
        v.delegate = self
        addSubview(v)
        return v
    }()

    override func layoutSubviews() {
        super.layoutSubviews()
        
        let w = bounds.width
        let h = bounds.height
        
        let a = w*offsetRatio
        let b = a + w*widthRatio

        let shadowInset: CGFloat = 10
        
        leftShadow.frame = CGRect(x: 0, y: borderHeight, width: a + shadowInset, height: h - 2*borderHeight)
        middleView.frame = CGRect(x: a, y: 0, width: b-a, height: h)
        rightShadow.frame = CGRect(x: b - shadowInset, y: borderHeight, width: w-b + shadowInset, height: h - 2*borderHeight)
    }
    
    func leftCornerMoved(_ dx: CGFloat) {
        let w = bounds.width
        
        if dx > 0 && widthRatio <= minWidth/bounds.width {
            return
        }
        
//        if dx < 0 && abs(middleView.frame.minX - 0) < 0.00001 {
//            return
//        }

        let minX = max(0, middleView.frame.minX + dx)
        let maxX = min(middleView.frame.maxX, w)

        updateFrame(
            offsetRatio: minX / w,
            widthRatio: (maxX - minX) / w
        )
    }
    
    func rightCornerMoved(_ dx: CGFloat) {
        let w = bounds.width
        
        let minX = max(0, middleView.frame.minX)
        let maxX = min(middleView.frame.maxX + dx, w)

        updateFrame(
            offsetRatio: minX / w,
            widthRatio: (maxX - minX) / w
        )
    }
    
    func middleMoved(_ dx: CGFloat) {
        let w = bounds.width
        
        if dx > 0 && abs(middleView.frame.maxX - w) < 0.00001 {
            return
        }
        
        if dx < 0 && abs(middleView.frame.minX - 0) < 0.00001 {
            return
        }
        
        let minX = max(0, middleView.frame.minX + dx)
        let maxX = min(middleView.frame.maxX + dx, w)

        updateFrame(
            offsetRatio: minX / w,
            widthRatio: (maxX - minX) / w
        )
    }
    
    func updateFrame(offsetRatio: CGFloat, widthRatio: CGFloat) {

//        if dx > 0 && abs(widthRatio - minWidth/bounds.width) < 0.00001 {
////            self.offsetRatio = min(max(0, offsetRatio), 1)
//        } else {
//
//        }

        self.offsetRatio = min(max(0, offsetRatio), 1 - minWidth/bounds.width)
        self.widthRatio = min(max(minWidth/bounds.width, widthRatio), 1 - self.offsetRatio)
        

        setNeedsLayout()
        layoutIfNeeded()
        
        delegate?.changeFrame(offset: offsetRatio, width: widthRatio)
    }
    
    func currentFrame() -> Frame {
        return Frame(offset: offsetRatio, length: widthRatio)
    }
}
