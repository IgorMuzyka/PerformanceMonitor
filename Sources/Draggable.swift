
import SwiftUI

public struct Draggable<Content: View>: View  {
    @State private var location: CGPoint = CGPoint(x: 350, y: 350)
    @State public var color: Color

    private let content: (_ touch: CGPoint?) -> Content
    @GestureState private var fingerLocation: CGPoint? = .none
    @GestureState private var startLocation: CGPoint? = .none

    public init(
        location: CGPoint = .zero,
        color: Color = .clear,
        content: @escaping (_ touch: CGPoint?) -> Content
    ) {
        self.location = location
        self.content = content
        self.color = color
    }

    private var simpleDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                var newLocation = startLocation ?? location
                newLocation.x += value.translation.width
                newLocation.y += value.translation.height
                self.location = newLocation
            }
            .updating($startLocation) { value, startLocation, transaction in
                startLocation = startLocation ?? location
            }
    }

    private var fingerDrag: some Gesture {
        DragGesture()
            .updating($fingerLocation) { value, fingerLocation, transaction in
                fingerLocation = value.location
            }
    }

    public var body: some View {
        ZStack {
            content(fingerLocation)
                .position(location)
                .gesture(
                    simpleDrag.simultaneously(with: fingerDrag)
                )
            if let fingerLocation = fingerLocation {
                Circle()
                    .stroke(color, lineWidth: 2)
                    .frame(width: 44, height: 44)
                    .position(fingerLocation)
            }
        }
    }
}


