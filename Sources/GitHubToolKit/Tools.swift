//
//  GitHubTools.swift
//  GitHubTools
//
//  Created by Norikazu Muramoto on 2025/02/18
//

import Foundation
import JSONSchema
import ContextProtocol

// MARK: - 1. CreateOrUpdateFile Tool

/// Input arguments for the create_or_update_file tool.
public struct CreateOrUpdateFileArgs: Codable, Sendable {
    public let owner: String
    public let repo: String
    public let path: String
    public let content: String
    public let message: String
    public let branch: String
    public let sha: String?
    
    public init(owner: String, repo: String, path: String, content: String, message: String, branch: String, sha: String? = nil) {
        self.owner = owner
        self.repo = repo
        self.path = path
        self.content = content
        self.message = message
        self.branch = branch
        self.sha = sha
    }
}

/// The create_or_update_file tool creates or updates a file in a GitHub repository.
public struct CreateOrUpdateFileTool: Tool {
    public var name: String = "create_or_update_file"
    public var description: String = "Create or update a single file in a GitHub repository."
    public var inputSchema: JSONSchema? = .object(
        description: "Schema for create_or_update_file input",
        properties: [
            "owner": .string(description: "Repository owner (username or organization)"),
            "repo": .string(description: "Repository name"),
            "path": .string(description: "Path where to create/update the file"),
            "content": .string(description: "Content of the file"),
            "message": .string(description: "Commit message"),
            "branch": .string(description: "Branch to create/update the file in"),
            "sha": .string(description: "SHA of the file being replaced")
        ],
        required: ["owner", "repo", "path", "content", "message", "branch"]
    )
    public var guide: String? = "Provide owner, repo, file path, content, commit message, branch, and optionally the SHA (when updating an existing file)."
    
    public init() { }
    
    public func run(_ input: CreateOrUpdateFileArgs) async throws -> String {
        let result = try await createOrUpdateFile(owner: input.owner,
                                                  repo: input.repo,
                                                  path: input.path,
                                                  content: input.content,
                                                  message: input.message,
                                                  branch: input.branch,
                                                  sha: input.sha)
        let jsonData = try JSONSerialization.data(withJSONObject: result)
        return String(decoding: jsonData, as: UTF8.self)
    }
}

// MARK: - 2. SearchRepositories Tool

/// Input arguments for the search_repositories tool.
public struct SearchRepositoriesArgs: Codable, Sendable {
    public let query: String
    public let page: Int?
    public let perPage: Int?
    
    public init(query: String, page: Int? = nil, perPage: Int? = nil) {
        self.query = query
        self.page = page
        self.perPage = perPage
    }
}

/// The search_repositories tool searches for GitHub repositories.
public struct SearchRepositoriesTool: Tool {
    public var name: String = "search_repositories"
    public var description: String = "Search for GitHub repositories."
    public var inputSchema: JSONSchema? = .object(
        description: "Schema for search_repositories input",
        properties: [
            "query": .string(description: "Search query (see GitHub search syntax)"),
            "page": .integer(description: "Page number"),
            "perPage": .integer(description: "Results per page")
        ],
        required: ["query"]
    )
    public var guide: String? = "Provide a search query and optionally page and perPage values to retrieve repositories."
    
    public init() { }
    
    public func run(_ input: SearchRepositoriesArgs) async throws -> String {
        let result = try await searchRepositories(query: input.query,
                                                    page: input.page ?? 1,
                                                    perPage: input.perPage ?? 30)
        let jsonData = try JSONEncoder().encode(result)
        return String(decoding: jsonData, as: UTF8.self)
    }
}

// MARK: - 3. CreateRepository Tool

/// Input arguments for the create_repository tool.
public struct CreateRepositoryArgs: Codable, Sendable {
    public let name: String
    public let description: String?
    public let isPrivate: Bool?
    public let autoInit: Bool?
    
    public init(name: String, description: String? = nil, isPrivate: Bool? = nil, autoInit: Bool? = nil) {
        self.name = name
        self.description = description
        self.isPrivate = isPrivate
        self.autoInit = autoInit
    }
}

