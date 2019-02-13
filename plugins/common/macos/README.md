# Shared Flutter Framework Fetcher

This project exists only to avoid having each plugin fetch its own copy of the
Flutter framework. Ideally in the future FlutterMacOS.framework will become
part of the Flutter SDK itself, and there will be no need to fetch it.

If you make your own standalone plugins there is no need to depend on this
project; you can manage the dependency on FlutterMacOS.framework however you
like.
