#!/bin/sh

# @author liufq
#需要输出日志的ip列表，用空格分隔
ips="$1"
#日志文件存储路径列表，用空格分隔
logs="$2"
#备份日志文件目录
backupDir="$3"
#备份多少天的日志文件
days=$4
#检测最近几个文件是否损坏
checkFiles=7

#存储运行时日志文件
logFile='/tmp/import_mams_log.log'
#每次暂停多少秒
sleepSecond=5
#日志日期格式
datePattern='+%Y-%m-%d %H:%M:%S'

importTaskFile="/data/tasks/log_tasks_import"
clearTaskFile="/data/tasks/log_tasks_clear"

echo `date "$datePattern"` " $0 start" >> $logFile

if [ -z "$ips" -o -z "$logs" -o -z "$backupDir" -o -z "$days" ]; then
	echo "Syntax: import_log.sh ips logs backupDir days"
	echo "Example: import_log.sh '10.10.84.31' '/data/logs/boss/boss.log' '/data/logs/backup' 7 "
        
	echo `date "$datePattern"` " Syntax: importLog.sh ips logs backupDir days" >> $logFile
	exit 1
fi

for ip in $ips
do
	for logPath in $logs
	do
		log=`echo ${logPath##*/}`
		for ((i=1; i<=$days; i++))
		do
			date=`date -d "$i days ago" +%Y-%m-%d`
                        
                        historyCount=`expr $i + $days`
			echo "$historyCount"
			historyDate=`date -d "$historyCount days ago" +%Y-%m-%d`
			echo "$historyDate"

			month=`date -d "$i days ago" +%Y%m`
			destDir="$backupDir/$ip/$month"
			if [ ! -e "$destDir" ]; then
				mkdir -p $destDir				
			fi

			filePath="$destDir/$log.$date.gz"
			srcFile="root@$ip:$logPath.$date"
			srcHistoryFile="$logPath.$historyDate"
			destFile="$destDir/$log.$date"
                        checksumFile="$destDir/checksum"
			
			if [ -e "$filePath" ]; then
				if [ $i -gt $checkFiles ]; then
                                     echo `date "$datePattern"` "$filePath not check" >> $logFile
                    	             continue;
                                fi
                            
                                echo `date "$datePattern"` "$filePath existed, check it first" >> $logFile

                                if [ -e "$checksumFile" ]; then
                                	checksum=`cksum "$filePath"`
                                	grep "$checksum" "$checksumFile"
                                	if [ 0 -eq $? ]; then
                                        	echo `date "$datePattern"` "$filePath checksum match" >> $logFile
                                        	continue;
                                	fi
                                fi

                                gzip -t "$filePath"
                                if [ 0 -eq $? ]; then
                                    	echo `date "$datePattern"` "$filePath check incorrupt" >> $logFile
                                    	echo `cksum "$filePath"` >> $checksumFile
                                    	continue;
                                else
                                    	echo `date "$datePattern"` "$filePath check corrupt" >> $logFile
                                            rm -rf $filePath
                                fi	
		      	fi

                        logDirectory=`echo ${logPath%/*}`
		        echo "$ip $logDirectory $log.$date $destDir" >> $importTaskFile
                        echo "$ip $srcHistoryFile" >> $clearTaskFile

		done
	done
done
echo `date "$datePattern"` " $0 end" >> $logFile
exit 0
