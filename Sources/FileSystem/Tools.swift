//
//  Server.swift
//  servers
//
//  Created by Norikazu Muramoto on 2025/02/18
//

import Foundation
import ContextProtocol
import JSONSchema
import System

// MARK: - Path Normalization, Expansion, and Validation

/**
 Retrieves the home directory as a `FilePath` by reading the appropriate environment variable.
 
 - Returns: The home directory as a `FilePath`. On macOS/Linux, it uses the "HOME" environment variable;
 on Windows it uses "USERPROFILE" (defaulting to `"C:\\"` if not found).
 */
private func getHomeDirectory() -> FilePath {
    if let home = ProcessInfo.processInfo.environment["HOME"] {
        return FilePath(home)
    } else {
#if os(Windows)
        return FilePath(ProcessInfo.processInfo.environment["USERPROFILE"] ?? "C:\\")
#else
        return FilePath("/")
#endif
    }
}

/**
 Normalizes the given file path using Foundation's standardization.
 
 - Parameter path: A `FilePath` instance to normalize.
 - Returns: A new `FilePath` instance with the path standardized.
 */
private func normalizePath(_ path: FilePath) -> FilePath {
    return FilePath((path.string as NSString).standardizingPath)
}

/**
 Expands a file path that uses the tilde ("~") shorthand to the user's home directory.
 
 - Parameter filepath: A string representing a file path. If it starts with "~" or "~/",
 it will be expanded to the full home directory path.
 - Returns: A normalized `FilePath` with the tilde expanded.
 */
private func expandHome(_ filepath: String) -> FilePath {
    if filepath == "~" || filepath.hasPrefix("~/") {
        let home = getHomeDirectory()
        // Remove the leading "~" and join with home directory.
        let relative = String(filepath.dropFirst())
        return normalizePath(FilePath(home.string + "/" + relative))
    }
    return FilePath(filepath)
}

/**
 Constructs a list of allowed directories from an array of string paths.
 
 - Parameter args: An array of string paths.
 - Returns: An array of normalized `FilePath` instances after expanding the tilde shorthand.
 */
private func allowedDirectories(from args: [String]) -> [FilePath] {
    return args.map { normalizePath(expandHome($0)) }
}

/// Global allowed directories for file system operations. These directories are used to
/// validate that requested file paths are within permitted boundaries. In this example,
/// the allowed directories are set to the user's home/Documents/allowed and /tmp/allowed.
let globalAllowedDirectories: [FilePath] = [
    normalizePath(FilePath(getHomeDirectory().string + "/Documents/allowed")),
    FilePath("/tmp/allowed")
]

/**
 Resolves a symbolic link at the specified file path using the POSIX `readlink` call.
 
 - Parameter path: The `FilePath` to check for a symbolic link.
 - Returns: An optional `FilePath` representing the target of the symbolic link.
 - Throws: An error if the `readlink` system call fails (except when `errno` equals EINVAL,
 which indicates that the file is not a symbolic link).
 */
private func resolveSymlink(for path: FilePath) throws -> FilePath? {
    var buffer = [CChar](repeating: 0, count: 4096)
    let count = readlink(path.string, &buffer, buffer.count)
    if count < 0 {
        // If errno is EINVAL, the file is not a symbolic link.
        if errno == EINVAL { return nil }
        throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
    }
    buffer[count] = 0 // Append null termination
    let targetBytes = buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
    let target = String(decoding: targetBytes, as: UTF8.self)
    return FilePath(target)
}

/**
 Validates that the requested path is within one of the allowed directories. It also resolves
 any symbolic links found at the specified path.
 
 - Parameters:
 - requestedPath: A string containing the file path to validate.
 - allowed: An array of allowed `FilePath` instances.
 - Returns: A normalized and (if applicable) symlink-resolved `FilePath`.
 - Throws: An error if the path is not within an allowed directory or if the symlink target
 is not allowed.
 */
