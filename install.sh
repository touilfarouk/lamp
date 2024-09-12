#!/usr/bin/env bash

# Use single quotes instead of double quotes to make it work with special-character passwords
PASSWORD='12345678'
PROJECTFOLDER='myproject'

# Create project folder
sudo mkdir -p "/var/www/html/${PROJECTFOLDER}"

# Update and upgrade system packages
sudo apt-get update
sudo apt-get -y upgrade

# Install Apache2
sudo apt-get install -y apache2

# Install PHP 8.x
sudo apt-get install -y php php-cli php-fpm php-mysql php-curl php-gd

# Install MySQL Server
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
sudo apt-get -y install mysql-server

# Install phpMyAdmin
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
sudo apt-get -y install phpmyadmin

# Setup Apache virtual host
VHOST=$(cat <<EOF
<VirtualHost *:80>
    DocumentRoot "/var/www/html/${PROJECTFOLDER}/public"
    <Directory "/var/www/html/${PROJECTFOLDER}/public">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
)
echo "${VHOST}" | sudo tee /etc/apache2/sites-available/000-default.conf

# Enable mod_rewrite and PHP-FPM
sudo a2enmod rewrite
sudo a2enconf php8.0-fpm

# Restart Apache
sudo systemctl restart apache2

# Install curl
sudo apt-get -y install curl

# Install Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Clone the project from GitHub
sudo git clone https://github.com/touilfarouk/convert_csv_to_mysql "/var/www/html/${PROJECTFOLDER}"

# Go to project folder and load Composer packages
cd "/var/www/html/${PROJECTFOLDER}"
sudo composer install

# Run SQL statements from the install folder
sudo mysql -h "localhost" -u "root" "-p${PASSWORD}" < "/var/www/html/${PROJECTFOLDER}/application/_installation/01-create-database.sql"
sudo mysql -h "localhost" -u "root" "-p${PASSWORD}" < "/var/www/html/${PROJECTFOLDER}/application/_installation/02-create-table-users.sql"
sudo mysql -h "localhost" -u "root" "-p${PASSWORD}" < "/var/www/html/${PROJECTFOLDER}/application/_installation/03-create-table-notes.sql"

# Set permissions for the avatars folder
sudo chown -R www-data "/var/www/html/${PROJECTFOLDER}/public/avatars"

# Remove Apache's default demo file
sudo rm "/var/www/html/index.html"

# Final feedback
echo "Voila!"
