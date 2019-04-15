import Foundation

struct BriefChartData {
    let points: [Point]
    let color: Color
    let name: String
}

struct DetailedChartData {
    let points: [[Point]]
}

func loadChart(_ i: Int) -> Chart {
    let allBriefData = loadBriefChartData(i)
    let briefData = loadBriefChartData(i)[0]
    let detailedData = loadDetailedChartData(i, allBriefData)[0]
    
    let briefPieces = genPieces(briefData.points, briefData.color)
    
    let groupLengths = detailedData.points.map { $0.count }
    
    
    let concatDetailedPoints = detailedData.points.concat()
    let detailedPieces = genPieces(concatDetailedPoints, briefData.color)
    let chunckedDetailedPieces = detailedPieces.groupBy(lengths: groupLengths) //.chunks(size: 24)

    let detailedPointsPretendingBrief = detailedPretendingBrief(brief: briefPieces, detailed: detailedData.points)
//    let detailedPointsPretendingBrief = detailedPretendingBrief1(briefData.points)
    let detailedPiecesPretendingBrief = genPieces(detailedPointsPretendingBrief, briefData.color)
    let chunckedDetailedPiecesPretendingBrief = detailedPiecesPretendingBrief.groupBy(lengths: groupLengths) //.chunks(size: 24)

    return Chart(
        pieces: PageAlignedContiguousArray(briefPieces),
        briefPieces: briefPieces,
        detailedPieces: chunckedDetailedPieces,
        detailedPiecesPretendingBrief: chunckedDetailedPiecesPretendingBrief,
        color: briefData.color,
        detailedState: nil
    )
}

func yFor(x: Float, a: Point, b: Point) -> Float {
    let r: Float = (x - a.x)/(b.x - a.x)
    return (1 - r)*a.y + r*b.y
}

func detailedPretendingBrief(brief: [Piece], detailed: [[Point]]) -> [Point] {
    return zip(brief, detailed).map {
        let (brief, detailed) = $0
        let a = brief.p1
        let b = brief.p2
        let c = brief.p3
        
        var pretendingDetailed: [Point] = []
        var minD: Float = Float.infinity
        
        for i in 0 ..< detailed.count {
            let p = detailed[i]
            let d = abs(p.x - b.x)
            if d < minD {
                minD = d
            } else if d > minD {
                pretendingDetailed[i-1] = b
            }
            
            let y: Float
            if p.x < b.x {
                y = yFor(x: p.x, a: a, b: b)
            } else {
                y = yFor(x: p.x, a: b, b: c)
            }
            
            pretendingDetailed.append(Point(x: p.x, y: y))
        }
        
        return pretendingDetailed
    }.concat()
}

//func detailedPretendingBrief1(_ ps: [Point]) -> [Point] {
//    assert(ps.count > 2)
//
//    let first: [Point] = (0..<23).map {
//        let a = ps[0]
//        let b = ps[1]
//        return a + (Float($0)/48)*(b-a)
//    }
//
//    let last: [Point] = (0..<23).map {
//        let b = ps[ps.count - 2]
//        let c = ps[ps.count - 1]
//        return (Float(1)/2)*(b-c) + (Float($0)/46)*(c-b)
//    }
//
//    let middle: [[Point]] = (1 ..< ps.count - 2).map { i in
//        let a = ps[i-1]
//        let b = ps[i]
//        let c = ps[i+1]
//        let left: [Point] = (0..<12).map {
//            let x: Point = 0.5*(a+b)
//            let y: Point = (Float($0)/24)*(b-a)
//            return x + y
//        }
//        let right: [Point] = (0..<12).map {
//            let x: Point = b
//            let y: Point = (Float($0)/24)*(b-a)
//            return x + y
//        }
//        return left + right
//    }
//
//    return first + middle.concat() + last
//}

func genPieces(_ ps: [Point], _ color: Color) -> [Piece] {
    guard ps.count > 2 else { return [] }
    
    func endPointPiece(_ i: Int) -> Piece {
        return Piece(
            p1: 2.25*ps[i] - 1.25*ps[i+1],
            p2: 0.75*ps[i] + 0.25*ps[i+1],
            p3: 0.25*ps[i] + 0.75*ps[i+1],
            color: color
        )
    }
    
    let middle = (0..<ps.count-2).map { i in
        Piece(p1: ps[i], p2: ps[i+1], p3: ps[i+2], color: color)
    }
    
    return [endPointPiece(0)] + middle + [endPointPiece(ps.count - 2)]
}

func loadBriefChartData(_ i: Int) -> [BriefChartData] {
    let f = Bundle.main.url(forResource: "graph_data2_s/\(i+1)/overview.json", withExtension: nil)!
    let d = fetchJson(f)
    let colors = parseColors(d)
    return parsePointsWithNames(d).map {
        BriefChartData(
            points: $0.1,
            color: colors[$0.0]!,
            name: findName(d, $0.0)!
        )
    }
}

