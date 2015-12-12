//
//  CommentService.swift
//  Fabler
//
//  Created by Christopher Day on 12/3/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import Alamofire
import SwiftyJSON
import XNGMarkdownParser
import SCLAlertView

// swiftlint:disable type_name

enum Vote: Int {
    case Down = -1
    case None = 0
    case Up = 1
}

// swiftlint:enable type_name

class CommentService {

    // MARK: - CommentService functions

    init() {
    }

    // MARK: - CommentService API functions

    func getCommentsForEpisode(episode: Episode, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (result: [Comment]) -> Void) {
        let id = episode.episodeId

        let request = Alamofire
        .request(FablerClient.Router.ReadCommentsForEpisode(episode: id))
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

    func addCommentForEpisode(episode: Episode, comment: String, parentCommentId: Int?, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (result: Bool) -> Void) {
        let id = episode.episodeId
        let title = episode.title

        let request = Alamofire
        .request(FablerClient.Router.AddCommentForEpisode(episode: id, comment: comment, parent: parentCommentId))
        .validate()
        .responseSwiftyJSON { response in
            let result: Bool

            switch response.result {
            case .Success:
                result = true
            case .Failure(let error):
                result = false
                Log.error("Adding comment failed with \(error).")

                dispatch_async(dispatch_get_main_queue(), {
                    SCLAlertView().showWarning("Warning", subTitle: "Unable to add comment to episode \(title).")
                })
            }

            dispatch_async(queue, {completion(result: result)})
        }

        Log.debug("Adding comment request: \(request)")
    }

    func getCommentsForPodcast(podcast: Podcast, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (result: [Comment]) -> Void) {
        let id = podcast.podcastId

        let request = Alamofire
        .request(FablerClient.Router.ReadCommentsForPodcast(podcast: id))
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

    func addCommentForPodcast(podcast: Podcast, comment: String, parentCommentId: Int?, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (result: Bool) -> Void) {
        let id = podcast.podcastId
        let title = podcast.title

        let request = Alamofire
        .request(FablerClient.Router.AddCommentForPodcast(podcast: id, comment: comment, parent: parentCommentId))
        .validate()
        .responseSwiftyJSON { response in
            let result: Bool

            switch response.result {
            case .Success:
                result = true
            case .Failure(let error):
                result = false
                Log.error("Adding comment failed with \(error).")

                dispatch_async(dispatch_get_main_queue(), {
                    SCLAlertView().showWarning("Warning", subTitle: "Unable to add comment to podcast \(title).")
                })
            }

            dispatch_async(queue, {completion(result: result)})
        }

        Log.debug("Adding comment request: \(request)")
    }

    func voteOnComment(comment: Comment, vote: Vote, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (result: Bool) -> Void) {
        let id = comment.commentId
        let user = comment.userName

        let request = Alamofire
        .request(FablerClient.Router.VoteComment(comment: id, vote: vote.rawValue))
        .validate()
        .responseSwiftyJSON { response in
            let result: Bool

            switch response.result {
            case .Success:
                result = true
            case .Failure(let error):
                result = false
                Log.error("Vote failed with \(error).")

                dispatch_async(dispatch_get_main_queue(), {
                    SCLAlertView().showWarning("Warning", subTitle: "Unable to vote on comment by \(user).")
                })
            }

            dispatch_async(queue, {completion(result: result)})
        }

        Log.debug("Voting comment request: \(request)")
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

            let parser = XNGMarkdownParser()
            parser.paragraphFont = UIFont(name: "Helvetica Neue", size: 15.0)
            comment.formattedComment = parser.attributedStringFromMarkdownString(comment.comment)
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
