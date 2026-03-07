# Smart Academic Project Hub

Centralized multi-university platform: project management, AI duplicate detection, progress tracking, and 3D model viewing.

## Step 1: Database (SQL Server)

1. Open **SQL Server Management Studio** (or `sqlcmd`) and run:
   - `Database/Schema.sql`

2. This creates:
   - **Database:** `SmartAcademicProjectHub`
   - **Tables:** `Universities`, `Users` (hashed passwords), `RefreshTokens`, `Projects`, `ChatChannels`, `ChatMessages`, `ChatChannelMembers`
   - **Seed:** Two sample universities (Demo University, Tech Institute)

3. Create first users via API: `POST /api/auth/register` (see API section below).

## Step 2: Backend API (.NET)

- **Path:** `Api/`
- **Stack:** .NET 10, EF Core, SQL Server, JWT, BCrypt

### Setup

1. Update connection string in `Api/appsettings.json`:
   - `ConnectionStrings:DefaultConnection` → your SQL Server instance.

2. Run the API:
   ```bash
   cd Api
   dotnet run
   ```
   - Default: `http://localhost:5000` or as in `launchSettings.json`.

### Auth (JWT)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/login` | Login (email + password) → access + refresh token |
| POST | `/api/auth/register` | Register Student/Teacher (requires `UniversityId` from `GET /api/universities`) |
| POST | `/api/auth/logout` | Logout (Authorization: Bearer token; optional body: `refreshToken`) |
| POST | `/api/auth/refresh` | New access token using `refreshToken` |

### Projects (AI duplicate & approval)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/projects` | **Student:** Submit project → AI similarity check; if &gt; 70% reject, else save as **Pending** |
| GET | `/api/projects` | My projects (Student/Teacher) |
| GET | `/api/projects/pending` | **Teacher:** Pending projects for their university |
| GET | `/api/projects/{id}` | Get one project (if authorized) |
| POST | `/api/projects/{id}/review` | **Teacher:** Approve or reject (body: `approve`, `rejectionReason`) |
| PATCH | `/api/projects/{id}/progress` | **Student:** Update progress % (body: `progressPercent`) |

### AI service (Python)

- The API calls a **Python NLP service** for duplicate detection.
- Configure in `appsettings.json`: `AiDuplicateDetection:PythonServiceBaseUrl` (e.g. `http://localhost:5001`).
- Expected Python endpoint: `POST /api/similarity` with JSON `{ "title", "abstract_text" }`, response e.g. `{ "similarity_score": 0.0-100.0 }`.
- If the Python service is down, the API assumes **0% similarity** (unique) and allows submission.

### Universities

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/universities` | List universities (for registration). |

---

## Step 3: Flutter App (Login + Dashboard)

- **Path:** `app/`
- **Stack:** Flutter (mobile + web), Provider, HTTP, SharedPreferences, Google Fonts

### Setup

1. **API base URL:** In `app/lib/services/api_service.dart`, set `_baseUrl` to your backend (e.g. `http://localhost:5000` or `http://10.0.2.2:5000` for Android emulator).

2. Run the app:
   ```bash
   cd app
   flutter pub get
   flutter run
   ```
   - Choose Chrome for web, or a connected device/emulator for mobile.

### UI

- **Login screen:** Glassmorphism-style card on gradient (teal → slate), Login/Register tabs, email/password, role and university for register. Outfit font, gold accent CTA.
- **Dashboard:** Welcome header, role badge, university name, logout. Neumorphic stat cards (Total, Pending, Approved, Rejected). Glass-style project cards with status chip and progress %. Teachers see a “Pending review” section and can Approve/Reject. Students have a FAB “New project” to submit title/abstract (hits API with AI duplicate check).

### Features

- JWT stored in SharedPreferences; app opens to Dashboard when already logged in.
- Register uses `GET /api/universities` for the university dropdown.
- Submit project calls `POST /api/projects`; backend runs AI similarity and rejects if &gt; 70%.

---

## Next steps (Python AI, Chat, 3D)

- **Python:** Flask/FastAPI service implementing `POST /api/similarity` for NLP similarity.
- **Chat:** Discord-style channels (Private, University, Global) with pinned project header.
- **3D:** Flutter .obj viewer + upload (e.g. Kiri Engine–converted models).
