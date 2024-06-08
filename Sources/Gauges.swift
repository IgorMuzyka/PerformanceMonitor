
import SwiftUI

struct Gauges: View {
    @EnvironmentObject private var reportObservable: ReportObservable
    @Environment(\.colorScheme) var colorScheme
    private var report: PerformanceReport? { reportObservable.report }
    let sizeClass: SizeClass

    internal init(sizeClass: SizeClass) {
        self.sizeClass = sizeClass
    }
    private var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }
    var body: some View {
        ZStack {
            if case .regular = sizeClass {
                Grid {
                    GridRow {
                        cpuAndMemory
                    }
                    GridRow {
                        thermalAndGraphics
                    }
                }
                .padding(3)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .circular))
            } else {
                HStack {
                    cpuAndMemory
                    thermalAndGraphics
                }
                .padding(3)
                .background(.ultraThinMaterial, in: Capsule(style: .continuous))
            }
        }
        .scaleEffect(sizeClass.scale, anchor: .center)
        .gaugeStyle(.accessoryCircular)
    }
    @ViewBuilder private var thermalAndGraphics: some View {
        if let report {
            fps(report.fps)
            thermalState(report.thermalState)
        }
    }
    @ViewBuilder private var cpuAndMemory: some View {
        if let report {
            cpu(report.cpuUsage)
            ram(report.memoryUsage)
        }
    }
    @ViewBuilder private func cpu(_ cpu: Double) -> some View {
        let colors: [Color] = [.blue, .green, .yellow, .orange, .pink]
        let bounds: ClosedRange<Double> = 0 ... 100
        let value = clamp(value: cpu, cap: 100)
        let color = stop(for: value, in: bounds, from: colors)
        Gauge(
            value: value,
            in: bounds,
            label: {
                Label("CPU", systemImage: "cpu")
            },
            currentValueLabel: { 
                Text("\(Int(cpu))%")
                    .foregroundColor(color)
            }
        )
        .tint(Gradient(colors: colors))
    }
    @ViewBuilder private func ram(_ usage: PerformanceReport.MemoryUsage) -> some View {
        let colors: [Color] = [.blue, .green, .yellow, .orange, .pink]
        let bounds = 0 ... Double(usage.total)
        let value = Double(clamp(value: usage.used, cap: usage.total))
        let text = formatter.string(fromByteCount: Int64(usage.used))
        let color = stop(for: value, in: bounds, from: colors)
        Gauge(
            value: value,
            in: bounds,
            label: {
                Label("RAM", systemImage: "memorychip")
            },
            currentValueLabel: {
                Text(text)
                    .foregroundColor(color)
            }
        )
        .tint(Gradient(colors: colors))
    }
    @ViewBuilder private func fps(_ fps: Int) -> some View {
        let colors: [Color] = [.blue, .green, .yellow, .orange, .pink]
        let bounds: ClosedRange<Int> = 0 ... maxFPS
        let value = clamp(value: fps, cap: bounds.upperBound)
        let color = stop(for: value, in: bounds, from: colors.reversed())
        Gauge(
            value: Double(value),
            in: 0 ... Double(maxFPS),
            label: {
                Label("FPS", systemImage: "display")
            },
            currentValueLabel: {
                Text("\(clamp(value: fps, cap: maxFPS))")
                    .foregroundColor(color)
            }
        )
        .tint(Gradient(colors: colors.reversed()))
    }
    @ViewBuilder private func thermalState(_ state: PerformanceReport.ThermalState) -> some View {
        let colors: [Color] = [.blue, .green, .orange, .pink]
        let bounds = PerformanceReport.ThermalState.nominal.float ... PerformanceReport.ThermalState.critical.float
        let value = state.float
        let color = stop(for: value, in: bounds, from: colors)
        Gauge(
            value: state.float,
            in: bounds,
            label: {
                #warning("symbol")
                Label("Thermal State", systemImage: state.symbol)
            },
            currentValueLabel: {
                Text(state.rawValue)
                    .foregroundColor(color)
            }
        )
        .tint(Gradient(colors: colors))
    }
}


#if os(macOS)
import CoreGraphics.CGDirectDisplay
#elseif os(iOS)
import UIKit.UIScreen
#endif

fileprivate extension Gauges {
    static var maxFPS: Int = {
        #if os(macOS)
        guard let mode = CGDisplayCopyDisplayMode(CGMainDisplayID()) else { return 0 }
        return Int(mode.refreshRate)
        #elseif os(iOS)
        return UIScreen.main.maximumFramesPerSecond
        #endif
    }()
    var maxFPS: Int { Self.maxFPS }
    static var byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter
    }()
    var formatter: ByteCountFormatter { Self.byteCountFormatter }
}

fileprivate extension PerformanceReport.ThermalState {
    var float: Float {
        switch self {
            case .nominal: return 0
            case .fair: return 1
            case .serious: return 2
            case .critical: return 3
            case .unknown: return -1
        }
    }
    var symbol: String {
        switch self {
            case .nominal: return "thermometer.snowflake"
            case .fair: return "thermometer.low"
            case .serious: return "thermometer.medium"
            case .critical: return "thermometer.high"
            case .unknown: return "questionmark"
        }
    }
}

fileprivate extension Gauges {
    func stop<Value: BinaryInteger & Comparable, Item>(
        for value: Value,
        in bounds: ClosedRange<Value>,
        from items: [Item]
    ) -> Item {
        let stop = remap(value: value, from: bounds, to: 0 ... Value(items.count - 1))
        let index = min(max(Int(stop), 0), items.count - 1)
        return items[index]
    }
    func stop<Value: BinaryFloatingPoint & Comparable, Item>(
        for value: Value,
        in bounds: ClosedRange<Value>,
        from items: [Item]
    ) -> Item {
        let stop = remap(value: value, from: bounds, to: 0 ... Value(items.count - 1))
        let index = min(max(Int(stop), 0), items.count - 1)
        return items[index]
    }
    func remap<Value: BinaryInteger & Comparable>(
        value: Value,
        from source: ClosedRange<Value>,
        to destination: ClosedRange<Value>
    ) -> Value {
        destination.lowerBound
            + (value - source.lowerBound)
            * (destination.upperBound - source.lowerBound)
            / (source.upperBound - source.lowerBound)
    }
    func remap<Value: FloatingPoint & Comparable>(
        value: Value,
        from source: ClosedRange<Value>,
        to destination: ClosedRange<Value>
    ) -> Value {
        destination.lowerBound
            + (value - source.lowerBound)
            * (destination.upperBound - source.lowerBound)
            / (source.upperBound - source.lowerBound)
    }
    func clamp<Value: Numeric & Comparable>(value: Value, cap: Value) -> Value {
        min(value, cap)
    }
}
