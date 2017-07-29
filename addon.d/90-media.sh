#!/sbin/sh
# 
# /system/addon.d/90-media.sh
# For ROMs with waaaayy too many AOSP/CM ringtones so they have been replaced.
# Installed as part of Nexus Media Installer.
#
# During an upgrade, this script backs up the media directory,
# /system is formatted and reinstalled, then the media files are restored.
#
# osm0sis @ xda-developers

. /tmp/backuptool.functions

# Only constant files known
save_files() {
cat <<EOF
media/bootanimation.zip
EOF
}

case "$1" in
  backup)
    save_files | while read FILE DUMMY; do
      backup_file $S/"$FILE"
    done
    # Backup custom system sounds manually since files can differ across devices
    cp -rpf /system/media/audio /tmp/audio
  ;;
  restore)
    save_files | while read FILE REPLACEMENT; do
      R=""
      [ -n "$REPLACEMENT" ] && R="$S/$REPLACEMENT"
      [ -f "$C/$S/$FILE" ] && restore_file $S/"$FILE" "$R"
    done
  ;;
  pre-backup)
    # Stub
  ;;
  post-backup)
    # Stub
  ;;
  pre-restore)
  ;;
  post-restore)
    # Wipe ROM system sounds then restore custom
    rm -rf /system/media/audio
    cp -rpf /tmp/audio /system/media/
    rm -rf /tmp/audio
  ;;
esac

