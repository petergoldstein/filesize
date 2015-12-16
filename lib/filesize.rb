class Filesize
  include Comparable

  TYPE_PREFIXES = {
    # Unit prefixes used for SI file sizes.
    :SI => %w{k M G T P E Z Y},
    # Unit prefixes used for binary file sizes.
    :BINARY => %w{Ki Mi Gi Ti Pi Ei Zi Yi}
  }

  # Set of rules describing file sizes according to SI units.
  SI = {
    :regexp => /^([\d,.]+)?\s?([kmgtpezy]?)b$/i,
    :multiplier => 1000,
    :prefixes => TYPE_PREFIXES[:SI],
  }
  # Set of rules describing file sizes according to binary units.
  BINARY = {
    :regexp => /^([\d,.]+)?\s?(?:([kmgtpezy])i)?b$/i,
    :multiplier => 1024,
    :prefixes => TYPE_PREFIXES[:BINARY],
  }

  # @param [Number] size A file size, in bytes.
  # @param [SI, BINARY] type Which type to use for conversions.
  def initialize(size, type = BINARY)
    @bytes = size.to_i
    @type  = type
  end

  # @return [Number] Returns the size in bytes.
  def to_i
    @bytes
  end
  alias_method :to_int, :to_i

  # @param [String] unit Which unit to convert to.
  # @return [Float] Returns the size in a given unit.
  def to_f(unit = 'B')
    to_parts = self.class.parse_unit(unit)
    prefix   = to_parts[:prefix]

    if prefix == 'B' or prefix.empty?
      return to_i.to_f
    end

    to_type = to_parts[:type]
    size    = @bytes

    pos = (@type[:prefixes].map { |s| s[0].chr.downcase }.index(prefix.downcase) || -1) + 1

    size = size/(to_type[:multiplier].to_f ** pos) unless pos < 1
  end

  # Formats the file size in the best matching unit.
  #
  # @return [String]
  def to_s
    if @bytes < @type[:multiplier]
      unit = "B"
    else
      pos = (Math.log(@bytes) / Math.log(@type[:multiplier])).floor
      pos = @type[:prefixes].size-1 if pos > @type[:prefixes].size - 1

      unit = @type[:prefixes][pos-1] + "B"
    end

    "%.2f %s" % [to_f(unit).to_f.to_s, unit]
  end

  # @return [Filesize]
  def +(other)
    self.class.new(@bytes + other.to_i, @type)
  end

  # @return [Filesize]
  def -(other)
    self.class.new(@bytes - other.to_i, @type)
  end

  # @return [Filesize]
  def *(other)
    self.class.new(@bytes * other.to_i, @type)
  end

  # @return [Filesize]
  def /(other)
    result = @bytes / other.to_f
    if other.is_a? Filesize
      result
    else
      self.class.new(result, @type)
    end
  end

  def <=>(other)
    self.to_i <=> other.to_i
  end

  # @return [Array<self, other>]
  # @api private
  def coerce(other)
    return self, other
  end

  class << self
    # Parses a string, which describes a file size, and returns a
    # Filesize object.
    #
    # @param [String] arg A file size to parse.
    # @raise [ArgumentError] Raised if the file size cannot be parsed properly.
    # @return [Filesize]
    def parse(arg)
      parts  = parse_unit(arg)
      prefix = parts[:prefix]
      size   = parts[:size]
      type   = parts[:type]

      raise ArgumentError, "Unparseable filesize" unless type
      offset = (type[:prefixes].map { |s| s[0].chr.downcase }.index(prefix.downcase) || -1) + 1
      new(size * (type[:multiplier] ** offset), type)
    end

    # @return [Hash<:prefix, :size, :type>]
    # @api private
    def parse_unit(string)
      type = nil
      # in this order, so we prefer binary :)
      [BINARY, SI].each { |_type|
        if string =~ _type[:regexp]
          type    =  _type
          break
        end
      }

      prefix = $2 || ''
      size   = ($1 || 0).to_f

      return { :prefix => prefix, :size => size, :type => type}
    end
  end

  # The size of a floppy disk
  Floppy = Filesize.parse("1474 KiB")
  # The size of a CD
  CD     = Filesize.parse("700 MB")
  # The size of a common DVD
  DVD_5  = Filesize.parse("4.38 GiB")
  # The same as a DVD 5
  DVD    = DVD_5
  # The size of a single-sided dual-layer DVD
  DVD_9  = Filesize.parse("7.92 GiB")
  # The size of a double-sided single-layer DVD
  DVD_10 = DVD_5 * 2
  # The size of a double-sided DVD, combining a DVD-9 and a DVD-5
  DVD_14 = DVD_9 + DVD_5
  # The size of a double-sided dual-layer DVD
  DVD_18 = DVD_14 * 2
  # The size of a Zip disk
  ZIP    = Filesize.parse("100 MB")
end
