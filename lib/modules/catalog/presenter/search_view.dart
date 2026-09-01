import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:rekluti_test/configs/theme/app_colors.dart';
import 'package:rekluti_test/configs/theme/app_theme.dart';
import 'package:rekluti_test/configs/theme/app_typography.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_bloc.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_event.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_history_bloc.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_history_event.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_history_state.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_state.dart';
import 'package:rekluti_test/modules/catalog/domain/product.dart';
import 'package:rekluti_test/modules/catalog/presenter/catalog_formats.dart';
import 'package:rekluti_test/modules/catalog/presenter/catalog_messages.dart';
import 'package:rekluti_test/modules/catalog/presenter/widgets/catalog_message.dart';
import 'package:rekluti_test/modules/catalog/presenter/widgets/history_chips.dart';
import 'package:rekluti_test/modules/catalog/presenter/widgets/pagination_footer.dart';
import 'package:rekluti_test/modules/catalog/presenter/widgets/product_card.dart';
import 'package:rekluti_test/modules/catalog/presenter/widgets/product_skeleton.dart';
import 'package:rekluti_test/modules/catalog/presenter/widgets/search_field.dart';

/// Terms worth offering when a search returns nothing.
///
/// English words and brands, which is what the service actually indexes.
const List<String> kSuggestedTerms = <String>[
  'nintendo',
  'sony',
  'computer',
  'lego',
];

/// The search screen: field, results and every state they can be in.
class SearchView extends StatefulWidget {
  const SearchView({required this.onProductSelected, super.key});

  /// Navigation is handed in, so this screen does not depend on the router.
  final void Function(BuildContext context, Product product) onProductSelected;

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  /// How far from the bottom to start fetching, so the next page is usually
  /// there before the user reaches the end of the list.
  static const double _prefetchExtent = 420;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    context.read<SearchHistoryBloc>().add(const SearchHistoryRequested());
  }

  @override
  void dispose() {
    _scroll.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) {
      return;
    }
    final double remaining =
        _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (remaining <= _prefetchExtent) {
      // The bloc decides whether this is worth acting on. Asking is cheap;
      // guarding the request belongs where the state lives.
      context.read<SearchBloc>().add(const SearchNextPageRequested());
    }
  }

  void _search(String term) {
    _controller
      ..text = term
      ..selection = TextSelection.collapsed(offset: term.length);
    context.read<SearchBloc>().add(SearchTermChanged(term));
  }

  void _clear() {
    _controller.clear();
    context.read<SearchBloc>().add(const SearchCleared());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final SearchState state = context.watch<SearchBloc>().state;

    return BlocListener<SearchBloc, SearchState>(
      // A completed search has just written a term to the history. Reloading
      // here keeps the chips current without the history bloc needing to know
      // that the search bloc exists.
      listenWhen: (SearchState previous, SearchState current) =>
          current is SearchResults || current is SearchEmpty,
      listener: (BuildContext context, SearchState _) =>
          context.read<SearchHistoryBloc>().add(const SearchHistoryRequested()),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppShapes.screenPadding,
                  12,
                  AppShapes.screenPadding,
                  14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (state is SearchIdle) ...<Widget>[
                      Text('Hola, buenas compras', style: AppTypography.meta),
                      Text(
                        'Mercado',
                        style: AppTypography.titleSm.copyWith(
                          color: AppColors.accent,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _searchField(state),
                  ],
                ),
              ),
              Expanded(child: _body(state)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchField(SearchState state) {
    // The field is rebuilt through a listener so the clear button appears as
    // soon as there is text, without the whole screen rebuilding per keystroke.
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (BuildContext context, TextEditingValue value, Widget? _) {
        return SearchField(
          controller: _controller,
          isSearching: state is SearchLoading,
          onChanged: (String term) =>
              context.read<SearchBloc>().add(SearchTermChanged(term)),
          onCleared: _clear,
        );
      },
    );
  }

  Widget _body(SearchState state) {
    return switch (state) {
      SearchIdle() => _idle(),
      final SearchLoading _ => const SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppShapes.screenPadding),
        child: ProductSkeletonList(),
      ),
      final SearchEmpty empty => CatalogMessage(
        icon: PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.duotone),
        title: 'Sin resultados',
        detail:
            'No encontramos productos para "${empty.term}". Prueba con una '
            'palabra en inglés o con una marca.',
        suggestions: kSuggestedTerms,
        onSuggestionTap: _search,
        actionLabel: 'Nueva búsqueda',
        onAction: _clear,
      ),
      final SearchFailed failed => CatalogMessage(
        icon: PhosphorIcons.warningCircle(PhosphorIconsStyle.duotone),
        title: CatalogMessages.title(failed.failure),
        detail: CatalogMessages.detail(failed.failure),
        tone: CatalogMessageTone.error,
        actionLabel: 'Reintentar',
        onAction: failed.failure.isRetryable
            ? () => context.read<SearchBloc>().add(const SearchRetryRequested())
            : null,
        code: CatalogMessages.code(failed.failure),
      ),
      final SearchResults results => _results(results),
    };
  }

  Widget _idle() {
    return BlocBuilder<SearchHistoryBloc, SearchHistoryState>(
      builder: (BuildContext context, SearchHistoryState state) {
        final List<Widget> children = <Widget>[];

        if (state is SearchHistoryLoaded && !state.isEmpty) {
          children.addAll(<Widget>[
            Text('Buscados antes', style: AppTypography.titleSm),
            const SizedBox(height: 12),
            HistoryChips(terms: state.terms, onSelected: _search),
            const SizedBox(height: 28),
          ]);
        }

        children.addAll(<Widget>[
          Text('Prueba con', style: AppTypography.titleSm),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kSuggestedTerms
                .map(
                  (String term) => ActionChip(
                    label: Text(term, style: AppTypography.label),
                    onPressed: () => _search(term),
                    backgroundColor: AppColors.cream,
                    side: const BorderSide(color: AppColors.hairline),
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                  ),
                )
                .toList(),
          ),
        ]);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppShapes.screenPadding,
            4,
            AppShapes.screenPadding,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        );
      },
    );
  }

  Widget _results(SearchResults results) {
    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(
        AppShapes.screenPadding,
        4,
        AppShapes.screenPadding,
        // Room for the floating navigation bar.
        100,
      ),
      itemCount: results.products.length + 2,
      separatorBuilder: (BuildContext context, int index) =>
          SizedBox(height: index == 0 ? 0 : 14),
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              CatalogFormats.resultsHeadline(
                results.totalResults,
                results.term,
              ),
              style: AppTypography.meta,
            ),
          );
        }
        if (index <= results.products.length) {
          final Product product = results.products[index - 1];
          return ProductCard(
            product: product,
            onTap: () => widget.onProductSelected(context, product),
          );
        }
        return PaginationFooter(
          state: results,
          onRetry: () =>
              context.read<SearchBloc>().add(const SearchRetryRequested()),
        );
      },
    );
  }
}
