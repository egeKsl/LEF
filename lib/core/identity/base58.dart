import 'dart:typed_data';

/// Pure Dart implementation of Base58 encoding and decoding.
/// Uses the standard Bitcoin Base58 alphabet (without 0, O, I, l, +, /).
class Base58 {
  static const String _alphabet =
      '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  static final List<int> _indexes = List<int>.filled(128, -1);
  static bool _initialized = false;

  static void _initIndexes() {
    if (_initialized) return;
    for (int i = 0; i < _alphabet.length; i++) {
      _indexes[_alphabet.codeUnitAt(i)] = i;
    }
    _initialized = true;
  }

  /// Encodes [bytes] into a Base58 encoded string.
  static String encode(List<int> bytes) {
    if (bytes.isEmpty) return '';

    _initIndexes();
    int zeros = 0;
    while (zeros < bytes.length && bytes[zeros] == 0) {
      zeros++;
    }

    final List<int> input = List<int>.from(bytes);
    final List<int> encoded = List<int>.filled(bytes.length * 2, 0);
    int outputStart = encoded.length;

    for (int inputStart = zeros; inputStart < input.length; inputStart++) {
      int carry = input[inputStart] & 0xFF;
      int i = encoded.length - 1;
      while (i >= outputStart || carry != 0) {
        carry += 256 * (encoded[i] & 0xFF);
        encoded[i] = carry % 58;
        carry ~/= 58;
        i--;
      }
      outputStart = i + 1;
    }

    while (outputStart < encoded.length && encoded[outputStart] == 0) {
      outputStart++;
    }

    final StringBuffer sb = StringBuffer();
    for (int i = 0; i < zeros; i++) {
      sb.write('1');
    }
    for (int i = outputStart; i < encoded.length; i++) {
      sb.write(_alphabet[encoded[i]]);
    }
    return sb.toString();
  }

  /// Decodes a Base58 string into a [Uint8List].
  /// Throws [FormatException] if the string contains non-Base58 characters.
  static Uint8List decode(String input) {
    if (input.isEmpty) return Uint8List(0);

    _initIndexes();
    int zeros = 0;
    while (zeros < input.length && input[zeros] == '1') {
      zeros++;
    }

    final List<int> decoded = List<int>.filled(input.length, 0);
    int outputStart = decoded.length;

    for (int i = zeros; i < input.length; i++) {
      final int code = input.codeUnitAt(i);
      if (code >= 128 || _indexes[code] == -1) {
        throw FormatException(
            'Invalid Base58 character at index $i: ${input[i]}');
      }
      int carry = _indexes[code];
      int j = decoded.length - 1;
      while (j >= outputStart || carry != 0) {
        carry += 58 * (decoded[j] & 0xFF);
        decoded[j] = carry % 256;
        carry ~/= 256;
        j--;
      }
      outputStart = j + 1;
    }

    while (outputStart < decoded.length && decoded[outputStart] == 0) {
      outputStart++;
    }

    final Uint8List result = Uint8List(zeros + (decoded.length - outputStart));
    for (int i = 0; i < result.length; i++) {
      result[i] = decoded[outputStart + i - zeros];
    }
    return result;
  }
}
