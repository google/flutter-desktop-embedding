Parses raw command-line arguments into a set of options and values.

This library supports [GNU][] and [POSIX][] style options, and it works
in both server-side and client-side apps.

## Defining options

First create an [ArgParser][]:

    var parser = new ArgParser();

Then define a set of options on that parser using [addOption()][addOption] and
[addFlag()][addFlag]. Here's the minimal way to create an option named "name":

    parser.addOption('name');

When an option can only be set or unset (as opposed to taking a string value),
use a flag:

```dart
parser.addFlag('name');
```

Flag options, by default, accept a 'no-' prefix to negate the option. You can
disable the 'no-' prefix using the `negatable` parameter:

```dart
parser.addFlag('name', negatable: false);
```

*Note:* From here on out, "option" refers to both regular options and flags. In
cases where the distinction matters, we'll use "non-flag option."

Options can have an optional single-character abbreviation, specified with the
`abbr` parameter:

```dart
parser.addOption('mode', abbr: 'm');
parser.addFlag('verbose', abbr: 'v');
```

Options can also have a default value, specified with the `defaultsTo`
parameter. The default value is used when arguments don't specify the option.

```dart
parser.addOption('mode', defaultsTo: 'debug');
parser.addFlag('verbose', defaultsTo: false);
```

The default value for non-flag options can be any string. For flags, it must
be a `bool`.

To validate a non-flag option, you can use the `allowed` parameter to provide an
allowed set of values. When you do, the parser throws an
[`ArgParserException`][ArgParserException] if the value for an option is not in
the allowed set. Here's an example of specifying allowed values:

[ArgParserException]: https://www.dartdocs.org/documentation/args/latest/args/ArgParserException-class.html

```dart
parser.addOption('mode', allowed: ['debug', 'release']);
```

You can use the `callback` parameter to associate a function with an option.
Later, when parsing occurs, the callback function is invoked with the value of
the option:

```dart
parser.addOption('mode', callback: (mode) => print('Got mode $mode'));
parser.addFlag('verbose', callback: (verbose) {
  if (verbose) print('Verbose');
});
```

The callbacks for all options are called whenever a set of arguments is parsed.
If an option isn't provided in the args, its callback is passed the default
value, or `null` if no default value is set.

## Parsing arguments

Once you have an [ArgParser][] set up with some options and flags, you use it by
calling [ArgParser.parse()][parse] with a set of arguments:

```dart
var results = parser.parse(['some', 'command', 'line', 'args']);
```

These arguments usually come from the arguments to `main()`. For example:

    main(List<String> args) {
      // ...
      var results = parser.parse(args);
    }

However, you can pass in any list of strings. The `parse()` method returns an
instance of [ArgResults][], a map-like object that contains the values of the
parsed options.

```dart
var parser = new ArgParser();
parser.addOption('mode');
parser.addFlag('verbose', defaultsTo: true);
var results = parser.parse(['--mode', 'debug', 'something', 'else']);

print(results['mode']); // debug
print(results['verbose']); // true
```

By default, the `parse()` method allows additional flags and options to be
passed after positional parameters unless `--` is used to indicate that all
further parameters will be positional. The positional arguments go into
[ArgResults.rest][rest].

```dart
print(results.rest); // ['something', 'else']
```

To stop parsing options as soon as a positional argument is found,
`allowTrailingOptions: false` when creating the [ArgParser][].

## Specifying options

To actually pass in options and flags on the command line, use GNU or POSIX
style. Consider this option:

```dart
parser.addOption('name', abbr: 'n');
```

You can specify its value on the command line using any of the following:

```
--name=somevalue
--name somevalue
-nsomevalue
-n somevalue
```

Consider this flag:

```dart
parser.addFlag('name', abbr: 'n');
```

You can set it to true using one of the following:

```
--name
-n
```

You can set it to false using the following:

```
--no-name
```

Multiple flag abbreviations can be collapsed into a single argument. Say you
define these flags:

```dart
parser
  ..addFlag('verbose', abbr: 'v')
  ..addFlag('french', abbr: 'f')
  ..addFlag('iambic-pentameter', abbr: 'i');
```

You can set all three flags at once:

```
-vfi
```

By default, an option has only a single value, with later option values
overriding earlier ones; for example:

```dart
var parser = new ArgParser();
parser.addOption('mode');
var results = parser.parse(['--mode', 'on', '--mode', 'off']);
print(results['mode']); // prints 'off'
```

If you need multiple values, set the `allowMultiple` parameter. In that case the
option can occur multiple times, and the `parse()` method returns a list of
values:

```dart
var parser = new ArgParser();
parser.addOption('mode', allowMultiple: true);
var results = parser.parse(['--mode', 'on', '--mode', 'off']);
print(results['mode']); // prints '[on, off]'
```

By default, values for a multi-valued option may also be separated with commas:

```dart
var parser = new ArgParser();
parser.addOption('mode', allowMultiple: true);
var results = parser.parse(['--mode', 'on,off']);
print(results['mode']); // prints '[on, off]'
```

This can be disabled by passing `splitCommas: false`.

## Defining commands ##

In addition to *options*, you can also define *commands*. A command is a named
argument that has its own set of options. For example, consider this shell
command:

```
$ git commit -a
```

The executable is `git`, the command is `commit`, and the `-a` option is an
option passed to the command. You can add a command using the [addCommand][]
method:

```dart
var parser = new ArgParser();
var command = parser.addCommand('commit');
```

It returns another [ArgParser][], which you can then use to define options
specific to that command. If you already have an [ArgParser][] for the command's
options, you can pass it in:

```dart
var parser = new ArgParser();
var command = new ArgParser();
parser.addCommand('commit', command);
```

The [ArgParser][] for a command can then define options or flags:

