require "malt_analysis/version"

module MaltAnalysis

  autoload :Parser, File.join('malt_analysis', 'parser')

  extend self

  def parser_for(malt:)
    Parser.lookup malt: malt
  end

end
