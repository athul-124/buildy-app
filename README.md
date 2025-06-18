# Buildly - Home Services App

Buildly is a Flutter application that connects customers with trusted local professionals (electricians, plumbers, carpenters, etc.) with transparent pricing and an emotional user experience.

## Features Implemented

### ✅ Core Features
- **Authentication System**: Firebase Auth with email/password signup & login
- **User Roles**: Customer and Professional user types
- **Welcome & Onboarding**: Beautiful welcome screen with "How Buildly Works" section
- **Modern UI**: Clean, minimal design with dark mode support
- **Service Listings**: Display services with pricing and expert availability
- **Expert Profiles**: Show expert cards with skills, ratings, and contact options
- **Firebase Integration**: Firestore database for users, experts, services, and bookings

### 🎨 Design Features
- Material 3 design system
- Custom color scheme with primary (Indigo), secondary (Emerald), and accent (Amber) colors
- Responsive layouts with proper spacing and typography
- Smooth animations and transitions
- Dark mode support

### 📱 Screens Implemented
1. **Welcome Screen**: App introduction with animated elements
2. **Login Screen**: Email/password authentication with forgot password
3. **Signup Screen**: User registration with role selection (Customer/Professional)
4. **Home Screen**: Dashboard with popular services and featured experts
5. **Service Cards**: Display service information with pricing
6. **Expert Cards**: Show expert profiles with ratings and contact options

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # Main app configuration
├── config/
│   └── theme.dart           # App theme and styling
├── screens/
│   ├── welcome_screen.dart  # Welcome and onboarding
│   ├── home_screen.dart     # Main dashboard
│   └── auth/
│       ├── login_screen.dart    # Login functionality
│       └── signup_screen.dart   # User registration
├── widgets/
│   ├── expert_card.dart     # Expert profile cards
│   └── service_card.dart    # Service display cards
├── models/
│   ├── user_model.dart      # User data model
│   ├── expert_model.dart    # Expert data model
│   ├── service_model.dart   # Service data model
│   └── booking_model.dart   # Booking data model
├── services/
│   ├── auth_service.dart    # Authentication logic
│   └── firebase_service.dart # Firestore operations
└── firebase_options.dart    # Firebase configuration
```

## Setup Instructions

### 1. Prerequisites
- Flutter SDK (latest stable version)
- Firebase project
- Android Studio / VS Code
- Git

### 2. Clone and Setup
```bash
git clone <repository-url>
cd buildy_app
flutter pub get
```

### 3. Firebase Configuration

#### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project named "Buildly"
3. Enable Authentication (Email/Password)
4. Create Firestore Database
5. Add your app (Android/iOS/Web)

#### Configure Firebase
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login: `firebase login`
3. Configure FlutterFire: `dart pub global activate flutterfire_cli`
4. Run: `flutterfire configure`

#### Update Configuration
Update `lib/firebase_options.dart` with your Firebase project credentials.

### 4. Environment Variables
Update `.env` file with your API keys:
```env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_API_KEY=your-api-key
RAZORPAY_KEY_ID=your-razorpay-key
GOOGLE_MAPS_API_KEY=your-maps-key
OPENAI_API_KEY=your-openai-key
```

### 5. Run the App
```bash
flutter run
```

## Firebase Firestore Collections

### Users Collection (`/users`)
```json
{
  "uid": "string",
  "name": "string",
  "email": "string",
  "role": "customer | professional",
  "address": "string",
  "phone": "string",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Experts Collection (`/experts`)
```json
{
  "name": "Anil Kumar",
  "specialty": "Electrician",
  "location": "Thrissur Town",
  "skills": ["Wiring", "Repair"],
  "experienceYears": 10,
  "description": "Experienced electrician...",
  "whatsapp": "https://wa.me/91xxxxxx",
  "rating": 4.8,
  "reviewCount": 45,
  "isAvailable": true
}
```

### Services Collection (`/services`)
```json
{
  "title": "AC Servicing",
  "category": "Appliance Repair",
  "priceRange": "₹600 - ₹1,200",
  "description": "Routine maintenance and cleaning",
  "expertIds": ["expert1", "expert2"],
  "tags": ["AC", "Servicing"],
  "isPopular": true
}
```

### Bookings Collection (`/bookings`)
```json
{
  "userId": "abc123",
  "expertId": "xyz789",
  "serviceId": "svc001",
  "status": "pending",
  "scheduledAt": "timestamp",
  "paymentStatus": "paid",
  "amount": 1200,
  "address": "Customer address"
}
```

## Sample Data

The app includes sample data initialization:
- 3 sample experts (Electrician, Plumber, Carpenter)
- 4 sample services (AC Servicing, Electrical Wiring, Plumbing Repair, Furniture Repair)

## Next Steps

### Upcoming Features
1. **Service Detail Pages**: Detailed service information and booking flow
2. **Expert Detail Pages**: Complete expert profiles with reviews
3. **Booking System**: Full booking flow with date/time selection
4. **Maps Integration**: Google Maps for location services
5. **Payment Gateway**: Razorpay integration for payments
6. **AI Chat Assistant**: OpenAI-powered chat support
7. **Search & Filters**: Advanced search and filtering options
8. **Reviews & Ratings**: User review system
9. **Push Notifications**: Booking updates and reminders
10. **Admin Panel**: Service and expert management

### Technical Improvements
- Error handling and loading states
- Offline support with local caching
- Performance optimization
- Unit and integration tests
- CI/CD pipeline setup

## Dependencies

```yaml
dependencies:
  flutter: sdk: flutter
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  razorpay_flutter: ^1.3.7
  provider: ^6.1.1
  http: ^1.1.2
  intl: ^0.19.0
  flutter_dotenv: ^5.1.0
  url_launcher: ^6.2.2
  cupertino_icons: ^1.0.8
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please contact the development team or create an issue in the repository.
