# frozen_string_literal: true

# Checks that a user's verification token is in the bio on their RSI citizen
# page. Only the account holder can edit the bio, so finding the token there is
# taken as proof that the handle is theirs.
#
# A check is identified by the time it was asked for, the same way a fleet's
# is: its answer is only written while that is still the user's latest check
# and the handle and token are the ones it looked for.
class UserRsiVerification
  attr_reader :user

  def self.generation_of(checked_at)
    checked_at&.utc&.iso8601(6)
  end

  # For a check that raised: failed rather than left pending, which would keep
  # the profile waiting -- but only if nothing newer has answered since.
  def self.fail_if_current!(user, generation)
    user.with_lock do
      next unless user.rsi_verification_pending?
      next unless generation_of(user.rsi_verification_checked_at) == generation

      user.update_columns(rsi_verification_status: :failed, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def initialize(user, generation: nil)
    @user = user
    @generation = generation || self.class.generation_of(user.rsi_verification_checked_at)
  end

  def run
    handle = user.rsi_handle
    token = user.rsi_verification_token

    if handle.blank? || token.blank?
      apply(:failed, handle:, token:)
    else
      page = Rsi::CitizenPage.fetch(handle)
      apply(status_for(page, handle:, token:), handle:, token:, page_handle: page.handle).tap do |status|
        # The handle is proved now, so the orgs it is in can verify the fleets.
        UserRsiOrganizationsJob.perform_async(user.id) if status == :verified
      end
    end
  end

  private def status_for(page, handle:, token:)
    return page.status unless page.status == :ok
    return :handle_mismatch unless page.handle&.casecmp?(handle)
    return :token_missing unless page.bio.include?(token)

    :verified
  end

  # Two users proving a handle nobody holds at once both write it: the loser
  # meets the unique index and goes again, with a holder to take it from this
  # time.
  private def apply(status, handle:, token:, page_handle: nil, attempts: 2)
    applied = User.transaction do
      user.lock!

      next :stale unless self.class.generation_of(user.rsi_verification_checked_at) == @generation

      if user.rsi_handle != handle || user.rsi_verification_token != token || user.rsi_handle_verified?
        write(rsi_verification_status: nil) if user.rsi_verification_pending?
        next :stale
      end

      if status == :verified
        # The page's own spelling: RSI answers for any case of the handle.
        user.verify_rsi_handle(page_handle, via: :rsi_profile)
        user.save!(validate: false)
      else
        write(rsi_verification_status: status)
      end

      status
    end

    applied unless applied == :stale
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::Deadlocked
    raise if (attempts -= 1).zero?

    retry
  end

  private def write(**columns)
    user.update_columns(**columns, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end
end
