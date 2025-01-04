#!/bin/bash -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

source ${DIR}/functions.sh

################################## GET KAFKA CLUSTER ID ########################
KAFKA_CLUSTER_ID=$(get_kafka_cluster_id_from_container)
#echo "KAFKA_CLUSTER_ID: $KAFKA_CLUSTER_ID"

################################## SETUP VARIABLES #############################
MDS_URL=https://kafka1:8091
CONNECT=connect-cluster
SR=schema-registry
KSQLDB=ksql-cluster
C3=c3-cluster
LICENSE_RESOURCE="Topic:_confluent-command"

SUPER_USER=superUser
SUPER_USER_PASSWORD=superUser
SUPER_USER_PRINCIPAL="User:$SUPER_USER"
CONNECT_ADMIN="User:connectAdmin"
CONNECTOR_SUBMITTER="User:connectorSubmitter"
CONNECTOR_PRINCIPAL="User:connectorSA"
SR_PRINCIPAL="User:schemaregistryUser"
KSQLDB_ADMIN="User:ksqlDBAdmin"
KSQLDB_USER="User:ksqlDBUser"
KSQLDB_SERVER="User:controlCenterAndKsqlDBServer"
C3_ADMIN="User:controlcenterAdmin"
REST_ADMIN="User:restAdmin"
CLIENT_PRINCIPAL="User:appSA"
LISTEN_PRINCIPAL="User:clientListen"

mds_login $MDS_URL ${SUPER_USER} ${SUPER_USER_PASSWORD} || exit 1

################################### SUPERUSER ###################################
echo "Creating role bindings for Super User"

confluent iam rbac role-binding create \
    --principal $SUPER_USER_PRINCIPAL  \
    --role SystemAdmin \
    --kafka-cluster $KAFKA_CLUSTER_ID

confluent iam rbac role-binding create \
    --principal $SUPER_USER_PRINCIPAL \
    --role SystemAdmin \
    --kafka-cluster $KAFKA_CLUSTER_ID \
    --schema-registry-cluster $SR

confluent iam rbac role-binding create \
    --principal $SUPER_USER_PRINCIPAL \
    --role SystemAdmin \
    --kafka-cluster $KAFKA_CLUSTER_ID \
    --connect-cluster $CONNECT

confluent iam rbac role-binding create \
    --principal $SUPER_USER_PRINCIPAL \
    --role SystemAdmin \
    --kafka-cluster $KAFKA_CLUSTER_ID \
    --ksql-cluster $KSQLDB

################################### SCHEMA REGISTRY ###################################
echo "Creating role bindings for Schema Registry"

# SecurityAdmin on SR cluster itself
confluent iam rbac role-binding create \
    --principal $SR_PRINCIPAL \
    --role SecurityAdmin \
    --kafka-cluster $KAFKA_CLUSTER_ID \
    --schema-registry-cluster $SR

# ResourceOwner for groups and topics on broker
for resource in Topic:_schemas Topic:_exporter_configs Topic:_exporter_states Group:schema-registry
do
    confluent iam rbac role-binding create \
        --principal $SR_PRINCIPAL \
        --role ResourceOwner \
        --resource $resource \
        --kafka-cluster $KAFKA_CLUSTER_ID
done

for role in DeveloperRead DeveloperWrite
do
    confluent iam rbac role-binding create \
        --principal $SR_PRINCIPAL \
        --role $role \
        --resource $LICENSE_RESOURCE \
        --kafka-cluster $KAFKA_CLUSTER_ID
done



############################## Control Center ###############################
echo "Creating role bindings for Control Center"

# C3 only needs SystemAdmin on the kafka cluster itself
confluent iam rbac role-binding create \
    --principal $C3_ADMIN \
    --role SystemAdmin \
    --kafka-cluster $KAFKA_CLUSTER_ID

############################## Rest Proxy ###############################
echo "Creating role bindings for Rest Proxy"
for role in DeveloperRead DeveloperWrite
do
    confluent iam rbac role-binding create \
        --principal $REST_ADMIN \
        --role $role \
        --resource $LICENSE_RESOURCE \
        --kafka-cluster $KAFKA_CLUSTER_ID
done


######################### Print #########################

echo "Cluster IDs:"
echo "    kafka cluster id: $KAFKA_CLUSTER_ID"
echo "    schema registry cluster id: $SR"
echo
echo "Cluster IDs as environment variables:"
echo "    export KAFKA_ID=$KAFKA_CLUSTER_ID ; export SR_ID=$SR"
echo
echo "Principals:"
echo "    super user account: $SUPER_USER_PRINCIPAL"
echo "    Schema Registry user: $SR_PRINCIPAL"
echo "    Rest Admin: $REST_ADMIN"
echo
