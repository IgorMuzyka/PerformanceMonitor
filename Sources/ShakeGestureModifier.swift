
#if os(iOS) && canImport(UIKit)
import SwiftUI
import UIKit

// The notification we'll send when a shake gesture happens.
fileprivate extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}
//  Override the default behavior of shake gestures to send our notification instead.
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
     }
}
// A view modifier that detects shaking and calls a function of our choosing.
fileprivate struct ShakeGestureModifier: ViewModifier {
    let action: () -> Void
    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                action()
            }
    }
}
// A View extension to make the modifier easier to use.
public extension View {
    func onShake(_ action: @escaping () -> Void) -> some View {
        self.modifier(ShakeGestureModifier(action: action))
    }
}

#elseif os(macOS)
import SwiftUI

public extension View {
    func onShake(_ action: @escaping () -> Void) -> some View {
        /// just a stub
        return self
    }
}
#endif
