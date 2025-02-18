//
//  Pulls.swift
//  GitHubTools
//
//  Created by Norikazu Muramoto on 2025/02/18
//

import Foundation

/**
 Creates a new pull request.
 
 - Parameter params: A dictionary containing pull request parameters.
 - Returns: A `GitHubPullRequest` representing the created pull request.
 - Throws: An error if the API request fails.
 */
public func createPullRequest(params: [String: Any]) async throws -> GitHubPullRequest {
    guard let owner = params["owner"] as? String,
          let repo = params["repo"] as? String else {
        throw NSError(domain: "createPullRequest", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing owner or repo"])
    }
    var options = params
    options.removeValue(forKey: "owner")
    options.removeValue(forKey: "repo")
    
    let url = "https://api.github.com/repos/\(owner)/\(repo)/pulls"
    let requestOptions = RequestOptions(method: "POST", body: options)
    let response = try await githubRequest(url: url, options: requestOptions)
    let data = try JSONSerialization.data(withJSONObject: response)
    return try JSONDecoder().decode(GitHubPullRequest.self, from: data)
}

/**
 Retrieves a pull request.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - pullNumber: Pull request number.
 - Returns: A `GitHubPullRequest` representing the pull request.
 - Throws: An error if the API request fails.
 */
public func getPullRequest(owner: String, repo: String, pullNumber: Int) async throws -> GitHubPullRequest {
    let url = "https://api.github.com/repos/\(owner)/\(repo)/pulls/\(pullNumber)"
    let response = try await githubRequest(url: url)
    let data = try JSONSerialization.data(withJSONObject: response)
    return try JSONDecoder().decode(GitHubPullRequest.self, from: data)
}

/**
 Lists pull requests for a repository.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - options: A dictionary of filtering options.
 - Returns: An array of `GitHubPullRequest` objects.
 - Throws: An error if the API request fails.
 */
public func listPullRequests(owner: String, repo: String, options: [String: String?]) async throws -> [GitHubPullRequest] {
    var components = URLComponents(string: "https://api.github.com/repos/\(owner)/\(repo)/pulls")!
    var queryItems: [URLQueryItem] = []
    for (key, value) in options {
        if let value = value {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
    }
    components.queryItems = queryItems.isEmpty ? nil : queryItems
    let url = components.url!.absoluteString
    let response = try await githubRequest(url: url)
    let data = try JSONSerialization.data(withJSONObject: response)
    return try JSONDecoder().decode([GitHubPullRequest].self, from: data)
}

/**
 Creates a pull request review.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - pullNumber: Pull request number.
 - options: A dictionary containing review options.
 - Returns: A `GitHubPullRequestReview` representing the review.
 - Throws: An error if the API request fails.
 */
public func createPullRequestReview(owner: String, repo: String, pullNumber: Int, options: [String: Any]) async throws -> GitHubPullRequestReview {
    let url = "https://api.github.com/repos/\(owner)/\(repo)/pulls/\(pullNumber)/reviews"
    let requestOptions = RequestOptions(method: "POST", body: options)
    let response = try await githubRequest(url: url, options: requestOptions)
    let data = try JSONSerialization.data(withJSONObject: response)
    return try JSONDecoder().decode(GitHubPullRequestReview.self, from: data)
}

/**
 Merges a pull request.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - pullNumber: Pull request number.
 - options: A dictionary of merge options.
 - Returns: The raw JSON response representing the merge result.
 - Throws: An error if the API request fails.
 */
public func mergePullRequest(owner: String, repo: String, pullNumber: Int, options: [String: Any]) async throws -> Any {
    let url = "https://api.github.com/repos/\(owner)/\(repo)/pulls/\(pullNumber)/merge"
    return try await githubRequest(url: url, options: RequestOptions(method: "PUT", body: options))
}

/**
 Retrieves the files changed in a pull request.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - pullNumber: Pull request number.
 - Returns: An array representing the pull request files.
 - Throws: An error if the API request fails.
 */
public func getPullRequestFiles(owner: String, repo: String, pullNumber: Int) async throws -> [Any] {
    let url = "https://api.github.com/repos/\(owner)/\(repo)/pulls/\(pullNumber)/files"
    let response = try await githubRequest(url: url)
    return response as? [Any] ?? []
}

/**
 Updates a pull request branch.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - pullNumber: Pull request number.
 - expectedHeadSha: Optional expected head SHA.
 - Throws: An error if the API request fails.
 */
public func updatePullRequestBranch(owner: String, repo: String, pullNumber: Int, expectedHeadSha: String? = nil) async throws {
    let url = "https://api.github.com/repos/\(owner)/\(repo)/pulls/\(pullNumber)/update-branch"
    let body: [String: Any]? = expectedHeadSha != nil ? ["expected_head_sha": expectedHeadSha!] : nil
    _ = try await githubRequest(url: url, options: RequestOptions(method: "PUT", body: body))
}

/**
 Retrieves pull request comments.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - pullNumber: Pull request number.
 - Returns: An array representing the pull request comments.
 - Throws: An error if the API request fails.
 */
public func getPullRequestComments(owner: String, repo: String, pullNumber: Int) async throws -> [Any] {
    let url = "https://api.github.com/repos/\(owner)/\(repo)/pulls/\(pullNumber)/comments"
    let response = try await githubRequest(url: url)
    return response as? [Any] ?? []
}

/**
 Retrieves pull request reviews.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - pullNumber: Pull request number.
 - Returns: An array of `GitHubPullRequestReview` objects.
 - Throws: An error if the API request fails.
 */
public func getPullRequestReviews(owner: String, repo: String, pullNumber: Int) async throws -> [GitHubPullRequestReview] {
    let url = "https://api.github.com/repos/\(owner)/\(repo)/pulls/\(pullNumber)/reviews"
    let response = try await githubRequest(url: url)
    let data = try JSONSerialization.data(withJSONObject: response)
    return try JSONDecoder().decode([GitHubPullRequestReview].self, from: data)
}

/**
 Retrieves the combined status of a pull request by using the head commit SHA.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - pullNumber: Pull request number.
 - Returns: The raw JSON response representing the combined status.
 - Throws: An error if the API request fails.
 */
public func getPullRequestStatus(owner: String, repo: String, pullNumber: Int) async throws -> Any {
    let pr = try await getPullRequest(owner: owner, repo: repo, pullNumber: pullNumber)
    let sha = pr.head.sha
    let url = "https://api.github.com/repos/\(owner)/\(repo)/commits/\(sha)/status"
    return try await githubRequest(url: url)
}
