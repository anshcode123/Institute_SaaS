# Student & Coaching Institute Management SaaS

Multi-tenant SaaS for coaching institutes to manage students, teachers, batches, attendance, fees, etc.
**This repo is currently Phase 1 only: project foundation + database architecture.** No auth, no business features yet.

## Tech Stack

**Frontend:** Flutter, Dart, Material 3, Riverpod, GoRouter, Dio
**Backend:** Node.js, Express.js, TypeScript
**Database:** PostgreSQL + Prisma ORM

## Folder Structure

```
student-saas/
├── frontend/               Flutter app (feature-based structure)
│   └── lib/
│       ├── core/            constants, theme, network, storage, errors, utils
│       ├── features/        empty — feature modules added from Phase 2 onward
│       ├── shared/widgets/  empty — shared widgets added as needed
│       └── main.dart
│
├── backend/
│   ├── src/
│   │   ├── config/          env, prisma client, cors
│   │   ├── controllers/     thin HTTP layer
│   │   ├── routes/          Express routers
│   │   ├── services/        business logic (only health-check logic exists so far)
│   │   ├── middleware/      error handler, async wrapper
│   │   ├── validators/      empty — request validation added later
│   │   ├── types/           shared TS types (API response shape)
│   │   ├── utils/           response helpers, AppError classes
│   │   └── app.ts / server.ts
│   └── prisma/
│       └── schema.prisma    Institute + User models
│
└── README.md
```

Request flow: `Route → Middleware → Controller → Service → Prisma → PostgreSQL`. No DB queries or business logic live in routes.

## 1. Install dependencies

**Backend**

```bash
cd backend
npm install
```

**Frontend**

```bash
cd frontend
flutter pub get
```

## 2. Configure environment

```bash
cd backend
cp .env.example .env
```

Edit `.env`:

```
NODE_ENV=development
PORT=4000
DATABASE_URL=postgresql://USER:PASSWORD@localhost:5432/student_saas?schema=public
```

Never commit `.env` — it's already in `.gitignore`.

## 3. Set up PostgreSQL

Create a local database (adjust to your Postgres setup):

```bash
createdb student_saas
```

Or with `psql`:

```sql
CREATE DATABASE student_saas;
```

## 4. Run Prisma migration

```bash
cd backend
npx prisma generate
npx prisma migrate dev --name init
```

This creates the `institutes` and `users` tables from `prisma/schema.prisma` and applies the first migration.

Optional — browse the DB visually:

```bash
npx prisma studio
```

## 5. Start the backend

```bash
cd backend
npm run dev
```

Server starts at `http://localhost:4000`.

## 6. Test the health endpoint

```bash
curl http://localhost:4000/api/health
```

Expected response:

```json
{
  "success": true,
  "message": "API is running",
  "data": {
    "api": "ok",
    "database": "connected",
    "timestamp": "2026-09-01T12:00:00.000Z"
  }
}
```

If `database` shows `"unavailable"`, check your `DATABASE_URL` and that Postgres is running.

## 7. Start the Flutter app

```bash
cd frontend
flutter run
```

You should see a single screen reading "Phase 1 foundation ready." — confirming Riverpod, GoRouter, and Material 3 theming are wired up correctly.

## Account Model — No Public Registration

There is no signup flow anywhere in this system, for any role:

- **Institute accounts** are created only by the Super Admin (the SaaS owner). Each institute gets a unique login identifier (`instituteCode`, e.g. `P10001`) and a password, both stored directly on the `Institute` row — the institute itself is the login, not a `User`.
- **Teachers, students, and parents** are created later by the institute, after it logs in with its `instituteCode` + password. They are not self-registered.
- **Super Admin** is the one role represented in `User` at this stage (`role = SUPER_ADMIN`, `instituteId = null`), created out-of-band (seed script / direct DB insert), never through an API.

```
Super Admin (creates)
    └── Institute (instituteCode + password)
            └── (later, institute creates) Students / Parents / Teachers
```

## Database Design Notes

