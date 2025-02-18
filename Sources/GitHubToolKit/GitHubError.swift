//
//  GitHubError.swift
//  servers
//
//  Created by Norikazu Muramoto on 2025/02/18
//

import Foundation

/// An enumeration representing GitHub API errors.
public enum GitHubError: Error, CustomStringConvertible, Sendable {
    /// Validation error (HTTP 422)
    case validation(message: String, status: Int)
    /// Resource not found (HTTP 404)
    case resourceNotFound(message: String, status: Int)
    /// Authentication failure (HTTP 401)
    case authentication(message: String, status: Int)
    /// Permission error (HTTP 403)
    case permission(message: String, status: Int)
    /// Rate limit exceeded (HTTP 429), with a reset date.
    case rateLimit(message: String, status: Int, resetAt: Date)
    /// Conflict error (HTTP 409)
    case conflict(message: String, status: Int)
    /// A generic error for all other HTTP statuses.
    case generic(message: String, status: Int)
    
    /// The error message.
    public var message: String {
        switch self {
        case .validation(let msg, _),
                .resourceNotFound(let msg, _),
                .authentication(let msg, _),
                .permission(let msg, _),
                .rateLimit(let msg, _, _),
                .conflict(let msg, _),
                .generic(let msg, _):
            return msg
        }
    }
    
    /// The HTTP status code.
    public var status: Int {
        switch self {
        case .validation(_, let status),
                .resourceNotFound(_, let status),
                .authentication(_, let status),
                .permission(_, let status),
                .rateLimit(_, let status, _),
                .conflict(_, let status),
                .generic(_, let status):
            return status
        }
    }
    
    /// A textual representation of the error.
    public var description: String {
        switch self {
        case .rateLimit(let msg, let status, let resetAt):
            let reset = ISO8601DateFormatter().string(from: resetAt)
            return "GitHubRateLimitError(status: \(status), message: \(msg), resetAt: \(reset))"
        default:
            return "GitHubError(status: \(status), message: \(message))"
        }
    }
}

/// Creates an appropriate `GitHubError` based on the HTTP status code and an optional message.
///
/// - Parameters:
///   - status: The HTTP status code.
///   - message: An optional error message. If not provided, a default message is used.
/// - Returns: A `GitHubError` corresponding to the status code.
public func createGitHubError(status: Int, message: String? = nil) -> GitHubError {
    switch status {
    case 401:
        return .authentication(message: message ?? "Authentication failed", status: status)
    case 403:
        return .permission(message: message ?? "Insufficient permissions", status: status)
    case 404:
        return .resourceNotFound(message: message ?? "Resource not found", status: status)
    case 409:
        return .conflict(message: message ?? "Conflict occurred", status: status)
    case 422:
        return .validation(message: message ?? "Validation failed", status: status)
    case 429:
        return .rateLimit(message: message ?? "Rate limit exceeded", status: status, resetAt: Date().addingTimeInterval(60))
    default:
        return .generic(message: message ?? "GitHub API error", status: status)
    }
}
