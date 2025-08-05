// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_post_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(CreatePostController)
const createPostControllerProvider = CreatePostControllerProvider._();

final class CreatePostControllerProvider
    extends $AsyncNotifierProvider<CreatePostController, void> {
  const CreatePostControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createPostControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createPostControllerHash();

  @$internal
  @override
  CreatePostController create() => CreatePostController();
}

String _$createPostControllerHash() =>
    r'4403b58fbe49c9921c2184acfb57f60848b55203';

abstract class _$CreatePostController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
