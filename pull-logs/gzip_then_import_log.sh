#!/bin/bash

# @author liufq
# 任务来源
taskFile="/data/tasks/log_tasks_import"
# 删除文件任务文件
clearTaskFile="/data/tasks/log_tasks_clear"
# 记录日志
logFile="/tmp/import_mams_log.log"

#日志日期格式
datePattern='+%Y-%m-%d %H:%M:%S'
function gzip_then_import_log(){
	# 目标机器
	ip=$1
	# 日志所在目录 /data/logs
	logPath=$2
	# 日志名称 api.log.2017-01-01
	fileName=$3
	
	# 备份目录
	destDir=$4
	if [ -z "$ip" -o -z "$logPath" -o -z "$fileName" -o -z "$destDir" ]; then
	    echo "error: path is not legal"
	    
	    echo `date "$datePattern"` " path is not legal [ip=$ip;logPath=$logPath;fileName=$fileName;destDir=$destDir]" >> $logFile
	    return 1
	fi
	
	if [ ! -e "$destDir" ]; then
				mkdir -p $destDir				
	fi
	
	echo `date "$datePattern"` " gzip $logPath/$fileName on remote server start" >> $logFile
	ssh $ip "if [ ! -e "$logPath/$fileName.gz" ]; then gzip -c $logPath/$fileName > $logPath/$fileName.gz; fi"
	echo `date "$datePattern"` " gzip $logPath/$fileName on remote server end" >> $logFile
	
	echo `date "$datePattern"` " scp $logPath/$fileName.gz start" >> $logFile
	scp root@$ip:$logPath/$fileName.gz $destDir/$fileName.gz
	echo `date "$datePattern"` " scp $logPath/$fileName.gz end" >> $logFile
	
	filePath="$destDir/$fileName.gz"
	checksumFile="$destDir/checksum"
	gzip -t "$filePath"
	if [ 0 -eq $? ]; then
			echo `date "$datePattern"` "$filePath check incorrupt" >> $logFile
			echo `cksum "$filePath"` >> $checksumFile
                        echo "$ip $logPath/$fileName.gz" >> $clearTaskFile
	else
		echo `date "$datePattern"` "$filePath check corrupt" >> $logFile
		rm -rf $filePath
		# retry
		echo "$ip $logPath $fileName $destDir transfer error ,retry" >> $logFile
		echo "$ip $logPath $fileName $destDir" >> $taskFile
	fi
}

trap "exec 6>&-;exec 6<&-;exit 0" 2
tmp_fifofile="/tmp/$$.fifo"
mkfifo $tmp_fifofile      # 新建一个fifo类型的文件
exec 6<>$tmp_fifofile     # 将fd6指向fifo类型
rm $tmp_fifofile    #删也可以

thread_num=8  # 最大可同时执行线程数量

#根据线程总数量设置令牌个数
for ((i=0;i<${thread_num};i++));do
    echo
done >&6

tail -f -n 100 $taskFile | 
while read ip logPath fileName destDir 
do
    # 一个read -u6命令执行一次，就从fd6中减去一个回车符，然后向下执行，
    # fd6中没有回车符的时候，就停在这了，从而实现了线程数量控制
	read -u6
	{
		gzip_then_import_log $ip $logPath $fileName $destDir
		echo >&6 # 当进程结束以后，再向fd6中加上一个回车符
	} &
done

wait
exec 6>&- # 关闭fd6
echo "over"
