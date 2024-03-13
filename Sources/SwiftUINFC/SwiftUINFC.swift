import CoreNFC
import SwiftUI

public extension View {
    func nfcReader(isPresented: Binding<Bool>,
                   onSuccess: @escaping (([NFCNDEFMessage]) -> String),
                   onFailure: ((Error) -> String)? = nil) -> some View {
        self.modifier(NFCSheet(isPresented: isPresented, onSuccess: onSuccess, onFailure: onFailure))
    }
}

public struct NFCSheet: ViewModifier {
    
    @StateObject var nfcManager = NFCManager()
    
    @Binding var isPresented: Bool
    var onSuccess: (([NFCNDEFMessage]) -> String)
    var onFailure: ((Error) -> String)
    
    init(isPresented: Binding<Bool>,
         onSuccess: @escaping (([NFCNDEFMessage]) -> String),
         onFailure: ((Error) -> String)?) {
        
        if let onFailure {
            self.onFailure = onFailure
        } else {
            self.onFailure = { error in
                return "Error: \(error.localizedDescription)"
            }
        }
        self.onSuccess = onSuccess
        self._isPresented = isPresented
    }
    
    public func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .onChange(of: isPresented) { oldValue, newValue in
                    if newValue {
                        nfcManager.read()
                    }
                }
                .onAppear {
                    nfcManager.onResult = { [self] result in
                        isPresented = false
                        switch result {
                        case .success(let messages):
                            return self.onSuccess(messages)
                        case .failure(let error):
                            return self.onFailure(error)
                        }
                    }
                }
        } else {
            content
                .onChange(of: isPresented) { newValue in
                    if newValue {
                        nfcManager.read()
                    }
                }
                .onAppear {
                    nfcManager.onResult = { [self] result in
                        isPresented = false
                        switch result {
                        case .success(let messages):
                            return self.onSuccess(messages)
                        case .failure(let error):
                            return self.onFailure(error)
                        }
                    }
                }
        }
    }
}

class NFCManager: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    
    var session: NFCNDEFReaderSession?
    
    var onResult: ((Result<[NFCNDEFMessage], Error>) -> String?)?
    
    override init() {
        
    }
    
    func read() {
        guard NFCNDEFReaderSession.readingAvailable else {
            print("Unsupported device")
            return
        }
        
        session = NFCNDEFReaderSession(delegate: self, queue: .main, invalidateAfterFirstRead: true)
        
        session?.alertMessage = "Hold your device near the badge"
        session?.begin()
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        session.alertMessage = onResult?(.failure(error)) ?? "An error occurred"
    }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        
        if let result = onResult?(.success(messages)) {
            session.alertMessage = result
        } else {
            session.alertMessage = "Unable to read badge"
        }
        session.invalidate()
        self.session = nil
    }
}
