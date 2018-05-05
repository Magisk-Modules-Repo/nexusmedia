#!/system/bin/sh

MODDIR=${0%/*};

# check Magisk version code to find which basic mount method to use
test -e /data/adb/magisk && adb=adb;
MAGISK_VER_CODE=$(grep "^MAGISK_VER_CODE=" "/data/$adb/magisk/util_functions.sh" 2>/dev/null | cut -d= -f2);
if [ "$MAGISK_VER_CODE" -lt 1640 ]; then
  basicmnt="/cache/magisk_mount";
else
  basicmnt="/data/adb/magisk_simple";
fi;

# restore boot animation for Magisk simple mount mode loading
if [ ! -f $basicmnt/system/media/bootanimation.zip ]; then
  mkdir -p $basicmnt/system/media;
  cp -rf $MODDIR/bootanimation.zip $basicmnt/system/media/;
fi;
