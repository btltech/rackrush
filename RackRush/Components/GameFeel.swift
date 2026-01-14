import SwiftUI
import AVFoundation
import AudioToolbox

// MARK: - Haptic Engine (Textured Vibrations)
class HapticEngine {
    static let shared = HapticEngine()
    
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    private init() {
        // Pre-warm generators for instant response
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        rigidGenerator.prepare()
        softGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    // Tile picked up from rack - light, quick tap
    func tilePickUp() {
        lightGenerator.impactOccurred(intensity: 0.6)
        lightGenerator.prepare()
    }
    
    // Tile dropped into word slot - medium thud
    func tileDrop() {
        rigidGenerator.impactOccurred(intensity: 0.8)
        rigidGenerator.prepare()
    }
    
    // Letter removed from word - soft reverse feel
    func tileRemove() {
        softGenerator.impactOccurred(intensity: 0.5)
        softGenerator.prepare()
    }
    
    // Word cleared - double tap pattern
    func wordClear() {
        lightGenerator.impactOccurred(intensity: 0.4)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            self?.lightGenerator.impactOccurred(intensity: 0.3)
            self?.lightGenerator.prepare()
        }
    }
    
    // Word submitted - satisfying confirmation
    func wordSubmit() {
        heavyGenerator.impactOccurred(intensity: 1.0)
        heavyGenerator.prepare()
    }
    
    // Round won - success pattern
    func roundWon() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }
    
    // Round lost - warning pattern
    func roundLost() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }
    
    // Match won - triumphant pattern
    func matchWon() {
        // Triple burst celebration
        heavyGenerator.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.rigidGenerator.impactOccurred(intensity: 0.9)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) { [weak self] in
            self?.heavyGenerator.impactOccurred(intensity: 1.0)
            self?.heavyGenerator.prepare()
        }
    }
    
    // Invalid action - error buzz
    func error() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }
    
    // Timer warning - subtle pulse
    func timerWarning() {
        softGenerator.impactOccurred(intensity: 0.3)
        softGenerator.prepare()
    }
    
    // Timer critical - urgent pulse
    func timerCritical() {
        mediumGenerator.impactOccurred(intensity: 0.7)
        mediumGenerator.prepare()
    }
}

// MARK: - Audio Synthesis Engine (Enhanced)
class AudioSynthesizer: ObservableObject {
    static let shared = AudioSynthesizer()
    
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var mixerNode: AVAudioMixerNode?
    
    // Flow state tracking
    @Published var flowIntensity: Double = 0.0
    private var lastTypingTime: Date = Date()
    private var typingSpeed: Double = 0.0
    private var recentTypingTimes: [Date] = []
    
    // Enhanced pentatonic scale with more notes
    private let baseFrequencies: [Double] = [
        261.63, // C4
        293.66, // D4
        329.63, // E4
        392.00, // G4
        440.00, // A4
        493.88, // B4
        523.25, // C5
        587.33, // D5
        659.25, // E5
        783.99, // G5
    ]
    
    private var currentNoteIndex = 0
    private let sampleRate: Double = 44100.0
    
    @AppStorage("soundEnabled") private var soundEnabled = true
    
    private init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        mixerNode = AVAudioMixerNode()
        
        guard let engine = audioEngine,
              let player = playerNode,
              let mixer = mixerNode else { return }
        
        engine.attach(player)
        engine.attach(mixer)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        
        engine.connect(player, to: mixer, format: format)
        engine.connect(mixer, to: engine.mainMixerNode, format: format)
        
