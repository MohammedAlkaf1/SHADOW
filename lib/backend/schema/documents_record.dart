import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DocumentsRecord extends FirestoreRecord {
  DocumentsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "fileName" field.
  String? _fileName;
  String get fileName => _fileName ?? '';
  bool hasFileName() => _fileName != null;

  // "localPath" field.
  String? _localPath;
  String get localPath => _localPath ?? '';
  bool hasLocalPath() => _localPath != null;

  // "lastReadPosition" field.
  int? _lastReadPosition;
  int get lastReadPosition => _lastReadPosition ?? 0;
  bool hasLastReadPosition() => _lastReadPosition != null;

  // "currentFontScale" field.
  double? _currentFontScale;
  double get currentFontScale => _currentFontScale ?? 0.0;
  bool hasCurrentFontScale() => _currentFontScale != null;

  void _initializeFields() {
    _fileName = snapshotData['fileName'] as String?;
    _localPath = snapshotData['localPath'] as String?;
    _lastReadPosition = castToType<int>(snapshotData['lastReadPosition']);
    _currentFontScale = castToType<double>(snapshotData['currentFontScale']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('documents');

  static Stream<DocumentsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => DocumentsRecord.fromSnapshot(s));

  static Future<DocumentsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => DocumentsRecord.fromSnapshot(s));

  static DocumentsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      DocumentsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static DocumentsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      DocumentsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'DocumentsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is DocumentsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createDocumentsRecordData({
  String? fileName,
  String? localPath,
  int? lastReadPosition,
  double? currentFontScale,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'fileName': fileName,
      'localPath': localPath,
      'lastReadPosition': lastReadPosition,
      'currentFontScale': currentFontScale,
    }.withoutNulls,
  );

  return firestoreData;
}

class DocumentsRecordDocumentEquality implements Equality<DocumentsRecord> {
  const DocumentsRecordDocumentEquality();

  @override
  bool equals(DocumentsRecord? e1, DocumentsRecord? e2) {
    return e1?.fileName == e2?.fileName &&
        e1?.localPath == e2?.localPath &&
        e1?.lastReadPosition == e2?.lastReadPosition &&
        e1?.currentFontScale == e2?.currentFontScale;
  }

  @override
  int hash(DocumentsRecord? e) => const ListEquality().hash(
      [e?.fileName, e?.localPath, e?.lastReadPosition, e?.currentFontScale]);

  @override
  bool isValidKey(Object? o) => o is DocumentsRecord;
}
