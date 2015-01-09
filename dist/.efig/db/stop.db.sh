#!/bin/bash

if [[ ! -z $E_DB_DUMP && ! -z $E_DB_NAME ]]; then
    echo "Backuping DB"
    mysqldump -uroot $E_DB_NAME > /db/$E_DB_DUMP;
fi

if [[ ! -z $E_DB_TEST_DUMP && ! -z $E_DB_TEST_NAME ]]; then
    echo "Backuping test DB"
    mysqldump -uroot $E_DB_TEST_NAME > /db/$E_DB_TEST_DUMP;
fi
