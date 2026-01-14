import SwiftUI
import UIKit

struct ShareSheet {
    static func share(text: String, image: UIImage? = nil) {
        var items: [Any] = [text]
        if let image = image {
            items.append(image)
        }
        
        let av = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // UIKit finding current window scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            
            // Handle iPad popover
            if let popover = av.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootVC.present(av, animated: true, completion: nil)
        }
    }
}
