lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "relaton_un/version"

# rubocop:disable Metrics/BlockLength
Gem::Specification.new do |spec|
  spec.name          = "relaton-un"
  spec.version       = RelatonUn::VERSION
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["open.source@ribose.com"]

  spec.summary       = "RelatonIso: retrieve CC Standards for bibliographic " \
                       "use using the IsoBibliographicItem model"
  spec.description   = "RelatonIso: retrieve CC Standards for bibliographic " \
                       "use using the IsoBibliographicItem model"
  spec.homepage      = "https://github.com/relaton/relaton-un"
  spec.license       = "BSD-2-Clause"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/})
    end
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "addressable", "~> 2.8.0"
  spec.add_dependency "faraday", "~> 2.7.0"
  spec.add_dependency "http-cookie", "~> 1.0.5"
  spec.add_dependency "relaton-bib", "~> 1.20.0"
  # spec.add_dependency "unf_ext", ">= 0.0.7.7"
end
# rubocop:enable Metrics/BlockLength
