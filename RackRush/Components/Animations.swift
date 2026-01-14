import SwiftUI

// MARK: - Tile Animations
struct TileAnimation: ViewModifier {
    let isPressed: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
    }
}

// MARK: - Shake Animation
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

// MARK: - Pulse Animation
struct PulseEffect: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - Glow Animation
struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat
    @State private var isGlowing = false
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(isGlowing ? 0.8 : 0.3), radius: isGlowing ? radius : radius/2)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isGlowing)
            .onAppear {
                isGlowing = true
            }
    }
}

// MARK: - Slide In Animation
struct SlideInEffect: ViewModifier {
    let delay: Double
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: isVisible ? 0 : 50)
            .opacity(isVisible ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

// MARK: - Confetti View
// MARK: - Premium Confetti View
struct ConfettiView: View {
    // Premium Palette: Gold, Silver, Holographic Blue
    let colors: [Color] = [
        Color(hue: 0.12, saturation: 0.8, brightness: 1.0), // Gold
        Color(hue: 0.1, saturation: 0.4, brightness: 1.0),  // Pale Gold
        Color.white.opacity(0.9),                           // Silver/Sparkle
        Color(hue: 0.55, saturation: 0.7, brightness: 1.0)  // Premium Blue
    ]
    
    @State private var particles: [PremiumConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(particle: particle)
                }
            }
        }
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        // High density burst
        particles = (0..<60).map { _ in
            PremiumConfettiParticle()
        }
    }
}

struct PremiumConfettiParticle: Identifiable {
    let id = UUID()
    let colorIndex = Int.random(in: 0..<4)
    let startX = Double.random(in: 0...1) // Normalized 0-1
    let duration = Double.random(in: 2.5...4.5)
    let delay = Double.random(in: 0...0.8)
    let scale = Double.random(in: 0.6...1.2)
    let rotationSpeed = Double.random(in: 2...8) // Rotations per second
    let isCircle = Bool.random()
}

struct ConfettiPiece: View {
    let particle: PremiumConfettiParticle
    @State private var falling = false
    
    // Premium Palette (matched to ConfettiView)
    private let colors: [Color] = [
        Color(hue: 0.12, saturation: 0.8, brightness: 1.0),
        Color(hue: 0.1, saturation: 0.4, brightness: 1.0),
        Color.white,
        Color(hue: 0.55, saturation: 0.7, brightness: 1.0)
    ]
    
    private var width: CGFloat {
        8 * particle.scale
    }
    
    private var height: CGFloat {
        (particle.isCircle ? 8 : 14) * particle.scale
    }
    
    private var xPos: CGFloat {
        falling ? xPosition(offset: 50) : xPosition(offset: -50)
    }
    
    private var yPos: CGFloat {
        falling ? UIScreen.main.bounds.height + 50 : -50
    }
    
    var body: some View {
        Group {
            if particle.isCircle {
                Circle()
                    .fill(colors[particle.colorIndex])
            } else {
                Rectangle()
                    .fill(colors[particle.colorIndex])
            }
        }
        .frame(width: width, height: height)
        .shadow(color: colors[particle.colorIndex].opacity(0.6), radius: 4)
        .position(x: xPos, y: yPos)
        .rotationEffect(.degrees(falling ? 360 * particle.rotationSpeed : 0))
        .drawingGroup()
        .onAppear {
            withAnimation(.easeOut(duration: particle.duration).delay(particle.delay)) {
                falling = true
            }
        }
    }
    
    private func xPosition(offset: CGFloat) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let base = particle.startX * screenWidth
        return base + CGFloat.random(in: -30...30)
    }
}

// MARK: - View Extensions
extension View {
    func tileAnimation(isPressed: Bool) -> some View {
        modifier(TileAnimation(isPressed: isPressed))
    }
    
    func shake(trigger: Bool) -> some View {
        modifier(ShakeEffect(animatableData: trigger ? 1 : 0))
    }
    
    func pulse() -> some View {
        modifier(PulseEffect())
    }
    
    // NOTE: .glow extension is defined in Effects.swift (preferred version with `when active` parameter)
    
    func slideIn(delay: Double = 0) -> some View {
        modifier(SlideInEffect(delay: delay))
    }
}
