import 'package:flutter_test/flutter_test.dart';
import 'package:ssh_remote/services/ssh_service.dart';

void main() {
  group('SshService.parseStats', () {
    test('parses standard Ubuntu output correctly', () {
      const rawOutput = '''
---MEM---
              total        used        free      shared  buff/cache   available
Mem:           3920        1500        1200          50        1220        2250
---DISK---
Filesystem     1M-blocks  Used Available Use% Mounted on
/dev/root          40960 10240     30720  25% /
---LOAD---
0.45 0.30 0.20 2/240 18920
---CORES---
2
---UPTIME---
up 4 days, 6 hours, 12 minutes
---OS---
Linux 5.15.0-88-generic x86_64
PRETTY_NAME="Ubuntu 22.04.3 LTS"
''';

      final stats = SshService.parseStats(rawOutput);

      expect(stats.ramTotalMb, equals(3920));
      expect(stats.ramUsedMb, equals(1500));
      expect(stats.ramPercent, closeTo(38.26, 0.1));

      expect(stats.diskTotalGb, equals(40.0));
      expect(stats.diskUsedGb, equals(10.0));
      expect(stats.diskPercent, equals(25.0));

      // 0.45 load on 2 cores = 22.5%
      expect(stats.cpuPercent, equals(22.5));
      expect(stats.cpuLoad, equals('0.45, 0.30, 0.20'));

      expect(stats.uptime, equals('4 days, 6 hours, 12 minutes'));
      expect(stats.osInfo, contains('Ubuntu 22.04.3 LTS'));
    });

    test('handles empty or malformed output gracefully without crashing', () {
      final stats = SshService.parseStats('');

      expect(stats.ramTotalMb, equals(0));
      expect(stats.ramUsedMb, equals(0));
      expect(stats.ramPercent, equals(0.0));
      expect(stats.diskTotalGb, equals(0.0));
      expect(stats.diskPercent, equals(0.0));
      expect(stats.cpuPercent, equals(0.0));
      expect(stats.uptime, equals('Unknown'));
    });
  });
}
