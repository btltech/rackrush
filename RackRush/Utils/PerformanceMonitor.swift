import SwiftUI
import QuartzCore

/// Performance monitoring utility for tracking FPS and latency
class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    @Published var currentFPS: Double = 60.0
    @Published var averageFPS: Double = 60.0
    @Published var isMonitoring: Bool = false
    
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var fpsHistory: [Double] = []
    private let historyLimit = 60 // 1 second at 60fps
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Start monitoring FPS
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkCallback))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    /// Stop monitoring FPS
    func stopMonitoring() {
        isMonitoring = false
        displayLink?.invalidate()
        displayLink = nil
        fpsHistory.removeAll()
    }
    
    /// Log performance metric
    func logMetric(_ name: String, duration: TimeInterval) {
        #if DEBUG
        if duration > 0.1 { // Log if > 100ms
            print("⚠️ Performance: \(name) took \(Int(duration * 1000))ms")
        }
        #endif
    }
    
    /// Measure execution time of a block
    func measure<T>(_ name: String, block: () -> T) -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = block()
        let duration = CFAbsoluteTimeGetCurrent() - start
        logMetric(name, duration: duration)
        return result
    }
    
    // MARK: - Private Methods
    
    @objc private func displayLinkCallback(displayLink: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = displayLink.timestamp
            return
        }
        
        let currentTimestamp = displayLink.timestamp
        let elapsed = currentTimestamp - lastTimestamp
        
        if elapsed > 0 {
            let fps = 1.0 / elapsed
            
            // Update current FPS
            DispatchQueue.main.async {
                self.currentFPS = fps
            }
            
            // Update history
            fpsHistory.append(fps)
            if fpsHistory.count > historyLimit {
                fpsHistory.removeFirst()
            }
            
            // Calculate average
            if !fpsHistory.isEmpty {
                let avg = fpsHistory.reduce(0, +) / Double(fpsHistory.count)
                DispatchQueue.main.async {
                    self.averageFPS = avg
                }
            }
        }
        
        lastTimestamp = currentTimestamp
        frameCount += 1
    }
}

/// Performance overlay for debugging
struct PerformanceOverlay: View {
    @StateObject private var monitor = PerformanceMonitor.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("FPS: \(Int(monitor.currentFPS))")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(fpsColor)
            
            Text("AVG: \(Int(monitor.averageFPS))")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(8)
        .background(Color.black.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onAppear {
            monitor.startMonitoring()
        }
        .onDisappear {
            monitor.stopMonitoring()
        }
    }
    
    private var fpsColor: Color {
        if monitor.currentFPS >= 55 {
            return .green
        } else if monitor.currentFPS >= 30 {
            return .orange
        } else {
            return .red
        }
    }
}
