//
//  GitHubToolKitTests.swift
//  GitHubToolKitTests
//
//  Created by Norikazu Muramoto on 2025/02/18
//

import Testing
import Foundation
@testable import GitHubToolKit

// MARK: - AnySendableBox

/// A simple type-erased Sendable wrapper.
public struct AnySendableBox: @unchecked Sendable {
    public let value: Any
    public init(_ value: Any) {
        self.value = value
    }
}

// MARK: - (必要に応じて) GitHubIssueComment の定義
// GitHubToolKit 側に以下のようなモデルが定義されていなければ、追加してください。
/*
 public struct GitHubIssueComment: Codable, Sendable {
 public let id: Int
 public let node_id: String
 public let url: String
 public let html_url: String
 public let user: GitHubIssueAssignee
 public let body: String
 public let created_at: String
 public let updated_at: String
 }
 */

// MARK: - Mock Network Response

actor MockURLSession {
    static let shared = MockURLSession()
    
    private var mockResponse: AnySendableBox?
    private var mockError: Error?
    
    func setResponse(_ response: any Sendable) {
        // response は Sendable な型である必要があります
        self.mockResponse = AnySendableBox(response)
        self.mockError = nil
    }
    
    func setError(_ error: Error) {
        self.mockError = error
        self.mockResponse = nil
    }
    
    func getResponse() -> AnySendableBox? {
        return mockResponse
    }
    
    func getError() -> Error? {
        return mockError
    }
    
    func reset() {
        mockResponse = nil
        mockError = nil
    }
}

// MARK: - Test Helpers

func mockGitHubResponse(_ response: any Sendable) async {
    await MockURLSession.shared.setResponse(response)
}

func mockGitHubError(_ error: Error) async {
    await MockURLSession.shared.setError(error)
}

struct GitHubToolsTestHelpers {
    /// Our local version of githubRequest, which uses the mock session.
    func githubRequest(url: String, options: RequestOptions = RequestOptions()) async throws -> Any {
        if let error = await MockURLSession.shared.getError() {
            throw error
        }
        if let box = await MockURLSession.shared.getResponse() {
            return box.value
        }
        throw NSError(domain: "MockURLSession", code: 0, userInfo: [NSLocalizedDescriptionKey: "No mock response or error set"])
    }
    
    // Helper functions to create mock data using existing models.
    func createMockGitHubOwner() -> GitHubOwner {
        return GitHubOwner(
            login: "testOwner",
            id: 1,
            node_id: "owner123",
            avatar_url: "https://github.com/avatar.png",
            url: "https://api.github.com/users/testOwner",
            html_url: "https://github.com/testOwner",
            type: "User"
        )
    }
    
    func createMockRepository(owner: GitHubOwner) -> GitHubRepository {
        return GitHubRepository(
            id: 1,
            node_id: "repo123",
            name: "test-repo",
            full_name: "\(owner.login)/test-repo",
            private: false,
            owner: owner,
            html_url: "https://github.com/\(owner.login)/test-repo",
            description: "Test repository",
            fork: false,
            url: "https://api.github.com/repos/\(owner.login)/test-repo",
            created_at: "2025-02-18T00:00:00Z",
            updated_at: "2025-02-18T00:00:00Z",
            pushed_at: "2025-02-18T00:00:00Z",
            git_url: "git://github.com/\(owner.login)/test-repo.git",
            ssh_url: "git@github.com:\(owner.login)/test-repo.git",
            clone_url: "https://github.com/\(owner.login)/test-repo.git",
            default_branch: "main"
        )
    }
    
    func createIssueAssignee(from owner: GitHubOwner) -> GitHubIssueAssignee {
        return GitHubIssueAssignee(
            login: owner.login,
            id: owner.id,
            avatar_url: owner.avatar_url,
            url: owner.url,
            html_url: owner.html_url
        )
    }
}

// MARK: - Base Test Suite

@Suite("GitHub Tools Tests")
struct GitHubToolsTests {
    let helpers = GitHubToolsTestHelpers()
    
    // MARK: Setup and Teardown
    func setUp() async throws {
        await MockURLSession.shared.reset()
    }
    
