# EyeConnect

EyeConnect is a persuasive social app that connects visually impaired individuals with volunteers who can guide them through various tasks using real-time video calls and chat support.

## Features

- **Real-time Video Assistance**: Connect visually impaired users with volunteers through WebRTC-powered video calls
- **Help Request System**: Visually impaired users can create and manage help requests
- **Volunteer Dashboard**: Volunteers can view and respond to help requests
- **Profile Management**: Both users and volunteers can manage their profiles
- **Leaderboard System**: Gamification feature to encourage volunteer participation
- **Push Notifications**: Real-time notifications for help requests and updates
- **Authentication**: Secure Firebase authentication system
- **Offline Support**: Local data persistence for better user experience

## Technology Stack

- **Frontend**: Flutter (SDK ^3.5.3)
- **Backend**: Firebase
  - Cloud Firestore
  - Firebase Authentication
  - Firebase Cloud Messaging
- **Real-time Communication**: WebRTC (flutter_webrtc)
- **State Management**: Provider
- **Local Storage**: Shared Preferences
- **Notifications**: Firebase Cloud Messaging + Flutter Local Notifications

## Getting Started

### Prerequisites

- Flutter SDK (^3.5.3)
- Firebase project setup
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/eyeconnect.git
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Add your `google-services.json` to the Android app
   - Add your `GoogleService-Info.plist` to the iOS app

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── models/         # Data models
├── providers/      # State management
├── screens/        # UI screens
├── services/       # Business logic and API services
├── widgets/        # Reusable UI components
└── main.dart       # App entry point
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Firebase for the backend infrastructure
- All contributors who help make this project better
