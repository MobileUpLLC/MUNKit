//
//  DNDAPITarget.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import munkit
import Moya
import Foundation

public enum DNDAPITarget {
    case classes
    case monsters(challengeRatings: [Double]?)
    case monster(_ index: String)
}

extension DNDAPITarget: MUNAPITarget {
    public var parameters: [String: Any] { getParameters() }
    public var isAccessTokenRequired: Bool { getIsAccessTokenRequired() }
    public var isRefreshTokenRequest: Bool { getIsRefreshTokenRequest() }
    public var baseURL: URL { getBaseURL() }
    public var path: String { getPath() }
    public var method: Moya.Method { getMethod() }
    public var task: Moya.Task { getTask() }
    public var headers: [String: String]? { getHeaders() }
    public var authorizationType: Moya.AuthorizationType? { getAuthorizationType() }
    public var mockFileName: String? { nil }
    public var isMockEnabled: Bool { false }

    private func getParameters() -> [String: Any] {
        switch self {
        case .classes, .monster:
            return [:]
        case .monsters(let challengeRatings):
            if let ratings = challengeRatings {
                let ratingsString = ratings.map { String($0) }.joined(separator: ",")
                return ["challenge_rating": ratingsString]
            }
            return [:]
        }
    }

    private func getIsAccessTokenRequired() -> Bool {
        switch self {
        case .classes, .monsters, .monster:
            return false
        }
    }

    private func getIsRefreshTokenRequest() -> Bool {
        switch self {
        case .classes, .monsters, .monster:
            return false
        }
    }

    private func getBaseURL() -> URL {
        switch self {
        case .classes, .monsters, .monster:
            return URL(string: "https://www.dnd5eapi.co")!
        }
    }

    private func getPath() -> String {
        switch self {
        case .classes:
            return "/api/2014/classes"
        case .monsters:
            return "/api/2014/monsters"
        case .monster(let index):
            return "/api/2014/monsters/\(index)"
        }
    }

    private func getMethod() -> Moya.Method {
        switch self {
        case .classes, .monsters, .monster:
            return .get
        }
    }

    private func getTask() -> Moya.Task {
        switch self {
        case .classes, .monster:
            return .requestPlain
        case .monsters(let challengeRatings):
            if challengeRatings != nil {
                return .requestParameters(
                    parameters: getParameters(),
                    encoding: URLEncoding.queryString
                )
            }
            return .requestPlain
        }
    }

    private func getHeaders() -> [String: String]? {
        switch self {
        case .classes, .monsters, .monster:
            return ["Accept": "application/json"]
        }
    }

    private func getAuthorizationType() -> Moya.AuthorizationType? {
        switch self {
        case .classes, .monsters, .monster:
            return nil
        }
    }
}
