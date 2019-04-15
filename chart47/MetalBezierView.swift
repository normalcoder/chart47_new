import UIKit
import MetalKit

class MetalBezierView: MTKView {
    private var commandQueue: MTLCommandQueue! = nil
    private var library: MTLLibrary! = nil
    private var pipelineDescriptor = MTLRenderPipelineDescriptor()
    private var pipelineState : MTLRenderPipelineState! = nil
    var vertexBuffer : MTLBuffer?

    var indices : [UInt16] = [UInt16]()
    var indicesBuffer : MTLBuffer?

    var globalParamBuffer : MTLBuffer?
    
    var currentAnimation: Animation<Animated>?
    let chart: ChartRef
    let frameProvider: FrameProvider
    lazy var animationCheckTimer: Timer = {
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            self?.animateVerticalFrameIfNeeded()
        }
    }()


    static let qColor = vector_float4(x: 0, y: 1, z: 0, w: 1)
//    var changed = false
//    func change() {
//        if changed {
//            qq.replaceSubrange((0..<2), with: [qq[1]])
//        } else {
//            let p1 = qq[0]
//            let p2 = Piece.mul(0.5, p1)
//
//            qq.replaceSubrange((0..<1), with: [p2, p1])
//        }
//
//        changed = !changed
//    }
    var qq: PageAlignedContiguousArray<Piece> = {
        let w = Float(UIScreen.main.bounds.width)
        let h = Float(UIScreen.main.bounds.height)
        let c = qColor
        return PageAlignedContiguousArray([
            Piece(p1: vector_float2(x: 40, y: -40+100), p2: vector_float2(x: 50, y: 50+100), p3: vector_float2(x: 60, y: 0-90+100), color: c),
            Piece(p1: vector_float2(x: 149.8, y: 50), p2: vector_float2(x: 150, y: 150), p3: vector_float2(x: 155, y: 100), color: c),
            Piece(p1: vector_float2(x: 199, y: 200), p2: vector_float2(x: 200, y: 150), p3: vector_float2(x: 210, y: 300), color: c),
            Piece(p1: vector_float2(x: 199+40, y: 300), p2: vector_float2(x: 200+40, y: 150), p3: vector_float2(x: 210+40, y: 200), color: c),
            Piece(p1: vector_float2(x: w-200, y: h-200), p2: vector_float2(x: w-100, y: h-100), p3: vector_float2(x: w-90, y: h-200), color: c),

            Piece(p1: vector_float2(x: 100, y: 300), p2: vector_float2(x: 150, y: 350), p3: vector_float2(x: 200, y: 300), color: c),
            Piece(p1: vector_float2(x: 150-100, y: 350-100), p2: vector_float2(x: 200-100, y: 300-100), p3: vector_float2(x: 250-100, y: 350-100), color: c),

            ])
    }()
    
    func params() -> PageAlignedContiguousArray<Piece> {

//        return qq
        return chart.value.pieces
        

//        func r() -> vector_float2 {
//            return vector_float2(x: Float(arc4random_uniform(350)), y: Float(arc4random_uniform(350)))
//        }
//
//        let params = (0 ..< 365*4*5/4).map { _ in
//            Piece(p1: r(), p2: r(), p3: r())
//        }
//
//        return PageAlignedContiguousArray(params)
    }

    
    var globalParams: PageAlignedContiguousArray<GlobalParameters>
    
    init(chart: ChartRef, frameProvider: FrameProvider) {
        self.chart = chart
        self.frameProvider = frameProvider
        let vFrame = chart.value.verticalFrameForHorizontal(frameProvider.currentFrame())
        oldFrame = vFrame
        newFrame = vFrame

        globalParams = PageAlignedContiguousArray([GlobalParameters(
            elementsPerInstance: 12,
            modelView: float3x3([float3([1,0,0]), float3([0,1,0]), float3([0,0,1])]),
            viewScale: float3x3([float3([1,0,0]), float3([0,1,0]), float3([0,0,1])]),
            frame: float3x3([float3([1,0,0]), float3([0,1,0]), float3([0,0,1])]),
            verticalFrame: float3x3([float3([1,0,0]), float3([0,1,0]), float3([0,0,1])]),
            lineWidth: 1
        )])
        
        super.init(frame: CGRect.zero, device: nil)
        
        _ = animationCheckTimer
//        isPaused = true
    }

