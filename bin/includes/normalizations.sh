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

