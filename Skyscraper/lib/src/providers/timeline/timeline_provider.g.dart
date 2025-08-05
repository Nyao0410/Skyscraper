// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

/// Provides a list of posts for the timeline.
///
/// This asynchronous provider fetches the timeline data from the
/// [timelineRepositoryProvider].
@ProviderFor(timeline)
const timelineProvider = TimelineProvider._();

/// Provides a list of posts for the timeline.
///
/// This asynchronous provider fetches the timeline data from the
/// [timelineRepositoryProvider].
final class TimelineProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Post>>,
          List<Post>,
          FutureOr<List<Post>>
        >
    with $FutureModifier<List<Post>>, $FutureProvider<List<Post>> {
  /// Provides a list of posts for the timeline.
  ///
  /// This asynchronous provider fetches the timeline data from the
  /// [timelineRepositoryProvider].
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
  $FutureProviderElement<List<Post>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Post>> create(Ref ref) {
    return timeline(ref);
  }
}

String _$timelineHash() => r'a678c8abe4f04c75c0ba5f0b89f333d4026266bc';

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
