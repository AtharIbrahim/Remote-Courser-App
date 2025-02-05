// Fetch Ip Address
import 'dart:io';

class FetchIpAddress {
  static Future<String> getIp() async {
    try {
      final result =
          await Process.run('python', ['get_ip.py'], runInShell: true);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      } else {
        return "Failed to fetch IP";
      }
    } catch (e) {
      return "Error: $e";
    }
  }
}
