#!/bin/sh

export PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin" ;

script="$(basename "$(test -L "${0}" && readlink "${0}" || echo "${0}")")" ;
mypidfile="/var/run/`basename ${0}`.pid" ;

usage()
{
        echo "Usage: mysql_backup.sh -d /var/backup -n daily [-c 10 -s -a -e test@domain.org]"
	    echo
       	echo "-d | --dir :: backup directory"
	    echo "-n | --name :: backup name"
        echo "-c | --copies :: number of copies to store (default 10)"
        echo "-e | --email :: notification email"
       	echo "-l | --lock-all-tables"
       	echo "-s | --single-transaction"
        echo "-z | --compress :: gzip dump"
        echo "-q | --quiet :: silent mode"
        echo "-h | --help :: display this help"
}

error()
{

    echo -e "\033[0;31m${1}\e[00m" ;
    if ! [ "${email}" = "" ] ; then
        echo "ERROR: `hostname`, ${script}: ${1}" | mail -s "'ERROR: `hostname`, ${script}: ${1}'" ${email} ;
    fi
}

while [ "${1}" != "" ]; do
    case ${1} in
        -d | --dir )            shift
                                dir=${1}
                                ;;
	    -n | --name )		    shift
                               	name=${1}
                               	;;
       	-c | --copies )         shift
                                copies=${1}
                                ;;
	    -e | --email )          shift
                                email=${1}
                                ;;
        -l | --lock-all-tables ) 
                                lock=1
                                ;;
	    -s | --single-transaction ) 
                                singletrans=1
                                ;;
	    -z | --compress )       compress=1
                                ;;
	    -q | --quiet )		    quiet=1
				                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

if [ "${copies}" = "" ] || [ ! -n "${copies}" ] || [ "${copies}" -le "0" ] ;
then
	copies=10
fi


if ! [ -d ${dir} ] ; then

	error "Directory '${dir}' does not exists!" ;
	exit 1 ;
fi

if [ -s ${mypidfile} ] ; then
    
    error "ERROR: `hostname` script ${script} already running!" ;
	exit 1 ;
fi

trap "rm -f ${mypidfile} ;" EXIT INT KILL TERM SIGKILL SIGTERM;

echo $$ > ${mypidfile} ;

mysqlparams="   --all-databases \
                --add-drop-database \
                --add-drop-table \
                --add-drop-trigger \
                --add-locks \
		        --compact \
		        --disable-keys \
                --apply-slave-statements \
                --allow-keywords \
                --complete-insert \
                --create-options \
                --default-character-set=UTF8 \
                --dump-date \
                --events \
                --extended-insert \
                --flush-privileges \
                --master-data \
                --include-master-host-port \
                --quick \
                --quote-names \
                --routines \
                --triggers \
                --force \
		        --max-allowed-packet=128M \
                --log-error=/var/log/mysqldump.log" ;

if [ "${singletrans}" ] ; then
    mysqlparams="${mysqlparams} --single-transaction" ;
fi

if [ "${lock}" ] ; then
    mysqlparams="${mysqlparams} --lock-all-tables" ;
fi

prefix="mysqldump.`hostname -s`.${name}" ;

if [ `ls ${dir} | grep ${prefix} | wc -l` -ge "${copies}" ] ; then
	i=1;
	for filename in `ls ${dir} | grep ${prefix} | sort -r` ; do
		if [ "${i}" -ge "${copies}" ] ; then
			rm "${dir}/${filename}" ;
		fi
		i=$(expr $i + 1)
	done
fi

if [ ! "${quiet}" ] ; then
	echo "Starting database dump (`date +\"%Y-%m-%d %H:%M:%S\"`)" ;
fi

date=`date +"%y%m%d.%H%M%S"` ;


dump_file_name="${dir}/${prefix}.${date}.sql" ;

mysqldump ${mysqlparams} > ${dump_file_name} ;

if [ "${compress}" ] ; then

	if [ ! "${quiet}" ] ; then
        echo "Compressing dump (`date +\"%Y-%m-%d %H:%M:%S\"`)..." ;
	fi

	gzip ${dump_file_name} ;
fi

rm -f ${mypidfile} ;

exit 0 ;