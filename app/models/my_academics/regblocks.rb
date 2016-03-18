module MyAcademics
  class Regblocks

    include AcademicsModule
    include DatedFeed
    include User::Student

    def merge(data)
      return unless legacy_user?
      data[:regblocks] = Bearfacts::Regblocks.new({user_id: @uid}).get
    end
  end
end
