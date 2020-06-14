# Diffusion Installer Config
# osm0sis @ xda-developers

INST_NAME="Nexus Media Installer Script";
AUTH_NAME="osm0sis @ xda-developers";

USE_ARCH=true
USE_ZIP_OPTS=true

custom_setup() {
  return # stub
}

custom_zip_opts() {
  case $choice in
    *noreplace*|*NoReplace*|*NOREPLACE*) NOREPLACE=1;;
  esac;

  # default to hammerhead if none specified
  MEDIA=bullhead;

  # install based on name if present
  ui_print " ";
  case $choice in
    *hammerhead*) MEDIA=hammerhead;;
    *flo*|*deb*) MEDIA=flo;;
    *shamu*) MEDIA=shamu;;
    *volantis*) MEDIA=volantis;;
    *bullhead*) MEDIA=bullhead;;
    *angler*) MEDIA=angler;;
    *) ui_print "Warning: Invalid or no media choice found in filename, fallback to default!"; ui_print " ";;
  esac;
  ui_print "Using media directory: $MEDIA";
}

custom_target() {
  # make room on new installs for media which may not fit in su.img/magisk.img if there are other mods
  if [ "$SUIMG" -a ! -e /dev/tmp/su/su.d/000mediamount -a ! -e /su/su.d/000mediamount -a ! -e /dev/tmp/magisk/nexusmedia/module.prop -a ! -e /magisk/nexusmedia/module.prop -a ! -e /sbin/.core/img/nexusmedia/module.prop -a ! -e /sbin/.magisk/img/nexusmedia/module.prop -a "$(which e2fsck)" ]; then
    umount $MNT;
    test "$LOOP" && losetup -d $LOOP;
    payload_size_check "$ZIPFILE" $MEDIA common;
    target_size_check $SUIMG;
    if [ "$reqSizeM" -gt "$curFreeM" ]; then
      suNewSizeM=$((((reqSizeM + curUsedM) / 32 + 1) * 32));
      ui_print " ";
      ui_print 'Resizing '"$(basename $SUIMG)"' to '"$suNewSizeM"'M ...';
      e2fsck -yf $SUIMG;
      resize2fs $SUIMG "$suNewSizeM"M;
    fi;
    mount_su;
  fi;
}

custom_install() {
  # work around scenarios where toybox's limited tar would be used (old Magisk Manager PATH issue, TWRPs without busybox)
  tar -xzf xz.tar.gz $ARCH/xz;
  set_perm 0 0 755 $ARCH/xz;
  case $MEDIA in
    hammerhead|flo) $ARCH/xz -dc common-5-7.tar.xz | tar -x;;
    shamu|volantis) $ARCH/xz -dc common-6-9-5x-6p.tar.xz | tar -x;;
    bullhead|angler) $ARCH/xz -dc common-6-9-5x-6p.tar.xz | tar -x; $ARCH/xz -dc common-5x-6p.tar.xz | tar -x;;
  esac;
  case $MEDIA in
    shamu|bullhead|angler) $ARCH/xz -dc common-6-5x-6p.tar.xz | tar -x;;
  esac;
  $ARCH/xz -dc common.tar.xz | tar -x;
  $ARCH/xz -dc $MEDIA.tar.xz | tar -x;
  ui_print " ";
  if [ -d common -a -d "$MEDIA" ]; then
    ui_print "Installing to $TARGET/media ...";
    rm -rf $TARGET/media;
    mkdir -p $TARGET/media;
    cp -rf common/* $TARGET/media/;
    cp -rf $MEDIA/* $TARGET/media/;
  else
    ui_print "Extraction error!";
    abort;
  fi;
  set_perm_recursive 0 0 755 644 $TARGET/media;

  if [ "$MNT" == /dev/tmp/su -o "$MNT" == /su -o "$BINDSBIN" ]; then
    ui_print "Installing 000mediamount script to $MNT/su.d ...";
    cp -rf su.d/* $MNT/su.d;
    set_perm 0 0 755 $MNT/su.d/000mediamount;
  elif [ "$MAGISK" ]; then
    ui_print "Installing Magisk configuration files ...";
    sed -i "s/version=.*/version=${MEDIA}/g" module.prop;
    if [ "$NOREPLACE" ]; then
      touch $TARGET/media/audio/.noreplace;
    else
      touch $TARGET/media/audio/.replace;
      rm -f $TARGET/media/audio/.noreplace;
    fi;
    # check Magisk version code to find if basic mount is supported and which method to use
    local basicmnt i serviced vercode;
    vercode=$(file_getprop /data/$ADB/magisk/util_functions.sh MAGISK_VER_CODE 2>/dev/null);
    if [ "$vercode" -le 19001 ]; then
      mv -f $TARGET/media/bootanimation.zip $MNT/$MODID/bootanimation.zip;
      cp -f post-fs-data.sh $MNT/$MODID/;
      serviced=`(ls -d /sbin/.core/img/.core/service.d || ls -d /sbin/.magisk/img/.core/service.d || ls -d $MNT/.core/service.d || ls -d /data/adb/service.d) 2>/dev/null`;
      ui_print "Using service.d cleanup script: $serviced";
      cp -rf service.d/* $serviced;
      set_perm 0 0 755 $serviced/000mediacleanup;
      if [ "$vercode" -lt 1640 ]; then
        basicmnt=/cache/magisk_mount;
      else
        basicmnt=/data/adb/magisk_simple;
      fi;
      ui_print "Using basic early mount bootanimation: $basicmnt";
      mkdir -p $basicmnt/system/media;
      cp -rf $MNT/$MODID/bootanimation.zip $basicmnt/system/media/;
    fi;
  elif [ -e $TARGET/addon.d ]; then
    ui_print "Installing 90-media.sh script to /system/addon.d ...";
    cp -rf addon.d/* $TARGET/addon.d;
    set_perm 0 0 755 $TARGET/addon.d/90-media.sh;
  fi;
}

custom_postinstall() {
  return # stub
}

custom_uninstall() {
  if [ ! "$SUIMG" -a ! "$BINDSBIN" -a ! "$MAGISK" ]; then
    rm -f $TARGET/addon.d/90-media.sh;
    ui_print " ";
    ui_print "Removed 90-media.sh addon.d script! Dirty flash your ROM to complete uninstall.";
  else
    rm -rf $MNT/su.d/000mediamount $TARGET/media;
  fi;
}

custom_postuninstall() {
  return # stub
}

custom_cleanup() {
  return # stub
}

custom_exitmsg() {
  return # stub
}

# additional custom functions
payload_size_check() {
  local entry item zip;
  zip="$1";
  shift;
  for item in "$@"; do
    echo " $item" >> grepfile.tmp;
  done;
  reqSizeM=0;
  for entry in $(unzip -l "$zip" 2>/dev/null | grep -f grepfile.tmp | tail -n +4 | awk '{ print $1 }'); do
    test $entry != "--------" && reqSizeM=$((reqSizeM + entry)) || break;
  done;
  test $reqSizeM -lt 1048576 && reqSizeM=1 || reqSizeM=$((reqSizeM / 1048576));
  rm -f grepfile.tmp;
}

target_size_check() {
  curBlocks=$(e2fsck -n $1 2>/dev/null | cut -d, -f3 | cut -d\  -f2);
  curUsedM=$((`echo "$curBlocks" | cut -d/ -f1` * 4 / 1024));
  curSizeM=$((`echo "$curBlocks" | cut -d/ -f2` * 4 / 1024));
  curFreeM=$((curSizeM - curUsedM));
}

