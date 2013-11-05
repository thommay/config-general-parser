require 'spec_helper'

describe ConfigGeneralParser::Parser do
  let(:parser) { ConfigGeneralParser::Parser.new }

  context "#simple_string" do
    it "should parse 'a'" do
      parser.string.should parse('a')
    end

    it "should parse 'a string'" do
      parser.string.should parse('a string')
    end
  end

  context "#string" do
    it "should parse a quoted string" do
      parser.string.should parse('"a string"')
    end

    it "should parse a quoted string with leading spaces" do
      parser.string.should parse('" a string"')
    end

    it "should parse a quoted string with trailing spaces" do
      parser.string.should parse('"a string "')
    end
  end

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

    it "captures the key and the value" do
      parser.option.parse("foo = bar\n").should eq(
       option: {key: "foo", val: {string: "bar"}})
    end
  end

  context "#block_open" do
    it "parses a simple block" do
      parser.block_open.should parse("<foo>\n")
    end

    it "parses a named block" do
      parser.block_open.should parse("<foo bar>\n")
    end

    it "captures both block and name" do
      parser.block_open.parse("<foo bar>\n").should eq(
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


    it "captures all the values from a simple block" do
      parser.block.parse("<foo>\nbar baz\n</foo>\n").should eq(
        name: [], type: "foo",
        block: [{option: {key: "bar", val: {string: "baz"}}}]
      )
    end
  end

  context "#document" do
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
