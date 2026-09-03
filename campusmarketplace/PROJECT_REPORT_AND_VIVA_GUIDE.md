# 🎓 Campus Marketplace — Complete Project Blueprint, Architecture & Defense Guide

---

## 👥 Master Team & Module Matrix

| Team Member | Role & Ownership | Primary Code Files Owned |
| :--- | :--- | :--- |
| **Shiva Dixit (Team Leader)** | **System Architecture, Responsive UI Engine & DevOps/Release** | `lib/main.dart`<br>`lib/core/theme/app_theme.dart`<br>`lib/core/constants/app_colors.dart`<br>`lib/features/listings/presentation/home_screen.dart`<br>`pubspec.yaml`, `AndroidManifest.xml` |
| **Sachin Kumar** | **Authentication Engine & User Profile Lifecycle** | `lib/features/auth/data/auth_repository.dart`<br>`lib/features/auth/presentation/auth_gate.dart`<br>`lib/features/auth/presentation/login_screen.dart`<br>`lib/features/auth/presentation/signup_screen.dart`<br>`lib/features/auth/providers/auth_provider.dart`<br>`lib/models/user_profile.dart` |
| **Sahil Srivastava** | **Listing Form, Media Processing & Cloud Storage Pipeline** | `lib/features/listings/presentation/create_edit_listing_screen.dart`<br>`lib/features/listings/data/storage_service.dart`<br>`lib/core/utils/image_compressor.dart`<br>`lib/models/listing_model.dart` |
| **Sarthak Tiwari** | **Discovery Engine: Real-Time Search, Filtering & Categories** | `lib/features/listings/providers/search_filter_provider.dart`<br>`lib/features/listings/presentation/widgets/search_bar_widget.dart`<br>`lib/features/listings/presentation/category_browse_screen.dart`<br>`lib/features/listings/presentation/widgets/category_chip_bar.dart`<br>`lib/features/listings/presentation/widgets/empty_state_view.dart` |
| **Satvik Agrawal** | **Item Details, Seller Relations & Peer-to-Peer Communication** | `lib/core/utils/contact_helper.dart`<br>`lib/features/listings/presentation/listing_detail_screen.dart`<br>`lib/features/profile/presentation/seller_profile_screen.dart`<br>`lib/features/listings/presentation/my_listings_screen.dart`<br>`lib/features/listings/presentation/widgets/image_carousel.dart` |

---

# 🛠️ Deep Dive: Tech Stack & Core Terminology Explained

### 1. **Flutter & Dart 3.x**
- **What it is**: Flutter is Google's open-source UI software development kit. Dart is the client-optimized, object-oriented programming language it runs on.
- **Why we chose it**: Flutter compiles directly to native ARM machine code using the **Impeller / Skia** rendering engine. It delivers consistent 60–120 FPS animations and eliminated the need to build separate codebases for Android and iOS.
- **Key Concepts**:
  - `StatelessWidget`: A widget that never changes its internal state once built (e.g. `ConditionBadge`).
  - `StatefulWidget` / `ConsumerWidget`: Widgets that dynamically react and rebuild when underlying state or user inputs change.
  - `BuildContext`: The handle to the location of a widget in the widget tree.

---

### 2. **Flutter Riverpod 2.x (State Management & Dependency Injection)**
- **What it is**: A reactive, compile-safe state management framework designed as a complete rewrite of the traditional Provider package.
- **Why we chose it**:
  - **No `BuildContext` dependency**: Providers are declared globally as immutable singletons and can be read or listened to from anywhere in the codebase without `ProviderNotFoundException`.
  - **Compile-Time Safety**: Type errors in state transitions are caught during compilation rather than crashing at runtime.
  - **Auto-Disposal & Caching**: Efficiently cleans up memory when screens are popped off the navigation stack.
- **Core Riverpod Terms in Our App**:
  - `ProviderScope`: The root widget wrapped around `runApp()` that holds the internal state container of all providers.
  - `StateProvider<T>`: A lightweight provider used for storing and mutating simple values (e.g., `searchQueryProvider` storing `String`, `selectedCategoryProvider` storing `String`).
  - `StreamProvider<T>`: Listens to continuous asynchronous streams (e.g., `activeListingsStreamProvider` listening to live Firestore changes and `authStateProvider` listening to Firebase login events).
  - `Provider<T>`: Used for synchronous derived computation (e.g., `filteredListingsProvider` which combines search text + category selection + raw listings in real-time).
  - `ref.watch()`: Listens to a provider inside `build()` and causes the widget to rebuild only when the state changes.
  - `ref.read()`: Reads a provider once without listening (ideal inside `onPressed` callbacks).

