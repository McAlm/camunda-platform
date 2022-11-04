#!/bin/bash

set -e
set -u

function create_user_and_database() {
	local database=$1
	local user=$2
	local password=$3
	echo "  Creating user and database '$database'"
	psql -v ON_ERROR_STOP=1 --dbname "$POSTGRES_DB" --username "$POSTGRES_USER" <<-EOSQL
	    CREATE USER "$user" WITH PASSWORD '$password';
	    CREATE DATABASE "$database";
	    GRANT ALL PRIVILEGES ON DATABASE "$database" TO "$user";
EOSQL
}


if [ -n "$POSTGRES_ADDITIONAL_DATABASES" ]; then
	echo "Multiple database creation requested: $POSTGRES_ADDITIONAL_DATABASES"
	for db in $(echo $POSTGRES_ADDITIONAL_DATABASES | tr ',' ' '); do

		userVar=$(sed "s/${db}/POSTGRES_${db}_USER/g" <<< ${db})
		userEnv=$(env | grep -i ${userVar} )
		dbUserVal=$(awk '{ sub(/.*=/, ""); print }' <<< ${userEnv})
		
		passwordVar=$(sed "s/${db}/POSTGRES_${db}_PASSWORD/g" <<< ${db})
		passwordEnv=$(env | grep -i ${passwordVar} )
		dbPasswordVal=$(awk '{ sub(/.*=/, ""); print }' <<< ${passwordEnv})

		create_user_and_database $db $dbUserVal $dbPasswordVal
	done
	echo "Multiple databases created"
fi
