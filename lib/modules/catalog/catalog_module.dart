import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:rekluti_test/modules/catalog/bloc/favorites_bloc.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_bloc.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_history_bloc.dart';
import 'package:rekluti_test/modules/catalog/contract/catalog_contract.dart';
import 'package:rekluti_test/modules/catalog/contract/catalog_remote_datasource.dart';
import 'package:rekluti_test/modules/catalog/contract/favorites_contract.dart';
import 'package:rekluti_test/modules/catalog/contract/favorites_datasource.dart';
import 'package:rekluti_test/modules/catalog/contract/search_history_datasource.dart';
import 'package:rekluti_test/modules/catalog/datasource/local/favorites_local_datasource.dart';
import 'package:rekluti_test/modules/catalog/datasource/local/search_history_local_datasource.dart';
import 'package:rekluti_test/modules/catalog/datasource/remote/walmart_remote_datasource.dart';
import 'package:rekluti_test/modules/catalog/service/catalog_service.dart';
import 'package:rekluti_test/modules/catalog/service/favorites_service.dart';
import 'package:rekluti_test/shared/database/app_database.dart';

/// Everything the catalog module needs registered, in one call.
void registerCatalogDependencies(GetIt injector) {
  injector.registerLazySingleton<CatalogRemoteDataSource>(
    () => WalmartRemoteDataSource(injector<Dio>()),
  );

  injector.registerLazySingleton<SearchHistoryDataSource>(
    () => SqliteSearchHistoryDataSource(injector<AppDatabase>()),
  );

  injector.registerLazySingleton<CatalogContract>(
    () => CatalogService(
      remote: injector<CatalogRemoteDataSource>(),
      history: injector<SearchHistoryDataSource>(),
    ),
  );

  // Both blocs are shared rather than created per screen: the history screen
  // starts a search that the search screen has to show, and switching tabs must
  // not throw away the results already loaded.
  injector.registerLazySingleton<SearchBloc>(
    () => SearchBloc(injector<CatalogContract>()),
    dispose: (SearchBloc bloc) => bloc.close(),
  );

  injector.registerLazySingleton<FavoritesDataSource>(
    () => SqliteFavoritesDataSource(injector<AppDatabase>()),
  );

  injector.registerLazySingleton<FavoritesContract>(
    () => FavoritesService(injector<FavoritesDataSource>()),
  );

  // Shared like the others: every heart in the app has to agree, and the
  // favourites screen must not disagree with the list behind it.
  injector.registerLazySingleton<FavoritesBloc>(
    () => FavoritesBloc(injector<FavoritesContract>()),
    dispose: (FavoritesBloc bloc) => bloc.close(),
  );

  injector.registerLazySingleton<SearchHistoryBloc>(
    () => SearchHistoryBloc(injector<CatalogContract>()),
    dispose: (SearchHistoryBloc bloc) => bloc.close(),
  );
}