        // Warmer volume
        mixer.outputVolume = 0.4
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
        } catch {
            Log.audio("Audio engine failed: \(error)")
        }
    }
    
    // Called when a letter is typed
    func onLetterTyped() {
        let now = Date()
        recentTypingTimes.append(now)
        recentTypingTimes = recentTypingTimes.filter { now.timeIntervalSince($0) < 3.0 }
        
        if recentTypingTimes.count >= 2 {
            let timeSpan = now.timeIntervalSince(recentTypingTimes.first!)
            typingSpeed = Double(recentTypingTimes.count - 1) / max(timeSpan, 0.1)
        }
        
        flowIntensity = min(1.0, typingSpeed / 4.0)
        playFlowNote()
        lastTypingTime = now
    }
    
    private func playFlowNote() {
        guard soundEnabled else { return }
        guard let player = playerNode, let engine = audioEngine, engine.isRunning else { return }
        
        let targetIndex = Int(flowIntensity * Double(baseFrequencies.count - 1))
        currentNoteIndex = min(targetIndex, baseFrequencies.count - 1)
        
        let frequency = baseFrequencies[currentNoteIndex]
        let duration = 0.1 + (flowIntensity * 0.06)
        
        if let buffer = generateWarmTone(frequency: frequency, duration: duration) {
            player.scheduleBuffer(buffer, completionHandler: nil)
            if !player.isPlaying {
                player.play()
            }
        }
    }
    
    // Warm tone: triangle wave + sine blend with smooth envelope
    private func generateWarmTone(frequency: Double, duration: Double) -> AVAudioPCMBuffer? {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        
        guard let channelData = buffer.floatChannelData?[0] else { return nil }
        
        let angularFreq = 2.0 * Double.pi * frequency / sampleRate
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let normalizedTime = t / duration
            
            // Smooth ADSR envelope
            let attack = 0.015
            let decay = 0.05
            let sustain = 0.6
            let release = 0.3
            var envelope: Double
            
            if normalizedTime < attack {
                envelope = normalizedTime / attack
            } else if normalizedTime < attack + decay {
                let decayProgress = (normalizedTime - attack) / decay
                envelope = 1.0 - (1.0 - sustain) * decayProgress
            } else if normalizedTime < 1.0 - release {
                envelope = sustain
            } else {
                let releaseProgress = (normalizedTime - (1.0 - release)) / release
                envelope = sustain * (1.0 - releaseProgress)
            }
            
            // Triangle wave (warmer than sine)
            let phase = fmod(Double(frame) * frequency / sampleRate, 1.0)
            let triangle = phase < 0.5 ? (4.0 * phase - 1.0) : (3.0 - 4.0 * phase)
            
            // Sine wave for smoothness
            let sine = sin(angularFreq * Double(frame))
            
            // Blend: 60% triangle, 40% sine
            let wave = triangle * 0.6 + sine * 0.4
            
            // Add subtle harmonic
            let harmonic = sin(angularFreq * 2.0 * Double(frame)) * 0.15
            
            let volume = 0.18 + (flowIntensity * 0.12)
            channelData[frame] = Float((wave + harmonic) * envelope * volume)
        }
        
        return buffer
    }
    
    // Success chord: Major 7th (warm, satisfying)
    func playSuccessChord() {
        guard soundEnabled else { return }
        // C major 7: C5, E5, G5, B5
        playRichChord(frequencies: [523.25, 659.25, 783.99, 987.77], duration: 0.4, shimmer: true)
    }
    
    // Tile tap: Short plucky note
    func playTileTap() {
        guard soundEnabled else { return }
        playPluck(frequency: 880.0, duration: 0.06)
    }
    
    // Submission: Satisfying confirmation
    func playSubmit() {
        guard soundEnabled else { return }
        // Two-note confirmation: G5 -> C6
        playPluck(frequency: 783.99, duration: 0.08)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.playPluck(frequency: 1046.50, duration: 0.12)
        }
    }
    
    // Error sound: Muted thud
    func playErrorSound() {
        guard soundEnabled else { return }
        playMutedThud()
    }
    
    private func playPluck(frequency: Double, duration: Double) {
        guard let player = playerNode, let engine = audioEngine, engine.isRunning else { return }
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let angularFreq = 2.0 * Double.pi * frequency / sampleRate
        
        for frame in 0..<Int(frameCount) {
            let normalizedTime = Double(frame) / Double(frameCount)
            
            // Quick decay envelope (plucky)
            let envelope = pow(1.0 - normalizedTime, 3.0)
            
            let sample = sin(angularFreq * Double(frame)) * 0.8
                       + sin(angularFreq * 2.0 * Double(frame)) * 0.15
                       + sin(angularFreq * 3.0 * Double(frame)) * 0.05
            
            channelData[frame] = Float(sample * envelope * 0.3)
        }
        
        player.scheduleBuffer(buffer, completionHandler: nil)
        if !player.isPlaying { player.play() }
    }
    
    private func playRichChord(frequencies: [Double], duration: Double, shimmer: Bool = false) {
        guard let player = playerNode, let engine = audioEngine, engine.isRunning else { return }
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        for frame in 0..<Int(frameCount) {
            var sample: Double = 0
            let normalizedTime = Double(frame) / Double(frameCount)
            
            // Bell-curve envelope
            let envelope = sin(Double.pi * normalizedTime) * (1.0 - normalizedTime * 0.3)
            
            for (i, frequency) in frequencies.enumerated() {
                let angularFreq = 2.0 * Double.pi * frequency / sampleRate
                var note = sin(angularFreq * Double(frame))
                
                // Add shimmer (subtle vibrato) to higher notes
                if shimmer && i >= frequencies.count / 2 {
                    let vibrato = sin(Double(frame) * 6.0 * Double.pi / sampleRate) * 0.003
                    note = sin((angularFreq + vibrato) * Double(frame))
                }
                
                sample += note
            }
            
            sample /= Double(frequencies.count)
            channelData[frame] = Float(sample * envelope * 0.3)
        }
        
        player.scheduleBuffer(buffer, completionHandler: nil)
        if !player.isPlaying { player.play() }
    }
    
    private func playMutedThud() {
        guard let player = playerNode, let engine = audioEngine, engine.isRunning else { return }
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * 0.12)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        for frame in 0..<Int(frameCount) {
            let normalizedTime = Double(frame) / Double(frameCount)
            let envelope = pow(1.0 - normalizedTime, 4.0)
            
            // Low frequency noise-like thud
            let freq1 = 2.0 * Double.pi * 80.0 / sampleRate
            let freq2 = 2.0 * Double.pi * 120.0 / sampleRate
            let sample = sin(freq1 * Double(frame)) * 0.7 + sin(freq2 * Double(frame)) * 0.3
            
            channelData[frame] = Float(sample * envelope * 0.25)
        }
        
        player.scheduleBuffer(buffer, completionHandler: nil)
        if !player.isPlaying { player.play() }
    }
    
    // Reset flow when word is cleared or submitted
    func resetFlow() {
        flowIntensity = 0.0
        currentNoteIndex = 0
        recentTypingTimes.removeAll()
    }
}

// MARK: - Flying Tile State
class TileAnimationState: ObservableObject {
    @Published var flyingTiles: [FlyingTile] = []
    
    struct FlyingTile: Identifiable {
        let id = UUID()
        let letter: String
        let sourcePosition: CGPoint
        let targetPosition: CGPoint
        var progress: Double = 0
    }
    
    func startFlyingTile(letter: String, from source: CGPoint, to target: CGPoint) {
        let tile = FlyingTile(letter: letter, sourcePosition: source, targetPosition: target)
        flyingTiles.append(tile)
        
        // Remove after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.flyingTiles.removeAll { $0.id == tile.id }
        }
    }
}

// MARK: - Namespace Key for Geometry Matching
struct TileNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var tileNamespace: Namespace.ID? {
        get { self[TileNamespaceKey.self] }
        set { self[TileNamespaceKey.self] = newValue }
    }
}
