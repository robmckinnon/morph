guard :rspec, cmd: "bundle exec rspec --fail-fast", all_on_start: false, failed_mode: :focus do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/morph_spec_helper.rb')  { "spec" }
  watch('spec/spec_helper.rb')  { "spec" }
end
