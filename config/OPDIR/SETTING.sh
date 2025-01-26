#!/system/bin/sh
# By Yule
# 操作目录设置脚本
# 让用户轻松地设置，禁止使用别的脚本来执行本脚本
clear
MYDIR=${0%/*}
MODDIR=${0%/*/*/*}
pro_num=$(find $MYDIR/confs -type f | wc -l)

notice() {
    local tag=$1
    local title=$2
    local text=$3    
    su -lp 2000 -c "cmd notification post -t \"$title\" -S bigtext \"$tag\" \"$text\"" 2>&1 > /dev/null
}

if [ "$(id -u)" -ne 0 ]; then
    echo "UID: $(id -u)"
    echo "- 未获得 Root 权限，请授权"
    exit 1
fi

echo "- 欢迎使用文件重定向快速配置工具"
echo "- 此脚本可以让您快速且安全地配置模块"
echo "* 当前项目数量: $pro_num"
echo ''
echo "---------------------------------"

while true; do
    echo "- [a] 创建新项目"
    echo "- [b] 查看和修改项目"
    echo "- [c] 删除项目"
    echo -n "- 请选择功能: "
    read user_input
    case $user_input in
        a)
            break
            ;;
        b)
            break
            ;;
        c)
            break
            ;;
        *)
            echo "> 请输入a-c来选择功能"
    esac
done

new_pro() {
    new_pro_filename=$(expr $pro_num + 1)
    new_pro_file="$MYDIR/confs/$new_pro_filename"
    
    echo "---------------------------------"
    echo -n "> 新项目源目录:"; read new_pro_sdir
    [ ! -d "$new_pro_sdir" ] && echo "x 目录不存在!" && exit 1
    echo -n "> 新项目终目录:"; read new_pro_tdir
    if [ ! -d "$new_pro_tdir" ] || [ "$new_pro_tdir" = "$new_pro_sdir" ]; then
        echo "x 目录不存在或与源目录相同"; exit 1
    fi
    echo -n "> 新项目操作模式(copy/move):"; read new_pro_mode
    if [ "$new_pro_mode" != "copy" ] && [ "$new_pro_mode" != "move" ]; then
        echo "x 选项不存在!"; exit 1
    fi
    echo "---------------------------------"
    
    touch $new_pro_file
    chmod 777 $new_pro_file
    echo "SDIR=\"$new_pro_sdir\"" >> $new_pro_file
    echo "TDIR=\"$new_pro_tdir\"" >> $new_pro_file
    echo "MODE=\"$new_pro_mode\"" >> $new_pro_file
    
    echo "* 新建项目 $new_pro_filename 完成"
}

old_pro() {
    echo "---------------------------------"
    echo "* 当前项目数量: $pro_num"
    echo "* 项目列表: "
    echo "$(ls $MYDIR/confs)"
    
    echo "---------------------------------"    
    echo -n "- 选择你要操作的项目:"
    read new_pro_filename
    new_pro_file="$MYDIR/confs/$new_pro_filename"
    [ ! -f $new_pro_file ] && echo "x 没有此项目" && exit 0
    echo "---------------------------------"
    
    source "$new_pro_file"
    echo "- 旧源目录:   $SDIR"
    echo "- 旧终目录:   $TDIR"
    echo "- 旧操作模式: $MODE"    
    echo "---------------------------------"
    
    echo -n "> 新源目录:"; read new_pro_sdir
    [ ! -d "$new_pro_sdir" ] && echo "x $new_pro_sdir 目录不存在!" && exit 1
    [ -z "$new_pro_sdir" ] && echo "x 目录未填写!" && exit 1
    echo -n "> 新终目录:"; read new_pro_tdir
    if [ ! -d "$new_pro_tdir" ] || [ "$new_pro_tdir" = "$new_pro_sdir" ]; then
        echo "x 目录不存在或与源目录相同"; exit 1
    fi
    [ -z "$new_pro_tdir" ] && echo "x 目录未填写!" && exit 1
    echo -n "> 新操作模式(copy/move/bind):"; read new_pro_mode
    if [ "$new_pro_mode" != "copy" ] && [ "$new_pro_mode" != "move" ] && ["$new_pro_mode" != "bind"  ]; then
        echo "x 选项不存在!"; exit 1
    fi
    [ -z "$new_pro_mode" ] && echo "x 模式未填写!" && exit 1
    echo "---------------------------------"
    
    echo "SDIR=\"$new_pro_sdir\"" > $new_pro_file
    echo "TDIR=\"$new_pro_tdir\"" >> $new_pro_file
    echo "MODE=\"$new_pro_mode\"" >> $new_pro_file
    
    echo "* 修改项目 $new_pro_filename 完成"
}

del_pro() {
    echo "---------------------------------"
    echo "* 当前项目数量: $pro_num"
    echo "* 项目列表: "
    echo "$(ls $MYDIR/confs)"
    
    echo "---------------------------------"    
    echo -n "- 选择你要删除的项目:"
    read new_pro_filename
    new_pro_file="$MYDIR/confs/$new_pro_filename"
    [ ! -f $new_pro_file ] && echo "x 没有此项目" && exit 0
    echo "---------------------------------"
    
    rm -f $new_pro_file
    echo "* 删除项目 $new_pro_filename 完成"
}

if [ $user_input = 'a' ]; then
    touch $MODDIR/STOP
    new_pro
    echo "* 设置完成！"
    cat $new_pro_file
    rm -f $MODDIR/STOP
elif [ $user_input = 'b' ]; then
    touch $MODDIR/STOP
    old_pro
    echo "* 设置完成！"
    cat $new_pro_file
    rm -f $MODDIR/STOP
elif [ $user_input = 'c' ]; then
    touch $MODDIR/STOP
    del_pro
    echo "* 设置完成！"
    rm -f $MODDIR/STOP
fi

notice "yule" "文件重定向 - 快速设置" "设置完成，所有修改将于稍后生效。"
rm -f $MODDIR/STOP
exit 0