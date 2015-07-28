#!/bin/bash
# Script to retrieve db and media data from production host
# Mario Orlandi, 2014

HOST="{{production.hostname}}"
REMOTE_DBNAME="{{ database.db_name }}"
REMOTE_DBOWNER="{{ database.db_user }}"
LOCAL_DBNAME="{{ database.db_name }}"
LOCAL_DBOWNER="{{ database.db_user }}"
REMOTE_MEDIA_FOLDER='{{ django.media_root }}'

# Prerequisites on MAC OS X:
# $ sudo port install coreutils
# to be used as follows:
# $ greadlink -f relative_path
# as readlink option -f is missing

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
LOCAL_DUMPS_FOLDER="${SCRIPTPATH}/../dumps"
if hash greadlink 2>/dev/null; then
    LOCAL_DUMPS_FOLDER=`greadlink -f $LOCAL_DUMPS_FOLDER`
else
    LOCAL_DUMPS_FOLDER=`readlink -f $LOCAL_DUMPS_FOLDER`
fi

LOCAL_MEDIA_FOLDER="${SCRIPTPATH}/../public/media"
if hash greadlink 2>/dev/null; then
    LOCAL_MEDIA_FOLDER=`greadlink -f $LOCAL_MEDIA_FOLDER`
else
    LOCAL_MEDIA_FOLDER=`readlink -f $LOCAL_MEDIA_FOLDER`
fi
#LOCAL_MEDIA_FOLDER='/home/slowd/sites/slowd/slowd/media'

echo ''
echo 'HOST: '$HOST
echo 'REMOTE_DBNAME: '$REMOTE_DBNAME
echo 'REMOTE_DBOWNER: '$REMOTE_DBOWNER
echo 'LOCAL_DBNAME: '$LOCAL_DBNAME
echo 'LOCAL_DBOWNER: '$LOCAL_DBOWNER
echo 'REMOTE_MEDIA_FOLDER: '$REMOTE_MEDIA_FOLDER
echo ''
echo 'LOCAL_DUMPS_FOLDER: '$LOCAL_DUMPS_FOLDER
echo 'LOCAL_MEDIA_FOLDER: '$LOCAL_MEDIA_FOLDER
echo ''

PREFIX=$(date +%Y-%m-%d_%H.%M.%S)_
DB_DUMP_FILENAME="${PREFIX}${REMOTE_DBNAME}.sql.gz"
DB_DUMP_FILEPATH="${LOCAL_DUMPS_FOLDER}/${DB_DUMP_FILENAME}"
MEDIA_DUMP_FILENAME="${PREFIX}${LOCAL_DBNAME}.media.tar.gz"
MEDIA_DUMP_FILEPATH="${LOCAL_DUMPS_FOLDER}/${MEDIA_DUMP_FILENAME}"


help() {
    echo 'Sample usage:'
    echo '    $ ./retrieve_remote_data action source'
    echo 'where:'
    echo '    action = sync|dump'
    echo '    source = media|db|all'
}

# do_sync_db() {
#     echo '*** sync db ..'
#     sudo -u postgres psql --command="drop database if exists $LOCAL_DBNAME"
#     sudo -u postgres psql --command="create database $LOCAL_DBNAME owner $LOCAL_DBOWNER"
#     COMMAND='sudo -u postgres pg_dump '$REMOTE_DBNAME' | gzip'
#     ssh $HOST $COMMAND | gunzip | sudo -u postgres psql $LOCAL_DBNAME
#     SQL="update django_site set domain='`hostname`.`hostname -d`' where id=1"
#     echo $SQL
#     sudo -u postgres psql -d $LOCAL_DBNAME -c "$SQL"
#     sudo -u postgres psql $LOCAL_DBNAME --command="select * from django_site"
# }

do_sync_db() {
    echo '*** sync db ..'
    psql --dbname="template1" --command="drop database if exists $LOCAL_DBNAME"
    psql --dbname="template1" --command="create database $LOCAL_DBNAME owner $LOCAL_DBOWNER"
    COMMAND='sudo -u postgres pg_dump '$REMOTE_DBNAME' | gzip'
    ssh $HOST $COMMAND | gunzip | psql $LOCAL_DBNAME
    SQL="update django_site set domain='`hostname`.`hostname -d`' where id=1"
    echo $SQL
    psql -d $LOCAL_DBNAME -c "$SQL"
    psql $LOCAL_DBNAME --command="select * from django_site"
}

do_sync_media() {
    echo '*** sync media ..'
    echo 'Downloading files from "'$HOST:$REMOTE_MEDIA_FOLDER'" ...'
    COMMAND="rsync -avz -e 'ssh' --delete --progress --partial --exclude=CACHE/ $HOST:$REMOTE_MEDIA_FOLDER/ $LOCAL_MEDIA_FOLDER/"
    echo $COMMAND
    $COMMAND
}

do_dump_db() {
    echo '*** dump db ..'
    echo 'Downloading db "'$REMOTE_DBNAME'" from "'$HOST'" ...'
    echo "ssh $HOST \"sudo -u postgres pg_dump $REMOTE_DBNAME | gzip\" > $DB_DUMP_FILEPATH"
    ssh $HOST "sudo -u postgres pg_dump $REMOTE_DBNAME | gzip" > $DB_DUMP_FILEPATH
    echo '=========================================================================='
    ls -lh $DB_DUMP_FILEPATH
    echo '=========================================================================='
}

do_dump_media() {
    echo '*** dump media ..'
    do_sync_media
    cd "$LOCAL_MEDIA_FOLDER/../"
    tar czf $MEDIA_DUMP_FILEPATH media
    cd $SCRIPTPATH
    echo '=========================================================================='
    ls -lh $MEDIA_DUMP_FILEPATH
    echo '=========================================================================='
}

if [ $# -ne 2 ]; then
    help
    exit
fi

action=$1
source=$2
if [ "$action" == "sync" ] && [ "$source" == "db" ]; then
    do_sync_db
elif [ "$action" == "sync" ] && [ "$source" == "media" ]; then
    do_sync_media
elif [ "$action" == "sync" ] && [ "$source" == "all" ]; then
    do_sync_db
    do_sync_media
elif [ "$action" == "dump" ] && [ "$source" == "db" ]; then
    do_dump_db
elif [ "$action" == "dump" ] && [ "$source" == "media" ]; then
    do_dump_media
elif [ "$action" == "dump" ] && [ "$source" == "all" ]; then
    do_dump_db
    do_dump_media
else
    help
fi
