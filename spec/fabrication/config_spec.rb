require 'spec_helper'

describe Fabrication::Config do
  after { described_class.reset_defaults }

  it 'provides reasonable defaults' do
    expect(described_class.fabricator_path).to eq(['test/fabricators', 'spec/fabricators'])
    expect(described_class.path_prefix).to eq(['.'])
    expect(described_class.sequence_start).to eq(0)
  end

  describe '.fabricator_path' do
    context 'with a single folder' do
      before do
        Fabrication.configure do |config|
          config.fabricator_path = 'lib'
        end
      end

      it 'stores the fabricator_path' do
        expect(described_class.fabricator_path).to eq(['lib'])
      end
    end

    context 'with multiple folders' do
      before do
        Fabrication.configure do |config|
          config.fabricator_path = %w[lib support]
        end
      end

      it 'stores the fabricator_path' do
        expect(described_class.fabricator_path).to eq(%w[lib support])
      end
    end
  end

  describe '.path_prefix' do
    context 'with a single folder' do
      before do
        Fabrication.configure do |config|
          config.path_prefix = '/path/to/app'
        end
      end

      it 'stores the path prefix' do
        expect(described_class.path_prefix).to eq(['/path/to/app'])
      end
    end

    context 'with multiple folders' do
      before do
        Fabrication.configure do |config|
          config.path_prefix = %w[/path/to/app /path/to/gem/fabricators]
        end
      end

      it 'stores the path prefix' do
        expect(described_class.path_prefix).to eq(['/path/to/app', '/path/to/gem/fabricators'])
      end
    end
  end

  describe '.register_generator' do
    before do
      Fabrication.configure do |config|
        config.generators << ImmutableGenerator
      end
    end

    it 'stores the generator' do
      expect(described_class.generators).to eq([ImmutableGenerator])
    end
  end
end
