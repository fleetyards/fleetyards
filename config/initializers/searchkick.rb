# frozen_string_literal: true

Searchkick.index_prefix = "fleetyards-#{Rails.env}"
Searchkick.model_options = {
  settings: {
    blocks: {
      read_only_allow_delete: false
    }
  }
}
