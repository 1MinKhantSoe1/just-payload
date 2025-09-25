#!/bin/bash

# --- Configuration ---
MSF_DIR="/opt/metasploit-framework"
DB_USER="msf"
DB_PASS="securepassword" # Change this password!

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
   echo "This script must be run as root or with sudo."
   exit 1
fi

echo "Starting Metasploit Framework installation on Alpine Linux..."

## 1. Install Dependencies ##
echo "--> 1. Installing required packages..."
# The 'build-base' package provides compilation tools (like gcc) needed for many gems.
# The list includes Ruby, development libraries, PostgreSQL, and network tools.
apk update
apk add build-base ruby ruby-bigdecimal ruby-bundler ruby-io-console ruby-webrick \
ruby-dev libffi-dev openssl-dev readline-dev sqlite-dev postgresql-dev \
libpcap-dev libxml2-dev libxslt-dev yaml-dev zlib-dev ncurses-dev autoconf \
bison subversion git sqlite nmap

if [ $? -ne 0 ]; then
    echo "ERROR: Dependency installation failed. Exiting."
    exit 1
fi
echo "    ...Packages installed successfully."

# --- Cleanup Build Dependencies (Optional but recommended for a minimal system) ---
# Dependencies like 'build-base' are no longer strictly needed after gem compilation.
# The commented section below can be uncommented to remove them.
# echo "--> Optional: Removing build dependencies..."
# apk del build-base ruby-dev libffi-dev openssl-dev readline-dev sqlite-dev postgresql-dev \
# libpcap-dev libxml2-dev libxslt-dev yaml-dev zlib-dev ncurses-dev bison autoconf \
# && rm -rf /var/cache/apk/*

## 2. Clone Metasploit Framework ##
echo "--> 2. Cloning Metasploit repository to $MSF_DIR..."
mkdir -p "$MSF_DIR"
git clone https://github.com/rapid7/metasploit-framework.git "$MSF_DIR"

if [ $? -ne 0 ]; then
    echo "ERROR: Cloning Metasploit repository failed. Exiting."
    exit 1
fi

## 3. Install Ruby Gems ##
echo "--> 3. Installing Ruby dependencies (this may take a while)..."
cd "$MSF_DIR"
bundle install --without development test > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "ERROR: Ruby gem installation failed. Check for missing dependencies."
    exit 1
fi
echo "    ...Ruby gems installed successfully."

## 4. Configure and Start PostgreSQL ##
echo "--> 4. Setting up and starting PostgreSQL database..."
# Initialize PostgreSQL data directory
su - postgres -c "initdb -D /var/lib/postgresql/data"

# Add PostgreSQL to runlevels and start the service
rc-service postgresql setup
rc-service postgresql start

# Create database user and database for Metasploit
su - postgres -c "create user $DB_USER with password '$DB_PASS';"
su - postgres -c "createdb -O $DB_USER msf"

# Create database configuration file for Metasploit
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

echo "    ...PostgreSQL configured."

## 5. Finalize and Launch ##
echo "--> 5. Installation complete."
echo ""
echo "To launch Metasploit console (msfconsole), run the following command:"
echo "    $MSF_DIR/msfconsole"
echo "To verify database connection, run 'db_status' inside msfconsole."
