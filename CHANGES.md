

## SQL Directory

should be linked to ~/.config/sqlrun

All parameter files should be available from a known directory

* sqlfile.conf
* parameters.conf
* driver-config.json


### example

```text
$ mkdir -p ~/.config/sqlrun
$ cd sqlrun
$  ln -s $(pwd)/SQL ~/.config/sqlrun
```

## Driver Specific Directories

Files for each RDBMS are in a specifically named directory in the SQL directory.

These names must match the names of the drivers used by DBI.

* SQL/Oracle
* SQL/Pg
* SQL/mysql


