//
//  Branches.swift
//  GitHubTools
//
//  Created by Norikazu Muramoto on 2025/02/18
//

import Foundation

/// Options for creating a branch.
public struct CreateBranchOptions {
    public let ref: String
    public let sha: String
    
    public init(ref: String, sha: String) {
        self.ref = ref
        self.sha = sha
    }
}

/**
 Retrieves the default branch SHA of a repository by trying "main" then "master".
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - Returns: The SHA string of the default branch.
 - Throws: An error if unable to determine the default branch.
 */
public func getDefaultBranchSHA(owner: String, repo: String) async throws -> String {
    do {
        let response = try await githubRequest(url: "https://api.github.com/repos/\(owner)/\(repo)/git/refs/heads/main")
        let data = try JSONSerialization.data(withJSONObject: response)
        let reference = try JSONDecoder().decode(GitHubReference.self, from: data)
        return reference.object.sha
    } catch {
        let response = try await githubRequest(url: "https://api.github.com/repos/\(owner)/\(repo)/git/refs/heads/master")
        let data = try JSONSerialization.data(withJSONObject: response)
        let reference = try JSONDecoder().decode(GitHubReference.self, from: data)
        return reference.object.sha
    }
}

/**
 Retrieves the SHA of a specific branch.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - branch: Branch name.
 - Returns: The SHA string of the branch.
 - Throws: An error if the branch cannot be retrieved.
 */
public func getBranchSHA(owner: String, repo: String, branch: String) async throws -> String {
    let response = try await githubRequest(url: "https://api.github.com/repos/\(owner)/\(repo)/git/refs/heads/\(branch)")
    let data = try JSONSerialization.data(withJSONObject: response)
    let reference = try JSONDecoder().decode(GitHubReference.self, from: data)
    return reference.object.sha
}

/**
 Creates a new branch in a repository.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - options: Options including new branch name (`ref`) and source SHA (`sha`).
 - Returns: A `GitHubReference` representing the new branch.
 - Throws: An error if branch creation fails.
 */
public func createBranch(owner: String, repo: String, options: CreateBranchOptions) async throws -> GitHubReference {
    let fullRef = "refs/heads/\(options.ref)"
    let body: [String: Any] = [
        "ref": fullRef,
        "sha": options.sha
    ]
    let response = try await githubRequest(url: "https://api.github.com/repos/\(owner)/\(repo)/git/refs", options: RequestOptions(method: "POST", body: body))
    let data = try JSONSerialization.data(withJSONObject: response)
    return try JSONDecoder().decode(GitHubReference.self, from: data)
}

/**
 Creates a new branch from a given reference.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - newBranch: New branch name.
 - fromBranch: Optional source branch; if nil, uses the default branch.
 - Returns: A `GitHubReference` representing the new branch.
 - Throws: An error if branch creation fails.
 */
public func createBranchFromRef(owner: String, repo: String, newBranch: String, fromBranch: String? = nil) async throws -> GitHubReference {
    let sha: String
    if let fromBranch = fromBranch {
        sha = try await getBranchSHA(owner: owner, repo: repo, branch: fromBranch)
    } else {
        sha = try await getDefaultBranchSHA(owner: owner, repo: repo)
    }
    let options = CreateBranchOptions(ref: newBranch, sha: sha)
    return try await createBranch(owner: owner, repo: repo, options: options)
}

/**
 Updates a branch reference to a new commit SHA.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - ref: Branch reference (e.g., "heads/main").
 - sha: New commit SHA.
 - Returns: A `GitHubReference` representing the updated branch.
 - Throws: An error if the update fails.
 */
public func updateBranch(owner: String, repo: String, ref: String, sha: String) async throws -> GitHubReference {
    let body: [String: Any] = [
        "sha": sha,
        "force": true
    ]
    let response = try await githubRequest(url: "https://api.github.com/repos/\(owner)/\(repo)/git/refs/\(ref)", options: RequestOptions(method: "PATCH", body: body))
    let data = try JSONSerialization.data(withJSONObject: response)
    return try JSONDecoder().decode(GitHubReference.self, from: data)
}
