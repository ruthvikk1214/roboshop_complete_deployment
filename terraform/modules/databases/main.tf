# KMS Keys for encryption
resource "aws_kms_key" "docdb" {
  description             = "KMS key for DocumentDB encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-docdb-kms"
  })
}

resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-rds-kms"
  })
}

resource "aws_kms_key" "elasticache" {
  description             = "KMS key for ElastiCache encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-elasticache-kms"
  })
}

resource "aws_kms_key" "mq" {
  description             = "KMS key for Amazon MQ encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-mq-kms"
  })
}

# DocumentDB (MongoDB compatible)
resource "aws_docdb_cluster" "mongodb" {
  cluster_identifier      = "${var.environment}-roboshop-mongodb"
  engine                  = "docdb"
  engine_version          = "5.0.0"
  master_username         = "roboshop"
  master_password         = var.mongodb_password
  port                    = 27017
  preferred_backup_window = "07:00-09:00"
  backup_retention_period = 7
  vpc_security_group_ids  = [var.database_sg_id]
  db_subnet_group_name    = var.db_subnet_group_name
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.docdb.arn
  apply_immediately       = true
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-mongodb"
  })
}

resource "aws_docdb_cluster_instance" "mongodb" {
  count              = 2
  identifier         = "${var.environment}-roboshop-mongodb-${count.index}"
  cluster_identifier = aws_docdb_cluster.mongodb.id
  instance_class     = "db.r6g.large"
  engine             = aws_docdb_cluster.mongodb.engine
  engine_version     = aws_docdb_cluster.mongodb.engine_version
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-mongodb-${count.index}"
  })
}

# RDS MySQL
resource "aws_db_instance" "mysql" {
  identifier             = "${var.environment}-roboshop-mysql"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.medium"
  allocated_storage      = 20
  max_allocated_storage  = 100
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.rds.arn
  db_name                = "shipping"
  username               = "roboshop"
  password               = var.mysql_password
  vpc_security_group_ids = [var.database_sg_id]
  db_subnet_group_name   = var.db_subnet_group_name
  backup_retention_period = 7
  backup_window          = "07:00-09:00"
  maintenance_window     = "mon:04:00-mon:05:00"
  deletion_protection    = true
  performance_insights_enabled = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn
  monitoring_interval    = 60
  monitoring_role_arn    = aws_iam_role.rds_monitoring.arn
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-mysql"
  })
}

resource "aws_iam_role" "rds_monitoring" {
  name = "${var.environment}-roboshop-rds-monitoring-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ElastiCache Redis
resource "aws_elasticache_parameter_group" "redis" {
  name   = "${var.environment}-roboshop-redis-param-group"
  family = "redis7"
  
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-redis-param-group"
  })
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.environment}-roboshop-redis"
  engine                     = "redis"
  engine_version             = "7.0"
  node_type                  = "cache.t3.medium"
  number_cache_clusters      = 2
  port                       = 6379
  parameter_group_name       = aws_elasticache_parameter_group.redis.name
  subnet_group_name          = var.elasticache_subnet_group_name
  security_group_ids         = [var.database_sg_id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.redis_password
  automatic_failover_enabled = true
  multi_az_enabled           = true
  kms_key_id                 = aws_kms_key.elasticache.arn
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-redis"
  })
}

# Amazon MQ RabbitMQ
resource "aws_mq_configuration" "rabbitmq" {
  name       = "${var.environment}-roboshop-rabbitmq-config"
  engine_type = "RABBITMQ"
  engine_version = "3.11"
  data = jsonencode({
    "rabbitmq" = {
      "auth_backends" = ["internal"],
      "loopback_users" = ["guest"],
      "tcp_listeners" = [5672],
      "ssl_listeners" = [5671],
      "management_listener" = {
        "port" = 15672,
        "ssl" = false
      }
    }
  })
}

resource "aws_mq_broker" "rabbitmq" {
  broker_name  = "${var.environment}-roboshop-rabbitmq"
  engine_type  = "RABBITMQ"
  engine_version = "3.11"
  host_instance_type = "mq.t3.micro"
  deployment_mode = "ACTIVE_STANDBY_MULTI_AZ"
  publicly_accessible = false
  subnet_ids   = var.database_subnet_ids
  security_groups = [var.database_sg_id]
  users = [{
    username = "roboshop"
    password = var.rabbitmq_password
    groups   = ["administrators"]
    console_access = true
  }]
  configuration = {
    id       = aws_mq_configuration.rabbitmq.id
    revision = aws_mq_configuration.rabbitmq.latest_revision
  }
  encryption_options = {
    use_aws_owned_key = false
    kms_key_id        = aws_kms_key.mq.arn
  }
  maintenance_window_start_time = {
    day_of_week = "MON"
    time_of_day = "04:00"
    time_zone   = "UTC"
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-rabbitmq"
  })
}

# Secrets Manager for database credentials
resource "aws_secretsmanager_secret" "mongodb" {
  name = "roboshop/${var.environment}/mongodb/password"
  
  tags = merge(var.tags, {
    Name = "roboshop-${var.environment}-mongodb-password"
  })
}

resource "aws_secretsmanager_secret_version" "mongodb" {
  secret_id = aws_secretsmanager_secret.mongodb.id
  secret_string = jsonencode({
    username = "roboshop"
    password = var.mongodb_password
    host     = aws_docdb_cluster.mongodb.endpoint
    port     = 27017
    database = "catalogue"
  })
}

resource "aws_secretsmanager_secret" "mysql" {
  name = "roboshop/${var.environment}/mysql/password"
  
  tags = merge(var.tags, {
    Name = "roboshop-${var.environment}-mysql-password"
  })
}

resource "aws_secretsmanager_secret_version" "mysql" {
  secret_id = aws_secretsmanager_secret.mysql.id
  secret_string = jsonencode({
    username = "roboshop"
    password = var.mysql_password
    host     = aws_db_instance.mysql.endpoint
    port     = 3306
    database = "shipping"
  })
}

resource "aws_secretsmanager_secret" "redis" {
  name = "roboshop/${var.environment}/redis/password"
  
  tags = merge(var.tags, {
    Name = "roboshop-${var.environment}-redis-password"
  })
}

resource "aws_secretsmanager_secret_version" "redis" {
  secret_id = aws_secretsmanager_secret.redis.id
  secret_string = jsonencode({
    host     = aws_elasticache_replication_group.redis.primary_endpoint_address
    port     = 6379
    password = var.redis_password
  })
}

resource "aws_secretsmanager_secret" "rabbitmq" {
  name = "roboshop/${var.environment}/rabbitmq/password"
  
  tags = merge(var.tags, {
    Name = "roboshop-${var.environment}-rabbitmq-password"
  })
}

resource "aws_secretsmanager_secret_version" "rabbitmq" {
  secret_id = aws_secretsmanager_secret.rabbitmq.id
  secret_string = jsonencode({
    username = "roboshop"
    password = var.rabbitmq_password
    host     = aws_mq_broker.rabbitmq.broker_instances[0].endpoint
    port     = 5672
    management_port = 15672
  })
}