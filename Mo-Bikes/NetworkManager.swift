//
//  NetworkManager.swift
//  Mo-Bikes
//
//  Created by Andrew on 2018-02-15.
//  Copyright © 2018 hearthedge. All rights reserved.
//

import Foundation
import Alamofire

class NetworkManager {
    static let sharedInstance = NetworkManager()

    // TODO: Change to return Completeable
    func updateStationData(_ completion: @escaping ([Station]) -> Void) {
        _ = Alamofire.request("https://vancouver-ca.smoove.pro/api-public/stations",
                          method: .get)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseObject { (response: DataResponse<ResultContainer>) in
                if let results = response.result.value {
                    completion(results.stationsArray)
                }
        }
    }
}

class ResultContainer: ResponseObjectSerializable {
    let stationsArray: [Station]

    required init?(response: HTTPURLResponse, representation: Any) {
        guard let representation = representation as? [String: Any],
        let result = representation["result"]
            else { return nil }

        self.stationsArray = Station.collection(from: response, withRepresentation: result)
    }
}

protocol ResponseObjectSerializable {
    init?(response: HTTPURLResponse, representation: Any)
}

extension DataRequest {
    func responseObject<T: ResponseObjectSerializable>(
        queue: DispatchQueue? = nil,
        completionHandler: @escaping (DataResponse<T>) -> Void)
        -> Self {
        let responseSerializer = DataResponseSerializer<T> { request, response, data, error in
            guard error == nil else { return .failure(BackendError.network(error: error!)) }

            let jsonResponseSerializer = DataRequest.jsonResponseSerializer(options: .allowFragments)
            let result = jsonResponseSerializer.serializeResponse(request, response, data, nil)

            guard case let .success(jsonObject) = result else {
                return .failure(BackendError.jsonSerialization(error: result.error!))
            }

            guard let response = response, let responseObject = T(response: response, representation: jsonObject) else {
                return .failure(BackendError.objectSerialization(reason: "JSON could not be serialized: \(jsonObject)"))
            }

            return .success(responseObject)
        }

        return response(queue: queue, responseSerializer: responseSerializer, completionHandler: completionHandler)
    }
}

protocol ResponseCollectionSerializable {
    static func collection(from response: HTTPURLResponse, withRepresentation representation: Any) -> [Self]
}

extension ResponseCollectionSerializable where Self: ResponseObjectSerializable {
    static func collection(from response: HTTPURLResponse, withRepresentation representation: Any) -> [Self] {
        var collection: [Self] = []

        if let representation = representation as? [[String: Any]] {
            for itemRepresentation in representation {

                if let item = Self(response: response, representation: itemRepresentation) {
                    collection.append(item)
                }
            }
        }

        return collection
    }
}

extension DataRequest {
    @discardableResult
    func responseCollection<T: ResponseCollectionSerializable>(
        queue: DispatchQueue? = nil,
        completionHandler: @escaping (DataResponse<[T]>) -> Void) -> Self {
        let responseSerializer = DataResponseSerializer<[T]> { request, response, data, error in
            guard error == nil else { return .failure(BackendError.network(error: error!)) }

            let jsonSerializer = DataRequest.jsonResponseSerializer(options: .allowFragments)
            let result = jsonSerializer.serializeResponse(request, response, data, nil)

            guard case let .success(jsonObject) = result else {
                return .failure(BackendError.jsonSerialization(error: result.error!))
            }

            guard let response = response else {
                let reason = "Response collection could not be serialized due to nil response."
                return .failure(BackendError.objectSerialization(reason: reason))
            }

            return .success(T.collection(from: response, withRepresentation: jsonObject))
        }

        return response(responseSerializer: responseSerializer, completionHandler: completionHandler)
    }
}

enum BackendError: Error {
    case network(error: Error) // Capture any underlying Error from the URLSession API
    case dataSerialization(error: Error)
    case jsonSerialization(error: Error)
    case xmlSerialization(error: Error)
    case objectSerialization(reason: String)
}
