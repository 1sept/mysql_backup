#!/bin/sh
# Dumping mysql database in current folder
# Usage: ${0} databse1 [database2 database3 database4 ...]


export PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin" ;

if [ -z "${1}" ] ; then

	echo "Error: no database name given!" ;
	echo
	echo "Usage: ${0} databse1 [database2 database3 database4 ...]"
	exit 1 ;
fi

param="	--lock-tables \
 		--add-drop-trigger \
		--triggers --routines --events \
        --add-locks \
		--skip-add-drop-table \
        --create-options \
        --complete-insert \
        --extended-insert \
        --allow-keywords \
        --default-character-set=utf8mb4 \
        --dump-date \
        --quote-names \
        --comments \
        --quick \
		--set-gtid-purged=OFF \
        --force"

while [ "${1}" != "" ]; do
	echo
	echo "Starting '${1}' database dump..." ;

	filename="mysqldump.${1}.`hostname -s`.`date +\"%y%m%d.%H%M%S\"`.sql" ;

	if [ -f filename ] ; then
        	echo "Database ${1} dump not completed! File ${filename} allready exists!"
		exit 1 ;
	fi

	if ! mysqldump ${1} ${param} > ${filename} ; then
		echo "Database ${1} dump not completed!" ;
		rm ${filename} ;
		exit 1 ;
	else
		echo "Compressing dump..."
		xz -T2 ${filename} ;
		echo "Database ${1} dump successful completed. ('${filename}.xz')" ;
	fi
	shift
done

exit 0