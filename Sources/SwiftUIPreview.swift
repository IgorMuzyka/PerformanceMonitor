
#if DEBUG && targetEnvironment(simulator)
import SwiftUI
struct Preview: View {
    @State var isPresented: Bool = true
    var body: some View {
        Rectangle()
            .fill(.clear)
            .performanceMonitor(
                isPresented: $isPresented,
                shakeGestureTogglesPresentation: true, 
                sizeClass: .compact
            )
    }
}
@available(iOS 17.0, *)
#Preview("Dark", traits: .fixedLayout(width: 262, height: 64)) {
    Preview()
        .background(.clear)
        .preferredColorScheme(.dark)
}
@available(iOS 17.0, *)
#Preview("Light", traits: .fixedLayout(width: 262, height: 64)) {
    Preview()
        .background(.clear)
        .preferredColorScheme(.light)
}
#endif
