# 📘 Project Best Practices

## 1. Project Purpose
A multi-part marketplace workspace comprising:
- A production-grade backend API (Node.js/Express) under marketplace/backend with robust security hardening, validation, and modular architecture.
- A Flutter mobile app under marketplace/app targeting frontend/mobile experiences that interact with the API.
- A lightweight root-level Express server (backend/) used for simple demos/health/templates.
- Developer tooling such as a Git Watcher daemon that suggests actions on file changes.

Domain focus: e-commerce marketplace with templates/themes, shop and product management, authentication, payments, and AI-assisted features (validation, content, analytics).

## 2. Project Structure
Top-level folders (selected):
- backend/: Simple Express server with MongoDB and Cloudinary demo endpoints.
- marketplace/
  - backend/: Main API service.
    - server.js: App entrypoint (security, middleware, routing, env validation, startup/shutdown).
    - src/
      - controllers/: Route handlers following SOLID and validation via Joi; extends BaseController.
      - routes/: Express route definitions (versioned, auth-protected where needed).
      - services/: Business logic, integration clients, security and logging services.
      - middleware/: Cross-cutting concerns (auth, rate limiting, errors, tracing, uploads).
      - models/: Data models (Mongoose models expected here).
      - validators/: Joi schemas and validators for inputs.
      - utils/: Helpers (tokens, caches, etc.).
      - scripts/: Operational scripts (import templates, tests, etc.).
      - data/: Static datasets/fixtures.
    - tests/: Jest-based test suites.
      - unit/: Focused logic and route unit tests with mocks.
      - integration/: API-level tests with Supertest.
      - security/: Security hardening tests (Phase 3).
  - app/: Flutter project (lib/, test/, integration_test/).
- glassify-forge/: Separate web UI project (has its own best_practices.md).
- git-watcher.js: Chokidar-based dev tool that watches files, suggests Git/CI actions.

Configuration and entry points:
- marketplace/backend/.env (required) with strict validation; .env.example provides template.
- marketplace/backend/server.js mounts security middleware, routes under /api/v1, and starts the server.
- marketplace/backend/package.json scripts for dev/test/lint.
- Root package.json provides Git Watcher scripts and dev dependencies.

Separation of concerns:
- Controllers perform input validation and orchestration only, delegating business logic to services.
- Services encapsulate domain logic and external integrations (DB, Redis, Stripe, AI, Cloudinary).
- Middleware centralizes auth, error mapping, tracing, rate limiting, and security policies.
- Routes declare URL schemas and bind middleware + controllers.

## 3. Test Strategy
Frameworks and libraries:
- Backend (marketplace/backend): Jest + Supertest for unit/integration; Mongoose for test DB setup.
- Flutter app: Uses Flutter test and integration_test (Dart) for widget and integration tests.

Structure and naming:
- marketplace/backend/tests/
  - unit/: Component-level tests (e.g., auth.controller.test.js) with mocks.
  - integration/: API flow tests (e.g., api-flutter.test.js) using request(app).
  - security/: End-to-end security validations (e.g., headers, rate limiting, validation).
- Prefer test file names with .test.js suffix. Integration tests may be grouped by feature/consumer (Flutter).

Mocking guidelines:
- For unit tests, mock external services, models, caches, and token/crypto utilities (jest.mock(...)).
- Validate response shapes and error codes; avoid hitting external networks in unit tests.

Unit vs integration:
- Unit: Validate controller/service logic in isolation (happy paths, validation errors, edge cases). Use mocks for DB/IO.
- Integration: Use Supertest against the Express app, optionally connecting to a test MongoDB (MONGODB_URI_TEST). Exercise routing, middleware (auth, validation), and response formatting.
- Security tests: Assert headers from Helmet, CORS behavior, rate limiting, XSS/SQLi validation paths, JSON parsing errors.

Coverage expectations:
- Critical flows (auth, templates, shops/products, rate limiting, error middleware) should be covered.
- Add tests as you introduce new services, validators, or routes. Aim for fast tests and representative integration coverage.

## 4. Code Style
Language and modules:
- Node.js JavaScript (CommonJS require/module.exports). Use async/await and structured error handling.
- Use Joi for input validation at the controller boundary.

Naming conventions:
- Files: feature.type.js (e.g., template.controller.js, jwt-security.service.js, error.middleware.js, template.routes.js).
- Classes: PascalCase (e.g., BaseController, StructuredLogger, DatabaseService).
- Functions/variables: camelCase; constants UPPER_SNAKE_CASE when appropriate.
- Route paths: kebab-case for URL segments; version under /api/v1.

Validation and typing:
- Validate all external inputs using Joi schemas. Normalize and coerce types (numbers, arrays) as needed.
- Sanitize where applicable (e.g., validators/services checking for XSS/SQLi patterns).

Commenting/documentation:
- Keep high-value comments explaining intent, security constraints, and non-obvious decisions.
- Document public service methods and controller responsibilities.

Error and exception handling:
- Use centralized error middleware (error.middleware.js) with consistent error mapping:
  - success: false, error.code, message, timestamp, requestId
