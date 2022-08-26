//
//  NativeWebSocket.swift
//  SocketDemo
//
//  Created by Admin on 24/08/22.
//

import Foundation
import Starscream


protocol WebSocketProvider {
    func send(text: String)
    func send(data: Data)
    func connect(header:[String:String])
    func disconnect()
    var delegate: WebSocketProviderDelegate? {
        get
        set
    }
}


protocol WebSocketProviderDelegate{
    func webSocketDidConnect(connection: WebSocketProvider)
    func webSocketDisConnect(connection: WebSocketProvider, error: Error)
    func webSocketReceiveError(connection: WebSocketProvider, error: Error)
    func onResponseReceived(connection: WebSocketProvider, text: String)
    func onResponseReceived(connection: WebSocketProvider, data: Data)
   
}

@available(iOS 13.0, *)
class NativeWebSocket : NSObject , WebSocketProvider , URLSessionDelegate , URLSessionWebSocketDelegate{
     
    var delegate: WebSocketProviderDelegate?
    private var socket:URLSessionWebSocketTask!
    private var timeout:TimeInterval!
    private var url:URL!
    private(set) var isConnected:Bool = false

    init(url:URL,timeout:TimeInterval) {
        self.timeout        = timeout
        self.url            = url
        super.init()
    }
    
    // do not move create socket to init method because if you want to reconnect it never connect again
    public func connect(header:[String:String]) {
        let configuration                        = URLSessionConfiguration.default
        let urlSession                           = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue())
        var urlRequest                           = URLRequest(url: url,timeoutInterval: timeout)
        if  header.totalItems() > 0{
            for(key, value) in header{
                // Add the reqtype field and its value to the raw http request data
                urlRequest.addValue(value, forHTTPHeaderField: key)
               
            }
        }
    
        log(request: urlRequest)
        socket = urlSession.webSocketTask(with: urlRequest)
        socket.resume()
        receivedResponse()
    }
    
    func send(data: Data) {
       
        socket.send(.data(data)) { error in
            self.handleError(error)
        }
        receivedResponse()
    }
    
    func send(text: String) {
      
        socket.send(.string(text)) { error in
            self.handleError(error)
        }
        receivedResponse()
    }
    
    private func receivedResponse() {
        socket.receive { result in
            print(result)
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
                break
            case .success(let message):
                switch message {
                case .data(let data):
                    self.delegate?.onResponseReceived(connection: self, data: data)
                case .string(let string):
                    self.delegate?.onResponseReceived(connection: self, data: string.data(using: .utf8)!)
                @unknown default:
                    print("un implemented case found in NativeWebSocketProvider")
                }
                self.receivedResponse()
            }
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        isConnected = true
        delegate?.webSocketDidConnect(connection: self)
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isConnected = false
    }
    
    ///never call delegate?.webSocketDidDisconnect in this method it leads to close next connection
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            handleError(error)
        }
    }
    
    func disconnect() {
        socket.cancel(with: .goingAway, reason: nil)
    }
    
    /// we need to check if error code is one of the 57 , 60 , 54 timeout no network and internet offline to notify delegate we disconnected from internet
    private func handleError(_ error:Error?){
        if let error = error as NSError?{
            if error.code == 57  || error.code == 60 || error.code == 54{
                isConnected = false
             //   connect(header: [:])
                delegate?.webSocketDisConnect(connection: self, error: error)
            }else{
                delegate?.webSocketReceiveError(connection: self, error: error)
            }
        }
    }
}



extension Dictionary{
    func totalItems() -> Int {
        return values.count
    }
}

////MARK:- SERVER LOG INFO
func log(request: URLRequest){
    let urlString = request.url?.absoluteString ?? ""
    let components = NSURLComponents(string: urlString)
    
    let method = request.httpMethod != nil ? "\(request.httpMethod!)": ""
    let path = "\(components?.path ?? "")"
    let query = "\(components?.query ?? "")"
    let host = "\(components?.host ?? "")"
    
    var requestLog = "\n---------- OUT ---------->\n"
    requestLog += "\(urlString)"
    requestLog += "\n\n"
    requestLog += "\(method) \(path)?\(query) HTTP/1.1\n"
    requestLog += "Host: \(host)\n"
    for (key,value) in request.allHTTPHeaderFields ?? [:] {
        requestLog += "\(key): \(value)\n"
    }
    if let body = request.httpBody{
        let bodyString = NSString(data: body, encoding: String.Encoding.utf8.rawValue) ?? "Can't render body; not utf8 encoded";
        requestLog += "\n\(bodyString)\n"
    }
    
    requestLog += "\n------------------------->\n";
    print(requestLog)
}