private func validatePath(_ requestedPath: String, allowed: [FilePath]) throws -> FilePath {
    let expanded = expandHome(requestedPath)
    let normalized = normalizePath(expanded)
    let isAllowed = allowed.contains { allowedDir in
        normalized.string.hasPrefix(allowedDir.string)
    }
    if !isAllowed {
        throw NSError(domain: "ValidatePath", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "Access denied – path not allowed: \(normalized.string)"])
    }
    if FileManager.default.fileExists(atPath: normalized.string) {
        if let symlinkTarget = try? resolveSymlink(for: normalized) {
            let resolved = normalizePath(symlinkTarget)
            let isResolvedAllowed = allowed.contains { allowedDir in
                resolved.string.hasPrefix(allowedDir.string)
            }
            if !isResolvedAllowed {
                throw NSError(domain: "ValidatePath", code: 2,
                              userInfo: [NSLocalizedDescriptionKey: "Access denied – symlink target not allowed: \(resolved.string)"])
            }
            return resolved
        }
    }
    return normalized
}

// MARK: - Diff Generation (Simplified)

/**
 Generates a unified diff (similar to the unified diff format) showing line-by-line changes
 between the original and modified text.
 
 - Parameters:
 - original: The original text.
 - modified: The modified text.
 - filePath: An optional file path string for header information (default is "file").
 - Returns: A string representing the diff between the original and modified text.
 */
private func createUnifiedDiff(original: String, modified: String, filePath: String = "file") -> String {
    let originalLines = original.components(separatedBy: "\n")
    let modifiedLines = modified.components(separatedBy: "\n")
    let diff = modifiedLines.difference(from: originalLines)
    
    var diffText = "Index: \(filePath)\n"
    diffText += "===================================================================\n"
    for change in diff {
        switch change {
        case let .remove(offset, element, _):
            diffText += "- \(offset): \(element)\n"
        case let .insert(offset, element, _):
            diffText += "+ \(offset): \(element)\n"
        }
    }
    return diffText
}

// MARK: - FileSystem Tools

// MARK: 1. Read File Tool

/**
 A structure representing the input arguments for the read_file tool.
 
 This includes the file path to be read.
 */
public struct ReadFileArgs: Codable, Sendable {
    public let path: String
    /// Public initializer.
    public init(path: String) {
        self.path = path
    }
}

/**
 The read_file tool reads the entire contents of a specified file as a UTF-8 string.
 
 The tool validates that the file is within allowed directories.
 */
public struct ReadFileTool: Tool {
    public var name: String = "read_file"
    public var description: String = "Reads the complete contents of a file."
    public var inputSchema: JSONSchema? = .object(
        properties: [
            "path": .string(description: "File path to read")
        ]
    )
    public var guide: String? = "Provide a valid file path (within allowed directories); the tool returns the file content as a UTF-8 string."
    
    /// Public initializer.
    public init() { }
    
    public func run(_ input: ReadFileArgs) async throws -> String {
        let validPath = try validatePath(input.path, allowed: globalAllowedDirectories)
        let fd = try FileDescriptor.open(validPath.string, .readOnly, options: [])
        defer { try? fd.close() }
        
        var buffer = [UInt8](repeating: 0, count: 4096)
        var fileData = Data()
        while true {
            let bytesRead = try buffer.withUnsafeMutableBytes { ptr in
                try fd.read(into: ptr)
            }
            if bytesRead == 0 { break }
            fileData.append(contentsOf: buffer[0..<bytesRead])
        }
        guard let content = String(data: fileData, encoding: .utf8) else {
            throw NSError(domain: "read_file", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "File content is not valid UTF-8"])
        }
        return content
    }
}

// MARK: 2. Read Multiple Files Tool

/**
 A structure representing the input arguments for the read_multiple_files tool.
 
 This includes an array of file paths to be read.
 */
public struct ReadMultipleFilesArgs: Codable, Sendable {
    public let paths: [String]
    /// Public initializer.
    public init(paths: [String]) {
        self.paths = paths
    }
}

/**
 The read_multiple_files tool reads the contents of multiple files and returns a mapping
 from the file path to its content.
 */
public struct ReadMultipleFilesTool: Tool {
    public var name: String = "read_multiple_files"
    public var description: String = "Reads the contents of multiple files."
    public var inputSchema: JSONSchema? = .object(
        properties: [
            "paths": .array(items: .string(description: "Each file path to read"))
        ]
    )
    public var guide: String? = "Provide an array of file paths (each within allowed directories); returns a mapping from path to file content."
    
