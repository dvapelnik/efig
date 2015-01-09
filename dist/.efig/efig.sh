#!/bin/bash

if [[ ! $(whoami) == "root" ]]; then
    echo "Action not permitted. You must be a root. Try to use sudo"
    exit 1
fi

# check is fig installed
fig --help &> /dev/null
if [[ $? -eq 127 ]]; then
    echo "Are you sure that fig.sh is installed? Browse to http://fig.sh/ for more information"
    exit 1
fi

# check is dnsmasq installed
dnsmasq --help &> /dev/null
if [[ $? -eq 127 ]]; then
    echo "Are you sure that DNSMasq is installed? Browse to http://www.thekelleys.org.uk/dnsmasq/doc.html for more information"
    exit 1
fi

# check is docker installed
docker --help &> /dev/null
if [[ $? -eq 127 ]]; then
    echo "Are you sure that Docker in installer? Browse to https://www.docker.com/ for more information"
    exit 1
fi

# check is nsenter installed
docker-enter --help &> /dev/null
if [[ $? -eq 127 ]]; then
    echo "Are you sure that nsenter was installed? Browse to https://github.com/jpetazzo/nsenter fo more information"
    exit 1
fi

# reading config
source efig.conf

ACTION=${1:-up}

# functions BEGIN
function fnCleanUp(){
    rm -f logs/*
    rm -f xd_profile/*
    rm -f xd_trace/*
}

function fnRestartDnsmasq(){
    service dnsmasq restart
}

function fnDeployDB(){
    sleep 10
    docker-enter $PROJECT_NAME"_db_1" /bin/bash /db/start.db.sh
}

function fnBackupDB(){
    docker-enter $PROJECT_NAME"_db_1" /bin/bash /db/stop.db.sh
}

function fnUp(){
    fig -f $FIG_CONF -p $PROJECT_NAME up -d
    IP=$(docker inspect --format='{{.NetworkSettings.IPAddress}}' $PROJECT_NAME"_web_1")
    echo "address=/$PROJECT_NAME.doc/$IP" >> /etc/dnsmasq.conf
    fnDeployDB
    fnRestartDnsmasq
}

function fnStop(){
    fnBackupDB
    fig -f $FIG_CONF -p $PROJECT_NAME stop
    sed "/$PROJECT_NAME\.doc\//d" -i /etc/dnsmasq.conf
    fnRestartDnsmasq
}

function fnRm(){
    fnStop
    fig -f $FIG_CONF -p $PROJECT_NAME rm --force
    fnCleanUp
}

function fnGetIPs(){
    echo "DB container IP:  "`docker inspect --format='{{.NetworkSettings.IPAddress}}' $PROJECT_NAME"_db_1"`
    echo "Web container IP: "`docker inspect --format='{{.NetworkSettings.IPAddress}}' $PROJECT_NAME"_web_1"`
}

function fnGetHelp(){
    echo -e "efig is tiny wrapper for fig.sh (http://www.fig.sh/) with database deploying and backuping"
    echo -e "available commandline actions:"
    echo -e "\tup\t- for start up containers and deploying database dump from file"
    echo -e "\trestart\t- for restart and redeploy database"
    echo -e "\trm\t- for remove containers with backup database"
    echo -e "\tdeploy\t- for manual deploying database from file"
    echo -e "\tbackup\t- for manual backuping database into file"
    echo -e "\thelp\t- show this help"
}
# functions END

case $ACTION in
    'up')
        fnUp
        ;;
    'restart')
        fnRm
        fnUp
        ;;
    'rm')
        fnRm
        ;;
    'deploy')
        fnDeployDB
        ;;
    'backup')
        fnBackupDB
        ;;
    'info')
        fnGetIPs
        ;;
    'help')
        fnGetHelp
        ;;
    *)
        echo "Try to use [up|restart|rm|info|deploy|backup|help] arguments"
        ;;
esac;

exit 0
