/**
 * Copyright (C) 2019-2020 Expedia, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

locals {
  scheduler_name      = "path-scheduler"
  scheduler_full_name = "${var.k8s_app_alias}-path-scheduler"
  scheduler_labels = {
    "app.kubernetes.io/name"       = "${var.k8s_app_alias}-path-scheduler"
    "app.kubernetes.io/instance"   = "${var.k8s_app_alias}-path-scheduler"
    "app.kubernetes.io/version"    = var.path_scheduler_docker_image_version
    "app.kubernetes.io/managed-by" = var.k8s_app_alias
  }
  scheduler_label_name_instance = {
    "app.kubernetes.io/name"     = "${var.k8s_app_alias}-path-scheduler"
    "app.kubernetes.io/instance" = "${var.k8s_app_alias}-path-scheduler"
  }
}

resource "kubernetes_deployment" "beekeeper_scheduler" {
  count = var.instance_type == "k8s" ? 1 : 0
  metadata {
    name      = local.scheduler_full_name
    namespace = var.k8s_namespace
    labels    = local.scheduler_labels
  }

  spec {
    # setting the number of replicas to greater than 1 is currently untested
    replicas = 1
    selector {
      match_labels = local.scheduler_label_name_instance
    }

    template {
      metadata {
        labels = local.scheduler_label_name_instance
        annotations = {
          "iam.amazonaws.com/role" = aws_iam_role.beekeeper_k8s_role_scheduler_iam[count.index].arn
          "prometheus.io/scrape": var.prometheus_enabled
          "prometheus.io/port": var.k8s_scheduler_port
          "prometheus.io/path": "/actuator/prometheus"
        }
      }

      spec {
        container {
          name              = local.scheduler_full_name
          image             = "${var.path_scheduler_docker_image}:${var.path_scheduler_docker_image_version}"
          image_pull_policy = var.k8s_image_pull_policy

          port {
            name           = local.scheduler_name
            container_port = var.k8s_scheduler_port
          }

          liveness_probe {
            http_get {
              path = "/actuator/health"
              port = var.k8s_scheduler_port
            }
            initial_delay_seconds = var.k8s_scheduler_liveness_delay
          }

          resources {
            limits {
              memory = var.k8s_scheduler_memory
              cpu    = var.k8s_scheduler_cpu
            }
            requests {
              memory = var.k8s_scheduler_memory
              cpu    = var.k8s_scheduler_cpu
            }
          }

          env {
            name  = "AWS_REGION"
            value = var.aws_region
          }

          env {
            name  = "AWS_DEFAULT_REGION"
            value = var.aws_region
          }

          env {
            name  = "DB_PASSWORD_STRATEGY"
            value = var.db_password_strategy
          }

          env {
            name  = "DB_PASSWORD_KEY"
            value = var.db_password_key
          }

          env {
            name  = "BEEKEEPER_CONFIG"
            value = base64encode(data.template_file.beekeeper_path_scheduler_config.rendered)
          }
        }
      }
    }
  }

}

resource "kubernetes_service" "beekeeper_scheduler" {
  count = var.instance_type == "k8s" ? 1 : 0
  metadata {
    name   = local.scheduler_full_name
    labels = local.scheduler_labels
  }
  spec {
    port {
      name        = local.scheduler_name
      target_port = local.scheduler_name
      port        = var.k8s_scheduler_port
    }
    selector = local.scheduler_label_name_instance
    type     = "ClusterIP"
  }
}
