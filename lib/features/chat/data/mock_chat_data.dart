/// Toggle off when wiring the list to live Matrix sync data.
const bool kUseMockChatPreview = true;

class MockChatPreview {
  final String roomName;
  final String lastMessage;
  final String timestamp;
  final int unreadCount;
  final bool isEncrypted;

  const MockChatPreview({
    required this.roomName,
    required this.lastMessage,
    required this.timestamp,
    this.unreadCount = 0,
    this.isEncrypted = true,
  });
}

const List<MockChatPreview> mockChatPreviews = [
  MockChatPreview(
    roomName: '#ops-command',
    lastMessage: 'Key rotation scheduled at 22:00 UTC',
    timestamp: '14:32',
    unreadCount: 3,
  ),
  MockChatPreview(
    roomName: '@alice:matrix.org',
    lastMessage: 'Acknowledged. Deploying patch.',
    timestamp: '13:05',
  ),
  MockChatPreview(
    roomName: '#dev-null-channel',
    lastMessage: 'Logs truncated. Session verified.',
    timestamp: '09:41',
    unreadCount: 12,
  ),
  MockChatPreview(
    roomName: '@bob:secure.node',
    lastMessage: 'Can you verify the device fingerprint?',
    timestamp: '18:20',
    unreadCount: 1,
  ),
  MockChatPreview(
    roomName: 'Secure Team Alpha',
    lastMessage: 'Meeting moved to #ops-command',
    timestamp: '07:02',
    unreadCount: 5,
  ),
  MockChatPreview(
    roomName: '#public-lobby',
    lastMessage: 'Welcome to the node — unencrypted relay',
    timestamp: '06:15',
    isEncrypted: false,
  ),
  MockChatPreview(
    roomName: '@cipher:darknet.io',
    lastMessage: '🔒 Message could not be decrypted',
    timestamp: '23:58',
    unreadCount: 2,
  ),
];
