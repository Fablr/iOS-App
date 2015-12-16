//
//  FablerClient.swift
//  Fabler
//
//  Created by Christopher Day on 10/28/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import Alamofire
import SwiftyJSON
import Foundation
import RealmSwift

// MARK: - FablerClient

// swiftlint:disable nesting
// swiftlint:disable variable_name

struct FablerClient {
    enum Router: URLRequestConvertible {
        static let baseURLString = "http://api.fablersite-dev.elasticbeanstalk.com"
        static var token: String?

        case FacebookLogin(token: String)
        case ReadPodcasts()
        case ReadPodcast(podcast: Int)
        case ReadSubscribedPodcasts()
        case ReadEpisodesForPodcast(podcast: Int)
        case SubscribeToPodcast(podcast: Int, subscribe: Bool)
        case ReadCurrentUser()
        case UpdateEpisodeMark(episode: Int, mark: NSTimeInterval, completed: Bool)
        case ReadCommentsForEpisode(episode: Int)
        case AddCommentForEpisode(episode: Int, comment: String, parent: Int?)
        case ReadCommentsForPodcast(podcast: Int)
        case AddCommentForPodcast(podcast: Int, comment: String, parent: Int?)
        case VoteComment(comment: Int, vote: Int)
        case ReadUser(user: Int)
        case ReadEpisode(episode: Int)
        case DeleteComment(comment: Int)
        case EditComment(comment: Int, newComment: String)

        var method: Alamofire.Method {
            switch self {
            case .FacebookLogin:
                return .GET
            case .ReadPodcasts:
                return .GET
            case .ReadPodcast:
                return .GET
            case .ReadSubscribedPodcasts:
                return .GET
            case .ReadEpisodesForPodcast:
                return .GET
            case .SubscribeToPodcast:
                return .POST
            case .ReadCurrentUser:
                return .GET
            case .UpdateEpisodeMark:
                return .POST
            case .ReadCommentsForEpisode:
                return .GET
            case .AddCommentForEpisode:
                return .POST
            case .ReadCommentsForPodcast:
                return .GET
            case .AddCommentForPodcast:
                return .POST
            case .VoteComment:
                return .POST
            case .ReadUser:
                return .GET
            case .ReadEpisode:
                return .GET
            case .DeleteComment:
                return .DELETE
            case .EditComment:
                return .PUT
            }
        }

        var path: String {
            switch self {
            case .FacebookLogin:
                return "/facebook/"
            case .ReadPodcasts:
                return "/podcast/"
            case .ReadPodcast(let podcast):
                return "/podcast/\(podcast)/"
            case .ReadSubscribedPodcasts:
                return "/podcast/subscribed/"
            case .ReadEpisodesForPodcast:
                return "/episode/"
            case .SubscribeToPodcast:
                return "/subscription/"
            case .ReadCurrentUser:
                return "/userprofile/current/"
            case .UpdateEpisodeMark:
                return "/episodereceipt/"
            case .ReadCommentsForEpisode(let episode):
                return "/episode/\(episode)/comments/"
            case .AddCommentForEpisode(let episode, _, _):
                return "/episode/\(episode)/comments/"
            case .ReadCommentsForPodcast(let podcast):
                return "/podcast/\(podcast)/comments/"
            case .AddCommentForPodcast(let podcast, _, _):
                return "/podcast/\(podcast)/comments/"
            case .VoteComment:
                return "/vote/"
            case .ReadUser(let user):
                return "/userprofile/\(user)/"
            case .ReadEpisode(let episode):
                return "/episode/\(episode)/"
            case .DeleteComment(let comment):
                return "/comment/\(comment)/"
            case .EditComment(let comment, _):
                return "/comment/\(comment)/"
            }
        }

        var URLRequest: NSMutableURLRequest {
            let URL = NSURL(string: Router.baseURLString)!
            let mutableURLRequest = NSMutableURLRequest(URL: URL.URLByAppendingPathComponent(path))
            mutableURLRequest.HTTPMethod = method.rawValue

            if let token = Router.token {
                mutableURLRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            switch self {
            case .FacebookLogin(let token):
                let parameters: [String: AnyObject] = ["access_token": token]
                return Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: parameters).0
            case .ReadEpisodesForPodcast(let podcast):
                let parameters: [String: AnyObject] = ["podcast": podcast]
                return Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: parameters).0
            case .SubscribeToPodcast(let podcast, let subscribe):
                let parameters: [String: AnyObject] = ["podcast": podcast, "active": subscribe]
                return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
            case .UpdateEpisodeMark(let episode, let mark, let completed):
                let parameters: [String: AnyObject] = ["episode": episode, "mark": mark.toString(), "completed": completed]
                return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
            case .AddCommentForEpisode(_, let comment, let parent):
                var parameters: [String: AnyObject] = ["comment": comment]
                if parent != nil {
                    parameters["parent"] = parent!
                }
                return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
            case .AddCommentForPodcast(_, let comment, let parent):
                var parameters: [String: AnyObject] = ["comment": comment]
                if parent != nil {
                    parameters["parent"] = parent!
                }
                return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
            case .VoteComment(let comment, let vote):
                let parameters: [String: AnyObject] = ["comment": comment, "value": vote]
                return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
            case .EditComment(_, let newComment):
                let parameters: [String: AnyObject] = ["comment": newComment]
                return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
            default:
                return mutableURLRequest
            }
        }
    }
}

// MARK: - Alamofire.Request extension

extension Alamofire.Request {
    public static func SwiftyJSONResponseSerializer(options: NSJSONReadingOptions = .AllowFragments) -> ResponseSerializer<JSON, NSError> {
        return ResponseSerializer { _, _, data, error in
            guard error == nil else { return .Failure(error!) }

            guard let validData = data where validData.length > 0 else {
                let failureReason = "JSON could not be serialized. Input data was nil or zero length."
                let error = Error.errorWithCode(.JSONSerializationFailed, failureReason: failureReason)
                return .Failure(error)
            }

            let json: JSON = SwiftyJSON.JSON(data: validData)
            if let jsonError = json.error {
                return Result.Failure(jsonError)
            }

            return Result.Success(json)
        }
    }

    public func responseSwiftyJSON(options: NSJSONReadingOptions = .AllowFragments, completionHandler: Response<JSON, NSError> -> Void) -> Self {
        return response(
            queue: dispatch_get_global_queue(QOS_CLASS_UTILITY, 0),
            responseSerializer: Request.SwiftyJSONResponseSerializer(options),
            completionHandler: completionHandler
        )
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
            Log.warning("String \(self) was unable to be parsed into NSTimeInterval.")
            break
        }

        return result
    }

    func toNSDate() -> NSDate? {
        var result: NSDate?

        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        result = dateFormatter.dateFromString(self)

        if result == nil {
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
            result = dateFormatter.dateFromString(self)
        }

        return result
    }
}

extension NSTimeInterval {
    func toString() -> String {
        var result: String

        let days = Int(floor(self / (60 * 60 * 24)))
        var remainder = Int(floor(self % (60 * 60 * 24)))
        let hours = Int(remainder / (60 * 60))
        remainder = Int(remainder % (60 * 60))
        let minutes = Int(remainder / 60)
        remainder = Int(remainder % 60)
        let seconds = Int(remainder)

        result = String(format: "%02d %02d:%02d:%02d", days, hours, minutes, seconds)

        return result
    }
}
