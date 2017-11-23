import Alamofire

class LineBotManager: NSObject {

    static func push(message: String) {
        
        Alamofire.request("https://api.line.me/v2/bot/message/push",
                          method: .post,
                          parameters: ["to" : "U98c6ba705ce8d73cdfe7198f02742977",
                            "messages":[["type":"text","text":"\(message)ニャン。"]]],
            encoding: JSONEncoding.default,
                          headers: ["Content-Type" : "application/json",
                                    "Authorization" : "Bearer KTElSimGOq79hyH3bn0kdHVxR8R4Bx0dSyhZKfM0Xr5DXAtrZRAUluw5DSaHCpTJC1KSsOhzaAHfrxtlTwKtt9g6krzDG5BAewFshRvUu1SaoajyhqjiP3ULRMWfXxvv6hK0V1p1oNvnq9Lxb5CASQdB04t89/1O/w1cDnyilFU="]
            ).responseJSON { response in
                print("Request: \(String(describing: response.request))")   // original url request
                print("Response: \(String(describing: response.response))") // http url response
                print("Result: \(response.result)")                         // response serialization result
                
                if let json = response.result.value {
                    print("JSON: \(json)") // serialized json response
                }
        }
    }
}