/// The create_repository tool creates a new GitHub repository.
public struct CreateRepositoryTool: Tool {
    public var name: String = "create_repository"
    public var description: String = "Create a new GitHub repository in your account."
    public var inputSchema: JSONSchema? = .object(
        description: "Schema for create_repository input",
        properties: [
            "name": .string(description: "Repository name"),
            "description": .string(description: "Repository description"),
            "private": .boolean(description: "Whether the repository should be private"),
            "autoInit": .boolean(description: "Initialize with README.md")
        ],
        required: ["name"]
    )
    public var guide: String? = "Provide repository options to create a new repository."
    
    public init() { }
    
    public func run(_ input: CreateRepositoryArgs) async throws -> String {
        let result = try await createRepository(options: CreateRepositoryOptions(name: input.name,
                                                                                 description: input.description,
                                                                                 private: input.isPrivate,
                                                                                 autoInit: input.autoInit))
        let jsonData = try JSONEncoder().encode(result)
        return String(decoding: jsonData, as: UTF8.self)
    }
}

// MARK: - 4. Get File Contents Tool

/// Input arguments for the get_file_contents tool.
public struct GetFileContentsArgs: Codable, Sendable {
    public let owner: String
    public let repo: String
    public let path: String
    public let branch: String?
    
    public init(owner: String, repo: String, path: String, branch: String? = nil) {
        self.owner = owner
        self.repo = repo
        self.path = path
        self.branch = branch
    }
}

/// The get_file_contents tool retrieves the contents of a file or directory from a GitHub repository.
public struct GetFileContentsTool: Tool {
    public var name: String = "get_file_contents"
    public var description: String = "Get the contents of a file or directory from a GitHub repository."
    public var inputSchema: JSONSchema? = .object(
        description: "Schema for get_file_contents input",
        properties: [
            "owner": .string(description: "Repository owner (username or organization)"),
            "repo": .string(description: "Repository name"),
            "path": .string(description: "Path to the file or directory"),
            "branch": .string(description: "Branch to get contents from")
        ],
        required: ["owner", "repo", "path"]
    )
    public var guide: String? = "Provide owner, repo, file path, and optional branch to retrieve contents."
    
    public init() { }
    
    public func run(_ input: GetFileContentsArgs) async throws -> String {
        let content = try await getFileContents(owner: input.owner, repo: input.repo, path: input.path, branch: input.branch)
        let jsonData = try JSONSerialization.data(withJSONObject: content)
        return String(decoding: jsonData, as: UTF8.self)
    }
}

// MARK: - 5. Push Files Tool

/// Represents a file operation for the push_files tool.
public struct FileOperation: Codable, Sendable {
    public let path: String
    public let content: String
    
    public init(path: String, content: String) {
        self.path = path
        self.content = content
    }
}

/// Input arguments for the push_files tool.
public struct PushFilesArgs: Codable, Sendable {
    public let owner: String
    public let repo: String
    public let branch: String
    public let files: [FileOperation]
    public let message: String
    
    public init(owner: String, repo: String, branch: String, files: [FileOperation], message: String) {
        self.owner = owner
        self.repo = repo
        self.branch = branch
        self.files = files
        self.message = message
    }
}

/// The push_files tool pushes multiple files to a GitHub repository in a single commit.
public struct PushFilesTool: Tool {
    public var name: String = "push_files"
    public var description: String = "Push multiple files to a GitHub repository in a single commit."
    public var inputSchema: JSONSchema? = .object(
        description: "Schema for push_files input",
        properties: [
            "owner": .string(description: "Repository owner (username or organization)"),
            "repo": .string(description: "Repository name"),
            "branch": .string(description: "Branch to push to"),
            "files": .array(items: .object(
                description: "File operation",
                properties: [
                    "path": .string(description: "File path"),
                    "content": .string(description: "File content")
                ],
                required: ["path", "content"]
            )),
            "message": .string(description: "Commit message")
        ],
        required: ["owner", "repo", "branch", "files", "message"]
    )
    public var guide: String? = "Provide owner, repo, branch, an array of file operations, and a commit message."
    
    public init() { }
    
