# DailyCare – Tasks

## Phase 0 – Project Setup
- Scaffold Vite React app with TypeScript
- Add React Router, ESLint, Prettier
- Optional: TailwindCSS
- Create `supabaseClient.ts` and `.env` usage

## Phase 1 – Public Pages
- Build `Home` page listing tips (newest first)
- Create `TipCard` component
- Loading/empty/error states

## Phase 2 – Auth
- Implement `Login` page (email/password)
- Store session and add `RequireAuth` route guard
- Add `Logout` control in header

## Phase 3 – Admin Dashboard (CRUD)
- `Dashboard` page with table/list of tips
- `AddTipForm` to insert new tip
- `EditTipForm` to update tip
- Delete action with confirmation

## Phase 4 – QoL and Polishing
- Basic accessibility checks (labels, focus, contrast)
- Basic SEO tags; app title per route
- Error boundary

## Phase 5 – Testing and CI
- Component tests with React Testing Library
- e2e smoke with Playwright for login and CRUD
- CI pipeline for build and tests

## Environment Variables
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

## Deliverables
- Functional public list of health tips
- Working admin login and CRUD
- Docs updated with any deviations


