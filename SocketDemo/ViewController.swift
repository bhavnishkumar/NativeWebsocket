//
//  ViewController.swift
//  SocketDemo
//
//  Created by Admin on 24/08/22.
//

import UIKit

// MARK: - PayloadModel
struct PayloadModel: Codable {
    let courseID, reviewID, webSocketCallType: Int

    enum CodingKeys: String, CodingKey {
        case courseID = "CourseId"
        case reviewID = "ReviewId"
        case webSocketCallType
    }
}


/*
 val WEB_SOCKET_ADD_LIKE_DISLIKE = "wss://api-qa.skillfy.in/api/WebSocket/LikeDislike"
 Web sockets work is deployed for Like Dislike
 URL: wss://api-qa.skillfy.in/api/WebSocket/LikeDislike
 Please add the token in the header while making the connection otherwise you will get a 401 error
 Payload:
 {
     "CourseId":1,
     "ReviewId":1,
     "webSocketCallType":0,1
 }

 Constants:
 webSocketCallType:
     LikeReview = 0,
     DisLikeReview = 1
 */




class ViewController: UIViewController {
    
    @IBOutlet weak var statusBtn: UIButton!
   // let webSocket = WebSocketClient.shared
    let websocket =  NativeWebSocket.init(url: URL.init(string: "wss://api-qa.skillfy.in/api/WebSocket/LikeDislike")!, timeout: TimeInterval.infinity)
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        websocket.delegate = self
        websocket.connect(header: ["Authorization":"Bearer \(token)"])
        
        
    }
    
//    @IBAction func statusBtnAction(_ sender: UIButton) {
//
//        if  statusBtn.titleLabel?.text! == "Connect"{
//            webSocket.subscribeToService { stockValue in
//                DispatchQueue.main.async {
//                    if self.webSocket.opened{
//                    self.statusBtn.setTitle("Disconnect", for: .normal)
//                    }
//                }
//
//                guard let stockValue = stockValue else {
//                    return
//                }
//            }
//        }else{
//            self.webSocket.closeSocket()
//            self.statusBtn.setTitle("Connect", for: .normal)
//        }
//    }
    
    
    @IBAction func sendDataBtn(_ sender: Any) {
        
 
     
       
        do {
            let data = try JSONEncoder().encode(PayloadModel.init(courseID: 1, reviewID: 1, webSocketCallType: 1))
            if websocket.isConnected{
               websocket.send(data: data)
            }
        } catch let error {
            print(error.localizedDescription)
        }
       
        
    }

    
    
    
}

extension ViewController:WebSocketProviderDelegate{
    func webSocketDidConnect(connection: WebSocketProvider) {
        print("Websocket connected")
    }
    
    func webSocketDisConnect(connection: WebSocketProvider, error: Error) {
        print("Websocket disconnect \(error.localizedDescription)")
    }
    
    func webSocketReceiveError(connection: WebSocketProvider, error: Error) {
        print("Websocket received error \(error.localizedDescription)")
    }
    
    func onResponseReceived(connection: WebSocketProvider, text: String) {
        print("received response:\(text)")
    }
    
    func onResponseReceived(connection: WebSocketProvider, data: Data) {
        print("received response:\(data.toString() ?? "")")
    }
    
    
    
    
}

