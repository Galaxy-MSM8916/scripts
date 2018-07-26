LIST="
/etc/apache2
/etc/crontab
/etc/screenrc
/etc/letsencrypt
/etc/monit
/etc/transmission-daemon
/root
/home
/var/lib/transmission-daemon/.config/transmission-daemon
/var/www
"

EXCLUDE="
download.msm8916.com/public_html
builds/full
.vim
.cache
.local
.jenkins
"

TEMP_DIR=$(mktemp -d)

EXCLUSIONS_FILE=${TEMP_DIR}/exclusions.txt

echo "$EXCLUDE" > ${EXCLUSIONS_FILE}

BACKUP_NAME=${TEMP_DIR}/"backup-$(date +%d-%m-%Y-%H%M).tar.gz"

TAR=$(which tar)
TAR_OPTS="-cvz --exclude-vcs --exclude-from=${EXCLUSIONS_FILE} -f ${BACKUP_NAME} ${LIST}" 

${TAR} ${TAR_OPTS} | tee ${BACKUP_NAME}.list

ssh jenkins@msm8916.com "mkdir /backups/$(hostname) -p" && scp ${BACKUP_NAME}* jenkins@msm8916.com:/backups/$(hostname)/

rm -rf ${TEMP_DIR}
