# db/seeds/accounts.seeds.rb
# frozen_string_literal: true

accounts = [
  [ "Bluebonnet Logistics", "Enterprise", "Central", "active" ],
  [ "Cedar Ridge Health", "Growth", "East", "active" ],
  [ "High Plains Supply", "Starter", "West", "trial" ],
  [ "Lone Star Fieldworks", "Enterprise", "Central", "active" ],
  [ "Pecan Street Labs", "Growth", "West", "active" ],
  [ "Trinity River Foods", "Growth", "East", "active" ]
].map do |name, plan, region, status|
  Account.find_or_initialize_by(name:).tap do |account|
    account.update!(plan:, region:, status:)
  end
end

random = Random.new(20_260_905)

accounts.each_with_index do |account, account_index|
  30.times do |days_ago|
    metric = DailyMetric.find_or_initialize_by(account:, recorded_on: Date.current - days_ago.days)
    active_users = 90 + (account_index * 47) + random.rand(0..35)
    requests = active_users * random.rand(28..42)

    metric.update!(
      active_users:,
      error_count: (requests * random.rand(0.001..0.009)).round,
      p95_ms: random.rand(110..390),
      request_count: requests,
      revenue_cents: 3_900_000 + (account_index * 825_000) + random.rand(0..250_000)
    )
  end
end

contact_blueprints = {
  "Bluebonnet Logistics" => [
    [ "Marisol", "Vega", "Chief Operating Officer", "Executive sponsor" ],
    [ "Owen", "Brooks", "Dispatch Systems Manager", "Operations lead" ],
    [ "Priya", "Nair", "Integration Engineer", "Technical lead" ]
  ],
  "Cedar Ridge Health" => [
    [ "Dana", "Whitfield", "Vice President of Care Operations", "Executive sponsor" ],
    [ "Tessa", "Nguyen", "Clinic Operations Director", "Operations lead" ],
    [ "Elias", "Grant", "Platform Architect", "Technical lead" ]
  ],
  "High Plains Supply" => [
    [ "Quinn", "Harper", "General Manager", "Executive sponsor" ],
    [ "Casey", "Rhodes", "Warehouse Operations Lead", "Operations lead" ],
    [ "Mateo", "Silva", "Systems Analyst", "Technical lead" ]
  ],
  "Lone Star Fieldworks" => [
    [ "Simone", "Carter", "Chief Service Officer", "Executive sponsor" ],
    [ "Wyatt", "Bell", "Field Operations Manager", "Operations lead" ],
    [ "Nina", "Shah", "Principal Engineer", "Technical lead" ]
  ],
  "Pecan Street Labs" => [
    [ "Lena", "Ortiz", "Chief Product Officer", "Executive sponsor" ],
    [ "Graham", "Foster", "Customer Operations Manager", "Operations lead" ],
    [ "Imani", "Reed", "Staff Software Engineer", "Technical lead" ]
  ],
  "Trinity River Foods" => [
    [ "Rosa", "Delgado", "Vice President of Distribution", "Executive sponsor" ],
    [ "Theo", "Bennett", "Fulfillment Director", "Operations lead" ],
    [ "Anika", "Rao", "Enterprise Applications Lead", "Technical lead" ]
  ]
}.freeze

accounts.index_by(&:name).each do |account_name, account|
  contact_blueprints.fetch(account_name).each do |first_name, last_name, job_title, relationship_role|
    email = "#{first_name}.#{last_name}@#{account_name.parameterize}.example".downcase
    contact = Contact.find_or_initialize_by(email:)
    contact.update!(account:, first_name:, job_title:, last_name:, relationship_role:)
  end
end
