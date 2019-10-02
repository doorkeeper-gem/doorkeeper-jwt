# frozen_string_literal: true

module Doorkeeper
  module JWT
    def self.gem_version
      Gem::Version.new VERSION::STRING
    end

    module VERSION
      # Semantic versioning
      MAJOR = 0
      MINOR = 4
      TINY = 0
      PRE = nil

      # Full version number
      STRING = [MAJOR, MINOR, TINY, PRE].compact.join(".")
    end
  end
end
