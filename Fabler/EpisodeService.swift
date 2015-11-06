//
//  EpisodeService.swift
//  Fabler
//
//  Created by Christopher Day on 11/3/15.
//  Copyright © 2015 AppCoda. All rights reserved.
//

import Alamofire

class EpisodeService {

    // MARK: - EpisodeService functions

    init() {
    }

    func getEpisodesForPodcast(podcastId: Int, completion: (result: [Episode]) -> Void) {
        Alamofire
            .request(FablerClient.Router.ReadEpisodesForPodcast(podcast: podcastId))
            .validate()
            .responseCollection { (response: Response<[Episode], NSError>) in
                switch response.result {
                case .Success(let value):
                    completion(result: value)
                case .Failure(let error):
                    print(error)
                }
        }
    }
}
