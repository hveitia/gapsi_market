import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_bloc.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_event.dart';
import 'package:rekluti_test/modules/catalog/domain/product.dart';
import 'package:rekluti_test/modules/catalog/presenter/history_view.dart';
import 'package:rekluti_test/modules/catalog/presenter/product_detail_view.dart';
import 'package:rekluti_test/modules/catalog/presenter/search_view.dart';
import 'package:rekluti_test/modules/catalog/presenter/widgets/floating_nav_bar.dart';

/// Locations owned by the catalog module.
abstract final class CatalogRoutePaths {
  static const String search = '/';
  static const String history = '/history';
  static const String product = '/product';
}

/// The screens this module contributes.
///
/// Search and history live in a shell so switching between them keeps each
/// one's scroll position. The detail screen is pushed over the shell, so it
/// covers the navigation bar the way the design draws it.
final List<RouteBase> catalogRoutes = <RouteBase>[
  StatefulShellRoute.indexedStack(
    builder:
        (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell shell,
        ) => CatalogShell(shell: shell),
    branches: <StatefulShellBranch>[
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: CatalogRoutePaths.search,
            builder: (BuildContext context, GoRouterState state) =>
                SearchView(onProductSelected: _openProduct),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: CatalogRoutePaths.history,
            builder: (BuildContext context, GoRouterState state) =>
                HistoryView(onTermSelected: _repeatSearch),
          ),
        ],
      ),
    ],
  ),
  GoRoute(
    path: CatalogRoutePaths.product,
    builder: (BuildContext context, GoRouterState state) {
      final Object? product = state.extra;
      // The service offers no way to fetch a single product, so a link opened
      // without one cannot be resolved. Saying so beats a blank screen.
      return product is Product
          ? ProductDetailView(product: product)
          : const _ProductUnavailable();
    },
  ),
];

void _openProduct(BuildContext context, Product product) {
  context.push(CatalogRoutePaths.product, extra: product);
}

void _repeatSearch(BuildContext context, String term) {
  context.read<SearchBloc>().add(SearchTermChanged(term));
  context.go(CatalogRoutePaths.search);
}

/// Holds the shell's branches and the floating navigation bar.
class CatalogShell extends StatelessWidget {
  const CatalogShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The bar floats over the content, which is why every scrollable screen
      // reserves room for it rather than the Scaffold pushing them up.
      extendBody: true,
      body: shell,
      bottomNavigationBar: FloatingNavBar(
        destinations: catalogDestinations(),
        currentIndex: shell.currentIndex,
        onSelected: (int index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
      ),
    );
  }
}

class _ProductUnavailable extends StatelessWidget {
  const _ProductUnavailable();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Este producto ya no está disponible. Vuelve a buscarlo.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
