# Communities Feature (Member 3)

Academic and interest-based communities with discussions and announcements.

## Screens

| Screen | File |
|---|---|
| Community list (search + category filter) | `screens/community_list_screen.dart` |
| Create community | `screens/create_community_screen.dart` |
| Community details (Join/Leave + tabs) | `screens/community_details_screen.dart` |

Tabs inside details: Posts, Announcements, Members (`widgets/`).

## Architecture

UI (screens/widgets) -> `CommunityController` -> `CommunityRepository` -> Firestore

## Firestore structure

```
communities/{communityId}
   |-- members/{userId}
   |-- posts/{postId}
   '-- announcements/{announcementId}
```

### communities/{communityId}
| Field | Type | Notes |
|---|---|---|
| name | string | 3-50 characters |
| description | string | 10-300 characters |
| category | string | Academic, Faculty, Degree, Interest, Sports, Other |
| createdBy | string | UID of creator (required by security rules) |
| createdAt | timestamp | |

### members/{userId}
Document ID is the member's UID. Fields: `role` (creator or member), `joinedAt`.
Join creates the document, leave deletes it.

### posts/{postId}
Fields: `authorId` (must equal the signed-in UID), `text`, `createdAt`.

### announcements/{announcementId}
Fields: `title`, `body`, `createdAt`. Only the community creator can write.

## For other members

- **Events (Member 4):** link an event to a community by storing the community document ID (`communityId`).
- **Navigation (Member 1):** routes needed for `CommunityListScreen`, `CreateCommunityScreen`, and `CommunityDetailsScreen(communityId: ...)`.

## Notes

- Member count is not stored. It is counted from the `members` sub-collection, because only the creator may update the community document.
- Member names currently show a short ID. Replace with real names once the `users` model is shared.
- No new collections or rules were added.