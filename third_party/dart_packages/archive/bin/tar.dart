library archive.tar;

import 'package:args/args.dart';
import 'package:archive/src/tar/tar_command.dart';

// tar --list <file>
// tar --extract <file> <dest>
// tar --create <source>

void main(List<String> arguments) {
  ArgParser args = new ArgParser();
  args.addFlag('list', abbr: 't', help: '<file>', negatable: false);
  args.addFlag('extract', abbr: 'x', help: '<file> <dest>', negatable: false);
  args.addFlag('create', abbr: 'c', help: '<directory>', negatable: false);

  ArgResults results = args.parse(arguments);
  List<String> files = results.rest;

  if (results['list']) {
    if (files.isEmpty) fail('expected the archive to act on');

    listFiles(files.first);
  } else if (results['create']) {
    if (files.isEmpty) fail('expected the directory to tar');

    createTarFile(files.first);
  } else if (results['extract']) {
    if (files.isEmpty) fail('expected the archive to extract');
    if (files.length < 2) fail('expected the directory to extract to');

    extractFiles(files.first, files[1]);
  } else {
    print('usage: tar [--list|--extract|--create] <file> [<dest>|<source>]');
    print('');
    fail(args.usage);
  }
}