//    override init(frame frameRect: CGRect, device: MTLDevice?)
//    {
//        super.init(frame: frameRect, device: device)
////        configureWithDevice(device!)
//    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //        let translate = float3x3([float3([1,0,0]), float3([0,1,0]), float3([-1,-1,1])])
//        let scale = float3x3([float3([2/Float(bounds.width),0,0]), float3([0,2/Float(bounds.height),0]), float3([0,0,1])])

        //        globalParams[0].modelView = simd_mul(translate, scale)
//        let viewScale = float3x3([float3([1,0,0]), float3([0,1,0]), float3([0,0,1])])

        let minX = chart.value.briefPieces[1].p1.x
        let maxX = chart.value.briefPieces[chart.value.briefPieces.count - 2].p3.x
        let minY = chart.value.briefPieces.map { $0.p2.y }.min { $0 < $1 }!
        let maxY = chart.value.briefPieces.map { $0.p2.y }.max { $0 < $1 }!
//        print("\(minX, maxX) \(minY, maxY)")

        let sx = Float(bounds.width/(CGFloat(maxX) - CGFloat(minX)))//*20
        let sy = Float(bounds.height/(CGFloat(maxY) - CGFloat(minY)))
//        let (sx, sy): (Float, Float) = (1.017501e-05, 0.010638298)
//        print("\(sx, sy)")

        let dx = -minX
        let dy = -minY
//        let (dx, dy): (Float, Float) = (-1.5230592e+09, -720.0)
//        print("\(dx, dy)")

        let translate = float3x3([float3([1,0,0]), float3([0,1,0]), float3([dx,dy,1])])
        let scale = float3x3([float3([sx,0,0]), float3([0,sy,0]), float3([0,0,1])])
        
//        let translate = float3x3([float3([1,0,0]), float3([0,1,0]), float3([0,0,1])])
//        let scale = float3x3([float3([1,0,0]), float3([0,1,0]), float3([0,0,1])])
        
        globalParams[0].viewScale = simd_mul(scale, translate)
    }

    required init(coder: NSCoder)
    {
        fatalError()
    }

    func configureWithDevice(_ device : MTLDevice) {
        self.clearColor = MTLClearColor.init(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.framebufferOnly = true
        self.colorPixelFormat = .bgra8Unorm

        // Run with 4x MSAA:
        self.sampleCount = 4

        self.preferredFramesPerSecond = 60

        self.device = device
    }

    override var device: MTLDevice! {
        didSet {
            super.device = device
            commandQueue = (self.device?.makeCommandQueue())!

            library = device?.makeDefaultLibrary()
            pipelineDescriptor.vertexFunction = library?.makeFunction(name: "piece_vertex")
            pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "piece_fragment")
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineDescriptor.sampleCount = 4
            
//            pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
//            pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
//            pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
//            pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
//            pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
//            pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
//            pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

//            pipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
//            pipelineStateDescriptor.colorAttachments[0].blendingEnabled = true
//            pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.Add
//            pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.Add
//            pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.One
//            pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.One
//            pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.OneMinusSourceAlpha
//            pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.OneMinusSourceAlpha
            
//            pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
//            pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
//            pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
//            pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .destinationAlpha
//            pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .destinationAlpha
//            pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
//            pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusBlendAlpha

            do {
                try pipelineState = device?.makeRenderPipelineState(descriptor: pipelineDescriptor)
            }
            catch {

            }

            vertexBuffer = device.makeBufferWithPageAlignedArray(params())

            var currentIndex : UInt16 = 0
            
            globalParamBuffer = device.makeBufferWithPageAlignedArray(globalParams)
            
            repeat {
                indices.append(currentIndex)
//                indices.append(currentIndex + 1)
//                indices.append(currentIndex + 2)
                currentIndex += 1
            } while indices.count < Int(globalParams[0].elementsPerInstance)

            let indicesDataSize = MemoryLayout<UInt>.size * indices.count
            indicesBuffer = self.device?.makeBuffer(bytes: indices, length: indicesDataSize, options: .storageModeShared)
        }
    }
    
    func applyHorizontalFrame(_ f: Frame) {
        let w = bounds.width
        
        //        0 1 -> translate 0, scale 1
        //        0 0.5 -> translate 0, scale 2
        //        0.5 1 -> translate w/2, scale 1
        //        0.5 1 -> translate w/2, scale 1
        
        let translate = float3x3([float3([1,0,0]), float3([0,1,0]), float3([Float(-w*f.offset),0,1])])
        let scale = float3x3([float3([Float(1/f.length),0,0]), float3([0,1,0]), float3([0,0,1])])
        
        globalParams[0].frame = simd_mul(scale, translate)
    }
    
    func changeFrame(offset: CGFloat, width: CGFloat) {
        applyHorizontalFrame(Frame(offset: offset, length: width))
        changeVerticalFrame(Frame(offset: offset, length: width))
    }
    
    var oldFrame: Frame
    var newFrame: Frame

    func changeVerticalFrame(_ hFrame: Frame) {
//        let fromFrame = chart.value.verticalFrameForHorizontal(frameProvider.currentFrame())
        newFrame = chart.value.verticalFrameForHorizontal(hFrame)
//        print("newFrame: \(newFrame)")
    }
        
