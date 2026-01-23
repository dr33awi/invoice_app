import 'package:flutter/material.dart';

/// Custom page route with smooth slide transition
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;

  SlidePageRoute({
    required this.page,
    this.direction = SlideDirection.left,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Determine slide offset based on direction and RTL
            final isRtl = Directionality.of(context) == TextDirection.rtl;

            Offset begin;
            switch (direction) {
              case SlideDirection.left:
                begin = Offset(isRtl ? -1.0 : 1.0, 0.0);
                break;
              case SlideDirection.right:
                begin = Offset(isRtl ? 1.0 : -1.0, 0.0);
                break;
              case SlideDirection.up:
                begin = const Offset(0.0, 1.0);
                break;
              case SlideDirection.down:
                begin = const Offset(0.0, -1.0);
                break;
            }

            final tween = Tween(begin: begin, end: Offset.zero).chain(
              CurveTween(curve: Curves.easeOutCubic),
            );

            final fadeTween = Tween(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: Curves.easeOut),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
}

/// Fade page route for smoother transitions
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({
    required this.page,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 200),
          reverseTransitionDuration: const Duration(milliseconds: 150),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation.drive(
                Tween(begin: 0.0, end: 1.0).chain(
                  CurveTween(curve: Curves.easeOut),
                ),
              ),
              child: child,
            );
          },
        );
}

/// Scale and fade transition for modals/dialogs
class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ScalePageRoute({
    required this.page,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleTween = Tween(begin: 0.9, end: 1.0).chain(
              CurveTween(curve: Curves.easeOutCubic),
            );
            final fadeTween = Tween(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: Curves.easeOut),
            );

            return ScaleTransition(
              scale: animation.drive(scaleTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
}

enum SlideDirection {
  left,
  right,
  up,
  down,
}
