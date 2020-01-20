#!/bin/sh
#
# MySQL backup script
# Set authorisation and host paramethers in homedir .my.cnf param. Read README.md
#

usage()
{
        echo "Usage: mysql_backup.sh -d /var/backup -n daily [-c 10 -s -x --xz-threads=6 -e test@domain.org]"
	    echo
       	echo "-d | --dir :: backup directory"
	    echo "-n | --name :: backup name"
        echo "-c | --copies :: number of copies to store (default: 10)"
        echo "-e | --email :: notification email"
       	echo "-l | --lock-all-tables"
       	echo "-s | --single-transaction"
        echo "-z | --gzip :: compress dump using gzip"
        echo "-x | --xz :: compress dump using xz"
        echo "--xz-threads :: number of worker threads to use by xz. 0 - use all CPU. (default: 2)"
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

export PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin" ;

script="$(basename "$(test -L "${0}" && readlink "${0}" || echo "${0}")")" ;
pidfile="/tmp/`basename ${0}`.pid" ;

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
                --log-error=/tmp/mysqldump.log" ;


while [ "${1}" != "" ]; do
    case ${1} in
        -d | --dir )            shift
                                dir=${1} ;
                                ;;
	    -n | --name )		    shift
                               	name=${1} ;
                               	;;
       	-c | --copies )         shift
                                copies=${1} ;
                                ;;
	    -e | --email )          shift
                                email=${1} ;
                                ;;
        -l | --lock-all-tables ) 
                                mysqlparams="${mysqlparams} --lock-all-tables" ;
                                ;;
	    -s | --single-transaction ) 
                                mysqlparams="${mysqlparams} --single-transaction" ;
                                ;;
	    -z | --gzip )           gzip=1 ;
                                ;;
        -x | --xz )             xz=1 ;
                                ;;
        --xz-threads )          shift
                                xzthreads=${1}
                                ;;
        -m | --master )         mysqlparams="${mysqlparams} --master-data --include-master-host-port --apply-slave-statements" ;
                                ;;
	    -q | --quiet )		    quiet=1
				                ;;
        --pid-file )		    shift
                                pidfile=${1}
                                ;;
        -h | --help )           usage ;
                                exit ;
                                ;;
        * )                     
                                echo "Uncnown option ${1}!" ;
                                usage ;
                                exit 1 ;
    esac
    shift
done

if [ "${copies}" = "" ] || [ ! -n "${copies}" ] || [ "${copies}" -le "0" ] ;
then
	copies=10 ;
fi

if [ "${xzthreads}" = "" ] || [ ! -n "${xzthreads}" ] || [ "${xzthreads}" -lt "0" ] ;
then
	xzthreads=2 ;
fi

if [ "${dir}" = "" ] || [ ! -d ${dir} ] ; then

	error "Directory '${dir}' does not exists!" ;
	exit 1 ;
fi

# sleep random 1-6 sec for crone
sleep `shuf -i0-9 -n1` ;

if [ -s ${pidfile} ] ; then
    
    error "ERROR: `hostname` script ${script} already running! Pid file \"${pidfile}\" exists!" ;
	exit 1 ;
fi

trap "rm -f ${pidfile} ;" EXIT INT KILL TERM SIGKILL SIGTERM SIGHUP ERR ;

echo $$ > ${pidfile} ;

prefix="mysqldump.`hostname -s`.${name}";

if [ `ls -t ${dir} | grep ${prefix}` -ge "${copies}" ] ; then
	
    i=1 ;
	
    for filename in `ls ${dir} | grep ${prefix} | sort -r` ; do
		if [ "${i}" -ge "${copies}" ] ; then
			rm "${dir}/${filename}" ;
		fi
		i=$(expr $i + 1) ;
	done

fi

if [ ! "${quiet}" ] ; then
	echo "Starting database dump (`date +\"%H:%M:%S\"`)" ;
fi

dump_file_name="`realpath ${dir}`/${prefix}.`date +\"%y%m%d.%H%M%S\"`.sql" ;

mysqldump ${mysqlparams} > ${dump_file_name} ;

if [ "${gzip}" ] ; then

	if [ ! "${quiet}" ] ; then
        echo "Compressing dump by gzip (`date +\"%H:%M:%S\"`)..." ;
	fi

	gzip ${dump_file_name} ;
else 
    if  [ "${xz}" ] ; then

        if [ ! "${quiet}" ] ; then
            echo "Compressing dump by xz (`date +\"%H:%M:%S\"`)..." ;
        fi

        xz --threads=${xzthreads} ${dump_file_name} ;
    fi
fi

if [ ! "${quiet}" ] ; then
    echo "Dump completed (`date +\"%H:%M:%S\"`)..." ;
fi

rm -f ${pidfile} ;