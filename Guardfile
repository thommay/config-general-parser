guard :rspec do
  watch(%r|^spec/unit/(.*)_spec\.rb|)
  watch(%r|^lib/.+/([^/]+)\.rb|) { |m| "spec/unit/#{m[1]}_spec.rb" }
end
