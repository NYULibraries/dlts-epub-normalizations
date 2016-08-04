function fix-package-file-xml-version() {
    local package_file=$1

    echo "[ INFO ]: changing wrong 'version=\"1.1\"' to 'version=\"1.0\"' for ${package_file}"

    perl -pi -e 's/version="1.1"/version="1.0"/g' $package_file
}

function remove-linear-equals-no-from-package-file() {
    local package_file=$1

    echo "[ INFO ]: removing 'linear=\"no\"' from ${package_file}"

    perl -pi -e 's/ linear="no"//g' $package_file
}

function remove-linear-no-and-fix-xml-version() {
    local process_dir=$1
    local package_file=$(find $process_dir -name *.opf)

    if [ ! -e $package_file ]; then
        echo "[ ERROR ]: package file not found for ${source_epub}.  Skipping."
        continue
    fi

    echo "[ INFO ]: package file - $package_file"

    remove-linear-equals-no-from-package-file $package_file
    fix-package-file-xml-version $package_file
}

function rename-epub-content-directories() {
    local process_dir=$1

    local REQUIRED_CONTENT_DIR_NAME='ops'

    # Try and find the content directory.  Possibilities:
    #     * OEBPS - both lowercase and uppercase
    #     * OPS   - both lowercase and uppercase
    local content_dir=$(find $process_dir -type d -name OEBPS)
    if [ -z $content_dir ]; then content_dir=$(find $process_dir -type d -name oebps); fi
    if [ -z $content_dir ]; then content_dir=$(find $process_dir -type d -name OPS); fi
    if [ -z $content_dir ]; then content_dir=$(find $process_dir -type d -name ops); fi

    if [ -z $content_dir ]
    then
        echo "[ ERROR ]: content directory not found for ${source_epub}.  Skipping."
        continue
    fi

    echo "[ INFO ]: content_dir = ${content_dir}"

    if [ "$(basename $content_dir)" != "${REQUIRED_CONTENT_DIR_NAME}" ]
    then
        new_content_dir=$(dirname $content_dir)/${REQUIRED_CONTENT_DIR_NAME}
        mv_cmd="mv ${content_dir} ${new_content_dir}"
        echo "[ INFO ] ${mv_cmd}"
        eval $mv_cmd
    fi
}
