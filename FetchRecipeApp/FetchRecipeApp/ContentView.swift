//
//  ContentView.swift
//  FetchRecipe
//
//  Created by Rohan Malige on 5/28/25.
//



import SwiftUI
import CryptoKit

private func makeHashedFilename(from urlString: String) -> String {
    // Turn the URL string into Data
    let data = Data(urlString.utf8)
    // Compute a SHA256 digest
    let shaDigest = SHA256.hash(data: data)
    // Convert digest bytes to hex string
    let hexString = shaDigest.compactMap { String(format: "%02x", $0) }.joined()
    return hexString
}

/// Loads/saves images to the Caches directory manually.
class ImageLoader: ObservableObject {
    @Published var image: UIImage? = nil
    private let urlString: String

    // Compute the caches‐folder URL once
    private static let cacheDir = FileManager.default
        .urls(for: .cachesDirectory, in: .userDomainMask)
        .first!

    init(urlString: String) {
        self.urlString = urlString
        loadImageIfNeeded()
    }

    private func loadImageIfNeeded() {
        // 1. Compute a unique filename for this URL
        let filename = makeHashedFilename(from: urlString)
        let fileURL = ImageLoader.cacheDir.appendingPathComponent(filename)

        // 2. Try to read from disk first:
        if let data = try? Data(contentsOf: fileURL),
           let uiImage = UIImage(data: data) {
            self.image = uiImage
            return
        }

        // 3. Otherwise, download it and write to disk
        guard let url = URL(string: urlString) else {
            return
        }
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let uiImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.image = uiImage
                    }
                    // Write to disk (ignore errors)
                    try? data.write(to: fileURL)
                }
            } catch {
                // We could set a placeholder or leave it nil
            }
        }
    }
}


/// A SwiftUI view that shows a ProgressView until the image loads.
/// This is how a new developer might wrap their custom ImageLoader.
struct AsyncImageView: View {
    @StateObject private var loader: ImageLoader

    init(urlString: String) {
        _loader = StateObject(wrappedValue: ImageLoader(urlString: urlString))
    }

    var body: some View {
        Group {
            if let ui = loader.image {
                Image(uiImage: ui)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ProgressView()
            }
        }
    }
}


/// Simple Recipe struct matching the API JSON keys.
struct Recipe: Identifiable, Decodable {
    let id: String
    let name: String
    let cuisine: String
    let photo_url_small: String?
    let photo_url_large: String?
    let source_url: String?
    let youtube_url: String?

    enum CodingKeys: String, CodingKey {
        case id = "uuid"
        case name, cuisine, photo_url_small, photo_url_large, source_url, youtube_url
    }
}

/// ObservableObject that fetches [`Recipe`]s from a given endpoint.
class RecipeFetcher: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var errorMessage: String? = nil

    /// Fetches and decodes recipes from a JSON API.
    /// Uses async/await under the hood.
    func fetchRecipes(from urlString: String) async {
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid URL"
                self.recipes = []
            }
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            // Decode into a dictionary keyed by "recipes"
            let decoded = try JSONDecoder().decode([String: [Recipe]].self, from: data)
            DispatchQueue.main.async {
                if let loaded = decoded["recipes"] {
                    self.recipes = loaded
                    self.errorMessage = nil
                } else {
                    self.recipes = []
                    self.errorMessage = "Malformed Data"
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.recipes = []
                self.errorMessage = "Failed to fetch recipes"
            }
        }
    }
}


/// A simple animated linear gradient that shifts over time.

struct AnimatedBackground: View {
    @State private var animate = false

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [.purple, .blue, .pink, .orange]),
            startPoint: animate ? .topLeading : .bottomTrailing,
            endPoint: animate ? .bottomTrailing : .topLeading
        )
        .animation(.linear(duration: 10).repeatForever(autoreverses: true), value: animate)
        .onAppear { animate.toggle() }
        .ignoresSafeArea()
    }
}


/// When a user taps a recipe, show this detail view with a larger image + links.
struct RecipeDetailView: View {
    let recipe: Recipe

