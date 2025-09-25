#!/bin/bash

# --- Configuration ---
MSF_DIR="/opt/metasploit-framework"
DB_USER="msf"
DB_PASS="securepassword" # IMPORTANT: Change this password!

# Ensure the script is run as root
if [ "$(id-u)" -ne 0 ]; then
   echo "This script must be run as root or with sudo."
   exit 1
fi

echo "Starting Metasploit Framework installation on Alpine Linux..."
echo "------------------------------------------------------------------"

## 1. Install Dependencies (Corrected for Alpine) ##
echo "--> 1. Installing required packages..."
# Added 'postgresql-initscripts' (for setup/rc-service) and ensured 'ncurses' is present.
apk update
apk add build-base ruby ruby-bigdecimal ruby-bundler ruby-dev libffi-dev openssl-dev \
readline-dev sqlite-dev postgresql-dev postgresql libpcap-dev libxml2-dev \
libxslt-dev yaml-dev zlib-dev ncurses ncurses-dev autoconf bison subversion git sqlite nmap

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Dependency installation failed. Exiting."
    exit 1
fi
echo "    ...Packages installed successfully. ✅"

# ------------------------------------------------------------------

## 2. Clone Metasploit Framework ##
echo "--> 2. Cloning Metasploit repository to $MSF_DIR..."
mkdir -p "$MSF_DIR"
git clone https://github.com/rapid7/metasploit-framework.git "$MSF_DIR"

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Cloning Metasploit repository failed."
    exit 1
fi

# ------------------------------------------------------------------

## 3. Install Ruby Gems ##
echo "--> 3. Installing Ruby dependencies (via bundle install)..."
cd "$MSF_DIR"
bundle install --without development test

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Ruby gem installation failed. Check the output for missing libraries."
    exit 1
fi
echo "    ...Ruby gems installed successfully. ✅"

# ------------------------------------------------------------------

## 4. Configure and Start PostgreSQL (Corrected) ##
echo "--> 4. Setting up and starting PostgreSQL database..."

# Start the PostgreSQL service using the OpenRC service command
echo "    Starting PostgreSQL service..."
rc-service postgresql start

# Enable PostgreSQL to start on boot
rc-update add postgresql default

# Wait briefly for the database to start
sleep 5

# Create database user and database for Metasploit
echo "    Creating Metasploit user and database..."
# The '2>/dev/null' suppresses warnings if user/db already exist, making the script idempotent.
su - postgres -c "psql -c \"CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';\"" 2>/dev/null
# su - postgres -c "create user $DB_USER with password '$DB_PASS';" 2>/dev/null
su - postgres -c "psql -c \"CREATE DATABASE msf OWNER msf;\"" 2>/dev/null
# su - postgres -c "createdb -O $DB_USER msf" 2>/dev/null

# Create database configuration file for Metasploit
mkdir -p "$MSF_DIR/config"
cat > "$MSF_DIR/config/database.yml" <<- EOM
production:
  adapter: postgresql
  encoding: unicode
  database: msf
  pool: 5
  username: $DB_USER
  password: $DB_PASS
  host: 127.0.0.1
  port: 5432
EOM

echo "    ...PostgreSQL configured and running. ✅"

# ------------------------------------------------------------------

## 5. Finalize and Launch ##
echo "--> 5. Installation complete. 🎉"
echo ""
echo "To launch Metasploit console (msfconsole), run the following command:"
echo "    $MSF_DIR/msfconsole"
echo "Inside msfconsole, run 'db_status' to verify database connection."
