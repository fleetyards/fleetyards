# frozen_string_literal: true

Searchkick.index_prefix = "fleetyards-#{Rails.env}"
Searchkick.model_options = {
  settings: {
    blocks: {
      read_only_allow_delete: false
    }
  }
}
Searchkick.client_options = {
  transport_options: {
    ssl: {
      verify: false
    }
  }
}
