import Foundation

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session

        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        decoder.dateDecodingStrategy = .iso8601

        encoder = JSONEncoder()
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let urlRequest = makeRequest(for: endpoint)
        return try await perform(urlRequest, responseType: T.self)
    }

    func request<T: Decodable, Body: Encodable>(_ endpoint: APIEndpoint, body: Body?) async throws -> T {
        var urlRequest = makeRequest(for: endpoint)

        if let body {
            urlRequest.httpBody = try encoder.encode(body)
        }

        return try await perform(urlRequest, responseType: T.self)
    }

    func register(_ request: RegisterRequest) async throws -> RegisterResponse {
        try await self.request(.register, body: request)
    }

    func uploadMultipart(endpoint: APIEndpoint, fields: [String: String], files: [MultipartFile]) async throws -> APIMessageResponse {
        let boundary = "Boundary-\(UUID().uuidString)"
        var urlRequest = makeRequest(for: endpoint)
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try MultipartBuilder.build(boundary: boundary, fields: fields, files: files)

        return try await perform(urlRequest, responseType: APIMessageResponse.self)
    }

    private func makeRequest(for endpoint: APIEndpoint) -> URLRequest {
        var urlRequest = URLRequest(url: endpoint.url)
        urlRequest.httpMethod = endpoint.method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = KeychainManager.shared.token, !token.isEmpty {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return urlRequest
    }

    private func perform<T: Decodable>(_ request: URLRequest, responseType: T.Type) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            debugPrintResponse(data: data, response: httpResponse, request: request)

            guard 200..<300 ~= httpResponse.statusCode else {
                let message = decodeErrorMessage(from: data, statusCode: httpResponse.statusCode)
                throw APIError.server(status: httpResponse.statusCode, message: message)
            }

            if responseType == EmptyResponse.self {
                guard let emptyResponse = EmptyResponse() as? T else {
                    throw APIError.invalidResponse
                }
                return emptyResponse
            }

            if data.isEmpty {
                throw APIError.invalidResponse
            }

            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data), errorResponse.success == false {
                throw APIError.server(status: httpResponse.statusCode, message: errorResponse.displayMessage)
            }

            do {
                return try decoder.decode(responseType, from: data)
            } catch {
                debugPrintDecodingError(error, responseType: responseType, data: data)
                throw APIError.decoding(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.transport(error)
        }
    }

    private func decodeErrorMessage(from data: Data, statusCode: Int) -> String {
        if let response = try? decoder.decode(ErrorResponse.self, from: data) {
            return response.displayMessage
        }

        if let response = try? decoder.decode(APIMessageResponse.self, from: data), let message = response.message, !message.isEmpty {
            return message
        }

        if let message = String(data: data, encoding: .utf8), !message.isEmpty {
            return message
        }

        return HTTPURLResponse.localizedString(forStatusCode: statusCode)
    }

    private func debugPrintResponse(data: Data, response: HTTPURLResponse, request: URLRequest) {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "<unknown url>"
        let body = String(data: data, encoding: .utf8) ?? "<non-utf8 response body>"

        print("API Response [\(response.statusCode)] \(method) \(url)")
        print(body.isEmpty ? "<empty response body>" : body)
    }

    private func debugPrintDecodingError<T>(_ error: Error, responseType: T.Type, data: Data) {
        let body = String(data: data, encoding: .utf8) ?? "<non-utf8 response body>"

        print("API Decoding Error for \(responseType): \(error)")
        print(body.isEmpty ? "<empty response body>" : body)
    }
}

struct MultipartFile {
    let fieldName: String
    let fileName: String
    let mimeType: String
    let url: URL
}

enum MultipartBuilder {
    static func build(boundary: String, fields: [String: String], files: [MultipartFile]) throws -> Data {
        var data = Data()

        for (name, value) in fields {
            data.appendString("--\(boundary)\r\n")
            data.appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            data.appendString("\(value)\r\n")
        }

        for file in files {
            data.appendString("--\(boundary)\r\n")
            data.appendString("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.fileName)\"\r\n")
            data.appendString("Content-Type: \(file.mimeType)\r\n\r\n")
            data.append(try Data(contentsOf: file.url))
            data.appendString("\r\n")
        }

        data.appendString("--\(boundary)--\r\n")
        return data
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        append(Data(string.utf8))
    }
}
