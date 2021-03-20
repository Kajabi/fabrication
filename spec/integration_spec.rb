require 'spec_helper'

CustomInitializer = Struct.new(:field1, :field2)

class Widget < Object; end

shared_examples 'something fabricatable' do
  let(:fabricated_object) { Fabricate(fabricator_name, placeholder: 'dynamic content') }

  it 'merges provided params with defaults from the defined fabicator' do
    expect(fabricated_object.dynamic_field).to eq('dynamic content')
    expect(fabricated_object.nil_field).to be_nil
    expect(fabricated_object.number_field).to eq(5)
    expect(fabricated_object.string_field).to eq('content')
    expect(fabricated_object.false_field).to eq(false)
  end

  it 'fires model callbacks' do
    expect(fabricated_object.before_validation_value).to eq(1)
    expect(fabricated_object.before_save_value).to eq(11)
  end

  context 'when overriding at fabricate time' do
    let(:fabricated_object) do
      Fabricate(
        "#{fabricator_name}_with_children",
        string_field: 'new content',
        number_field: 10,
        nil_field: nil,
        placeholder: 'is not invoked'
      ) do
        dynamic_field { 'new dynamic content' }
      end
    end

    it 'uses both an attributes hash and block overrides' do
      expect(fabricated_object.dynamic_field).to eq('new dynamic content')
      expect(fabricated_object.nil_field).to be_nil
      expect(fabricated_object.number_field).to eq(10)
      expect(fabricated_object.string_field).to eq('new content')
    end

    context 'with child collections' do
      let(:child_collection) { fabricated_object.send(collection_field) }

      it 'creates the children' do
        expect(child_collection.size).to eq(2)
        expect(child_collection.first).to be_persisted
        expect(child_collection.first.number_field).to eq(10)
        expect(child_collection.last).to be_persisted
        expect(child_collection.last.number_field).to eq(10)
      end
    end
  end

  context 'with state of the object' do
    it 'generates a fresh object every time' do
      expect(Fabricate(fabricator_name)).not_to eq(fabricated_object)
    end

    it 'saves the object' do
      expect(fabricated_object).to be_persisted
    end
  end

  context 'with transient attributes' do
    it 'does not apply the transients to the object' do
      expect(fabricated_object).not_to respond_to(:placeholder)
    end

    it 'exposes the transient value to other processing' do
      expect(fabricated_object.extra_fields).to eq({ transient_value: 'dynamic content' })
    end
  end

  describe '#build' do
    subject { Fabricate.build("#{fabricator_name}_with_children") }

    it { should_not be_persisted }

    it 'cascades to child records' do
      subject.send(collection_field).each do |o|
        expect(o).not_to be_persisted
      end
    end
  end

  describe '#attributes_for' do
    subject { Fabricate.attributes_for(fabricator_name) }

    it { should be_kind_of(Fabrication::Support.hash_class) }

    it 'serializes the attributes' do
      expect(subject).to include(
        { dynamic_field: nil, nil_field: nil, number_field: 5, string_field: 'content' }
      )
    end
  end

  context 'with belongs_to associations' do
    subject { Fabricate("#{Fabrication::Support.singularize(collection_field.to_s)}_with_parent") }

    it 'sets the parent association' do
      expect(subject.send(fabricator_name)).not_to be_nil
    end

    it 'sets the id of the associated object' do
      expect(subject.send("#{fabricator_name}_id")).to eq(subject.send(fabricator_name).id)
    end
  end
end

