import 'package:rekluti_test/shared/errors/failure.dart';

/// What each failure says to someone who is not a developer.
///
/// The failure model carries no copy on purpose, so the wording lives here and
/// a translation would touch one file.
abstract final class CatalogMessages {
  /// Headline for a search that could not be completed.
  static String title(Failure failure) => switch (failure) {
    NetworkFailure() => 'Sin conexión',
    TimeoutFailure() => 'La conexión tardó demasiado',
    UnauthorizedFailure() => 'Falta la llave de la API',
    RateLimitFailure() => 'Demasiadas búsquedas',
    ServerFailure() => 'El servicio no responde',
    ParsingFailure() => 'Respuesta inesperada',
    _ => 'Algo salió mal',
  };

  /// The sentence under the headline.
  static String detail(Failure failure) => switch (failure) {
    NetworkFailure() =>
      'No pudimos contactar el servicio. Revisa tu conexión e intenta de '
          'nuevo; tus búsquedas guardadas siguen disponibles.',
    TimeoutFailure() =>
      'El servicio tardó más de lo esperado en responder. Vuelve a intentarlo.',
    UnauthorizedFailure() =>
      'La aplicación se compiló sin la llave de RapidAPI. Consulta el README '
          'para ejecutarla con la llave.',
    RateLimitFailure() =>
      'Se alcanzó el límite de consultas del servicio. Espera un momento antes '
          'de volver a buscar.',
    ServerFailure() =>
      'El servicio devolvió un error. No es algo que puedas resolver desde '
          'aquí; vuelve a intentarlo en un momento.',
    ParsingFailure() =>
      'El servicio respondió en un formato que la aplicación no reconoce.',
    _ => 'No pudimos completar la búsqueda. Vuelve a intentarlo.',
  };

  /// The short line shown on the banner when an additional page fails.
  static String pageFailed(int page) => 'No se pudo cargar la página $page';

  /// Technical detail, when the failure carries one worth showing.
  static String? code(Failure failure) => switch (failure) {
    final ServerFailure f when f.statusCode != null =>
      'Código ${f.statusCode} · servicio no disponible',
    final RequestFailure f when f.statusCode != null => 'Código ${f.statusCode}',
    _ => null,
  };
}
