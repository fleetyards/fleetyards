# frozen_string_literal: true

module Raffles
  # Signs an admin weighs before a draw that several entries may be one person.
  # None of them decides on its own: a household shares an IP, and a real new
  # user can sign up the day a raffle opens.
  class EntryWarnings
    NEW_ACCOUNT_WINDOW = 1.day

    # Gmail ignores dots in the local part and treats googlemail.com as the
    # same domain.
    GMAIL_DOMAINS = %w[gmail.com googlemail.com].freeze

    Warning = Struct.new(:shared_ip_with, :same_inbox_as, :new_account, :placeholder_email)

    def initialize(raffle)
      @raffle = raffle
    end

    # One inbox, however the address is written: `name+1@` and `name+2@` both
    # deliver to `name@`.
    def self.inbox(address)
      local, domain = address.to_s.strip.downcase.split("@", 2)
      return if local.blank? || domain.blank?

      local = local.split("+", 2).first
      if GMAIL_DOMAINS.include?(domain)
        local = local.delete(".")
        domain = GMAIL_DOMAINS.first
      end

      "#{local}@#{domain}"
    end

    def for(entry)
      user = entry.user
      return Warning.new([], [], false, false) if user.blank?

      Warning.new(
        others(by_ip, ips(user), user),
        others(by_inbox, [self.class.inbox(user.email)], user),
        entry.created_at - user.created_at < NEW_ACCOUNT_WINDOW,
        user.placeholder_email?
      )
    end

    private def others(index, keys, user)
      keys.compact.flat_map { |key| index.fetch(key, []) }
        .reject { |entrant| entrant.id == user.id }
        .map(&:username).uniq.sort
    end

    private def ips(user)
      [user.current_sign_in_ip, user.last_sign_in_ip].compact_blank.uniq
    end

    private def entrants
      @entrants ||= User.where(id: @raffle.entries.select(:user_id))
        .select(:id, :username, :email, :current_sign_in_ip, :last_sign_in_ip).to_a
    end

    private def by_ip
      @by_ip ||= entrants.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |user, index|
        ips(user).each { |ip| index[ip] << user }
      end
    end

    private def by_inbox
      @by_inbox ||= entrants.group_by { |user| self.class.inbox(user.email) }
    end
  end
end
