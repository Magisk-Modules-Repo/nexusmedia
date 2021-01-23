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
  ZIPMEDIA=bullhead;

  # install based on name if present
  ui_print " ";
  case $choice in
    *hammerhead*) ZIPMEDIA=hammerhead;;
    *flo*|*deb*) ZIPMEDIA=flo;;
    *shamu*) ZIPMEDIA=shamu;;
    *volantis*) ZIPMEDIA=volantis;;
    *bullhead*) ZIPMEDIA=bullhead;;
    *angler*) ZIPMEDIA=angler;;
    *) ui_print "Warning: Invalid or no media choice found in filename, fallback to default!"; ui_print " ";;
  esac;
  ui_print "Using media directory: $ZIPMEDIA";
}

custom_target() {
  # make room on new installs for media which may not fit in su.img/magisk.img if there are other mods
  if [ "$SUIMG" -a ! -e /dev/tmp/su/su.d/000mediamount -a ! -e /su/su.d/000mediamount -a ! -e /dev/tmp/magisk/nexusmedia/module.prop -a ! -e /magisk/nexusmedia/module.prop -a ! -e /sbin/.core/img/nexusmedia/module.prop -a ! -e /sbin/.magisk/img/nexusmedia/module.prop -a "$(which e2fsck)" ]; then
    umount $MNT;
    [ "$LOOP" ] && losetup -d $LOOP;
    payload_size_check "$ZIPFILE" $ZIPMEDIA common;
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
  # support /system/product/media on /data/adb/modules Magisk and /system installs (also supported for SuperSU via su.d)
  MEDIA=media;
  if [ ! "$SUIMG" -a ! "$BINDSBIN" -a -e /system/product/media ]; then
    MEDIA=product/media;
  fi;
}

custom_install() {
  # work around scenarios where toybox's limited tar would be used (old Magisk Manager PATH issue, TWRPs without busybox)
  tar -xzf xz.tar.gz $ARCH/xz;
  set_perm 0 0 755 $ARCH/xz;
  case $ZIPMEDIA in
    hammerhead|flo) $ARCH/xz -dc common-5-7.tar.xz | tar -x;;
    shamu|volantis) $ARCH/xz -dc common-6-9-5x-6p.tar.xz | tar -x;;
    bullhead|angler) $ARCH/xz -dc common-6-9-5x-6p.tar.xz | tar -x; $ARCH/xz -dc common-5x-6p.tar.xz | tar -x;;
  esac;
  case $ZIPMEDIA in
    shamu|bullhead|angler) $ARCH/xz -dc common-6-5x-6p.tar.xz | tar -x;;
  esac;
  $ARCH/xz -dc common.tar.xz | tar -x;
  $ARCH/xz -dc $ZIPMEDIA.tar.xz | tar -x;
  ui_print " ";
  if [ -d common -a -d "$ZIPMEDIA" ]; then
    ui_print "Installing to $TARGET/$MEDIA ...";
    rm -rf $TARGET/$MEDIA;
    mkdir -p $TARGET/$MEDIA;
    cp -rf common/* $TARGET/$MEDIA/;
    cp -rf $ZIPMEDIA/* $TARGET/$MEDIA/;
  else
    ui_print "Extraction error!";
    abort;
  fi;
  set_perm_recursive 0 0 755 644 $TARGET/$MEDIA;

  if [ "$MNT" == /dev/tmp/su -o "$MNT" == /su -o "$BINDSBIN" ]; then
    ui_print "Installing 000mediamount script to $MNT/su.d ...";
    cp -rf su.d/* $MNT/su.d;
    set_perm 0 0 755 $MNT/su.d/000mediamount;
  elif [ "$MAGISK" ]; then
    ui_print "Installing Magisk configuration files ...";
    sed -i "s/version=.*/version=${ZIPMEDIA}/g" module.prop;
    if [ "$NOREPLACE" ]; then
      touch $TARGET/$MEDIA/audio/.noreplace;
    else
      touch $TARGET/$MEDIA/audio/.replace;
      rm -f $TARGET/$MEDIA/audio/.noreplace;
    fi;
    # check Magisk version code to find if basic mount is supported and which method to use
    local basicmnt i serviced vercode;
    vercode=$(file_getprop /data/$ADB/magisk/util_functions.sh MAGISK_VER_CODE 2>/dev/null);
    if [ "$vercode" -le 19001 ]; then
      mv -f $TARGET/$MEDIA/bootanimation.zip $MNT/$MODID/bootanimation.zip;
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
      mkdir -p $basicmnt/system/$MEDIA;
      cp -rf $MNT/$MODID/bootanimation.zip $basicmnt/system/$MEDIA/;
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
    rm -rf $MNT/su.d/000mediamount $TARGET/$MEDIA;
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
    if [ $entry != "--------" ]; then
      reqSizeM=$((reqSizeM + entry));
    else
      break;
    fi;
  done;
  if [ $reqSizeM -lt 1048576 ]; then
    reqSizeM=1;
  else
    reqSizeM=$((reqSizeM / 1048576));
  fi;
  rm -f grepfile.tmp;
}

target_size_check() {
  curBlocks=$(e2fsck -n $1 2>/dev/null | cut -d, -f3 | cut -d\  -f2);
  curUsedM=$((`echo "$curBlocks" | cut -d/ -f1` * 4 / 1024));
  curSizeM=$((`echo "$curBlocks" | cut -d/ -f2` * 4 / 1024));
  curFreeM=$((curSizeM - curUsedM));
}

