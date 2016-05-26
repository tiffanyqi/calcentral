# Simple parser to turn top -H output into a CSV file with hexadecimal PIDs.
# From the shell:
#   ruby lib/top_h_parser.rb /Downloads/memheaps/perf-2016-05-22-prod-01-top.log

class TopHParser
  require 'csv'

  STATS_ROW = /^\s*(?<pid>\d+)\s+app_calc\s+\d+\s+\d+\s+\S+\s+\S+\s+\S+\s+\S+\s+(?<cpu>[0-9.]+)\s+[0-9.]+\s+(?<time>[0-9:.]+)\s+java\s*/
  HEADER_ROW = /^\s*PID\s+USER\s+PR\s+NI\s+VIRT\s+RES\s+SHR/

  def self.run(top_h_filename)
    # Output CSV file to the same directory as the input 'top -H' log.
    top_h_path = File.expand_path top_h_filename
    raise RuntimeError, "top-H logfile does not exist: #{top_h_path}" unless File.exists? top_h_path
    top_h_lines = File.open(top_h_path).read.split /\r\n?|\n/
    parsed = TopHParser.new.parse_lines top_h_lines
    unless parsed.empty?
      csv_out_path = "#{top_h_path}.csv"
      CSV.open(
        csv_out_path, 'wb',
        {
          headers: parsed.first.keys,
          write_headers: true
        }
      ) do |csv|
        parsed.each {|row| csv << row}
      end
      puts "Parsed output is at #{csv_out_path}"
    else
      puts "No Java top -H stats found in #{top_h_filename}!"
    end
  end

  def parse_lines(lines)
    run = 0
    parsed_output = []
    lines.each do |line|
      if HEADER_ROW.match line
        run += 1
      elsif (row = STATS_ROW.match line)
        pid = row[:pid]
        parsed_output << {
          xpid: "x#{pid.to_i.to_s(16)}",
          pid: pid,
          cpu: row[:cpu].to_f,
          time: row[:time],
          run: run
        }
      end
    end
    parsed_output
  end
end

if __FILE__ == $0
  if ARGV[0]
    TopHParser.run ARGV[0]
  else
    puts 'Missing the input file name'
  end
end
