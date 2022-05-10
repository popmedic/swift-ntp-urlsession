import Foundation
import Network

public class NTP: URLProtocol {

    // MARK: - public static vars
    public static var register: Void { _ = registered }
    public static var registered: Bool = { registerClass() }()

    // MARK: - public class funcs
    override
    public class func canInit(with task: URLSessionTask) -> Bool {
        task.currentRequest?.url?.scheme?.lowercased() == "ntp"
    }

    override
    public class func canInit(with request: URLRequest) -> Bool {
        request.url?.scheme?.lowercased() == "ntp"
    }

    override
    public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    // MARK: - public overrides lifecycle
    override
    public init(request: URLRequest,
                cachedResponse: CachedURLResponse? = nil,
                client: URLProtocolClient? = nil) {
        super.init(request: request,
                   cachedResponse: cachedResponse,
                   client: client)
    }

    public convenience init(task: URLSessionTask,
                            cachedResponse: CachedURLResponse? = nil,
                            client: URLProtocolClient? = nil) {
        guard let request = task.currentRequest else {
            preconditionFailure("task must have a request")
        }
        self.init(request: request,
                  cachedResponse: cachedResponse,
                  client: client)
    }

    // MARK: - public overrides cotrol
    override
    public func startLoading() { ctrlQ.async { self.start() } }

    override
    public func stopLoading() { ctrlQ.async { self.connection.cancel() } }

    // MARK: - private vars
    private var endpoint: NWEndpoint!
    private var connection: NWConnection!
    private var startTime: TimeInterval = 0
    private var responseTime: TimeInterval = 0
    private var completed = false

    // MARK: - private lets
    private let ctrlQ = DispatchQueue(label: "\(NTP.self).connectionQ")
    private let connectionQ = DispatchQueue(label: "\(NTP.self).connectionQ")
    private let timeFrom1900to1970 = 2208988800.0 //((365 * 70) + 17) * 24 * 60 * 60
}

public extension NTP {

    // MARK: - errors
    enum Error: Swift.Error {
        case badNTPScheme
        case noURL
        case noHost
    }
}

private extension NTP {

    // MARK: - private class funcs
    class func registerClass() -> Bool { super.registerClass(NTP.self) }

    // MARK: - private funcs
    func endpoint(from: URL?) throws -> NWEndpoint {
        guard let url = request.url else { throw Error.noURL }
        guard let host = url.host else { throw Error.noHost }
        let port = url.port ?? 123
        return NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(
                rawValue: NWEndpoint.Port.RawValue(port)
            ) ?? 123
        )
    }
}

private extension NTP {

    func start() {
        do {
            let endpoint = try self.endpoint(from: request.url)
            let params = NWParameters.udp
            params.allowLocalEndpointReuse = true
            connection = NWConnection(to: endpoint, using: .udp)
            connection.receiveMessage { [weak self] in
                self?.receive($0, $1, $2, $3)
            }
            connection.stateUpdateHandler = { [weak self] state in
                self?.connectionChanged(to: state)
            }
            completed = false
            connection.start(queue: connectionQ)
            startTime = Date().timeIntervalSince1970
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    func receive(_ message: Data?,
                 _ context: NWConnection.ContentContext?,
                 _ isComplete: Bool,
                 _ error: NWError?) {
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        if let message = message {
            let packet = message.withUnsafeBytes { $0.load(as: Packet.self) }
                .nativeEndian
            let refTime = packet.referenceTime.timeInterval - timeFrom1900to1970
            let txTime = packet.transmitTime.timeInterval
            let rxTime = packet.receiveTime.timeInterval
            let time = refTime + (rxTime - txTime)
            var date = Date(timeIntervalSince1970: time)
            print(date)
            let data = Data(bytes: &date, count: MemoryLayout<TimeInterval>.size)
            client?.urlProtocol(self, didLoad: data)
        }
        if isComplete {
            completed = true
            responseTime = Date().timeIntervalSince1970
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    func connectionChanged(to state: NWConnection.State) {
        switch state {
        case .cancelled:
            self.client?.urlProtocolDidFinishLoading(self)
        case .failed(let error):
            self.client?.urlProtocol(self, didFailWithError: error)
        case .preparing:
            break
        case .ready:
            self.send(connection)
        case .setup:
            break
        case .waiting(let error):
            self.client?.urlProtocol(self, didFailWithError: error)
        @unknown default:
            fatalError()
        }
    }

    func send(_ connection: NWConnection) {
        connection.send(
            content: self.ntpRequest,
            completion: .contentProcessed({ [weak self] error in
                    self?.contentProcessed(error: error)
                }
            )
        )
    }

    func contentProcessed(error: NWError?) {
        if let error = error {
            self.client?.urlProtocol(self, didFailWithError: error)
            return
        }
    }

    var ntpRequest: Data {
        var timeval = Darwin.timeval()
        gettimeofday(&timeval, nil)
        precondition(timeval.tv_sec >= 0 && timeval.tv_usec >= 0, "Time must be positive \(timeval)")
        let whole = UInt32(Double(timeval.tv_sec) + timeFrom1900to1970)
        let frac = UInt32(UInt64(timeval.tv_usec) * UInt64(1<<32 / USEC_PER_SEC))
        let packet = Packet(
            stratum: 0,
            poll: 0,
            precision: 0,
            rootDelay: Time32(whole: 0, fraction: 0),
            rootDispersion: Time32(whole: 0, fraction: 0),
            referenceID: 0,
            referenceTime: Time64(whole: 0, fraction: 0),
            originateTime: Time64(whole: whole, fraction: frac),
            transmitTime: Time64(whole: 0, fraction: 0),
            receiveTime: Time64(whole: 0, fraction: 0)
        )
        var buffer = packet
        return Data(bytes: &buffer, count: MemoryLayout.size(ofValue: packet))
    }
}

extension NTP {

    struct Time32 {
        var whole: UInt16
        var fraction: UInt16
    }
    struct Time64 {
        var whole: UInt32
        var fraction: UInt32
    }

    struct Packet {
        var flags: UInt8 = 0b10011011

        var stratum: UInt8 = 0
        var poll: UInt8 = 0
        var precision: UInt8 = 0

        var rootDelay: Time32 = Time32(whole: 0, fraction: 0)
        var rootDispersion: Time32 = Time32(whole: 0, fraction: 0)
        var referenceID: UInt32 = 0

        var referenceTime: Time64 = Time64(whole: 0, fraction: 0)
        var originateTime: Time64 = Time64(whole: 0, fraction: 0)
        var transmitTime: Time64 = Time64(whole: 0, fraction: 0)
        var receiveTime: Time64 = Time64(whole: 0, fraction: 0)
    }
}

// MARK: - Timeable
protocol Timeable {
    associatedtype T: BinaryInteger
    var whole: T { get }
    var fraction: T { get }
}

extension Timeable {
    var timeInterval: TimeInterval {
        let string = "\(whole).\(fraction)"
        guard let double = Double(string) else { return TimeInterval(whole) }
        return TimeInterval(double)
    }
}

extension NTP.Time32: Timeable {}
extension NTP.Time64: Timeable {}