    public func run(_ input: PushFilesArgs) async throws -> String {
        let result = try await pushFiles(owner: input.owner, repo: input.repo, branch: input.branch, files: input.files, message: input.message)
        let jsonData = try JSONSerialization.data(withJSONObject: result)
        return String(decoding: jsonData, as: UTF8.self)
    }
}

// MARK: - 6. Create Issue Tool

/// Input arguments for the create_issue tool.
public struct CreateIssueArgs: Codable, Sendable {
    public let owner: String
    public let repo: String
    public let title: String
    public let body: String?
    public let assignees: [String]?
    public let milestone: Int?
    public let labels: [String]?
    
    public init(owner: String, repo: String, title: String, body: String? = nil, assignees: [String]? = nil, milestone: Int? = nil, labels: [String]? = nil) {
        self.owner = owner
        self.repo = repo
        self.title = title
        self.body = body
        self.assignees = assignees
        self.milestone = milestone
        self.labels = labels
    }
}

/// The create_issue tool creates a new issue in a GitHub repository.
public struct CreateIssueTool: Tool {
    public var name: String = "create_issue"
    public var description: String = "Create a new issue in a GitHub repository."
    public var inputSchema: JSONSchema? = .object(
        description: "Schema for create_issue input",
        properties: [
            "owner": .string(description: "Repository owner"),
            "repo": .string(description: "Repository name"),
            "title": .string(description: "Issue title"),
            "body": .string(description: "Issue body"),
            "assignees": .array(items: .string(description: "Assignee usernames")),
            "milestone": .integer(description: "Milestone number"),
            "labels": .array(items: .string(description: "Issue labels"))
        ],
        required: ["owner", "repo", "title"]
    )
    public var guide: String? = "Provide owner, repo, title, and optional issue details."
    
    public init() { }
    
    public func run(_ input: CreateIssueArgs) async throws -> String {
        let result = try await createIssue(owner: input.owner, repo: input.repo, options: [
            "title": input.title,
            "body": input.body as Any,
            "assignees": input.assignees as Any,
            "milestone": input.milestone as Any,
            "labels": input.labels as Any
        ])
        let jsonData = try JSONSerialization.data(withJSONObject: result)
        return String(decoding: jsonData, as: UTF8.self)
    }
}

// MARK: - 7. Create Pull Request Tool

/// Input arguments for the create_pull_request tool.
public struct CreatePullRequestArgs: Codable, Sendable {
    public let owner: String
    public let repo: String
    public let title: String
    public let body: String?
    public let head: String
    public let base: String
    public let draft: Bool?
    public let maintainer_can_modify: Bool?
    
    public init(owner: String, repo: String, title: String, body: String? = nil, head: String, base: String, draft: Bool? = nil, maintainer_can_modify: Bool? = nil) {
        self.owner = owner
        self.repo = repo
        self.title = title
        self.body = body
        self.head = head
        self.base = base
        self.draft = draft
        self.maintainer_can_modify = maintainer_can_modify
    }
}

/// The create_pull_request tool creates a new pull request in a GitHub repository.
public struct CreatePullRequestTool: Tool {
    public var name: String = "create_pull_request"
    public var description: String = "Create a new pull request in a GitHub repository."
    public var inputSchema: JSONSchema? = .object(
        description: "Schema for create_pull_request input",
        properties: [
            "owner": .string(description: "Repository owner"),
            "repo": .string(description: "Repository name"),
            "title": .string(description: "Pull request title"),
            "body": .string(description: "Pull request description"),
            "head": .string(description: "Branch with your changes"),
            "base": .string(description: "Branch to merge into"),
            "draft": .boolean(description: "Create as a draft pull request"),
            "maintainer_can_modify": .boolean(description: "Allow maintainers to modify")
        ],
        required: ["owner", "repo", "title", "head", "base"]
    )
    public var guide: String? = "Provide pull request details to create a new pull request."
    
    public init() { }
    
    public func run(_ input: CreatePullRequestArgs) async throws -> String {
        let pr = try await createPullRequest(params: [
            "owner": input.owner,
            "repo": input.repo,
            "title": input.title,
            "body": input.body as Any,
            "head": input.head,
            "base": input.base,
            "draft": input.draft as Any,
            "maintainer_can_modify": input.maintainer_can_modify as Any
        ])
        let jsonData = try JSONSerialization.data(withJSONObject: pr)
        return String(decoding: jsonData, as: UTF8.self)
    }
}

