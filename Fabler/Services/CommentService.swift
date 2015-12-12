//
//  CommentService.swift
//  Fabler
//
//  Created by Christopher Day on 12/3/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import Alamofire
import SwiftyJSON
import SCLAlertView
import RealmSwift

class CommentService {

    // MARK: - CommentService functions

    init() {
    }

    // MARK: - CommentService API functions

    func getCommentsForEpisode(episode: Episode, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (result: [Comment]) -> Void) -> [Comment] {
        guard let podcast = episode.podcast else {
            return []
        }

        let id = episode.episodeId
        let podcastId = podcast.podcastId

        let request = Alamofire
        .request(FablerClient.Router.ReadCommentsForEpisode(episode: id))
        .validate()
        .responseSwiftyJSON { response in
            switch response.result {
            case .Success(let json):
                self.serializeCommentCollection(json, episode: id, podcast: podcastId)
            case .Failure(let error):
                Log.error("Episode comments request failed with \(error).")
            }

            dispatch_async(queue, {completion(result: self.getCommentsForEpisodeFromRealm(id))})
        }

        Log.debug("Episode comments request: \(request)")

        return self.getCommentsForEpisodeFromRealm(id)
    }

    func getCommentsForEpisodeFromRealm(episode: Int) -> [Comment] {
        var comments: [Comment] = []

        do {
            let realm = try self.scratchRealm()

            comments = Array(realm.objects(Comment).filter("episode.episodeId == %d AND parent == nil", episode))

            // CHRIS flatten children
        } catch {
            Log.error("Realm read failed.")
        }

        return comments
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

    func getCommentsForPodcast(podcast: Podcast, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (result: [Comment]) -> Void) -> [Comment] {
        let id = podcast.podcastId

        let request = Alamofire
        .request(FablerClient.Router.ReadCommentsForPodcast(podcast: id))
        .validate()
        .responseSwiftyJSON { response in
            switch response.result {
            case .Success(let json):
                self.serializeCommentCollection(json, episode: nil, podcast: id)
            case .Failure(let error):
                Log.error("Episode comments request failed with \(error).")
            }

            dispatch_async(queue, {completion(result: self.getCommentsForPodcastFromRealm(id))})
        }

        Log.debug("Episode comments request: \(request)")

        return self.getCommentsForPodcastFromRealm(id)
    }

    func getCommentsForPodcastFromRealm(podcast: Int) -> [Comment] {
        var comments: [Comment] = []

        do {
            let realm = try self.scratchRealm()

            comments = Array(realm.objects(Comment).filter("podcast.podcastId == %d AND episode == nil AND parent == nil", podcast))

            // CHRIS flatten children
        } catch {
            Log.error("Realm read failed.")
        }

        return comments
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

    private func serializeCommentObject(data: JSON, episode: Int?, podcast: Int?) -> Comment? {
        var result: Comment?

        do {
            let comment = Comment()
            let realm = try self.scratchRealm()

            if let id = data["id"].int {
                comment.commentId = id
            }

            if let userName = data["user_name"].string {
                comment.userName = userName
            }

            if let userId = data["user"].int {
                let userService = UserService()
                if let user = userService.getUserFor(userId, completion: nil) {
                    var scratchUser: User?
                    try realm.write {
                        scratchUser = realm.create(User.self, value: user, update: true)
                    }

                    comment.user = scratchUser
                }

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
                comment.userVoteRaw = userVote
            }

            if let parentId = data["parent"].int {
                if let parent = realm.objectForPrimaryKey(Comment.self, key: parentId) {
                    comment.parent = parent
                }
            }

            if let episode = episode {
                let episodeService = EpisodeService()
                if let episodeObject = episodeService.getEpisodeFor(episode, completion: nil) {
                    var scratchEpisode: Episode?
                    try realm.write {
                        scratchEpisode = realm.create(Episode.self, value: episodeObject, update: true)
                    }

                    comment.episode = scratchEpisode
                }
            }

            if let podcast = podcast {
                let podcastService = PodcastService()
                if let podcastObject = podcastService.readPodcastFor(podcast, completion: nil) {
                    var scratchPodcast: Podcast?
                    try realm.write {
                        scratchPodcast = realm.create(Podcast.self, value: podcastObject, update: true)
                    }

                    comment.podcast = scratchPodcast
                }
            }

            try realm.write {
                realm.add(comment, update: true)
                comment.parent?.children.append(comment)
            }

            result = comment
        } catch {
            result = nil
        }

        return result
    }

    private func serializeCommentCollection(data: JSON, episode: Int?, podcast: Int?) -> [Comment] {
        var comments: [Comment] = []

        for (_, subJson):(String, JSON) in data {
            do {
                if let comment = serializeCommentObject(subJson, episode: episode, podcast: podcast) {
                    comments.append(comment)
                }
            }
        }

        return comments
    }

    private func scratchRealm() throws -> Realm {
        return try Realm(configuration: Realm.Configuration(inMemoryIdentifier: ScratchRealmIdentifier))
    }
}
