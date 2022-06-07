# Create necessary directories and clone repository
mkdir -p ${DATA_DIR}/HP_P410i_Patch
mkdir -p /HP_P410i/lib/modules/${UNAME}/kernel/drivers/scsi /HP_P410i/usr/bin
cd ${DATA_DIR}/HP_P410i_Patch
git clone https://github.com/im-0/hpsahba
cd ${DATA_DIR}/HP_P410i_Patch/hpsahba

# Compile application HPSAHBA
make hpsahba -j${CPU_COUNT}
cp ${DATA_DIR}/HP_P410i_Patch/hpsahba/hpsahba /HP_P410i/usr/bin
cd ${DATA_DIR}/linux-$UNAME
rm -rf ${DATA_DIR}/linux-$UNAME/*.patch

# Copy patches from HPSAHBA, depending on Kernel version and compile module
TARGET_V="5.17.99"
COMPARE="${UNAME//-*/}
$TARGET_V"
if [ "$TARGET_V" != "$(echo "$COMPARE" | sort -V | tail -1)" ]; then
  rsync -av ${DATA_DIR}/HP_P410i_Patch/hpsahba/kernel/5.18-patchset-v2/ ${DATA_DIR}/linux-$UNAME
  find ${DATA_DIR}/linux-$UNAME -type f -iname '*.patch' -print0|xargs -n1 -0 patch -p 1 -i
else
  rsync -av ${DATA_DIR}/HP_P410i_Patch/hpsahba/kernel/5.13-patchset-v2/ ${DATA_DIR}/linux-$UNAME
  find ${DATA_DIR}/linux-$UNAME -type f -iname '*.patch' -print0|xargs -n1 -0 patch -p 1 -i
fi

#Compress modules
xz --check=crc32 --lzma2 /HP_P410i/lib/modules/${UNAME}/kernel/drivers/scsi/hpsa.ko

# Create Slackware package
PLUGIN_NAME="hpsahba"
BASE_DIR="/HP_P410i"
TMP_DIR="/tmp/${PLUGIN_NAME}_"$(echo $RANDOM)""
VERSION="$(date +'%Y.%m.%d')"
mkdir -p $TMP_DIR/$VERSION
cd $TMP_DIR/$VERSION
cp -R $BASE_DIR/* $TMP_DIR/$VERSION/
mkdir $TMP_DIR/$VERSION/install
tee $TMP_DIR/$VERSION/install/slack-desc <<EOF
       |-----handy-ruler------------------------------------------------------|
$PLUGIN_NAME: $PLUGIN_NAME Package contents:
$PLUGIN_NAME:
$PLUGIN_NAME: Source: https://github.com/im-0/hpsahba
$PLUGIN_NAME:
$PLUGIN_NAME:
$PLUGIN_NAME: Custom $PLUGIN_NAME package for Unraid Kernel v${UNAME%%-*} by ich777
$PLUGIN_NAME:
EOF
${DATA_DIR}/bzroot-extracted-$UNAME/sbin/makepkg -l n -c n $TMP_DIR/$PLUGIN_NAME-plugin-$UNAME-1.txz
md5sum $TMP_DIR/$PLUGIN_NAME-plugin-$UNAME-1.txz | awk '{print $1}' > $TMP_DIR/$PLUGIN_NAME-plugin-$UNAME-1.txz.md5