import AVFoundation
import AudioToolbox
import SwiftUI

/// AudioManager with synthesized sound effects - using proper audio format
class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    @AppStorage("soundEnabled") var isSoundEnabled = true
    @AppStorage("hapticsEnabled") var isHapticsEnabled = true
    
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var audioFormat: AVAudioFormat?
    
    private init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioEngine = AVAudioEngine()
            playerNode = AVAudioPlayerNode()
            
            guard let engine = audioEngine, let player = playerNode else { return }
            
            engine.attach(player)
            
            // Get the format from the main mixer (this is what the player must output)
            let mixerFormat = engine.mainMixerNode.outputFormat(forBus: 0)
            audioFormat = mixerFormat
            
            // Connect with the mixer's format
            engine.connect(player, to: engine.mainMixerNode, format: mixerFormat)
            
            try engine.start()
        } catch {
            print("Audio engine setup failed: \(error)")
        }
    }
    
    // MARK: - Sound Effects
    
    func playTap() {
        if isSoundEnabled {
            playTone(frequency: 800, duration: 0.05, volume: 0.3)
        }
        if isHapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    func playTapWithHaptic() {
        playTap()
    }
    
    func playDelete() {
        if isSoundEnabled {
            playTone(frequency: 400, duration: 0.08, volume: 0.25)
        }
        if isHapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    func playSubmit() {
        if isSoundEnabled {
            // Rising tone
            playTone(frequency: 600, duration: 0.1, volume: 0.4)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.playTone(frequency: 900, duration: 0.15, volume: 0.4)
            }
        }
        if isHapticsEnabled {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }
    
    func playSubmitWithHaptic() {
        playSubmit()
    }
    
    func playWin() {
        if isSoundEnabled {
            // Victory fanfare
            playTone(frequency: 523, duration: 0.15, volume: 0.5)  // C5
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.playTone(frequency: 659, duration: 0.15, volume: 0.5)  // E5
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.playTone(frequency: 784, duration: 0.25, volume: 0.5)  // G5
            }
        }
        if isHapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    func playWinWithHaptic() {
        playWin()
    }
    
    func playLose() {
        if isSoundEnabled {
            // Descending sad tone
            playTone(frequency: 400, duration: 0.2, volume: 0.4)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.playTone(frequency: 300, duration: 0.3, volume: 0.35)
            }
        }
        if isHapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }
    
    func playLoseWithHaptic() {
        playLose()
    }
    
    func playTick() {
        if isSoundEnabled {
            playTone(frequency: 1000, duration: 0.03, volume: 0.2)
        }
    }
    
    func playError() {
        if isSoundEnabled {
            playTone(frequency: 200, duration: 0.15, volume: 0.4)
        }
        if isHapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    
    func playSelect() {
        if isSoundEnabled {
            playTone(frequency: 700, duration: 0.04, volume: 0.25)
        }
        if isHapticsEnabled {
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
    
    func playCountdown() {
        if isSoundEnabled {
            playTone(frequency: 880, duration: 0.1, volume: 0.35)
        }
    }
    
    // MARK: - Tone Generator
    
    private func playTone(frequency: Double, duration: Double, volume: Float) {
        guard let engine = audioEngine,
              let player = playerNode,
              let format = audioFormat else { return }
        
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        
        buffer.frameLength = frameCount
        
        let channelCount = Int(format.channelCount)
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let wave = sin(2.0 * .pi * frequency * time)
            
            // Apply envelope to avoid clicks
            let envelope: Float
            let attackTime = 0.01
            let releaseTime = 0.05
            
            if time < attackTime {
                envelope = Float(time / attackTime)
            } else if time > duration - releaseTime {
                envelope = Float((duration - time) / releaseTime)
            } else {
                envelope = 1.0
            }
            
            let sample = Float(wave) * envelope * volume
            
            // Write to all channels
            for channel in 0..<channelCount {
                buffer.floatChannelData?[channel][frame] = sample
            }
        }
        
        // Restart engine if needed
        if !engine.isRunning {
            try? engine.start()
        }
        
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        if !player.isPlaying {
            player.play()
        }
    }
    
    // MARK: - Haptic Only
    
    func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isHapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
