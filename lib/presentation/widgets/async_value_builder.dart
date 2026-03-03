import 'package:flutter/material.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/presentation/widgets/error_retry_widget.dart';

class AsyncValueBuilder<T> extends StatelessWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function()? loading;
  final Widget Function(Object error, VoidCallback retry)? error;

  const AsyncValueBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.loading,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final errorWidget = error;
          if (errorWidget != null) {
            return errorWidget(snapshot.error!, () {});
          }
          return ErrorRetryWidget.general(
            onRetry: () {},
            message: _errorMessage(context, snapshot.error),
          );
        }

        final child = !snapshot.hasData
            ? KeyedSubtree(
                key: const ValueKey('loading'),
                child: loading?.call() ??
                    const Center(child: CircularProgressIndicator()),
              )
            : KeyedSubtree(
                key: const ValueKey('data'),
                child: builder(context, snapshot.data as T),
              );

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: child,
        );
      },
    );
  }

  String _errorMessage(BuildContext context, Object? error) {
    if (error == null) return context.l10n.asyncValue_errorOccurred;
    final msg = error.toString();
    if (msg.contains('permission-denied')) return context.l10n.asyncValue_permissionDenied;
    if (msg.contains('unavailable') || msg.contains('network')) {
      return context.l10n.asyncValue_networkError;
    }
    return context.l10n.asyncValue_loadFailed;
  }
}

class FutureRetryBuilder<T> extends StatefulWidget {
  final Future<T> Function() futureFactory;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function()? loading;

  const FutureRetryBuilder({
    super.key,
    required this.futureFactory,
    required this.builder,
    this.loading,
  });

  @override
  State<FutureRetryBuilder<T>> createState() => _FutureRetryBuilderState<T>();
}

class _FutureRetryBuilderState<T> extends State<FutureRetryBuilder<T>> {
  late Future<T> _future;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _future = widget.futureFactory();
  }

  static const _maxRetries = 3;

  Future<void> _retry() async {
    if (_retryCount >= _maxRetries) {
      setState(() {
        _retryCount++;
        _future = widget.futureFactory();
      });
      return;
    }
    final delay = Duration(seconds: 1 << _retryCount);
    await Future.delayed(delay);
    if (mounted) {
      setState(() {
        _retryCount++;
        _future = widget.futureFactory();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      key: ValueKey(_retryCount),
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final error = snapshot.error;
          if (error.toString().contains('network') ||
              error.toString().contains('unavailable')) {
            return ErrorRetryWidget.network(onRetry: _retry);
          }
          if (error.toString().contains('timeout') ||
              error.toString().contains('deadline')) {
            return ErrorRetryWidget.timeout(onRetry: _retry);
          }
          return ErrorRetryWidget.general(onRetry: _retry);
        }

        final child = !snapshot.hasData
            ? KeyedSubtree(
                key: const ValueKey('loading'),
                child: widget.loading?.call() ??
                    const Center(child: CircularProgressIndicator()),
              )
            : KeyedSubtree(
                key: const ValueKey('data'),
                child: widget.builder(context, snapshot.data as T),
              );

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: child,
        );
      },
    );
  }
}
