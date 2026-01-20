import Foundation

// MARK: - Environment Snapshot

/// A snapshot of the execution environment at the time of a benchmark run.
///
/// `EnvironmentSnapshot` captures device information, system version, locale,
/// and application metadata. Use this to understand the context in which a
/// benchmark was executed.
///
/// ## Example
///
/// ```swift
/// let environment = EnvironmentSnapshot.capture()
/// print("Running on \(environment.deviceName) with \(environment.systemName) \(environment.systemVersion)")
/// ```
public struct EnvironmentSnapshot: Codable, Sendable {
    /// The name of the device where the benchmark was run.
    public let deviceName: String

    /// The name of the operating system (e.g., "macOS", "iOS", "visionOS").
    public let systemName: String

    /// The version of the operating system.
    public let systemVersion: String

    /// The locale identifier (e.g., "en_US").
    public let localeIdentifier: String

    /// The application version string, if available.
    public let appVersion: String?

    /// The application build number, if available.
    public let buildNumber: String?

    /// The hardware model identifier, if available.
    public let hardwareModel: String?

    /// The CPU/chip model name (e.g., "Apple M5").
    public let cpuModel: String?

    /// The number of CPU cores.
    public let cpuCores: Int?

    /// The GPU/chip model name (e.g., "Apple M5 10-core").
    public let gpuModel: String?

    /// The total physical memory in bytes.
    public let totalMemory: UInt64?

    /// The timestamp when the snapshot was captured.
    public let timestamp: Date

    /// Creates a new environment snapshot with the specified values.
    ///
    /// - Parameters:
    ///   - deviceName: The name of the device.
    ///   - systemName: The name of the operating system (e.g., "macOS", "iOS").
    ///   - systemVersion: The version of the operating system.
    ///   - localeIdentifier: The locale identifier (e.g., "en_US").
    ///   - appVersion: The application version string, if available.
    ///   - buildNumber: The application build number, if available.
    ///   - hardwareModel: The hardware model identifier, if available.
    ///   - cpuModel: The CPU/chip model name.
    ///   - cpuCores: The number of CPU cores.
    ///   - gpuModel: The GPU/chip model name.
    ///   - totalMemory: The total physical memory in bytes.
    ///   - timestamp: The timestamp for the snapshot. Defaults to the current date.
    public init(
        deviceName: String,
        systemName: String,
        systemVersion: String,
        localeIdentifier: String,
        appVersion: String?,
        buildNumber: String?,
        hardwareModel: String?,
        cpuModel: String?,
        cpuCores: Int?,
        gpuModel: String?,
        totalMemory: UInt64?,
        timestamp: Date = Date()
    ) {
        self.deviceName = deviceName
        self.systemName = systemName
        self.systemVersion = systemVersion
        self.localeIdentifier = localeIdentifier
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.hardwareModel = hardwareModel
        self.cpuModel = cpuModel
        self.cpuCores = cpuCores
        self.gpuModel = gpuModel
        self.totalMemory = totalMemory
        self.timestamp = timestamp
    }

    /// Captures the current execution environment.
    ///
    /// This method automatically detects device information, system version,
    /// locale, and application metadata from the current process and bundle.
    ///
    /// - Parameter bundle: The bundle to read application metadata from.
    ///   Defaults to `.main`.
    /// - Returns: An `EnvironmentSnapshot` containing the current environment
    ///   information.
    public static func capture(bundle: Bundle = .main) -> EnvironmentSnapshot {
        let processInfo = ProcessInfo.processInfo
        let osVersion = processInfo.operatingSystemVersion
        let versionString = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        let localeIdentifier = Locale.current.identifier
        let deviceName = processInfo.hostName

        let hardwareModel = processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"]

        #if os(macOS)
        let systemName = "macOS"
        let (cpuModel, cpuCores) = gatherMacOSHardwareInfo()
        let gpuModel = getMacGPUModelImpl()
        var totalMemory: UInt64?
        var memsize: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        if sysctlbyname("hw.memsize", &memsize, &size, nil, 0) == 0 {
            totalMemory = memsize
        }
        #elseif os(iOS)
        let systemName = "iOS"
        let cpuModel = processInfo.processorCount > 0 ? "Apple A-series" : nil
        let cpuCores = processInfo.processorCount
        let gpuModel = "Apple GPU"
        let totalMemory = processInfo.physicalMemory
        #elseif os(visionOS)
        let systemName = "visionOS"
        let cpuModel = processInfo.processorCount > 0 ? "Apple R-series" : nil
        let cpuCores = processInfo.processorCount
        let gpuModel = "Apple GPU"
        let totalMemory = processInfo.physicalMemory
        #else
        let systemName = processInfo.operatingSystemVersionString
        let cpuModel: String? = nil
        let cpuCores: Int? = nil
        let gpuModel: String? = nil
        let totalMemory: UInt64? = nil
        #endif

        let (shortVersion, buildNumber) = bundleMetadata(bundle: bundle)

        return EnvironmentSnapshot(
            deviceName: deviceName,
            systemName: systemName,
            systemVersion: versionString,
            localeIdentifier: localeIdentifier,
            appVersion: shortVersion,
            buildNumber: buildNumber,
            hardwareModel: hardwareModel,
            cpuModel: cpuModel,
            cpuCores: cpuCores,
            gpuModel: gpuModel,
            totalMemory: totalMemory,
            timestamp: Date()
        )
    }

    /// Extracts metadata from a bundle
    private static func bundleMetadata(bundle: Bundle) -> (String?, String?) {
        let shortVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let buildNumber = bundle.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
        return (shortVersion, buildNumber)
    }

    #if os(macOS)
    /// Gathers hardware information for macOS systems
    private static func gatherMacOSHardwareInfo() -> (String?, Int?) {
        // Get CPU information
        var cpuModel: String?
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        if size > 0 {
            var cpuBrand = [CChar](repeating: 0, count: size)
            sysctlbyname("machdep.cpu.brand_string", &cpuBrand, &size, nil, 0)
            cpuModel = String(cString: cpuBrand)
        }

        // Get CPU core count
        var cpuCores: Int?
        var ncpu: Int32 = 0
        size = MemoryLayout<Int32>.size
        if sysctlbyname("hw.ncpu", &ncpu, &size, nil, 0) == 0 {
            cpuCores = Int(ncpu)
        }

        return (cpuModel, cpuCores)
    }
    #endif

    /// Helper function to get Mac GPU model using system_profiler
    #if os(macOS)
    private static func getMacGPUModelImpl() -> String? {
        do {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/system_profiler")
            task.arguments = ["SPDisplaysDataType", "-json"]

            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = FileHandle.nullDevice  // Suppress stderr

            try task.run()  // Use run() instead of launch() - it throws Swift errors
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let hardwareData = json["SPDisplaysDataType"] as? [[String: Any]],
               let firstDisplay = hardwareData.first,
               let chipName = firstDisplay["sppci_model"] as? String ?? firstDisplay["sp_item_name"] as? String {
                return chipName
            }
        } catch {
            // Silently fail if system_profiler is not available or fails (e.g., sandboxed environment)
            return nil
        }

        return nil
    }
    #endif
}
