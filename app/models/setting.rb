class Setting < ActiveRecord::Base

  def self.to_h
    hash = {}

    self.all.each do |setting|
      hash.deep_merge! setting.to_h
    end

    hash
  end

  def to_h
    parts = self.keypath.split '.'

    head = {}
    hash = head
    parts[0..-2].each do |key|
      sym = key.to_sym
      hash[sym] = {}
      hash = hash[sym]
    end

    hash[parts[-1]] = YAML.load self.value
    head
  end
end
