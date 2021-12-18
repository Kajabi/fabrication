appraise 'kitchen-sink' do
  gem 'activerecord', require: 'active_record'
  gem 'dm-core'
  gem 'dm-migrations'
  gem 'dm-sqlite-adapter'
  gem 'dm-validations'
  gem 'mongoid'
  gem 'sequel'
end

appraise 'blank-slate' do
  # Simulates a framework-less environment
end

if RUBY_VERSION > '2.7.0'
  appraise 'rails-7.0' do
    gem 'activerecord', '~> 7.0.0', require: 'active_record'
  end
end

appraise 'rails-6.1' do
  gem 'activerecord', '~> 6.1.0', require: 'active_record'
end

appraise 'rails-6.0' do
  gem 'activerecord', '~> 6.0.0', require: 'active_record'
end

appraise 'mongoid-7.x' do
  gem 'mongoid', '~> 7.0'
end

appraise 'mongoid-6.x' do
  gem 'mongoid', '~> 6.0'
end

appraise 'sequel-5.x' do
  gem 'sequel', '~> 5.42'
end

appraise 'sequel-5.1' do
  gem 'sequel', '~> 5.1.0'
end

appraise 'sequel-4.x' do
  gem 'sequel', '~> 4.0'
end

if RUBY_VERSION < '3.0.0'
  appraise 'rails-5.2' do
    gem 'activerecord', '~> 5.2.0', require: 'active_record'
  end
end
