import UIKit

let tableHeaderHeight: CGFloat = 55

class TableHeader: UIView {
    lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.text = "FOLLOWERS"
        l.font = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.light)
        addSubview(l)
        return l
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let left: CGFloat = 16
        let bottom: CGFloat = 10

        let r = titleLabel.textRect(forBounds: CGRect(x: 0, y: 0, width: bounds.width - 2*left, height: bounds.height - 2*bottom), limitedToNumberOfLines: 1)
        
        titleLabel.frame = CGRect(x: left, y: tableHeaderHeight - bottom - r.height, width: r.width, height: r.height)
    }
}
