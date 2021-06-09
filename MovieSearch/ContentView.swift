//
//  ContentView.swift
//  MovieSearch
//
//  Created by Tanmay Bakshi on 2021-06-08.
//

import SwiftUI

struct MovieCellView: View {
    static let posterSize: (CGFloat, CGFloat) = (100, 148)
    
    let api: OMDbAPI
    let movie: OMDbAPI.Movie
    
    @Environment(\.colorScheme) var colorScheme
    @State var poster: UIImage?
    @State var posterBad = false
    @State var plot = ""
    
    var body: some View {
        HStack {
            if let poster = self.poster {
                Image(uiImage: poster)
                    .resizable()
                    .frame(width: MovieCellView.posterSize.0, height: MovieCellView.posterSize.1)
            } else if !posterBad {
                ProgressView()
                    .frame(width: MovieCellView.posterSize.0, height: MovieCellView.posterSize.1)
            } else {
                Rectangle()
                    .opacity(0)
                    .frame(width: MovieCellView.posterSize.0, height: MovieCellView.posterSize.1)
            }
            VStack(alignment: .leading) {
                Text(movie.title)
                    .fontWeight(.bold)
                Text(movie.year)
                    .foregroundColor(.gray)
                Text(plot)
            }
        }
        .onAppear {
            loadPoster()
            loadPlot()
        }
    }
    
    func loadPoster() {
        async {
            do {
                self.poster = try await movie.getPoster()
            } catch let error {
                posterBad = true
                print("Could not get movie poster! \(error)")
            }
        }
    }
    
    func loadPlot() {
        async {
            do {
                self.plot = try await api.plot(movie: movie)
            } catch let error {
                print("Could not get movie plot! \(error)")
            }
        }
    }
}

struct ContentView: View {
    let api = OMDbAPI(apiKey: "94fc179b")
    
    @State var searchQuery = ""
    @State var movies: [OMDbAPI.Movie] = []
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Movie search")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            Divider()
            
            TextField("Search", text: $searchQuery, onCommit: {
                searchMovies(query: searchQuery)
                UIApplication.shared.inputView?.endEditing(true)
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
            
            List {
                ForEach(movies, id: \.imdbID) { movie in
                    MovieCellView(api: api, movie: movie)
                        .onAppear {
                            if movie == movies.last {
                                searchMovies()
                            }
                        }
                }
            }
            
            Spacer()
        }
    }
    
    func searchMovies(query: String? = nil) {
        if query != nil {
            movies = []
        }
        async {
            do {
                self.movies += try await api.search(query: query)
            } catch {
                print("Could not load new movies! \(error)")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
