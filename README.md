# MySQL backup script

Feature rich MySQL / MariaDB backup script.

## Installation

- `git clone https://github.com/1sept/mysql_backup.git`
- set database `user` and `password` in `.my.cnf` located in user homedir.

## Example

**Usage:** `mysql_backup.sh -d /backup/dir/ -n daily [-c 10 -s -z -e test@domain.org]`

## Options

**-d , --dir**  
backup directory  
**-n, --name**  
backup name  
**-c, --copies**  
number of copies to store (default 10)  
**-e, --email**  
notification email  
**-l, --lock-all-tables**  
lock all tables across all databases. This is achieved by acquiring a global read lock for the duration of the whole dump. This option automatically turns off `--single-transaction` and `--lock-tables`.  
**-s, --single-transaction**  
this option sets the transaction isolation mode to REPEATABLE READ and sends a START TRANSACTION SQL statement to the server before dumping data. It is useful only with transactional tables such as InnoDB, because then it dumps the consistent state of the database at the time when START TRANSACTION was issued without blocking any applications.  
**-z, --compress**  
compress dump using gzip  
**-q, --quiet**  
**-h, --help**  

## Setup script in crontab

`20      01      *       *     *    root    /bin/sh /path/to/mysql_backup.sh -d /backup/dir/ -n daily -c 10 -e admin@email.com -z`

## .my.cnf example

```
    [client]
    user = mysqldump
    password = secret_passwd_here_HMnab4sBMmMwtDgvF=qZuuU#gsED9u6J
    host = localhost
```