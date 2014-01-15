class AwesomeOpenStruct < OpenStruct
  extend Forwardable

  def initialize *args
    @originals = {}
    super
  end

  def new_ostruct_member(name)
    super
    sym = name.to_sym
    @originals[sym] = @table[sym]
    if @table[sym].is_a?(Hash)
      @table[sym] = AwesomeOpenStruct.new(@table[sym])
    end
    name
  end

  def [] key
    @originals[key.to_sym] || @originals[key.to_s]
  end

  def merge hash
    merged = @originals.deep_merge hash
    self.marshal_load merged
  end

  def check_path? path
    result = true
    follow_path(path) do |key|
      unless key
        result = false
        break
      end
    end
    result
  end

  def find path
    current_step = follow_path(path) do |key|
      break unless key
    end

    current_step
  end

  def follow_path path, current_step = nil
    current_step ||= @originals
    steps = path.split('.')
    steps.each do |step|
      key = current_step.has_key?(step.to_sym) || current_step.has_key?(step.to_s)
      yield(key, step)
      current_step = current_step[step.to_sym] || current_step[step.to_s]
    end

    current_step
  end

  def reset path, value
    reset_hash = {}

    hash = reset_hash
    steps = path.split('.')
    steps[0..-2].each do |key|
      sym = key.to_sym
      hash[sym] = {}
      hash = hash[sym]
    end
    hash[steps[-1]] = YAML.load value.to_s

    self.merge reset_hash
  end

  def_delegators :@originals, :each, :map, :keys, :first, :to_hash, :symbolize_keys, :has_key?
end
