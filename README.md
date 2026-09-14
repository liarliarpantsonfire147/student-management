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
2. In Supabase SQL Editor, run [`supabase/schema.sql`](./supabase/schema.sql) in full for a new project, then run [`supabase/upgrade.sql`](./supabase/upgrade.sql) to install the current roster, GPA, and class-metrics functions. If you already ran the original schema, run only `upgrade.sql`; it is safe to run repeatedly.
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

For Vercel, the project includes a serverless `POST /api/users` function for admin staff creation. Add `SUPABASE_URL` and `SUPABASE_SECRET_KEY` in Vercel's Environment Variables panel (do not prefix these with `VITE_`). `SUPABASE_SERVICE_ROLE_KEY` is supported as a legacy fallback. The frontend calls `/api/users` on the same Vercel domain automatically, so do not set `VITE_API_URL` in Vercel.

For local split-server development only, set `VITE_API_URL=http://localhost:5000` in `.env`, then run `npm run server` and `npm run dev`. The frontend uses Supabase Auth and queries Supabase directly with the browser-safe anon key.

## Optional development data

To create 50 fictional students, three classes, and test enrollments, run [`supabase/seed.dev.sql`](./supabase/seed.dev.sql) in Supabase SQL Editor after `schema.sql`. Do not run this seed in a production project. The seed uses `school.test` email addresses and is safe to rerun.

## Structure

`src/App.jsx` contains the lightweight routed screens and grade drawer. `server/index.js` contains the service-role-only staff creation route plus class, roster, and grade endpoints. `supabase/schema.sql` creates the profiles, classes, class assignments, students, enrollments, and grades tables with teacher-scoped RLS.
