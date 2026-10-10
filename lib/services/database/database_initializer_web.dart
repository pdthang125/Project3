import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

void initializeDatabaseFactory() {
  // Avoid the shared worker during local web debugging. It requires a
  // generated sqflite_sw.js file and is not supported by every browser.
  databaseFactory = databaseFactoryFfiWebNoWebWorker;
}
