# encoding: UTF-8
require 'strscan'

class MaltAnalysis::Parser
  class Rahr < self

    def initialize(*)
      @memo = nil
      super
    end


    def scan
      grab_ship_date
      grab_ref_no
      slurp_varieties
      slurp_analysis
    end


  private

    def grab_ref_no
      skip_until marker: /Percent\s+/
      set "Reference Number", scanner.scan(/[\d-]+/)
    end


    def grab_results(array)
      if @memo
        set @memo, array[1]
        @memo = nil
      else
        if array[1] =~ /ASBC/
          set array[0], array[2]
        else
          set array[0], array[1]
        end
      end
    end


    def grab_ship_date
      scanner.scan_until /\d\d\/\d\d\/\d\d\d\d/
      set "Ship Date", scanner.matched
    end


    def parse_analysis_line(line:)
      return unless line
      vals = line.split(/\s\s+/)
      if( vals.size == 1 )
        @memo = vals[0]
      else
        grab_results vals
      end
    end


    def slurp_analysis
      skip_until marker: /\n\s+/
      guard_infinite do |i|
        line = scanner.scan(/[^\n]+\n\s+/)
        parse_analysis_line(line: line) if line
        line.nil?
      end
      parse_analysis_line line: scanner.scan(/[^\n]+/)
    end


    def slurp_varieties
      varieties = []
      scanner.scan_until(/Max Spec/).split(/\n/).each do |line|
        next if line =~ /^\s*$|^\s*Assay/
        m = /^\s*[0-9]+\s+([\w\s]+)\s+(\d+)%/.match(line)
        varieties << [ m[1].strip, m[2] ]
      end
      set "Varieties", varieties
    end

  end
end
