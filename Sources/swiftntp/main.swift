import Foundation
import NTPSession
import TSCBasic

// setup for color output
guard let tty = TerminalController(stream: stdoutStream) else {
    fatalError("unable to initialize terminal controller")
}

// register NTP as a URL protocol
NTP.register
// create a URL request to a NTP server
let request = URL(string: "ntp://time.apple.com")!
// create group to wait till done with task
let group = DispatchGroup()
// create a task using the NTP URL request
let task = URLSession.shared.dataTask(with: request) { data, _, error in
    // make sure there are no errors and data is not nil
    guard error == nil, let data = data else {
        fatalError("error should be nil not \"\(error!)\" and data should not be nil")
    }
    // read the bytes in data into a Date object
    let date = data.withUnsafeBytes { $0.load(as: Date.self) }
    // print the system current date and the date we just got
    print(tty.wrap("Localhost Date: \(Date().description(with: .current))", inColor: .cyan))
    print(tty.wrap("Apple.com Date: \(date.description(with: .current))", inColor: .green))
    group.leave()
}
// enter the group
group.enter()
// resume the task
task.resume()
// wait till response and printout
group.wait()
