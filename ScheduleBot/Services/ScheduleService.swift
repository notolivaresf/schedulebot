//
//  ScheduleService.swift
//  ScheduleBot
//
//  Created by Fernando Olivares on 13/01/26.
//

import Foundation

final class ScheduleService {

    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL = URL(string: "http://localhost:3000")!, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func postSchedule(_ schedule: ShareableSchedule) async throws -> ScheduleResponse {
        let url = baseURL.appendingPathComponent("schedules")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ["schedule": schedule]
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ScheduleServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 201 else {
            throw ScheduleServiceError.serverError(statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(ScheduleResponse.self, from: data)
    }
}

enum ScheduleServiceError: Error, LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let statusCode):
            return "Server error: \(statusCode)"
        }
    }
}
