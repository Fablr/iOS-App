//
//  Comment.swift
//  Fabler
//
//  Created by Christopher Day on 12/3/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import RealmSwift
import XNGMarkdownParser

// swiftlint:disable type_name

enum Vote: Int {
    case Down = -1
    case None = 0
    case Up = 1
}

// swiftlint:enable type_name

final public class Comment: Object {

    // MARK: - Comment members

    dynamic var commentId: Int = 0
    dynamic var userName: String = ""
    dynamic var user: User?
    dynamic var userId: Int = 0
    dynamic var comment: String = ""
    dynamic var submitDate: NSDate = NSDate()
    dynamic var editDate: NSDate?
    dynamic var voteCount: Int = 1
    dynamic var userVoteRaw: Int = 0
    dynamic var parent: Comment?
    dynamic var podcast: Podcast?
    dynamic var episode: Episode?
    dynamic var removed: Bool = false

    let children = List<Comment>()

    // MARK: - Computed properties

    var userVote: Vote {
        get {
            if let state = Vote(rawValue: self.userVoteRaw) {
                return state
            }

            return Vote.None
        }
    }

    var formattedComment: NSAttributedString? {
        get {
            let parser = XNGMarkdownParser()
            parser.paragraphFont = UIFont(name: "Helvetica Neue", size: 15.0)
            return parser.attributedStringFromMarkdownString(self.comment)
        }
    }

    // MARK: - Realm methods

    override public static func primaryKey() -> String? {
        return "commentId"
    }
}