// MARK: - 8. Fork Repository Tool

/// Input arguments for the fork_repository tool.
public struct ForkRepositoryArgs: Codable, Sendable {
    public let owner: String
    public let repo: String
    public let organization: String?
    
    public init(owner: String, repo: String, organization: String? = nil) {
        self.owner = owner
        self.repo = repo
        self.organization = organization
    }
}

/// The fork_repository tool forks a GitHub repository.
public struct ForkRepositoryTool: Tool {
    public var name: String = "fork_repository"
    public var description: String = "Fork a GitHub repository to your account or specified organization."
    public var inputSchema: JSONSchema? = .object(
        description: "Schema for fork_repository input",
        properties: [
            "owner": .string(description: "Repository owner"),
            "repo": .string(description: "Repository name"),
            "organization": .string(description: "Organization to fork to")
        ],
        required: ["owner", "repo"]
    )
    public var guide: String? = "Provide owner, repo, and optional organization to fork the repository."
    
    public init() { }
    
    public func run(_ input: ForkRepositoryArgs) async throws -> String {
        let repo = try await forkRepository(owner: input.owner, repo: input.repo, organization: input.organization)
        let jsonData = try JSONSerialization.data(withJSONObject: repo)
        return String(decoding: jsonData, as: UTF8.self)
    }
}

// MARK: - 9. Create Branch Tool

/// Input arguments for the create_branch tool.
public struct CreateBranchArgs: Codable, Sendable {
    public let owner: String
    public let repo: String
    public let branch: String
    public let from_branch: String?
    
    public init(owner: String, repo: String, branch: String, from_branch: String? = nil) {
        self.owner = owner
        self.repo = repo
        self.branch = branch
        self.from_branch = from_branch
    }
}

/// The create_branch tool creates a new branch in a GitHub repository from a specified source branch.
/// If no source branch is provided, the default branch is used.
public struct CreateBranchTool: Tool {
    public var name: String = "create_branch"
    public var description: String = "Create a new branch in a GitHub repository."
    public var inputSchema: JSONSchema? = .object(
        description: "Schema for create_branch input",
        properties: [
            "owner": .string(description: "Repository owner"),
            "repo": .string(description: "Repository name"),
            "branch": .string(description: "Name for the new branch"),
            "from_branch": .string(description: "Source branch")
        ],
        required: ["owner", "repo", "branch"]
    )
    public var guide: String? = "Provide owner, repo, new branch name, and optionally a source branch."
    
    public init() { }
    
    public func run(_ input: CreateBranchArgs) async throws -> String {
        let branchRef = try await createBranchFromRef(owner: input.owner, repo: input.repo, newBranch: input.branch, fromBranch: input.from_branch)
        let jsonData = try JSONSerialization.data(withJSONObject: branchRef)
        return String(decoding: jsonData, as: UTF8.self)
    }
}

// MARK: - 10. List Commits Tool

/// Input arguments for the list_commits tool.
public struct ListCommitsArgs: Codable, Sendable {
    public let owner: String
    public let repo: String
    public let sha: String?
    public let page: Int?
    public let perPage: Int?
    
    public init(owner: String, repo: String, sha: String? = nil, page: Int? = nil, perPage: Int? = nil) {
        self.owner = owner
        self.repo = repo
        self.sha = sha
        self.page = page
        self.perPage = perPage
    }
}

/// The list_commits tool retrieves a list of commits from a branch in a GitHub repository.
public struct ListCommitsTool: Tool {
    public var name: String = "list_commits"
    public var description: String = "Get list of commits of a branch in a GitHub repository."
    public var inputSchema: JSONSchema? = .object(
        description: "Schema for list_commits input",
        properties: [
            "owner": .string(description: "Repository owner"),
            "repo": .string(description: "Repository name"),
            "sha": .string(description: "Commit SHA"),
            "page": .integer(description: "Page number"),
            "perPage": .integer(description: "Results per page")
        ],
        required: ["owner", "repo"]
    )
    public var guide: String? = "Provide owner, repo, and optionally sha, page, and perPage parameters to list commits."
    
