# Festivo — Event & Food Management App

Built with Flutter + Supabase.

---

## Setup

**1. Create a Supabase project**

**2. Run the database schema**
- Go to SQL Editor in your Supabase dashboard
- Paste the contents of `supabase_schema.sql` and click Run

**3. Add your credentials** in `lib/utils/constants.dart`
```dart
static const String supabaseUrl = 'https://your-project.supabase.co';
static const String supabaseAnonKey = 'your-anon-key';
```

**5. Run**
```bash
flutter pub get
flutter run
```

---

## Features
- Register & login with email/password
- Password strength indicator
- Forgot password
- Dashboard with quick actions