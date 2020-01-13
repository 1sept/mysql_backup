# MySQL backup script

Feature rich MySQL / MariaDB backup script.
Scripts
- mysql_backup.sh :: backuping mysql databases in single dump. 
- mysql_db_dump.sh :: dumping single database

## Installation

- `git clone https://github.com/1sept/mysql_backup.git`
- set database `user` and `password` in `.my.cnf` located in user homedir.

## Example

**Usage:** `./mysql_backup.sh -d /backup/dir/ -n daily [-c 10 -s -z -e test@domain.org]`
**Usage:** `./mysql_db_dump.sh databse1 [database2 database3 database4 ...]`

## mysql_bakcup Options

**-d , --dir**  
backup directory  
**-n, --name**  
backup name  
**-c, --copies**  
number of copies to store (default 10)  
**-e, --email**  
email to send notifications  
**-l, --lock-all-tables**  
lock all tables across all databases. This is achieved by acquiring a global read lock for the duration of the whole dump. This option automatically turns off `--single-transaction` and `--lock-tables`.  
WARNING!!! This will block all applications.  
**-s, --single-transaction**  
this option sets the transaction isolation mode to REPEATABLE READ and sends a START TRANSACTION SQL statement to the server before dumping data. It is useful only with transactional tables such as InnoDB, because then it dumps the consistent state of the database at the time when START TRANSACTION was issued without blocking any applications.  
**-z, --gzip**  
compress dump using gzip  
**-x, --xz**  
compress dump using xz  
**--xz-threads**
number of worker threads to use by xz. 0 - use all CPU. (default: 2)
**-m, --master**  
set master data in dump  
**-q, --quiet**  
**--pid-file**  
set pid-file (default: /var/run/mysql_backup.sh.pid)
**-h, --help**  

## Setup script in crontab

`20      01      *       *     *    root    /bin/sh /path/to/mysql_backup.sh -d /backup/dir/ -n daily -c 7 -e admin@email.com -x --xz-threads 6 -q -m`

## .my.cnf example

```
    [mysqldump]
    user = mysqldump
    password = secret_passwd_here
    host = localhost
    max-allowed-packet=1G
```