---

### 3. **Firebase Cloud Firestore (Real-Time NoSQL Database)**
- **What it is**: A cloud-hosted, flexible NoSQL document database from Google Cloud.
- **Why we chose it**:
  - **Real-Time Synchronization**: Uses long-lived WebSocket connections to push instant database updates to all connected phones without manual HTTP polling.
  - **Document & Collection Model**: Data is stored as JSON-like documents grouped into collections (`users` and `listings`).
  - **Offline Persistence**: Automatically caches recent documents locally, allowing the app to open instantly even with spotty campus Wi-Fi.

---

### 4. **Firebase Authentication**
- **What it is**: A complete, managed user identity service supporting Email/Password and Google OAuth 2.0.
- **Why we chose it**: Handles token signing, session lifecycle, token refresh in the background, and secure password hashing (`scrypt`).

---

### 5. **Cloudinary CDN & Media Pipeline**
- **What it is**: Cloud-based media management platform.
- **Why we chose it**: Offers high-speed image delivery through global edge servers, automatic HTTPS URL generation, and fast multi-part HTTP upload endpoints.

---

### 6. **Helper Libraries**
- `flutter_image_compress`: Executes native C++ image downscaling and JPEG quantization directly on the device before upload.
- `url_launcher`: Dispatches native OS Intent URLs (`https://wa.me/`, `tel:`, `sms:`) to launch WhatsApp and phone dialers.
- `cached_network_image`: Automatically downloads, caches on disk, and renders network images with custom shimmer placeholders.

---

# 🗺️ Navigation Architecture & Screen Connectivity Map

### 📱 Visual Navigation Flowchart

```
                          ┌────────────────────────┐
                          │       main.dart        │
                          │ (ProviderScope + App)  │
                          └───────────┬────────────┘
                                      │
                                      ▼
                          ┌────────────────────────┐
                          │        AuthGate        │
                          │ (Listens to AuthState) │
                          └─────┬────────────┬─────┘
                                │            │
               [If Not Logged In]            [If Logged In]
                                │            │
                                ▼            ▼
  ┌───────────────────────────────┐        ┌────────────────────────────────────────────────────────┐
  │         LoginScreen           │        │                       HomeScreen                       │
  │  (Email/Pass + Google Signin) │        │ (Search Bar, Category Chips Bar, Active Listings Grid) │
  └───────────────┬───────────────┘        └───────┬──────────────┬──────────────┬──────────┬───────┘
                  │                                │              │              │          │
           [Tap Register]                          │              │              │          │
                  ▼                                │              │              │          │
  ┌───────────────────────────────┐                │              │              │          │
  │         SignupScreen          │                │              │              │          │
  │ (Name, Email, Password, Phone)│                │              │              │          │
  └───────────────────────────────┘                │              │              │          │
                                                   │              │              │          │
            ┌──────────────────────────────────────┘              │              │          └──────────────────────────┐
            │                                                     │              │                                     │
            ▼                                                     ▼              ▼                                     ▼
┌─────────────────────────┐                           ┌─────────────────────────┐┌─────────────────────────┐┌─────────────────────────┐
│   ListingDetailScreen   │                           │  CategoryBrowseScreen   ││    MyListingsScreen     ││    MyProfileScreen      │
│(Photos, Price, WhatsApp,│                           │ (Full Category Grid +   ││ (Active Listings Tab &  ││(User Info, Edit Profile,│
│ Call, Seller Profile)   │                           │  Quick Home Navigation) ││  Sold History Tab)      ││   My Listings, Logout)  │
└───────────┬─────────────┘                           └─────────────────────────┘└───────────┬─────────────┘└───────────┬─────────────┘
            │                                                                                │                           │
     [Tap Seller Info]                                                          [Tap Edit] / [Tap New]             [Tap Edit Profile]
            │                                                                                │                           │
            ▼                                                                                ▼                           ▼
┌─────────────────────────┐                                                     ┌─────────────────────────┐┌─────────────────────────┐
│   SellerProfileScreen   │                                                     │CreateEditListingScreen  ││   EditProfileDialog     │
│(Seller Card + All Other │                                                     │ (Photos, Title, Price,  ││ (Name, Phone Number,   │
│ Active Items by Seller) │                                                     │  Condition, Category)   ││  Campus Block / Hostel)│
└─────────────────────────┘                                                     └─────────────────────────┘└─────────────────────────┘
```

