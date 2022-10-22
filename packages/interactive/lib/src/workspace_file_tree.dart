class WorkspaceFileTree {
  Future<String> create() async {
    final dir = await _getDir();
    await _prepare(dir);
    return dir;
  }

  Future<String> _getDir() async {
    return TODO;
  }

  Future<void> _prepare(String dir) async {
    TODO;
  }
}
