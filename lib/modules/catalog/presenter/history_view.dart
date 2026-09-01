import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:rekluti_test/configs/theme/app_colors.dart';
import 'package:rekluti_test/configs/theme/app_theme.dart';
import 'package:rekluti_test/configs/theme/app_typography.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_history_bloc.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_history_event.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_history_state.dart';
import 'package:rekluti_test/modules/catalog/domain/search_term.dart';
import 'package:rekluti_test/modules/catalog/presenter/catalog_formats.dart';
import 'package:rekluti_test/modules/catalog/presenter/widgets/catalog_message.dart';

/// The full list of stored searches.
class HistoryView extends StatelessWidget {
  const HistoryView({required this.onTermSelected, super.key});

  /// Repeating a search is navigation, so the screen does not do it itself.
  final void Function(BuildContext context, String term) onTermSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<SearchHistoryBloc, SearchHistoryState>(
          builder: (BuildContext context, SearchHistoryState state) {
            return switch (state) {
              SearchHistoryLoading() => const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
              SearchHistoryUnavailable() => CatalogMessage(
                icon: PhosphorIcons.warningCircle(PhosphorIconsStyle.duotone),
                title: 'No pudimos leer tu historial',
                detail:
                    'El almacenamiento local no respondió. Tus búsquedas '
                    'siguen guardadas; vuelve a intentarlo.',
                tone: CatalogMessageTone.error,
                actionLabel: 'Reintentar',
                onAction: () => context.read<SearchHistoryBloc>().add(
                  const SearchHistoryRequested(),
                ),
              ),
              final SearchHistoryLoaded loaded when loaded.isEmpty =>
                CatalogMessage(
                  icon: PhosphorIcons.clockCounterClockwise(
                    PhosphorIconsStyle.duotone,
                  ),
                  title: 'Aún no buscaste nada',
                  detail:
                      'Las palabras que busques se guardan aquí y siguen '
                      'disponibles al volver a abrir la aplicación.',
                ),
              final SearchHistoryLoaded loaded => _list(context, loaded.terms),
            };
          },
        ),
      ),
    );
  }

  Widget _list(BuildContext context, List<SearchTerm> terms) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppShapes.screenPadding,
        8,
        AppShapes.screenPadding,
        100,
      ),
      itemCount: terms.length + 1,
      separatorBuilder: (BuildContext context, int index) =>
          SizedBox(height: index == 0 ? 0 : 12),
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return _Header(count: terms.length);
        }
        return _HistoryRow(
          entry: terms[index - 1],
          onTap: () => onTermSelected(context, terms[index - 1].term),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Historial', style: AppTypography.display),
                Text('Guardado localmente', style: AppTypography.meta),
              ],
            ),
          ),
          if (count > 0)
            OutlinedButton(
              onPressed: () => _confirmClear(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.dangerFg,
                side: const BorderSide(color: AppColors.hairline),
                shape: const StadiumBorder(),
                minimumSize: const Size(0, AppShapes.minTouchTarget),
              ),
              child: Text(
                'Borrar todo',
                style: AppTypography.label.copyWith(color: AppColors.dangerFg),
              ),
            ),
        ],
      ),
    );
  }

  /// Clearing the history cannot be undone, so it asks first.
  Future<void> _confirmClear(BuildContext context) async {
    final SearchHistoryBloc bloc = context.read<SearchHistoryBloc>();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('¿Borrar todo el historial?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      bloc.add(const SearchHistoryCleared());
    }
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry, required this.onTap});

  final SearchTerm entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppShapes.tileRadius + 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppShapes.tileRadius + 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.peach,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  PhosphorIcons.clockCounterClockwise(
                    PhosphorIconsStyle.duotone,
                  ),
                  size: 18,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      entry.term,
                      style: AppTypography.label.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${CatalogFormats.searchedAt(entry)} · '
                      '${CatalogFormats.resultCount(entry.resultCount)}',
                      style: AppTypography.meta,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.read<SearchHistoryBloc>().add(
                  SearchHistoryTermForgotten(entry.term),
                ),
                tooltip: 'Quitar "${entry.term}" del historial',
                icon: Icon(
                  PhosphorIcons.x(PhosphorIconsStyle.bold),
                  size: 16,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
