import 'dart:io';

import 'package:grinder/grinder.dart';
import 'package:path/path.dart' as path;

import '../bin/manifest.dart';
import '../lib/environment.dart';


// Helpers *******************************************************************
/// Returns the path to the project's top-level directory.
String get topLevel {
  var scriptRoot = path.dirname(Platform.script.toFilePath());
  return path.absolute(path.normalize(path.join(scriptRoot, '../../..')));
}

File copySync(File source, File destination) {
  destination.createSync(recursive: true);
  return source.copySync(destination.path);
}

String get loggerLevelFile {
  var where = path.join(topLevel, 'sublime_plugin_lib/__init__.py');
  return path.normalize(where);
}

bool checkLoggingLevelIsError() {
  var file = new File(loggerLevelFile);
  var regex = new RegExp(r'setLevel\(logging\.ERROR\)');
  return regex.hasMatch(file.readAsStringSync());
}

// Task Definition ***********************************************************
// TODO(guillermooo): use grinder "decorators".
main([List<String> args]) {
  task('check', check);
  task('deploy', do_deploy);
  task('release', null, ['check', 'deploy']);
  startGrinder(args);
}

// Task Implementation *******************************************************
void check(GrinderContext context) {
  if (!checkLoggingLevelIsError()) {
    var msg =
        'ERROR: wrong logging level used for release\n'
        '    check: $loggerLevelFile';
    context.fail(msg);
  }
}

void do_deploy(GrinderContext context) {
  var environment = new Environment(topLevel);

  try {
    var directory = new Directory(environment.destination);
    if (directory.existsSync()) directory.deleteSync(recursive: true);
    directory.createSync();
  } catch (Exception) {
    var message = 
        'cannot delete/create destination directory: ${environment.destination}';
    context.fail(message);
  }

  var manifest = new Manifest(included, environment);
  manifest.list().where((entity) => entity is File).forEach((source) {
    var relative = path.relative(source.path, from: environment.root);
    var destination = new File(path.join(environment.destination, relative));
    print('  ${source.path}');
    copySync(source, destination);
  });

  return 0;
}
