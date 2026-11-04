output "mongodb_endpoint" {
  description = "DocumentDB Cluster Endpoint"
  value       = aws_docdb_cluster.mongodb.endpoint
}

output "mongodb_reader_endpoint" {
  description = "DocumentDB Reader Endpoint"
  value       = aws_docdb_cluster.mongodb.reader_endpoint
}

output "mysql_endpoint" {
  description = "RDS MySQL Endpoint"
  value       = aws_db_instance.mysql.endpoint
}

output "redis_primary_endpoint" {
  description = "ElastiCache Redis Primary Endpoint"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_reader_endpoint" {
  description = "ElastiCache Redis Reader Endpoint"
  value       = aws_elasticache_replication_group.redis.reader_endpoint_address
}

output "rabbitmq_endpoints" {
  description = "Amazon MQ RabbitMQ Endpoints"
  value = {
    amqp = aws_mq_broker.rabbitmq.broker_instances[0].endpoint
    management = aws_mq_broker.rabbitmq.broker_instances[0].console_url
  }
}

output "mongodb_secret_arn" {
  description = "MongoDB Secret ARN"
  value       = aws_secretsmanager_secret.mongodb.arn
}

output "mysql_secret_arn" {
  description = "MySQL Secret ARN"
  value       = aws_secretsmanager_secret.mysql.arn
}

output "redis_secret_arn" {
  description = "Redis Secret ARN"
  value       = aws_secretsmanager_secret.redis.arn
}

output "rabbitmq_secret_arn" {
  description = "RabbitMQ Secret ARN"
  value       = aws_secretsmanager_secret.rabbitmq.arn
}

output "docdb_kms_key_arn" {
  description = "DocumentDB KMS Key ARN"
  value       = aws_kms_key.docdb.arn
}

output "rds_kms_key_arn" {
  description = "RDS KMS Key ARN"
  value       = aws_kms_key.rds.arn
}

output "elasticache_kms_key_arn" {
  description = "ElastiCache KMS Key ARN"
  value       = aws_kms_key.elasticache.arn
}

output "mq_kms_key_arn" {
  description = "Amazon MQ KMS Key ARN"
  value       = aws_kms_key.mq.arn
}