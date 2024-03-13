# SwiftUI NFC

A dead simple SwiftUI NFC library
```swift
.nfcReader(isPresented: $isReaderPresented) { messages in
    //
    return "Successfully scanned badge" // This text will appear briefly on the NFC reader layer
} onFailure: { error in
    // Optional error handle
    print(error.localizedDescription)
    return "Error when scanning badge" // This text will appear briefly on the NFC reader layer
}
```
