#!/bin/bash

set -eu

#=========================================#
# VARIABLES 
#=========================================#


#Set the timezone for the server. A full list of avaliable timezone can be found by 
# running timedatectl list-timezone
TIMEZONE=America/New_York

# Set the name of the new user to create.
USERNAME=greenlight

# Prompt tp enter a password for PostgreSQL greenlight user (rather than hard-coding 
# a password in this script).

read -p "Enter password for greenlight DB user: " DB_PASSWORD

# installed support for all locales. Do not change this setting!

export LC_ALL=en_US.UTF-8

#=========================================#
# SCRIPT LOGIC 
#=========================================#

add-apt-repository --yes universe

apt update
apt --yes -o Dpkg::Options::="--force-confnew" upgrade

# Set the system timezone and install locales
timedatectl set-timezone ${TIMEZONE}
apt --yes install locales-all

# Add the new user (and give them sudo privileges).
useradd --create-home --shell "/bin/bash" --groups sudo "${USERNAME}"

passws --delete "${USERNAME}"
chage --lastday 0 "${USERNAME}"

# Copy the SSH keys from the root user to the new user.

rsync --archive --chown=${USERNAME}:${USERNAME} /root/.ssh /home/${USERNAME}

# Configure the firewall to allow SSH, HTTPS traffic

ufw allow 22
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Install fali2ban
apt --yes install fali2ban

# Install the migrate CLI tool.

curl -L https://github.com/golang-migrate/migrate/releases/download/v4.14.1/migrate.linux-amd64.tar.gz | tar xvz 
mv migrate.linux-amd64 /usr/local/bin/migrate

# Install PostgreSQL
apt --yes install postgresql 

# Set up the greenlight DB and create a user account with the password entered earlier.
sudo -i -u postgres psql -c "CREATE DATABASE greenlight"
sudo -i -u postgres psql -d greenlight -c "CREATE EXTENSION IF NOT EXISTS citext"
sudo -i -u postgres psql -d greenlight -c "CREATE ROLE greenlight WITH LOGIN PASSWORD '${DB_PASSWORD}'"

# Add a DSN for connecting to the greenlight database to the system-wide environment
# variables in the /etc/environment file.
echo "GREENLIGHT_DB_DSN='postgres://greenlight:${DB_PASSWORD}@localhost/greenlight'" >> /etc/environment

# Install Caddy (see https://caddyserver.com/docs/install#debian-ubuntu-raspbian).
apt --yes install -y debian-keyring debian-archive-keyring apt-transport-https
curl -L https://dl.cloudsmith.io/public/caddy/stable/gpg.key | sudo apt-key add -
curl -L https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt | sudo tee -a /etc/apt/sources.list.d/caddy-stable.list 
apt update
apt --yes install caddy

echo "Script complete! Rebooting..." 
reboot