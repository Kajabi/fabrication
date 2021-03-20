require 'spec_helper'

describe Fabrication::Cucumber::StepFabricator do
  let(:name) { 'dogs' }

  describe '#klass' do
    context 'with a schematic for class "Boom"' do
      subject { described_class.new(name).klass }

      let(:fabricator_name) { :dog }

      before do
        allow(Fabricate).to receive(:schematic).with(fabricator_name).and_return(
          instance_double(
            'Fabrication::Schematic::Definition', klass: 'Boom'
          )
        )
      end

      it { is_expected.to eq('Boom') }

      context 'with a human name' do
        let(:name) { 'weiner dogs' }
        let(:fabricator_name) { :weiner_dog }

        it { is_expected.to eq('Boom') }
      end

      context 'with a titlecase human name' do
        let(:name) { 'Weiner Dog' }
        let(:fabricator_name) { :weiner_dog }

        it { is_expected.to eq('Boom') }
      end
    end
  end

  describe '#n' do
    let(:n) { 3 }
    let(:fabricator) { described_class.new(name) }

    it 'fabricates n times' do
      allow(Fabricate).to receive(:create).with(:dog, {})
      fabricator.n n
      expect(Fabricate).to have_received(:create).with(:dog, {}).exactly(n).times
    end

    it 'fabricates with attrs' do
      allow(Fabricate).to receive(:create).with(:dog, collar: 'red')
      fabricator.n n, collar: 'red'
      expect(Fabricate).to have_received(:create)
        .with(:dog, collar: 'red').at_least(1)
    end

    context 'with a plural subject' do
      let(:name) { 'dogs' }

      it 'remembers' do
        allow(Fabricate).to receive(:create).and_return('dog1', 'dog2', 'dog3')
        fabricator.n n
        expect(Fabrication::Cucumber::Fabrications[name]).to eq(%w[dog1 dog2 dog3])
      end
    end

    context 'with a singular subject' do
      let(:name) { 'dog' }

      it 'remembers' do
        allow(Fabricate).to receive(:create).and_return('dog1')
        fabricator.n 1
        expect(Fabrication::Cucumber::Fabrications[name]).to eq('dog1')
      end
    end
  end

  describe '#from_table' do
    it 'maps column names to attribute names' do
      table = instance_double('ASTable', hashes: [{ 'Favorite Color' => 'pink' }])
      allow(Fabricate).to receive(:create).with(:bear, favorite_color: 'pink')
      described_class.new('bears').from_table(table)
      expect(Fabricate).to have_received(:create).with(:bear, favorite_color: 'pink')
    end

    context 'with table transforms' do
      let(:table) { instance_double('ASTable', hashes: [{ 'some' => 'thing' }]) }

      before { allow(Fabricate).to receive(:create) }

      it 'applies transforms' do
        allow(Fabrication::Transform).to receive(:apply_to)
          .with('bears', { some: 'thing' }).and_return({})

        described_class.new('bears').from_table(table)

        expect(Fabrication::Transform).to have_received(:apply_to)
          .with('bears', { some: 'thing' })
      end
    end

    context 'with a plural subject' do
      let(:table) { instance_double('ASTable', hashes: hashes) }
      let(:hashes) do
        [{ 'some' => 'thing' },
         { 'some' => 'panother' }]
      end

      it 'fabricates with each rows attributes' do
        allow(Fabricate).to receive(:create).with(:dog, { some: 'thing' })
        allow(Fabricate).to receive(:create).with(:dog, { some: 'panother' })
        described_class.new(name).from_table(table)
        expect(Fabricate).to have_received(:create).with(:dog, { some: 'thing' })
        expect(Fabricate).to have_received(:create).with(:dog, { some: 'panother' })
      end

      it 'remembers' do
        allow(Fabricate).to receive(:create).and_return('dog1', 'dog2')
        described_class.new(name).from_table(table)
        expect(Fabrication::Cucumber::Fabrications[name]).to eq(%w[dog1 dog2])
      end
    end

    context 'when singular' do
      let(:name) { 'dog' }
      let(:table) { instance_double('ASTable', rows_hash: rows_hash) }
      let(:rows_hash) do
        { 'some' => 'thing' }
      end

      it 'fabricates with each row as an attribute' do
        allow(Fabricate).to receive(:create).with(:dog, { some: 'thing' })
        described_class.new(name).from_table(table)
        expect(Fabricate).to have_received(:create).with(:dog, { some: 'thing' })
      end

      it 'remembers' do
        allow(Fabricate).to receive(:create).and_return('dog1')
        described_class.new(name).from_table(table)
        expect(Fabrication::Cucumber::Fabrications[name]).to eq('dog1')
      end
    end
  end
end
