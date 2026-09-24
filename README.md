# LivestockOS Flutter App

Mobile and web client for the Laravel-based multi-tenant livestock farm management platform. It supports cattle, dairy, goat, sheep, poultry and mixed farms.

## Included modules

- Authentication, farm registration and persistent API session
- Permission-aware responsive navigation
- Dashboard and operational reports
- Farms, livestock, livestock batches and health records
- Inventory, stock movements and production records
- Sales and purchase POS with multiple invoice lines
- Livestock batch purchase and head/weight-based batch sale
- Customer receipts, vendor payments and invoice payments
- Party ledger balances
- Cash, bank and mobile accounts with line-by-line running balances
- Account-to-account transfers with available-balance validation
- Income, expense and searchable accounting categories
- User and role management
- Android, iOS and web targets

## API connection

The app connects to the Laravel API under `/api/v1`.

- Android emulator default: `http://10.0.2.2/Livestock_management/public/api/v1`
- iOS simulator and web default: `http://localhost/Livestock_management/public/api/v1`
- Physical phone: open **Configure API server** on the sign-in screen and enter the computer's LAN address, for example `http://192.168.0.10/Livestock_management/public/api/v1`.

MAMP Apache and MySQL must be running. The phone and development computer must be connected to the same network when using a physical device.

## Run

```bash
flutter pub get
flutter run
```

## Quality checks

```bash
flutter analyze
flutter test
flutter build apk --debug
```

The debug APK is generated at `build/app/outputs/flutter-apk/app-debug.apk`.
