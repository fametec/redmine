# redmine

Instalação do Redmine no CentOS 7

 

[root@localhost ~]# cat /etc/redhat-release

CentOS Linux release 7.2.1511 (Core)

 

 

 

[root@localhost ~]# free -m

              total        used        free      shared  buff/cache   available
Mem:           1840         167        1493           8         178        1525
Swap:           819           0         819

 

 

[root@localhost ~]# df -h

Filesystem               Size  Used Avail Use% Mounted on
/dev/mapper/centos-root  6.7G  2.5G  4.2G  38% /
devtmpfs                 911M     0  911M   0% /dev
tmpfs                    921M     0  921M   0% /dev/shm
tmpfs                    921M  8.4M  912M   1% /run
tmpfs                    921M     0  921M   0% /sys/fs/cgroup
/dev/sda1                497M  205M  293M  42% /boot
tmpfs                    185M     0  185M   0% /run/user/0

 

[root@localhost ~]# iptables -nvL
Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

 

 

[root@localhost ~]# getenforce
Permissive

 

[root@localhost ~]# netstat -tpln
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      910/sshd            
tcp6       0      0 :::22                   :::*                    LISTEN      910/sshd            

 

 

 

[root@localhost ~]# yum -y install zlib-devel curl-devel openssl-devel httpd-devel apr-devel apr-util-devel mysql-devel postgresql-devel ImageMagick-devel libffi-devel mod_ssl mod_fcgid fcgi mariadb mariadb-devel mariadb-server

 


[root@localhost ~]# systemctl start mariadb
[root@localhost ~]# systemctl enable mariadb

 

 

[root@localhost ~]# mysql_secure_installation

NOTE: RUNNING ALL PARTS OF THIS SCRIPT IS RECOMMENDED FOR ALL MariaDB
SERVERS IN PRODUCTION USE! PLEASE READ EACH STEP CAREFULLY!

In order to log into MariaDB to secure it, we'll need the current
password for the root user. If you've just installed MariaDB, and
you haven't set the root password yet, the password will be blank,
so you should just press enter here.

Enter current password for root (enter for none): SENHA
OK, successfully used password, moving on...

Setting the root password ensures that nobody can log into the MariaDB
root user without the proper authorisation.

You already have a root password set, so you can safely answer 'n'.

Change the root password? [Y/n] Y
New password: [NOVASENHA]
Re-enter new password: [NOVASENHA]
Password updated successfully!
Reloading privilege tables..
... Success!


By default, a MariaDB installation has an anonymous user, allowing anyone
to log into MariaDB without having to have a user account created for
them. This is intended only for testing, and to make the installation
go a bit smoother. You should remove them before moving into a
production environment.

Remove anonymous users? [Y/n] Y
... Success!

Normally, root should only be allowed to connect from 'localhost'. This
ensures that someone cannot guess at the root password from the network.

Disallow root login remotely? [Y/n] Y
... Success!

By default, MariaDB comes with a database named 'test' that anyone can
access. This is also intended only for testing, and should be removed
before moving into a production environment.

Remove test database and access to it? [Y/n] Y
- Dropping test database...
... Success!
- Removing privileges on test database...
... Success!

Reloading the privilege tables will ensure that all changes made so far
will take effect immediately.

Reload privilege tables now? [Y/n] Y
... Success!

Cleaning up...

All done! If you've completed all of the above steps, your MariaDB
installation should now be secure.

Thanks for using MariaDB!

 

 

[root@localhost ~]# mysql -u root -p
Enter password: [NOVASENHA]
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 11
Server version: 5.5.56-MariaDB MariaDB Server

Copyright (c) 2000, 2017, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> create database redmine character set utf8;

Query OK, 1 row affected (0.00 sec)

MariaDB [(none)]> create user 'redmine'@'localhost' identified by 'qaz123';

Query OK, 0 rows affected (0.01 sec)

MariaDB [(none)]> grant all privileges on redmine.* to 'redmine'@'localhost';

Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> exit

 

 
Upgrade Ruby

 

The default ruby is 2.0.0p648. If you keep that version, gem install passenger fails.

 

[root@localhost ~]# yum install -y gcc
[root@localhost src]# cd /usr/local/src
[root@localhost src]# wget https://cache.ruby-lang.org/pub/ruby/2.5/ruby-2.5.0.tar.gz
[root@localhost src]# tar xvfz ruby-2.5.0.tar.gz
[root@localhost src]# cd ruby-2.5.0/
[root@localhost src]# ./configure
[root@localhost src]# make
[root@localhost src]# make install

 

