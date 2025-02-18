//
//  Files.swift
//  GitHubTools
//
//  Created by Norikazu Muramoto on 2025/02/18
//

import Foundation

/**
 Retrieves the contents of a file or directory from a GitHub repository.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - path: Path to the file or directory.
 - branch: Optional branch to retrieve from.
 - Returns: A `GitHubContent` (either file content or an array of directory items).
 - Throws: An error if the API request fails.
 */
public func getFileContents(owner: String, repo: String, path: String, branch: String? = nil) async throws -> GitHubContent {
    var url = "https://api.github.com/repos/\(owner)/\(repo)/contents/\(path)"
    if let branch = branch {
        url += "?ref=\(branch)"
    }
    let response = try await githubRequest(url: url)
    let data = try JSONSerialization.data(withJSONObject: response)
    return try JSONDecoder().decode(GitHubContent.self, from: data)
}

/**
 Creates or updates a file in a GitHub repository.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - path: File path where the file will be created/updated.
 - content: The file content.
 - message: Commit message.
 - branch: The branch in which to create/update the file.
 - sha: Optional SHA of the existing file (for updates).
 - Returns: A `GitHubCreateUpdateFileResponse` containing file and commit info.
 - Throws: An error if the API request fails.
 */
public func createOrUpdateFile(owner: String, repo: String, path: String, content: String, message: String, branch: String, sha: String? = nil) async throws -> GitHubCreateUpdateFileResponse {
    let encodedContent = Data(content.utf8).base64EncodedString()
    
    var currentSha = sha
    if currentSha == nil {
        do {
            let existing = try await getFileContents(owner: owner, repo: repo, path: path, branch: branch)
            if case .file(let fileContent) = existing {
                currentSha = fileContent.sha
            }
        } catch {
            print("Note: File does not exist; will create new file")
        }
    }
    
    let url = "https://api.github.com/repos/\(owner)/\(repo)/contents/\(path)"
    var body: [String: Any] = [
        "message": message,
        "content": encodedContent,
        "branch": branch
    ]
    if let currentSha = currentSha {
        body["sha"] = currentSha
    }
    
    let response = try await githubRequest(url: url, options: RequestOptions(method: "PUT", body: body))
    let data = try JSONSerialization.data(withJSONObject: response)
    return try JSONDecoder().decode(GitHubCreateUpdateFileResponse.self, from: data)
}

/**
 Pushes multiple files to a GitHub repository in a single commit.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - branch: Branch to push to.
 - files: An array of file operations (each with a path and content).
 - message: Commit message.
 - Returns: The updated reference information.
 - Throws: An error if the API request fails.
 */
public func pushFiles(owner: String, repo: String, branch: String, files: [FileOperation], message: String) async throws -> Any {
    let refURL = "https://api.github.com/repos/\(owner)/\(repo)/git/refs/heads/\(branch)"
    let refResponse = try await githubRequest(url: refURL)
    let refData = try JSONSerialization.data(withJSONObject: refResponse)
    let ref = try JSONDecoder().decode(GitHubReference.self, from: refData)
    let commitSha = ref.object.sha
    
    let tree = try await createTree(owner: owner, repo: repo, files: files, baseTree: commitSha)
    let commit = try await createCommit(owner: owner, repo: repo, message: message, tree: tree.sha, parents: [commitSha])
    return try await updateReference(owner: owner, repo: repo, ref: "heads/\(branch)", sha: commit.sha)
}

/**
 Creates a Git tree for the specified file operations.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - files: An array of file operations.
 - baseTree: Optional base tree SHA.
 - Returns: A `GitHubTree` representing the new tree.
 - Throws: An error if the API request fails.
 */
private func createTree(owner: String, repo: String, files: [FileOperation], baseTree: String?) async throws -> GitHubTree {
    let tree = files.map { file in
        return [
            "path": file.path,
            "mode": "100644",
            "type": "blob",
            "content": file.content
        ]
    }
    
    let body: [String: Any] = [
        "tree": tree,
        "base_tree": baseTree as Any
    ]
    
    let response = try await githubRequest(url: "https://api.github.com/repos/\(owner)/\(repo)/git/trees", options: RequestOptions(method: "POST", body: body))
    let data = try JSONSerialization.data(withJSONObject: response)
    return try JSONDecoder().decode(GitHubTree.self, from: data)
}

/**
 Creates a Git commit.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - message: Commit message.
 - tree: Tree SHA.
 - parents: An array of parent commit SHAs.
 - Returns: A `GitHubCommit` representing the new commit.
 - Throws: An error if the API request fails.
 */
private func createCommit(owner: String, repo: String, message: String, tree: String, parents: [String]) async throws -> GitHubCommit {
    let body: [String: Any] = [
        "message": message,
        "tree": tree,
        "parents": parents
    ]
    let response = try await githubRequest(url: "https://api.github.com/repos/\(owner)/\(repo)/git/commits", options: RequestOptions(method: "POST", body: body))
    let data = try JSONSerialization.data(withJSONObject: response)
    return try JSONDecoder().decode(GitHubCommit.self, from: data)
}

/**
 Updates a Git reference to point to a new commit SHA.
 
 - Parameters:
 - owner: Repository owner.
 - repo: Repository name.
 - ref: Reference to update (e.g., "heads/main").
 - sha: New commit SHA.
 - Returns: A `GitHubReference` representing the updated reference.
 - Throws: An error if the API request fails.
 */
private func updateReference(owner: String, repo: String, ref: String, sha: String) async throws -> GitHubReference {
    let body: [String: Any] = [
        "sha": sha,
        "force": true
    ]
    let response = try await githubRequest(url: "https://api.github.com/repos/\(owner)/\(repo)/git/refs/\(ref)", options: RequestOptions(method: "PATCH", body: body))
    let data = try JSONSerialization.data(withJSONObject: response)
    return try JSONDecoder().decode(GitHubReference.self, from: data)
}
