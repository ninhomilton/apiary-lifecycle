/**
 * Copyright (C) 2019-2020 Expedia, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

data "template_file" "beekeeper_graphite_config" {
  template = file("${path.module}/files/beekeeper-graphite-config.yml")

  vars = {
    graphite_enabled = var.graphite_enabled
    graphite_host    = var.graphite_host
    graphite_prefix  = var.graphite_prefix
    graphite_port    = var.graphite_port
  }
}

data "template_file" "beekeeper_path_scheduler_config" {
  template = file("${path.module}/files/beekeeper-path-scheduler-config.yml")

  vars = {
    db_endpoint      = aws_db_instance.beekeeper.endpoint
    db_username      = aws_db_instance.beekeeper.username
    queue            = aws_sqs_queue.beekeeper.id
    graphite_config  = var.graphite_enabled == "false" ? "" : data.template_file.beekeeper_graphite_config.rendered
  }
}

data "template_file" "beekeeper_cleanup_config" {
  template = file("${path.module}/files/beekeeper-cleanup-config.yml")

  vars = {
    db_endpoint        = aws_db_instance.beekeeper.endpoint
    db_username        = aws_db_instance.beekeeper.username
    scheduler_delay_ms = var.scheduler_delay_ms
    dry_run_enabled    = var.dry_run_enabled
    graphite_config    = var.graphite_enabled == "false" ? "" : data.template_file.beekeeper_graphite_config.rendered
  }
}
