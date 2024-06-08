
import Foundation
import Combine
import DisplayLink

// MARK: - Calculator
final class Calculator {
    public let meteringTime: DispatchQueue.SchedulerTimeType.Stride
    public let report = PassthroughSubject<PerformanceReport, Never>()
    private let linkedFrameList = LinkedFramesList()
    private var displayLink: DisplayLink
    private var receiveFrame: AnyCancellable!
    private var metrics: AnyCancellable!

    init(meteringTime: DispatchQueue.SchedulerTimeType.Stride) {
        self.meteringTime = meteringTime
        displayLink = .init()
        bindDisplayLink()
    }
    private func bindDisplayLink() {
        receiveFrame = displayLink.frameSubject.sink(receiveValue: { [weak self] in
            self?.linkedFrameList.append(frameWithTimestamp: $0)
        })
        metrics = displayLink.frameSubject
            .throttle(for: meteringTime, scheduler: DispatchQueue.main, latest: true)
            .sink(receiveValue: { [weak self] _ in
                self?.collectMetrics()
            })
    }
    // MARK: - Execution control
    func resume() {
        displayLink.activate()
    }
    func pause() {
        displayLink = .init()
        bindDisplayLink()
    }
    // MARK: - Monitoring
    private var now: CFTimeInterval {
        Double(DispatchTime.now().uptimeNanoseconds) / Double(NSEC_PER_SEC) /// = `1_000_000_000`
    }
    private func collectMetrics() {
        report.send(.init(
            cpuUsage: cpuUsage(),
            memoryUsage: memoryUsage(),
            fps: fps(),
            thermalState: thermalState()
        ))
    }
}
// MARK: - CPU Usage
extension Calculator {
    func cpuUsage() -> Double {
        var totalUsageOfCPU: Double = 0.0
        var threadsList: thread_act_array_t?
        var threadsCount = mach_msg_type_number_t(0)
        let threadsResult = withUnsafeMutablePointer(to: &threadsList) {
            return $0.withMemoryRebound(to: thread_act_array_t?.self, capacity: 1) {
                task_threads(mach_task_self_, $0, &threadsCount)
            }
        }
        if threadsResult == KERN_SUCCESS, let threadsList = threadsList {
            for index in 0..<threadsCount {
                var threadInfo = thread_basic_info()
                var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
                let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        thread_info(threadsList[Int(index)], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                    }
                }
                guard infoResult == KERN_SUCCESS else {
                    break
                }
                let threadBasicInfo = threadInfo as thread_basic_info
                if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                    totalUsageOfCPU = (totalUsageOfCPU + (Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0))
                }
            }
        }
        vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: threadsList)), vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride))
        return totalUsageOfCPU
    }
}
// MARK: - FPS
extension Calculator {
    func fps() -> Int {
        linkedFrameList.count
    }
}
// MARK: - Memory Usage
extension Calculator {
    func memoryUsage() -> PerformanceReport.MemoryUsage {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        var used: UInt64 = 0
        if result == KERN_SUCCESS {
            used = UInt64(taskInfo.phys_footprint)
        }
        let total = ProcessInfo.processInfo.physicalMemory
        return .init(used: used, total: total)
    }
}
// MARK: - Thermal State
extension Calculator {
    func thermalState() -> PerformanceReport.ThermalState {
        .init(thermalState: ProcessInfo.processInfo.thermalState)
    }
}
