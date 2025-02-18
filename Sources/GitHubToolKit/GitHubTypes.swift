//
//  GitHubTypes.swift
//  GitHubTools
//
//  Created by Norikazu Muramoto on 2025/02/18
//

import Foundation

// MARK: - GitHub Models

/// Represents an author or committer.
public struct GitHubAuthor: Codable, Sendable {
    public let name: String
    public let email: String
    public let date: String
}

/// Represents the owner of a repository.
public struct GitHubOwner: Codable, Sendable {
    public let login: String
    public let id: Int
    public let node_id: String
    public let avatar_url: String
    public let url: String
    public let html_url: String
    public let type: String
}

/// Represents a GitHub repository.
public struct GitHubRepository: Codable, Sendable {
    public let id: Int
    public let node_id: String
    public let name: String
    public let full_name: String
    public let `private`: Bool
    public let owner: GitHubOwner
    public let html_url: String
    public let description: String?
    public let fork: Bool
    public let url: String
    public let created_at: String
    public let updated_at: String
    public let pushed_at: String
    public let git_url: String
    public let ssh_url: String
    public let clone_url: String
    public let default_branch: String
}

/// Represents the links for file content.
public struct GitHubFileContentLinks: Codable, Sendable {
    public let `self`: String
    public let git: String?
    public let html: String?
}

/// Represents a file's content.
public struct GitHubFileContent: Codable, Sendable {
    public let name: String
    public let path: String
    public let sha: String
    public let size: Int
    public let url: String
    public let html_url: String
    public let git_url: String
    public let download_url: String
    public let type: String
    public let content: String?
    public let encoding: String?
    public let _links: GitHubFileContentLinks
}

/// Represents a directory's content.
public struct GitHubDirectoryContent: Codable, Sendable {
    public let type: String
    public let size: Int
    public let name: String
    public let path: String
    public let sha: String
    public let url: String
    public let git_url: String
    public let html_url: String
    public let download_url: String?
}

/// Represents content that can either be a file or a directory.
public enum GitHubContent: Codable, Sendable {
    case file(GitHubFileContent)
    case directory([GitHubDirectoryContent])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let fileContent = try? container.decode(GitHubFileContent.self) {
            self = .file(fileContent)
        } else if let directoryContent = try? container.decode([GitHubDirectoryContent].self) {
            self = .directory(directoryContent)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode GitHubContent")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .file(let fileContent):
            try container.encode(fileContent)
        case .directory(let directoryContent):
            try container.encode(directoryContent)
        }
    }
}

/// Represents an entry in a Git tree.
public struct GitHubTreeEntry: Codable, Sendable {
    public let path: String
    public let mode: String
    public let type: String
    public let size: Int?
    public let sha: String
    public let url: String
}

/// Represents a Git tree.
public struct GitHubTree: Codable, Sendable {
    public let sha: String
    public let url: String
    public let tree: [GitHubTreeEntry]
    public let truncated: Bool
}

/// Represents a reference to a Git tree.
public struct GitHubTreeReference: Codable, Sendable {
    public let sha: String
    public let url: String
}

/// Represents a parent commit.
public struct GitHubParent: Codable, Sendable {
    public let sha: String
    public let url: String
}

/// Represents the object part of a Git reference.
public struct GitHubReferenceObject: Codable, Sendable {
    public let sha: String
    public let type: String
    public let url: String
}

/// Represents a Git reference.
public struct GitHubReference: Codable, Sendable {
    public let ref: String
    public let node_id: String
    public let url: String
    public let `object`: GitHubReferenceObject
}

/// Represents an issue assignee.
public struct GitHubIssueAssignee: Codable, Sendable {
    public let login: String
    public let id: Int
    public let avatar_url: String
    public let url: String
    public let html_url: String
}

/// Represents a label for an issue.
public struct GitHubLabel: Codable, Sendable {
    public let id: Int
    public let node_id: String
    public let url: String
    public let name: String
    public let color: String
    public let `default`: Bool
    public let description: String?
}

/// Represents a milestone for an issue.
public struct GitHubMilestone: Codable, Sendable {
    public let url: String
    public let html_url: String
    public let labels_url: String
    public let id: Int
    public let node_id: String
    public let number: Int
    public let title: String
    public let description: String
    public let state: String
}

/// Represents an issue.
public struct GitHubIssue: Codable, Sendable {
    public let url: String
    public let repository_url: String
    public let labels_url: String
    public let comments_url: String
    public let events_url: String
    public let html_url: String
    public let id: Int
    public let node_id: String
    public let number: Int
    public let title: String
    public let user: GitHubIssueAssignee
    public let labels: [GitHubLabel]
    public let state: String
    public let locked: Bool
    public let assignee: GitHubIssueAssignee?
    public let assignees: [GitHubIssueAssignee]
    public let milestone: GitHubMilestone?
    public let comments: Int
    public let created_at: String
    public let updated_at: String
    public let closed_at: String?
    public let body: String?
}

/// Represents a GitHub search response.
public struct GitHubSearchResponse<T: Codable & Sendable>: Codable, Sendable {
    public let total_count: Int
    public let incomplete_results: Bool
    public let items: [T]
}

/// Represents a pull request reference.
public struct GitHubPullRequestRef: Codable, Sendable {
    public let label: String
    public let ref: String
    public let sha: String
    public let user: GitHubIssueAssignee
    public let repo: GitHubRepository
}

/// Represents a pull request.
public struct GitHubPullRequest: Codable, Sendable {
    public let url: String
    public let id: Int
    public let node_id: String
    public let html_url: String
    public let diff_url: String
    public let patch_url: String
    public let issue_url: String
    public let number: Int
    public let state: String
    public let locked: Bool
    public let title: String
    public let user: GitHubIssueAssignee
    public let body: String?
    public let created_at: String
    public let updated_at: String
    public let closed_at: String?
    public let merged_at: String?
    public let merge_commit_sha: String?
    public let assignee: GitHubIssueAssignee?
    public let assignees: [GitHubIssueAssignee]
    public let requested_reviewers: [GitHubIssueAssignee]
    public let labels: [GitHubLabel]
    public let head: GitHubPullRequestRef
    public let base: GitHubPullRequestRef
}

/// Represents a pull request review.
public struct GitHubPullRequestReview: Codable, Sendable {
    public let id: Int
    public let node_id: String
    public let user: GitHubIssueAssignee
    public let body: String?
    public let state: String
    public let html_url: String
    public let pull_request_url: String
    public let commit_id: String
    public let submitted_at: String?
    public let author_association: String
}

/// Represents a parent commit for a file update.
public struct GitHubParentForFileUpdate: Codable, Sendable {
    public let sha: String
    public let url: String
    public let html_url: String
}

/// Represents commit information for a file update.
public struct GitHubCommitForFileUpdate: Codable, Sendable {
    public let sha: String
    public let node_id: String
    public let url: String
    public let html_url: String
    public let author: GitHubAuthor
    public let committer: GitHubAuthor
    public let message: String
    public let tree: GitHubTreeReference
    public let parents: [GitHubParentForFileUpdate]
}

/// Alias GitHubCommit to GitHubCommitForFileUpdate for file-update operations.
public typealias GitHubCommit = GitHubCommitForFileUpdate

/// Represents the response from a create/update file operation.
public struct GitHubCreateUpdateFileResponse: Codable, Sendable {
    /// The file content that was created or updated.
    public let content: GitHubFileContent?
    /// The commit information associated with the file change.
    public let commit: GitHubCommitForFileUpdate
}
