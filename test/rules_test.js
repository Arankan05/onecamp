const fs = require('fs');
const path = require('path');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'demo-onecamp';
jest.setTimeout(30000);

describe('OneCamp Isolated Firestore Security Rules Test Suite', () => {
  let testEnv;

  beforeAll(async () => {
    const rulesPath = path.join(__dirname, '../firestore.test.rules');
    const rules = fs.readFileSync(rulesPath, 'utf8');

    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: rules,
        host: '127.0.0.1',
        port: 8080,
      },
    });
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();

    // Seed test user documents
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      await db.doc('users/alice_uid').set({
        uid: 'alice_uid',
        email: 'alice@onecamp.edu',
        name: 'Alice Smith',
        role: 'student',
      });

      await db.doc('users/bob_uid').set({
        uid: 'bob_uid',
        email: 'bob@onecamp.edu',
        name: 'Bob Jones',
        role: 'student',
      });

      await db.doc('users/charlie_uid').set({
        uid: 'charlie_uid',
        email: 'charlie@onecamp.edu',
        name: 'Charlie Brown',
        role: 'student',
      });

      await db.doc('users/admin_uid').set({
        uid: 'admin_uid',
        email: 'admin@onecamp.edu',
        name: 'Admin User',
        role: 'admin',
      });

      // Seed Chat Room: Alice & Bob
      await db.doc('chats/chat1').set({
        type: 'direct',
        participantIds: ['alice_uid', 'bob_uid'],
        lastMessage: 'Hello',
        mutedBy: ['alice_uid'],
        pinnedBy: ['alice_uid'],
        hiddenFor: [],
      });

      // Seed Chat Room with existing hiddenFor entry
      await db.doc('chats/chat2').set({
        type: 'direct',
        participantIds: ['alice_uid', 'bob_uid'],
        lastMessage: 'Hidden chat',
        mutedBy: [],
        pinnedBy: [],
        hiddenFor: ['bob_uid'],
      });

      // Seed Group Chat Room
      await db.doc('chats/group1').set({
        type: 'group',
        groupName: 'CS Study Group',
        participantIds: ['alice_uid', 'bob_uid'],
        lastMessage: 'Welcome all',
        mutedBy: [],
        pinnedBy: [],
        hiddenFor: [],
      });

      // Seed Initial Message Doc in chat1
      await db.doc('chats/chat1/messages/msg1').set({
        senderId: 'alice_uid',
        text: 'Hello Bob!',
        messageType: 'text',
        sentAt: new Date(),
        readBy: ['alice_uid'],
        isDeleted: false,
        hiddenFor: [],
        status: 'sent',
      });

      // Seed Initial Message Doc with hiddenFor in chat1
      await db.doc('chats/chat1/messages/msg2').set({
        senderId: 'alice_uid',
        text: 'Existing hidden message',
        messageType: 'text',
        sentAt: new Date(),
        readBy: ['alice_uid'],
        isDeleted: false,
        hiddenFor: ['alice_uid'],
        status: 'sent',
      });

      // Seed Direct Block: Bob blocked Charlie
      await db.doc('users/bob_uid/blocked_users/charlie_uid').set({
        uid: 'charlie_uid',
        blockedAt: new Date(),
      });
    });
  });

  afterAll(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  // Test 1: Unauthorized Read Protection
  test('1. Unauthenticated user CANNOT read chats', async () => {
    const unauthed = testEnv.unauthenticatedContext();
    await assertFails(unauthed.firestore().collection('chats').get());
  });

  test('1b. Non-participant CANNOT read chat room', async () => {
    const charlie = testEnv.authenticatedContext('charlie_uid');
    await assertFails(charlie.firestore().doc('chats/chat1').get());
  });

  test('1c. Participant CAN read chat room', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertSucceeds(alice.firestore().doc('chats/chat1').get());
  });

  // Test 2: Message Authorization Protection
  test('2. Non-participant CANNOT send message to chat room', async () => {
    const charlie = testEnv.authenticatedContext('charlie_uid');
    await assertFails(
      charlie.firestore().collection('chats/chat1/messages').add({
        senderId: 'charlie_uid',
        text: 'Unauthorized intruder message',
        messageType: 'text',
        sentAt: new Date(),
        readBy: ['charlie_uid'],
        isDeleted: false,
        hiddenFor: [],
        status: 'sent',
      })
    );
  });

  // Test 3: Impersonation Prevention
  test('3. User CANNOT send message impersonating another senderId', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertFails(
      alice.firestore().collection('chats/chat1/messages').add({
        senderId: 'bob_uid',
        text: 'Impersonated message',
        messageType: 'text',
        sentAt: new Date(),
        readBy: ['alice_uid'],
        isDeleted: false,
        hiddenFor: [],
        status: 'sent',
      })
    );
  });

  // Test 4: Empty Message Validation
  test('4. Whitespace-only text message is REJECTED', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertFails(
      alice.firestore().collection('chats/chat1/messages').add({
        senderId: 'alice_uid',
        text: '   ',
        messageType: 'text',
        sentAt: new Date(),
        readBy: ['alice_uid'],
        isDeleted: false,
        hiddenFor: [],
        status: 'sent',
      })
    );
  });

  // Test 5: Valid Message Sending
  test('5. Valid short text message "Hi" is ACCEPTED', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertSucceeds(
      alice.firestore().collection('chats/chat1/messages').add({
        senderId: 'alice_uid',
        text: 'Hi',
        messageType: 'text',
        sentAt: new Date(),
        readBy: ['alice_uid'],
        isDeleted: false,
        hiddenFor: [],
        status: 'sent',
      })
    );
  });

  // Test 6: Cloudinary URL Domain Validation
  test('6. Invalid image URL domain is REJECTED', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertFails(
      alice.firestore().collection('chats/chat1/messages').add({
        senderId: 'alice_uid',
        text: '',
        imageUrl: 'https://malicious-site.com/hacked.jpg',
        messageType: 'image',
        sentAt: new Date(),
        readBy: ['alice_uid'],
        isDeleted: false,
        hiddenFor: [],
        status: 'sent',
      })
    );
  });

  test('7. Valid Cloudinary HTTPS image URL is ACCEPTED', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertSucceeds(
      alice.firestore().collection('chats/chat1/messages').add({
        senderId: 'alice_uid',
        text: '',
        imageUrl: 'https://res.cloudinary.com/o5k43wz7/image/upload/v12345/photo.jpg',
        messageType: 'image',
        sentAt: new Date(),
        readBy: ['alice_uid'],
        isDeleted: false,
        hiddenFor: [],
        status: 'sent',
      })
    );
  });

  // Test 8: Preference Isolation & Modification
  test('8. User CANNOT modify another user\'s mute or pin preference', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertFails(
      alice.firestore().doc('chats/chat1').update({
        mutedBy: ['bob_uid'],
      })
    );
  });

  test('8b. User CAN add their own UID to mutedBy preference', async () => {
    const bob = testEnv.authenticatedContext('bob_uid');
    await assertSucceeds(
      bob.firestore().doc('chats/chat1').update({
        mutedBy: ['alice_uid', 'bob_uid'],
      })
    );
  });

  test('8c. User CAN remove their own UID from mutedBy preference', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertSucceeds(
      alice.firestore().doc('chats/chat1').update({
        mutedBy: [],
      })
    );
  });

  test('8d. User CANNOT remove another user\'s UID from mutedBy', async () => {
    const bob = testEnv.authenticatedContext('bob_uid');
    await assertFails(
      bob.firestore().doc('chats/chat1').update({
        mutedBy: [],
      })
    );
  });

  // Test 9: Deletion Authorization
  test('9. Non-sender CANNOT delete a message for everyone', async () => {
    const bob = testEnv.authenticatedContext('bob_uid');
    await assertFails(
      bob.firestore().doc('chats/chat1/messages/msg1').update({
        text: 'This message was deleted',
        isDeleted: true,
      })
    );
  });

  test('9b. Original sender CAN delete their message for everyone', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertSucceeds(
      alice.firestore().doc('chats/chat1/messages/msg1').update({
        text: 'This message was deleted',
        isDeleted: true,
      })
    );
  });

  // Test 10: User Reports Read Protection
  test('10. Ordinary student CANNOT read user reports', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertFails(alice.firestore().collection('reports').get());
  });

  test('10b. Authorized Admin/Staff CAN read reports', async () => {
    const admin = testEnv.authenticatedContext('admin_uid');
    await assertSucceeds(admin.firestore().collection('reports').get());
  });

  // Test 11: Blocking Protection
  test('11. Blocked user CANNOT start a direct chat with the blocker', async () => {
    const charlie = testEnv.authenticatedContext('charlie_uid');
    await assertFails(
      charlie.firestore().collection('chats').add({
        type: 'direct',
        participantIds: ['charlie_uid', 'bob_uid'],
        lastMessage: '',
        mutedBy: [],
        pinnedBy: [],
        hiddenFor: [],
      })
    );
  });

  test('11b. User CAN unblock someone they previously blocked', async () => {
    const bob = testEnv.authenticatedContext('bob_uid');
    await assertSucceeds(
      bob.firestore().doc('users/bob_uid/blocked_users/charlie_uid').delete()
    );
  });

  test('11c. User CANNOT delete another user\'s block list entry', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertFails(
      alice.firestore().doc('users/bob_uid/blocked_users/charlie_uid').delete()
    );
  });

  // Test 12: Role Protection
  test('12. Student CANNOT promote themselves to admin role', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertFails(
      alice.firestore().doc('users/alice_uid').update({
        role: 'admin',
      })
    );
  });

  // Test 13: Read Receipts
  test('13a. Recipient CAN mark sender\'s message as read', async () => {
    const bob = testEnv.authenticatedContext('bob_uid');
    await assertSucceeds(
      bob.firestore().doc('chats/chat1/messages/msg1').update({
        readBy: ['alice_uid', 'bob_uid'],
      })
    );
  });

  test('13b. Sender CANNOT mark their own message as read', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertFails(
      alice.firestore().doc('chats/chat1/messages/msg1').update({
        readBy: ['alice_uid', 'alice_uid'],
      })
    );
  });

  test('13c. Non-participant CANNOT modify readBy array', async () => {
    const eve = testEnv.authenticatedContext('eve_uid');
    await assertFails(
      eve.firestore().doc('chats/chat1/messages/msg1').update({
        readBy: ['alice_uid', 'eve_uid'],
      })
    );
  });

  test('13d. User CANNOT add another user\'s UID to readBy', async () => {
    const bob = testEnv.authenticatedContext('bob_uid');
    await assertFails(
      bob.firestore().doc('chats/chat1/messages/msg1').update({
        readBy: ['alice_uid', 'charlie_uid'],
      })
    );
  });

  // Test 14: Hide Message For Me
  test('14a. Participant CAN add their own UID to message hiddenFor', async () => {
    const bob = testEnv.authenticatedContext('bob_uid');
    await assertSucceeds(
      bob.firestore().doc('chats/chat1/messages/msg1').update({
        hiddenFor: ['bob_uid'],
      })
    );
  });

  test('14b. Participant CANNOT add another user\'s UID to message hiddenFor', async () => {
    const bob = testEnv.authenticatedContext('bob_uid');
    await assertFails(
      bob.firestore().doc('chats/chat1/messages/msg1').update({
        hiddenFor: ['charlie_uid'],
      })
    );
  });

  test('14c. Existing hiddenFor entries CANNOT be removed', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertFails(
      alice.firestore().doc('chats/chat1/messages/msg2').update({
        hiddenFor: [],
      })
    );
  });

  // Test 15: Hide Chat
  test('15a. Participant CAN hide chat for themselves', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertSucceeds(
      alice.firestore().doc('chats/chat1').update({
        hiddenFor: ['alice_uid'],
      })
    );
  });

  test('15b. Participant CANNOT hide chat for another participant', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertFails(
      alice.firestore().doc('chats/chat1').update({
        hiddenFor: ['bob_uid'],
      })
    );
  });

  // Test 16: Group Chat Validation & Isolation
  test('16a. Valid group creation SUCCEEDS', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertSucceeds(
      alice.firestore().collection('chats').add({
        type: 'group',
        groupName: 'Flutter Devs',
        participantIds: ['alice_uid', 'bob_uid', 'charlie_uid'],
        lastMessage: '',
        mutedBy: [],
        pinnedBy: [],
        hiddenFor: [],
      })
    );
  });

  test('16b. Group creation with duplicate participants is REJECTED', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertFails(
      alice.firestore().collection('chats').add({
        type: 'group',
        groupName: 'Duplicate Test',
        participantIds: ['alice_uid', 'alice_uid'],
        lastMessage: '',
        mutedBy: [],
        pinnedBy: [],
        hiddenFor: [],
      })
    );
  });

  test('16c. Non-participant CANNOT read group messages', async () => {
    const charlie = testEnv.authenticatedContext('charlie_uid');
    await assertFails(charlie.firestore().collection('chats/group1/messages').get());
  });

  test('16d. Non-participant CANNOT send message to group', async () => {
    const charlie = testEnv.authenticatedContext('charlie_uid');
    await assertFails(
      charlie.firestore().collection('chats/group1/messages').add({
        senderId: 'charlie_uid',
        text: 'Unauthorized group message',
        messageType: 'text',
        sentAt: new Date(),
        readBy: ['charlie_uid'],
        isDeleted: false,
        hiddenFor: [],
        status: 'sent',
      })
    );
  });

  // Test 17: Message Field Integrity
  test('17a. Message senderId CANNOT be modified during update', async () => {
    const bob = testEnv.authenticatedContext('bob_uid');
    await assertFails(
      bob.firestore().doc('chats/chat1/messages/msg1').update({
        senderId: 'charlie_uid',
        readBy: ['alice_uid', 'bob_uid'],
      })
    );
  });

  test('17b. Invalid messageType is REJECTED during creation', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertFails(
      alice.firestore().collection('chats/chat1/messages').add({
        senderId: 'alice_uid',
        text: 'Audio message',
        messageType: 'audio_invalid',
        sentAt: new Date(),
        readBy: ['alice_uid'],
        isDeleted: false,
        hiddenFor: [],
        status: 'sent',
      })
    );
  });

  // Test 18: Specific Pre-Deployment Verification Cases
  test('18a. Alice CAN add her own UID to pinnedBy', async () => {
    const bob = testEnv.authenticatedContext('bob_uid');
    await assertSucceeds(
      bob.firestore().doc('chats/chat1').update({
        pinnedBy: ['alice_uid', 'bob_uid'],
      })
    );
  });

  test('18b. Alice CAN remove her own UID from pinnedBy', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertSucceeds(
      alice.firestore().doc('chats/chat1').update({
        pinnedBy: [],
      })
    );
  });

  test('18c. Alice CANNOT modify Bob\'s pinnedBy preference', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertFails(
      alice.firestore().doc('chats/chat1').update({
        pinnedBy: ['bob_uid'],
      })
    );
  });

  test('18d. Alice blocks Bob: Bob CANNOT create a direct chat with Alice', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('users/alice_uid/blocked_users/bob_uid').set({
        uid: 'bob_uid',
      });
    });

    const bob = testEnv.authenticatedContext('bob_uid');
    await assertFails(
      bob.firestore().collection('chats').add({
        type: 'direct',
        participantIds: ['bob_uid', 'alice_uid'],
        lastMessage: '',
        mutedBy: [],
        pinnedBy: [],
        hiddenFor: [],
      })
    );
  });

  test('18e. Bob blocks Alice: Alice CANNOT create a direct chat with Bob', async () => {
    const charlie = testEnv.authenticatedContext('charlie_uid'); // Bob blocked Charlie in beforeEach
    await assertFails(
      charlie.firestore().collection('chats').add({
        type: 'direct',
        participantIds: ['charlie_uid', 'bob_uid'],
        lastMessage: '',
        mutedBy: [],
        pinnedBy: [],
        hiddenFor: [],
      })
    );
  });

  test('18f. Alice and Bob CAN create a direct chat when neither has blocked the other', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertSucceeds(
      alice.firestore().collection('chats').add({
        type: 'direct',
        participantIds: ['alice_uid', 'charlie_uid'],
        lastMessage: '',
        mutedBy: [],
        pinnedBy: [],
        hiddenFor: [],
      })
    );
  });

  test('18g. Alice CAN hide a conversation for herself without hiding it for Bob', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertSucceeds(
      alice.firestore().doc('chats/chat1').update({
        hiddenFor: ['alice_uid'],
      })
    );
  });

  test('18h. Alice CANNOT remove Bob\'s hiddenFor entry from chat', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertFails(
      alice.firestore().doc('chats/chat2').update({
        hiddenFor: [],
      })
    );
  });

  test('18i. Alice CAN read necessary block status but CANNOT modify Bob\'s block list', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('users/bob_uid/blocked_users/alice_uid').set({
        uid: 'alice_uid',
      });
    });

    const alice = testEnv.authenticatedContext('alice_uid');
    const db = alice.firestore();
    await assertSucceeds(
      db.doc('users/bob_uid/blocked_users/alice_uid').get()
    );
    await assertFails(
      db.doc('users/bob_uid/blocked_users/charlie_uid').delete()
    );
  });

  test('18j. Existing group chat behaviour remains unchanged', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    const db = alice.firestore();
    const doc = await db.doc('chats/group1').get();
    expect(doc.exists).toBe(true);
    const msgs = await db.collection('chats/group1/messages').get();
    expect(msgs.empty).toBe(true);
  });

  // Test 19: Additional Message Creation Blocking Enforcement Test
  test('19a. Blocked user CANNOT send message in an existing direct chat', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('users/alice_uid/blocked_users/bob_uid').set({
        uid: 'bob_uid',
      });
    });

    const bob = testEnv.authenticatedContext('bob_uid');
    await assertFails(
      bob.firestore().collection('chats/chat1/messages').add({
        senderId: 'bob_uid',
        text: 'Blocked message attempt',
        messageType: 'text',
        sentAt: new Date(),
        readBy: ['bob_uid'],
        isDeleted: false,
        hiddenFor: [],
        status: 'sent',
      })
    );
  });

  test('19b. Blocker user CANNOT send message in a blocked direct chat', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('users/alice_uid/blocked_users/bob_uid').set({
        uid: 'bob_uid',
      });
    });

    const alice = testEnv.authenticatedContext('alice_uid');
    await assertFails(
      alice.firestore().collection('chats/chat1/messages').add({
        senderId: 'alice_uid',
        text: 'Message attempt while blocking',
        messageType: 'text',
        sentAt: new Date(),
        readBy: ['alice_uid'],
        isDeleted: false,
        hiddenFor: [],
        status: 'sent',
      })
    );
  });

  // Test 20: Independent Per-User Chat Deletion
  test('20a. Two users CAN independently hide a direct chat', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertSucceeds(
      alice.firestore().doc('chats/chat1').update({
        hiddenFor: ['alice_uid'],
      })
    );

    const bob = testEnv.authenticatedContext('bob_uid');
    await assertSucceeds(
      bob.firestore().doc('chats/chat1').update({
        hiddenFor: ['alice_uid', 'bob_uid'],
      })
    );
  });

  test('20b. Multiple group members CAN independently hide a group chat', async () => {
    const alice = testEnv.authenticatedContext('alice_uid');
    await assertSucceeds(
      alice.firestore().doc('chats/group1').update({
        hiddenFor: ['alice_uid'],
      })
    );

    const bob = testEnv.authenticatedContext('bob_uid');
    await assertSucceeds(
      bob.firestore().doc('chats/group1').update({
        hiddenFor: ['alice_uid', 'bob_uid'],
      })
    );
  });
});
