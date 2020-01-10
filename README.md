# MySQL backup script

Feature rich MySQL / MariaDB shell backup script.

## Installation

- `git clone https://github.com/1sept/mysql_backup.git`
- set database `user` and `password` in `.my.cnf` located in user homedir.

## Example

**Usage:** `mysql_backup.sh -d /backup/dir/ -n daily [-c 10 -s -a -e test@domain.org]`

## Options

- **-d , --dir**  
backup directory
- **-n, --name**  
backup name
- **-c, --copies**  
number of copies to store (default 10)
- **-e, --email**  
notification email
- **-l, --lock-all-tables**
- **-s, --single-transaction**
- **-z, --compress**  
compress dump using gzip
- **-q, --quiet**
- **-h, --help**

## Setup script in crontab

`20      01      *       *     *    root    /bin/sh /path/to/mysql_backup.sh -d /backup/dir/ -n daily -c 10 -e admin@email.com -a`

## .my.cnf example

```
    [client]
    user = mysqldump
    password = secret_passwd_here_HMnab4sBMmMwtDgvF=qZuuU#gsED9u6J
    host = localhost
```