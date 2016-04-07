module Berkeley
  module CourseCodes
    extend self

    def comparable_course_code(course)
      course_code = if course[:listings]
                      course[:listings].map { |l| l[:course_code] }.min
                    else
                      course[:course_code]
                    end
      dept_name, catalog = course_code.rpartition(' ').values_at(0, 2)
      catalog_prefix, catalog_root, catalog_suffix_1, catalog_suffix_2 = catalog.match(/([A-Z]?)(\d+)([A-Z]?)([A-Z]?)/).to_a.slice(1..4)
      [dept_name, catalog_root.to_i, catalog_prefix, catalog_suffix_1, catalog_suffix_2]
    end

    def comparable_section_code(section)
      [(section[:is_primary_section] ? 0 : 1), section[:section_label]]
    end

  end
end