    public init() { }
    
    public func run(_ input: ListCommitsArgs) async throws -> String {
        let response = try await listCommits(owner: input.owner, repo: input.repo, page: input.page ?? 1, perPage: input.perPage ?? 30, sha: input.sha)
        let jsonData = try JSONSerialization.data(withJSONObject: response)
        return String(decoding: jsonData, as: UTF8.self)
    }
}

// MARK: - 11. List Issues Tool

/// Input arguments for the list_issues tool.
public struct ListIssuesArgs: Codable, Sendable {
    public let owner: String
    public let repo: String
    public let direction: String?
    public let labels: [String]?
    public let page: Int?
    public let per_page: Int?
    public let since: String?
    public let sort: String?
    public let state: String?
    
    public init(owner: String, repo: String, direction: String? = nil, labels: [String]? = nil, page: Int? = nil, per_page: Int? = nil, since: String? = nil, sort: String? = nil, state: String? = nil) {
        self.owner = owner
        self.repo = repo
        self.direction = direction
        self.labels = labels
        self.page = page
        self.per_page = per_page
        self.since = since
        self.sort = sort
        self.state = state
    }
}

/// The list_issues tool retrieves a list of issues from a GitHub repository with optional filters.
public struct ListIssuesTool: Tool {
    public var name: String = "list_issues"
    public var description: String = "List issues in a GitHub repository with filtering options."
    public var inputSchema: JSONSchema? = .object(
        description: "Schema for list_issues input",
        properties: [
            "owner": .string(description: "Repository owner"),
            "repo": .string(description: "Repository name"),
            "direction": .string(description: "Sort direction (asc/desc)"),
            "labels": .array(items: .string(description: "Labels")),
            "page": .integer(description: "Page number"),
            "per_page": .integer(description: "Results per page"),
            "since": .string(description: "Only issues updated at or after this time"),
            "sort": .string(description: "Sort field (created/updated/comments)"),
            "state": .string(description: "Issue state (open/closed/all)")
        ],
        required: ["owner", "repo"]
    )
    public var guide: String? = "Provide owner, repo, and optional filters to list issues."
    
    public init() { }
    
    public func run(_ input: ListIssuesArgs) async throws -> String {
        let params: [String: String?] = [
            "direction": input.direction,
            "labels": input.labels?.joined(separator: ","),
            "page": input.page != nil ? "\(input.page!)" : nil,
            "per_page": input.per_page != nil ? "\(input.per_page!)" : nil,
            "since": input.since,
            "sort": input.sort,
            "state": input.state
        ]
        let response = try await listIssues(owner: input.owner, repo: input.repo, options: params)
        let jsonData = try JSONSerialization.data(withJSONObject: response)
        return String(decoding: jsonData, as: UTF8.self)
    }
}

// MARK: - 12. Update Issue Tool

/// Input arguments for the update_issue tool.
public struct UpdateIssueArgs: Codable, Sendable {
    public let owner: String
    public let repo: String
    public let issue_number: Int
    public let title: String?
    public let body: String?
    public let assignees: [String]?
    public let milestone: Int?
    public let labels: [String]?
    public let state: String?
    
    public init(owner: String, repo: String, issue_number: Int, title: String? = nil, body: String? = nil, assignees: [String]? = nil, milestone: Int? = nil, labels: [String]? = nil, state: String? = nil) {
        self.owner = owner
        self.repo = repo
        self.issue_number = issue_number
        self.title = title
        self.body = body
        self.assignees = assignees
        self.milestone = milestone
        self.labels = labels
        self.state = state
    }
}

