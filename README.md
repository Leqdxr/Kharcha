# Kharchha

Kharchha is a simple personal expense tracker. Users create an account, log in, and record their daily expenses with a title, amount, category and date. The dashboard shows a list of expenses, totals, and lets the user filter, edit and delete entries.

The project is split into two apps:

- `backend/` - a Laravel REST API with token authentication (Laravel Sanctum)
- `frontend/` - a Qwik City web app that talks to the API

## Features

- Register, log in and log out with token-based authentication
- Add, edit and delete expenses
- Categories: Food, Travel, Bills, Other
- Filter the expense list by category
- Summary of total spending
- Amounts shown in Nepali Rupees (Rs.)
- Each user can only see and change their own expenses
- Responsive layout for mobile screens

## Tech Stack

| Part     | Technology                                 |
| -------- | ------------------------------------------ |
| Backend  | PHP 8.3+, Laravel 13, Laravel Sanctum      |
| Database | MariaDB                                    |
| Frontend | Qwik, Qwik City, TypeScript, Vite          |

## Project Structure

```
Kharchha/
├── backend/                  Laravel API
│   ├── app/Http/Controllers/ AuthController, ExpenseController
│   ├── app/Models/           User, Expense
│   ├── database/migrations/  Database tables
│   └── routes/api.php        API routes
└── frontend/                 Qwik app
    ├── src/components/       UI components
    ├── src/lib/              API client, auth helpers, types, formatting
    └── src/routes/           Pages: /, /login, /register, /expenses
```

## Requirements

- PHP 8.3 or newer
- Composer
- MariaDB 10.3 or newer
- Node.js 18.17+ or 20.3+ and npm

## Getting Started

### 1. Database

Create a MariaDB database and user for the app:

```sql
CREATE DATABASE kharcha CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'kharcha'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON kharcha.* TO 'kharcha'@'localhost';
FLUSH PRIVILEGES;
```

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

## API Reference

All endpoints are under `/api`. Protected endpoints need the header `Authorization: Bearer <token>`, using the token returned by register or login.

| Method | Endpoint         | Auth | Description                    |
| ------ | ---------------- | ---- | ------------------------------ |
| POST   | `/register`      | No   | Create an account              |
| POST   | `/login`         | No   | Log in and get a token         |
| GET    | `/user`          | Yes  | Get the logged-in user         |
| POST   | `/logout`        | Yes  | Revoke the current token       |
| GET    | `/expenses`      | Yes  | List the user's expenses       |
| POST   | `/expenses`      | Yes  | Create an expense              |
| PUT    | `/expenses/{id}` | Yes  | Update an expense              |
| DELETE | `/expenses/{id}` | Yes  | Delete an expense              |

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

Returns `{ "user": {...}, "token": "..." }`, or `401` if the email or password is wrong.

### Create or update an expense

```json
POST /api/expenses
{
  "title": "Lunch",
  "amount": 350,
  "category": "Food",
  "date": "2026-11-24"
}
```

Validation rules:

- `title` - required, text, up to 255 characters
- `amount` - required, number, 0 or more
- `category` - required, one of `Food`, `Travel`, `Bills`, `Other`
- `date` - required, a valid date (`YYYY-MM-DD`)

Expenses are returned newest first. Updating or deleting an expense that belongs to another user returns `403`.

## Useful Commands

Backend (inside `backend/`):

```bash
php artisan serve      # start the API server
php artisan migrate    # run database migrations
php artisan test       # run tests
```

Tests use an in-memory SQLite database (set in `phpunit.xml`), so they don't touch your MariaDB data. This needs the PHP `pdo_sqlite` extension.

Frontend (inside `frontend/`):

```bash
npm run dev            # start the dev server
npm run build          # build for production
npm run lint           # run ESLint
npm run fmt            # format code with Prettier
```
