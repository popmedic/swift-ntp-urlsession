# swift-ntp

A Swift implementation of using URLSession for NTP.

## Example

```swift
// register NTP as a URL protocol
NTP.register
// create a URL request to a NTP server
let request = URL(string: "ntp://time.apple.com")!
// create a task using the NTP URL request
let task = URLSession.shared.dataTask(with: request) { data, _, error in
    // make sure there are no errors and data is not nil
    guard error == nil, let data = data else {
        fatelError("error shoul be nil not \"\(error!)\" and data should not be nil")
    }
    // read the bytes in data into a Date object
    let date = data.withUnsafeBytes { $0.load(as: Date.self) }
    // print the system current date and the date we just got
    print("Current Date = \(Date())")
    print("New Date     = \(date)")
}
```
