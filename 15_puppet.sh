#!/bin/bash
#
# Pre-receive hook that validates puppet syntax and erb templates
#
# Created by Kami Gerami <kami.gerami@gmail.com>
# 2016-08-03
#

cat <<EOF 
################################################# 
#Validating puppet syntax and erb template files#
#################################################
EOF


COMMAND='puppet parser validate'
TEMPDIR=`mktemp -d`


validate_ref()
{
	oldrev="$1"
	newrev="$2"
	refname="$3"


          # Get file names with directory path of modified files
          for file in $(git diff --name-only --diff-filter=AM ${oldrev} ${newrev})
	  do
            # Store blob as ojbect var
            object=$(git ls-tree --full-name -r ${newrev} | egrep "(\s)${file}\$" | awk ' { print $3 }')

            # validate or go to next iteration
            if [ -z ${object} ]; 
            then 
	      continue; 
	    fi

            # Otherwise, create all the necessary sub directories in the new temp directory
            mkdir -p "${TEMPDIR}/`dirname ${file}`" &>/dev/null
            # and output the object content into it's original file name
            git cat-file blob ${object} > ${TEMPDIR}/${file}

           # Now validate the files
	   case $file in
	     *.pp)
                # validate puppet syntax
		${COMMAND} ${TEMPDIR}/${file} &>/dev/null
		if [[ $? -ne 0 ]]; then
		  echo "" 
                  echo "Puppet syntax error in ${file}: "
		  OUTPUT=$(${COMMAND} ${TEMPDIR}/${file}) 
                  echo $OUTPUT | sed -e "s#$TEMPDIR/\(.*\).*err: Try.*usage#\1#g"
		  echo "" 
		  fail=1
		fi
	     ;;
	     *.erb)
		erb -P -x -T - "${TEMPDIR}/${file}" | ruby -c  &>/dev/null
		if [[ $? -ne 0 ]]; then
		  echo ""
                  echo "ERB syntax error in ${file}: "
		  OUTPUT=$(erb -P -x -T - ${TEMPDIR}/${file} | ruby -c)
		  echo "$OUTPUT" 
		  echo "" 
		  fail=1
		fi
	      ;;
	   esac
          done 
}
while read oldrev newrev refname
do
	validate_ref $oldrev $newrev $refname
        fail=1
done


if [ -n "$fail" ]; then
	exit $fail
else
        echo -e "Syntax OK\n"
fi
