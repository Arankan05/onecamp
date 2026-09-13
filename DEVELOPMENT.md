# OneCamp Development Guide

## 1. Project Architecture

The project follows a modular, feature-based architecture with a shared core.

### Folder Structure
- `lib/core/`: Shared constants, services, theme, utils, and reusable widgets.
- `lib/features/`: Feature-specific modules (auth, feed, etc.).
- `lib/routes/`: Scalable routing configuration.
- `lib/models/`: Shared data models (if any).

### Feature Internal Structure
Each feature module under `lib/features/` should follow:
- `models/`: Data models specific to the feature.
- `repositories/`: Data access layer (abstracting Firebase).
- `services/` or `controllers/`: Business logic and state management.
- `screens/`: UI screens.
- `widgets/`: Widgets used only within this feature.

### Data Flow
`UI` -> `Controller/Service` -> `Repository` -> `Firebase`

---

## 2. Firebase Architecture

### Firestore Collections
| Collection | Description | Sub-collections |
|------------|-------------|-----------------|
| `users` | User profiles | `settings` |
| `posts` | Social feed posts | `comments`, `likes` |
| `communities` | Groups and organizations | `members`, `posts`, `announcements` |
| `events` | Campus events | `attendees` |
| `chats` | Direct and group messages | `messages` |
| `marketplace` | Student marketplace items | - |
| `notifications` | Push notification history | - |
| `campus_updates` | Official university news | - |

**Example Paths:**
- `users/{uid}`
- `posts/{postId}/comments/{commentId}`
- `communities/{communityId}/members/{uid}`
- `events/{eventId}/attendees/{uid}`
- `chats/{chatId}/messages/{messageId}`

### Storage Paths
- `profile_images/{uid}/`
- `post_images/{postId}/`
- `community_images/{communityId}/`
- `event_images/{eventId}/`
- `chat_images/{chatId}/`
- `marketplace_images/{itemId}/`

---

## 3. Security Rules Plan

### Firestore
- **Users**: Read: any auth user; Write: `request.auth.uid == userId`.
- **Posts**: Read: any auth user; Create: any auth user; Update/Delete: `request.auth.uid == post.authorId`.
- **Chats**: Read/Write: `request.auth.uid in chat.participantIds`.
- **Communities**: Read: any auth user; Write: depends on member role.

### Storage
- Users can only upload to their own directories or feature-specific directories with proper ownership checks.

---

## 4. Git Workflow

### Branching Strategy
- `main`: Stable production/release branch.
- `develop`: Integration branch for the team.

### Feature Branches
- `feature/auth-profile`
- `feature/feed`
- `feature/communities`
- `feature/events`
- `feature/chat`
- `feature/marketplace`

### Rules
1. **No direct pushes** to `main` or `develop`.
2. All feature work must go through **Pull Requests (PRs)** to `develop`.
3. Keep changes isolated to your feature folder (`lib/features/your_feature`).
4. Discuss changes to `lib/core/` or `lib/routes/` with the team.
5. Do not commit secrets, `.env` files, or generated Firebase credentials.

---

## 5. Development Rules
- Use `AppTheme` for colors and text styles.
- Use `AppConstants` for collection names and strings.
- Run `flutter analyze` before pushing.
- Write unit tests for business logic in `repositories` and `services`.
