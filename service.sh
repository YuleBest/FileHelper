#!/system/bin/sh
# By Yule
# 长期服务 - 主逻辑
# 使用.来执行子脚本而不是sh

MODDIR=${0%/*}
COUNTER=$MODDIR/yule/counter
VARES=$MODDIR/yule/vares
log_file="$MODDIR/service_running.log"

echo -n '' > $log_file
. $MODDIR/yule/scripts/setvar.sh
. $MODDIR/config/SYSTEM/config.prop

LOGRCD() {
    local state=$1
    local block=$2
    local text=$3
    date_time=$(date +"%H:%M:%S.%3N")
    echo "$state | $date_time | [$block] $text" >> $log_file
}

notice() {
    local tag=$1
    local title=$2
    local text=$3    
    su -lp 2000 -c "cmd notification post -t \"$title\" -S bigtext \"$tag\" \"$text\"" 2>&1 > /dev/null
}

setmodprop() {
    new_prop_doc=$1
    prop_head="$MODDIR/yule/more/module.prop.head"
    new_prop="$MODDIR/yule/more/module.prop"
    
    cat "$prop_head" > "$new_prop"
    echo -n "$new_prop_doc" >> $new_prop    
    cp $new_prop "$MODDIR/module.prop"
    echo -n '' > $new_prop
}

should_skip_file() {
    is_protected_file() {
        local file="$1"
        local file_uid=$(ls -n "$file" | awk '{print $3}')
        if [ "$file_uid" -ge 0 ] && [ "$file_uid" -le 10000 ]; then
            return 0
        fi
        return 1
    }
    PROTECTED_DIRS="/acct|/apex|/bin|/bootstrap-apex|/cust|/d|/data/adb|/data_mirror|/debug_ramdisk|/dev|/etc|/linkerconfig|/metadata|/mi_ext|/mnt|/odm|/odm_dlkm|/oem|/proc|/sys|/system_ext|/system_dlkm|/system" # 系统白名单目录    
    is_in_protected_dir() {
        local file="$1"
        if echo "$file" | grep -Eq "^($PROTECTED_DIRS)(/|$)"; then
            return 0
        fi
        return 1
    }

    local file="$1"
    if is_protected_file "$file" || is_in_protected_dir "$file"; then
        return 0
    fi
    return 1
}

is_temp_file() {
    local file="$1"
    case "$file" in
        *.download|*.tmp)
            LOGRCD "INFO" "$now_pro" "$file: 为 .download / .tmp 文件"
            return 0 ;;
        *)
            return 1 ;;
    esac
}

is_changing_file() {
    local file=$1
    local old_md5=$(md5sum $file)
    LOGRCD "INFO" "$now_pro" "$file: OLD_MD5: $old_md5"
    sleep 1
    local new_md5=$(md5sum $file)
    LOGRCD "INFO" "$now_pro" "$file: NEW_MD5: $new_md5"
    if [ "$old_md5" != "$new_md5" ]; then
        retrun 0
    fi
    retrun 1
}

count_init() {
    local tag=$1
    echo -n "0" > "$COUNTER/$tag"
}

count_plus_one() {
    local count=$1
    local tag=$2
    
    counter=$(cat $COUNTER/$tag)
    counter=$(expr $counter + 1)
    echo -n $counter > $COUNTER/$tag
}

count_echo() {
    local tag=$1
    cat "$COUNTER/$tag"
}

var_to_file() {
    local var=$1
    local file=$2    
    echo -n $var > "$VARES/$file"
}

var_to_file_echo() {
    local file=$1
    cat "$VARES/$file"
}

count_init "all_copied_files"
count_init "all_moved_files"
count_init "all_skipped_files"
count_init "cycle_num"

file_operation() {
    count_init "copied_files"
    count_init "moved_files"
    count_init "skipped_files"
    
    LOGRCD "INFO" "$now_pro" "开始文件操作：SDIR = $SDIR, TDIR = $TDIR, MODE = $MODE, keep_sdir_structure = $keep_sdir_structure"
    
    if [ "$MODE" = "copy" ]; then
        # 创建目录结构
        /system/bin/find "$SDIR" -type d -exec mkdir -p "$TDIR/{}" \;
        # 复制文件
        /system/bin/find "$SDIR" -type f | while read -r file; do
            target_file="$TDIR/${file#$SDIR/}"
            cp "$file" "$target_file"
            LOGRCD "INFO" "$now_pro" "复制了文件: $file 到 $target_file"
            count_plus_one "$copied_files" "copied_files"
            count_plus_one "$all_copied_files" "all_copied_files"
        done
        LOGRCD "INFO" "$now_pro" "复制操作完成：共复制了 $(count_echo "copied_files") 个文件，总计复制文件数 $(count_echo "all_copied_files")"
        
    elif [ "$MODE" = "move" ]; then
        # 创建目录结构
        /system/bin/find "$SDIR" -type d -exec mkdir -p "$TDIR/{}" \;
        # 移动文件
        /system/bin/find "$SDIR" -type f | while read -r file; do
            file_name=$(basename "$file")
            var_to_file "false" "filewhitelisted"
            # 检查是否在白名单中
            for whitelist_item in $(echo "$WhiteList" | tr '|' '\n'); do
                if [ "$file_name" = "$whitelist_item" ]; then
                    var_to_file "true" "filewhitelisted"
                    break
                fi
            done
            if [ "$(var_to_file_echo "filewhitelisted")" = "true" ]; then               
                LOGRCD "INFO" "$now_pro" "跳过白名单文件：$file"
                count_plus_one "$skipped_files" "skipped_files"
                count_plus_one "$all_skipped_files" "all_skipped_files"
            elif should_skip_file "$file"; then
                LOGRCD "INFO" "$now_pro" "系统文件保护: $file"
                count_plus_one "$skipped_files" "skipped_files"
                count_plus_one "$all_skipped_files" "all_skipped_files"
            elif is_temp_file "$file"; then
                LOGRCD "INFO" "$now_pro" "跳过缓存或下载中文件：$file"
                count_plus_one "$skipped_files" "skipped_files"
                count_plus_one "$all_skipped_files" "all_skipped_files"
            elif is_changing_file "$file"; then
                LOGRCD "INFO" "$now_pro" "跳过修改或下载中文件：$file"
                count_plus_one "$skipped_files" "skipped_files"
                count_plus_one "$all_skipped_files" "all_skipped_files" 
            else            
                target_dir="$TDIR/$(dirname "${file#$SDIR/}")"
                mkdir -p "$target_dir"
                mv "$file" "$target_dir/"
                LOGRCD "INFO" "$now_pro" "移动了文件: $file 到 $target_dir/"
                count_plus_one "$moved_files" "moved_files"
                count_plus_one "$all_moved_files" "all_moved_files"
            fi
        done
        LOGRCD "INFO" "$now_pro" "移动操作完成：共移动了 $(count_echo "moved_files") 个文件，总计移动文件数 $(count_echo "all_moved_files")，跳过了 $(count_echo "skipped_files") 个文件"
    
    elif [ "$MODE" = "bind" ]; then
        # mount --bind 操作
        LOGRCD "INFO" "$now_pro" "开始挂载绑定目录：源目录 = $SDIR，目标目录 = $TDIR"
        if [ ! -f "$MODDIR/yule/mount/$now_pro" ]; then
            mkdir -p "$MODDIR/yule/mount"
            touch "$MODDIR/yule/mount/$now_pro"
            mount --bind "$SDIR" "$TDIR"
            LOGRCD "INFO" "$now_pro" "挂载成功: $SDIR 到 $TDIR"
        else
            LOGRCD "INFO" "$now_pro" "$TDIR 已经挂载，无需重复执行"
        fi
        
    else
        LOGRCD "*** ERROR" "$now_pro" "未知模式：$MODE"
    fi
}

operation() {
    local pro_filename=$1
    pro_file=$MODDIR/config/OPDIR/confs/$pro_filename
    SKIP_THIS_ROUND='NO'    
    . $pro_file
    
    if [ -z "$SDIR" ] || [ -z "$TDIR" ]; then
        LOGRCD "*** ERROR" "$now_pro" "源目录或终目录未设置，跳过本轮"
        SKIP_THIS_ROUND='YES'
    elif [ ! -d "$SDIR" ]; then
        LOGRCD "*** ERROR" "$now_pro" "$SDIR 不存在，跳过本轮"
        SKIP_THIS_ROUND='YES'
    elif [ ! -d "$TDIR" ]; then
        if [ $make_dir_if_tdir_none = "true" ]; then
            LOGRCD "WARN" "$now_pro" "$TDIR 不存在，且自动创建终目录已启用，正在创建这个目录"
            mkdir -p $TDIR
        else
            LOGRCD "*** ERROR" "$now_pro" "$TDIR 不存在，且自动创建终目录未打开，跳过本轮"
            notice "yule" "文件重定向 - 错误" "项目 $pro_filename 终目录 $TDIR 不存在，且您没有打开自动创建终目录功能，跳过本轮循环，请检查！"
            SKIP_THIS_ROUND='YES'
        fi
    elif [ ! "$MODE" ]; then
        LOGRCD "WARN" "$now_pro" "模式未设置，跳过本轮"
        SKIP_THIS_ROUND='YES'
    elif [ "$MODE" != "copy" ] && [ "$MODE" != "move" ] && [ "$MODE" != "bind" ]; then
        LOGRCD "WARN" "$now_pro" "模式设置错误: $MOD，跳过本轮"
        SKIP_THIS_ROUND='YES'
    fi 
    if [ $SKIP_THIS_ROUND = "NO" ]; then
        file_operation
    else
        LOGRCD "SKIP" "$now_pro" "跳过本轮，详情见上"
    fi
    # 删除空目录（如果未保留目录结构）
    if [ "$keep_sdir_structure" = "false" ]; then
        /system/bin/find "$SDIR" -mindepth 1 -type d -empty -exec rm -rf {} \;
        LOGRCD "INFO" "$now_pro" "删除了 $SDIR 中的空目录"
    fi
}

sleep $sleep_after_start
notice "yule" "文件重定向 - 启动成功" "模块已成功启动，感谢您的使用。"
mkdir -p $COUNTER
mkdir -p $VARES
mkdir -p $MODDIR/yule/logarchive

while true; do
    while [ -f $MODDIR/STOP ]; do
        . $MODDIR/config/SYSTEM/config.prop
        setmodprop "[模块状态] 正常 & 关闭"
        sleep $sleep_after_refresh
    done
    
    while [ ! -f $MODDIR/STOP ]; do
        LOGRCD "INFO" "系统" "<---------- 开启第 $(count_echo "cycle_num") 次检查 ---------->"
        . $MODDIR/config/SYSTEM/config.prop
        count_plus_one "$cycle_num" "cycle_num"
        pro_num=$(find $MODDIR/config/OPDIR/confs -type f | wc -l)
        
        if [ $pro_num = '0' ]; then
            LOGRCD "SKIP" "识别" "用户还没有创建任何项目"
        elif [ $pro_num = '1' ]; then
            operation 1
        else
            for now_pro in $(seq 1 ${pro_num}); do
                operation "$now_pro"
            done
        fi
        
        log_size=$(du -k "$log_file" | cut -f1)
        if [ "$log_size" -gt "$log_file_long" ]; then
            cp $log_file "$MODDIR/yule/logarchive/service_running_$(date +"%Y%m%d_%H%M%S")_base.log"
            echo -n '' > $log_file
        fi
        if [ $(find "$MODDIR/yule/logarchive" -type f | wc -l) -gt "5" ]; then
            find "$MODDIR/yule/logarchive" -type f | sort | head -n 1 | /system/bin/xargs rm -f
        fi
        
        setmodprop "[模块状态] 正常 & 启用 | [项目数] $pro_num | [循环次数] $(count_echo "cycle_num") | [本次开机数据] 移动 $(count_echo "all_moved_files") & 复制 $(count_echo "all_copied_files") | [最新操作] $now_pro 操作完成：复制了 $(count_echo "copied_files") 个文件，移动了 $(count_echo "moved_files") 个文件，跳过了 $(count_echo "skipped_files") 个文件"
        sleep $sleep_after_refresh
    done
done