    // MARK: - CreateOrUpdateFile Tool Tests
    @Test("CreateOrUpdateFile tool creates a file successfully")
    func testCreateOrUpdateFileTool() async throws {
        let tool = CreateOrUpdateFileTool()
        let args = CreateOrUpdateFileArgs(
            owner: "testOwner",
            repo: "testRepo",
            path: "test.txt",
            content: "Test content",
            message: "Test commit",
            branch: "main"
        )
        
        let mockResponse = GitHubCreateUpdateFileResponse(
            content: GitHubFileContent(
                name: "test.txt",
                path: "test.txt",
                sha: "abc123",
                size: 12,
                url: "https://api.github.com/repos/test/test.txt",
                html_url: "https://github.com/test/test.txt",
                git_url: "https://api.github.com/repos/test/git/test.txt",
                download_url: "https://raw.githubusercontent.com/test/test.txt",
                type: "file",
                content: "Test content",
                encoding: "base64",
                _links: GitHubFileContentLinks(
                    self: "https://api.github.com/repos/test/test.txt",
                    git: "https://api.github.com/repos/test/git/test.txt",
                    html: "https://github.com/test/test.txt"
                )
            ),
            commit: GitHubCommitForFileUpdate(
                sha: "def456",
                node_id: "node123",
                url: "https://api.github.com/repos/test/commits/def456",
                html_url: "https://github.com/test/commit/def456",
                author: GitHubAuthor(name: "Test User", email: "test@example.com", date: "2025-02-18T00:00:00Z"),
                committer: GitHubAuthor(name: "Test User", email: "test@example.com", date: "2025-02-18T00:00:00Z"),
                message: "Test commit",
                tree: GitHubTreeReference(sha: "tree123", url: "https://api.github.com/repos/test/git/trees/tree123"),
                parents: [GitHubParentForFileUpdate(
                    sha: "parent123",
                    url: "https://api.github.com/repos/test/commits/parent123",
                    html_url: "https://github.com/test/commit/parent123"
                )]
            )
        )
        
        await mockGitHubResponse(mockResponse)
        
        let result = try await tool.run(args)
        #expect(result.contains("def456"))
        #expect(result.contains("Test commit"))
    }
    
    // MARK: - SearchRepositories Tool Tests
    @Test("SearchRepositories tool returns repository results")
    func testSearchRepositoriesTool() async throws {
        let tool = SearchRepositoriesTool()
        let args = SearchRepositoriesArgs(query: "test", page: 1, perPage: 10)
        
        let mockOwner = helpers.createMockGitHubOwner()
        let mockRepo = helpers.createMockRepository(owner: mockOwner)
        
        let mockResponse = GitHubSearchResponse(
            total_count: 1,
            incomplete_results: false,
            items: [mockRepo]
        )
        
        await mockGitHubResponse(mockResponse)
        
        let result = try await tool.run(args)
        #expect(result.contains("test-repo"))
        #expect(result.contains("testOwner"))
    }
    
    // MARK: - CreateRepository Tool Tests
    @Test("CreateRepository tool creates a repository successfully")
    func testCreateRepositoryTool() async throws {
        let tool = CreateRepositoryTool()
        let args = CreateRepositoryArgs(
            name: "new-repo",
            description: "Test repository",
            isPrivate: true,
            autoInit: true
        )
        
        let mockOwner = helpers.createMockGitHubOwner()
        let mockRepo = helpers.createMockRepository(owner: mockOwner)
        
        await mockGitHubResponse(mockRepo)
        
        let result = try await tool.run(args)
        #expect(result.contains("new-repo"))
        #expect(result.contains("Test repository"))
    }
    
    // MARK: - GetFileContents Tool Tests
    @Test("GetFileContents tool retrieves file contents")
    func testGetFileContentsTool() async throws {
        let tool = GetFileContentsTool()
        let args = GetFileContentsArgs(
            owner: "testOwner",
            repo: "testRepo",
            path: "test.txt",
            branch: "main"
        )
        
        let mockContent = GitHubContent.file(GitHubFileContent(
            name: "test.txt",
            path: "test.txt",
            sha: "abc123",
            size: 12,
            url: "https://api.github.com/repos/test/test.txt",
            html_url: "https://github.com/test/test.txt",
            git_url: "https://api.github.com/repos/test/git/test.txt",
            download_url: "https://raw.githubusercontent.com/test/test.txt",
            type: "file",
            content: "VGVzdCBjb250ZW50", // Base64 encoded "Test content"
            encoding: "base64",
            _links: GitHubFileContentLinks(
                self: "https://api.github.com/repos/test/test.txt",
                git: "https://api.github.com/repos/test/git/test.txt",
                html: "https://github.com/test/test.txt"
            )
        ))
        
        await mockGitHubResponse(mockContent)
        
        let result = try await tool.run(args)
        #expect(result.contains("test.txt"))
        #expect(result.contains("VGVzdCBjb250ZW50"))
    }
    
    // MARK: - PushFiles Tool Tests
    @Test("PushFiles tool pushes multiple files successfully")
    func testPushFilesTool() async throws {
        let tool = PushFilesTool()
        let files = [
            FileOperation(path: "test1.txt", content: "Content 1"),
            FileOperation(path: "test2.txt", content: "Content 2")
        ]
        
        let args = PushFilesArgs(
            owner: "testOwner",
            repo: "testRepo",
            branch: "main",
            files: files,
            message: "Add test files"
        )
        
        let mockReference = GitHubReference(
            ref: "refs/heads/main",
            node_id: "node123",
            url: "https://api.github.com/repos/test/git/refs/heads/main",
            object: GitHubReferenceObject(
                sha: "abc123",
                type: "commit",
                url: "https://api.github.com/repos/test/git/commits/abc123"
            )
        )
        
        await mockGitHubResponse(mockReference)
        
        let result = try await tool.run(args)
        #expect(result.contains("abc123"))
        #expect(result.contains("refs/heads/main"))
    }
    
    // MARK: - CreateIssue Tool Tests
    @Test("CreateIssue tool creates an issue successfully")
    func testCreateIssueTool() async throws {
        let tool = CreateIssueTool()
        let args = CreateIssueArgs(
            owner: "testOwner",
            repo: "testRepo",
            title: "Test Issue",
            body: "Test description",
            assignees: ["user1"],
            milestone: 1,
            labels: ["bug"]
        )
        
        let mockAssignee = GitHubIssueAssignee(
            login: "creator",
            id: 1,
            avatar_url: "https://github.com/avatar.png",
            url: "https://api.github.com/users/creator",
            html_url: "https://github.com/creator"
        )
        
        let mockLabel = GitHubLabel(
            id: 1,
            node_id: "label123",
            url: "https://api.github.com/repos/test/labels/bug",
            name: "bug",
            color: "red",
            default: true,
            description: "Bug label"
        )
        
        let mockIssue = GitHubIssue(
            url: "https://api.github.com/repos/test/issues/1",
            repository_url: "https://api.github.com/repos/test",
            labels_url: "https://api.github.com/repos/test/issues/1/labels",
            comments_url: "https://api.github.com/repos/test/issues/1/comments",
            events_url: "https://api.github.com/repos/test/issues/1/events",
            html_url: "https://github.com/test/issues/1",
            id: 1,
            node_id: "issue123",
            number: 1,
            title: "Test Issue",
            user: mockAssignee,
            labels: [mockLabel],
            state: "open",
            locked: false,
            assignee: nil,
            assignees: [],
            milestone: nil,
            comments: 0,
            created_at: "2025-02-18T00:00:00Z",
            updated_at: "2025-02-18T00:00:00Z",
            closed_at: nil,
            body: "Test description"
        )
        
        await mockGitHubResponse(mockIssue)
        
        let result = try await tool.run(args)
        #expect(result.contains("Test Issue"))
        #expect(result.contains("Test description"))
        #expect(result.contains("bug"))
    }
    
    // MARK: - CreatePullRequest Tool Tests
    @Test("CreatePullRequest tool creates a pull request successfully")
    func testCreatePullRequestTool() async throws {
        let tool = CreatePullRequestTool()
        let args = CreatePullRequestArgs(
            owner: "testOwner",
            repo: "testRepo",
            title: "Test PR",
            body: "Test PR description",
            head: "feature",
            base: "main",
            draft: false,
            maintainer_can_modify: true
        )
        
        let mockOwner = helpers.createMockGitHubOwner()
        let mockRepo = helpers.createMockRepository(owner: mockOwner)
        let mockAssignee = helpers.createIssueAssignee(from: mockOwner)
        
        let mockPR = GitHubPullRequest(
            url: "https://api.github.com/repos/test/pulls/1",
            id: 1,
            node_id: "node123",
            html_url: "https://github.com/test/pull/1",
            diff_url: "https://github.com/test/pull/1.diff",
            patch_url: "https://github.com/test/pull/1.patch",
            issue_url: "https://api.github.com/repos/test/issues/1",
            number: 1,
            state: "open",
            locked: false,
            title: "Test PR",
            user: mockAssignee,
            body: "Test PR description",
            created_at: "2025-02-18T00:00:00Z",
            updated_at: "2025-02-18T00:00:00Z",
            closed_at: nil,
            merged_at: nil,
            merge_commit_sha: nil,
            assignee: nil,
            assignees: [],
            requested_reviewers: [],
            labels: [],
            head: GitHubPullRequestRef(
                label: "\(mockOwner.login):feature",
                ref: "feature",
                sha: "sha123",
                user: mockAssignee,
                repo: mockRepo
            ),
            base: GitHubPullRequestRef(
                label: "\(mockOwner.login):main",
                ref: "main",
                sha: "sha456",
                user: mockAssignee,
                repo: mockRepo
            )
        )
        
        await mockGitHubResponse(mockPR)
        
        let result = try await tool.run(args)
        #expect(result.contains("Test PR"))
        #expect(result.contains("Test PR description"))
        #expect(result.contains("feature"))
        #expect(result.contains("main"))
    }
    
    // MARK: - ForkRepository Tool Tests
    @Test("ForkRepository tool forks a repository successfully")
    func testForkRepositoryTool() async throws {
        let tool = ForkRepositoryTool()
        let args = ForkRepositoryArgs(
            owner: "testOwner",
            repo: "testRepo",
            organization: "testOrg"
        )
        
        let mockOwner = GitHubOwner(
            login: "testOrg",
            id: 2,
            node_id: "org123",
            avatar_url: "https://github.com/testorg-avatar.png",
            url: "https://api.github.com/organizations/testOrg",
            html_url: "https://github.com/testOrg",
            type: "Organization"
        )
        
        let mockRepo = helpers.createMockRepository(owner: mockOwner)
        // Fork 用に repository の full_name や description を変更
        let forkedRepo = GitHubRepository(
            id: mockRepo.id,
            node_id: mockRepo.node_id,
            name: mockRepo.name,
            full_name: "\(mockOwner.login)/\(mockRepo.name)",
            private: mockRepo.private,
            owner: mockOwner,
            html_url: "https://github.com/\(mockOwner.login)/\(mockRepo.name)",
            description: "Forked repository",
            fork: true,
            url: "https://api.github.com/repos/\(mockOwner.login)/\(mockRepo.name)",
            created_at: mockRepo.created_at,
            updated_at: mockRepo.updated_at,
            pushed_at: mockRepo.pushed_at,
            git_url: mockRepo.git_url,
            ssh_url: mockRepo.ssh_url,
            clone_url: mockRepo.clone_url,
            default_branch: mockRepo.default_branch
        )
        
        await mockGitHubResponse(forkedRepo)
        
        let result = try await tool.run(args)
        #expect(result.contains("testOrg/\(mockRepo.name)"))
        #expect(result.contains("Forked repository"))
        #expect(result.contains("Organization"))
    }
    
    // MARK: - CreateBranch Tool Tests
    @Test("CreateBranch tool creates a new branch successfully")
    func testCreateBranchTool() async throws {
        let tool = CreateBranchTool()
        let args = CreateBranchArgs(
            owner: "testOwner",
            repo: "testRepo",
            branch: "feature",
            from_branch: "main"
        )
        
        let mockReference = GitHubReference(
            ref: "refs/heads/feature",
            node_id: "ref123",
            url: "https://api.github.com/repos/testOwner/testRepo/git/refs/heads/feature",
            object: GitHubReferenceObject(
                sha: "sha789",
                type: "commit",
                url: "https://api.github.com/repos/testOwner/testRepo/git/commits/sha789"
            )
        )
        
        await mockGitHubResponse(mockReference)
        
        let result = try await tool.run(args)
        #expect(result.contains("refs/heads/feature"))
        #expect(result.contains("sha789"))
        #expect(result.contains("commit"))
    }
    
    // MARK: - ListCommits Tool Tests (既存のモデルを利用)
    @Test("ListCommits tool lists commits successfully")
    func testListCommitsTool() async throws {
        let tool = ListCommitsTool()
        let args = ListCommitsArgs(
            owner: "testOwner",
            repo: "testRepo",
            sha: "main",
            page: 1,
            perPage: 10
        )
        
        // GitHubCommit は GitHubCommitForFileUpdate の型エイリアスとして定義されています
        let commit = GitHubCommit(
            sha: "commit123",
            node_id: "node123",
            url: "https://api.github.com/repos/testOwner/testRepo/git/commits/commit123",
            html_url: "https://github.com/testOwner/testRepo/commit/commit123",
            author: GitHubAuthor(name: "Test Author", email: "test@example.com", date: "2025-02-18T00:00:00Z"),
            committer: GitHubAuthor(name: "Test Committer", email: "committer@example.com", date: "2025-02-18T00:00:00Z"),
            message: "Test commit",
            tree: GitHubTreeReference(sha: "tree123", url: "https://api.github.com/repos/testOwner/testRepo/git/trees/tree123"),
            parents: [
                GitHubParentForFileUpdate(
                    sha: "parent123",
                    url: "https://api.github.com/repos/testOwner/testRepo/commits/parent123",
                    html_url: "https://github.com/testOwner/testRepo/commit/parent123"
                )
            ]
        )
        let mockCommits = [commit]
        
        await mockGitHubResponse(mockCommits)
        
        let result = try await tool.run(args)
        #expect(result.contains("commit123"))
        #expect(result.contains("Test commit"))
        #expect(result.contains("Test Author"))
        #expect(result.contains("Test Committer"))
        #expect(result.contains("parent123"))
    }
    
    // MARK: - ListIssues Tool Tests
    @Test("ListIssues tool lists issues successfully")
    func testListIssuesTool() async throws {
        let tool = ListIssuesTool()
        let args = ListIssuesArgs(
            owner: "testOwner",
            repo: "testRepo",
            direction: "desc",
            labels: ["bug"],
            page: 1,
            per_page: 10,
            since: "2025-01-01T00:00:00Z",
            sort: "created",
            state: "open"
        )
        
        let mockAssignee = GitHubIssueAssignee(
            login: "user1",
            id: 1,
            avatar_url: "https://github.com/avatar.png",
            url: "https://api.github.com/users/user1",
            html_url: "https://github.com/user1"
        )
        
        let mockMilestone = GitHubMilestone(
            url: "https://api.github.com/repos/testOwner/testRepo/milestones/1",
            html_url: "https://github.com/testOwner/testRepo/milestone/1",
            labels_url: "https://api.github.com/repos/testOwner/testRepo/milestones/1/labels",
            id: 1,
            node_id: "milestone123",
            number: 1,
            title: "v1.0",
            description: "First milestone",
            state: "open"
        )
        
        let issue1 = GitHubIssue(
            url: "https://api.github.com/repos/testOwner/testRepo/issues/1",
            repository_url: "https://api.github.com/repos/testOwner/testRepo",
            labels_url: "https://api.github.com/repos/testOwner/testRepo/issues/1/labels",
            comments_url: "https://api.github.com/repos/testOwner/testRepo/issues/1/comments",
            events_url: "https://api.github.com/repos/testOwner/testRepo/issues/1/events",
            html_url: "https://github.com/testOwner/testRepo/issues/1",
            id: 1,
            node_id: "issue123",
            number: 1,
            title: "First Issue",
            user: mockAssignee,
            labels: [
                GitHubLabel(
                    id: 1,
                    node_id: "label123",
                    url: "https://api.github.com/repos/testOwner/testRepo/labels/bug",
                    name: "bug",
                    color: "ff0000",
                    default: true,
                    description: "Bug label"
                )
            ],
            state: "open",
            locked: false,
            assignee: mockAssignee,
            assignees: [mockAssignee],
            milestone: mockMilestone,
            comments: 2,
            created_at: "2025-02-18T00:00:00Z",
            updated_at: "2025-02-18T01:00:00Z",
            closed_at: nil,
            body: "First issue description"
        )
        let issue2 = GitHubIssue(
            url: "https://api.github.com/repos/testOwner/testRepo/issues/2",
            repository_url: "https://api.github.com/repos/testOwner/testRepo",
            labels_url: "https://api.github.com/repos/testOwner/testRepo/issues/2/labels",
            comments_url: "https://api.github.com/repos/testOwner/testRepo/issues/2/comments",
            events_url: "https://api.github.com/repos/testOwner/testRepo/issues/2/events",
            html_url: "https://github.com/testOwner/testRepo/issues/2",
            id: 2,
            node_id: "issue456",
            number: 2,
            title: "Second Issue",
            user: mockAssignee,
            labels: [
                GitHubLabel(
                    id: 1,
                    node_id: "label123",
                    url: "https://api.github.com/repos/testOwner/testRepo/labels/bug",
                    name: "bug",
                    color: "ff0000",
                    default: true,
                    description: "Bug label"
                )
            ],
            state: "open",
            locked: false,
            assignee: nil,
            assignees: [],
            milestone: nil,
            comments: 0,
            created_at: "2025-02-18T02:00:00Z",
            updated_at: "2025-02-18T02:00:00Z",
            closed_at: nil,
            body: "Second issue description"
        )
        let mockIssues = [issue1, issue2]
        
        await mockGitHubResponse(mockIssues)
        
        let result = try await tool.run(args)
        #expect(result.contains("First Issue"))
        #expect(result.contains("Second Issue"))
        #expect(result.contains("bug"))
        #expect(result.contains("user1"))
        #expect(result.contains("v1.0"))
    }
    
