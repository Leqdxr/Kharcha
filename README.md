# Kharcha

Kharcha is a personal expense tracker made for Nepal. Users create an account, log in, and record their daily expenses with a title, amount, category, payment method, date and an optional note. Each month gets its own view: the total compared with last month, a monthly budget with how much is safe to spend today, where the money went by category, and the list of expenses grouped by day.

It also keeps track of income and the TDS cut from it (with an estimate of the year's tax), money lent to and borrowed from friends (udharo), savings goals and monthly bills. Dates can be shown in Bikram Sambat (BS) or AD.

The project is split into three apps:

- `backend/` - a Laravel REST API with token authentication (Laravel Sanctum)
- `frontend/` - a Qwik City web app that talks to the API
- `mobile/` - a Flutter Android app that talks to the same API

## Features

- Register, log in and log out with token-based authentication
- Add, edit and delete expenses, each with an optional note
- Categories: Food, Travel, Bills, Other
- Month switcher: the list and every number show one month at a time
- Total for the month, compared with the month before ("16% less than October")
- Monthly budget with a progress bar and the amount left
- "Where it went": spending per category, high to low
- Expense list grouped by day, filtered by category chips and (on the web) a search box
- Asks for confirmation before deleting an expense, removing the budget or logging out
- On the phone: swipe a row left to delete it, or hold it to select several expenses (or incomes on the Tax tab) and delete them together
- Amounts shown in Nepali Rupees (Rs.)
- Each user can only see and change their own data
- Responsive web layout down to phone width
- Native Android app with Expenses, Insights, Udharo and Tax tabs, keeping you logged in between launches

**Nepal features (v3)**

- **BS or AD dates**: dates are shown in Bikram Sambat ("10 Mangsir 2083") or AD ("26 Nov 2026"). The choice is saved on the account, so web and mobile match. Dates are always stored and sent as AD, and monthly views stay on AD months
- **Payment method** on each expense: Cash, eSewa, Khalti, Bank card or Mobile banking (Settings chooses which ones show up)
- **Quick add** chips: Tea 25, Bus fare 30, Lunch 150, Momo 180, Phone recharge 500
- **Repeating bills**: "Repeat every month" creates the expense again on the same day each month. The mobile home shows the next three as "Upcoming bills". Turning the switch off in the edit form stops the repeat, and so does deleting the repeat's last expense
- **Safe to spend today**: what is left of the budget, divided by the days left in the month
- **Tax & TDS**: add income (salary, service fees, rent, interest, dividends) with the TDS filled in from the rate, see what you may get back or still owe for the fiscal year, how it was worked out slab by slab, and export the year's income as CSV (web)
- **Udharo**: who owes you and whom you owe, Settle with Undo, and Split a bill (each friend owes you an equal whole-rupee share; your share becomes an expense)
- **Savings goals** (mobile): progress, how much to save a month to make it, + Rs. 500 and "Add money". Money in goals doesn't count as spending
- **Settings** (mobile): calendar, Nepali fiscal year (on: the Tax tab lists Shrawan to Asar; off: January to December, and the web follows it too; the estimate always uses the fiscal year), budget, goals, payment methods, SSF contributor and PAN number. Changes show at once and save in the background. The PAN stays on the phone and is never sent to the API

> **Tax numbers are estimates only, not tax advice.** Every tax number (fiscal year dates, slabs, the SSF rule and the TDS rates for FY 2083/84) lives in one file, `backend/config/tax.php`, so next year's budget is a one-file change.

## Tech Stack

| Part     | Technology                                 |
| -------- | ------------------------------------------ |
| Backend  | PHP 8.3+, Laravel 13, Laravel Sanctum      |
| Database | MariaDB                                    |
| Frontend | Qwik, Qwik City, TypeScript, Vite          |
| Mobile   | Flutter, Dart                              |

## Project Structure

```
Kharcha/
├── backend/                  Laravel API
│   ├── app/Http/Controllers/ Auth, Expense, Summary, Budget, Settings, Income,
│   │                         TaxSummary, Udharo, Goal and RecurringExpense
│   ├── app/Models/           User, Expense, Income, Udharo, Goal, RecurringExpense
│   ├── app/Services/         TaxEstimator, RecurringExpenses
│   ├── config/tax.php        Fiscal year, tax slabs, SSF rule, TDS rates
│   ├── database/migrations/  Database tables
│   ├── routes/api.php        API routes
│   └── tests/Feature/        PHPUnit feature tests
├── frontend/                 Qwik app
│   ├── src/components/       UI components
│   ├── src/lib/              API client, auth helpers, types, formatting,
│   │                         quick add presets
│   └── src/routes/           Pages: /, /login, /register, and inside (app)/
│                             (logged in): /expenses, /tax, /udharo
└── mobile/                   Flutter app
    ├── lib/models/           User, Expense, Summary, Income, Udharo, Goal
    ├── lib/services/         API client, secure token and PAN storage, session
    ├── lib/screens/          Login, Register, Home (4 tabs), Goals, Settings
    └── lib/widgets/          Tabs, month switcher, summary card, expense row,
                              add/edit, income and udharo sheets, form fields
```

## Requirements

- PHP 8.3 or newer
- Composer
- MariaDB 10.3 or newer
- Node.js 18.17+ or 20.3+ and npm
- For the mobile app: Flutter (stable channel), plus an Android emulator or an Android phone with USB debugging

## Getting Started

### 1. Database

Create a MariaDB database and user for the app, plus a second database for the tests (`php artisan test` empties and rebuilds it on every run, so it must never be the real one):

```sql
CREATE DATABASE kharcha CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE kharcha_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'kharcha'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON kharcha.* TO 'kharcha'@'localhost';
GRANT ALL PRIVILEGES ON kharcha_test.* TO 'kharcha'@'localhost';
FLUSH PRIVILEGES;
```

If you already have the `kharcha` database, you only need the test database. Log in as root (`sudo mariadb`) and run:

```sql
CREATE DATABASE kharcha_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON kharcha_test.* TO 'kharcha'@'localhost';
FLUSH PRIVILEGES;
```

Laravel connects over TCP to `127.0.0.1`, which MariaDB can treat as a different host from `localhost`. If your `kharcha` user was created as `'kharcha'@'127.0.0.1'`, use that in the `GRANT` instead. The same goes for the command line: `mariadb -h 127.0.0.1 -u kharcha -p kharcha`.

### 2. Backend

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
```

Set the database connection in `backend/.env`, using the password you chose above:

```
DB_CONNECTION=mariadb
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=kharcha
DB_USERNAME=kharcha
DB_PASSWORD=your_password
```

Then run the migrations and start the server:

```bash
php artisan migrate
php artisan serve
```

The API runs at `http://localhost:8000/api`.

By default the API allows requests from `http://localhost:5173`. If the frontend runs on a different address, set it in `backend/.env`:

```
FRONTEND_URL=http://localhost:5173
```

### 3. Frontend

In a new terminal:

```bash
cd frontend
npm install
cp .env.example .env
npm run dev
```

The app runs at `http://localhost:5173`. The API address is set in `frontend/.env`:

```
PUBLIC_API_URL=http://localhost:8000/api
```

### 4. Mobile (optional)

The emulator or phone has to reach the backend over the network, so start the API on all interfaces:

```bash
cd backend
php artisan serve --host=0.0.0.0 --port=8000
```

Then, in a new terminal, run the app on an Android emulator:

```bash
cd mobile
flutter pub get
flutter run
```

The default API URL is `http://10.0.2.2:8000/api`, which is how the emulator reaches your computer's `localhost`. On a real phone (on the same Wi-Fi), pass your computer's IP instead:

```bash
flutter run --dart-define=API_URL=http://192.168.1.20:8000/api
```

See [`mobile/README.md`](mobile/README.md) for finding your IP, troubleshooting, and building a release APK.

## API Reference

All endpoints are under `/api`. Protected endpoints need the header `Authorization: Bearer <token>`, using the token returned by register or login. They only ever read or change the logged-in user's own data.

| Method | Endpoint                           | Auth | Description                                                             |
| ------ | ---------------------------------- | ---- | ----------------------------------------------------------------------- |
| POST   | `/register`                        | No   | Create an account                                                       |
| POST   | `/login`                           | No   | Log in and get a token                                                  |
| GET    | `/user`                            | Yes  | The logged-in user, with `monthly_budget` and the settings              |
| POST   | `/logout`                          | Yes  | Revoke the current token                                                |
| PUT    | `/settings`                        | Yes  | Change `calendar`, `ssf_contributor`, `fiscal_year_view`, `payment_methods` |
| GET    | `/expenses`                        | Yes  | List all expenses, newest first (creates due repeating bills first)     |
| GET    | `/expenses?month=YYYY-MM`          | Yes  | List one month's expenses, newest first                                 |
| POST   | `/expenses`                        | Yes  | Create an expense                                                       |
| PUT    | `/expenses/{id}`                   | Yes  | Update an expense                                                       |
| DELETE | `/expenses/{id}`                   | Yes  | Delete an expense (the last one of a repeat also stops the repeat)      |
| GET    | `/summary?month=YYYY-MM`           | Yes  | Totals for a month (default: this month), `days_left`, `safe_to_spend`  |
| PUT    | `/budget`                          | Yes  | Set or clear the monthly budget                                         |
| GET    | `/recurring-expenses`              | Yes  | Repeating bills, next one first                                         |
| POST   | `/recurring-expenses`              | Yes  | Repeat an expense every month: `{ "expense_id": 12 }`                   |
| DELETE | `/recurring-expenses/{id}`         | Yes  | Stop repeating (expenses already made stay)                             |
| GET    | `/incomes`                         | Yes  | List incomes, newest first                                              |
| POST   | `/incomes`                         | Yes  | Add an income                                                           |
| PUT    | `/incomes/{id}`                    | Yes  | Update an income                                                        |
| DELETE | `/incomes/{id}`                    | Yes  | Delete an income                                                        |
| GET    | `/tax/summary`                     | Yes  | Income, TDS and the tax estimate for the current fiscal year            |
| GET    | `/udharos`                         | Yes  | Unsettled udharo entries, newest first                                  |
| POST   | `/udharos`                         | Yes  | Add an udharo                                                           |
| PUT    | `/udharos/{id}`                    | Yes  | Update an udharo                                                        |
| DELETE | `/udharos/{id}`                    | Yes  | Delete an udharo                                                        |
| POST   | `/udharos/{id}/settle`             | Yes  | Mark it settled (hides it from the list)                                |
| POST   | `/udharos/{id}/unsettle`           | Yes  | Undo a settle                                                           |
| POST   | `/udharos/split`                   | Yes  | Split a bill you paid: friends' udharos plus your share as an expense   |
| GET    | `/goals`                           | Yes  | List savings goals                                                      |
| POST   | `/goals`                           | Yes  | Create a goal                                                           |
| PUT    | `/goals/{id}`                      | Yes  | Update a goal                                                           |
| DELETE | `/goals/{id}`                      | Yes  | Delete a goal                                                           |
| POST   | `/goals/{id}/deposit`              | Yes  | Add money to a goal: `{ "amount": 500 }`                                |

Validation errors return `422` with an `errors` object per field. Changing another user's row returns `403`. A missing or expired token returns `401`.

### Register

```json
POST /api/register
{
  "name": "Ram",
  "email": "ram@example.com",
  "password": "secret123",
  "password_confirmation": "secret123"
}
```

Returns `201` with `{ "user": {...}, "token": "..." }`.

### Login

```json
POST /api/login
{
  "email": "ram@example.com",
  "password": "secret123"
}
```

Returns `{ "user": {...}, "token": "..." }`, or `401` if the email or password is wrong. The user object includes `monthly_budget` (a whole number of rupees, or `null`).

### Create or update an expense

```json
POST /api/expenses
{
  "title": "Lunch",
  "amount": 350,
  "category": "Food",
  "date": "2026-11-24",
  "note": "With friends after class"
}
```

Validation rules:

- `title` - required, text, up to 255 characters
- `amount` - required, number, 0 or more
- `category` - required, one of `Food`, `Travel`, `Bills`, `Other`
- `payment_method` - optional, one of `cash`, `esewa`, `khalti`, `bank_card`, `mobile_banking`
- `date` - required, a valid date (`YYYY-MM-DD`)
- `note` - optional, text, up to 255 characters

Expenses also return `recurring_expense_id`: set when the expense repeats every month.

### Monthly summary

```
GET /api/summary?month=2026-11
```

```json
{
  "month": "2026-11",
  "total": 8060,
  "count": 10,
  "previous_month": "2026-10",
  "previous_total": 9600,
  "budget": 20000,
  "by_category": [
    { "category": "Bills", "total": 3240 },
    { "category": "Food", "total": 2970 },
    { "category": "Travel", "total": 1020 },
    { "category": "Other", "total": 830 }
  ]
}
```

The response also has `days_left` (days left in the month including today, or `null` for other months) and `safe_to_spend` (what's left of the budget divided by `days_left`, rounded; `0` when over budget, `null` with no budget or for other months).

`by_category` is sorted from highest to lowest and only lists categories with spending. `budget` is `null` when no budget is set.

### Monthly budget

```json
PUT /api/budget
{ "monthly_budget": 20000 }
```

`monthly_budget` must be present: a whole number from 0 to 100000000, or `null` to clear the budget. Returns the updated user.

### Settings

```json
PUT /api/settings
{ "calendar": "ad", "ssf_contributor": true, "fiscal_year_view": false, "payment_methods": ["cash", "esewa"] }
```

Send only the fields you want to change. `calendar` is `bs` or `ad`. `fiscal_year_view` (default `true`) chooses which year the apps list income for: the Nepali fiscal year, or the calendar year when `false`. `GET /tax/summary` always uses the fiscal year. Returns the updated user.

### Income and the tax summary

```json
POST /api/incomes
{
  "title": "Acme Pvt Ltd",
  "amount": 100000,
  "type": "salary",
  "tds_amount": 9000,
  "date": "2026-08-15",
  "note": "Shrawan salary"
}
```

`type` is one of the keys in `config/tax.php`: `salary`, `service_pan`, `service_vat`, `rent`, `interest`, `dividend`. `tds_amount` can't be more than `amount`.

`GET /api/tax/summary` works it out for the fiscal year in `config/tax.php`:

- Projected salary = average monthly salary entered so far x 12
- Taxable income = projected salary + all other income except interest and dividends (final withholding)
- Tax = the slabs (the 1% slab is waived for SSF contributors)
- `adjustable_tds_year_end` = average monthly salary TDS x 12 + TDS on the other non-final income
- `result` = `adjustable_tds_year_end` - tax: positive means you may get money back, negative means you may still owe

It also returns `types` (labels and rates), `totals`, `slabs` (one row per slab with `taxable`, `tax` and `waived`), `estimated_tax`, `effective_rate`, `tds_so_far` and `final_tds`.

### Udharo and Split a bill

```json
POST /api/udharos
{ "person": "Sujan", "amount": 500, "direction": "lent", "note": "Bus fare", "date": "2026-11-20" }
```

`direction` is `lent` (they owe you) or `borrowed` (you owe them).

```json
POST /api/udharos/split
{ "title": "Pizza", "total": 1001.5, "friends": ["Sujan", "Priya"], "category": "Food" }
```

Everyone's share is the total divided by the number of people, rounded down to whole rupees for each friend. You take the remainder (here 333 each for Sujan and Priya, 335.50 for you). It creates one `lent` udharo per friend and your share as an expense, all in one transaction. `category` defaults to `Food`, and `date` (optional) defaults to today.

### Goals

```json
POST /api/goals
{ "name": "New laptop", "target": 120000, "target_date": "2027-06-01" }
```

`saved` starts at 0. Use `POST /api/goals/{id}/deposit` with `{ "amount": 500 }` to add money.

## Useful Commands

Backend (inside `backend/`):

```bash
php artisan serve      # start the API server
php artisan migrate    # run database migrations
php artisan test       # run tests
```

Tests run on the `kharcha_test` MariaDB database (set in `phpunit.xml`; host, user and password come from `backend/.env`). Create it first, as shown in step 1. Every test run wipes and rebuilds that database, and never touches `kharcha`.

Frontend (inside `frontend/`):

```bash
npm run dev            # start the dev server
npm run build          # build for production
npm run lint           # run ESLint
npm run fmt            # format code with Prettier
```

Mobile (inside `mobile/`):

```bash
flutter pub get        # install dependencies
flutter run            # run on an emulator or connected phone
flutter analyze        # check the code for problems
flutter build apk --release --dart-define=API_URL=http://<your-ip>:8000/api
```
