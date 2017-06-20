## file description
Producer:
crontab-generate-task.sh   for crontab generate tasks to consume
Consumer:
gzip_then_import_log.sh    gzip log files and pull log from application server to log server
clear_history_files.sh     clear the history file in application server

Those two files moniter the file queue that crontab-generate-task.sh append tasks
and use tail to consume those tasks.


About the background and more description 
see: