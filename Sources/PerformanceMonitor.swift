
import SwiftUI
import Combine

class PerformanceMonitor {
    private enum State {
        case active
        case paused
    }
    private var state: State = .paused
    public private(set) static var shared: PerformanceMonitor = .init()
    private let calculator: Calculator
    private var receiveingReport: AnyCancellable!
    public private(set) lazy var reportObservable: ReportObservable = { .init() }()
    public let presentationToggle: Notification.Name = .init("PerformanceMonitorPresentationToggle")
    public init(
        meteringTime: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(500),
        throttle: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(500)
    ) {
        calculator = Calculator(meteringTime: meteringTime)
        receiveingReport = calculator.report
            .receive(on: DispatchQueue.main)
            .throttle(for: throttle, scheduler: DispatchQueue.main, latest: true)
            .sink { [unowned self] report in
                guard state == .active else { return }
                reportObservable.assign(report)
            }
    }
    public var presentationTogglePublisher: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: presentationToggle)
    }
    public var togglePresentationAction: () -> Void {{ [weak self] in
        self?.togglePresentation()
    }}
    public func togglePresentation() {
        NotificationCenter.default.post(name: presentationToggle, object: .none)
    }
    public func resume() {
        guard state != .active else { return }
        state = .active
        calculator.resume()
    }
    public func pause() {
        guard state != .paused else { return }
        state = .paused
        calculator.pause()
    }
}