/// The update_issue tool updates an existing issue in a GitHub repository.
public struct UpdateIssueTool: Tool {
    public var name: String = "update_issue"
    public var description: String = "Update an existing issue in a GitHub repository."
    public var inputSchema: JSONSchema? = .object(
        description: "Schema for update_issue input",
        properties: [
            "owner": .string(description: "Repository owner"),
            "repo": .string(description: "Repository name"),
            "issue_number": .integer(description: "Issue number"),
            "title": .string(description: "Issue title"),
            "body": .string(description: "Issue body"),
            "assignees": .array(items: .string(description: "Assignees")),
            "milestone": .integer(description: "Milestone"),
            "labels": .array(items: .string(description: "Labels")),
            "state": .string(description: "Issue state (open/closed)")
        ],
        required: ["owner", "repo", "issue_number"]
    )
    public var guide: String? = "Provide owner, repo, issue_number, and fields to update."
    
    public init() { }
    
    public func run(_ input: UpdateIssueArgs) async throws -> String {
        let response = try await updateIssue(owner: input.owner, repo: input.repo, issueNumber: input.issue_number, options: [
            "title": input.title as Any,
            "body": input.body as Any,
            "assignees": input.assignees as Any,
            "milestone": input.milestone as Any,
            "labels": input.labels as Any,
            "state": input.state as Any
        ])
        let jsonData = try JSONSerialization.data(withJSONObject: response)
        return String(decoding: jsonData, as: UTF8.self)
    }
}

// MARK: - 13. Add Issue Comment Tool

/// Input arguments for the add_issue_comment tool.
public struct AddIssueCommentArgs: Codable, Sendable {
    public let owner: String
    public let repo: String
    public let issue_number: Int
    public let body: String
    
    public init(owner: String, repo: String, issue_number: Int, body: String) {
        self.owner = owner
        self.repo = repo
        self.issue_number = issue_number
        self.body = body
    }
}

/// The add_issue_comment tool adds a comment to an existing issue.
public struct AddIssueCommentTool: Tool {
    public var name: String = "add_issue_comment"
    public var description: String = "Add a comment to an existing issue."
    public var inputSchema: JSONSchema? = .object(
        description: "Schema for add_issue_comment input",
        properties: [
            "owner": .string(description: "Repository owner"),
            "repo": .string(description: "Repository name"),
            "issue_number": .integer(description: "Issue number"),
            "body": .string(description: "Comment text")
        ],
        required: ["owner", "repo", "issue_number", "body"]
    )
    public var guide: String? = "Provide owner, repo, issue_number, and comment body."
    
    public init() { }
    
    public func run(_ input: AddIssueCommentArgs) async throws -> String {
        let response = try await addIssueComment(owner: input.owner, repo: input.repo, issueNumber: input.issue_number, body: input.body)
        let jsonData = try JSONSerialization.data(withJSONObject: response)
        return String(decoding: jsonData, as: UTF8.self)
    }
}

// MARK: - 14. Search Code Tool

/// Input arguments for the search_code tool.
public struct SearchCodeArgs: Codable, Sendable {
    public let q: String
    public let order: String?
    public let page: Int?
    public let perPage: Int?
    
    public init(q: String, order: String? = nil, page: Int? = nil, perPage: Int? = nil) {
        self.q = q
        self.order = order
        self.page = page
        self.perPage = perPage
    }
}

/// The search_code tool searches for code across GitHub repositories.
public struct SearchCodeTool: Tool {
    public var name: String = "search_code"
    public var description: String = "Search for code across GitHub repositories."
    public var inputSchema: JSONSchema? = .object(
        description: "Schema for search_code input",
        properties: [
            "q": .string(description: "Search query"),
            "order": .string(description: "Order (asc/desc)"),
            "page": .integer(description: "Page number"),
            "perPage": .integer(description: "Results per page")
        ],
        required: ["q"]
    )
    public var guide: String? = "Provide a search query and optional order, page, and perPage values."
    
    public init() { }
    
    public func run(_ input: SearchCodeArgs) async throws -> String {
        let response = try await searchCode(params: SearchOptions(q: input.q, order: input.order, page: input.page, per_page: input.perPage))
        let jsonData = try JSONSerialization.data(withJSONObject: response)
        return String(decoding: jsonData, as: UTF8.self)
    }
}

// MARK: - 15. Search Issues Tool

/// Input arguments for the search_issues tool.
public struct SearchIssuesArgs: Codable, Sendable {
    public let q: String
    public let order: String?
    public let page: Int?
    public let perPage: Int?
    public let sort: String?
    
