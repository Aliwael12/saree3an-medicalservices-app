# Saree3an Medical App

<div align="center">
  <h3>🏥 Your Complete Medical Services Solution</h3>
  <p><strong>Book Lab Tests • Request Ambulances • Schedule Doctors • Track Medical History</strong></p>
  
  ![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
  ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
  ![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
</div>

---

## 📸 Screenshots & Demo

### App Demo (Add GIF/Video Here)
![Saree3an App Demo](https://via.placeholder.com/600x400?text=App+Demo+Video/GIF)
*Demo: Full app walkthrough showing booking and tracking features*

### Feature Highlights

#### 1. Lab Test Booking
![Lab Test Booking](https://via.placeholder.com/300x500?text=Lab+Booking+Screen)
- Easy online booking
- Home collection available
- Real-time status updates

#### 2. Ambulance Request & Tracking
![Ambulance Tracking](https://via.placeholder.com/300x500?text=Ambulance+Tracking)
- Real-time GPS tracking
- Driver information
- ETA display

#### 3. Doctor Appointments
![Doctor Scheduling](https://via.placeholder.com/300x500?text=Doctor+Appointment)
- Schedule with specialists
- View appointment history
- Doctor ratings & reviews

#### 4. Medical History
![Medical History](https://via.placeholder.com/300x500?text=Medical+History)
- Centralized records
- All past services
- Easy reference

---

## 📋 Project Overview

**Saree3an** is a comprehensive medical services app that allows users to book lab tests, request ambulances, schedule doctor visits, and view their medical history. The app provides real-time tracking, instant notifications, and a seamless healthcare experience with a clean, intuitive interface.

### Key Features
- ✅ **User Registration & Login** via Firebase Auth
- ✅ **Lab Test Booking** with home collection option
- ✅ **Real-time Ambulance Tracking** with GPS
- ✅ **Doctor Appointment Scheduling**
- ✅ **Medical History Dashboard**
- ✅ **Admin Analytics Dashboard**
- ✅ **Push Notifications**
- ✅ **Cross-platform Support** (iOS, Android, Web)

---

## 🛠️ Tech Stack

| Technology | Purpose |
|-----------|---------|
| **Flutter (Dart)** | Cross-platform mobile & web development |
| **Firebase/Firestore** | Backend, authentication & real-time database |
| **Google Maps** | Location services & ambulance tracking |
| **Provider** | State management |
| **Geolocator** | GPS tracking & location services |
| **Font Awesome Flutter** | Icon library |

---

## 🏗️ How It Works

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│   Mobile    │────────▶│   Firebase   │◀────────│   Admin     │
│   Users     │         │   Backend    │         │  Dashboard  │
└─────────────┘         └──────────────┘         └─────────────┘
       ▲                        ▲
       │                        │
       └────────┬───────────────┘
                │
        ┌───────▼────────┐
        │  Real-time DB  │
        │   (Firestore)  │
        └────────────────┘
```

### User Journey

1. **Sign Up / Login** → Firebase Authentication
2. **Browse Services** → Lab Tests, Ambulances, Doctors
3. **Book Service** → Save to Firestore
4. **Track in Real-time** → GPS updates & notifications
5. **View History** → Access past services anytime

---

## 🚀 Quick Start Guide

### Prerequisites
- Flutter SDK (latest stable)
- Dart SDK
- Firebase account
- Android Studio or Xcode (for mobile development)

### Installation Steps

#### 1. Clone the Repository
```bash
git clone https://github.com/Aliwael12/saree3an-medicalservices-app.git
cd saree3an-medicalservices-app
```

#### 2. Install Dependencies
```bash
flutter pub get
```

#### 3. Firebase Setup
- Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
- Add Android/iOS/Web apps
- Download configuration files:
  - `google-services.json` (Android) → `android/app/`
  - `GoogleService-Info.plist` (iOS) → `ios/Runner/`
- Enable **Email/Password Authentication** in Firebase Auth
- Create Firestore collections:
  ```
  - users
  - doctorVisits
  - testReservations
  - ambulanceRequests
  - drivers
  - labs
  ```

#### 4. Run the App

**Mobile (Android/iOS):**
```bash
flutter run
```

**Web:**
```bash
flutter run -d chrome
```

---

## 📁 Project Structure

```
saree3an-medicalservices-app/
├── lib/
│   ├── screens/              # UI Screens (booking, confirmation, etc.)
│   ├── services/             # Business logic & Firebase interactions
│   ├── models/               # Data models (User, Doctor, Lab, etc.)
│   ├── widgets/              # Reusable UI components
│   ├── constants/            # App-wide constants & themes
│   ├── utils/                # Helper functions
│   └── main.dart             # App entry point
├── assets/                   # Images & static assets
├── android/                  # Android-specific code
├── ios/                      # iOS-specific code
└── pubspec.yaml             # Dependencies & metadata
```

---

## 📊 Data Models

### User Model
```dart
User {
  uid: String,
  name: String,
  email: String,
  phone: String,
  medicalHistory: List<String>,
  createdAt: DateTime
}
```

### Doctor Visit Model
```dart
DoctorVisit {
  id: String,
  userId: String,
  doctorId: String,
  date: DateTime,
  status: 'scheduled'|'completed'|'cancelled',
  notes: String
}
```

### Lab Test Reservation
```dart
TestReservation {
  id: String,
  userId: String,
  labId: String,
  testType: String,
  collectionType: 'home'|'lab',
  status: 'pending'|'confirmed'|'completed'
}
```

---

## 🔐 Authentication Flow

```mermaid
Start → Sign Up/Login → Firebase Auth
          ↓
    Email/Password Verified?
          ↓
    Yes → Load User Data from Firestore
          ↓
    Display Dashboard → Choose Service
```

---

## 📱 Supported Platforms

- **Android** 5.0+
- **iOS** 11.0+
- **Web** (Chrome, Firefox, Safari)

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Contribution Guidelines
- Follow Flutter best practices
- Write clean, documented code
- Test before submitting PRs
- Update README if adding new features

---

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

---

## 👨‍💻 Author

**Aliwael12** - [GitHub Profile](https://github.com/Aliwael12)

---

## 📞 Support & Contact

For issues, questions, or feature requests:
- 📧 Open an [Issue](https://github.com/Aliwael12/saree3an-medicalservices-app/issues)
- 🔔 Star the repository to stay updated
- 💬 Check existing discussions

---

## 🗺️ Roadmap

- [ ] Prescription management
- [ ] Telemedicine consultations
- [ ] Health insurance integration
- [ ] Multi-language support (Arabic, English)
- [ ] Dark mode theme
- [ ] Voice-guided booking
- [ ] Health analytics dashboard
- [ ] Push notification system enhancement

---

<div align="center">
  <h3>Made with ❤️ for better healthcare</h3>
  <p><strong>Saree3an Medical Services App</strong></p>
  <a href="https://github.com/Aliwael12/saree3an-medicalservices-app">⭐ Star the Repository</a>
</div>
