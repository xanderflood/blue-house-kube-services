locals {
  payments_build_num = "7"
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

module "payments_proton_cron" {
  source    = "./modules/cron"
  name      = "payments-proton"
  namespace = kubernetes_namespace.payments.metadata.0.name

  # TODO remove
  suspend = true

  image   = "xanderflood/payment-scraper:build-${local.payments_build_num}"
  command = ["./bin/run", "proton"]
  uid     = 1500

  env = {
    PROTONMAIL_USERNAME      = var.protonmail_username
    PROTONMAIL_PASSWORD      = var.protonmail_password
    PROTONMAIL_LABEL_NAME    = var.protonmail_label_name
    TELEGRAM_BOT_API_TOKEN   = var.telegram_bot_api_token
    TELEGRAM_BOT_API_CHAT_ID = var.telegram_bot_api_chat_id

    POSTGRES_CONNECTION_STRING = module.payments_db.postgres_url
    PGPASSWORD                 = module.payments_db.postgres_password

    DEVELOPMENT = true
  }

  capabilities = ["SYS_ADMIN"]
  schedule     = "45 */2 * * *"
}
