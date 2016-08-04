function make-epub-from-dir() {
    local epub_content_dir=$1
    local epub_file=$2

    # Necessary because relative paths lose meaning after we cd into $epub_content_dir
    epub_file_absolute_path=$(cd "$(dirname "${epub_file}")" ; pwd -P )/$(basename "${epub_file}")

    original_cwd=$(pwd)

    cd $epub_content_dir
    zip -X0 $epub_file_absolute_path mimetype
    zip -Xur9D $epub_file_absolute_path *

    cd $original_cwd
}
