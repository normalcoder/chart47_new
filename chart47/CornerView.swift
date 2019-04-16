import UIKit

let cornerColor = UIColor.lightGray.withAlphaComponent(0.7)

class CornerView: UIView {
    let isLeft: Bool
    let onMove: (CGFloat) -> Void
    let scrollView: UIScrollView

    init(isLeft: Bool, onMove: @escaping (CGFloat) -> Void, scrollView: UIScrollView) {
        self.isLeft = isLeft
        self.onMove = onMove
        self.scrollView = scrollView
        super.init(frame: .zero)
        backgroundColor = cornerColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        roundCorners(corners: isLeft ? [.topLeft, .bottomLeft] : [.topRight, .bottomRight], radius: 10.0)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        setScrollAllowed(false)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        onMove(touches.first!.location(in: self).x - touches.first!.previousLocation(in: self).x)
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

extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}
