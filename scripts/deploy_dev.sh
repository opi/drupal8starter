#!/bin/bash

function greenecho {
    echo "" && echo -e "\e[30;48;5;82m ✔ $1 \e[0m"
}
function orangeecho {
    echo "" && echo -e "\e[30;48;5;208m ⚠ $1 \e[0m"
}

# Get document root path
DOCUMENT_ROOT=$(drush status --fields=root --format=list)

# Git repo root
cd $DOCUMENT_ROOT && cd ..

# Get fresh sources
greenecho "Update sources"
git pull origin master

# Backup database
greenecho "Backup database"
drush sql-dump > /backups/projectname_`date +%Y-%m-%d_%H-%M-%S`.sql
echo "Database backup in /backups/projectname_`date +%Y-%m-%d_%H-%M-%S`.sql"

# Update dependencies
greenecho "Update dependencies (composer install)"
composer install

# Update database
greenecho "Update database"
drush updb -y

# Import new configuration
greenecho "Import configuration changes"
drush config-import -y

# Update entites schema
greenecho "Update entites schema"
drush entup

# Update locales
greenecho "Update translations"
drush locale-update

# Refresh cache
greenecho "Refresh caches"
drush cr
