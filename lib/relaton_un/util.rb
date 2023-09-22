module RelatonUn
  module Util
    extend RelatonBib::Util

    def self.logger
      RelatonUn.configuration.logger
    end
  end
end
