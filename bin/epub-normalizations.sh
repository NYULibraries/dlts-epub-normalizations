#!/bin/bash

function usage() {
    script_name=$(basename $0)

    cat <<EOF

usage: ${script_name} -s SOURCE_DIR -u UNZIPPED_DESTINATION_DIR -z ZIPPED_DESTINATION_DIR
    options:
        -h                           Print this help message.
        -s SOURCE_DIR                Path to source EPUB files.  Cannot be the same as
                                         UNZIPPED_DESTINATION_DIR or ZIPPED_DESTINATION_DIR.
        -u UNZIPPED_DESTINATION_DIR  Path to unzipped EPUB files destination directory.
        -z ZIPPED_DESTINATION_DIR    Path to zipped EPUB files destination directory.
EOF
}

BASEDIR=$(dirname $( cd "$(dirname "$0")" ; pwd -P ) )
INCLUDES_DIR=$BASEDIR/bin/includes

source $INCLUDES_DIR/normalizations.sh
source $INCLUDES_DIR/util.sh

while getopts hs:u:z: opt
do
    case $opt in
        h) usage; exit 0 ;;
        s) source_epubs_dir=$OPTARG ;;
        u) unzipped_destination_dir=$OPTARG ;;
        z) zipped_destination_dir=$OPTARG ;;
        *) echo >&2 "Options not set correctly."; usage; exit 1 ;;
    esac
done

# Validate dirs
if [ -z $source_epubs_dir ] || [ ! -d $source_epubs_dir ]; then
    echo >&2 "'${source_epubs_dir}' is not a valid source directory."
    usage
    exit 1
fi

if [ -z $unzipped_destination_dir ] || [ ! -d $unzipped_destination_dir ]; then
    echo >&2 "'${unzipped_destination_dir}' is not a valid unzipped EPUBs destination directory."
    usage
    exit 1
fi

if [ -z $zipped_destination_dir ] || [ ! -d $zipped_destination_dir ]; then
    echo >&2 "'${zipped_destination_dir}' is not a valid zipped EPUBs destination directory."
    usage
    exit 1
fi

# Get absolute paths for dirs
source_epubs_dir=$(cd "${source_epubs_dir}" ; pwd -P )
unzipped_destination_dir=$(cd "${unzipped_destination_dir}" ; pwd -P )
zipped_destination_dir=$(cd "${zipped_destination_dir}" ; pwd -P )

echo "[ INFO ]: source_epubs_dir=${source_epubs_dir}"
echo "[ INFO ]: unzipped_destination_dir=${unzipped_destination_dir}"
echo "[ INFO ]: zipped_destination_dir=${zipped_destination_dir}"

# Abort if source EPUBs dir is the same as either zipped or unzipped destination dirs,
# because they get cleaned completely.
if [ $source_epubs_dir == $unzipped_destination_dir ] || [ $source_epubs_dir == $zipped_destination_dir ]
then
    echo -e "\n[ ERROR ]: SOURCE_DIR cannot be the same as UNZIPPED_DESTINATION_DIR or ZIPPED_DESTINATION_DIR."
    usage
    exit 1
fi

TMP=$BASEDIR/tmp

# Clean
rm -fr $TMP/*; rm -fr $TMP/.git
rm -fr $unzipped_destination_dir/*
rm -f $zipped_destination_dir/*

# Unzip EPUB files into temp directory.
for source_epub in ${source_epubs_dir}/*.epub
do
    epub_name=$(basename $source_epub .epub)

    process_dir=${TMP}/${epub_name}

    unzip_cmd="unzip -d ${process_dir} ${source_epub}"
    echo "[ INFO ]: ${unzip_cmd}"
    eval $unzip_cmd
done

# Create (temporary) git repo, and commit for later
# comparison with normalized files.
echo "[ INFO ]: setting up git repo and committing originals."
cd $TMP
git init
git add *
git commit -m 'Originals'

# Do the normalizations
for source_epub in ${source_epubs_dir}/*.epub
do
    epub_name=$(basename $source_epub .epub)

    echo "[ INFO ]: processing ${source_epub}"

    process_dir=${TMP}/${epub_name}

    remove-linear-no-and-fix-xml-version $process_dir

    rename-epub-content-directories $process_dir
done

# Verify changes.  This is not foolproof, but it is a decent check.
# First, need to tell git that directories have been renamed.
DIFF_FILTERS_FILE=$INCLUDES_DIR/diff-filters.txt
GIT_DIFF_FILE=$TMP/git-diff.txt
cd $TMP
git add .
# Similarity of 95% seems to be a good threshold.
git diff --cached -M95% > $GIT_DIFF_FILE
git_diff_after_filtering_out_normalizations=$( egrep '^-|^\+' $GIT_DIFF_FILE | egrep -v -f $DIFF_FILTERS_FILE )

if [ -z $git_diff_after_filtering_out_normalizations ]
then
    echo "[ INFO ]: no unexpected differences between original and normalized EPUB content were found."
else
    echo "[ ERROR ]: unexpected differences between original and normalized EPUB content were found -- see git-diff.txt.  Will not create destination EPUBs."
    exit 1
fi

# Zip and/or copy to destination directories.
for source_epub in ${source_epubs_dir}/*.epub
do
    epub_name=$(basename $source_epub .epub)

    process_dir=${TMP}/${epub_name}

    zipped_destination_epub=${zipped_destination_dir}/${epub_name}.epub
    echo "[ INFO ]: zipping ${process_dir} into ${zipped_destination_epub}"
    make-epub-from-dir $process_dir $zipped_destination_epub

    unzipped_destination_epub=${unzipped_destination_dir}/${epub_name}

    cp_cmd="cp -pr ${process_dir} ${unzipped_destination_epub}"
    echo "[ INFO ]: ${cp_cmd}"
    eval $cp_cmd
done

# Do final verification of destination directories.  Check that their contents match.
ZIPPED_EPUB_VERIFICATION_DIR=$TMP/zipped-epub-verification-dir

mkdir $ZIPPED_EPUB_VERIFICATION_DIR

echo "[ INFO ]: verifying destination directories.  Unzipping destination *.epub files."
for epub in $zipped_destination_dir/*
do
    verification_dir=$ZIPPED_EPUB_VERIFICATION_DIR/$( basename $epub .epub )

    unzip_cmd="unzip -d ${verification_dir} ${epub}"
    echo "[ INFO ]: ${unzip_cmd}"
    eval $unzip_cmd

done

diff_cmd="diff -r $ZIPPED_EPUB_VERIFICATION_DIR $unzipped_destination_dir"
echo "[ INFO ]: ${diff_cmd}"
diff_verification_vs_unzipped=$( ${diff_cmd} )

if [ -z $diff_verification_vs_unzipped ]
then
    echo "[ INFO ] no content differences between ${zipped_destination_dir} and ${unzipped_destination_dir} found."
else
    echo "[ ERROR ] content differences between ${zipped_destination_dir} and ${unzipped_destination_dir} found."
fi
