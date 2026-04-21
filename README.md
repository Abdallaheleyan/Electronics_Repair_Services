# Electronics Repair App

A Flutter-based platform connecting customers with repair shops.

## 🛠️ Tech Stack

*   **Frontend**: Flutter (Dart)
*   **Backend**: Firebase (Auth, Firestore, Storage, Functions, Cloud Messaging)
*   **State Management**: Native `setState` (No third-party packages like Provider or Bloc are used)
*   **Maps & Location**: Google Maps Flutter & Geolocator

## ✨ Core Features

*   **User Roles**: Customers, Shop Owners, and Admins.
*   **Repair Workflow**: Create repair requests, track live status, and manage active/past tickets.
*   **Communication**: Direct chat system between customers and repair shops.

## 🚀 Getting Started

1.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

2.  **Configure Firebase:**
    Ensure you place your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in the appropriate directories, or run `flutterfire configure`.

3.  **Run the app:**
    ```bash
    flutter run
    ```
