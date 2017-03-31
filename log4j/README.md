we know that System.getCurrentTimeMillis is a costly operation.
In a multi-thread environment , this may become a bottleneck
so I provide this class to use a single thread to cache the current time millis
NOTE:It have a sleepGap average error,if you can't stand this,you'd better use the original {@link DailyRollingFileAppender}
 