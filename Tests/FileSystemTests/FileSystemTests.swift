import Testing
import Foundation
import System
@testable import FileSystem

// MARK: - Test Utilities
extension FileManager {
    /// テストに必要なディレクトリの存在を確認
    func ensureAllowedDirectoryExists() throws {
        let allowedPath = "/tmp/allowed"
        if !fileExists(atPath: allowedPath) {
            try createDirectory(
                atPath: allowedPath,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
    
    /// テストファイルの削除
    func cleanupTestFile(_ path: String) {
        try? removeItem(atPath: path)
    }
    
    /// テスト用の一意のファイルパスを生成
    func uniqueTestFilePath(prefix: String) -> String {
        return "/tmp/allowed/\(prefix)_\(UUID().uuidString).txt"
    }
}

// MARK: - Tool Tests
@Suite("FileSystem Tool Tests")
struct FileSystemToolTests {
    
    // MARK: - ReadFile Tests
    @Test("ReadFile - Basic functionality")
    func testReadFile() async throws {
        try FileManager.default.ensureAllowedDirectoryExists()
        let tool = ReadFileTool()
        let testContent = "Hello, World!"
        let testFile = FileManager.default.uniqueTestFilePath(prefix: "read_test")
        
        try testContent.write(toFile: testFile, atomically: true, encoding: .utf8)
        
        let args = ReadFileArgs(path: testFile)
        let content = try await tool.run(args)
        #expect(content == testContent)
        
        FileManager.default.cleanupTestFile(testFile)
    }
    
    @Test("ReadFile - Access denied for unauthorized path")
    func testReadFileUnauthorizedAccess() async throws {
        try FileManager.default.ensureAllowedDirectoryExists()
        let tool = ReadFileTool()
        let args = ReadFileArgs(path: "/tmp/unauthorized/test.txt")
        
        await #expect(throws: Error.self) {
            _ = try await tool.run(args)
        }
    }
    
    // MARK: - WriteFile Tests
    @Test("WriteFile - Basic functionality")
    func testWriteFile() async throws {
        try FileManager.default.ensureAllowedDirectoryExists()
        let tool = WriteFileTool()
        let testContent = "Test content"
        let testFile = FileManager.default.uniqueTestFilePath(prefix: "write_test")
        
        let args = WriteFileArgs(path: testFile, content: testContent)
        let result = try await tool.run(args)
        #expect(result.contains("Successfully wrote"))
        
        let written = try String(contentsOfFile: testFile, encoding: .utf8)
        #expect(written == testContent)
        
        FileManager.default.cleanupTestFile(testFile)
    }
    
    // MARK: - EditFile and Diff Tests
    @Test("EditFile - Single line modification with diff")
    func testEditFileSingleLine() async throws {
        let fileManager = FileManager.default
        try fileManager.ensureAllowedDirectoryExists()
        
        let tool = EditFileTool()
        let testFile = fileManager.uniqueTestFilePath(prefix: "edit_single")
        let originalContent = "Original test content"
        
        // ファイルが確実に作成されることを確認
        guard fileManager.createFile(
            atPath: testFile,
            contents: originalContent.data(using: .utf8),
            attributes: nil
        ) else {
            throw NSError(
                domain: "TestError",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create test file"]
            )
        }
        
        let dryRunArgs = EditFileArgs(
            path: testFile,
            edits: [EditOperation(oldText: originalContent, newText: "Modified test content")],
            dryRun: true
        )
        
        let dryRunDiff = try await tool.run(dryRunArgs)
        
        // Diffフォーマットの検証
        #expect(dryRunDiff.contains("Index: \(testFile)"))
        #expect(dryRunDiff.contains("==================================================================="))
        #expect(dryRunDiff.contains("- 0: Original test content"))
        #expect(dryRunDiff.contains("+ 0: Modified test content"))
        
        // 実際の変更を適用
        let realArgs = EditFileArgs(
            path: testFile,
            edits: [EditOperation(oldText: originalContent, newText: "Modified test content")],
            dryRun: false
        )
        
        let result = try await tool.run(realArgs)
        #expect(result.contains("Edits applied"))
        
        let modifiedContent = try String(contentsOfFile: testFile, encoding: .utf8)
        #expect(modifiedContent == "Modified test content")
        
        fileManager.cleanupTestFile(testFile)
    }
    
    @Test("EditFile - Multiple line modifications")
    func testEditFileMultipleLines() async throws {
        let fileManager = FileManager.default
        try fileManager.ensureAllowedDirectoryExists()
        
        let tool = EditFileTool()
        let testFile = fileManager.uniqueTestFilePath(prefix: "edit_multiple")
        
        // 改行コードを明示的に指定
        let lines = [
            "First line",
            "Second line",
            "Third line",
            "Fourth line"
        ]
        let originalContent = lines.joined(separator: "\n")
        
        // ファイルが確実に作成されることを確認
        guard fileManager.createFile(
            atPath: testFile,
            contents: originalContent.data(using: .utf8),
            attributes: nil
        ) else {
            throw NSError(
                domain: "TestError",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create test file"]
            )
        }
        
        let args = EditFileArgs(
            path: testFile,
            edits: [
                EditOperation(oldText: lines[1], newText: "2nd line"),
                EditOperation(oldText: lines[3], newText: "4th line")
            ],
            dryRun: true
        )
        
        let diff = try await tool.run(args)
        
        // Diffの構造を検証
        let diffLines = diff.split(separator: "\n")
        #expect(diffLines.contains { $0.contains("- 1: Second line") })
        #expect(diffLines.contains { $0.contains("+ 1: 2nd line") })
        #expect(diffLines.contains { $0.contains("- 3: Fourth line") })
        #expect(diffLines.contains { $0.contains("+ 3: 4th line") })
        
        fileManager.cleanupTestFile(testFile)
    }
    
    @Test("EditFile - Non-existent text replacement")
    func testEditFileNonExistentText() async throws {
        let fileManager = FileManager.default
        try fileManager.ensureAllowedDirectoryExists()
        
        let tool = EditFileTool()
        let testFile = fileManager.uniqueTestFilePath(prefix: "edit_nonexistent")
        let content = "Test content"
        
        guard fileManager.createFile(
            atPath: testFile,
            contents: content.data(using: .utf8),
            attributes: nil
        ) else {
            throw NSError(
                domain: "TestError",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create test file"]
            )
        }
        
        let args = EditFileArgs(
            path: testFile,
            edits: [EditOperation(oldText: "non-existent", newText: "new")],
            dryRun: false
        )
        
        await #expect(throws: Error.self) {
            _ = try await tool.run(args)
        }
        
        fileManager.cleanupTestFile(testFile)
    }
    
    @Test("EditFile - Multiple sequential edits")
    func testEditFileSequentialEdits() async throws {
        let fileManager = FileManager.default
        try fileManager.ensureAllowedDirectoryExists()
        
        let tool = EditFileTool()
        let testFile = fileManager.uniqueTestFilePath(prefix: "edit_sequential")
        let originalContent = "AAA BBB CCC"
        
        guard fileManager.createFile(
            atPath: testFile,
            contents: originalContent.data(using: .utf8),
            attributes: nil
        ) else {
            throw NSError(
                domain: "TestError",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create test file"]
            )
        }
        
        let args = EditFileArgs(
            path: testFile,
            edits: [
                EditOperation(oldText: originalContent, newText: "111 222 333")
            ],
            dryRun: false
        )
        
        let result = try await tool.run(args)
        let modifiedContent = try String(contentsOfFile: testFile, encoding: .utf8)
        #expect(modifiedContent == "111 222 333")
        
        let diffLines = result.split(separator: "\n")
        #expect(diffLines.contains { $0.contains("- 0: AAA BBB CCC") })
        #expect(diffLines.contains { $0.contains("+ 0: 111 222 333") })
        
        fileManager.cleanupTestFile(testFile)
    }
    
    // MARK: - Directory Operations Tests
    @Test("CreateDirectory and ListDirectory functionality")
    func testDirectoryOperations() async throws {
        let fileManager = FileManager.default
        try fileManager.ensureAllowedDirectoryExists()
        
        let createTool = CreateDirectoryTool()
        let listTool = ListDirectoryTool()
        let testDir = "/tmp/allowed/test_dir_\(UUID().uuidString)"
        
        // Create directory
        let createArgs = CreateDirectoryArgs(path: testDir)
        let createResult = try await createTool.run(createArgs)
        #expect(createResult.contains("Directory created"))
        
        // Create test files
        let file1Path = (testDir as NSString).appendingPathComponent("file1_\(UUID().uuidString).txt")
        let file2Path = (testDir as NSString).appendingPathComponent("file2_\(UUID().uuidString).txt")
        
        try "test1".write(toFile: file1Path, atomically: true, encoding: .utf8)
        try "test2".write(toFile: file2Path, atomically: true, encoding: .utf8)
        
        // List directory
        let listArgs = ListDirectoryArgs(path: testDir)
        let contents = try await listTool.run(listArgs)
        #expect(contents.contains(file1Path.components(separatedBy: "/").last!))
        #expect(contents.contains(file2Path.components(separatedBy: "/").last!))
        
        fileManager.cleanupTestFile(testDir)
    }
    
    // MARK: - File Move and Info Tests
    @Test("MoveFile and GetFileInfo functionality")
    func testMoveAndInfo() async throws {
        let fileManager = FileManager.default
        try fileManager.ensureAllowedDirectoryExists()
        
        let moveTool = MoveFileTool()
        let infoTool = GetFileInfoTool()
        
        let sourceFile = fileManager.uniqueTestFilePath(prefix: "move_source")
        let destFile = fileManager.uniqueTestFilePath(prefix: "move_dest")
        
        try "test content".write(toFile: sourceFile, atomically: true, encoding: .utf8)
        
        let moveArgs = MoveFileArgs(source: sourceFile, destination: destFile)
        let moveResult = try await moveTool.run(moveArgs)
        #expect(moveResult.contains("Moved"))
        
        let infoArgs = GetFileInfoArgs(path: destFile)
        let fileInfo = try await infoTool.run(infoArgs)
        #expect(fileInfo.contains("NSFileSize"))
        #expect(!FileManager.default.fileExists(atPath: sourceFile))
        #expect(FileManager.default.fileExists(atPath: destFile))
        
        fileManager.cleanupTestFile(destFile)
    }
    
    // MARK: - List Allowed Directories Test
    @Test("ListAllowedDirectories functionality")
    func testListAllowedDirectories() async throws {
        try FileManager.default.ensureAllowedDirectoryExists()
        let tool = ListAllowedDirectoriesTool()
        let result = try await tool.run([:])
        
        let directories = result.split(separator: "\n")
        #expect(directories.count == 2)
        #expect(directories.contains { $0.contains("/tmp/allowed") })
        #expect(directories.contains { $0.contains("/Documents/allowed") })
    }
}
