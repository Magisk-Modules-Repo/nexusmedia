#!/system/bin/sh

MODDIR=${0%/*};

# restore boot animation for Magisk post-fs mode loading
if [ ! -f /cache/magisk_mount/system/media/bootanimation.zip -o ! -f /data/adb/magisk_simple/system/media/bootanimation.zip ]; then
  mkdir -p /cache/magisk_mount/system/media /data/adb/magisk_simple/system/media;
  cp -rf $MODDIR/bootanimation.zip /cache/magisk_mount/system/media/;
  cp -rf $MODDIR/bootanimation.zip /data/adb/magisk_simple/system/media/;
fi;
