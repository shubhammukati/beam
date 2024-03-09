#!/bin/bash
#
#    Licensed to the Apache Software Foundation (ASF) under one or more
#    contributor license agreements.  See the NOTICE file distributed with
#    this work for additional information regarding copyright ownership.
#    The ASF licenses this file to You under the Apache License, Version 2.0
#    (the "License"); you may not use this file except in compliance with
#    the License.  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

echo "************ xyz123 run_transform_service.sh: 1"

read -r -d '' USAGE <<END
Usage: run_expansion_services.sh (start|stop) [options]
Options:
  --group_id [unique id for stop services later]
  --transform_service_launcher_jar [path to the transform service launcher jar]
  --external_port [external port exposed by the transform service]
  --start [command to start the transform service for the given group_id]
  --stop [command to stop the transform service for the given group_id]
END

echo "************ xyz123 run_transform_service.sh: 2"

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --group_id)
      GROUP_ID="$2"
      shift
      shift
      ;;
    --transform_service_launcher_jar)
      TRANSFORM_SERVICE_LAUNCHER_JAR="$2"
      shift
      shift
      ;;
    --external_port)
      EXTERNAL_PORT="$2"
      shift
      shift
      ;;
    --beam_version)
      BEAM_VERSION_JAR="$2"
      BEAM_VERSION_DOCKER=${BEAM_VERSION_JAR/-SNAPSHOT/.dev}
      shift
      shift
      ;;
    start)
      STARTSTOP="$1"
      shift
      ;;
    stop)
      STARTSTOP="$1"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "$USAGE"
      exit 1
      ;;
  esac
done

echo "************ xyz123 run_transform_service.sh: 3"

FILE_BASE="beam-transform-service"
if [ -n "$GROUP_ID" ]; then
  FILE_BASE="$FILE_BASE-$GROUP_ID"
fi

TEMP_DIR=/tmp

echo "************ xyz123 run_transform_service.sh: 4"

case $STARTSTOP in
  start)
    echo "************ xyz123 in script run_transform_service.sh: starting the service"
    echo "Starting the transform service for project $GROUP_ID at port $EXTERNAL_PORT for Beam version $BEAM_VERSION_DOCKER transform service startup jar is $TRANSFORM_SERVICE_LAUNCHER_JAR"
    java -jar $TRANSFORM_SERVICE_LAUNCHER_JAR --project_name $GROUP_ID --port $EXTERNAL_PORT --beam_version $BEAM_VERSION_DOCKER --command up  >$TEMP_DIR/$FILE_BASE-java1.log 2>&1 </dev/null
    echo "************ xyz123 printing launcher app startup error log"
    cat $TEMP_DIR/$FILE_BASE-java1.log
    echo "************ xyz123 DONE printing launcher app startup error log"
    echo "************ xyz123 in script run_transform_service.sh: DONE starting the service"
    ;;
  stop)
    echo "************ xyz123 run_transform_service.sh: printing docker logs"
    temp_output=`docker ps`
    printf "temp_output: $temp_output"
    printf "Logs from Controller:\n"
    temp_output=`docker ps | grep 'controller'`
    printf "temp_output controller: $temp_output"
    container=${temp_output%% *}
    docker logs $container
    printf "Logs from Java expansion service:\n"
    temp_output=`docker ps | grep 'java'`
    printf "temp_output java exp service: $temp_output"
    container=${temp_output%% *}
    docker logs $container
    printf "Logs from Python expansion service:\n"
    temp_output=`docker ps | grep 'python'`
    printf "temp_output py exp service: $temp_output"
    container=${temp_output%% *}
    docker logs $container
    echo "************ xyz123 run_transform_service.sh: DONE printing docker logs"
    echo "Stopping the transform service for project $GROUP_ID at port $EXTERNAL_PORT for Beam version $BEAM_VERSION_DOCKER  transform service startup jar is $TRANSFORM_SERVICE_LAUNCHER_JAR"
    java -jar $TRANSFORM_SERVICE_LAUNCHER_JAR --project_name $GROUP_ID --port $EXTERNAL_PORT --beam_version $BEAM_VERSION_DOCKER --command down  >$TEMP_DIR/$FILE_BASE-java2.log 2>&1 </dev/null

    echo "************ xyz123 printing launcher app shutdown error log"
    cat $TEMP_DIR/$FILE_BASE-java2.log
    echo "************ xyz123 DONE printing launcher app shutdown error log"

    echo "************ xyz123 run_transform_service.sh: DONE printing docker logs"

    TRANSFORM_SERVICE_TEMP_DIR=$TEMP_DIR/$GROUP_ID
    if [[ -d ${TRANSFORM_SERVICE_TEMP_DIR} ]]; then
      echo "Removing transform service temporary directory $TRANSFORM_SERVICE_TEMP_DIR"
      rm -rf ${TRANSFORM_SERVICE_TEMP_DIR}
    fi
    ;;
esac

echo "************ xyz123 run_transform_service.sh: 5"

