require "config_general_parser/parser"
require "config_general_parser/transformer"
require "config_general_parser/version"

module ConfigGeneralParser
  Error          = Class.new StandardError
  ParseError     = Class.new Error

  def self.load(str)
    Transformer.new.apply(Parser.new.parse(str))
  rescue Parslet::ParseFailed => e
    deepest = deepest_cause e.cause
    line, column = deepest.source.line_and_column(deepest.pos)
    raise ParseError, "unexpected input at line #{line} and column #{column}"
  end

  # Internal: helper for finding the deepest cause for a parse error
  # Robbed brutally from http://zerowidth.com/2013/03/14/displaying-errors-in-a-toml-document.html
  def self.deepest_cause(cause)
    if cause.children.any?
      deepest_cause(cause.children.first)
    else
      cause
    end
  end
end
