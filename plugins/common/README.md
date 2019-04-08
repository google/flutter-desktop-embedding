# Shared Flutter Library Fetcher

This directory exists only to avoid having each plugin fetch its own copy of
the Flutter library. Ideally in the future the library will become
part of the Flutter SDK itself, and there will be no need to fetch it.

If you make your own standalone plugins there is no need to depend on this
directory; you can manage the dependency on the library however you
like.
