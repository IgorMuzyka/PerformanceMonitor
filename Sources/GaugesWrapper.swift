
import SwiftUI

struct GaugesWrapper<Content: View>: View {
    @Environment(\.scenePhase) private var scenePhase
    weak var monitor: PerformanceMonitor?
    let content: () -> Content
    var body: some View {
        content()
            .onAppear {
                monitor?.resume()
            }
            .onDisappear {
                monitor?.pause()
            }
            .onChange(of: scenePhase) { scenePhase in
                switch scenePhase {
                    case .active: monitor?.resume()
                    case .inactive: monitor?.pause()
                    case .background: monitor?.pause()
                    @unknown default: break
                }
            }
    }
}
