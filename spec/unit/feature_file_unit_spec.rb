require 'spec_helper'

SimpleCov.command_name('FeatureFile') unless RUBY_VERSION.to_s < '1.9.0'

describe 'FeatureFile, Unit' do

  let(:clazz) { CukeModeler::FeatureFile }
  let(:feature_file) { clazz.new }


  describe 'common behavior' do

    it_should_behave_like 'a modeled element'

  end


  describe 'unique behavior' do

    it 'has a path' do
      expect(feature_file).to respond_to(:path)
    end

    it 'can change its path' do
      expect(feature_file).to respond_to(:path=)

      feature_file.path = :some_path
      feature_file.path.should == :some_path
      feature_file.path = :some_other_path
      feature_file.path.should == :some_other_path
    end

    it 'has a feature' do
      expect(feature_file).to respond_to(:feature)
    end

    it 'can change its feature' do
      expect(feature_file).to respond_to(:feature=)

      feature_file.feature = :some_features
      expect(feature_file.feature).to eq(:some_features)
      feature_file.feature = :some_other_features
      expect(feature_file.feature).to eq(:some_other_features)
    end


    describe 'abstract instantiation' do

      context 'a new feature file object' do

        let(:feature_file) { clazz.new }


        it 'starts with no path' do
          expect(feature_file.path).to be_nil
        end

        it 'starts with no name' do
          expect(feature_file.name).to be_nil
        end

        it 'starts with no feature' do
          expect(feature_file.feature).to be_nil
        end

      end

    end

    it 'contains a feature' do
      feature = :a_feature
      everything = [feature]

      feature_file.feature = feature

      expect(feature_file.children).to match_array(everything)
    end


    describe 'feature file output edge cases' do

      it 'is a String' do
        feature_file.to_s.should be_a(String)
      end


      context 'a new feature file object' do

        let(:feature_file) { clazz.new }


        it 'can output an empty feature file' do
          expect { feature_file.to_s }.to_not raise_error
        end

      end

    end

  end

end
