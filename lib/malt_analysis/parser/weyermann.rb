# encoding: UTF-8
require 'strscan'

class MaltAnalysis::Parser
  class Weyermann < self

    def scan
      [ :lot, :analysis_number, :date ].each do |k|
        grab marker_key: k
      end
      slurp_analysis
      grab marker_key: :kolbach
    end


    def text
      reader.pages.first.text
    end

private

    MARKERS = {
                analysis_number: { marker: /Analysis Number:\s+/,
                                   expression: /[\w|\s]+$/,
                                   key: "Analysis Number".freeze
                                 },
                kolbach: { marker: /Kolbach Index:\s+/,
                           expression: /[\d.]+/,
                           key: "Kolbach Index".freeze
                         },
                lot: { marker: /Sample Type:.+\n\s+/,
                       expression: /[^\s]+/,
                       key: "Lot Number".freeze
                     },
                date: { marker: /Date of Production:\s+/,
                        expression: /\d\d\d\d-\d\d-\d\d/,
                        key: "Production Date".freeze
                      }
              }


    def grab(marker_key:)
      marker = MARKERS[marker_key]
      skip_until marker: marker[:marker]
      res = scanner.scan marker[:expression]
      set marker[:key], res
    end


    def process_data(l)
      if l.count("[") == 0
        process_partial l
      else
        process_full l
      end
    end


    def process_full(l)
      m = /^([^:]+): ([^\[]+) \[([^\]]+)/.match(l)
      if m
        set m[1], m.values_at(2,3).join(' ')
      else
        if l.count(":") == 1
          process_partial l
        else
          process_incomplete l
        end
      end
    end


    def process_incomplete(l)
      a = l.split(' ')
      if a.size < 3
        debug { "Don't know how to handle #{l}" }
        return
      end
      a[-1] = strip_brackets(a[-1])
      set a[0..-3].join(" "), a[-2..-1].join(" ")
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


    def process_partial(l)
      p = l.split(/:\s+/)
      set p[0], strip_brackets(p[1])
    end


    def skip_to_analysis
      skip_until marker: /Results:/
    end


    def slurp_analysis
      skip_to_analysis
      while m = scanner.scan_until(/\[[^\]]+\]/)
        s = m.squeeze(' ').strip
        debug { "Scanning #{s}" }
        process_lines s
      end
    end


    def strip_brackets(s)
      s.gsub(/[\[\]]/, '')
    end

  end
end