    // MARK: - UpdateIssue Tool Tests
    @Test("UpdateIssue tool updates an issue successfully")
    func testUpdateIssueTool() async throws {
        let tool = UpdateIssueTool()
        let args = UpdateIssueArgs(
            owner: "testOwner",
            repo: "testRepo",
            issue_number: 1,
            title: "Updated Issue",
            body: "Updated description",
            assignees: ["user1"],
            milestone: 1,
            labels: ["bug", "enhancement"],
            state: "closed"
        )
        
        let mockAssignee = GitHubIssueAssignee(
            login: "user1",
            id: 1,
            avatar_url: "https://github.com/avatar.png",
            url: "https://api.github.com/users/user1",
            html_url: "https://github.com/user1"
        )
        
        let mockMilestone = GitHubMilestone(
            url: "https://api.github.com/repos/testOwner/testRepo/milestones/1",
            html_url: "https://github.com/testOwner/testRepo/milestone/1",
            labels_url: "https://api.github.com/repos/testOwner/testRepo/milestones/1/labels",
            id: 1,
            node_id: "milestone123",
            number: 1,
            title: "v1.0",
            description: "First milestone",
            state: "open"
        )
        
        let mockLabels = [
            GitHubLabel(
                id: 1,
                node_id: "label123",
                url: "https://api.github.com/repos/testOwner/testRepo/labels/bug",
                name: "bug",
                color: "ff0000",
                default: true,
                description: "Bug label"
            ),
            GitHubLabel(
                id: 2,
                node_id: "label456",
                url: "https://api.github.com/repos/testOwner/testRepo/labels/enhancement",
                name: "enhancement",
                color: "0000ff",
                default: true,
                description: "Enhancement label"
            )
        ]
        
        let mockUpdatedIssue = GitHubIssue(
            url: "https://api.github.com/repos/testOwner/testRepo/issues/1",
            repository_url: "https://api.github.com/repos/testOwner/testRepo",
            labels_url: "https://api.github.com/repos/testOwner/testRepo/issues/1/labels",
            comments_url: "https://api.github.com/repos/testOwner/testRepo/issues/1/comments",
            events_url: "https://api.github.com/repos/testOwner/testRepo/issues/1/events",
            html_url: "https://github.com/testOwner/testRepo/issues/1",
            id: 1,
            node_id: "issue123",
            number: 1,
            title: "Updated Issue",
            user: mockAssignee,
            labels: mockLabels,
            state: "closed",
            locked: false,
            assignee: mockAssignee,
            assignees: [mockAssignee],
            milestone: mockMilestone,
            comments: 0,
            created_at: "2025-02-18T00:00:00Z",
            updated_at: "2025-02-18T01:00:00Z",
            closed_at: "2025-02-18T01:00:00Z",
            body: "Updated description"
        )
        
        await mockGitHubResponse(mockUpdatedIssue)
        
        let result = try await tool.run(args)
        #expect(result.contains("Updated Issue"))
        #expect(result.contains("Updated description"))
        #expect(result.contains("closed"))
        #expect(result.contains("user1"))
        #expect(result.contains("bug"))
        #expect(result.contains("enhancement"))
        #expect(result.contains("v1.0"))
    }
    
