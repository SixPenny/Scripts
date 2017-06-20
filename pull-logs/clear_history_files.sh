#! /bin/bash
# @author liufq
clearFiles="/data/tasks/log_tasks_clear"
logFile="/tmp/import_mams_log.log"
datePattern='+%Y-%m-%d %H:%M:%S'
function clear_history_files(){
	ip=$1
	srcHistoryFile=$2
	if [ -z "$ip" -o -z "$srcHistoryFile"]
	then
	    echo "path is not legal [ip=$ip;srcHistoryFile=$srcHistoryFile]" >> $logFile
		return 1
	fi
	echo `date "$datePattern"` " clear $srcHistoryFile start" >> $logFile
	ssh $ip "/bin/rm -f $srcHistoryFile";
	echo "ssh $ip /bin/rm -f $srcHistoryFile" >> $logFile
	echo `date "$datePattern"` " clear $srcHistoryFile end" >> $logFile
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

tail -f -n 100 $clearFiles | 
while read ip file
do
    # 一个read -u6命令执行一次，就从fd6中减去一个回车符，然后向下执行，
    # fd6中没有回车符的时候，就停在这了，从而实现了线程数量控制
	read -u6
	{
		clear_history_files $ip $file
		echo >&6 # 当进程结束以后，再向fd6中加上一个回车符
	} &
done

wait
exec 6>&- # 关闭fd6
echo "over"
