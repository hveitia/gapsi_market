/// Build time configuration for the app.
///
/// Secrets are read through [String.fromEnvironment], which resolves at compile
/// time from `--dart-define`. Nothing sensitive is stored in this file, so the
/// repository can be shared without leaking credentials.
///
/// See the README for the flags required to run the project.
abstract final class EnvironmentConstants {
  //API URL BASE
  static const String apiBaseUrl =
      'https://axesso-walmart-data-service.p.rapidapi.com';

  //Endpoints
  static const String searchByKeywordPath = '/wlm/walmart-search-by-keyword';

  /// Host expected by RapidAPI's gateway to route the call.
  static const String rapidApiHost = 'axesso-walmart-data-service.p.rapidapi.com';

  /// Injected with `--dart-define=RAPIDAPI_KEY=...`.
  ///
  /// Defaults to an empty string so a build without the flag still compiles and
  /// can report the missing key, instead of failing to build.
  static const String rapidApiKey = String.fromEnvironment('RAPIDAPI_KEY');

  /// Whether the app was built with credentials.
  static bool get hasRapidApiKey => rapidApiKey.isNotEmpty;
}
