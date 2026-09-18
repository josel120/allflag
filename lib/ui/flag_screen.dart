import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/flag_item.dart';
import '../l10n/generated/app_localizations.dart';

class FlagScreen extends StatefulWidget {
  const FlagScreen({super.key, required this.item, this.onExit});
  final FlagItem item;
  final VoidCallback? onExit;

  @override
  State<FlagScreen> createState() => _FlagScreenState();
}

class _FlagScreenState extends State<FlagScreen> {
  Timer? _hideTimer;
  bool _controlsVisible = true;

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (widget.onExit == null) return;
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !MediaQuery.of(context).accessibleNavigation) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _reveal() {
    setState(() => _controlsVisible = true);
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flag = Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: SizedBox.expand(
        child: Image.asset(
          widget.item.asset,
          fit: BoxFit.contain,
          semanticLabel: AppLocalizations.of(context).flagLabel(
            widget.item.displayName(AppLocalizations.of(context).localeName),
          ),
          errorBuilder: (context, error, stackTrace) => Center(
            child: Text(
              AppLocalizations.of(context).flagUnavailable,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
    if (widget.onExit == null) return flag;
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) widget.onExit?.call();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            onTap: _reveal,
            hint: l10n.revealFlagControls,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _reveal,
              child: flag,
            ),
          ),
          if (_controlsVisible)
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                minimum: const EdgeInsets.all(8),
                child: IconButton.filled(
                  tooltip: l10n.exitFlag,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: widget.onExit,
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
