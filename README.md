# FetchRecipe App

### Summary
I built a simple SwiftUI recipe app that fetches a list of recipes from a JSON endpoint and displays them in a scrollable list. The home screen has an animated gradient background, a search bar for filtering by cuisine (with auto-suggestions), and a footer button to view favorites. Tapping a recipe cell navigates to a detail screen showing a larger image and links to the original recipe or its YouTube video. I’ve included a disk-backed image cache so images only download once, and a minimal loading spinner while data is fetching.

Below are a few quick screenshots to illustrate:

1. **Home Screen with Search Suggestions**  
   ![Search Suggestions](./Searchfeature.png)

2. **Recipe List**  
   ![Recipe List](./recipeView.png)

3. **Favourites Screen**  
   ![Loading Screen](./favourites.png)

4. **Detail Screen**  
   ![Detail Screen](./Detailedrecipe.png)

*(If you run the app locally, you’ll see smooth gradient animations and quick image loading after the first fetch.)*

---

### Focus Areas
- **Swift Concurrency & Networking**  
  I focused on using async/await for all network calls—fetching the recipe JSON and downloading images. The goal was to keep the UI responsive and ensure errors (invalid URL, malformed data, empty list) are handled gracefully.

- **Disk‐Backed Image Caching**  
  To avoid unnecessary bandwidth usage, I implemented a simple SHA256‐based filename hashing and wrote downloaded image data to the Caches directory. On subsequent launches or scrolls, the app loads images directly from disk if they exist.

- **SwiftUI‐First UI**  
  Since Fetch strongly prefers SwiftUI, I built everything with built‐in views—`ProgressView`, `List`, `NavigationView`, etc. The animated gradient background was added to demonstrate a lightweight but engaging modern SwiftUI effect.

- **Search Bar with Auto‐Suggestions**  
  I wanted to make searching by cuisine feel intuitive, so as the user types, the app filters out unique cuisine names to show relevant suggestions. If no suggestion matches, a “No cuisines found” note appears.

- **Favorites Management**  
  Users can tap a star icon in each cell to mark a recipe as a favorite. The footer button leads to a “My Favorites” screen, which reuses the same detail navigation—no persistent storage beyond the running session, but it works in memory during use.

- **UI Testing**  
  I added UI tests to verify core flows:  
  1. The loading indicator appears (via a hidden test‐only text).  
  2. At least one recipe shows up.  
  3. Tapping a cell navigates to the detail screen.  
  4. The favorites tab lists favorited recipes.  

---

### Time Spent
I spent about **6–7 hours** on this project total:
1. **Day 1 (3 hours)**  
   - Set up the base SwiftUI project, created `Recipe` and `RecipeFetcher` classes.  
   - Implemented the JSON fetch and basic list UI.  
   - Added image downloading functionality.

2. **Day 2 (2 hours)**  
   - Built the disk‐cache logic for images.  
   - Added the animated gradient background and refined the search bar with auto‐suggestions.  
   - Implemented the favorites feature (in‐memory using a `Set<UUID>`).

3. **Day 3 (1–2 hours)**  
   - Created the detail screen, linking to YouTube or the source site.  
   - Wrote UI tests.  
   - Polished error states (malformed/empty JSON).  
   - Wrote this README and cleaned up code comments.

---

### Trade-offs and Decisions
- **In‐Memory Favorites Only**  
  I did not persist favorites across app launches (e.g. via UserDefaults or a local database). That saved time, but favorites reset whenever the app restarts. For a production app, I’d add simple persistence.
- **No Third‐Party Pods**  
  To follow instructions, I avoided any external image‐caching libraries or networking frameworks. If I had more time, I might have built a more full‐featured cache (with expiration rules, memory cache, etc.).
- **Simplified JSON Decoding**  
  I assumed the top‐level JSON always has a `"recipes"` array. If that key is missing or the data is malformed, I clear the list and show an error. A more robust version might fallback to partial parsing or show which entries failed.
- **UI Polish vs. Speed**  
  I spent minimal time styling list rows and buttons (e.g. corners, padding). I could have spent much longer making the layout pixel‐perfect for all device sizes.

---

### Weakest Part of the Project
Probably the in‐memory favorites. It feels tacked on because it isn’t saved beyond the current session. If a user backgrounds the app or quits, all favorites disappear. In a real‐world scenario I’d use `UserDefaults` or a small local database to persist that state.

Another slightly weak point is the manual image cache. It works in most cases (writes to disk and reads back), but there’s no expiration or cleanup logic; over time it could fill up the user’s cache folder. A production version would need a more complete caching strategy.

---

### Additional Information
- **Error Handling**  
  - If the JSON URL is invalid or network fails, a red error message appears at the top of the list area.  
  - If the JSON exists but `"recipes"` is missing, I treat it as “Malformed Data” and clear out any old recipes.  
  - If `"recipes": []` (empty array), I show “No recipes available.” in gray text.

- **Testing Constraints**  
  - The UI tests rely on a hidden `Text("LoadingRecipesHidden")` with a unique accessibility identifier so that XCUITest can detect when the loading spinner is active.  
  - Because I did not embed a “pull‐to‐refresh” control, I left out tests around manual refresh. The “Refresh” button is in the toolbar, but I did not automate tapping it in tests.

- **Further Improvements**  
  1. **Persistent Favorites:** Store favorites in `UserDefaults` or a lightweight database so they survive app restarts.  
  2. **Memory Cache Layer:** In addition to disk caching, add an in‐memory `Dictionary<String, UIImage>` to avoid multiple disk reads during a short session.  
  3. **Pagination/Infinite Scroll:** If the list were very long, implement pagination or lazy loading.  
  4. **Localization:** Currently, all text is hardcoded in English. A next step would be to add localization support.

Thanks for reading—hope you enjoy poking around the code! If you have any questions or need clarification on any chunk of logic, let me know.
