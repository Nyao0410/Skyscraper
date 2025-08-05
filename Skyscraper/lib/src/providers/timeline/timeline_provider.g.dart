// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

/// A Riverpod notifier for managing the timeline state.
@ProviderFor(Timeline)
const timelineProvider = TimelineProvider._();

/// A Riverpod notifier for managing the timeline state.
final class TimelineProvider
    extends $AsyncNotifierProvider<Timeline, List<Post>> {
  /// A Riverpod notifier for managing the timeline state.
  const TimelineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'timelineProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$timelineHash();

  @$internal
  @override
  Timeline create() => Timeline();
}

String _$timelineHash() => r'd7f8ab2c762b7b87577645377d71f544943898f4';

abstract class _$Timeline extends $AsyncNotifier<List<Post>> {
  FutureOr<List<Post>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Post>>, List<Post>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Post>>, List<Post>>,
              AsyncValue<List<Post>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
