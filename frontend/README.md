# Kharcha frontend

A simple expense tracker built with Qwik City and TypeScript. It talks to the
Laravel API in `../backend`.

## Requirements

- Node.js 20 or newer
- PHP 8.2+ and Composer (for the backend)

## 1. Run the backend

```shell
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate        # uses SQLite; say "yes" if asked to create the database
php artisan serve          # http://localhost:8000
```

The API allows requests from `http://localhost:5173` by default. If the
frontend runs somewhere else, set `FRONTEND_URL` in `backend/.env`.

## 2. Run the frontend

```shell
cd frontend
npm install
cp .env.example .env       # sets PUBLIC_API_URL=http://localhost:8000/api
npm run dev                # http://localhost:5173
```

Open http://localhost:5173, create an account, and start adding expenses.

## Scripts

| Command               | What it does                     |
| --------------------- | -------------------------------- |
| `npm run dev`         | Start the dev server             |
| `npm run build`       | Production build                 |
| `npm run build.types` | Type-check with TypeScript       |
| `npm run lint`        | Lint with ESLint                 |
| `npm run fmt`         | Format with Prettier             |

## Project layout

```
src/
├── components/   UI pieces (navbar, table, forms, modal, ...)
├── lib/          api.ts (fetch wrapper), auth.ts (localStorage), format.ts, types.ts
├── routes/       /, /login, /register, /expenses
├── styles/       auth.css (shared by login and register)
└── global.css    colors, fonts and shared classes
```

The login token is kept in `localStorage`, so pages check auth and load data in
the browser (`useVisibleTask$`), not on the server.