- `Institute` now carries its own login credentials: `instituteCode` (unique, e.g. `P10001`) and `passwordHash`. The UUID `id` remains the actual primary key / FK target — `instituteCode` is a human-facing unique identifier, not the primary key.
- `User.instituteId` is **nullable**: `SUPER_ADMIN` has no institute; `TEACHER` / `STUDENT` / `PARENT` are expected to have one once the institute creates them. Not enforced at the DB level (Postgres can't conditionally require a nullable FK) — enforced in the service layer in a later phase.
- `onDelete: Cascade` on the `User → Institute` relation means deleting an institute removes its users. Revisit if soft-deletes are preferred later.
- Indexes exist on `instituteId` and `role` on `User`, `name` on `Institute`, and a unique constraint on `instituteCode`, anticipating institute-code lookups at login time.

## What's NOT in this phase

Student management, parent management, teacher management, batch management, attendance, fees, payments, tests, results, notifications, reports, subscription billing, payment gateway, full dashboards, analytics. Those are later phases.

---

# Phase 2 — Authentication, Institute Accounts & Multi-Tenancy

## Backend language change

The backend is now **plain JavaScript** (CommonJS `require`/`module.exports`), not TypeScript. `tsconfig.json` and the TS toolchain are gone; `npm run dev` runs `nodemon src/server.js` directly, no build step.

## Files created (Phase 2)

**Backend**

- `src/constants/roles.js` - `ROLES` / `INSTITUTE_STATUS` constants
- `src/utils/password.js` - bcrypt hashing, temp-password generator
- `src/utils/jwt.js` - access/refresh token sign & verify, token hashing
- `src/utils/institute-code.js` - sequential `P10001`-style code generator
- `src/services/token.service.js` - issue/rotate/revoke refresh tokens
- `src/services/auth.service.js` - Super Admin login, Institute login
- `src/services/institute.service.js` - create/list/get/suspend institutes
- `src/controllers/auth.controller.js`, `src/controllers/institute.controller.js`
- `src/middleware/authenticate.js` - verifies access token, sets trusted `req.auth`, rejects suspended institutes per-request
- `src/middleware/authorize.js` - role-based route guard
- `src/middleware/validate.js` - zod request-body validation
- `src/middleware/rate-limit.js` - login brute-force limiter
- `src/validators/auth.validators.js`, `src/validators/institute.validators.js`
- `src/routes/auth.routes.js`, `src/routes/admin.routes.js`
- `prisma/seed.js` - creates the first Super Admin (no public registration exists, so this is the only way in)

**Frontend**

- `lib/features/auth/domain/` - `AuthUser`, `AuthSession`, `AuthRepository` contract
- `lib/features/auth/data/` - `AuthRepositoryImpl`, `AuthInterceptor` (Dio), storage keys
- `lib/features/auth/presentation/` - `AuthController` (Riverpod state machine), Institute Login screen, Super Admin Login screen, minimal protected Home screen, shared `LoginForm` widget
- `lib/core/router/app_router.dart` - GoRouter with an auth-based redirect guard

## Files modified (Phase 2)

- `backend/prisma/schema.prisma` - added `InstituteStatus` enum, `Institute.status`, restored `INSTITUTE_ADMIN` role, added `RefreshToken` model
- `backend/package.json` - JS scripts, new deps (`bcryptjs`, `jsonwebtoken`, `zod`, `express-rate-limit`, `helmet`), removed TS deps
- `backend/.env.example` - added JWT + seed-admin variables
- `backend/src/app.js` - added `helmet()`
- `backend/src/routes/index.js` - mounted `/auth` and `/admin`
- `frontend/lib/main.dart` - now uses `routerProvider` instead of the Phase 1 placeholder router

## Account model (recap)

```
Super Admin (seeded once, out-of-band)
    │
    │ POST /api/admin/institutes
    ▼
Institute (instituteCode, status)
    │
    └── User { role: INSTITUTE_ADMIN, instituteId }  ← holds the login password
```

- `Institute` stores `instituteCode` (e.g. `P10001`) and `status` (`ACTIVE`/`SUSPENDED`), but **no password** — it isn't itself a login.
- The institute's login credentials live on a `User` row (`role = INSTITUTE_ADMIN`, `instituteId` set), created automatically alongside the Institute.
- Institute login flow checks, in order: institute exists → institute is `ACTIVE` → an `INSTITUTE_ADMIN` user exists for it → password matches → institute is still `ACTIVE` (re-checked).

## Authentication architecture

- **Password hashing:** bcrypt (`bcryptjs`, 12 salt rounds). Password hashes are stripped before any response ever leaves the service layer.
- **Access token:** short-lived JWT (`15m` default), payload = `{ sub: userId, role, instituteId }`. This is the **only** source of role/tenant trust — nothing is read from the client for authorization.
- **Refresh token:** longer-lived JWT (`7d` default), but validity is also checked against a `RefreshToken` DB row (hashed, never stored plaintext). `/api/auth/refresh` **rotates**: the presented token is revoked and a new pair issued. Reusing an already-rotated/revoked token fails and forces re-login.
- **Suspension takes effect immediately:** `authenticate` middleware re-checks institute status from the DB on every request for `INSTITUTE_ADMIN` tokens (not just at login), so a suspension doesn't wait for the access token to expire.
- **Rate limiting:** both login endpoints are limited to 10 attempts / 15 minutes per IP.

## Super Admin → Institute creation flow

`POST /api/admin/institutes` (protected: `authenticate` → `authorize(SUPER_ADMIN)`):

1. Generates the next sequential `instituteCode` (`P10001`, `P10002`, ...).
2. Generates a random 12-character initial password.
3. In a single DB transaction: creates the `Institute` row, then creates the `INSTITUTE_ADMIN` `User` row with the bcrypt hash of that password.
4. Returns the institute plus `{ instituteCode, initialPassword }` **once** — the plaintext password is never stored and can't be retrieved again after this response.

## Multi-tenant security model

- Every protected request carries a signed access token; `authenticate` decodes it into `req.auth = { userId, role, instituteId }` and nothing downstream trusts any `instituteId` sent in the request body/query/params.
- Because the token itself carries `instituteId`, an Institute Admin for `P10001` cannot access `P10002`'s data by passing a different ID — the server always scopes by the token's `instituteId`, not a client-supplied one. (No tenant-scoped data endpoints exist yet in Phase 2 beyond auth/admin, but this is the pattern later modules — students, attendance, fees — must follow.)
- `authorize(...roles)` is reusable: `authorize(ROLES.SUPER_ADMIN)` on admin routes, and the same middleware will gate future institute-scoped routes with `authorize(ROLES.INSTITUTE_ADMIN)`.

## Flutter authentication flow

- `AuthController` (Riverpod `StateNotifier`) drives `AuthState`: `initial → loading → authenticated | unauthenticated | error`. On app start it tries `restoreSession()` from secure storage.
- `AuthInterceptor` (Dio) attaches `Authorization: Bearer <accessToken>` to every request except login/refresh, and on a `401` transparently calls `/auth/refresh`, retries the original request once, and — if refresh itself fails — clears storage and flips the app back to `unauthenticated`.
- `GoRouter`'s `redirect` (in `app_router.dart`) sends unauthenticated users to `/` (Institute Login) and authenticated users away from the login screens to `/home`, re-evaluating whenever `AuthState` changes.
- Institute Login screen (`/`) takes Institute ID + password only — no signup link. Super Admin login is a separate route (`/super-admin/login`), reachable via a text button, not the default screen.
- `/home` is intentionally minimal — it just proves the authenticated area is reachable and shows the signed-in user's name/role from the server.

## Database migration

```bash
cd backend
npx prisma generate
npx prisma migrate dev --name phase2_auth_institute_status
```

## Backend commands

```bash
cd backend
npm install
cp .env.example .env   # fill in DATABASE_URL, JWT secrets, SUPER_ADMIN_* vars
npx prisma migrate dev --name phase2_auth_institute_status
npm run seed            # creates the first Super Admin from SUPER_ADMIN_* env vars
npm run dev
```

## Flutter commands

```bash
cd frontend
flutter pub get
flutter run
```

## API endpoints (Phase 2)

```
POST  /api/auth/super-admin/login
POST  /api/auth/institute/login
POST  /api/auth/refresh
POST  /api/auth/logout

POST  /api/admin/institutes            (Super Admin only)
GET   /api/admin/institutes            (Super Admin only)
GET   /api/admin/institutes/:id        (Super Admin only)
PATCH /api/admin/institutes/:id/status (Super Admin only)
```

## Testing this phase

**Super Admin login**

```bash
curl -X POST http://localhost:4000/api/auth/super-admin/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"change_me_now"}'
```

Save the `accessToken` from the response.

**Create an institute**

```bash
curl -X POST http://localhost:4000/api/admin/institutes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <SUPER_ADMIN_ACCESS_TOKEN>" \
  -d '{"name":"ABC Coaching","email":"abc@example.com","adminName":"ABC Admin"}'
```

Note the returned `instituteCode` (e.g. `P10001`) and `initialPassword` — shown only this once.

**Institute login**

```bash
curl -X POST http://localhost:4000/api/auth/institute/login \
  -H "Content-Type: application/json" \
  -d '{"instituteCode":"P10001","password":"<initialPassword from above>"}'
```

**Suspend it and confirm login is rejected**

```bash
curl -X PATCH http://localhost:4000/api/admin/institutes/<institute id>/status \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <SUPER_ADMIN_ACCESS_TOKEN>" \
  -d '{"status":"SUSPENDED"}'

curl -X POST http://localhost:4000/api/auth/institute/login \
  -H "Content-Type: application/json" \
  -d '{"instituteCode":"P10001","password":"<initialPassword>"}'
# expect 403 "This institute account is suspended"
```

**Verify tenant isolation**

Create a second institute (`P10002`) the same way, log in as `P10001`'s admin, and confirm its access token's `instituteId` claim (decode the JWT) matches only `P10001` — that token can never carry `P10002`'s id, since the server derives it server-side at login, not from anything the client sends.

**Authorization checks**

- Call `POST /api/admin/institutes` with an Institute Admin's access token → expect `403`.
- Call it with no `Authorization` header → expect `401`.

---

# Phase 3 — Students, Parents, Teachers & Batches

## What was added to the database

New models, all with a required `instituteId`: `Student`, `Parent`, `Teacher`, `Batch`, `Course`, `Subject`, plus join tables `StudentParent` (student↔parent, many-to-many, relationship type per link), `TeacherBatch` (teacher↔batch, many-to-many), and `TeacherSubject` (teacher↔subject, many-to-many). `Institute` and `User` got back-relations added for these; nothing about existing Phase 1/2 fields changed.

Notable design choices:

- `StudentParent` is a join table, not a plain FK, so a student can have multiple guardians and each link carries its own `relationship` (FATHER/MOTHER/GUARDIAN/OTHER) — the same parent can be "guardian" to one child and "father" to another.
- `Student.batchId` is a direct nullable FK (a student is in at most one batch at a time, reassignable via `POST /students/:id/batch`).
- `Student.qrCode` is a nullable unique string added now but left unpopulated — Phase 4's QR attendance foundation, so that model doesn't need another migration later.
- `Teacher.userId` is a nullable unique FK to `User` — a teacher _can_ later get a login without a second auth system, but none do yet.
- A shared `RecordStatus` enum (`ACTIVE`/`INACTIVE`) is reused across Student/Parent/Teacher/Batch for soft-deactivation — nothing in this phase hard-deletes.

## Files created

**Backend**

- `src/utils/tenant.js` — `findOwnedOrThrow(model, id, instituteId, message)`: the single tenant-scoping helper every Phase 3 lookup uses. A cross-tenant id returns 404, not 403, so a lookup never even confirms a record's existence to another tenant.
- `src/validators/{student,parent,teacher,batch}.validators.js`
- `src/services/{student,parent,teacher,batch}.service.js`
- `src/controllers/{student,parent,teacher,batch}.controller.js`
- `src/routes/{student,parent,teacher,batch}.routes.js`
- `src/middleware/validate.js` gained `validateQuery` (list endpoints validate search/filter/paging query strings the same way bodies are validated)

**Frontend** — for each of `students`, `parents`, `teachers`, `batches`: `domain/` (models + repository contract), `data/` (Dio-backed repository impl), `presentation/providers/` (list state + Riverpod `StateNotifier` controller + a `FutureProvider.family` detail fetch), `presentation/screens/` (List, Detail/Profile, Add/Edit form). Students additionally get `link_parent_screen.dart`. Batches additionally get student/teacher picker dialogs in `batch_detail_screen.dart`. Shared list/detail widgets: `lib/shared/widgets/{status_badge,empty_state,error_state,confirm_dialog}.dart`, `lib/core/network/paginated_result.dart`.

## Files modified

- `backend/prisma/schema.prisma` — Phase 3 models appended, `Institute`/`User` back-relations added.
- `backend/src/constants/roles.js` — added `RECORD_STATUS`, `GENDER`, `PARENT_RELATIONSHIP`.
- `backend/src/routes/index.js` — mounted `/students`, `/parents`, `/teachers`, `/batches`, all behind `authenticate` + `authorize(INSTITUTE_ADMIN)`.
- `backend/src/middleware/authenticate.js` — unchanged behavior, just now also gates the new resource routes.
- `frontend/lib/core/router/app_router.dart` — added all Phase 3 routes.
- `frontend/lib/features/auth/presentation/screens/home_screen.dart` — now links to Students/Parents/Teachers/Batches instead of being a bare placeholder.
- `frontend/pubspec.yaml` — added `intl` (date formatting on profile screens).

## Tenant isolation, concretely

Every service function takes `instituteId` from `req.auth` — set by the `authenticate` middleware from the verified JWT, never from the request body/query/params. Every single-record lookup is `findOwnedOrThrow(prisma.model, id, instituteId, ...)`, i.e. `where: { id, instituteId }` in one query — a cross-tenant id simply matches nothing and 404s. Relationship writes check **both** sides: linking a parent to a student checks the parent belongs to the caller's institute _and_ the student does; assigning a batch to a teacher checks the batch belongs to the same institute; bulk operations (assign multiple teachers/students/subjects) verify the _entire_ id set belongs to the institute — a set where only some ids match is rejected rather than proceeding with what matched.

## API endpoints

```
GET    /api/students
POST   /api/students
GET    /api/students/:id
PATCH  /api/students/:id
DELETE /api/students/:id          (soft-deactivate)
POST   /api/students/:studentId/parent
DELETE /api/students/:studentId/parent/:parentId
POST   /api/students/:studentId/batch

GET    /api/parents
POST   /api/parents
GET    /api/parents/:id
PATCH  /api/parents/:id
DELETE /api/parents/:id           (soft-deactivate)

GET    /api/teachers
POST   /api/teachers
GET    /api/teachers/:id
PATCH  /api/teachers/:id
DELETE /api/teachers/:id          (soft-deactivate)
POST   /api/teachers/:id/batches
POST   /api/teachers/:id/subjects

GET    /api/batches
POST   /api/batches
GET    /api/batches/:id
PATCH  /api/batches/:id
DELETE /api/batches/:id           (soft-deactivate)
POST   /api/batches/:id/students
DELETE /api/batches/:id/students
POST   /api/batches/:id/teachers
```

All of the above require `Authorization: Bearer <access token>` for an `INSTITUTE_ADMIN`. `GET` list endpoints accept `?q=`, `?status=`, `?page=` query params (students also accept `?batchId=`).

## Flutter screens

```
Students List → Student Profile → Add/Edit Student
                       │
                       └── Link Parent

Parents List → Parent Details → Add/Edit Parent
Teachers List → Teacher Details → Add/Edit Teacher
Batches List → Batch Details (assign teachers, add/remove students) → Create/Edit Batch
```

Every list screen has search, a status filter, an add button, loading/empty/error states, and pull-to-refresh. Every deactivate action goes through a confirmation dialog. The Student Profile screen includes reserved, disabled placeholder cards for Attendance/Fees/Tests/Results so the layout won't need reshaping when those phases land.

## Backend commands

```bash
cd backend
npm install
npx prisma generate
npx prisma migrate dev --name phase3_students_parents_teachers_batches
npm run dev
```

## Flutter commands

```bash
cd frontend
flutter pub get
flutter run
```

## Walkthrough

All examples assume you're logged in as an Institute Admin and have `<ACCESS_TOKEN>` from `POST /api/auth/institute/login`.

**Create a student**

```bash
curl -X POST http://localhost:4000/api/students \
  -H "Authorization: Bearer <ACCESS_TOKEN>" -H "Content-Type: application/json" \
  -d '{"studentCode":"S001","firstName":"Rahul","lastName":"Sharma"}'
```

**Create a parent**

```bash
curl -X POST http://localhost:4000/api/parents \
  -H "Authorization: Bearer <ACCESS_TOKEN>" -H "Content-Type: application/json" \
  -d '{"name":"Sunita Sharma","phone":"9876500000"}'
```

**Link the parent to the student**

```bash
curl -X POST http://localhost:4000/api/students/<studentId>/parent \
  -H "Authorization: Bearer <ACCESS_TOKEN>" -H "Content-Type: application/json" \
  -d '{"parentId":"<parentId>","relationship":"MOTHER"}'
```

**Create a teacher**

```bash
curl -X POST http://localhost:4000/api/teachers \
  -H "Authorization: Bearer <ACCESS_TOKEN>" -H "Content-Type: application/json" \
  -d '{"name":"Priya Verma"}'
```

**Create a batch**

```bash
curl -X POST http://localhost:4000/api/batches \
  -H "Authorization: Bearer <ACCESS_TOKEN>" -H "Content-Type: application/json" \
  -d '{"name":"Batch A - Morning"}'
```

**Assign the student to the batch, and the teacher to the batch**

```bash
curl -X POST http://localhost:4000/api/students/<studentId>/batch \
  -H "Authorization: Bearer <ACCESS_TOKEN>" -H "Content-Type: application/json" \
  -d '{"batchId":"<batchId>"}'

curl -X POST http://localhost:4000/api/batches/<batchId>/teachers \
  -H "Authorization: Bearer <ACCESS_TOKEN>" -H "Content-Type: application/json" \
  -d '{"teacherIds":["<teacherId>"]}'
```

**Verify tenant isolation**

Log in as two different institutes (`P10001` and `P10002` — see Phase 2 for creating them), create a student under `P10001`, then try to fetch/edit/deactivate it using `P10002`'s access token:

```bash
curl http://localhost:4000/api/students/<P10001's student id> \
  -H "Authorization: Bearer <P10002_ACCESS_TOKEN>"
# expect 404 "Student not found" - not 403, so P10002 never learns the id exists
```

Repeat for parents, teachers, batches, and for cross-tenant relationship writes (e.g. try linking a `P10002` parent to a `P10001` student, or assigning a `P10002` teacher to a `P10001` batch — both should 404 on the mismatched side).

---

# Phase 4 — Attendance + Secure QR Code Attendance

## What was added to the database

- **`Attendance`** model: `instituteId`, `studentId`, `batchId`, `date` (date-only, not a timestamp), `status` (`AttendanceStatus` enum: `PRESENT`/`ABSENT`/`LATE`/`EXCUSED`), `markedById` (who actually recorded it), `markedAt`. A `@@unique([studentId, batchId, date])` constraint is the database-level guarantee against duplicate attendance for the same student/batch/day — the same constraint that makes duplicate QR scans safe to handle without a race condition.
- **`Student.qrCode`** — added as an unpopulated stub back in Phase 3, now actually populated: every student gets a cryptographically random, opaque token (`crypto.randomBytes(24)`, base64url) generated server-side at creation. It encodes nothing about the student — see `backend/src/utils/qr-token.js`.
- Back-relations added to `Institute`, `Student`, `Batch`, `User` for `Attendance` / `markedAttendanceRecords`. Nothing about existing Phase 1–3 fields changed.

## Teacher authentication (new — reuses existing auth, not a second system)

Phases 1–3 never built teacher login ("don't implement unless required"). Phase 4's flow requires it, so:

- **`POST /api/auth/teacher/login`** (email + password) — issues tokens through the exact same `issueTokenPair`/refresh/`authenticate` pipeline as Super Admin and Institute login. Same JWT shape (`sub`, `role`, `instituteId`), same refresh-token rotation, same suspension re-check.
- **`POST /api/teachers/:id/create-login`** (Institute Admin only) — provisions the linked `User` row for an existing teacher (must already have an email on file), generates a temp password, returns it once, stores only the hash. Mirrors exactly how institute-admin accounts get created in Phase 2.
- `authenticate.js` was generalized: the live institute-suspension check now applies to **any** role with a non-null `instituteId` (previously `INSTITUTE_ADMIN`-only), so a suspended institute immediately blocks its teachers too, not just its admin.

## Batches: Teachers now get read access to their own

Phase 3 made `/batches` Institute-Admin-only. Phase 4's flow needs a teacher to select their own batch for attendance, so:

- `GET /batches` and `GET /batches/:id` are now reachable by `INSTITUTE_ADMIN` **and** `TEACHER` — but the service layer filters results: a Teacher only ever sees batches they're actually assigned to (via `TeacherBatch`), verified server-side, never from a client-supplied filter.
- Every mutation (`POST`/`PATCH`/`DELETE`, assign teachers/students) still requires `INSTITUTE_ADMIN` specifically, enforced with an additional `authorize()` call on those individual routes.
- This reuses the existing `BatchesListScreen`/`BatchDetailScreen` in Flutter as-is — no separate "teacher dashboard" screen was built. The Home screen hides the Students/Parents/Teachers nav cards for a Teacher login (those stay Institute-Admin-only) and labels the Batches card "My Batches".

## Tenant + assignment security model

New shared helper `backend/src/utils/teacher-access.js`:

- `assertCanAccessBatch(instituteId, auth, batchId)` — Institute Admin always passes; a Teacher must have a linked `Teacher` profile **and** an actual `TeacherBatch` link to that specific batch, or it throws `ForbiddenError`. Every other role (including `STUDENT`/`PARENT`, which have no login at all yet) is rejected outright.
- This one function is reused by QR scan, manual marking, attendance history (when scoped to a batch), and the batch summary endpoint — one gate, not four separate copies of the same check.
- QR scan additionally checks `student.instituteId === instituteId` and `student.batchId === batchId` before ever creating a record — a QR token from another institute, or a valid token for a student not enrolled in the scanned batch, both fail with a generic message rather than confirming anything about the record's existence elsewhere.

## Duplicate / invalid / wrong-batch handling

- **Duplicate scan**: idempotent, not an error. `POST /attendance/scan` returns `200` with `{ alreadyMarked: true, attendance: <existing record> }` and the message "Attendance already marked" — no second row is created, and a race between two near-simultaneous scans is caught by the same unique constraint and handled the same way (P2002 → re-fetch → return as already-marked) rather than surfacing a 500.
- **Invalid QR**: `400` "Invalid student QR code" — used both when the token doesn't exist at all and when it belongs to another institute, so a bad-faith scan never learns which case it hit.
- **Wrong batch**: `400` "Student is not enrolled in this batch" if the student's QR is valid but they're not assigned to the batch being scanned.
- **Suspended institute**: blocked at the `authenticate` layer before any attendance logic runs, for both Institute Admin and Teacher tokens.

## Files created

**Backend**

- `src/utils/qr-token.js`, `src/utils/teacher-access.js`
- `src/validators/attendance.validators.js`
- `src/services/attendance.service.js`
- `src/controllers/attendance.controller.js`
- `src/routes/attendance.routes.js`

**Frontend**

- `lib/features/attendance/` — full `domain/`, `data/`, `presentation/{providers,screens}` — QR scanner (`mobile_scanner`), Batch Attendance screen (scan + live present/remaining counts), Manual Attendance screen (date + per-student status), Attendance History screen (batch/student/status/date filters, paginated).
- `lib/features/students/presentation/screens/student_qr_screen.dart` — enlarged QR display (`qr_flutter`).
- `lib/features/auth/presentation/screens/teacher_login_screen.dart`.

## Files modified

- `backend/prisma/schema.prisma` — `Attendance` model, `AttendanceStatus` enum, back-relations, `Student.qrCode` doc comment updated.
- `backend/src/middleware/authenticate.js` — suspension check generalized beyond `INSTITUTE_ADMIN`.
- `backend/src/services/{auth,teacher,student,batch}.service.js` — teacher login, `createTeacherLogin`, QR generation on student creation, teacher-scoped batch filtering.
- `backend/src/controllers/{auth,teacher,batch}.controller.js`, `backend/src/routes/{auth,teacher,batch,index}.routes.js` — new endpoints/roles wired through.
- `frontend/lib/features/students/domain/student_models.dart` — added `qrCode`.
- `frontend/lib/features/students/presentation/screens/student_profile_screen.dart` — real QR button + live attendance summary card (replacing the Phase 3 placeholder).
- `frontend/lib/features/teachers/domain/teacher_models.dart`, `.../data/teacher_repository_impl.dart`, `.../presentation/screens/teacher_detail_screen.dart` — `hasLogin` + Create Login action.
- `frontend/lib/features/batches/presentation/screens/batch_detail_screen.dart` — "Take Attendance" entry point.
- `frontend/lib/features/auth/presentation/{providers/auth_providers.dart, data/auth_repository_impl.dart, domain/auth_repository.dart, presentation/screens/institute_login_screen.dart, presentation/screens/home_screen.dart}` — teacher login wiring, role-based nav.
- `frontend/lib/core/router/app_router.dart` — attendance + teacher-login routes.
- `frontend/pubspec.yaml` — added `qr_flutter`, `mobile_scanner`.

## API endpoints

```
POST /api/auth/teacher/login
POST /api/teachers/:id/login                    (INSTITUTE_ADMIN only - creates the login)

POST /api/attendance/scan                        {qrToken, batchId}
POST /api/attendance/manual                       {batchId, date?, entries:[{studentId,status}]}
GET  /api/attendance                              ?batchId&studentId&status&date&page
GET  /api/attendance/students/:studentId/summary
GET  /api/attendance/batches/:batchId/summary     ?date
```

All require `Authorization: Bearer <access token>` for `INSTITUTE_ADMIN` or `TEACHER`; a Teacher token is further restricted to their assigned batches at the service layer.

## Manual step required (not something this project can generate)

`mobile_scanner` needs camera permission declared in the platform projects. This repo currently ships `lib/` and `pubspec.yaml` only — no `android/`/`ios/` folders (those come from running `flutter create .` once, which needs the Flutter SDK). After you generate them, add:

- **Android** (`android/app/src/main/AndroidManifest.xml`): `<uses-permission android:name="android.permission.CAMERA"/>`
- **iOS** (`ios/Runner/Info.plist`): `NSCameraUsageDescription` with a usage string.

## Backend commands

```bash
cd backend
npm install
npx prisma generate
npx prisma migrate dev --name phase4_attendance_qr
npm run dev
```

## Flutter commands

```bash
cd frontend
flutter pub get
flutter run
```

## Full walkthrough

1. Super Admin creates institute `P10001` (Phase 2), Institute Admin logs in.
2. Institute Admin creates a student — a `qrCode` is generated automatically, visible on the student's profile under "Student QR Code".
3. Institute Admin creates a teacher, assigns them to a batch, then taps **Create Login** on the teacher's detail screen — note the generated password (shown once).
4. Assign the student to the same batch.
5. Teacher logs in via **Teacher login** on the Institute Login screen.
6. Teacher opens **My Batches** → the assigned batch → **Take Attendance**.
7. Teacher taps **Scan Student QR**, scans the student's QR code (shown on the admin's device, or printed).
8. Backend validates institute + batch + enrollment, marks `PRESENT`, returns success — UI shows the confirmation dialog only after the backend confirms.
9. Scanning the same student again the same day returns "Attendance already marked" — no duplicate row.
10. Attendance appears in **Attendance History**, filterable by batch/date/status; the student's profile "Attendance" card updates with the new percentage.

