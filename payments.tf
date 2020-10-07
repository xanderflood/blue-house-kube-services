locals {
  payments_build_num = "14"
}

resource "kubernetes_namespace" "payments" {
  metadata {
    name = "payments"
  }
}

module "payments_db" {
  source = "./modules/db"
  name   = "payments"

  extensions = ["pgcrypto"]
}

## TODO kube cron job?
module "payments_proton_deployment" {
  source    = "./modules/cron"
  name      = "payments-proton"
  namespace = kubernetes_namespace.payments.metadata.0.name

  image = "xanderflood/payment-scraper:build-${local.payments_build_num}"

  env = {
    PROTONMAIL_USERNAME      = var.protonmail_username
    PROTONMAIL_PASSWORD      = var.protonmail_password
    PROTONMAIL_LABEL_NAME    = var.protonmail_label_name
    TELEGRAM_BOT_API_TOKEN   = var.telegram_bot_api_token
    TELEGRAM_BOT_API_CHAT_ID = var.telegram_bot_api_chat_id
    PGHOST                   = "postgres.postgres.svc.cluster.local"
    PGUSER                   = "payments"
    PGDATABASE               = "payments"
    PGPASSWORD               = module.payments_db.postgres_password

    DEVELOPMENT = true
  }

  capabilities = ["SYS_ADMIN"]
  schedule     = "45 */2 * * *"
}