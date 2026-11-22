WholeMarket

CS310 Mobile Application Development - Group 24

WholeMarket is a Flutter-based mobile application designed to help small retailers manage their inventory, product pricing, and promotional campaigns.

The application aims to reduce product waste, improve pricing decisions and increase business efficiency through smart discount recommendations and inventory management tools.

Core Features

-Product and Inventory Management: Add, edit, and delete products, including prices, costs, stock quantities and expiration dates.
-Expiration Date Tracking and Filtering: Identify and filter products approaching expiration.
-Smart Discount Recommendations: Suggest discounts based on expiration dates, stock levels and product costs.
-Competitor Price Comparison: Manually enter and compare competitors' product prices.
-Seasonal Promotion Planner: Schedule and manage promotional campaigns.
-Dashboard: View inventory summaries, expiring products, promotions and discount suggestions.

Optional Features

-Sales and waste analytics
-Demand forecasting
-Smart restocking
-Notifications

Technologies Used

-Flutter & Dart
-SQLite (local database)
-Git & GitHub

Group Members

-Can Aksoy
-Zeynep Yağmur Demir
-Yasin Berkay Narin


## Requirements and Setup

### Flutter Version

- Flutter: 3.50.1
- Dart: 3.14.0

These versions were verified using GitHub Actions.

### Development Environment

- Flutter SDK
- Android Studio with an Android emulator, or Xcode with an iOS simulator on macOS
- Tested on a Pixel 9 Android emulator running Android 17 (API 37)

### How to Run

1. Clone the repository:

   `git clone https://github.com/HomerTheRoamer/WholeMarket-CS310.git`

2. Navigate to the project directory:

   `cd WholeMarket-CS310`

3. Install dependencies:

   `flutter pub get`

4. Start an Android emulator or iOS simulator.

5. Check available devices:

   `flutter devices`

6. Run the application:

   `flutter run`

### Step 2.2 Implementation Notes

- Authentication screens are UI-only demonstrations.
- Real user accounts and email verification are not implemented in this step.
- Products are stored locally using SQLite.
- Selected demo preferences, competitor observations, and promotions use SharedPreferences.
- Firebase Authentication and user-specific data management are planned for Step 3.
