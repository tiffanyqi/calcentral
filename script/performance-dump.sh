#!/bin/bash
# Script to dump diagnostic information to analyze performance and scalability issues.
# WARNING: This will impact normal operations and create very large files in the home directory.
# DO NOT RUN IN PRODUCTION UNLESS A RESTART IS PENDING OR LOAD IS VERY LOW.

# Make sure the normal shell environment is in place.
source "$HOME/.bash_profile"

if [ -z "$2" ]; then
  echo "Usage: $0 PID_of_torquebox-server node_id"
  echo "Get the PID via 'jps -mlv'"
  echo "Example: $0 2441 prod-01"
  exit 0
fi

TPID=$1
NODE=$2
DT=`date +"%Y-%m-%d"`

cd $( dirname "${BASH_SOURCE[0]}" )/..

LOG="$PWD/log/performance_dump_$DT.log"
LOGIT="tee -a $LOG"

# Enable rvm and use the correct Ruby version and gem set.
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"
source .rvmrc

export RAILS_ENV=${RAILS_ENV:-production}
export LOGGER_STDOUT=only
export LOGGER_LEVEL=INFO
export JRUBY_OPTS="--dev"

echo | $LOGIT
echo "------------------------------------------" | $LOGIT
echo "`date`: About to dump performance data for later analysis..." | $LOGIT

cd deploy

bundle exec rake memcached:get_stats > "$HOME/perf-$DT-$NODE-memcached.txt"
jmap -heap $TPID > "$HOME/perf-$DT-$NODE-jmap.txt"
jstack -l $TPID > "$HOME/perf-$DT-$NODE-jstack-1.txt"
echo "`date`: About to gather 15 seconds of top -H" | $LOGIT
top -Hb -n 5 -d 3 > "$HOME/perf-$DT-$NODE-top.log"
jstack -l $TPID > "$HOME/perf-$DT-$NODE-jstack-2.txt"

echo "`date`: About to collect class loader stats" | $LOGIT
jmap -clstats $TPID > "$HOME/perf-$DT-$NODE-clstats.txt"

echo "`date`: About to copy Torquebox log" | $LOGIT
TORQUEBOX_LOG=$(find "$HOME/calcentral/log/" -name torquebox\*.log | sort -n | tail -1)
cp $TORQUEBOX_LOG "$HOME/perf-$DT-$NODE-torquebox.log"

echo "`date`: About to dump server memory to file" | $LOGIT
# This will take a LOT of space. scp and rm it ASAP.
jmap -dump:live,format=b,file="$HOME/perf-$DT-$NODE-heap.bin" $TPID
ruby lib/top_h_parser.rb "$HOME/perf-$DT-$NODE-top.log"

echo "------------------------------------------" | $LOGIT
echo "`date`: Performance data dumped to $HOME - copy and delete files ASAP!" | $LOGIT