    /// Public initializer.
    public init() { }
    
    public func run(_ input: ReadMultipleFilesArgs) async throws -> [String: String] {
        var results: [String: String] = [:]
        for path in input.paths {
            do {
                let validPath = try validatePath(path, allowed: globalAllowedDirectories)
                let fd = try FileDescriptor.open(validPath.string, .readOnly, options: [])
                defer { try? fd.close() }
                
                var buffer = [UInt8](repeating: 0, count: 4096)
                var fileData = Data()
                while true {
                    let bytesRead = try buffer.withUnsafeMutableBytes { ptr in
                        try fd.read(into: ptr)
                    }
                    if bytesRead == 0 { break }
                    fileData.append(contentsOf: buffer[0..<bytesRead])
                }
                guard let content = String(data: fileData, encoding: .utf8) else {
                    results[path] = "Error: Invalid UTF-8 content"
                    continue
                }
                results[path] = content
            } catch {
                results[path] = "Error: \(error)"
            }
        }
        return results
    }
}

// MARK: 3. Write File Tool

/**
 A structure representing the input arguments for the write_file tool.
 
 This includes the target file path and the content to write.
 */
public struct WriteFileArgs: Codable, Sendable {
    public let path: String
    public let content: String
    /// Public initializer.
    public init(path: String, content: String) {
        self.path = path
        self.content = content
    }
}

/**
 The write_file tool writes the provided content to the specified file, overwriting any
 existing file. The file path is validated to be within allowed directories.
 */
public struct WriteFileTool: Tool {
    public var name: String = "write_file"
    public var description: String = "Writes content to a file."
    public var inputSchema: JSONSchema? = .object(
        properties: [
            "path": .string(description: "Target file path"),
            "content": .string(description: "Content to write")
        ]
    )
    public var guide: String? = "Provide a file path (within allowed directories) and content; overwrites any existing file at that path."
    
    /// Public initializer.
    public init() { }
    
    public func run(_ input: WriteFileArgs) async throws -> String {
        let validPath = try validatePath(input.path, allowed: globalAllowedDirectories)
        let fd = try FileDescriptor.open(validPath.string, .writeOnly,
                                         options: [.create, .truncate],
                                         permissions: FilePermissions(rawValue: 0o644))
        defer { try? fd.close() }
        guard let data = input.content.data(using: .utf8) else {
            throw NSError(domain: "write_file", code: 4,
                          userInfo: [NSLocalizedDescriptionKey: "Content is not valid UTF-8"])
        }
        try data.withUnsafeBytes { ptr in
            _ = try fd.write(ptr)
        }
        return "Successfully wrote to \(input.path)"
    }
}

// MARK: 4. Edit File Tool

/**
 A structure representing an edit operation for the edit_file tool.
 
 - Parameters:
 - oldText: The text to search for in the file.
 - newText: The text to replace the old text with.
 */
public struct EditOperation: Codable, Sendable {
    public let oldText: String
    public let newText: String
    /// Public initializer.
    public init(oldText: String, newText: String) {
        self.oldText = oldText
        self.newText = newText
    }
}

/**
 A structure representing the input arguments for the edit_file tool.
 
 This includes the file path, a list of edit operations, and an optional flag for a dry-run.
 */
public struct EditFileArgs: Codable, Sendable {
    public let path: String
    public let edits: [EditOperation]
    public let dryRun: Bool?
    /// Public initializer.
    public init(path: String, edits: [EditOperation], dryRun: Bool? = nil) {
        self.path = path
        self.edits = edits
        self.dryRun = dryRun
    }
}

/**
 The edit_file tool applies a list of text edits to a file and generates a unified diff
 showing the changes. If `dryRun` is true, it returns the diff without modifying the file.
 */