[root@localhost ruby-2.5.0]# export PATH=/usr/local/bin:$PATH
[root@localhost ruby-2.5.0]# ruby -v
ruby 2.5.0p0 (2017-12-25 revision 61468) [x86_64-linux]

 
Install passenger and Gem bundler

 

[root@localhost src]# gem install passenger
[root@localhost src]# gem install bundler

[root@localhost src]# passenger-install-apache2-module

 

[root@localhost ~]# vim /etc/httpd/conf.d/passenger.conf

 

 

LoadModule passenger_module /usr/local/lib/ruby/gems/2.5.0/gems/passenger-5.2.3/buildout/apache2/mod_passenger.so

PassengerRoot /usr/local/lib/ruby/gems/2.5.0/gems/passenger-5.2.3
PassengerDefaultRuby /usr/local/bin/ruby

 

 

 

[root@localhost ~]# systemctl restart httpd

 

 

 

 

 

[root@localhost src]# useradd redmine

[root@localhost src]# yum -y install svn

 

[root@localhost src]# mkdir /var/www/redmine
[root@localhost src]# chown -R redmine.redmine /var/www/redmine/
[root@localhost src]# su redmine
[redmine@localhost src]$ cd /var/www/
[redmine@localhost www]$ svn co http://svn.redmine.org/redmine/branches/3.4-stable redmine

 

[redmine@localhost www]$ cd /var/www/redmine/config
[redmine@localhost config]$ cp database.yml.example database.yml

 

vim database.yml

 


production:
adapter: mysql2
database: redmine
host: localhost
username: redmine
password: "qaz123"
encoding: utf8

 

 


[redmine@localhost config]$ exit

[redmine@localhost config]# cd /var/www/redmine
[redmine@localhost redmine]# bundle install


[redmine@localhost config] yard config --gem-install-yri

 

[root@localhost redmine]# vim /var/www/redmine/config/environment.rb

ENV['RAILS_ENV'] ||= 'production'

...

...

 

[root@localhost redmine]# RAILS_ENV=production bundle exec rake generate_secret_token

[root@localhost redmine]# RAILS_ENV=production bundle exec rake db:migrate

 

[redmine@localhost redmine]$ /usr/local/bin/ruby bin/rails server -b 0.0.0.0 -e production
=> Booting WEBrick
=> Rails 4.2.8 application starting in production on http://0.0.0.0:3000
=> Run `rails server -h` for more startup options
=> Ctrl-C to shutdown server
Rails Error: Unable to access log file. Please ensure that /var/www/redmine/log/production.log exists and is writable (ie, make it writable for user and group: chmod 0664 /var/www/redmine/log/production.log). The log level has been raised to WARN and the output directed to STDERR until the problem is fixed.
[2018-04-05 20:11:33] INFO WEBrick 1.4.2
[2018-04-05 20:11:33] INFO ruby 2.5.0 (2017-12-25) [x86_64-linux]
[2018-04-05 20:11:33] INFO WEBrick::HTTPServer#start: pid=26702 port=3000

 

yum -y install git

 

 

[root@localhost redmine]# vim /usr/lib/systemd/system/redmine.service

 

[Unit]
Description=Redmine server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=simple
User=redmine
Group=redmine
EnvironmentFile=/etc/sysconfig/httpd
ExecStart=/usr/local/bin/ruby /var/www/redmine/bin/rails server -b 0.0.0.0 -e production
TimeoutSec=300
ExecStop=/bin/kill -WINCH ${MAINPID}

[Install]
WantedBy=multi-user.target

 

 

systemctl daemon-reload

 

 

[root@localhost redmine]# vim /etc/httpd/conf.d/ssl.conf

 
DocumentRoot /var/www/redmine/public

 
                Options Indexes ExecCGI FollowSymLinks
                Order allow,deny
                Allow from all
                AllowOverride all
 


 

 

 

[root@localhost public]# cd /var/www/redmine/public

[root@localhost public]# cp htaccess.fcgi.example .htaccess

[root@localhost public]# cp dispatch.fcgi.example dispatch.fcgi

 

vim dispatch.fcgi

 

#!/usr/local/bin/ruby

 

 

[root@localhost public]# chown -R apache:apache .

[root@localhost public]# chmod -x dispatch.fcgi

 

 

 

 

 

 

Referências:

 

https://www.redmine.org/projects/redmine/wiki/HowTos

https://www.redmine.org/projects/redmine/wiki/Install_Redmine_34_on_RHEL74

 

 https://www.redmine.org/projects/redmine/wiki/Install_Redmine_25x_on_Centos_65_complete#Install-Passenger

 

 

 