---

### 🔍 Screen-by-Screen Relationship & Logic Rationale

1. **`AuthGate` $\rightarrow$ `LoginScreen` or `HomeScreen`**:
   - *Why*: Acts as a security firewall. Users cannot access marketplace listings or post items without an authenticated Firebase session.
2. **`HomeScreen` $\rightarrow$ `ListingDetailScreen`**:
   - *Why*: Tapping any product card opens its full view with all photos, description, seller info, and contact buttons.
3. **`HomeScreen` $\rightarrow$ `CategoryBrowseScreen`**:
   - *Why*: Allows users to explore all campus categories with dedicated icons. Selecting a category updates `selectedCategoryProvider` and pops back to the home feed filtered to that category.
4. **`HomeScreen` $\rightarrow$ `CreateEditListingScreen`**:
   - *Why*: Triggered by the Floating Action Button (`+ Sell Item`) for quick item listing.
5. **`HomeScreen` $\rightarrow$ `MyProfileScreen`**:
   - *Why*: Triggered by tapping the top-right user avatar.
6. **`ListingDetailScreen` $\rightarrow$ `SellerProfileScreen`**:
   - *Why*: Buyers can tap on the seller's card to view their profile, verify their campus credentials, and inspect all other items currently listed by the same student.
7. **`ListingDetailScreen` $\rightarrow$ External WhatsApp / Phone App**:
   - *Why*: Deep links directly into the student's WhatsApp or phone dialer for peer-to-peer negotiation.
8. **`MyListingsScreen` $\rightarrow$ `CreateEditListingScreen`**:
   - *Why*: Allows sellers to edit existing listings or tap "Mark as Sold" to move items into their sold history.
9. **`MyProfileScreen` $\rightarrow$ `EditProfileDialog` & Logout**:
   - *Why*: Users can update their phone number and campus hostel/block, or log out (which notifies `AuthGate` to transition back to `LoginScreen`).

---

# 🛡️ Application Security Architecture

Campus Marketplace implements defense-in-depth across multiple layers:

### 1. **Cryptographic Authentication & Password Storage**
- Passwords are **never stored in plaintext** and never pass through our Firestore database.
- Firebase Auth hashes passwords using Google’s server-side **scrypt algorithm** with dynamic cryptographic salts, preventing rainbow table attacks.

### 2. **Database Access Control & Data Ownership Rules**
- Security rules verify user identity on every database interaction:
  - **Read**: Any authenticated student can read active listings.
  - **Create**: Only authenticated students can create listings, and the `sellerId` field must match their authenticated `request.auth.uid`.
  - **Update / Delete**: A user can **only** edit, mark as sold, or delete a listing if `request.auth.uid == resource.data.sellerId`. No student can modify another student’s listing.

### 3. **Brute-Force & DDoS Mitigation**
- Firebase Auth tracks consecutive failed login attempts by IP and email.
- Exceeding the attempt threshold automatically triggers the `auth/too-many-requests` rate-limiting lockout for several minutes.

### 4. **Client-Side Input Sanitization**
- All phone numbers are strictly sanitized through regular expressions (`phone.replaceAll(RegExp(r'[^\d+]'), '')`) to eliminate malicious injection payloads before dispatching to system intents.
- Prices are validated as positive decimal numbers (`price > 0 && price <= 1000000`) to prevent negative or arithmetic overflow inputs.

### 5. **Android 11+ Package Visibility & Intent Isolation**
- `<queries>` declarations in `AndroidManifest.xml` restrict the application to only inspect explicit intent schemes (`https`, `tel`, `sms`), adhering to Android's principle of least privilege.

---

# 🧑‍💻 Individual Module Breakdown, Code & Defense

