# sha-compare-directories
compare two directories with checksums

This script takes the input of two paths to compare their files via their checksums. With not sufficient parameters provided it prints out a small help text.

If it finds differences, another file "copy_all.sh" will be created in an "output" directory that contains the copy instructions from 'path1' to 'path2'. This script looks at a common path prefix under the provided paths and assumes that the common path prefix starts at the third directory down. This is useful to verify `rsync` copies from one drive on macOS to another where the drive is mounted under /Volume/drive1 or /Volume/drive2.

For efficiency reasons when comparing files, I opted for a file's SHA sum over `diff`. It's only necessary to know that files differ, not where.

The script assumes a comparison across something like: "/Volumes/Vol1/path/to/files/" and "/Volumes/Vol2/path/to/files/" with the list of files within having the same names but potentially different contents.

To guard against accidential overwrites and to verify files before they're copied, the copy command (`cp -p`) is output to a separate script, copy_all.sh.

Differnces, if they exist, are logged in a file "mismatchs.csv" file. Often, the sheer existence of this file should account for restarting `rsync` again.

This is work in progress and there is currently a fair bit of redundant debug output.
