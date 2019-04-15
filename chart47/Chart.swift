import Foundation
import CoreGraphics

struct Chart {
    var pieces: PageAlignedContiguousArray<Piece>
    var briefPieces: [Piece]
    var detailedPieces: [[Piece]]
    var detailedPiecesPretendingBrief: [[Piece]]

    var color: Color

    var detailedState: DetailedState?
}

class ChartRef {
    var value: Chart
    
    init(value: Chart) {
        self.value = value
    }
}

typealias Point = vector_float2
typealias Color = vector_float4

struct Coord {
    var x: Float // timestamp
    var y: Float // value
}

extension Chart {
    mutating func setStep(_ step: [Piece]) {
        assert(detailedState != nil)
        guard let s = detailedState else { return }
        
        for i in 0 ..< step.count {
            pieces[s.newRange.lowerBound + i] = step[i]
        }
    }
}

struct DetailedState {
    let oldRange: Range<Int>
    let old: [Piece]
    let newRange: Range<Int>
    let new: [Piece]
    let newFinal: [Piece]
}

extension Chart {
//    func calcDetailedState(_ rawR: Range<Int>) -> DetailedState {
//        let r = cutRange(rawR, bounds: (0, briefPieces.count))
//        let detailedPretendingBriefChunk = detailedPiecesPretendingBrief[r].flatMap { $0 }
//        let detailedPiecesCount = briefPieces.count - (r.upperBound - r.lowerBound) + detailedPretendingBriefChunk.count
//
//        let detailedRange = r.lowerBound ..< r.upperBound + detailedPretendingBriefChunk.count
//
//        let activeRange = extendRangeByOne(detailedRange, bounds: (0, detailedPiecesCount))
//
//        let firstPiece = dec(r.lowerBound, minBound: 0).map { briefPieces[$0] }
//        let lastPiece = inc(r.upperBound, maxBound: briefPieces.count - 1).map { briefPieces[$0] }
//
//        let old = [firstPiece].compactMap { $0 } + briefPieces[r] + [lastPiece].compactMap { $0 }
//
//        let src =
//            [firstPiece].compactMap { $0 } + detailedPretendingBriefChunk + [lastPiece].compactMap { $0 }
//
//        let detailedChunk = detailedPieces[r].flatMap { $0 }
//
//        let firstDetailedPiece = firstPiece.map { p in
//            Piece(p1: p.p1, p2: p.p2, p3: detailedChunk.first!.p1, color: p.color)
//        }
//        let lastDetailedPiece = lastPiece.map { p in
//            Piece(p1: detailedChunk.last!.p3, p2: p.p2, p3: p.p3, color: p.color)
//        }
//
//        let dst =
//            [firstDetailedPiece].compactMap { $0 } + detailedChunk + [lastDetailedPiece].compactMap { $0 }
//
//        return DetailedState(oldRange: r, old: old, newRange: activeRange, new: src, newFinal: dst)
//    }
    