---

# 1. 🏛️ Shiva Dixit (Team Leader & System Architect)

### 📌 Role & Responsibilities
- Architected the foundational Flutter project structure, Riverpod dependency injection root (`ProviderScope`), and centralized Material 3 design system (`AppTheme`, `AppColors`).
- Designed the adaptive screen-size engine to ensure pixel-perfect rendering across small smartphones (360dp), large devices (420dp), and tablets (600dp+).
- Managed release engineering, app launcher icon asset pipelines, and automated GitHub Releases distribution.

### 💻 Key Code Implementation

#### Responsive Grid Layout Delegate (`home_screen.dart`)
```dart
// Dynamically compute columns and aspect ratios based on physical screen width
final screenWidth = MediaQuery.sizeOf(context).width;
final crossAxisCount = screenWidth >= 900 ? 4 : (screenWidth >= 600 ? 3 : 2);
final childAspectRatio = screenWidth >= 600 ? 0.75 : 0.69;

return GridView.builder(
  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount,
    childAspectRatio: childAspectRatio,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
  ),
  itemCount: listings.length,
  itemBuilder: (context, index) => ListingCard(listing: listings[index], onTap: () => ...),
);
```

### ⚠️ Problems Faced & Technical Solutions
1. **Problem: "BOTTOM OVERFLOWED BY 32 PIXELS" on Mobile Phones**
   - *Cause*: A hardcoded `childAspectRatio: 0.78` allocated only ~70px for card details beneath the 1.15 aspect ratio photo on mobile phones, while the price, title, 2 lines of description, and footer required ~105px.
   - *Fix*: Decreased mobile aspect ratio to `0.69`, reduced `ListingCard` padding to `EdgeInsets.fromLTRB(10, 8, 10, 8)`, restricted description snippet to `maxLines: 1`, and made grid columns responsive.
2. **Problem: Launcher Icon Generation Failure (`PathNotFoundException` in iOS folder)**
   - *Cause*: `flutter_launcher_icons` with `ios: true` failed because iOS Xcode project directories were not generated in this Android-first Windows environment.
   - *Fix*: Set `ios: false` and `android: "launcher_icon"` in `pubspec.yaml`, generating all Android mipmap densities (`mipmap-mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`) cleanly.
3. **Problem: In-Place Upgrade Failures on Mobile Devices**
   - *Cause*: Android requires a monotonically increasing integer `versionCode` to permit updating an existing APK without uninstalling.
   - *Fix*: Configured semantic versioning (`version: 1.0.1+2`), allowing users to update their installed app seamlessly directly from GitHub Releases.

### 🎯 Shiva Dixit's Specific Viva Questions & Answers
- **Q1: Why is Riverpod's `ProviderScope` wrapped around the root `runApp(ProviderScope(child: CampusMarketplaceApp()))`?**
  - *Answer*: `ProviderScope` stores the runtime state container of all Riverpod providers. In Riverpod, providers are global top-level variables, but their internal state lives inside the `ProviderScope`.
- **Q2: What is the difference between `MediaQuery.of(context).size` and `MediaQuery.sizeOf(context)` in modern Flutter?**
  - *Answer*: `MediaQuery.sizeOf(context)` (introduced in Flutter 3.10) only establishes an inherited model dependency on the **size** property. If keyboard insets or padding change, widgets listening to `sizeOf` do not needlessly rebuild.
- **Q3: How did you configure Android Adaptive Icons for modern Android versions (API 26+)?**
  - *Answer*: We set `min_sdk_android: 21` in `flutter_launcher_icons`. The tool generated legacy square/round PNGs as well as modern adaptive foreground drawables and background colors.
- **Q4: Why choose a 2-column grid for mobile and 3/4-column for tablet?**
  - *Answer*: It maximizes visual browsing density on mobile while keeping photos clear enough to inspect product quality, and automatically spreads out on larger tablet screens without card stretching.
- **Q5: How do you structure build variants between debug and release builds in Flutter?**
  - *Answer*: In debug mode, Flutter runs in JIT mode for hot reload. For release mode (`flutter build apk --release`), Flutter uses AOT compilation, treeshakes unused icon fonts, and produces an optimized ARM64 native binary.

---

