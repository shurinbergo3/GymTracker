//
//  GroqClient.swift
//  GymTracker
//
//  Talks to our Vercel proxy at `/api/ai-coach`, which sits in front of the
//  Groq Chat Completions API. We never ship the Groq key in the IPA — every
//  request is signed with a Firebase ID token and the proxy forwards to
//  Groq using a server-side secret.
//
//  Proxy source: ../../../../../groq-proxy/api/ai-coach.js
//  Deploy: `vercel deploy --prod` from that folder, then set
//          GROQ_API_KEY and FIREBASE_SERVICE_ACCOUNT in the Vercel dashboard.
//

import Foundation
import FirebaseAuth

// MARK: - Public types

struct GroqMessage: Codable, Hashable {
    enum Role: String, Codable {
        case system
        case user
        case assistant
    }
    let role: Role
    let content: String
}

enum GroqError: LocalizedError {
    case notSignedIn
    case invalidURL
    case http(status: Int, body: String)
    case decoding
    case empty
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .notSignedIn: return "Войдите в аккаунт, чтобы пользоваться AI-коучем."
        case .invalidURL: return "Неверный URL запроса."
        case .http(let s, let b):
            if s == 429 { return "Слишком много запросов. Попробуй чуть позже." }
            if s == 401 { return "Сессия истекла. Войди в аккаунт ещё раз." }
            return "Ошибка сети (\(s)). \(b)"
        case .decoding: return "Не удалось разобрать ответ модели."
        case .empty: return "Модель вернула пустой ответ."
        case .underlying(let e): return e.localizedDescription
        }
    }
}

// MARK: - Endpoint configuration

enum GroqProxyConfig {
    /// Production URL of the Vercel proxy. Project: `groq-proxy` under
    /// `shurinbergo3s-projects`. Uses Vercel's stable production alias so
    /// future deploys don't change this URL.
    static let endpoint = "https://groq-proxy-dun.vercel.app/api/ai-coach"
}

// MARK: - Client

actor GroqClient {

    static let shared = GroqClient()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 45
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    // MARK: - Wire types

    private struct Payload: Encodable {
        let messages: [GroqMessage]
        let temperature: Double
        let maxTokens: Int
    }

    private struct ProxyResponse: Decodable {
        let text: String
    }

    /// Sends a chat-completion request via the proxy and returns the model's reply.
    func complete(messages: [GroqMessage],
                  temperature: Double = 0.4,
                  maxTokens: Int = 700) async throws -> String {

        guard let url = URL(string: GroqProxyConfig.endpoint),
              url.scheme == "https" else {
            throw GroqError.invalidURL
        }

        // 1. Get a fresh Firebase ID token (auto-refreshes if expired). Done on
        // MainActor so we don't carry the non-Sendable `User` across actors.
        let idToken: String
        do {
            idToken = try await Self.fetchIDToken()
        } catch let e as GroqError {
            throw e
        } catch {
            throw GroqError.underlying(error)
        }

        // 2. Build request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

        let payload = Payload(messages: messages, temperature: temperature, maxTokens: maxTokens)
        request.httpBody = try JSONEncoder().encode(payload)

        // 3. Send
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw GroqError.underlying(error)
        }

        guard let http = response as? HTTPURLResponse else { throw GroqError.decoding }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw GroqError.http(status: http.statusCode, body: body)
        }

        // 4. Decode
        do {
            let decoded = try JSONDecoder().decode(ProxyResponse.self, from: data)
            let trimmed = decoded.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { throw GroqError.empty }
            return decoded.text
        } catch is DecodingError {
            throw GroqError.decoding
        } catch {
            throw error
        }
    }

    // MARK: - Helpers

    @MainActor
    private static func fetchIDToken() async throws -> String {
        guard let user = Auth.auth().currentUser else { throw GroqError.notSignedIn }
        return try await user.getIDToken()
    }
}
