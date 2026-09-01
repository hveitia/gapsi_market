import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:rekluti_test/configs/theme/app_colors.dart';
import 'package:rekluti_test/configs/theme/app_typography.dart';

/// One destination of the floating bar.
class NavDestination {
  const NavDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// The floating pill the design uses instead of a Material navigation bar.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
    super.key,
  });

  /// Height of the bar plus the gap under it, which every scrollable screen
  /// reserves at the bottom so nothing ends up hidden behind it.
  static const double reservedSpace = 100;

  final List<NavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
      child: Material(
        color: AppColors.ink,
        shape: const StadiumBorder(),
        child: SizedBox(
          height: 64,
          child: Row(
            children: List<Widget>.generate(destinations.length, (int index) {
              final NavDestination destination = destinations[index];
              final bool selected = index == currentIndex;

              return Expanded(
                child: Semantics(
                  selected: selected,
                  button: true,
                  child: InkWell(
                    onTap: () => onSelected(index),
                    customBorder: const StadiumBorder(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          destination.icon,
                          size: 20,
                          color: selected
                              ? AppColors.accentSoft
                              : const Color(0xFFA89285),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          destination.label,
                          style: AppTypography.meta.copyWith(
                            fontSize: 10,
                            color: selected
                                ? AppColors.accentSoft
                                : const Color(0xFFA89285),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// The destinations the catalogue exposes.
List<NavDestination> catalogDestinations() => <NavDestination>[
  NavDestination(
    icon: PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.duotone),
    label: 'Buscar',
  ),
  NavDestination(
    icon: PhosphorIcons.heart(PhosphorIconsStyle.duotone),
    label: 'Favoritos',
  ),
  NavDestination(
    icon: PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.duotone),
    label: 'Historial',
  ),
];
