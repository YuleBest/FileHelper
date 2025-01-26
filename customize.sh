#!/system/bin/sh
# By Yule
# 安装脚本
# 此脚本中使用 $MODPATH 而不是 $MODDIR
SKIPUNZIP=0

if [ "$(magisk -V)" -gt "28000" ]; then
    echo "- Magisk 版本为 $(magisk -V) ≥ 28000"
    echo "- ✅ 符合要求，为您开启 action.sh 脚本"
    cp $MODPATH/yule/scripts/action.sh $MODPATH/
    echo "- 后续您可通过 Magisk 管理器来实时启用或关闭模块"
else
    echo "- Magsik 版本为 $(magisk -V) ＜ 28000"
    echo "- 😭 不符合要求，不开启 action.sh 脚本"
fi

echo "* 是否需要为您创建测试体验项目？"
echo "  (您手动删除后不会再创建)"
echo "> 按音量 + 键确认创建 (新手推荐)"
echo "> 按音量 - 键不创建"

key_click=""
while [ "$key_click" = "" ]; do
    key_click="$(getevent -qlc 1 | awk '{ print $3 }' | grep 'KEY_')"
    sleep 0.2
done
case "$key_click" in
    "KEY_VOLUMEUP")
        mkdir -p /sdcard/测试目录/测试源目录A
        mkdir -p /sdcard/测试目录/测试源目录B
        mkdir -p /sdcard/测试目录/测试终目录A
        mkdir -p /sdcard/测试目录/测试终目录B
        mkdir -p "$MODPATH/config/OPDIR/confs"
        echo 'U0RJUj0iL3NkY2FyZC/mtYvor5Xnm67lvZUv5rWL6K+V5rqQ55uu5b2VQSIKVERJUj0iL3NkY2FyZC/mtYvor5Xnm67lvZUv5rWL6K+V57uI55uu5b2VQSIKTU9ERT0ibW92ZSIK' | base64 -d > "$MODPATH/config/OPDIR/confs/1"
        echo -n 'U0RJUj0iL3NkY2FyZC/mtYvor5Xnm67lvZUv5rWL6K+V5rqQ55uu5b2VQiIKVERJUj0iL3NkY2FyZC/mtYvor5Xnm67lvZUv5rWL6K+V57uI55uu5b2VQiIKTU9ERT0ibW92ZSIK' | base64 -d > "$MODPATH/config/OPDIR/confs/2"
        echo "- ✅ 已为您创建测试体验项目"
        echo "- 体验项目: /sdcard/测试目录"
    ;;
    *)
esac

echo "- ✅ 安装完成，请重启生效"
echo "- 配置本模块: /data/adb/module/FileHelper/config/"
echo "- 请先阅读:   /data/adb/module/FileHelper/README.md"