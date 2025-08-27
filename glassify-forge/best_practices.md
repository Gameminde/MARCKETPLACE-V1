# 📘 Project Best Practices

## 1. Project Purpose
A modern marketplace web application (React + TypeScript) showcasing a premium, fluid UI with 3D background elements and advanced animations. The application focuses on a rich home experience (hero, categories, featured products, shop templates), and is designed to scale toward a complete marketplace with the following functional areas:

- Core features: Home with immersive hero, animated product gallery, dynamic shop pages/templates, authentication flows, product upload with real-time validation, multi-step Stripe checkout, seller gamification, advanced search with filters + geolocation, notifications center, complete user profile.
- Advanced features: Template Builder for shops, AI-assisted product validation and content feedback, seller analytics dashboard with animated charts, integrated buyer-seller chat, reviews & ratings, favorites/wishlist with animations, personalized push notifications.

This file documents coding and architectural practices to implement those features in this repository’s stack, without prescribing themes or colors.

## 2. Project Structure
- Entry and providers
  - index.html: Vite SPA entry
  - src/main.tsx: React mount
  - src/App.tsx: App shell, global providers (React Query, Tooltip, Toasters, Router), layout (Header/Footer), routes
- Source code layout (current)
  - src/components/
    - 3d/: Background 3D canvas and particles (React Three Fiber, drei)
    - layout/: Header, Footer
    - sections/: Page-level sections (Hero, Categories, Featured, ShopTemplates)
    - ui/: Reusable UI primitives (shadcn/radix-based, glass/neon components, ErrorBoundary)
  - src/pages/: Route-level screens (Index, FigmaMCP, NotFound)
  - src/hooks/, src/lib/: Composable utilities (reserved for data, helpers)
- Configuration
  - Vite (vite.config.ts)
  - TypeScript (tsconfig*.json) with path alias @/ -> ./src
  - ESLint (eslint.config.js) with TS + React Hooks + React Refresh
  - Tailwind (tailwind.config.ts) with extended tokens and animations
- Routing
  - react-router-dom in SPA mode; add new routes in App.tsx
- Styling
  - Tailwind CSS utility-first + shadcn UI primitives + custom component classes

## 3. Test Strategy
- Frameworks
  - Unit/Component: Vitest + React Testing Library (RTL)
  - Integration/UI flows: RTL with MemoryRouter
  - E2E (optional): Playwright or Cypress
- Structure & naming
  - Co-locate tests next to components: ComponentName.test.tsx
  - Page/flow tests under src/pages/__tests__ or per-page colocation
- Mocking & data
  - Use MSW (Mock Service Worker) for API scenarios
  - For React Query tests, use a fresh QueryClient per test and wrap with QueryClientProvider
- Animations & 3D
  - Prefer reduced motion mode in tests (mock prefers-reduced-motion) and assert end-states instead of animation frames
  - 3D scenes: test presence of canvas and key nodes; keep visual correctness in E2E/snapshots if needed
- Coverage & quality
  - Aim for coverage on critical flows: auth, checkout, upload, search, favorites
  - Add accessibility assertions (axe-core/rtl-axe) for interactive components

## 4. Code Style
- TypeScript
  - Explicit types for public component props and exported utilities
  - Keep any minimal; prefer discriminated unions and zod for schema validation when needed
  - Consider gradually enabling stricter TS: noImplicitAny, strictNullChecks, noUnusedLocals/Parameters
- React
  - Functional components with named exports where practical; default exports acceptable for pages/sections
  - Props interfaces: interface Props { ... } or type Props = { ... }
  - Local UI state via useState/useReducer; server state via React Query
  - Memoization: useMemo/useCallback for expensive work or unstable dependencies
  - Avoid side effects in render; use effects sparingly and cleanup appropriately
- Styling & UI
  - Tailwind for layout/spacing/typography; compose with clsx/tailwind-merge if needed
  - Reuse components from src/components/ui; keep variants via class-variance-authority where applicable
  - Avoid inline styles for theme; only use inline for dynamic transforms/positions
- Animations
  - Framer Motion for transitions/micro-interactions; standard durations: 200ms (micro), 800ms (page)
  - Respect prefers-reduced-motion: reduce/disable heavy animations for accessibility
  - Staggered lists via variants; keep motion values out of hot re-render paths
- 3D (React Three Fiber)
  - Keep Canvas in isolated wrappers (components/3d); avoid blocking main thread
  - Minimize object counts and use instancing/points where possible
  - Consider dynamic import of heavy 3D sections and suspend until ready
- Data fetching (React Query)
  - Co-locate queries with components that use them or in feature hooks in src/hooks
  - Stable query keys; cache time and stale time tuned per feature
  - Use optimistic updates for wishlist/favorites; invalidate minimal scopes
- Error handling
  - Wrap app in ErrorBoundary (already present); add route-level boundaries for complex pages
  - Fail fast on unrecoverable errors and show actionable UI for recoverable ones

