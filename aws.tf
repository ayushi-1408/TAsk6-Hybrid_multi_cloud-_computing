provider "aws" {

region = "ap-south-1"

profile = "ayushi1"

}
 provider "kubernetes" {
  config_context_cluster   = "minikube"
}
resource "aws_security_group" "dbsg" {
  name        = "mysqlsg"
  description = "Allow MYSQL"
  vpc_id      = "vpc-5de8f535"
ingress {
    description = "Allow MYSQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
}
egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
    Name = "allowmysql"
  }
}
resource "aws_db_instance" "mysqldb" {
  
  allocated_storage    = 200
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mysqldb"
  username             = "ayushi"
  password             = "--"
  parameter_group_name = "default.mysql5.7"
  publicly_accessible = "true"
  port                = "3306"
  vpc_security_group_ids= ["${aws_security_group.dbsg.id}",]
  final_snapshot_identifier = "false"
  skip_final_snapshot = "true"
}
resource "kubernetes_deployment" "deploy1" {
    depends_on = [aws_db_instance.mysqldb]
  metadata {
    name = "wp"
    
  }

spec {
    replicas = 1

    selector {
      match_labels = {
        app = "wordpress"
      }
    }

    template {
      metadata {
          name = "wp-pod"
          labels = {
             app = "wordpress"
            }
       }

      spec {
        container {
          image = "wordpress:4.8-apache"
          name  = "wp1"
         
         
        }
      
    }
    resource "kubernetes_service" "service" {
    depends_on = [kubernetes_deployment.deploy1]
  metadata {
    name = "wp-service"
  }
    spec {
    selector = {
      app = kubernetes_deployment.deploy1.metadata.0.labels.app
    }
    
    port {
      port        = 8080
      target_port = 80
    }

    type = "NodePort"
    }  
}
