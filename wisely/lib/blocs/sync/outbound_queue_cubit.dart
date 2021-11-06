import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mutex/mutex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry/sentry.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wisely/blocs/sync/classes.dart';
import 'package:wisely/blocs/sync/encryption_cubit.dart';
import 'package:wisely/blocs/sync/vector_clock_cubit.dart';
import 'package:wisely/classes/journal_db_entities.dart';
import 'package:wisely/classes/sync_message.dart';
import 'package:wisely/sync/encryption.dart';
import 'package:wisely/sync/encryption_salsa.dart';
import 'package:wisely/utils/audio_utils.dart';
import 'package:wisely/utils/image_utils.dart';

import 'imap_out_cubit.dart';
import 'outbound_queue_db.dart';
import 'outbound_queue_state.dart';

class OutboundQueueCubit extends Cubit<OutboundQueueState> {
  late final EncryptionCubit _encryptionCubit;
  late final ImapOutCubit _imapOutCubit;
  late final VectorClockCubit _vectorClockCubit;
  ConnectivityResult? _connectivityResult;

  final sendMutex = Mutex();

  late final OutboundQueueDb _db;
  late String? _b64Secret;

  OutboundQueueCubit({
    required EncryptionCubit encryptionCubit,
    required ImapOutCubit imapOutCubit,
    required VectorClockCubit vectorClockCubit,
  }) : super(OutboundQueueState.initial()) {
    _encryptionCubit = encryptionCubit;
    _imapOutCubit = imapOutCubit;
    _vectorClockCubit = vectorClockCubit;
    _db = OutboundQueueDb();
    init();

    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _connectivityResult = result;
      debugPrint('Connectivity onConnectivityChanged $result');
    });
  }

  Future<void> init() async {
    await _db.openDb();
    SyncConfig? syncConfig = await _encryptionCubit.loadSyncConfig();

    if (syncConfig != null) {
      _b64Secret = syncConfig.sharedSecret;
    }
    emit(OutboundQueueState.online());
    _startPolling();
  }

  void reportConnectivity() async {
    await Sentry.captureEvent(
        SentryEvent(
          message: SentryMessage(_connectivityResult.toString()),
        ),
        withScope: (Scope scope) => scope.level = SentryLevel.info);
  }

  void sendNext() async {
    final transaction = Sentry.startTransaction('sendNext()', 'task');
    _connectivityResult = await Connectivity().checkConnectivity();
    debugPrint('sendNext Connectivity $_connectivityResult');
    reportConnectivity();

    // TODO: check why not working reliably on macOS - workaround
    bool isConnected =
        Platform.isIOS ? _connectivityResult != ConnectivityResult.none : true;
    if (isConnected && !sendMutex.isLocked) {
      List<OutboundQueueRecord> unprocessed = await _db.oldestEntries();
      if (unprocessed.isNotEmpty) {
        sendMutex.acquire();
        OutboundQueueRecord nextPending = unprocessed.first;
        bool saveSuccess = await _imapOutCubit.saveImap(
          nextPending.encryptedMessage,
          nextPending.subject,
          encryptedFilePath: nextPending.encryptedFilePath,
        );
        debugPrint('sendNext saveImap success: $saveSuccess');
        if (saveSuccess) {
          _db.update(
            nextPending,
            OutboundMessageStatus.sent,
            nextPending.retries,
          );
        } else {
          _db.update(
            nextPending,
            nextPending.retries < 10
                ? OutboundMessageStatus.pending
                : OutboundMessageStatus.error,
            nextPending.retries + 1,
          );
        }
        sendMutex.release();
        sendNext();
      }
    }
    await transaction.finish();
  }

  void _startPolling() async {
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      sendNext();
    });
  }

  Future<void> enqueueMessage(SyncMessage syncMessage) async {
    if (syncMessage is SyncJournalDbEntity) {
      final transaction = Sentry.startTransaction('enqueueMessage()', 'task');
      JournalDbEntity journalDbEntity = syncMessage.journalEntity;
      String jsonString = json.encode(syncMessage);
      var docDir = await getApplicationDocumentsDirectory();

      File? attachment;
      String subject = 'enqueueMessage ${journalDbEntity.vectorClock}';

      journalDbEntity.data.maybeMap(
        journalDbAudio: (JournalDbAudio journalDbAudio) {
          attachment = File(AudioUtils.getAudioPath(journalDbAudio, docDir));
          AudioUtils.saveAudioNoteJson(journalDbAudio, journalDbEntity);
        },
        journalDbImage: (JournalDbImage image) {
          attachment = File(getFullImagePathWithDocDir(image, docDir));
          saveJournalImageJson(image, journalDbEntity);
        },
        orElse: () {},
      );

      if (_b64Secret != null) {
        String encryptedMessage = encryptSalsa(jsonString, _b64Secret);
        if (attachment != null) {
          int fileLength = attachment!.lengthSync();
          if (fileLength > 0) {
            File encryptedFile = File('${attachment!.path}.aes');
            await encryptFile(attachment!, encryptedFile, _b64Secret!);
            await _db.queueInsert(encryptedMessage, subject,
                encryptedFilePath: encryptedFile.path);
          }
        } else {
          await _db.queueInsert(encryptedMessage, subject);
        }
      }
      await transaction.finish();
      sendNext();
    }
  }
}