## 5. Common Patterns
- Reusable UI primitives
  - Use components in src/components/ui (e.g., GlassCard, NeonButton) for consistent interactions and states
  - Favor composition over prop bloat; add small wrappers per domain if necessary
- Sections & pages
  - Sections in src/components/sections are presentation; keep them stateless or UI-focused
  - Pages in src/pages orchestrate data, navigation, and assemble sections
- Routing
  - Define routes in App.tsx; co-locate per-page assets; prefer lazy(() => import(...)) for non-root routes
- Feature implementation guidelines (functional focus)
  - Home & Hero: parallax-like background via 3D layers, staggered entrances, keyboard-focusable CTAs
  - Product Gallery: lazy loading, virtualization if needed, skeletons, accessible cards with semantic buttons/links
  - Shop Templates: preview cards with non-blocking image loading; template selection persisted to storage/API
  - Auth: form validation (react-hook-form + zod), immediate feedback, secure redirects; avoid storing tokens in localStorage if possible (prefer httpOnly cookies server-side)
  - Product Upload: multi-step flow, client validation first; call AI validation service via safe API; show progressive hints
  - Payments (Stripe): multi-step checkout with address validation; use Stripe Elements on web; clear error/retry paths
  - Gamification: compute progress client-side from server data; non-intrusive celebration animations with reduced-motion support
  - Search & Filters: debounce input (300–500ms), URL-searchParams for shareable state, geolocation with user consent only
  - Notifications: in-app center with categories and preferences; push via Service Worker (optional), allow granular opt-in
  - Chat: optimistic send, presence/typing indicators over WebSocket; persist threads; upload attachments safely
  - Reviews & Ratings: anti-spam (rate limits), display distributions and helpful votes; allow edit within grace window
  - Favorites/Wishlist: instant UI updates (optimistic), sync on focus; merge anonymous + authenticated lists

## 6. Do's and Don'ts
- Do
  - Co-locate components and tests; keep components small and focused
  - Use React Query for server state; invalidate precisely
  - Memoize expensive derived data; wrap heavy components in React.memo
  - Adhere to accessibility: semantic HTML, focus management, ARIA when needed
  - Guard 3D features on capability and viewport; provide a lightweight fallback
  - Keep environment secrets out of the client; use VITE_ vars only for public config
- Don’t
  - Don’t block the main thread with heavy 3D or synchronous work
  - Don’t trigger re-renders via unstable props/context unnecessarily
  - Don’t rely on time-based animation assertions in unit tests; assert end states
  - Don’t hardcode business text/strings deep in components; centralize for future i18n
  - Don’t persist PII in localStorage; avoid mixing UI and data-fetch concerns

## 7. Tools & Dependencies
- Core
  - React + TypeScript, Vite (bundler)
  - Tailwind CSS + tailwindcss-animate (utilities & motion helpers)
  - shadcn UI + Radix primitives (accessible UI)
  - Framer Motion (animations)
  - React Three Fiber + drei + three (3D background/effects)
  - @tanstack/react-query (server state)
  - react-router-dom (routing)
- Developer experience
  - ESLint configured for TS + hooks; consider enabling stricter rules over time
  - Path alias @/ to shorten imports
- Setup & scripts
  - Install: npm i
  - Develop: npm run dev
  - Lint: npm run lint
  - Build/Preview: npm run build && npm run preview
- Environment variables (examples)
  - VITE_API_BASE_URL, VITE_STRIPE_PUBLIC_KEY, VITE_FEATURE_FLAGS (never commit secrets)

## 8. Other Notes
- Accessibility & inclusion
  - Minimum target size ~44px; visible focus rings; keyboard navigable dialogs/menus (Radix defaults help)
  - Always provide alt text/aria-labels for interactive icons and images
  - Respect prefers-reduced-motion; reduce particle counts and animation intensity
- Performance
  - Images: use responsive sizes and lazy loading; cache and skeletons for lists
  - 3D: limit particle/object counts; prefer points/instancing; throttle animation where offscreen
  - Code-splitting for routes/feature-heavy sections; prefetch on hover/intent where beneficial
- Error boundaries & fallbacks
  - Global ErrorBoundary present; add per-route boundaries for complex flows (upload, checkout)
- Implementation cautions (observed in repo)
  - Ensure all React hooks are imported where used (e.g., useState/useEffect in 3D components)
  - Avoid referencing undefined vars in 3D scenes; pass configuration via props rather than free variables
  - Avoid using window or WebGL APIs at module scope; guard with effects or environment checks
- LLM guidance
  - Follow this structure and reuse existing UI primitives in src/components/ui
  - Keep new sections under src/components/sections and pages under src/pages; add routes in App.tsx
  - Prefer hooks in src/hooks for reusable data/logic (queries, debounced search, feature flags)
  - Do not introduce color palettes or theme specifics here; focus on functional behavior and accessibility
