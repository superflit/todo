module ActionPack
  # Returns the version of the currently loaded Action Pack as a <tt>Gem::Version</tt>
  def self.gem_version
    Gem::Version.new VERSION::STRING
  end

  module VERSION
    MAJOR = 4
    MINOR = 2
    TINY  = 11
    PRE   = "3"

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join(".")
  end
end