// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(timelineRepository)
const timelineRepositoryProvider = TimelineRepositoryProvider._();

final class TimelineRepositoryProvider
    extends
        $FunctionalProvider<
          ITimelineRepository,
          ITimelineRepository,
          ITimelineRepository
        >
    with $Provider<ITimelineRepository> {
  const TimelineRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'timelineRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$timelineRepositoryHash();

  @$internal
  @override
  $ProviderElement<ITimelineRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ITimelineRepository create(Ref ref) {
    return timelineRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ITimelineRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ITimelineRepository>(value),
    );
  }
}

String _$timelineRepositoryHash() =>
    r'2bcc8c1521ca30b9d95f212185490d431f0cf69d';

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