    func calcDetailedState1(_ _rawR: Range<Int>) -> DetailedState {
        let rawR = cutRange(_rawR, bounds: (0, briefPieces.count))
        let r = extendRangeByOne(rawR, bounds: (0, briefPieces.count))
        let briefChunk = Array(briefPieces[r])
        
        let firstBrief = briefChunk.first!
        let lastBrief = briefChunk.last!

        let detailedChunk = detailedPieces[rawR].flatMap { $0 }
        
        let firstDetailed = detailedChunk.first!
        let lastDetailed = detailedChunk.last!
        let middleDetailed = detailedChunk[1 ..< detailedChunk.count - 1]

//        let c = Color(x: 1, y: 1, z: 1, w: 1)
//        let c2 = Color(x: 1, y: 0, z: 0, w: 1)
        let combinedChunk =
            [Piece(p1: firstBrief.p1, p2: firstBrief.p2, p3: firstDetailed.p2, color: firstBrief.color)]
                + [Piece(p1: firstBrief.p2, p2: firstDetailed.p2, p3: firstDetailed.p3, color: firstBrief.color)]
                + middleDetailed
                + [Piece(p1: lastDetailed.p1, p2: lastDetailed.p2, p3: lastBrief.p2, color: firstBrief.color)]
                + [Piece(p1: lastDetailed.p2, p2: lastBrief.p2, p3: lastBrief.p3, color: firstBrief.color)]
        
        
        let detailedPretendingBriefChunk = detailedPiecesPretendingBrief[rawR].flatMap { $0 }
        
        let firstPretendingDetailed = detailedPretendingBriefChunk.first!
        let lastPretendingDetailed = detailedPretendingBriefChunk.last!
        let middlePretendingDetailed = detailedPretendingBriefChunk[1 ..< detailedPretendingBriefChunk.count - 1]
        

        let combinedPretendingChunk =
            [Piece(p1: firstBrief.p1, p2: firstBrief.p2, p3: firstPretendingDetailed.p2, color: firstBrief.color)]
                + [Piece(p1: firstBrief.p2, p2: firstPretendingDetailed.p2, p3: firstPretendingDetailed.p3, color: firstBrief.color)]
                + middlePretendingDetailed
                + [Piece(p1: lastPretendingDetailed.p1, p2: lastPretendingDetailed.p2, p3: lastBrief.p2, color: firstBrief.color)]
                + [Piece(p1: lastPretendingDetailed.p2, p2: lastBrief.p2, p3: lastBrief.p3, color: firstBrief.color)]
        

//        let detailedRange = r.lowerBound ..< r.lowerBound + detailedChunk.count
        
//        let activeRange = extendRangeByOne(detailedRange, bounds: (0, detailedPiecesCount))

        return DetailedState(
            oldRange: r,
            old: briefChunk,
            newRange: pieces.count ..< pieces.count + combinedChunk.count,
            new: combinedPretendingChunk,
            newFinal: combinedChunk
        )
    }
    
    mutating func setDetailedAndPretendBrief(_ rawR: Range<Int>, currentFrame: Frame) -> Animation<Animated>.Params {
        assert(detailedState == nil)
        
        let s = calcDetailedState1(rawR)
        
        pieces.replaceSubrange(pieces.count ..< pieces.count, with: s.new)
        s.oldRange.forEach {
            pieces[$0] = .mul(0.1, pieces[$0]) //Color(x: 0, y: 0, z: 0, w: 0)// 0*pieces[$0].color
            //            let p = pieces[$0]
            //            pieces[$0] = Piece(p1: p.p1, p2: p.p2, p3: p.p3, color: Color(p.color.x, p.color.y, p.color.z, 0.0))
        }
//        pieces.append(contentsOf: s.new)
//        pieces.replaceSubrange(s.oldRange, with: s.new)
        detailedState = s
        
        return Animation.Params(
            range: s.newRange,
            fromValue: Animated(pieces: s.new, verticalFrame: verticalFrameForHorizontal(currentFrame), frame: currentFrame),
            toValue: Animated(pieces: s.newFinal, verticalFrame: verticalFrameForPieces(s.newFinal), frame: horizontalFrameForPieces(s.newFinal))
        )
    }
    
    mutating func setDetailed(_ rawR: Range<Int>) {
        assert(detailedState == nil)
        
        let s = calcDetailedState1(rawR)
        
        pieces.replaceSubrange(pieces.count ..< pieces.count, with: s.newFinal)
        s.oldRange.forEach {
            pieces[$0] = .mul(0.1, pieces[$0]) //Color(x: 0, y: 0, z: 0, w: 0)// 0*pieces[$0].color
//            let p = pieces[$0]
//            pieces[$0] = Piece(p1: p.p1, p2: p.p2, p3: p.p3, color: Color(p.color.x, p.color.y, p.color.z, 0.0))
        }
//        pieces.append(contentsOf: s.newFinal)
//        pieces.replaceSubrange(s.oldRange, with: s.newFinal)
        detailedState = s
    }

