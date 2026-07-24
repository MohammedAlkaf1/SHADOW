import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class TranscriptionsRecord extends FirestoreRecord {
  TranscriptionsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "text" field.
  String? _text;
  String get text => _text ?? '';
  bool hasText() => _text != null;

  // "title" field.
  String? _title;
  String get title => _title ?? '';
  bool hasTitle() => _title != null;

  // "category" field.
  String? _category;
  String get category => _category ?? '';
  bool hasCategory() => _category != null;

  // "timestamp" field.
  int? _timestamp;
  int get timestamp => _timestamp ?? 0;
  bool hasTimestamp() => _timestamp != null;

  // "duration" field.
  int? _duration;
  int get duration => _duration ?? 0;
  bool hasDuration() => _duration != null;

  void _initializeFields() {
    _text = snapshotData['text'] as String?;
    _title = snapshotData['title'] as String?;
    _category = snapshotData['category'] as String?;
    _timestamp = castToType<int>(snapshotData['timestamp']);
    _duration = castToType<int>(snapshotData['duration']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('transcriptions');

  static Stream<TranscriptionsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => TranscriptionsRecord.fromSnapshot(s));

  static Future<TranscriptionsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => TranscriptionsRecord.fromSnapshot(s));

  static TranscriptionsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      TranscriptionsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static TranscriptionsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      TranscriptionsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'TranscriptionsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is TranscriptionsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createTranscriptionsRecordData({
  String? text,
  String? title,
  String? category,
  int? timestamp,
  int? duration,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'text': text,
      'title': title,
      'category': category,
      'timestamp': timestamp,
      'duration': duration,
    }.withoutNulls,
  );

  return firestoreData;
}

class TranscriptionsRecordDocumentEquality
    implements Equality<TranscriptionsRecord> {
  const TranscriptionsRecordDocumentEquality();

  @override
  bool equals(TranscriptionsRecord? e1, TranscriptionsRecord? e2) {
    return e1?.text == e2?.text &&
        e1?.title == e2?.title &&
        e1?.category == e2?.category &&
        e1?.timestamp == e2?.timestamp &&
        e1?.duration == e2?.duration;
  }

  @override
  int hash(TranscriptionsRecord? e) => const ListEquality()
      .hash([e?.text, e?.title, e?.category, e?.timestamp, e?.duration]);

  @override
  bool isValidKey(Object? o) => o is TranscriptionsRecord;
}
