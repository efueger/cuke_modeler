require 'spec_helper'

SimpleCov.command_name('DocString') unless RUBY_VERSION.to_s < '1.9.0'

describe 'DocString, Integration' do

  let(:clazz) { CukeModeler::DocString }


  describe 'getting stuff' do

    before(:each) do
      source = ['Feature: Test feature',
                '',
                '  Scenario: Test test',
                '    * a big step:',
                '  """',
                '  a',
                '  doc',
                '  string',
                '  """']
      source = source.join("\n")

      file_path = "#{@default_file_directory}/doc_string_test_file.feature"
      File.open(file_path, 'w') { |file| file.write(source) }
    end

    let(:directory) { CukeModeler::Directory.new(@default_file_directory) }
    let(:doc_string) { directory.feature_files.first.features.first.tests.first.steps.first.block }


    it 'can get its directory' do
      gotten_directory = doc_string.get_ancestor(:directory)

      expect(gotten_directory).to equal(directory)
    end

    it 'can get its feature file' do
      gotten_feature_file = doc_string.get_ancestor(:feature_file)

      expect(gotten_feature_file).to equal(directory.feature_files.first)
    end

    it 'can get its feature' do
      gotten_feature = doc_string.get_ancestor(:feature)

      expect(gotten_feature).to equal(directory.feature_files.first.features.first)
    end

    it 'can get its test' do
      gotten_test = doc_string.get_ancestor(:test)

      expect(gotten_test).to equal(directory.feature_files.first.features.first.tests.first)
    end

    it 'can get its step' do
      gotten_step = doc_string.get_ancestor(:step)

      expect(gotten_step).to equal(directory.feature_files.first.features.first.tests.first.steps.first)
    end

    it 'returns nil if it does not have the requested type of ancestor' do
      gotten_example = doc_string.get_ancestor(:example)

      expect(gotten_example).to be_nil
    end

  end
end
