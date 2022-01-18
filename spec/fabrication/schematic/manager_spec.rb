require 'spec_helper'

describe Fabrication::Schematic::Manager do
  let(:manager) { described_class.instance }

  before { manager.clear }

  describe '#register' do
    let(:options) { { aliases: ['thing_one', :thing_two] } }

    before do
      manager.register(:open_struct, options) do
        first_name 'Joe'
        last_name { 'Schmoe' }
      end
    end

    it 'creates a schematic' do
      expect(manager.schematics[:open_struct]).not_to be_nil
    end

    it 'infers the correct class' do
      expect(manager.schematics[:open_struct].send(:klass)).to eq(OpenStruct)
    end

    it 'has the attributes' do
      expect(manager.schematics[:open_struct].attributes.size).to eq(2)
    end

    context 'with an alias' do
      it 'recognizes the aliases' do
        expect(manager.schematics[:thing_one]).to eq(manager.schematics[:open_struct])
        expect(manager.schematics[:thing_two]).to eq(manager.schematics[:open_struct])
      end
    end
  end

  describe '#[]' do
    subject { manager[key] }

    before { manager.schematics[:some] = 'thing' }

    context 'with a symbol' do
      let(:key) { :some }

      it { is_expected.to eq('thing') }
    end

    context 'with a string' do
      let(:key) { 'some' }

      it { is_expected.to eq('thing') }
    end
  end

  describe '.load_definitions' do
    it 'registers fabricators in files defined by the fabricator_paths' do
      Fabrication.clear_definitions
      Fabrication::Config.fabricator_paths << 'spec/fabricators.rb'
      Fabrication.manager.load_definitions

      # loads individual files named in fabricator_paths
      expect(Fabrication.manager[:loaded_from_single_file]).not_to be_nil

      # loads files in folders named in fabricator_paths
      expect(Fabrication.manager[:parent_ruby_object]).not_to be_nil
    end

    context 'when an error occurs during the load' do
      it 'still freezes the manager' do
        allow(Fabrication::Config).to receive(:fabricator_paths).and_raise(Exception)
        expect { Fabrication.manager.load_definitions }.to raise_error(Exception)
        expect(Fabrication.manager).not_to be_initializing
      end
    end
  end
end
