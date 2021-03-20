require 'spec_helper'

module Family
  def self.const_missing(_name)
    raise NameError, 'original message'
  end
end

describe Fabrication::Support do
  describe '.class_for' do
    context 'with a class that exists' do
      it 'returns the class for a class' do
        expect(described_class.class_for(Object)).to eq(Object)
      end

      it 'returns the class for a class name string' do
        expect(described_class.class_for('object')).to eq(Object)
      end

      it 'returns the class for a class name symbol' do
        expect(described_class.class_for(:object)).to eq(Object)
      end
    end

    context "with a class that doesn't exist" do
      it 'returns nil for a class name string' do
        expect { described_class.class_for('your_mom') }
          .to raise_error(Fabrication::UnfabricatableError)
      end

      it 'returns nil for a class name symbol' do
        expect { described_class.class_for(:your_mom) }
          .to raise_error(Fabrication::UnfabricatableError)
      end
    end

    context 'and custom const_missing is defined' do
      it 'raises an exception with the message from the original exception' do
        expect { described_class.class_for('Family::Mom') }
          .to raise_error(Fabrication::UnfabricatableError, /original message/)
      end
    end
  end

  describe '.hash_class', depends_on: :active_support do
    subject { described_class.hash_class }

    before do
      pending unless defined?(HashWithIndifferentAccess)
    end

    context 'with HashWithIndifferentAccess defined' do
      it { should == HashWithIndifferentAccess }
    end

    # rubocop:disable Lint/ConstantDefinitionInBlock, RSpec/LeakyConstantDeclaration
    context 'without HashWithIndifferentAccess defined' do
      before do
        TempHashWithIndifferentAccess = HashWithIndifferentAccess
        described_class.instance_variable_set('@hash_class', nil)
        Object.send(:remove_const, :HashWithIndifferentAccess)
      end

      after do
        described_class.instance_variable_set('@hash_class', nil)
        HashWithIndifferentAccess = TempHashWithIndifferentAccess
      end

      it { should == Hash }
    end
    # rubocop:enable Lint/ConstantDefinitionInBlock, RSpec/LeakyConstantDeclaration
  end
end
