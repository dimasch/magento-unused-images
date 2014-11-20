#!/bin/bash
MAGENTO_PATH="/var/www/magento"
LOG=${MAGENTO_PATH}/var/log/imagecleanup.log
DB_USER=$(sed -n 's|<username><\!\[CDATA\[\(.*\)\]\]></username>|\1|p' ${MAGENTO_PATH}/app/etc/local.xml | tr -d ' ')
DB_PASS=$(sed -n 's|<password><\!\[CDATA\[\(.*\)\]\]></password>|\1|p' ${MAGENTO_PATH}/app/etc/local.xml | tr -d ' ')
DB_NAME=$(sed -n 's|<dbname><\!\[CDATA\[\(.*\)\]\]></dbname>|\1|p' ${MAGENTO_PATH}/app/etc/local.xml | tr -d ' ')
DB_PREFIX=$(sed -n 's|<table_prefix><\!\[CDATA\[\(.*\)\]\]></table_prefix>|\1|p' ${MAGENTO_PATH}/app/etc/local.xml | tr -d ' ')

function search_db() {
        COUNT=$(mysql -u ${DB_USER} -p ${DB_PASS} ${DB_NAME} --execute="SELECT count(*) FROM ${DB_PREFIX}catalog_product_entity_media_gallery WHERE value = \"$1\"")
        echo $(echo ${COUNT} | cut -d" " -f2)
}

echo "Starting image cleanup " $(date) | tee -a ${LOG}
IMG_PATH=${MAGENTO_PATH}/media/catalog/product/
for IMG in $(find ${IMG_PATH} -name '*.jpg' ! -path '*cache*' ! -name 'google*'); do
        REL_IMG=/${IMG:${#IMG_PATH}}
        if [ $(search_db ${REL_IMG/'${MAGENTO_PATH}/media/catalog/product'/}) != 1 ]; then
                IMG=${IMG##*/}
                for CACHE_IMG in $(find ${MAGENTO_PATH}/media/catalog/product/ -name "${IMG}"); do
                        echo "Found unused image ${CACHE_IMG}"
                        if [ "$1" ] && [ $1 == 'cleanup' ]; then
                                echo "Removing unused image ${CACHE_IMG}" | tee -a ${LOG}
                                rm "${CACHE_IMG}"
                        fi
                done
        else 
                echo "Not touching " ${IMG}
        fi
done
echo "Finished image cleanup " $(date) | tee -a ${LOG}
