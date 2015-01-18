#!/bin/bash

if [[ ! -z $E_DB_DUMP && ! -z $E_DB_NAME && -f /db/$E_DB_DUMP ]]; then
    echo "Deploing DB"
    mysql -uroot $E_DB_NAME < /db/$E_DB_DUMP;
fi

if [[ ! -z $E_DB_TEST_DUMP && ! -z $E_DB_TEST_NAME && -f /db/$E_DB_TEST_DUMP ]]; then
    echo "Deploing test DB"
    mysql -uroot $E_DB_TEST_NAME < /db/$E_DB_TEST_DUMP;
fi

