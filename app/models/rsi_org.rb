# encoding: utf-8
# frozen_string_literal: true

class RsiOrg
  attr_accessor :name, :main, :sid, :rank, :archetype, :language,
                :main_activity, :secondary_activity, :recruiting,
                :commitment, :rpg, :exclusive, :logo

  def initialize(args = {})
    self.name = args[:name]
    self.main = args[:main]
    self.sid = args[:sid]
    self.rank = args[:rank]
    self.archetype = args[:archetype]
    self.language = args[:language]
    self.main_activity = args[:main_activity]
    self.secondary_activity = args[:secondary_activity]
    self.recruiting = args[:recruiting]
    self.commitment = args[:commitment]
    self.rpg = args[:rpg]
    self.exclusive = args[:exclusive]
    self.logo = args[:logo]
  end
end
