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
function fnCheckConfig(){
    if [[ -z $PROJECT_NAME ]]; then
        echo "PROJECT_NAME in config expected"
        exit 1
    fi

    if [[ -z $FIG_CONF ]]; then
        echo "FIG_CONF in config expected"
        exit 1
    fi

    if [[ -z $SUBDOMAINS_ENABLED ]]; then
        echo "SUBDOMAINS_ENABLED in config expected"
        exit 1
    fi

    if [[ ! ($SUBDOMAINS_ENABLED -eq 0 || $SUBDOMAINS_ENABLED -eq 1) ]]; then
        echo "SUBDOMAINS_ENABLED value is incorrect. Use 0 or 1"
        exit 1
    fi

    if [[ -z $DNS_ZONE ]]; then
        echo "DNS_ZONE in config expected"
        exit 1
    fi

    if [[ -z $MAIN_CONTAINER_NAME ]]; then
        echo "MAIN_CONTAINER_NAME is not defined in config"
        exit 1
    fi

    if [[ -z $DNSMASQ_CONFIG_PATH ]]; then
        echo "DNSMASQ_CONFIG_PATH is not defined in config"
        exit 1
    fi
}

function fnCleanUp(){
    rm -f logs/*
    rm -f xd_profile/*
    rm -f xd_trace/*
}

function fnRestartDnsmasq(){
    service dnsmasq restart
}

function fnDeployDB(){
    docker-enter $PROJECT_NAME"_${DB_CONTAINER_NAME}_1" /bin/bash /db/start.db.sh
}

function fnBackupDB(){
    docker-enter $PROJECT_NAME"_${DB_CONTAINER_NAME}_1" /bin/bash /db/stop.db.sh
}

function fnUp(){
    fig -f $FIG_CONF -p $PROJECT_NAME up -d
    IP=$(docker inspect --format='{{.NetworkSettings.IPAddress}}' $PROJECT_NAME"_${MAIN_CONTAINER_NAME}_1")
    echo "Adding main container into DNSMasq config"
    echo "address=/$PROJECT_NAME.$DNS_ZONE/$IP" >> $DNSMASQ_CONFIG_PATH
    if [[ $SUBDOMAINS_ENABLED -eq 1 ]]; then
        for CONTAINER in `grep -E -o '^(\w+)' efig.yml`; do
            IP=$(docker inspect --format='{{.NetworkSettings.IPAddress}}' $PROJECT_NAME"_${CONTAINER}_1")
            echo "Adding ${CONTAINER} container into DNSMasq config"
            echo "address=/$CONTAINER.$PROJECT_NAME.$DNS_ZONE/$IP" >> $DNSMASQ_CONFIG_PATH
        done
    fi

    if [[ ! -z $DB_CONTAINER_NAME ]]; then
        echo -ne "Waiting for database container is completely started"
        for i in {1..10}; do
            sleep 1;
        echo -ne ".";
        done
        echo -ne "\n"
        fnDeployDB
    fi

    fnRestartDnsmasq
}

function fnStop(){
    if [[ ! -z $DB_CONTAINER_NAME ]]; then
        fnBackupDB
    fi
    fig -f $FIG_CONF -p $PROJECT_NAME stop
    echo "Cleaning up DNSMasq.conf"
    sed "/$PROJECT_NAME\.$DNS_ZONE\//d" -i $DNSMASQ_CONFIG_PATH
    fnRestartDnsmasq
}

function fnRm(){
    fnStop
    fig -f $FIG_CONF -p $PROJECT_NAME rm --force
    fnCleanUp
}

function fnGetIPs(){
    for CONTAINER in `grep -E -o '^(\w+)' efig.yml`; do
        IP=$(docker inspect --format='{{.NetworkSettings.IPAddress}}' $PROJECT_NAME"_${CONTAINER}_1")
        echo "${CONTAINER} IP is: ${IP}"
    done
    # if [[ ! -z $DB_CONTAINER_NAME ]]; then
    #     echo "DB container IP:  "`docker inspect --format='{{.NetworkSettings.IPAddress}}' $PROJECT_NAME"_${DB_CONTAINER_NAME}_1"`
    # fi
    # echo "Web container IP: "`docker inspect --format='{{.NetworkSettings.IPAddress}}' $PROJECT_NAME"_${MAIN_CONTAINER_NAME}_1"`
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

fnCheckConfig

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
        if [[ ! -z $DB_CONTAINER_NAME ]]; then
            fnDeployDB
        else
            echo "No DB container specified in config"
        fi
        ;;
    'backup')
        if [[ ! -z $DB_CONTAINER_NAME ]]; then
            fnBackupDB
        else
            echo "No DB container specified in config"
        fi
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
