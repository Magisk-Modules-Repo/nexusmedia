#!/system/bin/sh

MODDIR=${0%/*};

# restore boot animation for Magisk post-fs mode loading
if [ ! -f /cache/magisk_mount/system/media/bootanimation.zip ]; then
  mkdir -p /cache/magisk_mount/system/media;
  cp -rf $MODDIR/bootanimation.zip /cache/magisk_mount/system/media/;
fi;

