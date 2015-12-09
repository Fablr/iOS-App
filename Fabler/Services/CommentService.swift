//
//  CommentService.swift
//  Fabler
//
//  Created by Christopher Day on 12/3/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import Alamofire
import SwiftyJSON

class CommentService {

    // MARK: - CommentService functions

    init() {
    }

    // MARK: - CommentService API functions

    func getCommentsForEpisode(episodeId: Int, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (result: [Comment]) -> Void) {
        let request = Alamofire
        .request(FablerClient.Router.ReadCommentsForEpisode(episode: episodeId))
        .validate()
        .responseSwiftyJSON { response in
            var comments: [Comment] = []

            switch response.result {
            case .Success(let json):
                comments = self.serializeCommentCollection(json)
            case .Failure(let error):
                Log.error("Episode comments request failed with \(error).")
            }

            dispatch_async(queue, {completion(result: comments)})
        }

        Log.debug("Episode comments request: \(request)")
    }

    func addCommentForEpisode(episodeId: Int, comment: String, parentCommentId: Int?, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (result: Bool) -> Void) {
        let request = Alamofire
        .request(FablerClient.Router.AddCommentForEpisode(episode: episodeId, comment: comment, parent: parentCommentId))
        .validate()
        .responseSwiftyJSON { response in
            let result: Bool

            switch response.result {
            case .Success:
                result = true
            case .Failure(let error):
                result = false
                Log.error("Adding comment failed with \(error).")
            }

            dispatch_async(queue, {completion(result: result)})
        }

        Log.debug("Adding comment request: \(request)")
    }

    func getCommentsForPodcast(podcastId: Int, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (result: [Comment]) -> Void) {
        let request = Alamofire
            .request(FablerClient.Router.ReadCommentsForPodcast(podcast: podcastId))
            .validate()
            .responseSwiftyJSON { response in
                var comments: [Comment] = []

                switch response.result {
                case .Success(let json):
                    comments = self.serializeCommentCollection(json)
                case .Failure(let error):
                    Log.error("Episode comments request failed with \(error).")
                }

                dispatch_async(queue, {completion(result: comments)})
        }

        Log.debug("Episode comments request: \(request)")
    }

    func addCommentForPodcast(podcastId: Int, comment: String, parentCommentId: Int?, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (result: Bool) -> Void) {
        let request = Alamofire
            .request(FablerClient.Router.AddCommentForPodcast(podcast: podcastId, comment: comment, parent: parentCommentId))
            .validate()
            .responseSwiftyJSON { response in
                let result: Bool

                switch response.result {
                case .Success:
                    result = true
                case .Failure(let error):
                    result = false
                    Log.error("Adding comment failed with \(error).")
                }

                dispatch_async(queue, {completion(result: result)})
        }

        Log.debug("Adding comment request: \(request)")
        debugPrint(request)
    }

    // MARK: - CommentService serialize functions

    private func serializeCommentObject(data: JSON) -> Comment? {
        let comment = Comment()

        if let id = data["id"].int {
            comment.commentId = id
        }

        if let userName = data["user_name"].string {
            comment.userName = userName
        }

        if let userId = data["user"].int {
            comment.userId = userId
        }

        if let commentBody = data["comment"].string {
            comment.comment = commentBody
        }

        if let submitDate = (data["submit_date"].string)?.toNSDate() {
            comment.submitDate = submitDate
        }

        if let editDate = (data["edited_date"].string)?.toNSDate() {
            comment.editDate = editDate
        }

        if let voteCount = data["net_vote"].int {
            comment.voteCount = voteCount
        }

        if let userVote = data["user_vote"].int {
            comment.userVote = userVote
        }

        if let parentId = data["parent"].int {
            comment.parentId = parentId
        }

        return comment
    }

    private func serializeCommentCollection(data: JSON) -> [Comment] {
        var comments: [Comment] = []

        for (_, subJson):(String, JSON) in data {
            do {
                if let comment = serializeCommentObject(subJson) {
                    comments.append(comment)
                }
            }
        }

        return comments
    }
}
