# Spendza – Expense Tracker Mobile App

Spendza is a Flutter-based mobile expense tracker designed to help users record, manage, and monitor their daily expenses. The application uses Firebase for authentication and cloud data storage.

## Features

* User registration and login with Firebase Authentication
* Add new expenses
* Edit existing expenses
* Delete expenses
* Expense categories
* Expense date selection
* Optional expense notes
* Current-month total spending
* Expense history
* Filter expenses by category
* Filter expenses by date
* Form validation
* Loading, empty, and error states
* Responsive Flutter UI
* Light and dark mode support
* Expense data stored securely in Firebase Firestore

## Technologies & Packages Used

### Frontend

* Flutter
* Dart
* Material Design

### Backend & Database

* Firebase Authentication
* Firebase Cloud Firestore

### Packages

* `firebase_core` – Firebase initialization
* `firebase_auth` – User authentication
* `cloud_firestore` – Firestore database operations
* `intl` – Date formatting
* `flutter_secure_storage` – Secure local storage
* `flutter_launcher_icons` – Application launcher icon generation

### Development Tools

* Android Studio
* Visual Studio Code
* Git & GitHub

## Project Structure

```text
lib/
├── models/
│   ├── category_model.dart
│   └── expense.dart
│
├── screens/
│   ├── add_expenses_screen.dart
│   ├── expenses_screen.dart
│   ├── home_screen.dart
│   ├── login_screen.dart
│   └── main_navigation_screen.dart
│   └── profile_screen.dart
│   └── report_screen.dart
│   └── signup_screen.dart
│
├── services/
│   ├── app_state.dart
│   ├── firestore_service.dart
│   
└── firebase_options.dart
│
└── main.dart
```

## Project Setup

### Prerequisites

Make sure the following are installed:

* Flutter SDK
* Dart SDK
* Android Studio or Visual Studio Code
* Android SDK
* A Firebase project

Check your Flutter installation:

```bash
flutter doctor
```

### 1. Clone the Repository

```bash
git clone https://github.com/nisuli09/Spendza-Expenses_Tracker.git
```

Navigate into the project:

```bash
cd Spendza-Expenses_Tracker
```

### 2. Install Dependencies

Run:

```bash
flutter pub get
```

### 3. Configure Firebase

Create or use a Firebase project and enable:

* Firebase Authentication
* Cloud Firestore

Configure Firebase for your target platforms using the FlutterFire configuration process.


### 4. Run the Application

Connect an Android device or start an Android emulator and run:

```bash
flutter run
```

To check available devices:

```bash
flutter devices
```

## AI Tools Used

AI tools were used as development assistance throughout the project, particularly for:

**ChatGPT**

* Debugging Flutter and Dart errors
* Troubleshooting package and dependency issues
* Improving UI implementation
* Reviewing and refining code

**Claude**

* Generate the initial Flutter UI screens (Expenses, Add/Edit Expense, Reports, Profile, Login, Sign Up) from design mockups/screenshots
* Debug build and runtime issues (Gradle build waits, emulator boot failures, RAM/compatibility warnings)

**GitHub Copilot**

* Assisting with code completion and implementation

AI assistance was used as a development aid, while the application's implementation, integration, testing, and final decisions were carried out by the developer.

## Testing

The project includes Flutter widget tests under:

```text
test/
```

Run the tests using:

```bash
flutter test
```

## Author

**Nisuli Kihansa**

BSc (Hons) Computer Science
NSBM Green University / University of Plymouth
