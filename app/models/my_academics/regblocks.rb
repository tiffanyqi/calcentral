module MyAcademics
  class Regblocks

    include AcademicsModule
    include DatedFeed
    include User::Student

    def merge(data)
      # TODO Remove by Fall 2016.
      return unless legacy_user? && current_term.legacy?
      data[:regblocks] = Bearfacts::Regblocks.new({user_id: @uid}).get
    end
  end
end
