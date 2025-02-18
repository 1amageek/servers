//
//  GitHubUtils.swift
//  GitHubTools
//
//  Created by Norikazu Muramoto on 2025/02/18
//

import Foundation

/**
 Builds a URL string by appending query parameters to a base URL.
 
 - Parameters:
 - baseUrl: The base URL.
 - params: A dictionary of query parameters.
 - Returns: A complete URL string with query parameters.
 */
public func buildUrl(baseUrl: String, params: [String: String?]) -> String {
    guard var components = URLComponents(string: baseUrl) else { return baseUrl }
    var queryItems: [URLQueryItem] = []
    for (key, value) in params {
        if let value = value {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
    }
    components.queryItems = queryItems.isEmpty ? nil : queryItems
    return components.url?.absoluteString ?? baseUrl
}

/**
 Represents request options for a GitHub API request.
 */
public struct RequestOptions {
    public var method: String?
    public var body: Any?
    public var headers: [String: String]?
    
    public init(method: String? = nil, body: Any? = nil, headers: [String: String]? = nil) {
        self.method = method
        self.body = body
        self.headers = headers
    }
}

private let USER_AGENT: String = {
    // Compose a default user agent with our version and system info.
    let defaultUA = "context/servers/github/v\(VERSION) Swift"
    return defaultUA
}()

struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    public init<T: Encodable>(_ wrapped: T) {
        self._encode = wrapped.encode
    }
    public func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

/**
 Performs a GitHub API request.
 
 - Parameters:
 - url: The URL string.
 - options: RequestOptions including method, body, and headers.
 - Returns: A decoded JSON object or text.
 - Throws: An error if the request fails or the response status is not successful.
 */
public func githubRequest(url: String, options: RequestOptions = RequestOptions()) async throws -> Any {
    guard let requestUrl = URL(string: url) else {
        throw NSError(domain: "githubRequest", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
    }
    var request = URLRequest(url: requestUrl)
    request.httpMethod = options.method ?? "GET"
    request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue(USER_AGENT, forHTTPHeaderField: "User-Agent")
    if let token = ProcessInfo.processInfo.environment["GITHUB_PERSONAL_ACCESS_TOKEN"] {
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    if let headers = options.headers {
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
    }
    if let body = options.body {
        if let jsonObject = body as? [String: Any] {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
        } else if let jsonArray = body as? [Any] {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonArray, options: [])
        } else if let encodableBody = body as? Encodable {
            // Encodableな型の場合はAnyEncodableでラップしてエンコード
            request.httpBody = try JSONEncoder().encode(AnyEncodable(encodableBody))
        } else {
            throw NSError(domain: "githubRequest", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid body type for JSON serialization"])
        }
    }
    
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
        throw NSError(domain: "githubRequest", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
    }
    
    let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? ""
    let responseBody: Any
    if contentType.contains("application/json") {
        responseBody = try JSONSerialization.jsonObject(with: data, options: [])
    } else {
        responseBody = String(data: data, encoding: .utf8) ?? ""
    }
    
    if !(200...299).contains(httpResponse.statusCode) {
        throw createGitHubError(status: httpResponse.statusCode)
    }
    
    return responseBody
}
