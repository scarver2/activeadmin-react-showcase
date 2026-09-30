# lib/tasks/global_search.rake
# frozen_string_literal: true

namespace :global_search do
  desc "Repair and rebuild the application-owned Active Search indexes"
  task rebuild: :environment do
    Showcase::GlobalSearchIndex.rebuild!
  end
end