- Expose stack traces only in development/staging.
- In controllers, use BaseController.handleError for consistent responses; log through structured-logger.service.

Security and performance:
- Enforce Helmet, CORS, HPP, xss-clean, compression. Apply express-rate-limit and express-slow-down.
- Cap JSON payload size (MAX_FILE_SIZE) and validate JSON in body parser verify hook.
- Prefer streaming or background processing for heavy tasks; avoid blocking the event loop.

## 5. Common Patterns
- BaseController pattern
  - Validation helpers and handleError centralizing error mapping.
  - Consistent sendSuccess shape for responses with data/meta where used.
- Service-oriented design
  - Business logic lives in services (template.service, jwt-security.service, database.service, redis services, AI services).
  - Encapsulate integrations (Stripe, Cloudinary, Redis, MongoDB, external AI) in dedicated services.
- Middleware-first security
  - Auth middleware parses and verifies Bearer JWT, supports requireRole('admin') and optional auth.
  - Error middleware maps all failures to structured responses; tracing middleware attaches request IDs.
  - Rate limiters and slow-down on /api/*; CORS configured per environment.
- Versioned API routing
  - All feature routes mounted under /api/v1; separate routers per domain (auth, users, shops, products, templates, payments, monitoring, ai).
- Environment-driven configuration
  - Strict .env verification for production; no hardcoded secrets; JWT_SECRET min length; warning on non-Atlas Mongo in prod.
- Logging
  - Winston-based structured logger with audit and error files; optional Elasticsearch integration hook.

## 6. Do's and Don'ts
- Do
  - Validate all inputs with Joi at the edge (controllers); enforce types and domain rules.
  - Use services for side effects and domain logic; keep controllers thin.
  - Return consistent JSON envelopes (success, data/error, timestamp, requestId).
  - Use auth middleware and requireRole for protected endpoints; check blacklist for revoked tokens.
  - Apply Helmet, CORS, HPP, xss-clean, compression globally; keep rate limiting on API routes.
  - Keep secrets in .env files only. Use generate-secrets.js and copy .env.local -> .env as instructed.
  - Add unit tests for non-trivial logic and integration tests for API flows.
  - Implement graceful shutdown: close HTTP server, DB, Redis cleanly.
- Don't
  - Don’t expose stack traces or sensitive fields in production responses/logs.
  - Don’t hardcode credentials, tokens, or default placeholder values. Enforce JWT_SECRET length.
  - Don’t bypass centralized error handling; avoid ad-hoc res.status(...).json(...) in services.
  - Don’t block the event loop with heavy synchronous work; don’t perform long-running tasks in request cycle.
  - Don’t couple controllers directly to transport or storage details; use services.

## 7. Tools & Dependencies
Key libraries (marketplace/backend):
- Express, Helmet, CORS, Compression, HPP, xss-clean
- express-rate-limit, express-slow-down
- Joi (validation)
- Mongoose (MongoDB), pg (PostgreSQL), Redis clients (ioredis/redis)
- jsonwebtoken, bcryptjs
- Winston (structured logging)
- Stripe, Cloudinary, Sharp (images) as integrations
- Supertest, Jest (tests)

Setup instructions:
- marketplace/backend
  - cp .env.example .env (or cp .env.local .env) and fill real values (never placeholders).
  - npm install
  - Development: NODE_ENV=development npm run dev
  - Tests: npm test (use MONGODB_URI_TEST for integration tests)
- Root Git Watcher
  - npm install
  - npm run start (watches app/backend paths; suggests lint/test/commit actions)
- Flutter app
  - flutter pub get
  - flutter test and integration_test as applicable

Node versions:
- marketplace/backend engines: Node >= 18
- root package engines: Node >= 16 (prefer >= 18 to align across projects)

## 8. Other Notes
Guidance for LLM-generated code in this repo:
- Follow established naming patterns: *.controller.js, *.service.js, *.middleware.js, *.routes.js.
- Add new routes under src/routes and mount in server.js under /api/v1/<feature>.
- Always add Joi validators for new endpoints; route params via router.param where useful.
- Use structured-logger.service for any significant event, error, or security log.
- Maintain response shapes and error codes; add to error.middleware map when introducing new codes.
- Respect environment validation policies (no placeholders, JWT length, secure URIs in prod).
- For new services integrating external APIs, wrap calls with circuit breakers/retries where appropriate (opossum present) and sanitize/validate external inputs and outputs.
- For Flutter-facing endpoints, keep payloads small and predictable; support pagination and filters.
- Keep AI-related features behind dedicated services; avoid mixing UI/AI concerns and ensure inputs are validated against prompt injection/XSS patterns.

Special constraints and edge cases:
- Rate limiting and slow-down middlewares can affect parallel test runs; consider disabling or relaxing limits in test configs if necessary.
- server.js enforces .env presence and strict checks in non-development modes; ensure CI sets required env vars.
- DatabaseService performs actual write/read validation on connect; integration tests should point to an isolated test DB.
