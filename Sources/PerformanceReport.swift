
import Foundation.NSProcessInfo

public struct PerformanceReport {
    public let uuid = UUID()
    public let cpuUsage: Double
    public struct MemoryUsage {
        public let used: UInt64
        public let total: UInt64
    }
    public let memoryUsage: MemoryUsage
    public let fps: Int
    public enum ThermalState: String, CaseIterable {
        case nominal = "Nominal"
        case fair = "Fair"
        case serious = "Serious"
        case critical = "Critical"
        case unknown = "Unknown"
        init(thermalState: ProcessInfo.ThermalState) {
            switch thermalState {
                case .nominal: self = .nominal
                case .fair: self = .fair
                case .serious: self = .serious
                case .critical: self = .critical
                @unknown default: self = .unknown
            }
        }
    }
    public let thermalState: ThermalState
}