```dart
command.addFlag('all', abbr: 'a');
```

You can add multiple commands to the same parser so that a user can select one
from a range of possible commands. When parsing an argument list, you can then
determine which command was entered and what options were provided for it.

```dart
var results = parser.parse(['commit', '-a']);
print(results.command.name);   // "commit"
print(results.command['all']); // true
```

Options for a command must appear after the command in the argument list. For
example, given the above parser, `"git -a commit"` is *not* valid. The parser
tries to find the right-most command that accepts an option. For example:

```dart
var parser = new ArgParser();
parser.addFlag('all', abbr: 'a');
var command = parser.addCommand('commit');
command.addFlag('all', abbr: 'a');

var results = parser.parse(['commit', '-a']);
print(results.command['all']); // true
```

Here, both the top-level parser and the `"commit"` command can accept a `"-a"`
(which is probably a bad command line interface, admittedly). In that case, when
`"-a"` appears after `"commit"`, it is applied to that command. If it appears to
the left of `"commit"`, it is given to the top-level parser.

## Dispatching Commands

If you're writing a command-based application, you can use the [CommandRunner][]
and [Command][] classes to help structure it. [CommandRunner][] has built-in
support for dispatching to [Command][]s based on command-line arguments, as well
as handling `--help` flags and invalid arguments. For example:

```dart
var runner = new CommandRunner("git", "Distributed version control.")
  ..addCommand(new CommitCommand())
  ..addCommand(new StashCommand())
  ..run(['commit', '-a']); // Calls [CommitCommand.run()]
```

Custom commands are defined by extending the [Command][] class. For example:

```dart
class CommitCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  final name = "commit";
  final description = "Record changes to the repository.";

  CommitCommand() {
    // [argParser] is automatically created by the parent class.
    argParser.addFlag('all', abbr: 'a');
  }

  // [run] may also return a Future.
  void run() {
    // [argResults] is set before [run()] is called and contains the options
    // passed to this command.
    print(argResults['all']);
  }
}
```

Commands can also have subcommands, which are added with [addSubcommand][]. A
command with subcommands can't run its own code, so [run][] doesn't need to be
implemented. For example:

```dart
class StashCommand extends Command {
  final String name = "stash";
  final String description = "Stash changes in the working directory.";

  StashCommand() {
    addSubcommand(new StashSaveCommand());
    addSubcommand(new StashListCommand());
  }
}
```

[CommandRunner][] automatically adds a `help` command that displays usage
information for commands, as well as support for the `--help` flag for all
commands. If it encounters an error parsing the arguments or processing a
command, it throws a [UsageException][]; your `main()` method should catch these and
print them appropriately. For example:

```dart
runner.run(arguments).catchError((error) {
  if (error is! UsageException) throw error;
  print(error);
  exit(64); // Exit code 64 indicates a usage error.
});
```

## Displaying usage

You can automatically generate nice help text, suitable for use as the output of
`--help`. To display good usage information, you should provide some help text
when you create your options.

To define help text for an entire option, use the `help:` parameter:

```dart
parser.addOption('mode', help: 'The compiler configuration',
    allowed: ['debug', 'release']);
parser.addFlag('verbose', help: 'Show additional diagnostic info');
```

For non-flag options, you can also provide a help string for the parameter:

```dart
parser.addOption('out', help: 'The output path', valueHelp: 'path',
    allowed: ['debug', 'release']);
```

For non-flag options, you can also provide detailed help for each expected value
by using the `allowedHelp:` parameter:

```dart
parser.addOption('arch', help: 'The architecture to compile for',
    allowedHelp: {
      'ia32': 'Intel x86',
      'arm': 'ARM Holding 32-bit chip'
    });
```

To display the help, use the [usage][usage] getter:

```dart
print(parser.usage);
```

The resulting string looks something like this:

```
--mode            The compiler configuration
                  [debug, release]

--out=<path>      The output path
--[no-]verbose    Show additional diagnostic info
--arch            The architecture to compile for
      [arm]       ARM Holding 32-bit chip
      [ia32]      Intel x86
```

[posix]: http://pubs.opengroup.org/onlinepubs/009695399/basedefs/xbd_chap12.html#tag_12_02
[gnu]: http://www.gnu.org/prep/standards/standards.html#Command_002dLine-Interfaces
[ArgParser]: http://www.dartdocs.org/documentation/args/latest/index.html#args/args.ArgParser
[ArgResults]: http://www.dartdocs.org/documentation/args/latest/index.html#args/args.ArgResults
[CommandRunner]: http://www.dartdocs.org/documentation/args/latest/index.html#args/command_runner.CommandRunner
[Command]: http://www.dartdocs.org/documentation/args/latest/index.html#args/command_runner.Command
[UsageException]: http://www.dartdocs.org/documentation/args/latest/index.html#args/command_runner.UsageException
[addOption]: http://www.dartdocs.org/documentation/args/latest/index.html#args/args.ArgParser@id_addOption
[addFlag]: http://www.dartdocs.org/documentation/args/latest/index.html#args/args.ArgParser@id_addFlag
[parse]: http://www.dartdocs.org/documentation/args/latest/index.html#args/args.ArgParser@id_parse
[rest]: http://www.dartdocs.org/documentation/args/latest/index.html#args/args.ArgResults@id_rest
[addCommand]: http://www.dartdocs.org/documentation/args/latest/index.html#args/args.ArgParser@id_addCommand
[getUsage]: http://www.dartdocs.org/documentation/args/latest/index.html#args/args.ArgParser@id_getUsage
[addSubcommand]: http://www.dartdocs.org/documentation/args/latest/index.html#args/command_runner.Command@id_addSubcommand
[run]: http://www.dartdocs.org/documentation/args/latest/index.html#args/command_runner.Command@id_run
