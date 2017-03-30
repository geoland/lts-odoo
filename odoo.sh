#!/bin/bash
################################################################################
# Script for Installation: ODOO Saas4/Trunk server on Ubuntu 14.04 LTS
# Author: André Schenkels, ICTSTUDIO 2014
#-------------------------------------------------------------------------------
#  
# This script will install ODOO Server on
# clean Ubuntu 14.04 Server
#-------------------------------------------------------------------------------
# USAGE:
#
# odoo-install
#
# EXAMPLE:
# ./odoo-install 
#
################################################################################
 
##fixed parameters
#openerp
OE_USER=$USER
OE_HOME=$GOPATH
OE_HOME_EXT="$OE_HOME/odoo"

#Enter version for checkout "8.0" for version 8.0, "7.0 (version 7), saas-4, saas-5 (opendays version) and "master" for trunk
OE_VERSION="8.0"

#set the superadmin password
OE_SUPERADMIN="secret"

#set the server name
OE_CONFIG="odoo-server"

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
sudo apt-get update
sudo apt-get upgrade -y

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------

# Convert the postgres db to UTF8
sudo service postgresql stop
sudo pg_dropcluster --stop 9.3 main
sudo pg_createcluster --start -e UTF-8 9.3 main
sudo service postgresql start
	
echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true
sudo su - postgres -c "psql -U postgres -d postgres -c \"alter user $OE_USER with password '$OE_SUPERADMIN';\""

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n---- Install tool packages ----"
sudo apt-get install wget subversion git bzr bzrtools python-pip -y
	
echo -e "\n---- Install python packages ----"
sudo apt-get install python-dateutil python-feedparser python-ldap python-libxslt1 python-lxml python-mako python-openid python-psycopg2 python-pybabel python-pychart python-pydot python-pyparsing python-reportlab python-simplejson python-tz python-vatnumber python-vobject python-webdav python-werkzeug python-xlwt python-yaml python-zsi python-docutils python-psutil python-mock python-unittest2 python-jinja2 python-pypdf python-decorator python-requests python-passlib python-pil -y
	
echo -e "\n---- Install python libraries ----"
sudo pip install gdata

echo -e "\n---- Create Log directory ----"
mkdir $OE_HOME/log

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
echo -e "\n==== Installing ODOO Server ===="
git clone --branch $OE_VERSION --single-branch https://www.github.com/odoo/odoo

echo -e "\n---- Create custom module directory ----"
mkdir $OE_HOME/custom-addons

echo -e "* Create server config file"
cp $OE_HOME_EXT/debian/openerp-server.conf $OE_HOME/$OE_CONFIG.conf
sudo chmod 640 $OE_HOME/$OE_CONFIG.conf

echo -e "* Change server config file"
sed -i s#"; admin_passwd.*"#"admin_passwd = $OE_SUPERADMIN"#g $OE_HOME/$OE_CONFIG.conf
sed -i s#"db_host = .*"#"db_host = localhost"#g $OE_HOME/$OE_CONFIG.conf
sed -i s#"db_port = .*"#"db_port = 5432"#g $OE_HOME/$OE_CONFIG.conf
sed -i s#"db_user = .*"#"db_user = $OE_USER"#g $OE_HOME/$OE_CONFIG.conf
sed -i s#"db_password = .*"#"db_password = $OE_SUPERADMIN"#g $OE_HOME/$OE_CONFIG.conf
sed -i s#"addons_path = .*"#"addons_path = $OE_HOME_EXT/addons,$OE_HOME/custom-addons"#g $OE_HOME/$OE_CONFIG.conf
echo "logfile = $OE_HOME/log/$OE_CONFIG$1.log" >> $OE_HOME/$OE_CONFIG.conf
echo "xmlrpc_interface = 0.0.0.0 " >> $OE_HOME/$OE_CONFIG.conf
echo "xmlrpc_port = 8080" >> $OE_HOME/$OE_CONFIG.conf

#--------------------------------------------------
# Adding ODOO as a deamon (initscript)
#--------------------------------------------------