    // MARK: - SearchUsers Tool Tests
    @Test("SearchUsers tool searches users successfully")
    func testSearchUsersTool() async throws {
        let tool = SearchUsersTool()
        let args = SearchUsersArgs(
            q: "type:user language:swift",
            order: "desc",
            page: 1,
            perPage: 10,
            sort: "repositories"
        )
        
        // 検索結果の T として GitHubIssueAssignee（ユーザー情報）を利用
        let user = GitHubIssueAssignee(
            login: "swiftdev",
            id: 1,
            avatar_url: "https://github.com/avatar.png",
            url: "https://api.github.com/users/swiftdev",
            html_url: "https://github.com/swiftdev"
        )
        // 追加情報としてユーザーの詳細が必要な場合は、GitHubToolKit 側のモデルに合わせて拡張してください。
        let mockUsersSearchResult = GitHubSearchResponse<GitHubIssueAssignee>(
            total_count: 1,
            incomplete_results: false,
            items: [user]
        )
        
        await mockGitHubResponse(mockUsersSearchResult)
        
        let result = try await tool.run(args)
        #expect(result.contains("swiftdev"))
        // ユーザー詳細（name, company など）が含まれる場合は、その文字列もチェック
    }
    
    // MARK: - GetIssue Tool Tests
    @Test("GetIssue tool retrieves issue details")
    func testGetIssueTool() async throws {
        let tool = GetIssueTool()
        let args = GetIssueArgs(
            owner: "testOwner",
            repo: "testRepo",
            issue_number: 1
        )
        
        // 既存の GitHubIssue モデルを利用
        let mockIssue: GitHubIssue = GitHubIssue(
            url: "https://api.github.com/repos/testOwner/testRepo/issues/1",
            repository_url: "https://api.github.com/repos/testOwner/testRepo",
            labels_url: "https://api.github.com/repos/testOwner/testRepo/issues/1/labels",
            comments_url: "https://api.github.com/repos/testOwner/testRepo/issues/1/comments",
            events_url: "https://api.github.com/repos/testOwner/testRepo/issues/1/events",
            html_url: "https://github.com/testOwner/testRepo/issues/1",
            id: 1,
            node_id: "issue123",
            number: 1,
            title: "Test Issue",
            user: GitHubIssueAssignee(
                login: "creator",
                id: 1,
                avatar_url: "https://github.com/avatar.png",
                url: "https://api.github.com/users/creator",
                html_url: "https://github.com/creator"
            ),
            labels: [],
            state: "open",
            locked: false,
            assignee: nil,
            assignees: [],
            milestone: nil,
            comments: 0,
            created_at: "2025-02-18T00:00:00Z",
            updated_at: "2025-02-18T00:00:00Z",
            closed_at: nil,
            body: "Test issue body"
        )
        
        await mockGitHubResponse(mockIssue)
        
        let result = try await tool.run(args)
        #expect(result.contains("Test Issue"))
        #expect(result.contains("Test issue body"))
    }
    
    // MARK: - Error Handling Tests
    @Test("Tools handle GitHub API errors appropriately")
    func testErrorHandling() async throws {
        let tool = GetIssueTool()
        let args = GetIssueArgs(owner: "testOwner", repo: "testRepo", issue_number: 1)
        
        let errorCases: [(GitHubError, Int)] = [
            (.resourceNotFound(message: "Issue not found", status: 404), 404),
            (.authentication(message: "Bad credentials", status: 401), 401),
            (.permission(message: "Not authorized", status: 403), 403),
            (.validation(message: "Validation failed", status: 422), 422),
            (.rateLimit(message: "API rate limit exceeded", status: 429, resetAt: Date().addingTimeInterval(3600)), 429),
            (.conflict(message: "Merge conflict", status: 409), 409)
        ]
        
        for (errorCase, status) in errorCases {
            await mockGitHubError(errorCase)
            
            do {
                _ = try await tool.run(args)
                #expect(false, "Expected error to be thrown for status \(status)")
            } catch {
                #expect(error is GitHubError)
                if let githubError = error as? GitHubError {
                    #expect(githubError.status == status)
                }
            }
        }
    }
    
