# MySQL backup shell script

MySQL backup shell script
Feature rich MySQL / MariaDB backup script.

## Installation

- `git clone https://github.com/1sept/mysql_backup.git`
- set database `user` and `password` in `.my.cnf` located in user homedir.

## Usage

**Usage:** `mysql_backup.sh -d /var/backup -n daily [-c 10 -s -a -e test@domain.org]`

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
compress dump by gzip
- **-q, --quiet**
- **-h, --help**

## .my.cnf example

```
    [client]
    user = mysqldump
    password = secret_passwd_here_HMnab4sBMmMwtDgvF=qZuuU#gsED9u6J
    host = localhost
```