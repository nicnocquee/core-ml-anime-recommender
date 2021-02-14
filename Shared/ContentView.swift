//
//  ContentView.swift
//  Shared
//
//  Created by Nico Prananta on 11.02.21.
//

import SwiftUI
import SQift
import CoreML

struct Anime: Identifiable, Equatable {
    var id: Int
    var title: String
    var imageUrl: String
    var rating: String
    var score: Double
    var rank: Int
    var popularity: Int
}

extension Anime: ExpressibleByRow {
    init(row: Row) throws {
        guard
            let id: Int = row[0],
            let title: String = row[1],
            let imageUrl: String = row[2],
            let rating: String = row[3],
            let score: Double = row[4],
            let rank: Int = row[5],
            let popularity: Int = row[6]
        else {
            throw ExpressibleByRowError(type: Anime.self, row: row)
        }

        self.id = id
        self.title = title
        self.imageUrl = imageUrl
        self.rating = rating
        self.score = score
        self.rank = rank
        self.popularity = popularity
    }
}

let animeSamples = [
    Anime(id: 1535, title: "Death Note", imageUrl: "https://cdn.myanimelist.net/images/anime/9/9453.jpg", rating: "R - 17+ (violence & profanity)",score: 8.67,rank: 51, popularity: 1),
    Anime(id: 1536, title: "Death Note Something longer", imageUrl: "https://cdn.myanimelist.net/images/anime/9/9453.jpg", rating: "R - 17+ (violence & profanity)",score: 8.67,rank: 51, popularity: 1),
    Anime(id: 1537, title: "Death Note", imageUrl: "https://cdn.myanimelist.net/images/anime/9/9453.jpg", rating: "R - 17+ (violence & profanity)",score: 8.67,rank: 51, popularity: 1),
    Anime(id: 1538, title: "Death Note", imageUrl: "https://cdn.myanimelist.net/images/anime/9/9453.jpg", rating: "R - 17+ (violence & profanity)",score: 8.67,rank: 51, popularity: 1),
    Anime(id: 1539, title: "Death Note", imageUrl: "https://cdn.myanimelist.net/images/anime/9/9453.jpg", rating: "R - 17+ (violence & profanity)",score: 8.67,rank: 51, popularity: 1),
    Anime(id: 1540, title: "Death Note", imageUrl: "https://cdn.myanimelist.net/images/anime/9/9453.jpg", rating: "R - 17+ (violence & profanity)",score: 8.67,rank: 51, popularity: 1)
]

protocol AnimeListStore {
    var animes: [Anime] { get set }
}

class PopularAnime: ObservableObject, AnimeListStore {
    @Published var animes: [Anime] = []
    var appState: AppState?
    
    convenience init(popular: [Anime]) {
        self.init()
        self.animes = popular
    }
    
    func start() {
        if let db = appState?.db {
            do {
                self.animes = try db.query("SELECT * FROM animes WHERE popularity < 20 LIMIT 20")
            } catch {
                print(error)
            }
        }
    }
}

class RecommendationsStore: ObservableObject, AnimeListStore {
    @Published var animes: [Anime] = []
    
    var model: AnimeUserRating?
    var appState: AppState?
    
    convenience init(animes: [Anime]) {
        self.init()
        self.animes = animes
    }
    
