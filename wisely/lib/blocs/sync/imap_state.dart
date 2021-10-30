import 'package:freezed_annotation/freezed_annotation.dart';

part 'imap_state.freezed.dart';

@freezed
class ImapState with _$ImapState {
  factory ImapState.initial() = Initial;
  factory ImapState.loading() = Loading;
  factory ImapState.online({required DateTime lastUpdate}) = Online;
  factory ImapState.failed() = Failed;
}
