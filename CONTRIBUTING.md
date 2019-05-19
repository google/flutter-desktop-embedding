# How to Contribute

We'd love to accept your patches and contributions to this project. There are
just a few small guidelines you need to follow.

## Contributor License Agreement

Contributions to this project must be accompanied by a Contributor License
Agreement. You (or your employer) retain the copyright to your contribution,
this simply gives us permission to use and redistribute your contributions as
part of the project. Head over to <https://cla.developers.google.com/> to see
your current agreements on file or to sign a new one.

You generally only need to submit a CLA once, so if you've already submitted one
(even if it was for a different project), you probably don't need to do it
again.

## Code reviews

All submissions, including submissions by project members, require review. We
use GitHub pull requests for this purpose. Consult
[GitHub Help](https://help.github.com/articles/about-pull-requests/) for more
information on using pull requests.

## Project Standards

- C++ code should follow
  [Google's C++ style guide](https://google.github.io/styleguide/cppguide.html).
- Objective-C code should follow
  [Google's Objective-C style guide](http://google.github.io/styleguide/objcguide.html).
- For C++ and Objective-C code, please run `clang-format -style=file` on files
  you have changed if possible. If you don't have `clang-format`, don't worry;
  a project member can do it prior to submission.
- Dart code should follow the
  [Dart style guide](https://www.dartlang.org/guides/language/effective-dart/style)
  and use `dartfmt`.
- Build scripts and other tooling should be written in Dart. (Some existing
  scripts are `bash` or `.bat` scripts; if you need to make non-trivial changes
  to one of those scripts, please convert it to Dart first if possible.)
