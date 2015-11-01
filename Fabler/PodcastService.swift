//
//  PodcastService.swift
//  Fabler
//
//  Created by Christopher Day on 10/30/15.
//  Copyright © 2015 AppCoda. All rights reserved.
//

import Alamofire

class PodcastService {

    // MARK: - LoginService functions

    init() {
    }

    func readAllPodcasts(completion: (result: [Podcast]) -> Void) {
        Alamofire
            .request(FablerClient.Router.ReadPodcasts())
            .validate()
            .responseCollection { (response: Response<[Podcast], NSError>) in
                switch response.result {
                case .Success(let value):
                    completion(result: value)
                case .Failure(let error):
                    print(error)
                }
            }
    }
}
