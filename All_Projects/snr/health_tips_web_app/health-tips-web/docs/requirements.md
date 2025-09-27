# DailyCare – Requirements

## 1. Overview
DailyCare is a React web application that provides daily health tips to the public and a secure admin dashboard for managing content. It uses Supabase for database and authentication.

## 2. Goals and Non-Goals
### Goals
- Deliver a fast, accessible public interface to browse health tips sorted by date.
- Provide a secure admin experience to create, read, update, and delete tips.
- Use Supabase (PostgreSQL + Auth) for data and authentication.
- Ship a maintainable codebase with basic tests, SEO, and CI-ready structure.

### Non-Goals (Initial Release)
- Complex editorial workflows (drafts, approvals, versioning).
- Role hierarchies beyond a single admin role.
- Media storage beyond future-proof placeholders (images optional later).
- Native mobile apps.

## 3. Personas
### Visitor (Public User)
- Browses health tips on the homepage.
- Needs quick load, readable typography, and mobile-friendly layout.

### Admin
- Logs in securely (email/password via Supabase Auth).
- Manages tips (add/edit/delete) via dashboard.
- Requires guardrails to avoid accidental destructive actions.

## 4. User Stories and Acceptance Criteria
### Public
1. As a visitor, I can view a list of health tips sorted by newest first.
   - Given I open the homepage, when tips load, then I see tips ordered by `created_at` descending.
   - Empty state shows a friendly message if no tips exist.
   - Loading and error states are visible and accessible.

2. As a visitor, I can read the full content of a tip in its card.
   - Long content is displayed with proper wrapping and spacing.

### Admin
3. As an admin, I can log in with email/password.
   - Login errors are displayed; successful login redirects to the dashboard.

4. As an admin, I can create a new tip with `title` and `content`.
   - Validation: title and content are required; submit disabled until valid.

5. As an admin, I can edit an existing tip.
   - Changes persist and are reflected immediately in the list.

6. As an admin, I can delete a tip.
   - A confirmation is required before deletion.

## 5. Scope
### In Scope (MVP)
- Public homepage listing tips.
- Admin login and authenticated dashboard with CRUD for tips.
- Supabase integration: database table `health_tips` and Auth.
- Basic SEO (title, meta), accessibility baseline (WCAG 2.1 AA targets).

### Out of Scope (MVP)
- Categories, images, advanced search/filters, notifications (planned future).

## 6. Functional Requirements
- List tips: query `health_tips` ordered by `created_at` desc.
- Create/edit/delete tips: available to authenticated admin only.
- Authentication state persists across reloads; logout supported.

## 7. Data Model (Supabase)
Table: `health_tips`
- `id` bigint primary key (auto increment)
- `title` text not null
- `content` text not null
- `created_at` timestamp default now()

Auth: Supabase Auth (email/password) for admin login.

Row Level Security (RLS) policies (to be configured in Supabase):
- Read: allow anonymous/select for all users.
- Write (insert/update/delete): allow only authenticated users with admin status.

## 8. Technology Stack
- Frontend: React (Vite), React Router, optional TailwindCSS.
- Backend: Supabase (PostgreSQL + Auth), Supabase JS Client SDK.
- Tooling: ESLint, Prettier, testing with React Testing Library and/or Playwright later.

## 9. Non-Functional Requirements
- Performance: First load < 2s on typical 4G; minimize bundle.
- Accessibility: Keyboard navigable, semantic HTML, sufficient contrast.
- Security: Protect admin routes, handle tokens securely, avoid exposing service keys.
- Reliability: Handle offline/slow network gracefully; clear error states.
- SEO: Basic meta tags; sitemap/robots in later phase.

## 10. Environment and Configuration
Environment variables (never hardcode secrets):
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

## 11. Risks and Mitigations
- Accidental destructive admin actions → confirmation modals and undo cues where possible.
- Misconfigured RLS → document and verify policies with test users.
- Exposing service keys in frontend → use only anon public key on client.

## 12. Success Metrics
- Time-to-content under 2s on first visit.
- Admin can complete CRUD without errors.
- Zero accessibility blockers in automated audits (e.g., Axe) for MVP pages.


