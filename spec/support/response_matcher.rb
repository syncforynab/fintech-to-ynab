RSpec::Matchers.define :have_json do |expected_json|
  match do |response|
    JSON.parse(response.body) == expected_json
  end

  failure_message do |response|
    "Expected #{JSON.parse(response.body)} to match #{expected_json}"
  end
end
