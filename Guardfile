# Guardfile
# frozen_string_literal: true

guard :rspec, cmd: "bin/test" do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^app/(.+)\.rb$}) { |match| "spec/#{match[1]}_spec.rb" }
  watch(%r{^lib/(.+)\.rb$}) { |match| "spec/lib/#{match[1]}_spec.rb" }
  watch("spec/rails_helper.rb") { "spec" }
  watch("spec/spec_helper.rb") { "spec" }
end

guard :rubocop, cli: [ "--force-exclusion" ] do
  watch(%r{.+\.rb$})
  watch(%r{(?:^|/)(?:\.rubocop|rubocop).+\.ya?ml$}) { |match| File.dirname(match[0]) }
  watch("Gemfile")
  watch("Rakefile")
end
