require 'pdf-reader'
require 'strscan'

module MaltAnalysis
  class Parser

    autoload :Rahr, File.join('malt_analysis', 'parser', 'rahr')
    autoload :Weyermann, File.join('malt_analysis', 'parser', 'weyermann')

    CLASS_TABLE = {
                    rahr: :Rahr,
                    weyermann: :Weyermann
                  }

    def self.lookup(malt:)
      class_table[malt] && const_get(class_table[malt])
    end

    def self.class_table; CLASS_TABLE; end


    attr_reader :results

    def dump
      text.split(/\n/).each do |l|
        next if l =~ /^\s*$/
        puts l.strip
      end
    end


    def initialize(filename: nil, reader: nil, logger: nil)
      @logger = logger
      @reader = reader || PDF::Reader.new(filename)
      @results = {}
      @scanner = StringScanner.new(text)
    end


    def text
      reader && reader.pages.first.text
    end

  private

    attr_reader :logger, :reader, :scanner

    def debug(&block)
      return if logger.nil?
      logger.debug name, &block
    end


    def guard_infinite(max_loop: 500)
      return unless block_given?
      i = 0
      stop = false
      while ! stop
        stop = yield(i)
        i += 1
        if( i >= max_loop )
          warn "Possible infinite loop detected after #{i} iterations\n#{caller}"
          stop = true
        end
      end
    end


    def name
      self.class.name
    end


    def set(key, value)
      debug { "Found %s = %s\n" % [ key, value ] }
      results[key] = value
    end


    def skip_until(marker:)
      return unless scanner
      skipped = scanner.skip_until marker
      debug { "Skipped #{skipped} looking for #{marker}" }
      skipped
    end

  end
end
