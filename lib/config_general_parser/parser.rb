require 'parslet'
require 'parslet/convenience'

module ConfigGeneralParser
  class Parser < Parslet::Parser
    root :document

    rule(:spaces) { match('[ \t]').repeat(1) }
    rule(:spaces?) { spaces.maybe }
    rule(:newline)    { match["\\n"] }
    rule(:eof) { any.absent? }

    rule(:simple_string) {
      (match['[:alnum:]'] >>
       (spaces | match['[:alnum:]']).repeat).repeat
    }

    rule(:string) {
      (str('"').maybe >> spaces? >>
      simple_string >> spaces? >>
      str('"').maybe).as(:string)
    }

    rule(:comment) {
      str('#') >> any.repeat >> newline.maybe
    }

    rule(:option) {
      ( spaces? >> match['[:alnum:]'].repeat.as(:key) >> spaces? >>
        str('=').maybe >> spaces?  >>
        string.as(:val)) >> newline
    }

    rule(:block_open) {
      spaces? >> str("<") >> str("/").absent? >>
      ( match['[:alnum:]'].repeat.as(:type) >>
        (spaces? >> match['[:alnum:]'].repeat.as(:name)).maybe).capture(:block_key) >>
      str(">") >> newline
    }

    rule(:block_end) {
      spaces? >> dynamic do |source, context|
        str(format_block_end(context.captures[:block_key]))
      end >> newline
    }

    rule(:block_line) {
      block_end.absent? >> value
    }

    rule(:block) {
      scope { block_open >> (block | block_line).repeat.as(:block) >> block_end }
    }

    rule(:value) {
      (option | comment)
    }

    rule(:document) {
      scope { (eof.absent? >> (block | value)).repeat }
    }

    private
    def format_block_end(hsh)
      k = "</#{hsh[:type]} "
      k << "#{hsh[:name]}" if hsh[:name].size > 0
      k.strip + ">"
    end
  end
end
