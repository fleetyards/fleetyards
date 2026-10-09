# frozen_string_literal: true

# Reads a user's RSI organisations page through their verified handle and stores
# the orgs on it as the user's list, which their fleet memberships are verified
# from.
class UserRsiOrganizations
  def initialize(user)
    @user = user
  end

  def run
    handle = @user.rsi_handle
    return :skipped unless @user.rsi_handle_verified? && handle.present?

    # Taken before asking, so a slower read of an older page cannot pass for a
    # newer one when two are out at once.
    read_at = Time.current
    page = Rsi::CitizenOrganizationsPage.fetch(handle)
    # A block is not an answer about this user, so they stay due.
    @user.update_columns(rsi_organizations_attempted_at: read_at) unless page.status == :blocked
    return page.status unless page.status == :ok

    @user.store_rsi_organizations(page.sids, read_at:, handle:) ? :ok : :stale
  end
end
