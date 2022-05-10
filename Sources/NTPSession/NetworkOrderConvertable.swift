import Foundation

protocol NetworkOrderConvertible {
    var byteSwapped: Self { get }
}

private enum Endian {
    static let Little = CFByteOrder(CFByteOrderLittleEndian.rawValue)
    static var isLittle = CFByteOrderGetCurrent() == Endian.Little
}

extension NetworkOrderConvertible {
    var nativeEndian: Self {
        return Endian.isLittle ? byteSwapped : self
    }
}

extension Int: NetworkOrderConvertible {}

extension NTP.Time32: NetworkOrderConvertible {
    var byteSwapped: NTP.Time32 {
        return NTP.Time32(whole: whole.byteSwapped, fraction: fraction.byteSwapped)
    }
}

extension NTP.Time64: NetworkOrderConvertible {
    var byteSwapped: NTP.Time64 {
        return NTP.Time64(whole: whole.byteSwapped, fraction: fraction.byteSwapped)
    }
}

extension NTP.Packet: NetworkOrderConvertible {
    var byteSwapped: NTP.Packet {
        return NTP.Packet(
            flags: self.flags,
            stratum: self.stratum,
            poll: self.poll,
            precision: self.precision,
            rootDelay: self.rootDelay.byteSwapped,
            rootDispersion: self.rootDispersion.byteSwapped,
            referenceID: self.referenceID,
            referenceTime: self.referenceTime.byteSwapped,
            originateTime: self.originateTime.byteSwapped,
            transmitTime: self.transmitTime.byteSwapped,
            receiveTime: self.transmitTime.byteSwapped
        )
    }
}
