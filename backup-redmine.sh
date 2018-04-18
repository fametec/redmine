#!/bin/sh

#Debug
set +x

NOW=`date +%y_%m_%d`
DBNAME="redmine"
DBUSER="redmine"
DBPASS="E7uumTZ11zbZdw8xQDkyIiRP3uZRWV7NL"

/usr/bin/mysqldump -u ${DBUSER} -p${DBPASS} ${DBNAME} > /backup/redmine_${NOW}.sql
EXITVALUE=$?
if [ $EXITVALUE != 0 ]; then
    /usr/bin/logger -t REDMINE "ALERT exited abnormally with $EXITVALUE"
    exit $EXITVALUE
fi

tar -zcf /backup/redmine/redmine_${NOW}.tar.gz /var/www/redmine /opt/redmine /backup/redmine_${NOW}.sql
EXITVALUE=$?
if [ $EXITVALUE != 0 ]; then
    /usr/bin/logger -t REDMINE "ALERT exited abnormally with $EXITVALUE"
    exit $EXITVALUE
else
    rm -rf /backup/redmine_${NOW}.sql
fi


find /backup/redmine -mtime +30 -delete
EXITVALUE=$?
if [ $EXITVALUE != 0 ]; then
    /usr/bin/logger -t REDMINE "ALERT exited abnormally with $EXITVALUE"
    exit $EXITVALUE
fi


exit 0
