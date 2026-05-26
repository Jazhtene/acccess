/// UI flags for the web admin shell.
abstract final class AdminUiConfig {
  /// Always false — all modules load data from PostgreSQL via the API.
  static const bool showDemoData = false;
}
