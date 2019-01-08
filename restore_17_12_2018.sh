/u01/app/oracle/product/11.2.0/db_home1/bin/rman target / nocatalog log = /home/oracle/DBHC/full-rman-restore/Sessionrestore_17_12_2018.log append <<EOF
run
{
ALLOCATE CHANNEL c1 DEVICE TYPE DISK;
ALLOCATE CHANNEL c2 DEVICE TYPE DISK;
ALLOCATE CHANNEL c3 DEVICE TYPE DISK;
 set newname for datafile 1 to '/oradata/testorcl/system01.dbf';
set newname for datafile 2 to '/oradata/testorcl/sysaux01.dbf';
set newname for datafile 3 to '/oradata/testorcl/undotbs01.dbf';
set newname for datafile 4 to '/oradata/testorcl/users01.dbf';
set newname for datafile 5 to '/oradata/testorcl/example01.dbf';
 SQL "ALTER DATABASE RENAME FILE ''/oradata/orcl/redo03.log'' TO ''/oradata/testorcl/redo03.log'' ";
SQL "ALTER DATABASE RENAME FILE ''/oradata/orcl/redo02.log'' TO ''/oradata/testorcl/redo02.log'' ";
SQL "ALTER DATABASE RENAME FILE ''/oradata/orcl/redo01.log'' TO ''/oradata/testorcl/redo01.log'' ";

restore database;
SWITCH DATAFILE ALL;
switch tempfile all;
release channel c1;
release channel c2;
release channel c3;
}
exit;
EOF
