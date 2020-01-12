#!/bin/sh

export PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin" ;

script="$(basename "$(test -L "${0}" && readlink "${0}" || echo "${0}")")" ;
pidfile="/var/run/`basename ${0}`.pid" ;

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
        echo "-z | --gzip :: compress dump using gzip"
        echo "-x | --xz :: compress dump using xz"
        echo "-m | --master :: set master data"
        echo "-q | --quiet :: silent mode"
        echo "--pid-file :: pid file default ${pidfile}"
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
	    -z | --gzip )           gzip=1
                                ;;
        -x | --xz )             xz=1
                                ;;
        -m | --master )         master=1
	    -q | --quiet )		    quiet=1
				                ;;
        --pid-file )		    shift
                                pidfile=${1}
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

if [ "${dir}" = "" ] || [ ! -d ${dir} ] ; then

	error "Directory '${dir}' does not exists!" ;
	exit 1 ;
fi

if [ -s ${pidfile} ] ; then
    
    error "ERROR: `hostname` script ${script} already running! Pid file \"${pidfile}\" exists!" ;
	exit 1 ;
fi

trap "rm -f ${pidfile} ;" EXIT INT KILL TERM SIGKILL SIGTERM;

echo $$ > ${pidfile} ;

mysqlparams="   --all-databases \
                --add-drop-database \
                --add-drop-table \
                --add-drop-trigger \
                --triggers \
                --add-locks \
                --create-options \
                --complete-insert \
                --extended-insert \
                --allow-keywords \
                --default-character-set=utf8mb4 \
                --dump-date \
                --events \
                --routines \
                --quote-names \
                --flush-privileges \
                --comments \
                --quick \
                --force \
                --ignore-table=mysql.slow_log \
                --log-error=/var/log/mysqldump.log" ;

if [ "${singletrans}" ] ; then
    mysqlparams="${mysqlparams} --single-transaction" ;
fi

if [ "${lock}" ] ; then
    mysqlparams="${mysqlparams} --lock-all-tables" ;
fi

if [ "${master}" ] ; then
    mysqlparams="${mysqlparams} --master-data --include-master-host-port --apply-slave-statements" ;
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
	echo "Starting database dump (`date +\"%H:%M:%S\"`)" ;
fi

date=`date +"%y%m%d.%H%M%S"` ;


dump_file_name="${dir}/${prefix}.${date}.sql" ;

mysqldump ${mysqlparams} > ${dump_file_name} ;

if [ "${gzip}" ] ; then

	if [ ! "${quiet}" ] ; then
        echo "Compressing dump by gzip (`date +\"%H:%M:%S\"`)..." ;
	fi

	gzip ${dump_file_name} ;
else 
    if  [ "${xz}" ] ; than

        if [ ! "${quiet}" ] ; then
            echo "Compressing dump by xz (`date +\"%H:%M:%S\"`)..." ;
        fi

        xz ${dump_file_name} ;
    fi
fi

if [ ! "${quiet}" ] ; then
    echo "Dump completed (`date +\"%H:%M:%S\"`)..." ;
fi

rm -f ${pidfile} ;

exit 0 ;