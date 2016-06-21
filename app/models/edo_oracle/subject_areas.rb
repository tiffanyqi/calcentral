module EdoOracle
  class SubjectAreas
    extend Cache::Cacheable

    def self.fetch
      fetch_from_cache { self.new }
    end

    def initialize
      # Build a map to restore subject-area formatting lost in Campus Solutions stripping of non-alphanumeric characters.
      @decompression_map = EdoOracle::Queries.get_subject_areas.inject({}) do |map, row|
        compressed = self.class.compress row['subjectarea']
        # If multiple decompressions are available, prefer the longest.
        if !map[compressed] || (map[compressed].length < row['subjectarea'].length)
          map[compressed] = row['subjectarea']
        end
        map
      end
    end

    def self.compress(subject_area)
      subject_area.gsub(/\W+/, '') if subject_area
    end

    def decompress(subject_area)
      compressed = self.class.compress subject_area
      @decompression_map[compressed] || subject_area
    end

  end
end
