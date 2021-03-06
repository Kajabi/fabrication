require 'spec_helper'

describe Fabrication::Schematic::Definition do
  let(:schematic) do
    described_class.new('OpenStruct') do
      name 'Orgasmo'
      something(param: 2) { 'hi!' }
      another_thing { 25 }
    end
  end

  describe 'generator selection' do
    subject { described_class.new(klass).generator }

    context 'with an activerecord object', depends_on: :active_record do
      let(:klass) { 'ParentActiveRecordModel' }

      it { is_expected.to eq(Fabrication::Generator::ActiveRecord) }
    end

    context 'with a mongoid object', depends_on: :mongoid do
      let(:klass) { 'ParentMongoidDocument' }

      it { is_expected.to eq(Fabrication::Generator::Mongoid) }
    end

    context 'with a sequel object', depends_on: :sequel do
      let(:klass) { 'ParentSequelModel' }

      it { is_expected.to eq(Fabrication::Generator::Sequel) }
    end
  end

  describe '.new' do
    it 'stores the name' do
      expect(schematic.name).to eq('OpenStruct')
    end

    it 'stores the generator' do
      expect(schematic.generator).to eq(Fabrication::Generator::Base)
    end

    it 'stores the attributes' do
      expect(schematic.attributes.size).to eq(3)
    end
  end

  describe '#attribute' do
    it 'returns the requested attribute if it exists' do
      expect(schematic.attribute(:name).name).to eq(:name)
    end

    it 'returns nil if it does not exist' do
      expect(schematic.attribute(:not_there)).to be_nil
    end
  end

  describe '#attributes' do
    it 'loads the fabricator body' do
      schematic.attributes = nil
      allow(schematic).to receive(:load_body)
      expect(schematic.attributes).to eq([])
      expect(schematic).to have_received(:load_body)
    end
  end

  describe '#callbacks' do
    it 'loads the fabricator body' do
      schematic.callbacks = nil
      allow(schematic).to receive(:load_body)
      expect(schematic.callbacks).to eq({})
      expect(schematic).to have_received(:load_body)
    end
  end

  describe '#fabricate' do
    it 'generates a new instance' do
      expect(schematic.fabricate).to be_kind_of(OpenStruct)
    end
  end

  describe '#to_attributes' do
    let(:hash) { schematic.to_attributes }

    it "generates a hash with the object's attributes" do
      expect(hash).to be_kind_of(Hash)
    end

    it 'has the correct attributes' do
      expect(hash.size).to eq(3)
      expect(hash[:name]).to eq('Orgasmo')
      expect(hash[:something]).to eq('hi!')
      expect(hash[:another_thing]).to eq(25)
    end
  end

  describe '#merge' do
    context 'without inheritance' do
      let(:merged_schematic) { schematic.merge }

      it 'makes a new schematic' do
        expect(schematic).not_to eq(merged_schematic)
      end

      it "stored 'name' correctly" do
        attribute = merged_schematic.attribute(:name)
        expect(attribute.name).to eq(:name)
        expect(attribute.params).to eq({})
        expect(attribute.value).to eq('Orgasmo')
      end

      it "stored 'something' correctly" do
        attribute = merged_schematic.attribute(:something)
        expect(attribute.name).to eq(:something)
        expect(attribute.params).to eq({ param: 2 })
        expect(attribute.value).to be_a(Proc)
        expect(attribute.value.call).to eq('hi!')
      end

      it "stored 'another_thing' correctly" do
        attribute = merged_schematic.attribute(:another_thing)
        expect(attribute.name).to eq(:another_thing)
        expect(attribute.params).to eq({})
        expect(attribute.value).to be_a(Proc)
        expect(attribute.value.call).to eq(25)
      end
    end

    context 'with inheritance' do
      let(:merged_schematic) do
        schematic.merge do
          name { 'Willis' }
          something 'Else!'
          another_thing(thats_what: 'she_said') { 'Boo-ya!' }
        end
      end

      it 'makes a new schematic' do
        expect(schematic).not_to eq(merged_schematic)
      end

      it "stored 'name' correctly" do
        attribute = merged_schematic.attribute(:name)
        expect(attribute.name).to eq(:name)
        expect(attribute.params).to eq({})
        expect(attribute.value).to be_a(Proc)
        expect(attribute.value.call).to eq('Willis')
      end

      it "stored 'something' correctly" do
        attribute = merged_schematic.attribute(:something)
        expect(attribute.name).to eq(:something)
        expect(attribute.params).to eq({})
        expect(attribute.value).to eq('Else!')
      end

      it "stored 'another_thing' correctly" do
        attribute = merged_schematic.attribute(:another_thing)
        expect(attribute.name).to eq(:another_thing)
        expect(attribute.params).to eq({ thats_what: 'she_said' })
        expect(attribute.value).to be_a(Proc)
        expect(attribute.value.call).to eq('Boo-ya!')
      end
    end
  end

  describe '#on_init' do
    let(:init_block) { -> {} }
    let(:init_schematic) do
      block = init_block
      described_class.new('OpenStruct') do
        on_init(&block)
      end
    end

    it 'stores the on_init callback' do
      expect(init_schematic.callbacks[:on_init]).to eq(init_block)
    end

    context 'with inheritance' do
      let(:child_block) { -> {} }
      let(:child_schematic) do
        block = child_block
        init_schematic.merge do
          on_init(&block)
        end
      end

      it 'overwrites the on_init callback' do
        expect(child_schematic.callbacks[:on_init]).to eq(child_block)
      end
    end
  end

  describe '#initialize_with' do
    let(:init_block) { -> {} }
    let(:init_schematic) do
      block = init_block
      described_class.new('OpenStruct') do
        initialize_with(&block)
      end
    end

    it 'stores the initialize_with callback' do
      expect(init_schematic.callbacks[:initialize_with]).to eq(init_block)
    end

    context 'with inheritance' do
      let(:child_block) { -> {} }
      let(:child_schematic) do
        block = child_block
        init_schematic.merge do
          initialize_with(&block)
        end
      end

      it 'overwrites the initialize_with callback' do
        expect(child_schematic.callbacks[:initialize_with]).to eq(child_block)
      end
    end
  end

  describe '#transient' do
    let(:definition) do
      described_class.new('OpenStruct') do
        transient :one, two: 'with a default value', three: 200
      end
    end

    it 'stores the attributes as transient' do
      expect(definition.attributes.map(&:transient?)).to eq([true, true, true])
    end

    it 'accept default value' do
      expect(definition.attributes[1].name).to eq(:two)
      expect(definition.attributes[1].value).to eq('with a default value')
      expect(definition.attributes[2].name).to eq(:three)
      expect(definition.attributes[2].value).to eq(200)
    end
  end

  context 'when overriding' do
    it 'symbolizes attribute keys' do
      expect(Fabricate.build(:parent_ruby_object, 'string_field' => 'valid').string_field).to eq 'valid'
    end
  end

  describe '#sorted_attributes' do
    subject { definition.sorted_attributes.map(&:name) }

    let(:definition) do
      described_class.new('OpenStruct') do
        three { nil }
        one ''
        transient :two
      end
    end

    it { is_expected.to eq(%i[one two three]) }
  end

  describe '#klass' do
    subject { schematic.klass }

    it { is_expected.to be OpenStruct }
  end
end
