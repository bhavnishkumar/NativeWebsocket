//
//  SwiftWebSocketClient.swift
//  SocketDemo
//
//  Created by Admin on 24/08/22.
//

import Foundation

var token = "eyJhbGciOiJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzA0L3htbGRzaWctbW9yZSNobWFjLXNoYTM4NCIsInR5cCI6IkpXVCJ9.eyJ1c2VyIjoiMSIsImp0aSI6IjMwZmI3OWM4LTg5ZmQtNGQ4My05NTlhLTllYTJiZWJiM2ZiNCIsImVtYWlsIjoicmFodWwua2Fwb29yQGFwcGludmVudGl2LmNvbSIsImlhdCI6IjA4LzI1LzIwMjIgMTM6MTI6NDQiLCJuYmYiOjE2NjE0MzMxNjQsImV4cCI6MTk3NzA1MjM2NCwiaXNzIjoiVEVTVF9Jc3N1ZXIiLCJhdWQiOiJURVNUX0F1ZGllbmNlIn0.NLaNvb8kwT3lQhmdN4GPmUmn3UYLeHYyDvxR2e394BCJ0Ai9OJ6a2f-wM_wN9NB2"

final class WebSocketClient: NSObject {
    
    static let shared = WebSocketClient()
    var webSocket: URLSessionWebSocketTask?
    
    var opened = false
    var connectionId = -1
    private var urlString = "wss://e5c4-101-0-38-50.in.ngrok.io/ws"
    
    private override init() {
        // no-op
    }
    
    func subscribeToService(with completion: @escaping (String?) -> Void) {
        if !opened {
            openWebSocket()
        }
        
        guard let webSocket = webSocket else {
            completion(nil)
            return
        }
        
        webSocket.receive(completionHandler: { [weak self] result in
            
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
                completion(nil)
            case .success(let webSocketTaskMessage):
                switch webSocketTaskMessage {
                case .string(let str):
                    print(str)
                    completion(nil)
                case .data(let data):
                    
                    print(data.toString())
                    completion(nil)
                default:
                    fatalError("Failed. Received unknown data format. Expected String")
                }
            }
            
        })
    }
    
    
    //MARK:- Send Message to Server
    func sendMessagetoServer(message:String?,completion: @escaping (String?) -> Void) {
        if !opened {
            openWebSocket()
        }
        guard let webSocket = webSocket else {
            return
        }
        
        if let messsageStr = message {
            webSocket.send(URLSessionWebSocketTask.Message.string(messsageStr)) { error in
                if let error = error {
                    print("Failed with Error \(error.localizedDescription)")
                }
            }
            
            webSocket.receive(completionHandler: { [weak self] result in
                
                guard let self = self else { return }
                
                switch result {
                case .failure(let error):
                    print(error.localizedDescription)
                    completion(nil)
                case .success(let webSocketTaskMessage):
                    switch webSocketTaskMessage {
                    case .string(let str):
                        print(str)
                        completion(nil)
                    case .data(let data):
                        
                        
                        completion(nil)
                    default:
                        fatalError("Failed. Received unknown data format. Expected String")
                    }
                }
            })
            
            
        } else {
            completion(nil)
        }
    }
    //MARK:- Connect With Server
    private func openWebSocket() {
        if let url = URL(string: urlString) {
            var request = URLRequest(url: url)
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
            let webSocket = session.webSocketTask(with: request)
            self.webSocket = webSocket
            
            
            self.webSocket?.resume()
        } else {
            webSocket = nil
        }
    }
    
    func closeSocket() {
        webSocket?.cancel(with: .goingAway, reason: nil)
        opened = false
        webSocket = nil
    }
    
    
}

extension WebSocketClient: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        opened = true
    }
    
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        self.webSocket = nil
        self.opened = false
        print(reason?.toString())
    }
}







extension Data{
    func toString() -> String?
    {
        return String(data: self, encoding: .utf8)
    }
}
