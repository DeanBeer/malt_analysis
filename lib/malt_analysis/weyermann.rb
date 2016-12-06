require 'strscan'
module MaltAnalysis
  class Weyermann

    attr_reader :results

    def initialize(str:)
      @results = {}
      @scanner = StringScanner.new(str)
      @str = str
      freeze
    end


    def process
      str.split(/\n/).each do |l|
        next if l =~ /^\s*$/
        puts l.strip.gsub(/\s+/, ' ')
      end
    end


    def scan
      grab_date
      skip_to_analysis
      while m = scanner.scan_until(/\[[^\]]+\]/)
        process_lines m.squeeze(' ').strip
      end
    end

private

    attr_reader :scanner, :str

    def grab_date
      s = "Date of Production".freeze
      scanner.scan_until /#{s}:\s+/
      d = scanner.scan /\d\d\d\d-\d\d-\d\d/
      results[s] = d
    end


    def process_lines(*l)
      l.each do |s|
        if( s.count(':') > 1 )
          process_lines *s.split(/\s\s+/)
        else
          process_data s
        end
      end
    end


    def process_data(l)
      if l.count("[") == 0
        process_partial l
      else
        process_full l
      end
    end


    def process_incomplete(l)
      a = l.split(' ')
      if a.size < 3
        STDERR.puts "Don't know how to handle #{l}"
        return
      end
      a[-1] = strip_brackets(a[-1])
      results[ a[0..-3].join(" ") ] = a[-2..-1].join(" ")
    end


    def process_partial(l)
      p = l.split(/:\s+/)
      results[p[0]] = strip_brackets(p[1])
    end


    def process_full(l)
      m = /^([^:]+): ([^\[]+) \[([^\]]+)/.match(l)
      if m
        results[m[1]] = m.values_at(2,3).join(' ')
      else
        if l.count(":") == 1
          process_partial l
        else
          process_incomplete l
        end
      end
    end


    def skip_to_analysis
      scanner.skip_until /Results:/
    end


    def strip_brackets(s)
      s.gsub(/[\[\]]/, '')
    end

  end
end
