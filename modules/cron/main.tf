variable "name" {
  type = string
}
variable "namespace" {
  type = string
}
variable "image" {
  type = string
}
variable "env" {
  type    = map
  default = {}
}
variable "capabilities" {
  type    = list(string)
  default = []
}
variable "schedule" {
  type = string
}

resource "kubernetes_cron_job" "cron_job" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }

  spec {
    schedule = var.schedule

    concurrency_policy        = "Forbid"
    starting_deadline_seconds = 30

    failed_jobs_history_limit     = 10
    successful_jobs_history_limit = 10

    job_template {
      metadata {
        labels = { app = var.name }
      }

      spec {
        backoff_limit = 3

        template {
          metadata {
            labels = { app = var.name }
          }

          spec {
            container {
              image = var.image
              name  = var.name

              dynamic "env" {
                for_each = var.env
                content {
                  name  = env.key
                  value = env.value
                }
              }

              security_context {
                capabilities {
                  add = var.capabilities
                }
              }
            }
          }
        }
      }
    }
  }
}
