#!/bin/bash

# Debug

set -xv

## VARIAVEIS

FQDN="redmine.eftech.com.br"
ADMINEMAIL="suporte@eftech.com.br"
ORGANIZATION="EF-TECH"
MYSQL_ROOT_PASSWORD=''
DBUSER="redmine"
DBHOST="localhost"
DBNAME="redmine"
DBPASS="`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;`"
#DBPASS="qaz123"
#MYSQL_NEW_ROOT_PASSWORD="qaz123"
MYSQL_NEW_ROOT_PASSWORD="`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;`"


MYSQL="mysql -u root -p${MYSQL_NEW_ROOT_PASSWORD}"
CURL=`which curl`


## SELINUX

sed -i s/enforcing/permissive/g /etc/selinux/config

setenforce 0


## INSTALL MARIADB-SERVER

yum -y install mariadb-server expect epel-release


## Restart do mysql

systemctl enable mariadb
systemctl restart mariadb


## Configuração de segurança do banco

SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"$MYSQL_ROOT_PASSWORD\r\"
expect \"Change the root password?\"
send \"y\r\"
expect \"New password:\"
send \"$MYSQL_NEW_ROOT_PASSWORD\r\"
expect \"Re-enter new password:\"
send \"$MYSQL_NEW_ROOT_PASSWORD\r\" 
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")

echo "$SECURE_MYSQL"


## DATABASE

$MYSQL -e "create database $DBNAME character set utf8;"
$MYSQL -e "create user $DBUSER@localhost identified by '"$DBPASS"';"
$MYSQL -e "grant all privileges on $DBNAME.* to $DBUSER@localhost;"



## Download e Install Redmine

## DEPENDENCIAS

yum -y install \
zlib-devel \
curl-devel \
openssl-devel \
httpd-devel \
apr-devel \
apr-util-devel \
mysql-devel \
ImageMagick-devel \
libffi-devel \
mod_ssl \
mod_fcgid \
fcgi \
mariadb \
mariadb-devel \
mariadb-server



## RUBY

yum -y install gcc 
cd /usr/local/src
curl https://cache.ruby-lang.org/pub/ruby/2.5/ruby-2.5.0.tar.gz -O ruby-2.5.0.tar.gz 
tar xvfz ruby-2.5.0.tar.gz
cd ruby-2.5.0/
./configure && make && make install

export PATH=/usr/local/bin:$PATH
ruby -v
# ruby 2.5.0p0 (2017-12-25 revision 61468) [x86_64-linux]



## INSTALL PASSENGER AND GEM BUNDLER

gem install passenger

gem install bundler

passenger-install-apache2-module --language ruby -a 

# Press Enter to continue, or Ctrl-C to abort.

cat <<EOF > /etc/httpd/conf.d/passenger.conf
   LoadModule passenger_module /usr/local/lib/ruby/gems/2.5.0/gems/passenger-5.2.3/buildout/apache2/mod_passenger.so
   <IfModule mod_passenger.c>
     PassengerRoot /usr/local/lib/ruby/gems/2.5.0/gems/passenger-5.2.3
     PassengerDefaultRuby /usr/local/bin/ruby
   </IfModule>
EOF


## INSTALL REDMINE

useradd redmine

usermod -a -G apache redmine

yum -y install svn

mkdir -p /var/www/redmine

cd /var/www/

svn co http://svn.redmine.org/redmine/branches/3.4-stable redmine


cat <<EOF > /var/www/redmine/config/database.yml
production:
  adapter: mysql2
  database: $DBNAME
  host: $DBHOST
  username: $DBUSER
  password: "$DBPASS"
  encoding: utf8
EOF

cat /var/www/redmine/config/database.yml


chown -R redmine:redmine /var/www/redmine


cd /var/www/redmine

bundle install 

yard config --gem-install-yri


echo "ENV['RAILS_ENV'] ||= 'production'" >> /var/www/redmine/config/environment.rb


RAILS_ENV=production bundle exec rake generate_secret_token

RAILS_ENV=production bundle exec rake db:migrate



cd /var/www/redmine/public
mkdir -p plugin_assets
cp dispatch.fcgi.example dispatch.fcgi
cp htaccess.fcgi.example .htaccess
chmod +x dispatch.fcgi



cat <<EOF > /etc/httpd/conf.d/ssl-$HOST.conf
<VirtualHost *:80>
        ServerName $FQDN
        ServerAdmin admin@$FQDN
        DocumentRoot /var/www/redmine/public/
        ErrorLog logs/error_log
        <Directory "/var/www/redmine/public/">
                Options Indexes ExecCGI FollowSymLinks
                Order allow,deny
                Allow from all
                AllowOverride all
        </Directory>
</VirtualHost>
EOF


chown -R apache:apache /var/www/redmine/public

systemctl enable httpd
systemctl restart httpd



## FIM

echo ""
echo ""
echo "MYSQL root@localhost: $MYSQL_NEW_ROOT_PASSWORD"
echo ""
echo "MYSQL redmine@localhost: $DBPASS"
echo ""
echo "Login: admin"
echo ""
echo "Password: admin "
echo ""