    // MARK: - Complete Workflow Test
    @Test("Complete workflow with repository, branch, and pull request")
    func testCompleteWorkflow() async throws {
        let mockOwner = helpers.createMockGitHubOwner()
        let mockRepo = helpers.createMockRepository(owner: mockOwner)
        let mockAssignee = helpers.createIssueAssignee(from: mockOwner)
        
        // 1. Create repository
        let createRepoTool = CreateRepositoryTool()
        let createRepoArgs = CreateRepositoryArgs(
            name: "test-repo",
            description: "Test repository",
            isPrivate: true,
            autoInit: true
        )
        
        await mockGitHubResponse(mockRepo)
        let repoResult = try await createRepoTool.run(createRepoArgs)
        #expect(repoResult.contains("test-repo"))
        
        // 2. Create branch
        let createBranchTool = CreateBranchTool()
        let createBranchArgs = CreateBranchArgs(
            owner: mockOwner.login,
            repo: mockRepo.name,
            branch: "feature",
            from_branch: "main"
        )
        
        let mockBranchRef = GitHubReference(
            ref: "refs/heads/feature",
            node_id: "branch123",
            url: "https://api.github.com/repos/\(mockOwner.login)/\(mockRepo.name)/git/refs/heads/feature",
            object: GitHubReferenceObject(
                sha: "sha123",
                type: "commit",
                url: "https://api.github.com/repos/\(mockOwner.login)/\(mockRepo.name)/git/commits/sha123"
            )
        )
        
        await mockGitHubResponse(mockBranchRef)
        let branchResult = try await createBranchTool.run(createBranchArgs)
        #expect(branchResult.contains("feature"))
        #expect(branchResult.contains("sha123"))
        
        // 3. Create pull request
        let createPRTool = CreatePullRequestTool()
        let createPRArgs = CreatePullRequestArgs(
            owner: mockOwner.login,
            repo: mockRepo.name,
            title: "Add feature",
            body: "Implemented new feature",
            head: "feature",
            base: "main",
            draft: false,
            maintainer_can_modify: true
        )
        
        let mockPR = GitHubPullRequest(
            url: "https://api.github.com/repos/\(mockOwner.login)/\(mockRepo.name)/pulls/1",
            id: 1,
            node_id: "pr123",
            html_url: "https://github.com/\(mockOwner.login)/\(mockRepo.name)/pull/1",
            diff_url: "https://github.com/\(mockOwner.login)/\(mockRepo.name)/pull/1.diff",
            patch_url: "https://github.com/\(mockOwner.login)/\(mockRepo.name)/pull/1.patch",
            issue_url: "https://api.github.com/repos/\(mockOwner.login)/\(mockRepo.name)/issues/1",
            number: 1,
            state: "open",
            locked: false,
            title: "Add feature",
            user: mockAssignee,
            body: "Implemented new feature",
            created_at: "2025-02-18T00:00:00Z",
            updated_at: "2025-02-18T00:00:00Z",
            closed_at: nil,
            merged_at: nil,
            merge_commit_sha: nil,
            assignee: nil,
            assignees: [],
            requested_reviewers: [],
            labels: [],
            head: GitHubPullRequestRef(
                label: "\(mockOwner.login):feature",
                ref: "feature",
                sha: "sha123",
                user: mockAssignee,
                repo: mockRepo
            ),
            base: GitHubPullRequestRef(
                label: "\(mockOwner.login):main",
                ref: "main",
                sha: "sha456",
                user: mockAssignee,
                repo: mockRepo
            )
        )
        
        await mockGitHubResponse(mockPR)
        
        let prResult = try await createPRTool.run(createPRArgs)
        #expect(prResult.contains("Add feature"))
        #expect(prResult.contains("Implemented new feature"))
    }
}
