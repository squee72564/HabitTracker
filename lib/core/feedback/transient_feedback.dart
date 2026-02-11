import 'package:flutter/material.dart';

final Expando<_TransientFeedbackState> _feedbackStatesByMessenger =
    Expando<_TransientFeedbackState>('transient_feedback_state');

void showTransientFeedback(
  final BuildContext context,
  final String message, {
  final bool coalesceIdenticalMessages = true,
}) {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final _TransientFeedbackState state =
      _feedbackStatesByMessenger[messenger] ??= _TransientFeedbackState();

  if (coalesceIdenticalMessages && state.activeMessage == message) {
    return;
  }

  messenger.removeCurrentSnackBar();

  final int nextVersion = state.messageVersion + 1;
  state
    ..activeMessage = message
    ..messageVersion = nextVersion;

  final ScaffoldFeatureController<SnackBar, SnackBarClosedReason> controller =
      messenger.showSnackBar(SnackBar(content: Text(message)));
  controller.closed.whenComplete(() {
    if (state.messageVersion == nextVersion) {
      state.activeMessage = null;
    }
  });
}

class _TransientFeedbackState {
  String? activeMessage;
  int messageVersion = 0;
}
