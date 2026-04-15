Act as an expert Flutter developer and software architect. I need you to plan and scaffold a new Flutter application for tracking personal savings goals. 

Please provide a detailed project structure, dependency list, and step-by-step implementation plan based on the following requirements. 

### 1. Core Purpose & Features
- **Purpose:** A quick-view dashboard to manage savings goals, track monetary values in South African Rands (ZAR), and make deposits.
- **Home View:** Displays the total portfolio value (formatted in ZAR), a "Last Updated" timestamp below it, and a list of customizable accounts (e.g., "32-Day Notice", "Easy Equities"). Clicking an account shows its transaction history.
- **Goals View:** Displays active goals (e.g., "Car Deposit", "Holiday"). Each goal requires a progress bar, percentage completed, and the remaining monetary amount needed. Clicking a goal shows its specific transaction history.
- **Center Action (+):** A floating action button (or center nav item) that triggers a bottom sheet or modal to either:
  1. Add a new goal.
  2. Make a deposit (Requires selecting the destination Account, the target Goal, and the Amount).
- **CRUD:** Basic Create, Read, Update, and Delete functionality is required for Accounts, Goals, and Transactions.

### 2. UI/UX Requirements
- **Navigation:** Bottom Navigation Bar with three items: Home, a central '+' action button, and Goals.
- **Aesthetic:** Premium, neat, vivid, and colorful. 
- **Components:** Every account and goal must be displayed as a card with assigned or customizable colors. 
- **Offline Indicator:** A subtle UI element (like a cloud-off icon or small banner) that appears when the device loses connection.

### 3. Architecture & State Management (STRICT)
- **State Management:** BLoC (Business Logic Component). Keep a strict separation between logic and UI. 
- **Architecture Pattern:** Clean Architecture using Application, Domain, and Data layers.
- **Data Flow:** UI -> BLoC -> Service -> Repository -> Data Source.
- **Best Practices:** - Extensive use of Enums for types and states.
  - Centralized Constants for styling, strings, and routing.
  - Proper, globally handled exception management.

### 4. Data Storage & Offline Sync Strategy
- **Remote DB:** Supabase (PostgreSQL).
- **Local DB:** Hive (NoSQL key-value store).
- **Sync Strategy (Offline-First / Optimistic UI):**
  - The app must allow users to log deposits even when completely offline.
  - When offline, save new transactions to a `pending_sync` Hive box and update the local `transactions` box so the UI reflects the change immediately.
  - Implement a sync service that listens for connectivity restoration. Once online, push the queue from `pending_sync` to Supabase and clear the queue.

### Required Output from Cursor:
1. **Dependencies:** A list of all `pubspec.yaml` dependencies needed (e.g., flutter_bloc, get_it, hive, hive_flutter, supabase_flutter, connectivity_plus, intl).
2. **Folder Structure:** A tree representation of the Clean Architecture directories.
3. **Domain Models:** Draft the Dart models for `Account`, `Goal`, and `Transaction`, keeping in mind how they map to relational Supabase tables and local Hive adapters.
4. **Implementation Steps:** Provide a sequential plan to build this app, starting from domain models down to UI.