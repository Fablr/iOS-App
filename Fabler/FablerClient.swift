//
//  FablerClient.swift
//  Fabler
//
//  Created by Christopher Day on 10/28/15.
//  Copyright © 2015 AppCoda. All rights reserved.
//

import Alamofire

// MARK: - FablerClient

struct FablerClient {
    enum Router: URLRequestConvertible {
        static let baseURLString = "http://api.fablersite-dev.elasticbeanstalk.com"
        static var OAuthToken: String?

        case FacebookLogin(token:String)
        case ReadPodcasts()

        var method: Alamofire.Method {
            switch self {
            case .FacebookLogin:
                return .GET
            case .ReadPodcasts:
                return .GET
            }
        }

        var path: String {
            switch self {
            case .FacebookLogin:
                return "/facebook/"
            case .ReadPodcasts:
                return "/podcast/"
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
            default:
                return mutableURLRequest
            }
        }
    }
}

// MARK: - Alamofire.Request extension

public protocol ResponseObjectSerializable {
    init?(response: NSHTTPURLResponse, representation: AnyObject)
}

public protocol ResponseCollectionSerializable {
    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [Self]
}

extension Alamofire.Request {
    public func responseObject<T: ResponseObjectSerializable>(completionHandler: Response<T, NSError> -> Void) -> Self {
        let responseSerializer = ResponseSerializer<T, NSError> { request, response, data, error in
            guard error == nil else { return .Failure(error!) }

            let JSONSerializer = Request.JSONResponseSerializer(options: .AllowFragments)
            let result = JSONSerializer.serializeResponse(request, response, data, error)

            switch result {
            case .Success(let value):
                if let response = response,
                    responseObject = T(response: response, representation: value)
                {
                    return .Success(responseObject)
                } else {
                    let failureReason = "JSON could not be serialized into response object: \(value)"
                    let error = Error.errorWithCode(.JSONSerializationFailed, failureReason: failureReason)
                    return .Failure(error)
                }
            case .Failure(let error):
                return .Failure(error)
            }
        }

        return response(responseSerializer: responseSerializer, completionHandler: completionHandler)
    }

    public func responseCollection<T: ResponseCollectionSerializable>(completionHandler: Response<[T], NSError> -> Void) -> Self {
        let responseSerializer = ResponseSerializer<[T], NSError> { request, response, data, error in
            guard error == nil else { return .Failure(error!) }

            let JSONSerializer = Request.JSONResponseSerializer(options: .AllowFragments)
            let result = JSONSerializer.serializeResponse(request, response, data, error)

            switch result {
            case .Success(let value):
                if let response = response {
                    return .Success(T.collection(response: response, representation: value))
                } else {
                    let failureReason = "Response collection could not be serialized due to nil response"
                    let error = Error.errorWithCode(.JSONSerializationFailed, failureReason: failureReason)
                    return .Failure(error)
                }
            case .Failure(let error):
                return .Failure(error)
            }
        }

        return response(responseSerializer: responseSerializer, completionHandler: completionHandler)
    }
}
