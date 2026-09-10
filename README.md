# Classroom · Student Management System

Small staff-only student management app built with React, Vite, Tailwind, Express, and Supabase.

## Run locally

```bash
cp .env.example .env
npm install
npm run dev
```

## Connect Supabase

1. Create a Supabase project and copy the project URL, anon key, and service-role key into `.env`. Keep `SUPABASE_SERVICE_ROLE_KEY` server-only; only the two `VITE_*` values are used by the browser.
2. In Supabase SQL Editor, run [`supabase/schema.sql`](./supabase/schema.sql) in full. It creates the tables, helper functions, and teacher/admin RLS policies.
3. Create the initial admin and teacher accounts:

```bash
npm run setup:accounts
```

Default development credentials are printed by the command:

```text
admin@school.edu / ChangeMe_Admin_2025!
teacher@school.edu / ChangeMe_Teacher_2025!
```

Set `INITIAL_*` values in `.env` before running the command if you want different credentials. Change the passwords immediately after signing in.

Run `npm run server` in a second terminal for the Express API, then `npm run dev` for the frontend. The frontend uses Supabase Auth and queries Supabase directly with the browser-safe anon key.

## Optional development data

To create 50 fictional students, three classes, and test enrollments, run [`supabase/seed.dev.sql`](./supabase/seed.dev.sql) in Supabase SQL Editor after `schema.sql`. Do not run this seed in a production project. The seed uses `school.test` email addresses and is safe to rerun.

## Structure

`src/App.jsx` contains the lightweight routed screens and grade drawer. `server/index.js` contains the service-role-only staff creation route plus class, roster, and grade endpoints. `supabase/schema.sql` creates the profiles, classes, class assignments, students, enrollments, and grades tables with teacher-scoped RLS.
