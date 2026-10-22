import 'package:drift/native.dart';
import 'package:duemate/core/database/database.dart';

/// Opens an isolated, in-memory database for repository tests.
///
/// Each call returns a fresh database so tests never share state.
AppDatabase openTestDatabase() =>
    AppDatabase.withExecutor(NativeDatabase.memory());
