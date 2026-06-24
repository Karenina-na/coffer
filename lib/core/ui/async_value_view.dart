import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'coffer_empty_state.dart';
import 'design_tokens.dart';
import 'error_localizer.dart';

/// Generic AsyncValue wrapper for common loading / error / empty / data states.
class CofferAsyncValueView<T> extends StatelessWidget {
  const CofferAsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.isEmpty,
    this.empty,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) data;
  final Widget? loading;
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  )?
  error;
  final bool Function(T data)? isEmpty;
  final Widget Function(BuildContext context, T data)? empty;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final errorBuilder = error;
    return value.when(
      loading: () =>
          loading ??
          const Center(
            child: CircularProgressIndicator(color: CofferColors.actionPrimary),
          ),
      error: (e, stackTrace) =>
          errorBuilder?.call(context, e, stackTrace) ??
          CofferEmptyState.error(
            message: '加载失败: ${errorToMessage(e)}',
            onRetry: onRetry,
          ),
      data: (dataValue) {
        if (isEmpty != null && isEmpty!(dataValue) && empty != null) {
          return empty!(context, dataValue);
        }
        return data(context, dataValue);
      },
    );
  }
}
