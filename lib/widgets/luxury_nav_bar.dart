import 'package:flutter/material.dart';
import '../widgets/luxury_form_widgets.dart';

/// A custom luxury bottom navigation bar with purple/black theme.
/// Supports 3–5 items. Active item shows a pill indicator + gradient icon.
class LuxuryNavBar extends StatelessWidget {
  const LuxuryNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<LuxuryNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        border: Border(
          top: BorderSide(
            color: LuxuryTheme.purpleLight.withAlpha(40),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: LuxuryTheme.purple.withAlpha(30),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              return Expanded(
                child: _NavItem(
                  item: items[i],
                  isActive: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final LuxuryNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: isActive
              ? LuxuryTheme.purple.withAlpha(30)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with active indicator dot
            Stack(
              alignment: Alignment.topRight,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 40,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive
                        ? LuxuryTheme.purple.withAlpha(50)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: isActive
                        ? ShaderMask(
                            shaderCallback: (bounds) =>
                                const LinearGradient(
                              colors: [
                                LuxuryTheme.purpleLight,
                                LuxuryTheme.goldLight,
                              ],
                            ).createShader(bounds),
                            child: Icon(
                              item.activeIcon ?? item.icon,
                              color: Colors.white,
                              size: 22,
                            ),
                          )
                        : Icon(
                            item.icon,
                            color: Colors.white38,
                            size: 22,
                          ),
                  ),
                ),
                // Notification badge
                if (item.badge != null && item.badge! > 0)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: LuxuryTheme.purpleLight,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          item.badge! > 9 ? '9+' : '${item.badge}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                color: isActive
                    ? LuxuryTheme.purpleLight
                    : Colors.white38,
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: isActive ? 0.3 : 0,
              ),
              child: Text(item.label),
            ),
            // Active indicator line
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 2,
              width: isActive ? 20 : 0,
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(colors: [
                        LuxuryTheme.purple,
                        LuxuryTheme.purpleLight,
                      ])
                    : null,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data class for a nav bar item
class LuxuryNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final int? badge;

  const LuxuryNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.badge,
  });
}

/// Shared luxury AppBar used across all nav pages
PreferredSizeWidget luxuryAppBar({
  required String title,
  required VoidCallback onLogout,
  List<Widget>? extraActions,
}) {
  return AppBar(
    backgroundColor: LuxuryTheme.card,
    elevation: 0,
    scrolledUnderElevation: 0,
    flexibleSpace: Container(
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        border: Border(
          bottom: BorderSide(
            color: LuxuryTheme.purpleLight.withAlpha(40),
            width: 1,
          ),
        ),
      ),
    ),
    title: ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [LuxuryTheme.goldLight, LuxuryTheme.purpleLight],
      ).createShader(bounds),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: 0.5,
        ),
      ),
    ),
    actions: [
      ...?extraActions,
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: onLogout,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: LuxuryTheme.purpleDim.withAlpha(120),
              shape: BoxShape.circle,
              border: Border.all(
                  color: LuxuryTheme.purple.withAlpha(80)),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Colors.white70,
              size: 16,
            ),
          ),
        ),
      ),
    ],
  );
}
