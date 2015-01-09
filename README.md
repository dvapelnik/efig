# efig
```efig``` is a tiny wrapper for ```fig``` [(homepage)](http://www.fig.sh). Main ```efig```'s function is create environment for web developer with *php* and *mysql*. One click way for start your dockerized project.

```efig``` can startup containers with ```fig.yml``` config, deploy data from file into database, backup data from database into file, remove and restart containers.

---------------------

## Example

You have a project in ```~/web/project```. Make or copy files into ```~/web/project/.efig```:
```
.efig/
├── db
│   ├── start.db.sh
│   └── stop.db.sh
├── efig.conf
├── efig.sh
├── efig.yml
├── httpd.conf
├── logs/
├── xd_profile/
└── xd_trace/
```
File or folder | Comment
----------------|----------------
* ```db/``` | directory for database deploy and backup scripts and dump-files storage
* ```efig.conf``` | configuration file
* ```efig.sh``` | exacutable file
* ```efig.yml``` | *fig* configuration file for configurate containers
* ```httpd.conf``` | *apache2* config for project
* ```logs/``` - directory for apache2 log-files
* ```xd_profile/``` and ```xd_trace/``` - directories for XDebug profile and trace files

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
        - db/:/db/
web:
    image: dvapelnik/docker-lap:debian.jessie.php56
    volumes:
        - ../:/var/www/
        - httpd.conf:/etc/apache2/sites-enabled/000-default
    links:
        - db:db
```
Variable | Comment
------------|-------------
```E_DB_DUMP``` | db-dump filename in ```db/``` directory for *production* database
```E_DB_NAME``` | name of *production* database
```E_DB_TEST_DUMP``` | db-dump filename in ```db/``` directory for *test* database (if not need - you can comment this lines)
```E_DB_TEST_NAME``` | name of *test* database


```bash
# efig.cong
PROJECT_NAME=project
FIG_CONF=efig.yml
```
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
