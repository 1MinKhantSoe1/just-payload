#!/bin/bash

# --- Configuration ---
MSF_DIR="/opt/metasploit-framework"
DB_USER="msf"
DB_PASS="securepassword" # IMPORTANT: Change this password!

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
   echo "This script must be run as root or with sudo."
   exit 1
fi

echo "Starting Metasploit Framework installation on Alpine Linux..."
echo "This process may take a while, especially the bundle install step."
echo "------------------------------------------------------------------"

## 1. Install Dependencies (Corrected) ##
echo "--> 1. Installing required packages..."
# Removed 'ruby-io-console' and 'ruby-webrick' as they are not separate packages in Alpine 3.22.
# Their functionality is provided by the core 'ruby' package or installed later by 'bundle install'.
apk update
apk add build-base ruby ruby-bigdecimal ruby-bundler ruby-dev libffi-dev openssl-dev \
readline-dev sqlite-dev postgresql-dev libpcap-dev libxml2-dev libxslt-dev \
yaml-dev zlib-dev ncurses-dev autoconf bison subversion git sqlite nmap

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Dependency installation failed. Please check your network and repository configuration."
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
# The 'development' and 'test' groups are typically not needed for runtime.
bundle install --without development test

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Ruby gem installation failed. Check the output for missing libraries."
    exit 1
fi
echo "    ...Ruby gems installed successfully. ✅"

# ------------------------------------------------------------------

## 4. Configure and Start PostgreSQL ##
echo "--> 4. Setting up and starting PostgreSQL database..."

# Initialize PostgreSQL data directory and setup service
if [ ! -d "/var/lib/postgresql/data" ]; then
    echo "    Initializing PostgreSQL database..."
    /usr/bin/postgresql-setup -i
fi

# Add PostgreSQL to runlevels and start the service
rc-service postgresql start

# Wait briefly for the database to start
sleep 5

# Create database user and database for Metasploit
echo "    Creating Metasploit user and database..."
su - postgres -c "create user $DB_USER with password '$DB_PASS';" 2>/dev/null
su - postgres -c "createdb -O $DB_USER msf" 2>/dev/null

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

echo "    ...PostgreSQL configured. ✅"

# ------------------------------------------------------------------

## 5. Finalize and Launch ##
echo "--> 5. Installation complete. 🎉"
echo ""
echo "To launch Metasploit console (msfconsole), run the following command:"
echo "    $MSF_DIR/msfconsole"
echo "To verify database connection, run 'db_status' inside msfconsole."
