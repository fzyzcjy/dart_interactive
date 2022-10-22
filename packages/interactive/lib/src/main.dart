import 'package:interactive/src/vm_service_wrapper.dart';

Future<void> main() async {
  final vm = await VmServiceWrapper.create();
  try {
    await _body(vm);
  } finally {
    vm.dispose();
  }
}

Future<void> _body(VmServiceWrapper vm) async {
  TODO;
}