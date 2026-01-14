import SwiftUI

// MARK: - Device-Aware Layout System
struct DeviceLayout {
    enum DeviceCategory {
        case phoneMini    // iPhone SE, iPhone 8
        case phone        // iPhone 13/14/15 standard
        case phoneLarge   // iPhone Pro Max
        case pad          // all iPads
        
        static var current: DeviceCategory {
            let width = UIScreen.main.bounds.width
            let height = UIScreen.main.bounds.height
            let screenSize = min(width, height)
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                return .pad
            } else if screenSize <= 375 {
                return .phoneMini
            } else if screenSize <= 390 {
                return .phone
            } else {
                return .phoneLarge
            }
        }
    }
    
    // Current device
    static let device = DeviceCategory.current
    
    // Base scale factor (1.0 = iPhone 13/14/15)
    static var scale: CGFloat {
        switch device {
        case .phoneMini: return 0.85
        case .phone: return 1.0
        case .phoneLarge: return 1.1
        case .pad: return 1.4
        }
    }
    
    // MARK: - Tile Sizing
    static var tileSize: CGFloat {
        switch device {
        case .phoneMini: return 52
        case .phone: return 60
        case .phoneLarge: return 68
        case .pad: return 85
        }
    }
    
    static var wordBuilderTileSize: CGFloat {
        switch device {
        case .phoneMini: return 36
        case .phone: return 44
        case .phoneLarge: return 50
        case .pad: return 60
        }
    }
    
    // MARK: - Timer Sizing
    static var timerSize: CGFloat {
        switch device {
        case .phoneMini: return 100
        case .phone: return 120
        case .phoneLarge: return 140
        case .pad: return 180
        }
    }
    
    // MARK: - Spacing
    static var tileSpacing: CGFloat {
        switch device {
        case .phoneMini: return 6
        case .phone: return 8
        case .phoneLarge: return 10
        case .pad: return 14
        }
    }
    
    static var sectionSpacing: CGFloat {
        switch device {
        case .phoneMini: return 16
        case .phone: return 20
        case .phoneLarge: return 24
        case .pad: return 32
        }
    }
    
    // MARK: - Button Sizing
    static var buttonHeight: CGFloat {
        switch device {
        case .phoneMini: return 48
        case .phone: return 56
        case .phoneLarge: return 60
        case .pad: return 70
        }
    }
    
    static var buttonCornerRadius: CGFloat {
        switch device {
        case .phoneMini: return 24
        case .phone: return 28
        case .phoneLarge: return 30
        case .pad: return 35
        }
    }
    
    // MARK: - Font Sizes
    struct Fonts {
        static var title: CGFloat {
            switch device {
            case .phoneMini: return 28
            case .phone: return 34
            case .phoneLarge: return 38
            case .pad: return 48
            }
        }
        
        static var headline: CGFloat {
            switch device {
            case .phoneMini: return 18
            case .phone: return 20
            case .phoneLarge: return 22
            case .pad: return 28
            }
        }
        
        static var body: CGFloat {
            switch device {
            case .phoneMini: return 14
            case .phone: return 16
            case .phoneLarge: return 17
            case .pad: return 20
            }
        }
        
        static var caption: CGFloat {
            switch device {
            case .phoneMini: return 11
            case .phone: return 12
            case .phoneLarge: return 13
            case .pad: return 16
            }
        }
        
        static var tileLetter: CGFloat {
            switch device {
            case .phoneMini: return 22
            case .phone: return 26
            case .phoneLarge: return 30
            case .pad: return 38
            }
        }
        
        static var tileScore: CGFloat {
            switch device {
            case .phoneMini: return 8
            case .phone: return 9
            case .phoneLarge: return 10
            case .pad: return 12
            }
        }
        
        static var timer: CGFloat {
            switch device {
            case .phoneMini: return 32
            case .phone: return 40
            case .phoneLarge: return 48
            case .pad: return 60
            }
        }
        
        static var score: CGFloat {
            switch device {
            case .phoneMini: return 36
            case .phone: return 44
            case .phoneLarge: return 52
            case .pad: return 64
            }
        }
    }
    
    // MARK: - Layout Utilities
    static var isPad: Bool { device == .pad }
    static var isCompact: Bool { device == .phoneMini }
    
    // Maximum content width (for iPad centering)
    static var maxContentWidth: CGFloat {
        switch device {
        case .pad: return 500
        default: return .infinity
        }
    }
    
    // Tiles per row in letter rack
    static var tilesPerRow: Int {
        switch device {
        case .phoneMini: return 5
        case .phone: return 5
        case .phoneLarge: return 5
        case .pad: return 7
        }
    }
}

// MARK: - Responsive View Modifier
struct ResponsiveFrame: ViewModifier {
    let maxWidth: CGFloat
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: maxWidth)
            .padding(.horizontal, DeviceLayout.isPad ? 40 : 0)
    }
}

extension View {
    /// Centers content with max width on iPad
    func responsiveFrame() -> some View {
        modifier(ResponsiveFrame(maxWidth: DeviceLayout.maxContentWidth))
    }
    
    /// Scales a value based on device
    func scaled(_ value: CGFloat) -> CGFloat {
        value * DeviceLayout.scale
    }
}

// MARK: - Screen Size Reader
struct ScreenSize {
    static var width: CGFloat { UIScreen.main.bounds.width }
    static var height: CGFloat { UIScreen.main.bounds.height }
    static var safeAreaTop: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.safeAreaInsets.top ?? 0
    }
    static var safeAreaBottom: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.safeAreaInsets.bottom ?? 0
    }
}
