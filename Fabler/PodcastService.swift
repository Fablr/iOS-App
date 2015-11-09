//
//  PodcastService.swift
//  Fabler
//
//  Created by Christopher Day on 10/30/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import Alamofire

class PodcastService {

    // MARK: - PodcastService functions

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

    func readSubscribedPodcasts(completion: (result: [Podcast]) -> Void) {
        Alamofire
            .request(FablerClient.Router.ReadSubscribedPodcasts())
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

    func subscribeToPodcast(podcastId: Int, subscribe: Bool, completion: (result: Bool) -> Void) {
        Alamofire
            .request(FablerClient.Router.SubscribeToPodcast(podcast: podcastId, subscribe: subscribe))
            .validate(statusCode: 200..<202)
            .responseJSON { response in
                switch response.result {
                case .Success:
                    completion(result: true)
                case .Failure(let error):
                    print(error)
                    completion(result: false)
                }
            }
    }
}