    var body: some View {
        ZStack {
            AnimatedBackground()

            ScrollView {
                VStack(spacing: 16) {
                    // Large image
                    if let urlStr = recipe.photo_url_large {
                        AsyncImageView(urlString: urlStr)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(12)
                    }

                    // Title and cuisine
                    Text(recipe.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Text(recipe.cuisine)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Buttons for website + YouTube
                    HStack(spacing: 20) {
                        if let site = recipe.source_url,
                           let link = URL(string: site) {
                            Link(destination: link) {
                                Label("View Recipe", systemImage: "link")
                                    .padding()
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(8)
                            }
                        }

                        if let yt = recipe.youtube_url,
                           let link = URL(string: yt) {
                            Link(destination: link) {
                                Label("Watch Video", systemImage: "play.circle.fill")
                                    .padding()
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.bottom)
                }
                .padding()
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Main List View (with Loading State)

struct RecipeListView: View {
    @StateObject private var fetcher = RecipeFetcher()
    @State private var searchText: String = ""
    @State private var favorites: Set<String> = []
    @State private var isLoading: Bool = true

    @Environment(\.openURL) var openURL

    // The “All Recipes” endpoint
    private let urlString = "https://d3jbb8n5wk0qxi.cloudfront.net/recipes.json"

    /// Filters recipes when the user types into the search bar.
    var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return fetcher.recipes
        } else {
            return fetcher.recipes.filter { $0.cuisine.localizedCaseInsensitiveContains(searchText) }
        }
    }

    /// Auto-suggestions for cuisine names as the user types.
    var suggestions: [String] {
        let allCuisines = Set(fetcher.recipes.map { $0.cuisine })
        return allCuisines
            .sorted()
            .filter { $0.localizedCaseInsensitiveContains(searchText) && !searchText.isEmpty }
    }

    /// A quick list of only the favorited recipes.
    var favoriteRecipes: [Recipe] {
        fetcher.recipes.filter { favorites.contains($0.id) }
    }

    var body: some View {
        Group {
            if isLoading {
                // Show a full-screen loader over the gradient
                ZStack {
                    AnimatedBackground()
                    ProgressView {
                        Text("Loading Recipes…")
                            .accessibilityIdentifier("LoadingText")
                            .accessibilityLabel("Loading Recipes…")

                    }
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .foregroundColor(.white)
                    .font(.title2)
                    // Invisible Text used only for UI testing.
                    Text("LoadingRecipesHidden")
                        .accessibilityIdentifier("LoadingHidden")
                        .accessibilityLabel("Loading Recipes…")
                        .opacity(0) // makes it invisible to the user
                        .accessibilityHidden(false)  // keep it in the accessibility tree

                }
                .task {
                    await fetcher.fetchRecipes(from: urlString)
                    withAnimation {
                        isLoading = false
                    }
                }
            } else {
                // Main navigation + list
                NavigationView {
                    VStack(spacing: 0) {
                        // Top header (search bar on animated gradient)
                        ZStack {
                            AnimatedBackground()
                                .frame(height: 170)

                            VStack(alignment: .leading) {
                                TextField("Search cuisine", text: $searchText)
                                    .padding(10)
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(8)

                                if !suggestions.isEmpty {
                                    ForEach(suggestions, id: \.self) { suggestion in
                                        Text(suggestion)
                                            .padding(.horizontal)
                                            .padding(.vertical, 6)
                                            .background(Color.white.opacity(0.85))
                                            .cornerRadius(5)
                                            .onTapGesture {
                                                searchText = suggestion
                                            }
                                    }
                                } else if !searchText.isEmpty {
                                    Text("No cuisines found")
                                        .foregroundColor(.gray)
                                        .padding(.top, 5)
                                }
                            }
                            .padding()
                        }

                        // Main recipe list or error/empty states
                        if let error = fetcher.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                        } else if filteredRecipes.isEmpty {
                            Text("No recipes available.")
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            List(filteredRecipes) { recipe in
                                HStack {
                                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                        AsyncImageView(urlString: recipe.photo_url_small ?? "")
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .padding(.trailing, 8)

                                        VStack(alignment: .leading) {
                                            Text(recipe.name)
                                                .font(.headline)
                                            Text(recipe.cuisine)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Button(action: {
                                        if favorites.contains(recipe.id) {
                                            favorites.remove(recipe.id)
                                        } else {
                                            favorites.insert(recipe.id)
                                        }
                                    }) {
                                        Image(systemName: favorites.contains(recipe.id) ? "star.fill" : "star")
                                            .foregroundColor(.yellow)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .listStyle(PlainListStyle())
                        }

                        // Footer navigation to Favorites
                        HStack {
                            Spacer()
                            NavigationLink(destination: FavoritesView(recipes: favoriteRecipes)) {
                                Label("Favorites", systemImage: "star.fill")
                                    .padding()
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(8)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                    }
                    .navigationTitle("Recipes")
                    .navigationBarTitleDisplayMode(.inline)
                } // end NavigationView
            }
        }
    }
}

// MARK: - Favorites Screen

/// Shows a list of only the user’s favorited recipes. Tapping takes you to the same detail.
struct FavoritesView: View {
    let recipes: [Recipe]

    var body: some View {
        List(recipes) { recipe in
            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                HStack {
                    Text(recipe.name)
                    Spacer()
                    Text(recipe.cuisine)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("My Favorites")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

struct RecipeListView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeListView()
    }
}
