require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.default_cassette_options = {
    clean_outdated_http_interactions: true,
    re_record_interval: 7 * 24 * 3600,
    record: :once,
    match_requests_on: %i[method body],
  }
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.filter_sensitive_data("<UN_AUTH_TOKEN>") do |interaction|
    interaction.request.headers["Authorization"]&.first
  end
end
