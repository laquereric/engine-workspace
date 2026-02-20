# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "rake", "~> 13.0"
gem "rspec", "~> 3.0", group: :test
gem "view_component"
gem "sqlite3", ">= 2.1"

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "rubocop-rails-omakase", require: false
end

eco_root = __dir__
eco_root = File.dirname(eco_root) until File.exist?("#{eco_root}/Gemfile.eco")
eval_gemfile "#{eco_root}/Gemfile.eco"

eco_gem "library-citizen"
eco_gem "engine-design-system"

# Soft dependencies — loaded at runtime if available
# eco_gem "engine-llm"
# eco_gem "engine-planner"

# Transitive deps of library-citizen need path refs until gems are published
eco_gem "library-exception"
eco_gem "library-biological"
eco_gem "service-protege"
eco_gem "library-json-rpc-ld-client"
eco_gem "library-json-rpc-ld-server"
eco_gem "library-manager"
eco_gem "library-semantics-rdf"
eco_gem "library-llm-engine"
eco_gem "library-heartbeat"
eco_gem "library-platform"
