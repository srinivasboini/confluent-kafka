{
    "topic_name": $topic_name,
    "partitions_count": 1,
    "replication_factor": 1,
    "configs": [
        {
            "name": "confluent.value.schema.validation",
            "value": $confluent_value_schema_validation
        }
    ]
}
