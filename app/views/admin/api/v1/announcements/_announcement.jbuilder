# frozen_string_literal: true

# No json.cache! here, unlike the rest of the admin API: a delivery row changes
# status from a background job without touching the announcement, so a fragment
# keyed on the announcement would keep serving "pending" after the post landed.
json.partial!("admin/api/v1/announcements/base", announcement:)
