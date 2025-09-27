# DailyCare – Design

## 1. Information Architecture
- Public
  - Home (`/`): list of latest health tips
  - 404: not found fallback
- Admin
  - Login (`/login`)
  - Dashboard (`/dashboard`)

## 2. Navigation and Routing
- React Router v6
- Public routes: `/`, `*`
- Protected routes: `/dashboard` (guarded by auth state)

## 3. UI Design
- Typography: System font stack for speed; optional TailwindCSS for utility classes
- Color: clean neutrals with an accent (e.g., green) for health context
- Layout: responsive grid/cards for tips; max-width container for readability
- Components
  - `TipCard`: title, created date, content
  - `AddTipForm`: fields `title`, `content`
  - `EditTipForm`: same as add, pre-filled
  - `Header`: site title + auth controls (login/logout)
  - `Button`, `Input`, `Textarea`

## 4. State Management
- Local component state with React hooks
- Supabase client for data fetching and auth
- Simple context for auth session (subscribe to Supabase auth state)

## 5. Data Fetching
- Public: read-only `select` on `health_tips` ordered by `created_at` desc
- Admin: CRUD via Supabase client with row-level policies
- Loading and error handling patterns per view

## 6. Authentication and Authorization
- Supabase Auth (email/password)
- Store session in memory; rely on Supabase to persist via local storage
- Route guard component `RequireAuth` to protect `/dashboard`

## 7. Accessibility
- Semantic HTML for lists and forms
- Labels tied to inputs, proper focus management on dialogs/forms
- Color contrast meeting WCAG 2.1 AA

## 8. Error Handling
- Global error boundary for unexpected errors
- Inline form validation messages
- Toasts or inline alerts consistent with app styling

## 9. Styling
- Option A: TailwindCSS
- Option B: Minimal CSS modules for components; keep styles co-located

## 10. Supabase Integration
- `supabaseClient.ts` created with `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`
- Helper functions for tips CRUD encapsulated in a `services/tips.ts`

## 11. Deployment Considerations
- Environment variables configured via `.env` and host provider
- Build with `vite build`; static hosting with edge-friendly CDN


