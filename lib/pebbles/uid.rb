module Pebbles
  class InvalidUid < StandardError; end
  class Uid
    def initialize(uid)
      /(?<klass>^[^:]+)\:(?<path>[^\#]*)?\#?(?<oid>.*$)?/ =~ uid
      self.klass, self.path, self.oid = klass, path, oid
    end

    attr_reader :klass, :path, :oid
    def klass=(value)
      return @klass = nil if value.strip == ''
      raise InvalidUid, "Invalid klass '#{value}'" unless self.class.valid_klass?(value)
      @klass = value
    end
    def path=(value)
      return @path = nil if value.strip == ''
      raise InvalidUid, "Invalid path '#{path}'" unless self.class.valid_path?(value)
      @path = (value.strip != "") ? value : nil
    end
    def oid=(value)
      return @oid = nil if value.strip == ''
      raise InvalidUid, "Invalid oid '#{oid}'" unless self.class.valid_oid?(value)
      @oid = (value.strip != "") ? value : nil
    end

    def self.parse(string)
      uid = new(string)
      [uid.klass, uid.path, uid.oid]
    end

    def self.valid_label?(value)
      !!(value =~ /^[a-zA-Z0-9]+$/)
    end

    def self.valid_klass?(value)
      self.valid_label?(value)
    end

    def self.valid_path?(value)
      # catches a stupid edge case in ruby where "..".split('.') == [] instead of ["", "", ""]
      return false if value =~ /^\.+$/ 
      value.split('.').each do |label|
        return false unless self.valid_label?(label)
      end
      true
    end

    def self.valid_oid?(value)
      self.valid_label?(value)
    end

    def inspect
      "#<Pebbles::Uid '#{to_s}'>"
    end

    def to_s
      "#{@klass}:#{@path}##{@oid}".chomp("#")
    end
    alias_method :to_uid, :to_s 

  end
end