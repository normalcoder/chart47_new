import UIKit

struct Frame: Equatable {
    let offset: CGFloat
    let length: CGFloat
}

extension Frame: Linear {
    static func plus(_ x: Frame, _ y: Frame) -> Frame {
        return Frame(offset: x.offset + y.offset, length: x.length + y.length)
    }
    
    static func minus(_ x: Frame, _ y: Frame) -> Frame {
        return Frame(offset: x.offset - y.offset, length: x.length - y.length)
    }
    
    static func mul(_ a: Float, _ x: Frame) -> Frame {
        return Frame(offset: CGFloat(a)*x.offset, length: CGFloat(a)*x.length)
    }
}
