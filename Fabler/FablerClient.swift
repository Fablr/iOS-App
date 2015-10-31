//
//  FablerClient.swift
//  Fabler
//
//  Created by Christopher Day on 10/28/15.
//  Copyright © 2015 AppCoda. All rights reserved.
//

import Alamofire

struct FablerClient {
    enum Router: URLRequestConvertible {
        static let baseURLString = "http://api.fablersite-dev.elasticbeanstalk.com"
        static var OAuthToken: String?

        case FacebookLogin(token:String)

        var method: Alamofire.Method {
            switch self {
            case .FacebookLogin:
                return .GET
            }
        }

        var path: String {
            switch self {
            case .FacebookLogin:
                return "/facebook/"
            }
        }

        var URLRequest: NSMutableURLRequest {
            let URL = NSURL(string: Router.baseURLString)!
            let mutableURLRequest = NSMutableURLRequest(URL: URL.URLByAppendingPathComponent(path))
            mutableURLRequest.HTTPMethod = method.rawValue

            if let token = Router.OAuthToken {
                mutableURLRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            switch self {
            case .FacebookLogin(let token):
                let parameters = ["access_token": token]
                return Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: parameters).0
            }
        }
    }
}
