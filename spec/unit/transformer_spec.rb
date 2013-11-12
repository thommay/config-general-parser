require 'spec_helper'

describe ConfigGeneralParser::Transformer do
  let (:tform) { ConfigGeneralParser::Transformer.new }
  let (:parser) { ConfigGeneralParser::Parser.new }

  describe "option" do
    it "should turn an option into a key and a value" do
      tform.apply(key: "foo", val: "a string").should eq("foo" => "a string")
    end
  end

  describe "block" do
    it "should turn a simple block into a type, and a hash of options" do
      tform.apply(block: {name: "", type: "simple", values: [{key: "foo", val: "a string"}]}).should eq({ "simple" => {"foo" => "a string"}})
    end

    it "should transform a named block into a deeper hash" do
      tree = parser.block.parse("<deep simple>\nfoo = a string\n</deep simple>\n")
      tform.apply(tree).should eq({ "deep" => { "simple" => {"foo" => "a string"}}})
    end

    it "should transform a list of options correctly" do
      tform.apply(block: {name: "", type: "simple", values: [{key: "bar", val: "ka"}, {key: "foo", val: "a string"}]}).should eq({ "simple" => {"bar" => "ka", "foo" => "a string"}})
    end

    it "should transform a list of options with the same name correctly" do
      tform.apply(block: {name: "", type: "simple", values: [{key: "foo", val: "ka"}, {key: "foo", val: "a string"}]}).should eq({ "simple" => {"foo" => ["ka", "a string"]}})
      tform.apply(block: {name: "", type: "simple", values: [{key: "foo", val: "zakalwe"}, {key: "foo", val: "ka"}, {key: "foo", val: "a string"}]}).should eq({ "simple" => {"foo" => ["zakalwe", "ka", "a string"]}})
    end

    it "should transform a subblock correctly" do
      tree = parser.block.parse("<deep simple>\nfoo = a string\n<ka>\na string\n</ka>\n</deep simple>\n")
      tform.apply(tree).should eq({"deep"=>{"simple"=>{"foo"=>"a string", "ka"=>{"a"=>"string"}}}})
    end
  end

  describe "document" do
    it "should parse a document" do
      tree = parser.parse("foo = bar\n<deep simple>\nfoo bar\nfoo = a string\n<foo>\na string\n</foo>\n</deep simple>\n")
      tform.apply(tree).should eq({"foo"=>"bar", "deep"=>{"simple"=>{"foo"=>["bar", "a string", {"a"=>"string"}]}}})
    end

    it "should parse a complex document" do
      tree = parser.parse("foo = bar\n<deep>\na value\n</deep>\n<deep simple>\nfoo bar\nfoo = a string\n<foo>\na string\n</foo>\n</deep simple>\n")
      tform.apply(tree).should eq({"foo"=>"bar", "deep"=>{"a"=>"value", "simple"=>{"foo"=>["bar", "a string", {"a"=>"string"}]}}})
    end
  end

  describe ".merge_into_array" do
    let (:target) {["a", "b", {"c" => "x"}]}

    it "merges a hash with a single key" do
      expect(ConfigGeneralParser::Transformer.merge_into_array(target, {"a" => "b"})).to eq([{"a" => "b"}, "b", {"c" => "x"}])
    end

    it "merges a hash with multiple keys" do
      expect(ConfigGeneralParser::Transformer.merge_into_array(target, {"a" => "b", "k" => "v"})).to eq([{"a" => "b"}, "b", {"c" => "x"}, { "k" => "v"}])
    end

    it "merges two hashes" do
      expect(ConfigGeneralParser::Transformer.merge_into_array(target, {"a" => "b" , "c" => "y"})).to eq([{"a" => "b"}, "b", {"c" => ["x", "y"]}])
    end
  end

  describe ".merge_options" do
    context "an empty target" do
      it "returns a hash with the new values in" do
        expect(ConfigGeneralParser::Transformer.merge_options({}, a: "b")).to eq("a" => "b")
      end

      it "merges a hash correctly" do
        expect(ConfigGeneralParser::Transformer.merge_options({}, a: {"b" => "c"})).to eq("a" => {"b"=>"c"})
      end
    end

    context "a single item" do
      it "magics it into an array" do
        expect(ConfigGeneralParser::Transformer.merge_options({"a"=>"b"}, {"a"=>"c"})).to eq("a" => ["b","c"])
      end
    end

    context "a hash target" do
      it "merges two hashes" do
        expect(ConfigGeneralParser::Transformer.merge_options({"a" => "c"}, {a: {"b" => "c"}})).to eq("a" => ["c", {"b"=>"c"}])
      end

      it "merges two complex hashes" do
        expect(ConfigGeneralParser::Transformer.merge_options({"a" => "c", "b" => "x"}, {a: {"b" => "c"}})).to eq("a" => ["c", {"b"=>"c"}], "b" => "x")
      end

      it "merges two deep hashes" do
        expect(ConfigGeneralParser::Transformer.merge_options({"a" => {"c" =>"d"}}, {a: {"b" => "c"}})).to eq("a" => {"c" => "d", "b"=>"c"})
      end
    end

    context "an array target" do
      it "should append to an array" do
        expect(ConfigGeneralParser::Transformer.merge_options({"a"=>["b", "d"]}, {"a"=>"c"})).to eq("a" => ["b","d","c"])
      end
      it "should merge deeply into an array" do
        expect(ConfigGeneralParser::Transformer.merge_options({"a" => ["x", {"c" =>"d"}]}, {a: {"c" => "e"}})).to eq("a" => ["x", {"c" => ["d","e"]}])
      end
    end
  end
end