    func animationParamsToReturnToBrief(frameToReturn: Frame) -> Animation<Animated>.Params {
        assert(detailedState != nil)
        let s = detailedState!
        
        
        return Animation.Params(
            range: s.newRange,
            fromValue: Animated(pieces: s.newFinal, verticalFrame: verticalFrameForHorizontal(frameToReturn), frame: frameToReturn),
            toValue: Animated(pieces: s.new, verticalFrame: verticalFrameForHorizontal(frameToReturn), frame: frameToReturn)
        )
    }
    
    mutating func setBrief() {
        assert(detailedState != nil)
        let s = detailedState!
        
        pieces.replaceSubrange(pieces.count - s.newFinal.count ..< pieces.count, with: [])
        s.oldRange.forEach {
            pieces[$0] = .mul(10, pieces[$0]) //Color(x: 0, y: 0, z: 0, w: 0)// 0*pieces[$0].color
//            let p = pieces[$0]
//            pieces[$0] = Piece(p1: p.p1, p2: p.p2, p3: p.p3, color: Color(p.color.x, p.color.y, p.color.z, 1.0))
        }
//        pieces.replaceSubrange(s.newRange, with: s.old)

        detailedState = nil
    }
    
    func horizontalFrameForPieces(_ ps: [Piece]) -> Frame {
        let allMin = briefPieces[1].p1.x
        let allMax = briefPieces[briefPieces.count - 2].p3.x

        let min = ps[1].p2.x
        let max = ps[ps.count - 2].p2.x

        let offset = CGFloat((min - allMin)/(allMax - allMin))
        let offsetPlusLength = CGFloat((max - allMin)/(allMax - allMin))

        return Frame(offset: offset, length: offsetPlusLength - offset)
    }
    
    func verticalFrameForPieces(_ ps: [Piece]) -> Frame {
        let allYs = briefPieces.map { $0.p2.y }
        let allMin = allYs.min()!
        let allMax = allYs.max()!
        
        
        let ys = ps.map { $0.p2.y }
        
        let min = ys.min()!
        let max = ys.max()!
        
        let offset = CGFloat((min - allMin)/(allMax - allMin))
        let offsetPlusLength = CGFloat((max - allMin)/(allMax - allMin))
        
        return Frame(offset: offset, length: offsetPlusLength - offset)
    }

    func verticalFrameForRange(_ r: Range<Int>) -> Frame {
        let allYs = briefPieces.map { $0.p2.y }
        let allMin = allYs.min()!
        let allMax = allYs.max()!
        
        let firstIndex = r.lowerBound
        let nextToLastIndex = r.upperBound
        
        let ys = briefPieces[firstIndex ..< nextToLastIndex].map { $0.p2.y }
        
        let min = ys.min()!
        let max = ys.max()!
        
        let offset = CGFloat((min - allMin)/(allMax - allMin))
        let offsetPlusLength = CGFloat((max - allMin)/(allMax - allMin))
        
        return Frame(offset: offset, length: offsetPlusLength - offset)
    }

    func verticalFrameForHorizontal(_ f: Frame) -> Frame {
        let n = briefPieces.count
        return verticalFrameForRange(Int(CGFloat(n)*f.offset) ..< Int(CGFloat(n)*(f.offset + f.length)))
    }
}


//chart
//..., 1 - 14, 15.0 - 15.23, 16 - 30, ...
//
//mini
//..., 1 - 11, 12.0 - 18.23, 19 - 30, ...
//

//0 1 2 3 4       5 6
//1 2 3 4 (5 6 7) 8 9

func inc(_ x: Int, maxBound: Int) -> Int? {
    let x1 = x + 1
    return x1 <= maxBound ? x1 : nil
}

func dec(_ x: Int, minBound: Int) -> Int? {
    let x1 = x - 1
    return x1 >= minBound ? x1 : nil
}

func cutRange(_ r: Range<Int>, bounds: (Int, Int)) -> Range<Int> {
    return max(r.lowerBound, bounds.0) ..< min(r.upperBound, bounds.1)
}

func extendRangeByOne(_ r: Range<Int>, bounds: (Int, Int)) -> Range<Int> {
    return cutRange(r.lowerBound - 1 ..< r.upperBound + 1, bounds: bounds)
}
