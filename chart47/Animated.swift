import UIKit

struct Animated {
    let pieces: [Piece]?
    let verticalFrame: Frame?
    let frame: Frame?
}

extension Animated: Linear {
    static func plus(_ x: Animated, _ y: Animated) -> Animated {
        let pieces: [Piece]? = {
            guard let x = x.pieces, let y = y.pieces else { return nil }
            return .plus(x, y)
        }()
        let verticalFrame: Frame? = {
            guard let x = x.verticalFrame, let y = y.verticalFrame else { return nil }
            return .plus(x, y)
        }()
        let frame: Frame? = {
            guard let x = x.frame, let y = y.frame else { return nil }
            return .plus(x, y)
        }()
        return Animated(pieces: pieces, verticalFrame: verticalFrame, frame: frame)
    }
    
    static func minus(_ x: Animated, _ y: Animated) -> Animated {
        let pieces: [Piece]? = {
            guard let x = x.pieces, let y = y.pieces else { return nil }
            return .minus(x, y)
        }()
        let verticalFrame: Frame? = {
            guard let x = x.verticalFrame, let y = y.verticalFrame else { return nil }
            return .minus(x, y)
        }()
        let frame: Frame? = {
            guard let x = x.frame, let y = y.frame else { return nil }
            return .minus(x, y)
        }()
        return Animated(pieces: pieces, verticalFrame: verticalFrame, frame: frame)
    }
    
    static func mul(_ a: Float, _ x: Animated) -> Animated {
        let pieces: [Piece]? = {
            guard let x = x.pieces else { return nil }
            return .mul(a, x)
        }()
        let verticalFrame: Frame? = {
            guard let x = x.verticalFrame else { return nil }
            return .mul(a, x)
        }()
        let frame: Frame? = {
            guard let x = x.frame else { return nil }
            return .mul(a, x)
        }()
        return Animated(pieces: pieces, verticalFrame: verticalFrame, frame: frame)
    }
}
