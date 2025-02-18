//
//  Issues.swift
//  GitHubTools
//
//  Created by Norikazu Muramoto on 2025/02/18
//

import Foundation

/**
 Retrieves a specific issue from a repository.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - issueNumber: Issue number.
 - Returns: The raw JSON response representing the issue.
 - Throws: An error if the API request fails.
 */
public func getIssue(owner: String, repo: String, issueNumber: Int) async throws -> Any {
    let url = "https://api.github.com/repos/\(owner)/\(repo)/issues/\(issueNumber)"
    return try await githubRequest(url: url)
}

/**
 Adds a comment to an issue.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - issueNumber: Issue number.
 - body: Comment text.
 - Returns: The raw JSON response representing the comment.
 - Throws: An error if the API request fails.
 */
public func addIssueComment(owner: String, repo: String, issueNumber: Int, body: String) async throws -> Any {
    let url = "https://api.github.com/repos/\(owner)/\(repo)/issues/\(issueNumber)/comments"
    let options = RequestOptions(method: "POST", body: ["body": body])
    return try await githubRequest(url: url, options: options)
}

/**
 Creates a new issue in a repository.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - options: A dictionary of issue options (e.g., title, body, assignees, milestone, labels).
 - Returns: The raw JSON response representing the created issue.
 - Throws: An error if the API request fails.
 */
public func createIssue(owner: String, repo: String, options: [String: Any]) async throws -> Any {
    let url = "https://api.github.com/repos/\(owner)/\(repo)/issues"
    let requestOptions = RequestOptions(method: "POST", body: options)
    return try await githubRequest(url: url, options: requestOptions)
}

/**
 Lists issues in a repository with optional filtering.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - options: A dictionary of filtering options.
 - Returns: The raw JSON response representing the list of issues.
 - Throws: An error if the API request fails.
 */
public func listIssues(owner: String, repo: String, options: [String: String?]) async throws -> Any {
    let url = buildUrl(baseUrl: "https://api.github.com/repos/\(owner)/\(repo)/issues", params: options)
    return try await githubRequest(url: url)
}

/**
 Updates an existing issue.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - issueNumber: Issue number.
 - options: A dictionary of update options.
 - Returns: The raw JSON response representing the updated issue.
 - Throws: An error if the API request fails.
 */
public func updateIssue(owner: String, repo: String, issueNumber: Int, options: [String: Any]) async throws -> Any {
    let url = "https://api.github.com/repos/\(owner)/\(repo)/issues/\(issueNumber)"
    let requestOptions = RequestOptions(method: "PATCH", body: options)
    return try await githubRequest(url: url, options: requestOptions)
}
