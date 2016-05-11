require 'spec_helper'

describe ConfigGeneralParser::Parser do
  let(:parser) { ConfigGeneralParser::Parser.new }

  context "#comment" do
    it "should parse a comment" do
      parser.comment.should parse("#foo\n")
    end

    it "should ignore normal text" do
      parser.comment.should_not parse("bar #foo\n")
    end
  end

  context "#option" do
    it "should parse a key value pair" do
      parser.option.should parse("foo = bar\n")
    end

    it "should parse a quoted value" do
      parser.option.should parse("foo = \"bar\"\n")
    end

    it "should parse a key value with no '='" do
      parser.option.should parse("foo bar\n")
    end

    it "should parse a quoted key value with no '='" do
      parser.option.should parse("foo \"bar\"\n")
    end

    it "should parse a string with funky characters" do
      parser.option.should parse("foo = \"/etc/init.d/tomcat restart | tee /var/tmp/opman.log\"\n")
    end

    it "should parse a heredoc string" do
      parser.option.parse("foo <<FOO\nvalues\nFOO\n").should eq(
        key: "foo", val: { heredoc: { name: "FOO", content: "values\n" }})
    end

    it "captures the key and the value" do
      parser.option.parse("foo = bar\n").should eq( key: "foo", val: "bar")
    end
  end

  context "#heredoc_open" do
    it "parses a simple heredoc" do
      parser.heredoc_open.should parse("<<EOF\n")
    end

    it "captures heredoc name" do
      expect(parser.heredoc_open.parse("<<EOF\n")).to eq(
        name: "EOF")
    end
  end

  context "#heredoc" do
    it "parses heredoc" do
      parser.heredoc.should parse(<<-EOH
<<HERE
value
value2
HERE
EOH
)
    end

    it "captures heredoc options" do
      expect(parser.heredoc.parse("<<HERE\nvalue 1\nvalue 2\nHERE\n")).to eq(
        heredoc: {
          name: "HERE",
          content: "value 1\nvalue 2\n"
        }
      )
    end
  end

  context "#block_open" do
    it "parses a simple block" do
      parser.block_open.should parse("<foo>\n")
    end

    it "parses a named block" do
      parser.block_open.should parse("<foo bar>\n")
    end

    it "parses a block with a silly name" do
      expect(parser.block_open.parse("<foo bar-baz>\n")).to eq(
        type: "foo", name: "bar-baz")
    end

    it "parses a block with a quoted type" do
      expect(parser.block_open).to parse("<\"foo\">\n")
    end

    it "parses a block with a quoted type and name" do
      expect(parser.block_open).to parse("<\"foo\" \"bar\">\n")
    end

    it "parses a block with a quoted type and unqouted name" do
      expect(parser.block_open).to parse("<\"foo\" bar>\n")
    end

    it "parses a block with an unquoted type and quoted name" do
      expect(parser.block_open).to parse("<foo \"bar\">\n")
    end

    it "captures both block and name" do
      parser.block_open.parse("<foo bar>\n").should eq(
        type: "foo", name: "bar")
    end

    it "captures both block and name when quoted" do
      parser.block_open.parse("<\"foo\" \"bar\">\n").should eq(
        type: "foo", name: "bar")
    end

  end

  context "#block" do
    it "parses a full block" do
      parser.block.should parse(<<-EOH
<foo>
                                bar baz
                                </foo>
                                EOH
                               )
    end

    it "parses a block with multiple values" do
      parser.block.should parse(<<-EOH
<foo>
                                bar baz
                                foo = caz
                                </foo>
                                EOH
                               )
    end

    it "parses a block with a sub block" do
      parser.block.should parse(<<-EOH
                                <foo>
                                <bar baz>
                                foo = caz
                                </bar baz>
                                </foo>
                                EOH
                               )
    end

    it "parses a block with options and a sub block" do
      parser.block.should parse(<<-EOH
                                <foo>
                                foo = caz
                                <bar baz>
                                foo = caz
                                </bar baz>
                                </foo>
                                EOH
                               )
    end

    it "parses a named block" do
      expect(parser.block).to parse(<<-EOH
<pool api>
                                bar baz
                                foo = caz
                                </pool api>
                                EOH
                               )
    end

    it "parses a named block with quoted type" do
      expect(parser.block).to parse(<<-EOH
                                <"pool" api>
                                bar baz
                                foo = caz
                                </"pool" api>
                                EOH
                               )
    end

    it "captures all the values from a simple block" do
      parser.block.parse("<foo>\nbar baz\n</foo>\n").should eq(
        block: {
          name: "", type: "foo",
          values: [{key: "bar", val: "baz"}]
        }
      )
    end

    it "captures all the values from a named block" do
      parser.block.parse("<pool api>\nbar baz\n</pool api>\n").should eq(
        block: {
          name: "api", type: "pool",
          values: [{key: "bar", val:"baz"}]
        }
      )
    end
  end

  context "#document" do
    it "parses an empty block" do
      expect(parser.document).to parse("<pool api>\n</pool api>\n")
    end

    it "parses a document starting with a block" do
      parser.document.should parse("<foo>\nfoo bar\n</foo>\n")
    end

    it "parses a document starting with an option" do
      parser.document.should parse("foo = bar\n<foo>\nfoo bar\n</foo>\n")
    end

    it "parses a document with just options" do
      parser.document.should parse("foo = bar\nfoo bar\n")
    end
  end
end
