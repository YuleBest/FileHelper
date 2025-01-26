#!/system/bin/sh
# By Yule
# 设定面具模块状态
# Only Magisk 28001 or KSU 1.03 or above
MODDIR=${0%/*}

STOP_FILE="$MODDIR/STOP"
if [ ! -d "$STOP_FILE" ]; then
    touch $STOP_FILE
    echo "- 模块已开启"
else
    rm -f $STOP_FILE
    echo "- 模块已关闭"
fi
sleep 2
exit 0