describe Fabrication do
  context 'with plain old ruby objects' do
    let(:fabricator_name) { :parent_ruby_object }
    let(:collection_field) { :child_ruby_objects }

    it_behaves_like 'something fabricatable'
  end

  context 'with active_record models', depends_on: :active_record do
    let(:fabricator_name) { :parent_active_record_model }
    let(:collection_field) { :child_active_record_models }

    it_behaves_like 'something fabricatable'

    context 'with associations in attributes_for' do
      let(:attributes_for) do
        Fabricate.attributes_for(:child_active_record_model, parent_active_record_model: parent_model)
      end

      let(:parent_model) { Fabricate(:parent_active_record_model) }

      it 'serializes the belongs_to as an id' do
        expect(attributes_for).to include({ parent_active_record_model_id: parent_model.id })
      end
    end

    context 'with association proxies' do
      subject { parent_model.child_active_record_models.build }

      let(:parent_model) { Fabricate(:parent_active_record_model_with_children) }

      it { should be_kind_of(ChildActiveRecordModel) }
    end
  end

  context 'with data_mapper models', depends_on: :data_mapper do
    let(:fabricator_name) { :parent_data_mapper_model }
    let(:collection_field) { :child_data_mapper_models }

    it_behaves_like 'something fabricatable'

    context 'with associations in attributes_for' do
      let(:attributes_for) do
        Fabricate.attributes_for(
          :child_data_mapper_model, parent_data_mapper_model: parent_model
        )
      end

      let(:parent_model) { Fabricate(:parent_data_mapper_model) }

      it 'serializes the belongs_to as an id' do
        expect(attributes_for).to include({ parent_data_mapper_model_id: parent_model.id })
      end
    end
  end

  context 'with referenced mongoid documents', depends_on: :mongoid do
    let(:fabricator_name) { :parent_mongoid_document }
    let(:collection_field) { :referenced_mongoid_documents }

    it_behaves_like 'something fabricatable'
  end

  context 'with embedded mongoid documents', depends_on: :mongoid do
    let(:fabricator_name) { :parent_mongoid_document }
    let(:collection_field) { :embedded_mongoid_documents }

    it_behaves_like 'something fabricatable'
  end

  context 'with sequel models', depends_on: :sequel do
    let(:fabricator_name) { :parent_sequel_model }
    let(:collection_field) { :child_sequel_models }

    it_behaves_like 'something fabricatable'

    context 'with class table inheritance' do
      before do
        clear_sequel_db
        Fabricate(:inherited_sequel_model)
        Fabricate(:parent_sequel_model)
        Fabricate(:inherited_sequel_model)
      end

      it 'generates the right number of objects' do
        expect(ParentSequelModel.count).to eq(3)
        expect(InheritedSequelModel.count).to eq(2)
      end
    end
  end

  context 'when the class requires a constructor' do
    let(:fabricated_object) do
      Fabricate(:custom_initializer) do
        on_init { init_with('value1', 'value2') }
      end
    end

    before do
      Fabricator(:custom_initializer) unless described_class.manager[:custom_initializer]
    end

    it 'uses the custom initializer' do
      expect(fabricated_object.field1).to eq('value1')
      expect(fabricated_object.field2).to eq('value2')
    end
  end

  context 'with the generation parameter' do
    let(:parent_ruby_object) do
      Fabricate(:parent_ruby_object, string_field: 'Paul') do
        placeholder { |attrs| "#{attrs[:string_field]}#{attrs[:number_field]}" }
        number_field 50
      end
    end

    it 'evaluates the fields in order of declaration' do
      expect(parent_ruby_object.string_field).to eq('Paul')
    end
  end

  context 'with a field named the same as an Object method' do
    let(:fabricated_object) { Fabricate(:predefined_namespaced_class, display: 'working') }

    it 'works with field names that are also on Object' do
      expect(fabricated_object.display).to eq('working')
    end
  end

  context 'with multiple instances' do
    let!(:parent_ruby_object1) { Fabricate(:parent_ruby_object, string_field: 'Jane') }
    let!(:parent_ruby_object2) { Fabricate(:parent_ruby_object, string_field: 'John') }

    it 'parent_ruby_object1 has the correct string field' do
      expect(parent_ruby_object1.string_field).to eq('Jane')
    end

    it 'parent_ruby_object2 has the correct string field' do
      expect(parent_ruby_object2.string_field).to eq('John')
    end

    it 'they have different extra fields' do
      expect(parent_ruby_object1.extra_fields).not_to equal(parent_ruby_object2.extra_fields)
    end
  end

  context 'with a specified class name' do
    let(:fabricated_object) { Fabricate(:custom_parent_ruby_object) }

    before do
      Fabricator(:custom_parent_ruby_object, class_name: :parent_ruby_object) do
        string_field 'different'
      end
    end

    it 'uses the specified class name' do
      expect(fabricated_object).to be_a(ParentRubyObject)
      expect(fabricated_object.string_field).to eq('different')
    end
  end

  context 'with for namespaced classes' do
    it 'correctly identifies the namespace' do
      fabricated_object = Fabricate('namespaced_classes/ruby_object', name: 'working')
      expect(fabricated_object).to be_a(NamespacedClasses::RubyObject)
      expect(fabricated_object.name).to eq('working')
    end

    context 'with a descendant from namespaced class' do
      let(:fabricated_object) { Fabricate(:predefined_namespaced_class) }

      it 'uses the predefined namespace' do
        expect(fabricated_object.name).to eq('aaa')
        expect(fabricated_object).to be_a(NamespacedClasses::RubyObject)
      end
    end
  end

  context 'with a mongoid document', depends_on: :mongoid do
    it 'sets dynamic fields' do
      expect(Fabricate(:parent_mongoid_document, mongoid_dynamic_field: 50).mongoid_dynamic_field).to eq 50
    end

    it 'sets lazy dynamic fields' do
      expect(Fabricate(:parent_mongoid_document) { lazy_dynamic_field 'foo' }.lazy_dynamic_field).to eq 'foo'
    end
  end

  context 'with multiple callbacks' do
    let(:fabricated_object) { Fabricate(:multiple_callbacks) }

    before do
      unless described_class.manager[:multiple_callbacks]
        Fabricator(:multiple_callbacks, from: OpenStruct) do
          before_validation { |o| o.callback1 = 'value1' }
          before_validation { |o| o.callback2 = 'value2' }
        end
      end
    end

    it 'executes the callbacks' do
      expect(fabricated_object.callback1).to eq('value1')
      expect(fabricated_object.callback2).to eq('value2')
    end
  end

  context 'with multiple, inherited callbacks' do
    let(:fabricated_object) { Fabricate(:multiple_inherited_callbacks) }

    before do
      unless described_class.manager[:multiple_inherited_callbacks]
        Fabricator(:multiple_inherited_callbacks, from: :multiple_callbacks) do
          before_validation { |o| o.callback3 = o.callback1 + o.callback2 }
        end
      end
    end

    it 'executes all all callbacks' do
      expect(fabricated_object.callback3).to eq('value1value2')
    end
  end

  describe '.clear_definitions' do
    before { described_class.clear_definitions }

    after { described_class.manager.load_definitions }

    it 'clears the definitions in the manager' do
      expect(described_class.manager).to be_empty
    end
  end

  context 'when defining a fabricator twice' do
    it 'throws an error' do
      expect { Fabricator(:parent_ruby_object) }.to raise_error(Fabrication::DuplicateFabricatorError)
    end
  end

  context "when fabricating class that doesn't exist" do
    before { Fabricator(:class_that_does_not_exist) }

    it 'throws an error' do
      expect { Fabricate(:class_that_does_not_exist) }.to raise_error(Fabrication::UnfabricatableError)
    end
  end

  context 'when generating from a non-existant fabricator' do
    it 'throws an error' do
      expect { Fabricate(:misspelled_fabricator_name) }.to raise_error(Fabrication::UnknownFabricatorError)
    end
  end

  context 'when defining a fabricator' do
    context 'without a block' do
      before do
        Fabricator(:widget) unless described_class.manager[:custom_initializer]
      end

      it 'works fine' do
        expect(Fabricate(:widget)).not_to be_nil
      end
    end
  end

  describe 'Fabricate with a sequence' do
    let(:fabricated_object) { Fabricate(:sequencer) }

    it 'starts a zero' do
      expect(fabricated_object.simple_iterator).to eq(0)
    end

    it 'increments from a starting point when provided' do
      expect(fabricated_object.param_iterator).to eq(10)
    end

    it 'passes the right number to blocks' do
      expect(fabricated_object.block_iterator).to eq('block2')
    end

    context 'with a namespace' do
      let(:fabricated_object) { Fabricate('Sequencer::Namespaced') }

      it 'creates the correct object' do
        expect(fabricated_object).to be_a(Sequencer::Namespaced)
        expect(fabricated_object.iterator).to eq(0)
      end
    end
  end

  describe 'Fabricating while initializing' do
    before { described_class.manager.preinitialize }

    after { described_class.manager.freeze }

    it 'throws an error' do
      expect { Fabricate(:an_error) }.to raise_error(Fabrication::MisplacedFabricateError)
    end
  end

  describe 'using an actual class in options' do
    let(:fabricated_object) { Fabricate(:actual_class) }

    context 'with from' do
      before do
        Fabricator(:actual_class, from: OpenStruct) do
          name 'Hashrocket'
        end
      end

      after { described_class.clear_definitions }

      it 'uses the provided class' do
        expect(fabricated_object.name).to eq('Hashrocket')
        expect(fabricated_object).to be_a(OpenStruct)
      end
    end

    context 'with class_name' do
      before do
        Fabricator(:actual_class, class_name: OpenStruct) do
          name 'Hashrocket'
        end
      end

      after { described_class.clear_definitions }

      it 'uses the provided class' do
        expect(fabricated_object.name).to eq('Hashrocket')
        expect(fabricated_object).to be_a(OpenStruct)
      end
    end
  end

  describe 'accidentally an infinite recursion' do
    context 'with a single self-referencing fabricator' do
      before do
        Fabricator(:infinite_recursor, class_name: :child_ruby_object) do
          parent_ruby_object { Fabricate(:infinite_recursor) }
        end
      end

      it 'throws a meaningful error' do
        expect { Fabricate(:infinite_recursor) }.to raise_error(
          Fabrication::InfiniteRecursionError,
          'You appear to have infinite recursion with the `infinite_recursor` fabricator'
        )
      end
    end

    context 'with a parent-child recursive scenario' do
      before do
        Fabricator(:parent_recursor, class_name: :parent_ruby_object) do
          child_ruby_objects(count: 1, fabricator: :child_recursor)
        end

        Fabricator(:child_recursor, class_name: :child_ruby_object) do
          parent_ruby_object { Fabricate(:parent_recursor) }
        end
      end

      it 'throws a meaningful error' do
        expect { Fabricate(:parent_recursor) }.to raise_error(
          Fabrication::InfiniteRecursionError,
          'You appear to have infinite recursion with the `parent_recursor` fabricator'
        )
      end
    end
  end

  describe 'using the rand option' do
    before { described_class.clear_definitions }

    context 'with an integer' do
      let!(:parent) do
        Fabricate(:parent_ruby_object) do
          child_ruby_objects(rand: 3)
        end
      end

      it 'generates between 1 and 3 child_ruby_objects' do
        expect(parent.child_ruby_objects.length).to be >= 1
        expect(parent.child_ruby_objects.length).to be <= 3
      end
    end

    context 'with a range' do
      let!(:parent) do
        Fabricate(:parent_ruby_object) do
          child_ruby_objects(rand: 3..5)
        end
      end

      it 'generates between 3 and 5 child_ruby_objects' do
        expect(parent.child_ruby_objects.length).to be >= 3
        expect(parent.child_ruby_objects.length).to be <= 5
      end
    end
  end
end
