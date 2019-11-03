#!/sbin/sh
#
# ADDOND_VERSION=2
#
# /system/addon.d/90-media.sh
# For ROMs with waaaayy too many AOSP/LOS ringtones so they have been replaced.
# Installed as part of Nexus Media Installer.
#
# During an upgrade, this script backs up the media directory,
# /system is formatted and reinstalled, then the media files are restored.
#
# osm0sis @ xda-developers

V1_FUNCS=/tmp/backuptool.functions
V2_FUNCS=/postinstall/system/bin/backuptool_ab.functions

if [ -f $V1_FUNCS ]; then
  . $V1_FUNCS
  backuptool_ab=false
elif [ -f $V2_FUNCS ]; then
  . $V2_FUNCS
else
  return 1
fi

# Only constant files known
list_files() {
cat <<EOF
media/bootanimation.zip
EOF
}

case "$1" in
  backup)
    list_files | while read FILE DUMMY; do
      backup_file $S/"$FILE"
    done
    # Backup custom system sounds manually since files can differ across devices
    cp -rpf $S/media/audio $C/$S/media/audio
  ;;
  restore)
    list_files | while read FILE REPLACEMENT; do
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
    $backuptool_ab && P=/postinstall

    # Wipe ROM system sounds then restore custom
    test -f $C/$S/media/audio/.noreplace || rm -rf $P/$S/media/audio
    cp -rpf $C/$S/media/audio $P/$S/media/
    rm -rf $C/$S/media/audio
  ;;
esac

