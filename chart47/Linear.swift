import Foundation

protocol Linear {
    static func plus(_ x: Self, _ y: Self) -> Self
    static func minus(_ x: Self, _ y: Self) -> Self
    static func mul(_ a: Float, _ x: Self) -> Self
}

extension Float: Linear {
    static func plus(_ x: Float, _ y: Float) -> Float { return x + y }
    static func minus(_ x: Float, _ y: Float) -> Float { return x - y }
    static func mul(_ a: Float, _ x: Float) -> Float { return a*x }
}

extension Point: Linear {
    static func plus(_ x: Point, _ y: Point) -> Point { return Point(x.x + y.x, x.y + y.y) }
    static func minus(_ x: Point, _ y: Point) -> Point { return Point(x.x - y.x, x.y - y.y) }
    static func mul(_ a: Float, _ x: Point) -> Point { return Point(a*x.x, a*x.y) }
}

extension Color: Linear {
    static func plus(_ x: Color, _ y: Color) -> Color {
        return Color(x.x + y.x, x.y + y.y, x.z + y.z, x.w + y.w)
    }
    
    static func minus(_ x: Color, _ y: Color) -> Color {
        return Color(x.x - y.x, x.y - y.y, x.z - y.z, x.w - y.w)
    }
    
    static func mul(_ a: Float, _ x: Color) -> Color {
        return Color(a*x.x, a*x.y, a*x.z, a*x.w)
    }
}

extension Piece: Linear {
    static func plus(_ x: Piece, _ y: Piece) -> Piece {
        return Piece(p1: Point.plus(x.p1, y.p1), p2: Point.plus(x.p2, y.p2), p3: Point.plus(x.p3, y.p3), color: Color.plus(x.color, y.color))
    }
    
    static func minus(_ x: Piece, _ y: Piece) -> Piece {
        return Piece(p1: Point.minus(x.p1, y.p1), p2: Point.minus(x.p2, y.p2), p3: Point.minus(x.p3, y.p3), color: Color.minus(x.color, y.color))
    }
    
    static func mul(_ a: Float, _ x: Piece) -> Piece {
        return Piece(p1: Point.mul(a, x.p1), p2: Point.mul(a, x.p2), p3: Point.mul(a, x.p3), color: Color.mul(a, x.color))
    }
}

extension Array: Linear where Element: Linear {
    static func plus(_ x: [Element], _ y: [Element]) -> [Element] {
        return zip(x,y).map { .plus($0.0, $0.1) }
    }
    
    static func minus(_ x: [Element], _ y: [Element]) -> [Element] {
        return zip(x,y).map { .minus($0.0, $0.1) }
    }
    
    static func mul(_ a: Float, _ x: [Element]) -> [Element] {
        return x.map { .mul(a, $0) }
    }
}
