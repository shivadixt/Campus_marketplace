# Campus Marketplace — Project Synopsis

## 1. Project Title
**Campus Marketplace** — A Mobile App for College Students to Buy & Sell Pre-owned Items

---

## 2. Overview
Campus Marketplace is a simple and fast cross-platform mobile application built with **Flutter**. It allows college students to buy and sell second-hand items—such as books, electronics, cycle, calculators, and notes—directly with peers within their college.

---

## 3. Problem Statement
Students often have used textbooks, calculators, or gadgets they no longer need after a semester, while other students look to buy those same items at lower prices. Existing platforms like OLX are too broad and involve unknown people or shipping hassles. Campus Marketplace solves this by offering a secure, campus-only trading platform.

---

## 4. Key Features

- **User Authentication**: Simple signup, login, and profile management with email and password.
- **Product Listings**: Upload photos, title, price, description, condition, and category.
- **Search & Filters**: Search products by name and filter by categories (Books, Electronics, Stationery, etc.).
- **Direct Contact**: Contact sellers instantly via **WhatsApp** or **Direct Phone Call**.
- **Listing Management**: Mark items as "Active" or "Sold", edit details, or delete items.

---

## 5. Technology Stack

| Component | Technology | Purpose |
|---|---|---|
| **Frontend App** | Flutter (Dart) | Cross-platform mobile app (Android & iOS) |
| **State Management** | Riverpod | Easy state and data management |
| **Authentication** | Firebase Auth | User login and registration |
| **Database** | Cloud Firestore | Real-time database for products and users |
| **Image Storage** | Cloudinary | Fast photo upload and cloud storage |
| **Direct Contact** | URL Launcher | Open WhatsApp chat and phone dialer |

---

## 6. App Architecture Flow

```text
Student (Mobile App)
       │
       ├─► Firebase Auth   ── (User Login / Signup)
       ├─► Cloud Firestore ── (Save & Fetch Product Listings)
       ├─► Cloudinary      ── (Upload & Store Item Photos)
       └─► WhatsApp / Call ── (Direct Chat with Seller)
```

---

## 7. Folder Structure

```text
lib/
├── main.dart
├── backend/
│   ├── constants/       # App settings & categories
│   ├── models/          # Data models (Listing, UserProfile)
│   ├── providers/       # State providers (Auth, Listings, Search)
│   ├── services/        # Firebase & Cloudinary upload services
│   └── utils/           # Formatters & input validation
└── frontend/
    ├── screens/         # Login, Signup, Home, Product Details, Profile
    ├── widgets/         # Cards, Search Bar, Filter Chips
    └── theme/           # App colors and styles
```

---

## 8. Expected Outcome
A clean, easy-to-use mobile app that helps college students save money, trade easily on campus, and promote recycling of student essentials.
