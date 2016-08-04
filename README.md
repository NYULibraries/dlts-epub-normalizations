DLTS EPUB Normalization
=======================

Bash script for performing a minimum set of normalizations on a collection of EPUBs.

The normalizations:

* OPF file:
  * Change incorrect `<?xml version="1.1"?>` to correct `<?xml version="1.0"?>`.
    Motivation: [readium-js-viewer issue - Some browsers do not support <?xml version="1.1"?> tag #467](https://github.com/readium/readium-js-viewer/issues/467)
  * Remove `linear="no"` from any spine items in OPF files.
    Motivation: have every single page in our books display in the default view of our
    current version of ReadiumJS viewer.  Sometimes the cover spine item has `linear="no"`
    attribute, which prevents it from loading when user first opens the book.

## Getting Started

```shell
$ bin/epub-normalizations.sh -h

usage: epub-normalizations.sh -s SOURCE_DIR -u UNZIPPED_DESTINATION_DIR -z ZIPPED_DESTINATION_DIR
    options:
        -h                           Print this help message.
        -s SOURCE_DIR                Path to source EPUB files.  Cannot be the same as
                                         UNZIPPED_DESTINATION_DIR or ZIPPED_DESTINATION_DIR.
        -u UNZIPPED_DESTINATION_DIR  Path to unzipped EPUB files destination directory.
        -z ZIPPED_DESTINATION_DIR    Path to zipped EPUB files destination directory.
```

The script does the following:

* For a clean start, deletes everything in `UNZIPPED_DESTINATION_DIR`,
`ZIPPED_DESTINATION_DIR`, and the work directory, `tmp/`.
* Unzips all `*.epub` files from `SOURCE_DIR` into `tmp/`.
* Initializes a git repo in `tmp/` and checks in everything for later
comparision with the final, normalized EPUB content.
* Does normalizations in-place in `tmp/`.  The edits of the OPF file are done using
Perl substitutions.  Since the XML is not being parsed, this is not 100% foolproof,
but seems to work well enough so far.
* Verifies the changes:
  * Does `git add .` followed by `git diff --cached -M95%` with output redirected into
a file for analysis.  This diff command will follow file/directory renamings,
using a 95% similarity index threshold.  If more normalizations are added to this script
in the future, this threshold may need to be decreased.
  * The diff file is checked for any unexpected differences, i.e. any changes that
 were not the result of a correctly performed normalization.  This check is not
 100% foolproof, but again, it seems to work well enough so far.
* EPUB directories in `tmp/` are zipped into *.epub files in ZIPPED_DESTINATION_DIR.
* EPUB directories are copied to UNZIPPED_DESTINATION_DIR.
* The zipped EPUBs are then verified to make sure the zipping was done correctly:
  * *.epub files in ZIPPED_DESTINATION_DIR are copied into `tmp/zipped-epub-verification-dir`.
  * A `diff -r` is performed against `tmp/zipped-epub-verification-dir` and UNZIPPED_DESTINATION_DIR.

### Prerequisites

* bash
* git
* grep
* perl

### Examples

Normalize UMich Press EPUBs that have been stored in our private zipped EPUBs repo
and cloned locally to `~/Documents/epubs/`.  The new zipped EPUBs are to replace the
originals here, but this must be done manually by the user after the script has run.
The unzipped content will be copied to our private `epub_content` repo,
cloned locally to `~/Documents/epub-content/`.

```
# Zipped EPUBs destination cannot be the same as source.
$ mkdir ~/Documents/epubs/epub/umich-press-new

# Do normalizations, outputting zipped EPUBs to new (temporary) destination directory,
# and unzipped EPUB directories to the `epub_content` repo.
$ bin/epub-normalizations.sh -s ~/Documents/epubs/epub/umich-press/     \
                             -z ~/Documents/epubs/epub/umich-press-new/ \
                             -u ~/Documents/epub-content/umich-press/

# Remove old source EPUBs and copy in new ones.
$ rm ~/Documents/epubs/epub/umich-press/*
$ mv ~/Documents/epubs/epub/umich-press-new/* ~/Documents/epubs/epub/umich-press/
$ rmdir ~/Documents/epubs/epub/umich-press-new

# Commit new files in both destination repos.
cd ~/Documents/epubs/epub/umich-press/
git add .
git commit -m "epub/umich-press/: minimum set of normalizations"

cd ~/Documents/epub-content/umich-press/
git add .
git commit -m "umich-press/: minimum set of normalizations"
```

### Notes

This script was developed and tested on a Mac OS X 10.10.5 machine with:

* bash 4.3.42
* git 2.7.1
* grep 2.5.1-FreeBSD
* perl 5.22.0