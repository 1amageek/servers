//
//  Commits.swift
//  GitHubTools
//
//  Created by Norikazu Muramoto on 2025/02/18
//

import Foundation

/**
 Lists commits for a given repository.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - page: Optional page number (default is 1).
 - perPage: Optional results per page (default is 30).
 - sha: Optional commit SHA to filter by.
 - Returns: The raw JSON response representing the list of commits.
 - Throws: An error if the API request fails.
 */
public func listCommits(owner: String, repo: String, page: Int = 1, perPage: Int = 30, sha: String? = nil) async throws -> Any {
    let url = buildUrl(baseUrl: "https://api.github.com/repos/\(owner)/\(repo)/commits", params: [
        "page": "\(page)",
        "per_page": "\(perPage)",
        "sha": sha
    ])
    return try await githubRequest(url: url)
}
