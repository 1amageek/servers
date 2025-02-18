//
//  Repository.swift
//  GitHubTools
//
//  Created by Norikazu Muramoto on 2025/02/18
//

import Foundation

/**
 Options for creating a repository.
 */
public struct CreateRepositoryOptions: Codable {
    public let name: String
    public let description: String?
    public let `private`: Bool?
    public let autoInit: Bool?
    
    public init(name: String, description: String? = nil, private: Bool? = nil, autoInit: Bool? = nil) {
        self.name = name
        self.description = description
        self.private = `private`
        self.autoInit = autoInit
    }
}

/**
 Creates a new repository for the authenticated user.
 
 - Parameter options: Options for repository creation.
 - Returns: A `GitHubRepository` representing the new repository.
 - Throws: An error if the API request fails.
 */
public func createRepository(options: CreateRepositoryOptions) async throws -> GitHubRepository {
    let url = "https://api.github.com/user/repos"
    let encoder = JSONEncoder()
    let optionsData = try encoder.encode(options)
    guard let optionsDict = try JSONSerialization.jsonObject(with: optionsData, options: []) as? [String: Any] else {
        throw NSError(domain: "createRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert options to dictionary"])
    }
    let requestOptions = RequestOptions(method: "POST", body: optionsDict)
    let response = try await githubRequest(url: url, options: requestOptions)
    let data = try JSONSerialization.data(withJSONObject: response)
    return try JSONDecoder().decode(GitHubRepository.self, from: data)
}


/**
 Searches for repositories using a query.
 
 - Parameters:
 - query: The search query.
 - page: Optional page number (default is 1).
 - perPage: Optional number of results per page (default is 30).
 - Returns: A `GitHubSearchResponse<GitHubRepository>` object.
 - Throws: An error if the API request fails.
 */
public func searchRepositories(query: String, page: Int = 1, perPage: Int = 30) async throws -> GitHubSearchResponse<GitHubRepository> {
    let url = buildUrl(baseUrl: "https://api.github.com/search/repositories", params: [
        "q": query,
        "page": "\(page)",
        "per_page": "\(perPage)"
    ])
    let response = try await githubRequest(url: url)
    let data = try JSONSerialization.data(withJSONObject: response)
    return try JSONDecoder().decode(GitHubSearchResponse<GitHubRepository>.self, from: data)
}

/**
 Forks a repository.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - organization: Optional organization to fork to.
 - Returns: A `GitHubRepository` representing the forked repository.
 - Throws: An error if the API request fails.
 */
public func forkRepository(owner: String, repo: String, organization: String? = nil) async throws -> GitHubRepository {
    var url = "https://api.github.com/repos/\(owner)/\(repo)/forks"
    if let org = organization {
        url += "?organization=\(org)"
    }
    let response = try await githubRequest(url: url, options: RequestOptions(method: "POST"))
    let data = try JSONSerialization.data(withJSONObject: response)
    return try JSONDecoder().decode(GitHubRepository.self, from: data)
}