    func recommend(animes: [Anime]) {
        if animes.count == 0 {
            self.animes = []
            return
        }
        if model == nil {
            do {
                model = try AnimeUserRating(configuration: MLModelConfiguration())
            } catch {
                print(error)
            }
        }
        if let model = self.model {
            var items: [Int64: Double] = [:]
            for anime in animes {
                items[Int64(anime.id)] = 10
            }
            let input = AnimeUserRatingInput(items: items, k: 20)
            guard let unwrappedResults = try? model.prediction(input: input) else {
                fatalError("Could not get results back!")
            }
            print(unwrappedResults.recommendations)
            
            if unwrappedResults.recommendations.count > 0 {
                if let db = appState?.db {
                    do {
                        let conditions = unwrappedResults.recommendations.map({ "anime_id = \($0)" }).joined(separator: " OR ")
                        self.animes = try db.query("SELECT * FROM animes WHERE \(conditions)")
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
}

class SearchStore: ObservableObject, AnimeListStore {
    @Published var animes: [Anime] = []
    
    var appState: AppState?
    
    convenience init(search: [Anime]) {
        self.init()
        self.animes = search
    }
    
    func search(keyword: String) {
        if keyword.count == 0 {
            self.animes = []
            return
        }
        if let db = appState?.db {
            do {
                self.animes = try db.query("SELECT * FROM animes WHERE title LIKE '%\(keyword)%' LIMIT 20")
            } catch {
                print(error)
            }
        }
    }
}

func animeCount(db: Connection?) throws -> Int {
    if let db = db {
        do {
            let count: Int? = try db.query("SELECT count(*) FROM animes")
            if let c = count {
                return c
            }
        } catch {
            print(error)
        }
    }
    return 0
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State var animesCount = 0
    @State var searchKey: String = ""
    @State var selectedAnimes: [Anime] = []
    @State var showSelections = false
    @State var searching = false
    @ObservedObject var popularStore = PopularAnime()
    @ObservedObject var recommendationStore = RecommendationsStore()
    @ObservedObject var searchStore = SearchStore()
    
    func addOrRemoveAnime(_ anime: Anime) {
        if self.selectedAnimes.contains(anime) {
            let index = self.selectedAnimes.firstIndex(of: anime)
            self.selectedAnimes.remove(at: index!)
        } else {
            self.selectedAnimes.append(anime)
        }
        self.recommendationStore.recommend(animes: self.selectedAnimes)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                
                if animesCount < 0 {
                    ProgressView("Loading ...")
                } else {
                    SearchBar(searchInput: $searchKey, searching: $searching)
                    Text("Number of anime: \(animesCount)")
                        .font(.caption)
                        .padding(.bottom, 30)
                    
                    Text(searchStore.animes.count > 0 ? "Search Result" : "Popular")
                        .font(.title)
                        .bold()
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(searchStore.animes.count > 0 ? searchStore.animes : popularStore.animes) { (anime) in
                                Button(action: {
                                    addOrRemoveAnime(anime)
                                }, label: {
                                    VStack {
                                        AsyncImage(url: URL(string: anime.imageUrl)!, placeholder: {
                                            if appState.useSample {
                                                Image("sample").resizable().aspectRatio(contentMode: .fill)
                                            } else {
                                                Text("Loading ...")
                                            }
                                            
                                        }) {
                                            Image(uiImage: $0)
                                                .resizable()
                                        }
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 100)
                                        .clipped()
                                        .border(Color.yellow, width: selectedAnimes.contains(anime) ? 8 : 0)
                                        .cornerRadius(8)
                                        
                                        
                                        Text(anime.title)
                                            .lineLimit(2)
                                            .font(.body)
                                    }
                                    .frame(width: 100)
                                })
                            }
                        }
                    }
                    .padding(.bottom, 30)
                    
                    if recommendationStore.animes.count > 0 {
                        Text("Recommendations")
                            .font(.title)
                            .bold()
                        HStack {
                            Text("Based on \(selectedAnimes.count) anime you like.")
                                .font(.body)
                            Button("See selections") {
                                showSelections.toggle()
                            }.sheet(isPresented: $showSelections, content: {
                                VStack {
                                    HStack {
                                        Text("Selected")
                                            .font(.title)
                                            .bold()
                                        Spacer()
                                        Button("Clear") {
                                            selectedAnimes = []
                                            recommendationStore.recommend(animes: selectedAnimes)
                                        }
                                    }
                                    List {
                                        ForEach(selectedAnimes) { (anime) in
                                            HStack {
                                                AsyncImage(url: URL(string: anime.imageUrl)!, placeholder: {
                                                    if appState.useSample {
                                                        Image("sample").resizable().aspectRatio(contentMode: .fill)
                                                    } else {
                                                        Text("Loading ...")
                                                    }
                                                }) {
                                                    Image(uiImage: $0)
                                                        .resizable()
                                                }
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 100, height: 100)
                                                .clipped()
                                                .cornerRadius(8)
                                                    
                                                Text(anime.title)
                                                    .font(.body)
                                                Spacer()
                                            }
                                            .padding(.bottom, 5)
                                            .listRowInsets(EdgeInsets())
                                        }
                                        .onDelete(perform: {
                                            selectedAnimes.remove(atOffsets: $0)
                                            recommendationStore.recommend(animes: selectedAnimes)
                                        })
                                    }
                                }
                                .padding()
                            })
                        }
                        Divider()
                            .padding(.vertical, 10)
                        ForEach(recommendationStore.animes) { (anime) in
                            HStack {
                                AsyncImage(url: URL(string: anime.imageUrl)!, placeholder: {
                                    if appState.useSample {
                                        Image("sample").resizable().aspectRatio(contentMode: .fill)
                                    } else {
                                        Text("Loading ...")
                                    }
                                    
                                }) {
                                    Image(uiImage: $0)
                                        .resizable()
                                }
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipped()
                                .cornerRadius(8)
                                    
                                Text(anime.title)
                                    .font(.body)
                                Spacer()
                            }
                            .onTapGesture {
                                addOrRemoveAnime(anime)
                            }
                            .padding(.bottom, 5)
                            .listRowInsets(EdgeInsets())
                        }
                    } else {
                        VStack(alignment: .center, spacing: 0) {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("Select an anime from the popular list or by searching to view your recommendation")
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
        .gesture(
           DragGesture().onChanged { value in
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
           }
        )
        .onAppear(perform: {
            recommendationStore.appState = appState
            popularStore.appState = appState
            popularStore.start()
            
            animesCount = (try? animeCount(db: appState.db)) ?? 0
            
            searchStore.appState = appState
        })
        .onChange(of: searchKey, perform: { value in
            searchStore.search(keyword: value)
        })
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView(popularStore: PopularAnime(popular: animeSamples), recommendationStore: RecommendationsStore())
                .environmentObject(AppState(useSample: true))
                .previewDisplayName("Initial")
            ContentView(popularStore: PopularAnime(popular: animeSamples), recommendationStore: RecommendationsStore(), searchStore: SearchStore(search: animeSamples))
                .environmentObject(AppState(useSample: true))
                .previewDisplayName("With Search Result")
            ContentView(popularStore: PopularAnime(popular: animeSamples), recommendationStore: RecommendationsStore(animes: animeSamples))
                .environmentObject(AppState(useSample: true))
                .previewDisplayName("With Recommendations")
        }
    }
}