    public init(q: String, order: String? = nil, page: Int? = nil, perPage: Int? = nil, sort: String? = nil) {
        self.q = q
        self.order = order
        self.page = page
        self.perPage = perPage
        self.sort = sort
    }
}

/// The search_issues tool searches for issues and pull requests across GitHub repositories.
public struct SearchIssuesTool: Tool {
    public var name: String = "search_issues"
    public var description: String = "Search for issues and pull requests across GitHub repositories."
    public var inputSchema: JSONSchema? = .object(
        description: "Schema for search_issues input",
        properties: [
            "q": .string(description: "Search query"),
            "order": .string(description: "Order (asc/desc)"),
            "page": .integer(description: "Page number"),
            "perPage": .integer(description: "Results per page"),
            "sort": .string(description: "Sort field")
        ],
        required: ["q"]
    )
    public var guide: String? = "Provide a search query and optional parameters for ordering, pagination, and sorting."
    
    public init() { }
    
    public func run(_ input: SearchIssuesArgs) async throws -> String {
        let response = try await searchIssues(params: SearchIssuesOptions(q: input.q, order: input.order, page: input.page, per_page: input.perPage, sort: input.sort))
        let jsonData = try JSONSerialization.data(withJSONObject: response)
        return String(decoding: jsonData, as: UTF8.self)
    }
}

// MARK: - 16. Search Users Tool

/// Input arguments for the search_users tool.
public struct SearchUsersArgs: Codable, Sendable {
    public let q: String
    public let order: String?
    public let page: Int?
    public let perPage: Int?
    public let sort: String?
    
    public init(q: String, order: String? = nil, page: Int? = nil, perPage: Int? = nil, sort: String? = nil) {
        self.q = q
        self.order = order
        self.page = page
        self.perPage = perPage
        self.sort = sort
    }
}

/// The search_users tool searches for users on GitHub.
public struct SearchUsersTool: Tool {
    public var name: String = "search_users"
    public var description: String = "Search for users on GitHub."
    public var inputSchema: JSONSchema? = .object(
        description: "Schema for search_users input",
        properties: [
            "q": .string(description: "Search query"),
            "order": .string(description: "Order (asc/desc)"),
            "page": .integer(description: "Page number"),
            "perPage": .integer(description: "Results per page"),
            "sort": .string(description: "Sort field")
        ],
        required: ["q"]
    )
    public var guide: String? = "Provide a search query and optional pagination and sorting parameters."
    
    public init() { }
    
    public func run(_ input: SearchUsersArgs) async throws -> String {
        let response = try await searchUsers(params: SearchUsersOptions(q: input.q, order: input.order, page: input.page, per_page: input.perPage, sort: input.sort))
        let jsonData = try JSONSerialization.data(withJSONObject: response)
        return String(decoding: jsonData, as: UTF8.self)
    }
}

// MARK: - 17. Get Issue Tool

/// Input arguments for the get_issue tool.
public struct GetIssueArgs: Codable, Sendable {
    public let owner: String
    public let repo: String
    public let issue_number: Int
    
    public init(owner: String, repo: String, issue_number: Int) {
        self.owner = owner
        self.repo = repo
        self.issue_number = issue_number
    }
}

/// The get_issue tool retrieves details of a specific issue in a GitHub repository.
public struct GetIssueTool: Tool {
    public var name: String = "get_issue"
    public var description: String = "Get details of a specific issue in a GitHub repository."
    public var inputSchema: JSONSchema? = .object(
        description: "Schema for get_issue input",
        properties: [
            "owner": .string(description: "Repository owner"),
            "repo": .string(description: "Repository name"),
            "issue_number": .integer(description: "Issue number")
        ],
        required: ["owner", "repo", "issue_number"]
    )
    public var guide: String? = "Provide owner, repo, and issue_number to retrieve issue details."
    
    public init() { }
    
    public func run(_ input: GetIssueArgs) async throws -> String {
        let response = try await getIssue(owner: input.owner, repo: input.repo, issueNumber: input.issue_number)
        let jsonData = try JSONSerialization.data(withJSONObject: response)
        return String(decoding: jsonData, as: UTF8.self)
    }
}
