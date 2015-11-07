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
        case ReadSubscribedPodcasts()
        case ReadEpisodesForPodcast(podcast:Int)

        var method: Alamofire.Method {
            switch self {
            case .FacebookLogin:
                return .GET
            case .ReadPodcasts:
                return .GET
            case .ReadSubscribedPodcasts:
                return .GET
            case .ReadEpisodesForPodcast:
                return .GET
            }
        }

        var path: String {
            switch self {
            case .FacebookLogin:
                return "/facebook/"
            case .ReadPodcasts:
                return "/podcast/"
            case .ReadSubscribedPodcasts:
                return "/get-subscribed-podcasts/"
            case .ReadEpisodesForPodcast:
                return "/episode/"
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
            case .ReadEpisodesForPodcast(let podcast):
                let parameters = ["podcast": podcast]
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

// MARK: - String extension

extension String {
    func toBool() -> Bool? {
        switch self {
        case "True", "true", "yes", "1":
            return true
        case "False", "false", "no", "0":
            return false
        default:
            return nil
        }
    }

    func toNSTimeInterval() -> NSTimeInterval {
        var result: NSTimeInterval

        result = 0

        let tokens = self.componentsSeparatedByString(":")

        switch tokens.count {
        case 1:
            if let seconds = Int(tokens[0]) {
                result = Double(seconds)
            }
        case 2:
            if let minutes = Int(tokens[0]), seconds = Int(tokens[1]) {
                result = Double((minutes * 60) + seconds)
            }
        case 3:
            if let hours = Int(tokens[0]), minutes = Int(tokens[1]), seconds = Int(tokens[2]) {
                result = Double((hours * 60 * 60) + (minutes * 60) + seconds)
            }
        default:
            break
        }

        return result
    }

    func toNSDate() -> NSDate? {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter.dateFromString(self)
    }
}