**Verify tenant + assignment isolation:**

```bash
# A teacher from another institute (P10002) cannot use P10001's student QR:
curl -X POST http://localhost:4000/api/attendance/scan \
  -H "Authorization: Bearer <P10002_TEACHER_TOKEN>" -H "Content-Type: application/json" \
  -d '{"qrToken":"<P10001 student token>","batchId":"<any P10002 batch id>"}'
# expect 400 "Invalid student QR code"

# A teacher not assigned to a batch cannot mark attendance for it, even
# within their own institute:
curl -X POST http://localhost:4000/api/attendance/scan \
  -H "Authorization: Bearer <TEACHER_TOKEN_NOT_ON_THIS_BATCH>" -H "Content-Type: application/json" \
  -d '{"qrToken":"<valid token>","batchId":"<batch they are not assigned to>"}'
# expect 403 "You are not assigned to this batch"
```

## What's NOT in this phase

Fees, payments, tests, results, notifications, SaaS billing. Those are later phases. Also not built: a dedicated "Student portal" or "Parent portal" login (Students/Parents still have no authentication at all — the summary/history screens here are viewed through the Institute Admin/Teacher app, matching the scope of every prior phase).

---

# Phase 5 — Fees, Payments & Receipts

## Correction to the Phase 5 brief

