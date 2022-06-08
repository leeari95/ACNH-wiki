//
//  APIRequest.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/17.
//

import Foundation
import Alamofire

protocol APIRequest: URLConvertible, URLRequestConvertible {
    associatedtype Response: APIResponse

    var method: HTTPMethod { get }
    var baseURL: URL? { get }
    var path: String { get }
    var parameters: [String: String] { get }
    var headers: [String: String]? { get }
}

extension APIRequest {
    func asURL() throws -> URL {
        guard let url = self.baseURL?.appendingPathComponent(self.path) else {
            throw APIError.invalidURL(self.baseURL?.absoluteString ?? "")
        }
        var urlComponents = URLComponents(string: url.absoluteString)
        let urlQuries = self.parameters.map { key, value -> URLQueryItem in
            let value = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            return URLQueryItem(name: key, value: value)
        }
        
        if urlQuries.isEmpty == false {
            urlComponents?.percentEncodedQueryItems = urlQuries
        }
        return url
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = try self.asURL()
        
        var request = URLRequest(url: url)
        request.httpMethod = self.method.rawValue

        if let headers = self.headers {
            headers.forEach { key, value in
                request.addValue(value, forHTTPHeaderField: key)
            }
        }

        return request
    }
}
