import UIKit

let cornerWidth: CGFloat = 20

protocol MiddleViewDelegate: class {
    func leftCornerMoved(_ dx: CGFloat)
    func rightCornerMoved(_ dx: CGFloat)
    func middleMoved(_ dx: CGFloat)
}

class MiddleView: UIView {
    let scrollView: UIScrollView
    weak var delegate: MiddleViewDelegate?

    init(scrollView: UIScrollView) {
        self.scrollView = scrollView
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    lazy var leftCorner: CornerView = {
        let v = CornerView(isLeft: true, onMove: { self.delegate?.leftCornerMoved($0) }, scrollView: scrollView)
        addSubview(v)
        return v
    }()
    
    lazy var rightCorner: CornerView = {
        let v = CornerView(isLeft: false, onMove: { self.delegate?.rightCornerMoved($0) }, scrollView: scrollView)
        addSubview(v)
        return v
    }()
    
    lazy var topBorder: UIView = {
        let v = UIView()
        v.backgroundColor = cornerColor
        addSubview(v)
        return v
    }()
    
    lazy var bottomBorder: UIView = {
        let v = UIView()
        v.backgroundColor = cornerColor
        addSubview(v)
        return v
    }()
    

    override func layoutSubviews() {
        super.layoutSubviews()
        
        let w = bounds.width
        let h = bounds.height
        
        topBorder.frame = CGRect(x: cornerWidth, y: 0, width: w - 2*cornerWidth, height: borderHeight)
        bottomBorder.frame = CGRect(x: cornerWidth, y: h - borderHeight, width: w - 2*cornerWidth, height: borderHeight)
        leftCorner.frame = CGRect(x: 0, y: 0, width: cornerWidth, height: h)
        rightCorner.frame = CGRect(x: w - cornerWidth, y: 0, width: cornerWidth, height: h)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        setScrollAllowed(false)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.middleMoved(touches.first!.location(in: self).x - touches.first!.previousLocation(in: self).x)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        setScrollAllowed(true)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        setScrollAllowed(true)
    }

    func setScrollAllowed(_ allowed: Bool) {
        scrollView.isScrollEnabled = allowed
    }
}
