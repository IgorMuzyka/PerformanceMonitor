
import SwiftUI

public class ReportObservable: ObservableObject {
    @Published public private(set) var report: PerformanceReport?
    internal func assign(_ report: PerformanceReport) {
        self.report = report
    }
}