# 2. 🔐 Sachin Kumar (Authentication & User Profiles)

### 📌 Role & Responsibilities
- Architected the Firebase Authentication layer supporting both Email/Password credentials and Google OAuth.
- Built the reactive `AuthGate` router that intercepts application startup and routes users according to live auth sessions.
- Designed the Firestore `UserProfile` document schema and managed user profile state streams.

### 💻 Key Code Implementation

#### Email Registration & Auto-Provisioning (`auth_repository.dart`)
```dart
Future<UserProfile> signUp({
  required String email,
  required String password,
  required String name,
  String phone = '',
}) async {
  final userCredential = await _auth.createUserWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );
  final user = userCredential.user;
  if (user == null) throw Exception('User registration failed');

  await user.updateDisplayName(name.trim());

  final profile = UserProfile(
    id: user.uid,
    name: name.trim(),
    email: email.trim(),
    phone: phone.trim(),
    createdAt: DateTime.now(),
  );

  await _firestore.collection('users').doc(user.uid).set(profile.toFirestore());
  return profile;
}
```

### ⚠️ Problems Faced & Technical Solutions
1. **Problem: First-Time Google Sign-In Missing Firestore Profile**
   - *Cause*: When users signed in via Google OAuth, Firebase Auth created the user, but no document existed in Firestore `users/{uid}`, causing null errors on the profile page.
   - *Fix*: In `signInWithGoogle()`, added a document existence check: `final doc = await _firestore.collection('users').doc(user.uid).get();`. If `!doc.exists`, it automatically extracts `user.displayName`, `user.email`, and `user.photoURL` and writes a new profile document.
2. **Problem: UI Stutter & Multiple Rebuilds on Auth State Changes**
   - *Cause*: Calling `setState()` during active async auth operations caused widget build race conditions.
   - *Fix*: Migrated auth listening to Riverpod `StreamProvider` where state transitions are handled declaratively via `.when()`.
3. **Problem: Brute-Force Password Guessing & Error Handling**
   - *Cause*: Repeated login attempts could leave the account vulnerable.
   - *Fix*: Captured Firebase Auth exceptions: `auth/too-many-requests`, `auth/wrong-password`, `auth/user-not-found`, and mapped them to clear user-friendly notifications.

### 🎯 Sachin Kumar's Specific Viva Questions & Answers
- **Q1: What is the difference between `FirebaseAuth.instance.currentUser` and `authStateChanges()`?**
  - *Answer*: `currentUser` is a synchronous single-moment snapshot cached in memory. `authStateChanges()` returns a continuous `Stream<User?>` that notifies the app in real-time whenever a user logs in, logs out, or the token refreshes.
- **Q2: How is password security managed in Firebase Auth?**
  - *Answer*: Passwords are never saved in Firestore or on device. Firebase hashes passwords using the **scrypt** key derivation function on Google servers.
- **Q3: What is the role of `user.uid` in database security?**
  - *Answer*: The `uid` is a unique 28-character identifier. In Firestore security rules, we enforce `request.auth.uid == resource.data.sellerId`, ensuring students can only edit or delete their own listings.
- **Q4: How does Google OAuth authentication work under the hood in Flutter?**
  - *Answer*: `GoogleSignIn` retrieves an `idToken` and `accessToken` via Android Account Manager. These are exchanged with Firebase Auth via `GoogleAuthProvider.credential()` to create the user session.
- **Q5: How do you handle email format and password strength validation in Flutter?**
  - *Answer*: We built centralized validation functions in `validators.dart` using regular expressions (`RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')`) and enforced a minimum 6-character length before sending network requests.

---

# 3. 📦 Sahil Srivastava (Listings, Media Processing & Storage)

### 📌 Role & Responsibilities
- Engineered the complete listing creation and modification interface (`create_edit_listing_screen.dart`).
- Built the client-side image compression engine (`image_compressor.dart`) to optimize device camera photos before transmission.
- Designed the Cloud Storage upload pipeline (`storage_service.dart`) utilizing Cloudinary CDN and multi-part upload workers.

### 💻 Key Code Implementation

