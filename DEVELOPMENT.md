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

## 3. Security Rules & Role Strategy

### Firestore Security Rules
- **Authentication Required**: All read/write operations require a valid Firebase Auth session.
- **User Profiles**: 
    - Users can read all profiles (public info).
    - Users can only create/update their own profile.
    - **Role Escalation Protection**: Users cannot set their role to anything other than "student" during creation, and cannot change their role during updates.
- **Posts & Social**: Only authors can edit or delete their own posts, comments, and likes.
- **Chats**: Private. Only UIDs in the `participantIds` array can read or write messages within a chat.
- **Marketplace**: Only the seller can manage their own listings.
- **Notifications**: Users can only read and manage their own notifications.
- **Campus Updates**: Read-only for students; write access restricted to `admin` or `staff` roles.

### Admin/Staff Role Strategy
For the initial development phase, roles are managed via a `role` field in the `users` document. 
- **Security Limitation**: Since client-side promotion is blocked, initial admin/staff accounts must have their `role` field updated manually in the Firebase Console.
- **Long-term Solution**: Future production environments should use **Firebase Auth Custom Claims** to store user roles. This is more secure as it prevents unnecessary Firestore lookups in rules and is harder to spoof.

---

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