func loadDetailedChartData(_ i: Int, _ brief: [BriefChartData]) -> [DetailedChartData] {
    let root = Bundle.main.url(forResource: "graph_data2_s/\(i+1)", withExtension: nil)!
    let unsortedFiles = root.subdirs.flatMap { $0.files }
    let files = unsortedFiles.map { $0.absoluteString }.sorted().map { URL(string: $0)! }
    
    let points: [[[Point]]] = files.map { file in
        let points = parsePoints(fetchJson(file))
        
        return zip(points, brief).map {
            let (points, brief) = $0
            return zip(points, brief.points).map {
                let (point, brief) = $0
                return Point(x: point.x, y: brief.y + point.y)
            }
        }
    }
    
    let q = transpose(points)
    
    return q.map { DetailedChartData(points: $0) }
}

func fetchJson(_ f: URL) -> [String: Any] {
    let data = try! Data(contentsOf: f)
    return (try! JSONSerialization.jsonObject(with: data, options: [])) as! [String: Any]
}

func parsePointsWithNames(_ d: [String: Any]) -> [(String, [Point])] {
    let (xs, yss) = parseXY(d)
    return yss.map { ($0.0, zip(xs, $0.1).map { Point(Float($0.0/1000), Float($0.1)) }) }
}

func parsePoints(_ d: [String: Any]) -> [[Point]] {
    return parsePointsWithNames(d).unzip().1
}

func parseBrief(_ d: [String: Any]) -> [BriefChartData] {
    let colors = parseColors(d)
    
    return parsePointsWithNames(d).map {
        BriefChartData(
            points: $0.1,
            color: colors[$0.0]!,
            name: findName(d, $0.0)!
        )
    }
}

func parseXY(_ d: [String: Any]) -> ([Int], [(String, [Int])]) {
    guard let rawColumns = d["columns"] as? [[Any]] else { return ([], []) }
    
    let columns: [(String, [Int])] = rawColumns.map {
        let (rawName, rawValues) = $0.takeFirst()!
        let name = rawName as! String
        let values = rawValues as! [Int]
        return (name, values)
    }
    
    let xs = columns.filter { $0.0 == "x" }.first!.1
    let yss = columns.filter { $0.0 != "x" }
    
    return (xs, yss)
}

func findName(_ d: [String: Any], _ k: String) -> String? {
    return (d["names"] as? [String: String]).flatMap { $0[k] }
}

func parseColors(_ d: [String: Any]) -> [String: Color] {
    return (d["colors"] as! [String: String]).mapValues {
        Color.hashHexString($0)!
    }
}



extension Array {
    func takeFirst() -> (Element, [Element])? {
        return first.map { ($0, Array(self[1...])) }
    }
}

extension Color {
    static func hex(_ rgb: Int) -> Color {
        return Color(
            ((Float)((rgb / 0x10000) % 0x100))/255.0,
            ((Float)((rgb / 0x100) % 0x100))/255.0,
            ((Float)(rgb % 0x100))/255.0,
            1
        )
    }
    
    static func hexString(_ s: String) -> Color? {
        return Int(s, radix: 16).map { hex($0) }
    }
    
    static func hashHexString(_ s: String) -> Color? {
        return hexString(String(s.dropFirst()))
    }
}

extension Array {
    func chunks(size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
    
    func unzip<T1, T2>() -> ([T1], [T2]) where Element == (T1, T2) {
        var result = ([T1](), [T2]())
        
        result.0.reserveCapacity(self.count)
        result.1.reserveCapacity(self.count)
        
        for (a, b) in self {
            result.0.append(a)
            result.1.append(b)
        }
        
        return result
    }
    
    func concat<T>() -> [T] where Element == [T] {
        return flatMap { $0 }
    }
}


extension Array {
    func groupBy(lengths: [Int]) -> [[Element]] {
        var r: [[Element]] = []
        var lens = lengths
        
        for i in 0 ..< count {
            if lens.count == 0 {
                break
            } else {
                if lens[0] == 1 {
                    lens.remove(at: 0)
                    if r.count > 0 {
                        r[r.count - 1].append(self[i])
                    } else {
                        r.append([self[i]])
                    }
                    if lens.count > 0 {
                        r.append([])
                    }
                } else {
                    lens[0] -= 1
                    if r.count > 0 {
                        r[r.count - 1].append(self[i])
                    } else {
                        r.append([self[i]])
                    }
                }
            }
        }
        
        return r
    }
}


func transpose<T>(_ input: [[T]]) -> [[T]] {
    if input.isEmpty { return [[T]]() }
    let count = input[0].count
    var out = [[T]](repeating: [T](), count: count)
    for outer in input {
        for (index, inner) in outer.enumerated() {
            out[index].append(inner)
        }
    }
    return out
}

extension URL {
    var isDirectory: Bool {
        return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
    
    var subdirs: [URL] {
        assert(isDirectory)
        guard isDirectory else { return [] }
        return try! FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]).filter { $0.isDirectory }
    }
    
    var files: [URL] {
        assert(isDirectory)
        guard isDirectory else { return [] }
        return try! FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]).filter { !$0.isDirectory }
    }
}