#### Client-Side Image Compression Algorithm (`image_compressor.dart`)
```dart
class ImageCompressor {
  static Future<XFile> compressImage(XFile file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = p.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        minWidth: 1024,
        minHeight: 1024,
        quality: 80,
        format: CompressFormat.jpeg,
      );

      return result != null ? XFile(result.path) : file;
    } catch (e) {
      debugPrint('Compression notice: $e');
      return file;
    }
  }
}
```

### ⚠️ Problems Faced & Technical Solutions
1. **Problem: App Out-Of-Memory (OOM) Crashes on Multi-Image Selection**
   - *Cause*: Selecting 4 full-resolution uncompressed 4K images from the phone gallery consumed over 120MB of RAM during simultaneous raw byte decoding.
   - *Fix*: Handled compression via native Android C++ image pipelines (`flutter_image_compress`) using file paths rather than loading raw byte arrays into the Dart heap.
2. **Problem: Form State Duplication Between "Create Listing" and "Edit Listing"**
   - *Cause*: Creating separate screens for creating vs editing would result in duplicate code.
   - *Fix*: Created a unified `CreateEditListingScreen({this.listingToEdit})`. If `listingToEdit` is supplied, form controllers pre-populate, existing image URLs are preserved in a preview list, and the submit button triggers an `updateListing()` instead of `createListing()`.
3. **Problem: Network Dropouts During Photo Uploads**
   - *Cause*: Large uploads over unstable campus Wi-Fi failed without visual feedback.
   - *Fix*: Added a step-by-step progress dialog showing current status: *"Compressing images..." -> "Uploading photo 1 of 3..." -> "Saving listing details..."*.

### 🎯 Sahil Srivastava's Specific Viva Questions & Answers
- **Q1: Why is client-side image compression preferred over server-side compression for mobile apps?**
  - *Answer*: Server-side compression still requires uploading large 10MB raw files over mobile data. Compressing on-device before transmission reduces upload time from ~15s to <1s and prevents upload timeouts on poor networks.
- **Q2: How does `image_picker` interact with native Android permissions?**
  - *Answer*: On Android 13+ (API 33+), `image_picker` uses the modern Android Photo Picker which does not require declaring dangerous `READ_EXTERNAL_STORAGE` permissions in `AndroidManifest.xml`.
- **Q3: What data types are used to store listing information in Firestore?**
  - *Answer*: We use `String` for title, description, category, condition, sellerId; `double` for price; `List<String>` for imageUrls; `bool` for isActive and isSold; and Firestore `Timestamp` for createdAt.
- **Q4: How do you validate that price input contains valid numeric values?**
  - *Answer*: In `validators.dart`, we parse the string using `double.tryParse(value)` and enforce `price > 0 && price <= 1000000` to prevent negative or absurd values.
- **Q5: What happens to old images when a user replaces a photo during listing edit?**
  - *Answer*: The new photo is compressed and uploaded to Cloud Storage, the URL array in Firestore is updated, and any old image references can be cleaned up via storage delete calls.

---

# 4. 🔍 Sarthak Tiwari (Search, Filtering & Categorization)

### 📌 Role & Responsibilities
- Architected the real-time marketplace discovery feed, search bar, and category browsing engine.
- Built the reactive Riverpod filtering pipeline (`search_filter_provider.dart`) combining full-text multi-field search with category selection.
- Designed dynamic empty states (`empty_state_view.dart`) to guide users when no listings match their query.

### 💻 Key Code Implementation

#### In-Memory Reactive Multi-Criteria Filter Engine (`search_filter_provider.dart`)
```dart
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedConditionProvider = StateProvider<String?>((ref) => null);

final filteredListingsProvider = Provider<AsyncValue<List<Listing>>>((ref) {
  final listingsAsync = ref.watch(activeListingsStreamProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final selectedCondition = ref.watch(selectedConditionProvider);

  return listingsAsync.whenData((listings) {
    return listings.where((listing) {
      if (selectedCategory != 'All' && listing.category != selectedCategory) return false;
      if (selectedCondition != null && listing.condition != selectedCondition) return false;
      if (query.isNotEmpty) {
        final bool titleMatch = listing.title.toLowerCase().contains(query);
        final bool descMatch = listing.description.toLowerCase().contains(query);
        final bool locMatch = listing.location.toLowerCase().contains(query);
        final bool catMatch = listing.category.toLowerCase().contains(query);
        return titleMatch || descMatch || locMatch || catMatch;
      }
      return true;
    }).toList();
  });
});
```

