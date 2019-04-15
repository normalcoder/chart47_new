import Foundation

struct Animation<T: Linear> {
    struct Params {
        let range: Range<Int>
        let fromValue: T
        let toValue: T
    }
    let params: Params
    let startTime: TimeInterval
    let endTime: TimeInterval
    let timingFunction: (Double) -> Double
    let completion: () -> Void
    
    func step(_ t: TimeInterval) -> T? {
        guard t < endTime else { return nil }
        
        let ratio = (t - startTime)/(endTime - startTime)
        let r = Float(timingFunction(ratio))
        return .plus(params.fromValue, .mul(r, (.minus(params.toValue, params.fromValue))))
    }
}
