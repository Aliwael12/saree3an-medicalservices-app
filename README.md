# Saree3an Medical App

## Project Overview
Saree3an is a comprehensive medical services app that allows users to book lab tests, request ambulances, schedule doctor visits, and view their medical history. The app provides real-time tracking for ambulance requests, supports both home and lab test reservations, and features dedicated dashboards for doctors and admins.

## Tech Stack
- **Flutter** (Dart) for cross-platform mobile and web development
- **Firebase** (Firestore, Auth) for backend, authentication, and real-time data
- **Google Maps / Flutter Map** for location and tracking
- **Provider** for state management
- **Other packages:** geolocator, font_awesome_flutter, flutter_animate, etc.

## How It Was Created
The app was built using Flutter for a seamless cross-platform experience. Firebase is used for authentication, data storage, and real-time updates. The architecture follows a modular approach, separating screens, services, models, and widgets for maintainability. The UI is designed for both patients and medical professionals, with role-based access and dashboards.

## How It Works
- **User Registration & Login:** Users sign up and log in using Firebase Auth.
- **Book Lab Tests:** Users can book lab tests for home collection or at a lab. Reservations are saved in Firestore and shown in the user's history.
- **Ambulance Requests:** Users can request an ambulance, track its real-time location, and see estimated arrival time and medic info.
- **Doctor Visits:** Users can schedule doctor appointments. Doctors have a dashboard to manage and update appointment statuses.
- **History Tab:** Users can view their past doctor visits, test reservations, and ambulance requests, all fetched in real-time from Firestore.
- **Admin Dashboard:** Admins can view statistics and manage resources.

## How to Run
1. **Clone the Repository:**
   ```
   git clone <repo-url>
   cd saree3anapp
   ```
2. **Install Dependencies:**
   ```
   flutter pub get
   ```
3. **Firebase Setup:**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/).
   - Add Android/iOS/Web apps as needed.
   - Download `google-services.json` (Android) and/or `GoogleService-Info.plist` (iOS) and place them in the appropriate directories.
   - Enable Email/Password authentication in Firebase Auth.
   - Set up Firestore database with the required collections (users, doctorVisits, testReservations, ambulanceRequests, etc.).
4. **Run the App:**
   - For mobile:
     ```
     flutter run
     ```
   - For web:
     ```
     flutter run -d chrome
     ```

## Folder Structure
- `lib/screens/` — All UI screens (booking, confirmation, dashboards, etc.)
- `lib/services/` — Business logic and Firestore/Firebase interactions
- `lib/models/` — Data models for users, doctors, labs, etc.
- `lib/widgets/` — Reusable UI components
- `lib/constants/` — App-wide constants and themes
- `assets/` — Images and static assets

## Contribution & License
Feel free to fork and contribute! Please open issues or pull requests for improvements. Licensing details can be added as needed.
