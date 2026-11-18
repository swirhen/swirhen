# /bin/sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"
LOGFILE="${SCRIPT_DIR}/logs/daily_backup.log"
echo "# DAILY BACKUP START: `date`" > "${LOGFILE}"
# book
rsync -auv --delete --exclude '.DAV' /sora_data2/book/ /backup1/book/ >> "${LOGFILE}"
# v_old
rsync -auv --delete --exclude '.DAV' /sora_data1/v_old/ /backup2/v_old/ >> "${LOGFILE}"
# anime_old, anime_lib3
rsync -auv --delete --exclude '.DAV' /sora_data2/anime_old/ /backup5/anime_old/ >> "${LOGFILE}"
rsync -auv --delete --exclude '.DAV' /sora_data1/anime_lib3/ /backup3/anime_lib3/ >> "${LOGFILE}"
# share, idol_media
rsync -auv --delete --exclude '.DAV' /sora_data1/share/ /backup1/share/ >> "${LOGFILE}"
rsync -auv --delete --exclude '.DAV' /sora_data3/idol_media/ /backup4/idol_media/ >> "${LOGFILE}"

echo "# DAILY BACKUP END: `date`" >> "${LOGFILE}"
