//
//  Search.swift
//  GitHubTools
//
//  Created by Norikazu Muramoto on 2025/02/18
//

import Foundation

/**
 Represents common search options.
 */
public struct SearchOptions {
    public let q: String
    public let order: String?
    public let page: Int?
    public let per_page: Int?
    
    public init(q: String, order: String? = nil, page: Int? = nil, per_page: Int? = nil) {
        self.q = q
        self.order = order
        self.page = page
        self.per_page = per_page
    }
}

/**
 Represents options for searching users.
 */
public struct SearchUsersOptions {
    public let q: String
    public let order: String?
    public let page: Int?
    public let per_page: Int?
    public let sort: String?
    
    public init(q: String, order: String? = nil, page: Int? = nil, per_page: Int? = nil, sort: String? = nil) {
        self.q = q
        self.order = order
        self.page = page
        self.per_page = per_page
        self.sort = sort
    }
}

/**
 Represents options for searching issues.
 */
public struct SearchIssuesOptions {
    public let q: String
    public let order: String?
    public let page: Int?
    public let per_page: Int?
    public let sort: String?
    
    public init(q: String, order: String? = nil, page: Int? = nil, per_page: Int? = nil, sort: String? = nil) {
        self.q = q
        self.order = order
        self.page = page
        self.per_page = per_page
        self.sort = sort
    }
}

/**
 Searches for code across GitHub repositories.
 
 - Parameter params: The search options.
 - Returns: The raw JSON search result.
 - Throws: An error if the API request fails.
 */
public func searchCode(params: SearchOptions) async throws -> Any {
    let url = buildUrl(baseUrl: "https://api.github.com/search/code", params: [
        "q": params.q,
        "order": params.order,
        "page": params.page.map { "\($0)" },
        "per_page": params.per_page.map { "\($0)" }
    ])
    return try await githubRequest(url: url)
}

/**
 Searches for issues across GitHub repositories.
 
 - Parameter params: The search options for issues.
 - Returns: The raw JSON search result.
 - Throws: An error if the API request fails.
 */
public func searchIssues(params: SearchIssuesOptions) async throws -> Any {
    let url = buildUrl(baseUrl: "https://api.github.com/search/issues", params: [
        "q": params.q,
        "order": params.order,
        "page": params.page.map { "\($0)" },
        "per_page": params.per_page.map { "\($0)" },
        "sort": params.sort
    ])
    return try await githubRequest(url: url)
}

/**
 Searches for users on GitHub.
 
 - Parameter params: The search options for users.
 - Returns: The raw JSON search result.
 - Throws: An error if the API request fails.
 */
public func searchUsers(params: SearchUsersOptions) async throws -> Any {
    let url = buildUrl(baseUrl: "https://api.github.com/search/users", params: [
        "q": params.q,
        "order": params.order,
        "page": params.page.map { "\($0)" },
        "per_page": params.per_page.map { "\($0)" },
        "sort": params.sort
    ])
    return try await githubRequest(url: url)
}
