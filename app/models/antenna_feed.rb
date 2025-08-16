# frozen_string_literal: true

class AntennaFeed < Feed
  def initialize(antenna)
    super(:antenna, antenna.id)
  end
end