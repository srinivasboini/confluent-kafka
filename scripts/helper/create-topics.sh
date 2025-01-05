#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/functions.sh

KAFKA_CLUSTER_ID=$(get_kafka_cluster_id_from_container)

auth="superUser:superUser"

create_topic kafka1:8091 ${KAFKA_CLUSTER_ID} users-avro true ${auth}

create_topic kafka1:8091 ${KAFKA_CLUSTER_ID} users false ${auth}

create_topic kafka1:8091 ${KAFKA_CLUSTER_ID} wikipedia false ${auth}
