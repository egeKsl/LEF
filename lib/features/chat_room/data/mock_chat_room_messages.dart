/// Toggle with [kUseMockChatPreview] in chat list — room UI uses mock timeline when true.
const bool kUseMockChatRoomMessages = true;

class MockMessage {
  final String body;
  final String time;
  final bool isMe;
  final bool isCustomEncoded;

  const MockMessage({
    required this.body,
    required this.time,
    this.isMe = false,
    this.isCustomEncoded = false,
  });
}

List<MockMessage> mockMessagesForRoom(String roomName) {
  return _messagesByRoom[roomName] ?? _defaultMessages;
}

const List<MockMessage> _defaultMessages = [
  MockMessage(
    body: 'Channel handshake complete. Keys exchanged.',
    time: '09:12',
    isMe: false,
  ),
  MockMessage(
    body: 'Copy. Standing by on this node.',
    time: '09:14',
    isMe: true,
  ),
  MockMessage(
    body: 'Reminder: rotate session material before 22:00 UTC.',
    time: '09:18',
    isMe: false,
  ),
];

final Map<String, List<MockMessage>> _messagesByRoom = {
  '#ops-command': [
    MockMessage(
      body: 'All units: key rotation at 22:00 UTC.',
      time: '14:28',
      isMe: false,
    ),
    MockMessage(
      body: 'Acknowledged. Preparing device re-verify.',
      time: '14:29',
      isMe: true,
    ),
    MockMessage(
      body: 'Visual payload queued — awaiting decode pipeline.',
      time: '14:30',
      isMe: false,
    ),
    MockMessage(
      body: 'Payload received. Hash matches manifest.',
      time: '14:32',
      isMe: true,
    ),
  ],
  '@alice:matrix.org': [
    MockMessage(
      body: 'Patch bundle is on the relay.',
      time: '12:58',
      isMe: false,
    ),
    MockMessage(
      body: 'Deploying to staging node now.',
      time: '13:02',
      isMe: true,
    ),
    MockMessage(
      body: 'Acknowledged. Deploying patch.',
      time: '13:05',
      isMe: false,
    ),
  ],
  '#dev-null-channel': [
    MockMessage(
      body: 'Logs truncated. Session verified.',
      time: '09:41',
      isMe: false,
    ),
    MockMessage(
      body: 'Retention policy applied — 0 messages persisted.',
      time: '09:42',
      isMe: true,
    ),
  ],
  '@bob:secure.node': [
    MockMessage(
      body: 'Can you verify the device fingerprint?',
      time: '18:18',
      isMe: false,
    ),
    MockMessage(
      body: 'Scanning QR anchor now.',
      time: '18:19',
      isMe: true,
    ),
  ],
  'Secure Team Alpha': [
    MockMessage(
      body: 'Meeting moved to #ops-command',
      time: '07:00',
      isMe: false,
    ),
    MockMessage(
      body: 'Roger. Joining ops channel.',
      time: '07:02',
      isMe: true,
    ),
  ],
  '#public-lobby': [
    MockMessage(
      body: 'Welcome to the node — unencrypted relay',
      time: '06:14',
      isMe: false,
    ),
    MockMessage(
      body: 'Do not post credentials here.',
      time: '06:15',
      isMe: true,
    ),
  ],
  '@cipher:darknet.io': [
    MockMessage(
      body: '🔒 Message could not be decrypted',
      time: '23:55',
      isMe: false,
    ),
    MockMessage(
      body: 'Requesting session re-key.',
      time: '23:58',
      isMe: true,
    ),
  ],
};
