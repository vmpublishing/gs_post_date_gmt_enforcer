#!/usr/bin/env bash

SCRIPTPATH=$( cd $(dirname "${BASH_SOURCE[0]}"); pwd -P)
NORMALIZED_SCRIPT_PATH=`echo $SCRIPTPATH | sed -e "s/workspace\/bin/bin/g"`
PLUGIN_NAME=`echo $NORMALIZED_SCRIPT_PATH | sed -e "s/.*\/\([^\/]*\)\(\/workspace\)\?\/bin$/\1/g"`
DB_NAME="${PLUGIN_NAME}_tests"
PLUGIN_CONST=`echo $PLUGIN_NAME | awk '{print toupper($0)}'`
DEFAULTS_FILE=${DEFAULTS_FILE-"$HOME/.my.cnf.gruenderszene_tests"}
WP_VERSION=${1-latest}
DB_USER=`grep -R "user"      $DEFAULTS_FILE | head -1 | sed 's/user="\(.*\)"/\1/'`
DB_PASS=`grep -R "password"  $DEFAULTS_FILE | head -1 | sed 's/password="\(.*\)"/\1/'`
DB_HOST=`grep -R "host"      $DEFAULTS_FILE | head -1 | sed 's/host="\(.*\)"/\1/'`
DB_PORT=`grep -R "port"      $DEFAULTS_FILE | head -1 | sed 's/port="\(.*\)"/\1/'`

## error section
ERR_MYSQL_CONFIG_FILE_MISSING=1
ERR_MYSQL_DATABASE_USER_MISSING=2
ERR_WORPRESS_VERSION_NOT_FOUND=3
ERR_PLUGIN_NAME_NOT_FOUND=4

if [ ! -f $DEFAULTS_FILE ]; then
  echo "mysql defaults file '$DEFAULTS_FILE' not found";
  exit $ERR_MYSQL_CONFIG_FILE_MISSING;
fi

if [ -z "$DB_USER" ]; then
  echo "no db_user set";
  exit $ERR_MYSQL_DATABASE_USER_MISSING;
fi

if [ -z "$PLUGIN_NAME" ]; then
  echo "no plugin name";
  exit $ERR_PLUGIN_NAME_NOT_FOUND;
else
  echo "PLUGIN_NAME: ${PLUGIN_NAME}"
fi

WP_TESTS_DIR="${HOME}/.tmp/${PLUGIN_NAME}/wordpress-tests-lib"
WP_CORE_DIR="${HOME}/.tmp/${PLUGIN_NAME}/wordpress"

download() {
    if [ `which curl` ]; then
        curl -s "$1" > "$2";
    elif [ `which wget` ]; then
        wget -nv -O "$2" "$1";
    fi
}

if [[ $WP_VERSION =~ [0-9]+\.[0-9]+(\.[0-9]+)? ]]; then
	WP_TESTS_TAG="tags/$WP_VERSION"
elif [[ $WP_VERSION == 'nightly' || $WP_VERSION == 'trunk' ]]; then
	WP_TESTS_TAG="trunk"
else
	# http serves a single offer, whereas https serves multiple. we only want one
	download http://api.wordpress.org/core/version-check/1.7/ /tmp/wp-latest.json
	grep '[0-9]+\.[0-9]+(\.[0-9]+)?' /tmp/wp-latest.json
	LATEST_VERSION=$(grep -o '"version":"[^"]*' /tmp/wp-latest.json | sed 's/"version":"//')
	if [[ -z "$LATEST_VERSION" ]]; then
		echo "Latest WordPress version could not be found";
		exit $ERR_WORPRESS_VERSION_NOT_FOUND;
	fi
	WP_TESTS_TAG="tags/$LATEST_VERSION"
fi

set -ex

install_wp() {

	if [ -d $WP_CORE_DIR ]; then
		return;
	fi

	mkdir -p $WP_CORE_DIR

	if [[ $WP_VERSION == 'nightly' || $WP_VERSION == 'trunk' ]]; then
		mkdir -p /tmp/wordpress-nightly
		download https://wordpress.org/nightly-builds/wordpress-latest.zip  /tmp/wordpress-nightly/wordpress-nightly.zip
		unzip -q /tmp/wordpress-nightly/wordpress-nightly.zip -d /tmp/wordpress-nightly/
		mv /tmp/wordpress-nightly/wordpress/* $WP_CORE_DIR
	else
		if [ $WP_VERSION == 'latest' ]; then
			local ARCHIVE_NAME='latest'
		else
			local ARCHIVE_NAME="wordpress-$WP_VERSION"
		fi
		download https://wordpress.org/${ARCHIVE_NAME}.tar.gz  /tmp/wordpress.tar.gz
		tar --strip-components=1 -zxmf /tmp/wordpress.tar.gz -C $WP_CORE_DIR
	fi

	download https://raw.github.com/markoheijnen/wp-mysqli/master/db.php $WP_CORE_DIR/wp-content/db.php
}

install_test_suite() {
	# portable in-place argument for both GNU sed and Mac OSX sed
	if [[ $(uname -s) == 'Darwin' ]]; then
		local ioption='-i .bak'
	else
		local ioption='-i'
	fi

	# set up testing suite if it doesn't yet exist
  rm -rf $WP_TESTS_DIR
	if [ ! -d $WP_TESTS_DIR ]; then
		# set up testing suite
		mkdir -p $WP_TESTS_DIR
		svn co --quiet https://develop.svn.wordpress.org/${WP_TESTS_TAG}/tests/phpunit/includes/ $WP_TESTS_DIR/includes
	fi

	if [ ! -f wp-tests-config.php ]; then
		download https://develop.svn.wordpress.org/${WP_TESTS_TAG}/wp-tests-config-sample.php "$WP_TESTS_DIR"/wp-tests-config.php
		# remove all forward slashes in the end
		WP_CORE_DIR=$(echo $WP_CORE_DIR | sed "s:/\+$::")
		sed $ioption "s:dirname( __FILE__ ) . '/src/':'$WP_CORE_DIR/':" "$WP_TESTS_DIR"/wp-tests-config.php
		sed $ioption "s/youremptytestdbnamehere/$DB_NAME/" "$WP_TESTS_DIR"/wp-tests-config.php
		sed $ioption "s/yourusernamehere/$DB_USER/" "$WP_TESTS_DIR"/wp-tests-config.php
		sed $ioption "s/yourpasswordhere/$DB_PASS/" "$WP_TESTS_DIR"/wp-tests-config.php
		sed $ioption "s|localhost|${DB_HOST}|" "$WP_TESTS_DIR"/wp-tests-config.php
	fi

}

install_db() {
	# create database
	`mysql --defaults-file=${DEFAULTS_FILE} -e "CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8 COLLATE utf8_general_ci"`
}

install_wp
install_test_suite
install_db