public struct EditFileTool: Tool {
    public var name: String = "edit_file"
    public var description: String = "Edits text within a file and returns a unified diff of the changes."
    public var inputSchema: JSONSchema? = .object(
        properties: [
            "path": .string(description: "File path to edit"),
            "edits": .array(
                items: .object(properties: [
                    "oldText": .string(description: "Text to search for"),
                    "newText": .string(description: "Replacement text")
                ])
            ),
            "dryRun": .boolean(description: "Optional: true for a dry-run diff")
        ]
    )
    public var guide: String? = "Provide a file path and a list of edits; if dryRun is true, returns a unified diff preview; otherwise applies changes."
    
    /// Public initializer.
    public init() { }
    
    public func run(_ input: EditFileArgs) async throws -> String {
        let validPath = try validatePath(input.path, allowed: globalAllowedDirectories)
        let fd = try FileDescriptor.open(validPath.string, .readOnly, options: [])
        defer { try? fd.close() }
        
        var buffer = [UInt8](repeating: 0, count: 4096)
        var originalData = Data()
        while true {
            let bytesRead = try buffer.withUnsafeMutableBytes { ptr in
                try fd.read(into: ptr)
            }
            if bytesRead == 0 { break }
            originalData.append(contentsOf: buffer[0..<bytesRead])
        }
        guard let originalContent = String(data: originalData, encoding: .utf8) else {
            throw NSError(domain: "edit_file", code: 5,
                          userInfo: [NSLocalizedDescriptionKey: "File content is not valid UTF-8"])
        }
        var modifiedContent = originalContent
        for edit in input.edits {
            if modifiedContent.contains(edit.oldText) {
                modifiedContent = modifiedContent.replacingOccurrences(of: edit.oldText, with: edit.newText)
            } else {
                throw NSError(domain: "edit_file", code: 6,
                              userInfo: [NSLocalizedDescriptionKey: "Could not find text to replace: \(edit.oldText)"])
            }
        }
        let diff = createUnifiedDiff(original: originalContent, modified: modifiedContent, filePath: input.path)
        if input.dryRun == true {
            return diff
        } else {
            let fdw = try FileDescriptor.open(validPath.string, .writeOnly, options: [.truncate])
            defer { try? fdw.close() }
            guard let data = modifiedContent.data(using: .utf8) else {
                throw NSError(domain: "edit_file", code: 7,
                              userInfo: [NSLocalizedDescriptionKey: "Modified content is not valid UTF-8"])
            }
            try data.withUnsafeBytes { ptr in
                _ = try fdw.write(ptr)
            }
            return "Edits applied to \(input.path)\nDiff:\n\(diff)"
        }
    }
}

// MARK: 5. Create Directory Tool

/**
 A structure representing the input arguments for the create_directory tool.
 
 This includes the directory path to create.
 */
public struct CreateDirectoryArgs: Codable, Sendable {
    public let path: String
    /// Public initializer.
    public init(path: String) {
        self.path = path
    }
}

/**
 The create_directory tool creates a directory (and any necessary intermediate directories)
 at the specified path.
 */
public struct CreateDirectoryTool: Tool {
    public var name: String = "create_directory"
    public var description: String = "Creates a directory."
    public var inputSchema: JSONSchema? = .object(
        properties: [
            "path": .string(description: "Directory path to create")
        ]
    )
    public var guide: String? = "Provide a directory path (within allowed directories); creates the directory (including intermediate directories if needed)."
    
    /// Public initializer.
    public init() { }
    
    public func run(_ input: CreateDirectoryArgs) async throws -> String {
        let validPath = try validatePath(input.path, allowed: globalAllowedDirectories)
        do {
            try FileManager.default.createDirectory(atPath: validPath.string, withIntermediateDirectories: true)
        } catch {
            throw NSError(domain: "create_directory", code: 8,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create directory at \(input.path): \(error)"])
        }
        return "Directory created at \(input.path)"
    }
}

// MARK: 6. List Directory Tool

/**
 A structure representing the input arguments for the list_directory tool.
 
 This includes the directory path to list.
 */
public struct ListDirectoryArgs: Codable, Sendable {
    public let path: String
    /// Public initializer.
    public init(path: String) {
        self.path = path
    }
}

/**
 The list_directory tool returns an array of filenames and directory names found in the specified directory.
 */
public struct ListDirectoryTool: Tool {
    public var name: String = "list_directory"
    public var description: String = "Lists files and directories in the specified path."
    public var inputSchema: JSONSchema? = .object(
        properties: [
            "path": .string(description: "Directory path to list")
        ]
    )
    public var guide: String? = "Provide a directory path (within allowed directories); returns an array of file and directory names."
    
