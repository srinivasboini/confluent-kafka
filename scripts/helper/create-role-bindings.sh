#!/bin/bash -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

source ${DIR}/functions.sh

################################## GET KAFKA CLUSTER ID ########################
KAFKA_CLUSTER_ID=$(get_kafka_cluster_id_from_container)
#echo "KAFKA_CLUSTER_ID: $KAFKA_CLUSTER_ID"

################################## SETUP VARIABLES #############################
MDS_URL=https://kafka1:8091
SR=schema-registry
C3=c3-cluster
LICENSE_RESOURCE="Topic:_confluent-command"
USERS_RESOURCE="Topic:users"

SUPER_USER=superUser
SUPER_USER_PASSWORD=superUser
SUPER_USER_PRINCIPAL="User:$SUPER_USER"
SR_PRINCIPAL="User:schemaregistryUser"
C3_ADMIN="User:controlcenterAdmin"
CLIENT_PRINCIPAL="User:appSA"

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

################################### SCHEMA REGISTRY ###################################
echo "Creating role bindings for Schema Registry"

# SecurityAdmin on SR cluster itself
confluent iam rbac role-binding create \
    --principal $SR_PRINCIPAL \
    --role SecurityAdmin \
    --kafka-cluster $KAFKA_CLUSTER_ID \
    --schema-registry-cluster $SR


confluent iam rbac role-binding create \
    --principal $SR_PRINCIPAL \
    --role ResourceOwner \
    --resource Subject:users-avro-value \
    --kafka-cluster $KAFKA_CLUSTER_ID \
    --schema-registry-cluster $SR

confluent iam rbac role-binding create \
    --principal $CLIENT_PRINCIPAL \
    --role ResourceOwner \
    --resource Subject:wikipedia-value \
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

for role in DeveloperRead DeveloperWrite
do
    confluent iam rbac role-binding create \
        --principal $CLIENT_PRINCIPAL \
        --role $role \
        --resource $USERS_RESOURCE \
        --kafka-cluster $KAFKA_CLUSTER_ID
done


############################## Control Center ###############################
echo "Creating role bindings for Control Center"

# C3 only needs SystemAdmin on the kafka cluster itself
confluent iam rbac role-binding create \
    --principal $C3_ADMIN \
    --role SystemAdmin \
    --kafka-cluster $KAFKA_CLUSTER_ID

echo "list acls"

confluent iam rbac role-binding list --principal $SR_PRINCIPAL --kafka-cluster $KAFKA_CLUSTER_ID

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
echo
