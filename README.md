# efig

`efig` is a tiny wrapper for `fig` [(homepage)](http://www.fig.sh). Main `efig`'s function is create environment for web developer with *php* and *mysql* with one click way for start your dockerized project.

`efig` can startup containers with `fig.yml` config, deploy data from file into database, backup data from database into file, remove and restart containers.

---------------------

## Requirements

* Docker (https://www.docker.com/)
* ~~fig (http://www.fig.sh)~~ (use docker-compose in new Docker versions)
* DNSMasq (http://www.thekelleys.org.uk/dnsmasq/doc.html)
* nsenter (https://github.com/jpetazzo/nsenter) (will replace with `docker exec`)

### DNSMasq minimal configuration

```bash
# cat /etc/dnsmasq.conf | grep -E -v '^(#.*)?$'
interface=lo
```

---------------------

## Example

Imagine you have a project in `~/web/project`. Make or copy files into `~/web/project/.efig`:
```
.efig/
├── db
│   ├── start.db.sh
│   └── stop.db.sh
├── efig.conf
├── efig.sh
├── efig.yml
├── httpd-conf
│   └── httpd.conf
├── logs
├── scripts
│   ├── on.start.sh
│   └── on.stop.sh
├── xd_profile
└── xd_trace
```
File or folder | Comment
----------------|----------------
`db/` | directory for database deploy and backup scripts and dump-files storage
`efig.conf` | configuration file
`efig.sh` | exacutable file
`efig.yml` | `fig` configuration file for configurate containers
`httpd-conf/httpd.conf` | `apache2` config for project
`logs/` | directory for `apache2` log-files
`xd_profile/` `xd_trace/` | directories for XDebug profile and trace files
`scripts/on.start.sh` | action after start containers
`scripts/on.stop.sh` | action after stop containers

### Config samples
```yml
# efig.yml
db:
    image: sameersbn/mysql:latest
    environment:
        - DB_USER=dbuser
        - DB_PASS=dbpass
        - DB_NAME=dbname
        - E_DB_DUMP=db.sql
        - E_DB_NAME=dbname
        - E_DB_TEST_DUMP=db.test.sql
        - E_DB_TEST_NAME=dbtest
    volumes:
        - ./db/:/db/
web:
    image: dvapelnik/docker-lap:debian.jessie.php56
    volumes:
        - ../:/var/www/
        - ./httpd-conf/:/etc/apache2/sites-enabled/
    links:
        - db:db
```
Variable | Comment
------------|-------------
`E_DB_DUMP` | db-dump filename in `db/` directory for *production* database
`E_DB_NAME` | name of *production* database
`E_DB_TEST_DUMP` | db-dump filename in `db/` directory for *test* database (if not need - you can comment this lines)
`E_DB_TEST_NAME` | name of *test* database


```bash
# efig.conf
PROJECT_NAME=project
FIG_CONF=efig.yml
SUBDOMAINS_ENABLED=1
DNS_ZONE=doc
MAIN_CONTAINER_NAME=web
DB_CONTAINER_NAME=db
ADDITIANAL_SUBDOMAINS=''
DNSMASQ_CONFIG_PATH=/etc/dnsmasq.conf
```

Config key | Comment
-----------|---------
`PROJECT_NAME` | Name of project. Will use in project URL
`FIG_CONF` | Fig configuration file name
`SUBDOMAINS_ENABLED` | Available values: `0`, `1`. If it equal to `1` then will create domains for each container in format: `http://CONTAINER_NAME.PROJECT_NAME.DNS_ZONE`. 
`DNS_ZONE` | DNS zone for domain location. See in `SUBDOMAINS_ENABLED`
`MAIN_CONTAINER_NAME` | Name of main (web) container. Must mutch with container name in `FIG_CONF`
`DB_CONTAINER_NAME` | Name of database container. Must mutch with container name in `FIG_CONF`
`ADDITIANAL_SUBDOMAINS` | Space separated string with list of additional web-sybdomains
`DNSMASQ_CONFIG_PATH` | Path to DNSMasq config file

You can add two scripts `scripts/on.start.sh` and `scripts/on.stop.sh` for some actions after start and after stop containers. For example, manage `iptables`'s rules using squid container as caching transparent proxy (look at squid example)

```apacheconf
# httpd.conf
<VirtualHost *:80>
    DocumentRoot /var/www/
    DirectoryIndex index.php

    <Directory /var/www>
        AllowOverride All
        php_admin_value open_basedir /var/www:/tmp:/usr/share:/var/lib
    </Directory>

    CustomLog   /var/www/.efig/logs/access.log combined
    ErrorLog    /var/www/.efig/logs/error.log

    php_admin_value xdebug.profiler_output_dir  /var/www/.efig/xd_profile
    php_admin_value xdebug.trace_output_dir     /var/www/.efig/xd_trace
    php_admin_value xdebug.var_display_max_depth    10
</VirtualHost>
```
So, we can start own containers if we have this config files and file structure

```bash
# check is DNSMasq is running
sudo service dnsmasq status
# check is docker.io is running
sudo docker.io status
# going to efig project directory
cd ~/web/project/.efig
# start 
sudo ./efig.sh
```
Now we can browse http://project.doc/ and see your project
```bash
# manual deploy database
sudo ./efig deploy
# manual backup database
sudo ./efig backup
```
```bash
# stop and remove project containers
sudo /efig.sh rm
```

--------------------------

## Docker images

`efig` completely tested with `dvapelnik/docker-lap` docker containers 

* dvapelnik/docker-lap:debian.squeeze.php53
* dvapelnik/docker-lap:debian.wheezy.php54
* dvapelnik/docker-lap:ubuntu.trusty.php55
* dvapelnik/docker-lap:debian.jessie.php56
* dvapelnik/docker-lap:debian.jessie.php70

They can be pulled from [DockerHub](https://registry.hub.docker.com/u/dvapelnik/docker-lap/) or builded with Dockerfiles from [dvapelnik/docker-lap](https://github.com/dvapelnik/docker-lap)