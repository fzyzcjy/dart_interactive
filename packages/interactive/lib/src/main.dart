import 'package:interactive/src/reader.dart';
import 'package:interactive/src/vm_service_wrapper.dart';

Future<void> main() async {
  final vm = await VmServiceWrapper.create();
  try {
    await runReader((input) => _handleInput(vm, input));
  } finally {
    vm.dispose();
  }
}

Future<void> _handleInput(VmServiceWrapper vm, String input) async {
  TODO;
}
