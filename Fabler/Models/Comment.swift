//
//  Comment.swift
//  Fabler
//
//  Created by Christopher Day on 12/3/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

final class Comment {

    // MARK: - Comment members

    var commentId: Int = 0
    var userName: String = ""
    var userId: Int = 0
    var comment: String = ""
    var formattedComment: NSAttributedString?
    var submitDate: NSDate = NSDate()
    var editDate: NSDate?
    var voteCount: Int = 1
    var userVote: Int = 0
    var parentId: Int?
}
