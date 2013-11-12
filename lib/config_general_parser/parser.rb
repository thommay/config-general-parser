require 'parslet'
require 'parslet/convenience'

module ConfigGeneralParser
  class Parser < Parslet::Parser
    root :document

    rule(:spaces) { match('[ \t]').repeat(1) }
    rule(:spaces?) { spaces.maybe }
    rule(:newline)    { match["\\n"] }
    rule(:eof) { any.absent? }

    rule(:comment) {
      str('#') >> any.repeat >> newline.maybe
    }

    rule(:option) {
      ( spaces? >> match['[:alnum:]'].repeat.as(:key) >> spaces? >>
        str('=').maybe >> spaces?  >>
        (newline.absent? >> any).repeat.as(:val)) >> newline
    }

    rule(:block_open) {
      spaces? >> str("<") >> str("/").absent? >>
      (str('"').maybe >> match['[^\"> ]'].repeat.as(:type) >> str('"').maybe >>
        (spaces? >> str('"').maybe >> match['[^\">]'].repeat.maybe.as(:name) >> str('"').maybe)).
      capture(:block_key) >> str(">") >> newline
    }

    # FIXME: There *HAS* to be a better way to do this
    rule(:block_end) {
      spaces? >> str('</') >> str('"').maybe >>
      dynamic do |_, context|
        type = context.captures[:block_key][:type]
        str(type)
      end >> str('"').maybe >> spaces? >> str('"').maybe >>
      dynamic do |_, context|
        name = context.captures[:block_key][:name]
        str(name)
      end >> str('"').maybe >> str('>') >> newline
    }

    rule(:block_line) {
      block_end.absent? >> value
    }

    rule(:block) {
      (scope { block_open >> (block | block_line).repeat.as(:values) >> block_end }).as(:block)
    }

    rule(:value) {
      (option | comment)
    }

    rule(:document) {
      scope { (eof.absent? >> (block | value)).repeat }.as(:document)
    }

  end
end
