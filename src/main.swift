import Foundation
import CoreMotion
import Network

// Get IP and Port
var UDP_IP: String
var UDP_PORT: UInt16

if CommandLine.arguments.count == 3 {
    // Use arguments if provided
    UDP_IP = CommandLine.arguments[1]
    guard let port = UInt16(CommandLine.arguments[2]) else {
        print("Invalid port number")
        exit(1)
    }
    UDP_PORT = port
} else {
    // Interactive mode if no args
    print("Enter target IP:", terminator: " ")
    guard let ipInput = readLine(), !ipInput.isEmpty else {
        print("No IP provided")
        exit(1)
    }
    UDP_IP = ipInput

    print("Enter target Port:", terminator: " ")
    guard let portInput = readLine(), let port = UInt16(portInput) else {
        print("Invalid port")
        exit(1)
    }
    UDP_PORT = port
}

print("Using IP: \(UDP_IP), Port: \(UDP_PORT)")

// UDP connection
let connection = NWConnection(
    host: NWEndpoint.Host(UDP_IP),
    port: NWEndpoint.Port(rawValue: UDP_PORT)!,
    using: .udp
)
connection.start(queue: .global())

let mgr = CMHeadphoneMotionManager()

mgr.startDeviceMotionUpdates(to: .main) { motion, error in
    guard let m = motion else { return }

    let attitude = m.attitude

    let yaw = attitude.yaw * 180.0 / .pi
    let pitch = attitude.pitch * 180.0 / .pi
    let roll = attitude.roll * 180.0 / .pi

    let data: [Double] = [0, 0, 0, yaw, pitch, roll]

    var buffer = Data(capacity: MemoryLayout<Double>.size * data.count)
    for value in data {
        var val = value
        buffer.append(UnsafeBufferPointer(start: &val, count: 1))
    }

    connection.send(content: buffer, completion: .contentProcessed { error in
        if let error = error {
            print("UDP send error:", error)
        }
    })

    print("Sent: \(data)")
}

RunLoop.main.run()

