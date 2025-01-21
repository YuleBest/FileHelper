#!/system/bin/sh
# By Yule
# 设定一些文件和目录的变量，此脚本只能使用第一层的脚本作为入口点，不能使用sh来执行，否则路径会出错

MODDIR=${0%/*}
log_file="$MODDIR/service_running.log"
OPDIR_CONFIGS="$MODDIR/config/OPDIR" # 这是一个目录
SYSTEM_CONFIG="$MODDIR/config/SYSTEM/config.prop"