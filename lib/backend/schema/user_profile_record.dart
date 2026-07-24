import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class UserProfileRecord extends FirestoreRecord {
  UserProfileRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "selectedDisability" field.
  String? _selectedDisability;
  String get selectedDisability => _selectedDisability ?? '';
  bool hasSelectedDisability() => _selectedDisability != null;

  // "preferredFontSize" field.
  double? _preferredFontSize;
  double get preferredFontSize => _preferredFontSize ?? 0.0;
  bool hasPreferredFontSize() => _preferredFontSize != null;

  // "highContrast" field.
  bool? _highContrast;
  bool get highContrast => _highContrast ?? false;
  bool hasHighContrast() => _highContrast != null;

  void _initializeFields() {
    _selectedDisability = snapshotData['selectedDisability'] as String?;
    _preferredFontSize = castToType<double>(snapshotData['preferredFontSize']);
    _highContrast = snapshotData['highContrast'] as bool?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('user_profile');

  static Stream<UserProfileRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => UserProfileRecord.fromSnapshot(s));

  static Future<UserProfileRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => UserProfileRecord.fromSnapshot(s));

  static UserProfileRecord fromSnapshot(DocumentSnapshot snapshot) =>
      UserProfileRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static UserProfileRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      UserProfileRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'UserProfileRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is UserProfileRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createUserProfileRecordData({
  String? selectedDisability,
  double? preferredFontSize,
  bool? highContrast,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'selectedDisability': selectedDisability,
      'preferredFontSize': preferredFontSize,
      'highContrast': highContrast,
    }.withoutNulls,
  );

  return firestoreData;
}

class UserProfileRecordDocumentEquality implements Equality<UserProfileRecord> {
  const UserProfileRecordDocumentEquality();

  @override
  bool equals(UserProfileRecord? e1, UserProfileRecord? e2) {
    return e1?.selectedDisability == e2?.selectedDisability &&
        e1?.preferredFontSize == e2?.preferredFontSize &&
        e1?.highContrast == e2?.highContrast;
  }

  @override
  int hash(UserProfileRecord? e) => const ListEquality()
      .hash([e?.selectedDisability, e?.preferredFontSize, e?.highContrast]);

  @override
  bool isValidKey(Object? o) => o is UserProfileRecord;
}