echo -e "* Create init file"
echo '#!/bin/sh' >> $OE_HOME/$OE_CONFIG
echo '### BEGIN INIT INFO' >> $OE_HOME/$OE_CONFIG
echo '# Provides: $OE_CONFIG' >> $OE_HOME/$OE_CONFIG
echo '# Required-Start: $remote_fs $syslog' >> $OE_HOME/$OE_CONFIG
echo '# Required-Stop: $remote_fs $syslog' >> $OE_HOME/$OE_CONFIG
echo '# Should-Start: $network' >> $OE_HOME/$OE_CONFIG
echo '# Should-Stop: $network' >> $OE_HOME/$OE_CONFIG
echo '# Default-Start: 2 3 4 5' >> $OE_HOME/$OE_CONFIG
echo '# Default-Stop: 0 1 6' >> $OE_HOME/$OE_CONFIG
echo '# Short-Description: Enterprise Business Applications' >> $OE_HOME/$OE_CONFIG
echo '# Description: ODOO Business Applications' >> $OE_HOME/$OE_CONFIG
echo '### END INIT INFO' >> $OE_HOME/$OE_CONFIG
echo 'PATH=/bin:/sbin:/usr/bin' >> $OE_HOME/$OE_CONFIG
echo "DAEMON=$OE_HOME_EXT/openerp-server" >> $OE_HOME/$OE_CONFIG
echo "NAME=$OE_CONFIG" >> $OE_HOME/$OE_CONFIG
echo "DESC=$OE_CONFIG" >> $OE_HOME/$OE_CONFIG
echo '' >> $OE_HOME/$OE_CONFIG
echo '# Specify the user name (Default: odoo).' >> $OE_HOME/$OE_CONFIG
echo "USER=$OE_USER" >> $OE_HOME/$OE_CONFIG
echo '' >> $OE_HOME/$OE_CONFIG
echo '# Specify an alternate config file (Default: /etc/openerp-server.conf).' >> $OE_HOME/$OE_CONFIG
echo "CONFIGFILE=\"$OE_HOME/$OE_CONFIG.conf\"" >> $OE_HOME/$OE_CONFIG
echo '' >> $OE_HOME/$OE_CONFIG
echo '# pidfile' >> $OE_HOME/$OE_CONFIG
echo 'PIDFILE=/var/run/$NAME.pid' >> $OE_HOME/$OE_CONFIG
echo '' >> $OE_HOME/$OE_CONFIG
echo '# Additional options that are passed to the Daemon.' >> $OE_HOME/$OE_CONFIG
echo 'DAEMON_OPTS="-c $CONFIGFILE"' >> $OE_HOME/$OE_CONFIG
echo '[ -x $DAEMON ] || exit 0' >> $OE_HOME/$OE_CONFIG
echo '[ -f $CONFIGFILE ] || exit 0' >> $OE_HOME/$OE_CONFIG
echo 'checkpid() {' >> $OE_HOME/$OE_CONFIG
echo '[ -f $PIDFILE ] || return 1' >> $OE_HOME/$OE_CONFIG
echo 'pid=`cat $PIDFILE`' >> $OE_HOME/$OE_CONFIG
echo '[ -d /proc/$pid ] && return 0' >> $OE_HOME/$OE_CONFIG
echo 'return 1' >> $OE_HOME/$OE_CONFIG
echo '}' >> $OE_HOME/$OE_CONFIG
echo '' >> $OE_HOME/$OE_CONFIG
echo 'case "${1}" in' >> $OE_HOME/$OE_CONFIG
echo 'start)' >> $OE_HOME/$OE_CONFIG
echo 'echo -n "Starting ${DESC}: "' >> $OE_HOME/$OE_CONFIG
echo 'start-stop-daemon --start --quiet --pidfile ${PIDFILE} \' >> $OE_HOME/$OE_CONFIG
echo '--chuid ${USER} --background --make-pidfile \' >> $OE_HOME/$OE_CONFIG
echo '--exec ${DAEMON} -- ${DAEMON_OPTS}' >> $OE_HOME/$OE_CONFIG
echo 'echo "${NAME}."' >> $OE_HOME/$OE_CONFIG
echo ';;' >> $OE_HOME/$OE_CONFIG
echo 'stop)' >> $OE_HOME/$OE_CONFIG
echo 'echo -n "Stopping ${DESC}: "' >> $OE_HOME/$OE_CONFIG
echo 'start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \' >> $OE_HOME/$OE_CONFIG
echo '--oknodo' >> $OE_HOME/$OE_CONFIG
echo 'echo "${NAME}."' >> $OE_HOME/$OE_CONFIG
echo ';;' >> $OE_HOME/$OE_CONFIG
echo '' >> $OE_HOME/$OE_CONFIG
echo 'restart|force-reload)' >> $OE_HOME/$OE_CONFIG
echo 'echo -n "Restarting ${DESC}: "' >> $OE_HOME/$OE_CONFIG
echo 'start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \' >> $OE_HOME/$OE_CONFIG
echo '--oknodo' >> $OE_HOME/$OE_CONFIG
echo 'sleep 1' >> $OE_HOME/$OE_CONFIG
echo 'start-stop-daemon --start --quiet --pidfile ${PIDFILE} \' >> $OE_HOME/$OE_CONFIG
echo '--chuid ${USER} --background --make-pidfile \' >> $OE_HOME/$OE_CONFIG
echo '--exec ${DAEMON} -- ${DAEMON_OPTS}' >> $OE_HOME/$OE_CONFIG
echo 'echo "${NAME}."' >> $OE_HOME/$OE_CONFIG
echo ';;' >> $OE_HOME/$OE_CONFIG
echo '*)' >> $OE_HOME/$OE_CONFIG
echo 'N=/etc/init.d/${NAME}' >> $OE_HOME/$OE_CONFIG
echo 'echo "Usage: ${NAME} {start|stop|restart|force-reload}" >&2' >> $OE_HOME/$OE_CONFIG
echo 'exit 1' >> $OE_HOME/$OE_CONFIG
echo ';;' >> $OE_HOME/$OE_CONFIG
echo '' >> $OE_HOME/$OE_CONFIG
echo 'esac' >> $OE_HOME/$OE_CONFIG
echo 'exit 0' >> $OE_HOME/$OE_CONFIG

echo -e "* Security Init File"
sudo mv $OE_HOME/$OE_CONFIG /etc/init.d/$OE_CONFIG
sudo chmod 755 /etc/init.d/$OE_CONFIG
sudo chown root: /etc/init.d/$OE_CONFIG

echo -e "* Start ODOO on Startup"
sudo update-rc.d $OE_CONFIG defaults

sudo service apache2 stop 
echo "Done! The ODOO server can be started with /etc/init.d/$OE_CONFIG"