The Phase 5 prompt's "Completed Phases" summary describes Phase 4 as including a Student/Teacher/Parent **portal**. Only Teacher login was actually built (see the Phase 4 section above, which flagged this at the time). So in this phase, "Student fee view" and "Parent fee view" are **not** separate self-service logins — there still isn't one, for the same reason there wasn't one in Phase 4: building one now would mean inventing a new authentication system, which the brief itself says not to do. Instead, both views are the existing Institute Admin app reading a student's fees (`GET /fees/student/:studentId`, surfaced on the Student Profile screen) — the same pattern Phase 4 used for the attendance summary.

## Database

New models (none of Phases 1–4's models were altered beyond adding back-relations):

- **`FeeStructure`** + **`FeeStructureInstallment`** — the reusable template (e.g. "NEET 2026, ₹60,000, 3 installments"). Optionally scoped to a `Batch`.
- **`StudentFee`** + **`FeeInstallment`** — created by _snapshotting_ a `FeeStructure`'s numbers onto a specific student at assignment time. Editing a `FeeStructure` afterward (name/description/status only — see below) never retroactively changes an already-assigned student's fee.
- **`Payment`** — one row per payment, tied to exactly one `FeeInstallment`.
- **`PaymentReceipt`** — one per payment, unique `receiptNumber`, with `previousOutstanding`/`remainingOutstanding` **snapshotted at issue time** so a receipt reads correctly forever even after later payments change the running balance.
- **`PaymentRefund`** — modeled now, no endpoint yet (out of Phase 5 scope per the spec) — exists so a refund never needs to be a delete of the original payment when that phase arrives.

**Money**: every amount is Prisma `Decimal` (Postgres `NUMERIC(12,2)`), never a JS float. All arithmetic goes through `backend/src/utils/money.js`.

**Fee structures are not fully editable after creation**: `PATCH /fees/structures/:id` only accepts `name`/`description`/`status`. `totalAmount` and the installment schedule are locked once created, specifically so already-assigned students' snapshotted numbers never silently drift from a "current" template.

## Discount handling

`POST /fees/student` accepts _either_ `discountAmount` (fixed) _or_ `discountPercentage` (0–100), never both. The backend:

1. Computes `discountAmount` server-side (percentage → amount conversion happens here, not in Flutter).
2. Rejects a discount greater than the total (never a negative final amount).
3. Distributes the discount **proportionally** across the fee structure's installment templates — not just off the first one — so a student's remaining installments each reflect a fair share. The last installment absorbs any rounding remainder so the parts always sum _exactly_ to `finalAmount` (verified: a ₹5,000 discount split across three ₹20,000 installments produces 18333.33 / 18333.33 / 18333.34 — summing to exactly ₹55,000, no paisa lost).

Flutter's Assign Fee screen shows a live "Final Payable Amount" preview purely for the admin's convenience — the number that actually gets persisted is always recalculated server-side from scratch.

## Payment: atomic transaction

`POST /payments` runs entirely inside one `prisma.$transaction`: create payment → update installment (`paidAmount`, status) → update student fee (`paidAmount`, `outstandingAmount`, status) → generate receipt. If any step fails, nothing is written. Before the transaction starts, the backend independently verifies: student belongs to the institute, the student fee belongs to that student, the installment belongs to that student fee, the fee isn't `CANCELLED`, and the payment amount doesn't exceed the installment's remaining balance (rejected at the exact boundary — the remaining amount itself is accepted, one cent over is not).

## Status derivation (OVERDUE is never stored)

`FeeInstallment.status` and `StudentFee.status` only ever get `PENDING`/`PARTIALLY_PAID`/`PAID`/`CANCELLED` written to them directly, at payment time. **`OVERDUE` is computed at read time** (`backend/src/utils/fee-status.js`) by comparing `dueDate` to today for anything still unpaid — so it's always correct without a background job, and a fully-paid installment reported after its due date correctly still shows `PAID`, never `OVERDUE`.

## Receipt numbers

Sequential per institute per calendar year: `REC-2026-000001`, `REC-2026-000002`, ... A different institute (or the next calendar year) starts its own sequence at `000001`. Generated inside the same transaction as the payment, so there's no window for a duplicate.

## Authorization

Every `/fees`, `/payments`, `/receipts` route requires `INSTITUTE_ADMIN` specifically — `TEACHER` gets zero access, matching the spec's "no financial modification by default." (No student/parent login exists to authorize either way, per the correction above.)

## Files created

**Backend**

- `src/utils/money.js`, `src/utils/fee-status.js`, `src/utils/receipt-number.js`
- `src/validators/{fee-structure,student-fee,payment}.validators.js`
- `src/services/{fee-structure,student-fee,payment,fee-dashboard}.service.js`
- `src/controllers/{fee-structure,student-fee,payment}.controller.js`
- `src/routes/{fee,payment}.routes.js`

**Frontend**

- `lib/features/fees/` — full `domain/`, `data/` (including `receipt_pdf_generator.dart`), `presentation/{providers,screens,widgets}`: Fee Dashboard, Fee Structures list + create form, Fee Structure detail (activate/deactivate), Assign Fee (student search + discount toggle + live preview), All Student Fees list, Student Fee detail (installments + Pay buttons), Record Payment form, Payment History, Receipt view (with print/share via `pdf`+`printing`).
- `lib/shared/widgets/currency_text.dart` — INR formatting helper.

## Files modified

- `backend/prisma/schema.prisma` — Phase 5 models + back-relations on `Institute`/`Student`/`Batch`/`User`.
- `backend/src/constants/roles.js` — added `FEE_STRUCTURE_STATUS`, `FEE_STATUS`, `DISCOUNT_TYPE`, `PAYMENT_METHOD`, `PAYMENT_STATUS`.
- `backend/src/routes/index.js` — mounted `/fees`, `/payments`, `/receipts`, Institute-Admin-only.
- `frontend/lib/features/students/presentation/screens/student_profile_screen.dart` — replaced the Phase 3/4 "Fees" placeholder with a real fee summary + "Assign fee" link.
- `frontend/lib/features/auth/presentation/screens/home_screen.dart` — added a "Fees" nav card (hidden for Teacher logins, same reasoning as Students/Parents/Teachers).
- `frontend/lib/core/router/app_router.dart` — all fee/payment/receipt routes.
- `frontend/pubspec.yaml` — added `pdf`, `printing`.

## API endpoints

```
POST  /api/fees/structures
GET   /api/fees/structures
GET   /api/fees/structures/:id
PATCH /api/fees/structures/:id           (name/description/status only)

POST  /api/fees/student                  {studentId, feeStructureId, discountAmount? | discountPercentage?}
GET   /api/fees/student/:studentId       (aggregate view across all that student's fees)
GET   /api/fees/dashboard
GET   /api/fees                          ?studentId&status&page
GET   /api/fees/:id

POST  /api/payments                      {studentId, studentFeeId, installmentId, amount, paymentMethod, ...}
GET   /api/payments                      ?studentId&studentFeeId&page
GET   /api/payments/:id

GET   /api/receipts/:id
```

## Backend commands

```bash
cd backend
npm install
npx prisma generate
npx prisma migrate dev --name phase5_fees_payments_receipts
npm run dev
```

## Flutter commands

```bash
cd frontend
flutter pub get
flutter run
```

## Full walkthrough

1. Institute Admin logs in, goes to **Fees → Fee Structures → +**, creates "NEET 2026" (₹60,000, 3×₹20,000 installments).
2. **Fees → Assign Fee**, searches for a student, selects the fee structure, optionally applies a discount, submits — lands on the Student Fee detail screen showing the (server-calculated) final amount and installment schedule.
3. On the student's fee detail, taps **Pay** on installment 1 — amount is pre-filled to the remaining balance, picks a payment method, submits.
4. Backend runs the atomic transaction; app navigates straight to the generated **Receipt**, showing a unique `REC-2026-000001`-style number, previous/remaining outstanding, and Print/Share actions.
5. Back on the Student Profile, the "Fees" card now shows updated paid/outstanding totals; **Fees → All Student Fees** and **Fees dashboard** totals reflect the payment too.
6. Scanning the same installment again for more than its remaining balance is rejected before anything is written.
7. **Tenant isolation**: repeat with a second institute's Institute Admin token against the first institute's `studentFeeId`/`paymentId` — expect `404`, not `403`, on every endpoint (same pattern as every prior phase's `findOwnedOrThrow`).

## What's NOT in this phase

Online payment gateway integration (a clean abstraction point exists — `PaymentStatus`/`PaymentMethod` — but no fake gateway was built, per the spec's explicit instruction not to fake one). Refund endpoints (model exists, no API yet). Tests, marks, results, notifications, announcements, advanced reports, production hardening — all later phases.

---

# Phase 6 — Tests, Marks & Results

## Correction to the Phase 6 brief

The prompt's regression checklist asks to preserve "Theme toggle", "Grid/List toggle", and separate "SUPER_ADMIN dashboard / INSTITUTE_ADMIN dashboard / TEACHER dashboard" screens. **None of these were ever built.** There's a single `AppTheme` (light/dark, no in-app toggle switch), no grid/list view toggle anywhere, and one shared `HomeScreen` with role-conditional nav cards (not three separate dashboard screens) — this has been the pattern since Phase 2 and is documented in every prior phase's section of this README. Phase 6 extends that existing single-Home-screen pattern (adding a "Tests"/"My Tests" nav card) rather than inventing the features the prompt assumes exist.

## Database

New models, all tenant-scoped:

- **`Test`** — one per test/exam. `totalMarks` is denormalized (kept in sync via transaction whenever subjects are added/edited/removed) so it never has to be recomputed from `TestSubject` rows on every read.
- **`TestSubject`** — per-subject max/passing marks for a test. `@@unique([testId, subjectId])` rejects duplicate subjects on the same test at the database level, not just in a validator.
- **`StudentSubjectMark`** — the raw entry a teacher edits, one row per (test, student, subject). `maxMarks` is snapshotted from `TestSubject` at entry time (same snapshot pattern as Phase 5's `StudentFee`), so a later max-marks edit never silently reinterprets an already-entered score.
- **`StudentTestResult`** — a **computed rollup**, not something created upfront. It's upserted automatically the moment a student has a mark recorded for every subject on the test, and refreshed on every subsequent mark save. This is a deliberate deviation from the spec's suggested shape (which nested `StudentSubjectMark` under a pre-existing `StudentTestResult`) — nesting that way creates a chicken-and-egg problem, since marks are entered subject-by-subject _before_ any result exists. `publishedAt` is only stamped when the whole `Test` is published.

Marks are plain `Int` (whole-number scores, matching the spec's own 82/76/91 examples) — this explicitly isn't a financial module and doesn't touch Phase 5's `Decimal` money fields. `percentage` is `Decimal(5,2)` since grade-boundary comparisons (89.99 vs 90) need exact decimal comparison; it reuses the same generic Decimal helpers from `utils/money.js` that Phase 5 uses — a shared arithmetic utility, not Phase-5-specific logic.

## Grading (centralized, single source of truth)

`backend/src/utils/grade.js` — one function, `calculateGrade(percentage)`, used everywhere a grade is computed. No controller or service computes a grade inline. Boundaries exactly as specified (90→A+, 80→A, 70→B+, 60→B, 50→C, 40→D, below→F), verified at every threshold including the 89.99-vs-90.00 edge with real Decimal comparison, not float.

**Pass/fail rule (fixed policy, not yet configurable)**: a student passes only if the overall passing-marks requirement is met **and** every individual subject's passing-marks requirement is met — the spec's stated preference. This is hard-coded in `computeResult()`, flagged here as a decision an institute might eventually want to override (e.g. "pass if you clear the overall bar regardless of one weak subject").

## Publishing

`POST /tests/:id/publish` validates that **every currently-enrolled active student** has a computed `StudentTestResult` (i.e., complete marks in every subject) before allowing publication — it will not publish a partial result set. On success, it stamps `publishedAt` on every result and flips `Test.status` to `PUBLISHED`, in one transaction. While published, `POST /tests/:id/marks` and all subject-configuration endpoints reject changes; `POST /tests/:id/unpublish` (Institute Admin only) clears `publishedAt` and reverts `Test.status` to `COMPLETED`, reopening marks for editing.

## Authorization

Every `/tests/*` route requires `INSTITUTE_ADMIN` or `TEACHER`. Mutating/admin-only actions (create/edit/cancel test, subject configuration, publish/unpublish) additionally require `INSTITUTE_ADMIN` specifically — a `TEACHER` calling those gets `403` regardless of batch assignment. For everything else (view tests, enter marks, view results), a `TEACHER` is restricted to batches they're actually assigned to via the same `assertCanAccessBatch` helper Phase 4 built for attendance — reused as-is, not reimplemented. `GET /students/:studentId/results` and `.../results/:resultId` are mounted at `/students` but registered _before_ the general Institute-Admin-only `/students` gate, with their own `[INSTITUTE_ADMIN, TEACHER]` authorize — a Teacher can see their own students' results without getting full student-management access, and any `/students` request that doesn't match a results route falls through to the stricter gate unaffected.

## Files created

**Backend**

- `src/utils/grade.js`
- `src/validators/{test,marks}.validators.js`
- `src/services/{test,marks,result}.service.js`
- `src/controllers/{test,marks,result}.controller.js`
- `src/routes/{test,student-results}.routes.js`

**Frontend**

- `lib/features/tests/` — full `domain/`, `data/`, `presentation/{providers,screens,widgets}`: Tests list (doubles as Institute Admin's "Tests Dashboard" and Teacher's "My Tests", same screen, server-filtered), Create Test (dynamic subject rows, live total-marks calculation), Test Detail (subject config, publish/unpublish, links into marks entry), Marks Entry (subject → student roster → enter/edit → save, prefilled with existing marks), Test Results (ranked table + class analytics), Student Result Detail (the spec's exact mockup: subject-wise marks, total, percentage, grade, pass/fail).

## Files modified

- `backend/prisma/schema.prisma` — Phase 6 models + back-relations on `Institute`, `Batch`, `Subject`, `Student`, `User`. No Phase 1–5 model was altered beyond adding a relation field.
- `backend/src/constants/roles.js` — added `TEST_STATUS`, `RESULT_STATUS`.
- `backend/src/routes/index.js` — mounted `/tests` (`[INSTITUTE_ADMIN, TEACHER]`) and the student-results sub-router at `/students` ahead of the existing Institute-Admin-only gate.
- `frontend/lib/features/students/presentation/screens/student_profile_screen.dart` — replaced the Phase 3/4/5 "Tests"/"Results" placeholders with a real test-history card.
- `frontend/lib/features/auth/presentation/screens/home_screen.dart` — added a "Tests"/"My Tests" nav card, visible to both roles (unlike Fees, which stays Institute-Admin-only).
- `frontend/lib/core/router/app_router.dart` — all test/marks/result routes.

## API endpoints

```
POST   /api/tests                          (INSTITUTE_ADMIN)
GET    /api/tests                          (both, teacher-filtered)
GET    /api/tests/:id                      (both, assignment-checked)
PATCH  /api/tests/:id                      (INSTITUTE_ADMIN)
DELETE /api/tests/:id                      (INSTITUTE_ADMIN — soft cancel, not a hard delete)

POST   /api/tests/:id/subjects             (INSTITUTE_ADMIN)
PATCH  /api/tests/:id/subjects/:subjectId  (INSTITUTE_ADMIN)
DELETE /api/tests/:id/subjects/:subjectId  (INSTITUTE_ADMIN)

POST   /api/tests/:id/marks                (both, assignment-checked)
GET    /api/tests/:id/marks                (both, assignment-checked)
GET    /api/tests/:id/results              (both, assignment-checked; includes rank + class summary)
POST   /api/tests/:id/publish              (INSTITUTE_ADMIN)
POST   /api/tests/:id/unpublish            (INSTITUTE_ADMIN)

GET    /api/students/:studentId/results
GET    /api/students/:studentId/results/:resultId
```

## Backend commands

```bash
cd backend
npm install
npx prisma generate
npx prisma migrate dev --name phase6_tests_marks_results
npm run dev
```

## Flutter commands

```bash
cd frontend
flutter pub get
flutter run
```

## Verification performed in this sandbox

Same limitation as every prior phase: `prisma generate` can't complete here (blocked engine binary), so nothing was tested against a live database. What _was_ verified:

- Full syntax check across every backend file, and a full app load (all routes → controllers → services) against a mocked Prisma client.
- Real Decimal-arithmetic tests (temporarily installed genuine `decimal.js`, removed afterward) confirming every grade boundary lands correctly, including the exact 89.99-vs-90.00 edge.
- The spec's own worked example (249/300 → 83% → grade A → PASS) reproduced exactly by `computeResult()`.
- The "fails if even one subject fails, regardless of a passing overall percentage" rule, and its opposite (passes only when both bars clear), each tested explicitly.
- Standard competition ranking with ties (1, 1, 3, 4) and class analytics (average/highest/lowest/pass count) arithmetic.
- Service-layer rejections tested against the real `marks.service.js` with a mocked Prisma client: marks exceeding a subject's max marks are rejected before any write, and a published test rejects further mark edits until unpublished.
- Frontend: brace-balanced and every relative import resolved across the whole `lib/` tree; every navigation call in the new screens manually traced against the declared router paths.

**Not verified**: live database behavior, and the Flutter UI hasn't been run on a device/emulator (no Flutter SDK in this sandbox). The Create Test screen's subject picker is a raw text field for the subject's ID rather than a search-and-select dialog (unlike the picker pattern used in `batch_detail_screen.dart`) — a known UX shortcut given time constraints, not a security or correctness issue since the backend validates the ID regardless.

## What's NOT in this phase

Student/Parent login (planned for Phase 7 — the result/mark services are structured so a future student/parent-facing wrapper can filter `publishedAt != null` before exposing anything). Notifications (a `RESULT_PUBLISHED` event point is implicit in `result.service.js`'s `publishTest`, but no notification system was built — Phase 7 per the spec). Configurable pass/fail rules or grade bands (fixed policy for now, flagged above). PDF result reports (the spec said not to introduce a large unrelated PDF system if one doesn't already serve this need — Phase 5's receipt PDF generator is scoped to receipts, not repurposed here).