### ⚠️ Problems Faced & Technical Solutions
1. **Problem: Firestore NoSQL Query Limitations on Partial String Matching**
   - *Cause*: Cloud Firestore does not support native substring search (e.g. searching "chem" to find "Chemistry Book"). Firestore queries only match exact prefixes (`>= 'chem'` and `< 'chem\uf8ff'`).
   - *Fix*: Designed a client-side reactive pipeline in Riverpod: Firestore streams the active listings in real time, and Dart's optimized `.contains()` processes multi-keyword search across Title, Description, Location, and Category instantly.
2. **Problem: Blank Screen on Empty Search Results**
   - *Cause*: When no listings matched a search, the UI displayed a blank area, confusing users.
   - *Fix*: Built `EmptyStateView` with contextual messaging: if `isSearching == true`, it shows a "No matching items found" banner with a "Reset Filters" button that clears search and resets category to 'All'.
3. **Problem: Category Chip Scrolling Jank**
   - *Cause*: Re-rendering the entire top category bar whenever the product list scrolled caused dropped frames.
   - *Fix*: Placed the category chips inside `NestedScrollView`'s `headerSliverBuilder` inside a `SliverToBoxAdapter`, isolating chip bar rebuilds from grid scroll physics.

### 🎯 Sarthak Tiwari's Specific Viva Questions & Answers
- **Q1: Why did you combine category filtering and keyword search in a single Riverpod provider?**
  - *Answer*: By computing both in `filteredListingsProvider`, any change in either the search string or category chip automatically triggers a unified recalculation, guaranteeing UI synchronization.
- **Q2: What is the time complexity of your client-side search filtering algorithm?**
  - *Answer*: The filtering runs in $\mathcal{O}(N \times M)$ time, where $N$ is the number of active listings and $M$ is string length. In Dart, scanning 500 items takes less than 2ms, making it instantaneous on mobile processors.
- **Q3: How do you handle case-insensitivity during search?**
  - *Answer*: Both the search query and the target fields (`title`, `description`, `location`, `category`) are converted to lowercase using `.toLowerCase()` before evaluating `.contains()`.
- **Q4: What is the advantage of using Riverpod's `StateProvider` for search queries?**
  - *Answer*: `StateProvider` is a lightweight provider for storing simple mutable state. It avoids boilerplate classes for primitive types like `String` and `bool`.
- **Q5: How does `CategoryBrowseScreen` interact with the home feed?**
  - *Answer*: When a user selects a category from `CategoryBrowseScreen`, it updates `selectedCategoryProvider.state = cat` and calls `Navigator.pop(context)`. The Home screen immediately displays the filtered category items.

---

# 5. 🤝 Satvik Agrawal (Listing Details, Profiles & Peer Communication)

### 📌 Role & Responsibilities
- Engineered `listing_detail_screen.dart` with image carousel (`image_carousel.dart`) and condition badges.
- Developed peer-to-peer contact integration (`contact_helper.dart`) enabling instant WhatsApp chat, phone calls, and SMS messaging.
- Implemented the seller profile screen (`seller_profile_screen.dart`) and listing lifecycle state management ("Mark as Sold" / Delete).

### 💻 Key Code Implementation

#### WhatsApp & Native Dialer Intent Integration (`contact_helper.dart`)
```dart
class ContactHelper {
  static Future<bool> openWhatsApp({
    required String phone,
    required String sellerName,
    required String listingTitle,
    required BuildContext context,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.startsWith('+')) cleaned = cleaned.substring(1);
    if (cleaned.length == 10) cleaned = '91$cleaned'; // Standardize India country code

    final message = Uri.encodeComponent(
      "Hi $sellerName, I'm interested in your listing '$listingTitle' on Campus Marketplace!",
    );

    final url = Uri.parse('https://wa.me/$cleaned?text=$message');

    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        return await openPhoneDialer(phone: phone, context: context);
      }
    } catch (e) {
      _showError(messenger, 'Could not open WhatsApp: $e');
      return false;
    }
  }

  static Future<bool> openPhoneDialer({required String phone, required BuildContext context}) async {
    final url = Uri.parse('tel:${phone.replaceAll(RegExp(r'[^\d+]'), '')}');
    if (await canLaunchUrl(url)) return await launchUrl(url);
    return false;
  }
}
```