    /// Public initializer.
    public init() { }
    
    public func run(_ input: ListDirectoryArgs) async throws -> [String] {
        let validPath = try validatePath(input.path, allowed: globalAllowedDirectories)
        do {
            let entries = try FileManager.default.contentsOfDirectory(atPath: validPath.string)
            return entries
        } catch {
            throw NSError(domain: "list_directory", code: 9,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to list directory at \(input.path): \(error)"])
        }
    }
}

// MARK: 7. Move File Tool

/**
 A structure representing the input arguments for the move_file tool.
 
 This includes both the source and destination file paths.
 */
public struct MoveFileArgs: Codable, Sendable {
    public let source: String
    public let destination: String
    /// Public initializer.
    public init(source: String, destination: String) {
        self.source = source
        self.destination = destination
    }
}

/**
 The move_file tool moves or renames a file from the source path to the destination path.
 */
public struct MoveFileTool: Tool {
    public var name: String = "move_file"
    public var description: String = "Moves or renames a file."
    public var inputSchema: JSONSchema? = .object(
        properties: [
            "source": .string(description: "Source file path"),
            "destination": .string(description: "Destination file path")
        ]
    )
    public var guide: String? = "Provide source and destination paths (both within allowed directories); moves the file accordingly."
    
    /// Public initializer.
    public init() { }
    
    public func run(_ input: MoveFileArgs) async throws -> String {
        let validSource = try validatePath(input.source, allowed: globalAllowedDirectories)
        let validDest = try validatePath(input.destination, allowed: globalAllowedDirectories)
        do {
            try FileManager.default.moveItem(atPath: validSource.string, toPath: validDest.string)
        } catch {
            throw NSError(domain: "move_file", code: 10,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to move \(input.source) to \(input.destination): \(error)"])
        }
        return "Moved \(input.source) to \(input.destination)"
    }
}

// MARK: 8. Get File Info Tool

/**
 A structure representing the input arguments for the get_file_info tool.
 
 This includes the file path for which to retrieve metadata.
 */
public struct GetFileInfoArgs: Codable, Sendable {
    public let path: String
    /// Public initializer.
    public init(path: String) {
        self.path = path
    }
}

/**
 The get_file_info tool retrieves file metadata (such as size, creation date, etc.) and
 returns it as a formatted string.
 */
public struct GetFileInfoTool: Tool {
    public var name: String = "get_file_info"
    public var description: String = "Retrieves file metadata."
    public var inputSchema: JSONSchema? = .object(
        properties: [
            "path": .string(description: "File path")
        ]
    )
    public var guide: String? = "Provide a file path (within allowed directories); returns file attributes as a string."
    
    /// Public initializer.
    public init() { }
    
    public func run(_ input: GetFileInfoArgs) async throws -> String {
        let validPath = try validatePath(input.path, allowed: globalAllowedDirectories)
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: validPath.string)
            return attributes.map { "\($0.key): \($0.value)" }
                .joined(separator: "\n")
        } catch {
            throw NSError(domain: "get_file_info", code: 11,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to get file info for \(input.path): \(error)"])
        }
    }
}

// MARK: 9. List Allowed Directories Tool

/**
 The list_allowed_directories tool returns a newline-separated list of directories that are
 allowed for file system access.
 */
public struct ListAllowedDirectoriesTool: Tool {
    public var name: String = "list_allowed_directories"
    public var description: String = "Lists directories that are allowed for access."
    public var inputSchema: JSONSchema? = .object(properties: [:])
    public var guide: String? = "No input required; returns the list of allowed directories."
    
    /// Public initializer.
    public init() { }
    
    public func run(_ input: [String: String]) async throws -> String {
        return globalAllowedDirectories.map { $0.string }.joined(separator: "\n")
    }
}
