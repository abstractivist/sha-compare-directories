#!/bin/bash
#
# This script takes the input of two paths to compare their files via their checksums.
# If it finds differences, another file "copy_all.sh" will be created in "output" that contains the
# copy instructions from 'path1' to 'path2'. This script looks at a common path prefix under the 
# provided paths and assumes that the common path prefix starts at the third directory down.
# The script assumes a comparison across something like: "/Volumes/Vol1/path/to/files/" and
# "/Volumes/Vol2/path/to/files/" with the list of files within having the same names but potentially
# different contents.
# This is work in progress and there is currently a fair bit of redundant debug output.

# Escape path function
escape_path() {
  printf '%q' "$1"
}

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 path1 path2"
  exit 1
fi

# temporary directory; must end on /
tmpdir=~/Downloads/

mkdir -p "${tmpdir}output"

# create an empty copy script
copy_script="copy_all.sh"
copy_script="${tmpdir}output/${copy_script}"
> $copy_script
chmod +x "$copy_script"

mismatchfile="mismatches.csv"

# create file names to store the results in; use the full path name as the file name
sha_file_list1="${tmpdir}output/$(echo $1 | sed 's/\//_/g').txt"
sha_file_list2="${tmpdir}output/$(echo $2 | sed 's/\//_/g').txt"

# find all files and output their SHA sum and their full path
echo "starting: find files and their SHA sums in $1"
find "$1" -type f -exec shasum {} \; | sort -k 2 | tee "$sha_file_list1" | pv -i 1 -s $(find "$1" -type f | tr -cd '\0' | wc -c) -N "Processing files..."
echo "starting: find files and their SHA sums in $2"
find "$2" -type f -exec shasum {} \; | sort -k 2 | tee "$sha_file_list2" | pv -i 1 -s $(find "$2" -type f | tr -cd '\0' | wc -c) -N "Processing files..."

# ask for input to continue
read -n 1 -r -s -p $'SHA sums and file lists created. Check output and press any key to continue...\n'

# now start comparing the outputs for differences; the SHA sum should be 40 chars long and the path
# should start at character 43.
while IFS= read -r line1 <&3 && IFS= read -r line2 <&4; do  # IFS=, ?
  sha1=${line1:0:40}
  echo "sha1: $sha1"
  sha2=${line2:0:40}
  echo "sha2: $sha2"
  path1="${line1:42}"
  echo "path1: $path1"
  path2="${line2:42}"
  echo "path2: $path2"

  common_prefix1=$(echo "${path1}" | awk -F/ 'BEGIN{OFS="/"} {for(i=4;i<=NF-1;i++) if ($i != "") {printf("%s/",$i)}}')
  echo "common_prefix1: $common_prefix1"
  common_prefix2=$(echo "${path2}" | awk -F/ 'BEGIN{OFS="/"} {for(i=4;i<=NF-1;i++) if ($i != "") {printf("%s/",$i)}}')
  echo "common_prefix2: $common_prefix2"

  echo "common_prefix1&filename1: ${common_prefix1}${path1##*/}"
  echo "common_prefix2&filename2: ${common_prefix2}${path2##*/}"
  
  # compare relative paths and file names
  if [ "${common_prefix1}${path1##*/}" == "${common_prefix2}${path2##*/}" ]; then
    # compare SHA sums
    if [ "${sha1}" != "${sha2}" ]; then
        # add copy command to copyfile
        # echo "mkdir -p \"${path1%/*}\" && cp -p \"${path1}\" \"${common_prefix}\"" >> output/copy_all.sh
        echo "cp -p $(escape_path "$path1") $(escape_path "$path2")" >> "$copy_script"
    fi
  else
    # add line to mismatchfile
    echo "\"$path1\";\"$path2\"" >> "${tmpdir}output/${mismatchfile}"
  fi

  # ask for input to continue
  # read -n 1 -r -s -p $'Press any key to continue...\n'

done 3<"$sha_file_list1" 4<"$sha_file_list2"
