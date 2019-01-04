import 'dart:io';

Future<int> runCommand(String exe, List<String> arguments,
    {String workingDirectory, bool allowFail = false}) async {
  final fullCommand = '$exe ${arguments.join(" ")}';
  print('Running $fullCommand');

  final process = await Process.start(exe, arguments,
      workingDirectory: workingDirectory, runInShell: true);
  stdout.addStream(process.stdout);
  stderr.addStream(process.stderr);

  final exitCode = await process.exitCode;
  if (!allowFail && exitCode != 0) {
    throw new Exception('$fullCommand failed with exit code $exitCode');
  }
  return exitCode;
}