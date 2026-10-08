# frozen_string_literal: true

json.ignore_nil! false

json.enabled @user.hangar_share_enabled?
json.share_url @user.hangar_share_url
