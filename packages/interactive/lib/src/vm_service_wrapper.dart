import 'package:logging/logging.dart';
import 'package:vm_service/utils.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

class VmServiceWrapper {
  final VmService vmService;

  VmServiceWrapper._({
    required this.vmService,
  });

  static Future<VmServiceWrapper> create(Uri serverUri) async {
    final vmService = await vmServiceConnectUri(
      convertToWebSocketUrl(serviceProtocolUrl: serverUri).toString(),
      log: _Log(),
    );

    return VmServiceWrapper._(vmService: vmService);
  }

  void dispose() {
    vmService.dispose();
  }
}

class _Log extends Log {
  final log = Logger('VmServiceLogger');

  @override
  void warning(String message) => log.warning(message);

  @override
  void severe(String message) => log.warning(message);
}
