# frozen_string_literal: true

# == Schema Information
#
# Table name: terminals
#
#  id                   :uuid             not null, primary key
#  available            :boolean          default(TRUE), not null
#  city                 :string
#  code                 :string
#  contact_url          :string
#  display_name         :string
#  has_docking_port     :boolean          default(FALSE), not null
#  has_freight_elevator :boolean          default(FALSE), not null
#  has_loading_dock     :boolean          default(FALSE), not null
#  max_container_size   :integer
#  moon                 :string
#  name                 :string           not null
#  nickname             :string
#  orbit                :string
#  outpost              :string
#  planet               :string
#  player_owned         :boolean          default(FALSE), not null
#  source_updated_at    :datetime
#  space_station        :string
#  star_system          :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  uex_id               :integer          not null
#
# Indexes
#
#  index_terminals_on_star_system  (star_system)
#  index_terminals_on_uex_id       (uex_id) UNIQUE
#
class Terminal < ApplicationRecord
  has_many :item_prices, dependent: :nullify
  has_many :origin_trade_routes, class_name: "TradeRoute", foreign_key: :origin_terminal_id, dependent: :delete_all, inverse_of: :origin_terminal
  has_many :destination_trade_routes, class_name: "TradeRoute", foreign_key: :destination_terminal_id, dependent: :delete_all, inverse_of: :destination_terminal

  validates :uex_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :contact_url, format: {with: %r{\Ahttps?://}}, allow_blank: true

  scope :available, -> { where(available: true) }
end
