#!/bin/bash
#
# Pre-receive hook that looks for tabs and trailing whitespaces
# in the diffed file
#
# Created by Kami Gerami <kami.gerami@gmail.com>
# 2016-08-03
#
cat <<EOF 
#####################################################
#Looking for trailing whitespaces and tab characters#
#####################################################
EOF

validate_ref()
{
	oldrev="$1"
	newrev="$2"
	refname="$3"

        fail=""

          # Get file names with directory path of modified files
          for file in $(git diff --name-only --diff-filter=AM ${oldrev} ${newrev})
	  do
            object="$(git ls-tree --full-name -r ${newrev} | egrep "(\s)${file}\$" | awk ' { print $3 }')"
           # Now validate the files
	   case $file in
	     *.pp|*.py|*.txt|*.pl)
                  
                # look for tabs
                git diff -U0 $oldrev $newrev -- $file | grep  $'^+.*\t.*' &>/dev/null
                if [[ $? -eq 0 ]]; then
                  echo -e "$file contains tab character:\n"
                  echo "$(git diff -U0 $oldrev $newrev -- $file | grep -v $'^-.*' | grep $'^+.*\t.*' -B1)"
                  echo -e "\n"
                  fail=1
                fi
                # look for spaces
                git diff -U0 $oldrev $newrev -- $file | grep $'^+.* [[:space:]]$' &>/dev/null
                if [[ $? -eq 0 ]]; then  
                  echo -e "$file contains lines with trailing whitespace:\n"
                  echo "$(git diff -U0 $oldrev $newrev -- $file | grep -v $'^-.*' | grep $'^+.* [[:space:]]$' -B1)"
                  echo -e "\n"
                  fail=1
                fi
               ;;
	   esac
          done 
}
while read oldrev newrev refname
do
	validate_ref $oldrev $newrev $refname
done


if [ -n "$fail" ]; then
	exit $fail
else
        echo -e "Syntax OK\n"
fi