### ⚠️ Problems Faced & Technical Solutions
1. **Problem: Android 11+ (API 30+) Package Visibility Blocking WhatsApp & Dialer Launch**
   - *Cause*: Android 11 introduced security restrictions where `canLaunchUrl()` returns `false` unless explicit intent schemes are declared in the manifest.
   - *Fix*: Added intent `<queries>` in `android/app/src/main/AndroidManifest.xml`:
     ```xml
     <queries>
       <intent><action android:name="android.intent.action.VIEW" /><data android:scheme="https" /></intent>
       <intent><action android:name="android.intent.action.DIAL" /><data android:scheme="tel" /></intent>
       <intent><action android:name="android.intent.action.SENDTO" /><data android:scheme="smsto" /></intent>
     </queries>
     ```
2. **Problem: Accidental Listing Deletion by Sellers**
   - *Cause*: Sellers accidentally tapping delete immediately destroyed the Firestore document.
   - *Fix*: Built a modal confirmation barrier with explicit action confirmation: *"Are you sure you want to delete this listing? This action cannot be undone."*
3. **Problem: Image Carousel Blank Flickers on Poor Connections**
   - *Cause*: Slow loading of multiple network images caused layout jumps.
   - *Fix*: Built `ImageCarousel` using `CachedNetworkImage` with custom shimmer background containers and page indicator dots (`SmoothPageIndicator`).

### 🎯 Satvik Agrawal's Specific Viva Questions & Answers
- **Q1: Why did you use `LaunchMode.externalApplication` for launching WhatsApp?**
  - *Answer*: By default, `url_launcher` tries to open URLs inside an in-app WebView. WhatsApp deep links (`wa.me`) cannot run inside an in-app browser; they must be handed off to the OS to launch the standalone native WhatsApp client.
- **Q2: How does the "Mark as Sold" feature update the database and UI?**
  - *Answer*: It calls `ListingsRepository.updateListingStatus(id, isSold: true, isActive: false)`. Since the home feed listens to `activeListingsStreamProvider` (which filters for `isActive == true`), Firestore automatically pushes an update via WebSocket and the sold item disappears from the marketplace feed instantly.
- **Q3: How do you format relative timestamps (e.g., "2 hours ago", "Yesterday") in listing cards?**
  - *Answer*: In `formatters.dart`, `formatRelativeTime(DateTime dateTime)` calculates the difference `DateTime.now().difference(dateTime)` and maps minutes, hours, and days to clean readable strings.
- **Q4: How is currency formatting handled across the app?**
  - *Answer*: In `formatters.dart`, `formatPrice(double price)` uses `NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)` to display prices according to the Indian numbering format (e.g., `₹20,000`).
- **Q5: How do you handle listings where the seller has not uploaded any photos?**
  - *Answer*: `ListingCard` and `ImageCarousel` check `listing.imageUrls.isNotEmpty`. If empty, they render a placeholder icon (`Icons.image_not_supported_outlined`) with a clean background color.

---

# 📊 Master Comparison Matrix for Examiners

| Evaluation Parameter | Campus Marketplace Implementation | Industry Alternative (OLX / Facebook Marketplace) |
| :--- | :--- | :--- |
| **Target Audience** | Verified Campus Students & Staff | General Public / Unknown strangers |
| **Authentication** | Firebase Auth (Campus Email / Google OAuth) | Phone OTP / Social Logins |
| **Communication** | Direct WhatsApp & Native Phone Dialer Deep-linking | Heavy In-App Chat Server |
| **Image Pipeline** | Native on-device 80% JPEG compression (`1024x1024`) | Cloud-side transcoding servers |
| **State Management** | Riverpod 2.x Compile-Safe Streams & Providers | Redux / Bloc / MobX |
| **Database** | Firebase Cloud Firestore (Real-Time NoSQL) | PostgreSQL / MongoDB + Socket.io |
| **Client Performance** | 60–120 FPS Flutter Impeller / Skia engine | React Native Bridge / Native Android |
| **Distribution** | GitHub Releases + Direct APK Self-Update | Google Play Store / Apple App Store |
