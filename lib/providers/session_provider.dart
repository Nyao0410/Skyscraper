
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skyscraper/providers/auth_provider.dart';
import 'package:atproto_core/atproto_core.dart';

final sessionProvider = Provider<Session?>((ref) {
  final auth = ref.watch(authProvider);
  return auth.asData?.value;
});
