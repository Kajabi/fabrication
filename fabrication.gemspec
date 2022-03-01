lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'fabrication/version'

Gem::Specification.new do |s|
  s.name = 'fabrication'
  s.version = Fabrication::VERSION
  s.license = 'MIT'

  s.authors = ['Paul Elliott']
  s.email = ['paul@codingfrontier.com']
  s.description = 'Fabrication is an object generation framework for ' \
                  'ActiveRecord, Mongoid, DataMapper, Sequel, or any other Ruby object.'

  s.homepage = 'http://fabricationgem.org'
  s.require_paths = ['lib']
  s.rubygems_version = '1.3.7'
  s.required_ruby_version = '>= 2.4.0'
  s.summary = 'Generates object instances for test suites, seed files, etc.'

  s.files = Dir.glob('lib/**/*') + %w[LICENSE README.markdown Rakefile]
  s.require_path = 'lib'

  s.metadata = {
    'bug_tracker_uri' => 'https://gitlab.com/fabrication-gem/fabrication/-/issues',
    'changelog_uri' => 'https://gitlab.com/fabrication-gem/fabrication/-/blob/master/Changelog.markdown',
    'documentation_uri' => 'https://fabricationgem.org',
    'homepage_uri' => 'https://fabricationgem.org',
    'mailing_list_uri' => 'https://groups.google.com/g/fabricationgem',
    'rubygems_mfa_required' => 'true',
    'source_code_uri' => 'https://gitlab.com/fabrication-gem/fabrication'
  }
end
