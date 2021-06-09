//
//  OMDbAPI.swift
//  MovieSearch
//
//  Created by Tanmay Bakshi on 2021-06-08.
//

import UIKit

class OMDbAPI {
    enum RequestError: Error {
        case invalidURL
        case invalidResponse
    }
    
    struct Movie: Codable, Equatable {
        enum PosterError: Error {
            case invalidImage
        }
        
        enum CodingKeys: String, CodingKey {
            case imdbID = "imdbID"
            case title = "Title"
            case year = "Year"
            case posterURL = "Poster"
        }
        
        let imdbID: String
        let title: String
        let year: String
        let posterURL: String
        
        func getPoster() async throws -> UIImage {
            guard let url = URL(string: posterURL) else { throw RequestError.invalidURL }
            let request = URLRequest(url: url)
            let (result, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw RequestError.invalidResponse }
            guard let image = UIImage(data: result) else { throw PosterError.invalidImage }
            return image
        }
    }
    
    struct SearchAPIResponse: Codable {
        let Search: [Movie]
    }
    
    struct IDAPIResponse: Codable {
        let Plot: String
    }
    
    private let apiKey: String
    private var lastSearch = ""
    private var lastPage = 0
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func search(query: String? = nil) async throws -> [Movie] {
        let url: URL
        if let query = query {
            lastPage = 1
            lastSearch = query
            
            if let queryUrl = URL(string: "https://www.omdbapi.com/?apikey=\(apiKey)&type=movie&s=\(query)") {
                url = queryUrl
            } else {
                throw RequestError.invalidURL
            }
        } else {
            lastPage += 1
            
            if let queryUrl = URL(string: "https://www.omdbapi.com/?apikey=\(apiKey)&type=movie&s=\(lastSearch)&page=\(lastPage)") {
                url = queryUrl
            } else {
                throw RequestError.invalidURL
            }
        }
        let urlRequest = URLRequest(url: url)
        let (result, response) = try await URLSession.shared.data(for: urlRequest)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw RequestError.invalidResponse }
        return try JSONDecoder().decode(SearchAPIResponse.self, from: result).Search
    }
    
    func plot(movie: Movie) async throws -> String {
        guard let url = URL(string: "https://www.omdbapi.com/?apikey=\(apiKey)&i=\(movie.imdbID)&plot=short") else { throw RequestError.invalidURL }
        let request = URLRequest(url: url)
        let (result, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw RequestError.invalidResponse }
        return try JSONDecoder().decode(IDAPIResponse.self, from: result).Plot
    }
}
