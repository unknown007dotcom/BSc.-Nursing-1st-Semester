# CareStudy — first-year nursing learning hub

A responsive static study dashboard designed around the first-year nursing materials in the connected Google Drive. It includes interactive study-plan tracking, a lesson preview, and a Drive library with direct links to course resources.

## Run locally

Run `npm install` then `npm run dev` for the local app. `npm run build` creates the Vite static production bundle in `dist/`.

## Optional Google sign-in (Supabase free tier)

The dashboard works in local mode and is wired to the configured Supabase project. The Supabase database schema is applied; the browser client uses the project's public publishable key in `config.js` (safe to expose by design, with RLS as the data boundary). Google sign-in requires Google OAuth client credentials: the linked Supabase project reports the Google provider disabled, so enable it in Supabase Auth with your Google OAuth client ID/secret and add the deployed URL to its redirect allowlist. Keep the OAuth client secret and every Supabase secret/service-role key only in provider settings, never in browser code. Google Drive resource links open under the signed-in user's own Drive permissions; the app does not proxy or publicly share private books.

## Free-tier design choices

- Static HTML/CSS/JS: no server runtime or paid database required for the study UI.
- Study tasks, completed lesson count, and progress are stored in the browser's local storage.
- Supabase Auth and Postgres are included; the restored Supabase project is on its existing free plan. Google OAuth needs the account owner's OAuth client credentials before sign-in can work.
- Drive links are shortcuts into the owner's existing Drive. Dropbox is not needed for this first UI, and no content has been copied or shared.
- Vercel Hobby supports static deployment; this repository can be deployed there without provisioning paid services. Check current provider quotas before adding user counts, analytics, or large media.

## Next production steps

Enable Google OAuth by entering your Google client ID/secret in Supabase Auth, configure redirect origins, expand the real syllabus/course map, and add the Notes and quiz screens on the existing protected tables. Keep secret keys in provider settings and stay within each service's current free-plan quotas.
