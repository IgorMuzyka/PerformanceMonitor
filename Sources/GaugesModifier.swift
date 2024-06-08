
import SwiftUI

public extension View {
    func performanceMonitor(
        isPresented: Binding<Bool>,
        shakeGestureTogglesPresentation: Bool = true,
        sizeClass: SizeClass = .compact
    ) -> some View {
        modifier(GaugesModifier(
            isPresented: isPresented,
            sizeClass: sizeClass,
            shakeGestureTogglesPresentation: shakeGestureTogglesPresentation,
            menuItems: {}
        ))
    }
    func performanceMonitor<MenuItems: View>(
        isPresented: Binding<Bool>,
        sizeClass: SizeClass = .compact,
        shakeGestureTogglesPresentation: Bool = true,
        @ViewBuilder menuItems: @escaping () -> MenuItems?
    ) -> some View {
        modifier(GaugesModifier(
            isPresented: isPresented,
            sizeClass: sizeClass,
            shakeGestureTogglesPresentation: shakeGestureTogglesPresentation,
            menuItems: menuItems
        ))
    }
}

struct GaugesModifier<MenuItems: View>: ViewModifier {
    @Binding private var isPresented: Bool
    @State private var sizeClass: SizeClass
    @ViewBuilder private let menuItems: () -> MenuItems?
    private let shakeGestureTogglesPresentation: Bool
    init(
        isPresented: Binding<Bool>,
        sizeClass: SizeClass,
        shakeGestureTogglesPresentation: Bool,
        @ViewBuilder menuItems: @escaping () -> MenuItems?
    ) {
        _isPresented = isPresented
        self.sizeClass = sizeClass
        self.shakeGestureTogglesPresentation = shakeGestureTogglesPresentation
        self.menuItems = menuItems

    }
    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    GeometryReader { geometry in
                        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        Draggable(location: center) { touch in
                            GaugesWrapper(monitor: PerformanceMonitor.shared) {
                                Gauges(sizeClass: sizeClass)
                            }
                            .environmentObject(PerformanceMonitor.shared.reportObservable)
                            .allowsHitTesting(touch == .none)
                            .onTapGesture(count: 2) {
                                isPresented.toggle()
                            }
                            .contextMenu {
                                contextMenu
                            }
                        }
                    }
                    .transition(.opacity)
                    .animation(.default, value: isPresented)
                } else {
                    EmptyView()
                }
            }
            .onShake {
                guard shakeGestureTogglesPresentation else { return }
                withAnimation(.default) {
                    isPresented.toggle()
                }
            }
            .onReceive(PerformanceMonitor.shared.presentationTogglePublisher) { _ in
                withAnimation(.default) {
                    isPresented.toggle()
                }
            }
    }
    @ViewBuilder private var contextMenu: some View {
        if let menuItems = menuItems() {
            menuItems
            Divider()
        }
        Button {
            guard let previous = sizeClass.previous() else { return }
            withAnimation(.default) {
                sizeClass = previous
            }
        } label: {
            Label("Zoom -", systemImage: "minus.circle")
        }
        .disabled(sizeClass.previous() == .none)
        Button {
            guard let next = sizeClass.next() else { return }
            withAnimation(.default) {
                sizeClass = next
            }
        } label: {
            Label("Zoom +", systemImage: "plus.circle")
        }
        .disabled(sizeClass.next() == .none)
    }
}