//        guard let oldFrame = oldFrame else {
//            let h = bounds.height
//            let translate = float3x3([float3([1,0,0]), float3([0,1,0]), float3([0,Float(-h*toFrame.offset),1])])
//            let scale = float3x3([float3([1,0,0]), float3([0,Float(1/toFrame.length),0]), float3([0,0,1])])
//            globalParams[0].verticalFrame = simd_mul(scale, translate)
//            self.oldFrame = toFrame
//            return
//        }

    func animateVerticalFrameIfNeeded() {
        guard currentAnimation == nil else { return }
        guard newFrame != oldFrame else { return }
        
        let startTime = CACurrentMediaTime()
        let endTime = startTime + 0.25
        
        let from = Animated(pieces: nil, verticalFrame: oldFrame, frame: nil)
        let to = Animated(pieces: nil, verticalFrame: newFrame, frame: nil)
        let params = Animation.Params(range: 0..<0, fromValue: from, toValue: to)
        
        let a = Animation(
            params: params,
            startTime: startTime,
            endTime: endTime,
            timingFunction: timingFunction,
            completion: {}
        )
        
        animate(a)
        self.oldFrame = newFrame
    }

    override func draw(_ rect: CGRect) {
//        let t = CACurrentMediaTime()
//        let v: Float = Float(sin(t) + 2)
        
        let shouldPause: Bool
        
        if let a = currentAnimation {
            if let step = a.step(CACurrentMediaTime()) {
                if let pieces = step.pieces {
                    chart.value.setStep(pieces)
                }
                if let f = step.verticalFrame {
                    let h = bounds.height
                    let translate = float3x3([float3([1,0,0]), float3([0,1,0]), float3([0,Float(-h*f.offset),1])])
                    let scale = float3x3([float3([1,0,0]), float3([0,Float(1/f.length),0]), float3([0,0,1])])
                    globalParams[0].verticalFrame = simd_mul(scale, translate)
                }
                if let f = step.frame {
                    applyHorizontalFrame(f)
                }
//                globalParams[0].detailed = step.detailed
//
//                chart.value.setStep(step.chart)
                
                shouldPause = false
            } else {
                shouldPause = true
                a.completion()
                currentAnimation = nil
            }
        } else {
            shouldPause = false
        }
        
        let translate = float3x3([float3([1,0,0]), float3([0,1,0]), float3([-1,-1,1])])
        let scale = float3x3([float3([2/Float(bounds.width),0,0]), float3([0,2/Float(bounds.height),0]), float3([0,0,1])])
        
        globalParams[0].modelView = simd_mul(translate, scale)
        
        

        let commandBuffer = commandQueue!.makeCommandBuffer()!

        let renderPassDescriptor = self.currentRenderPassDescriptor
        
        if renderPassDescriptor == nil {
            return
        }
        

        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor!)!

        renderEncoder.setRenderPipelineState(pipelineState)

        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(globalParamBuffer, offset: 0, index: 1)

        // Enable this to see the actual triangles instead of a solid curve:
//        renderEncoder.setTriangleFillMode(.lines)

        renderEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: indices.count, indexType: .uint16, indexBuffer: indicesBuffer!, indexBufferOffset: 0, instanceCount: params().count)

        renderEncoder.endEncoding()

        commandBuffer.present(self.currentDrawable!)
        commandBuffer.commit()
        
        if shouldPause {
//            isPaused = true
        }
    }
    
    func animate(_ a: Animation<Animated>) {
        currentAnimation = a
//        isPaused = false
    }
}
