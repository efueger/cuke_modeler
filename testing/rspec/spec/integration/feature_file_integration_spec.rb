require "#{File.dirname(__FILE__)}/../spec_helper"


describe 'FeatureFile, Integration' do

  let(:clazz) { CukeModeler::FeatureFile }


  describe 'common behavior' do

    it_should_behave_like 'a model, integration'

  end

  describe 'unique behavior' do

    it 'stores the original data generated by the parsing adapter', :gherkin4 => true do
      path = "#{@default_file_directory}/#{@default_feature_file_name}"
      File.open(path, "w") { |file| file.puts "#{@feature_keyword}: test feature" }

      feature_file = clazz.new(path)
      data = feature_file.parsing_data

      expect(data.keys).to match_array([:type, :feature, :comments])
      expect(data[:type]).to eq(:GherkinDocument)
    end

    it 'stores the original data generated by the parsing adapter', :gherkin3 => true do
      path = "#{@default_file_directory}/#{@default_feature_file_name}"
      File.open(path, "w") { |file| file.puts "#{@feature_keyword}: test feature" }

      feature_file = clazz.new(path)
      data = feature_file.parsing_data

      # There is no parsing data stored above the feature level for gherkin 3.x
      expect(data).to be_nil
    end

    it 'stores the original data generated by the parsing adapter', :gherkin2 => true do
      path = "#{@default_file_directory}/#{@default_feature_file_name}"
      File.open(path, "w") { |file| file.puts "#{@feature_keyword}: test feature" }

      feature_file = clazz.new(path)
      data = feature_file.parsing_data

      # There is no parsing data stored above the feature level for gherkin 2.x
      expect(data).to eq([])
    end

    it 'provides its own filename when being parsed' do
      path = "#{@default_file_directory}/#{@default_feature_file_name}"
      File.open(path, "w") { |file| file.puts 'bad feature text' }

      expect { clazz.new(path) }.to raise_error(/'#{path}'/)
    end

    it 'cannot model a non-existent feature file' do
      path = "#{@default_file_directory}/missing_file.txt"

      expect { clazz.new(path) }.to raise_error(ArgumentError)
    end


    describe 'model population' do

      let(:source_text) { "#{@feature_keyword}: Test feature" }
      let(:feature_file_path) { "#{@default_file_directory}/#{@default_feature_file_name}" }
      let(:feature_file) { clazz.new(feature_file_path) }

      before(:each) do
        File.open(feature_file_path, "w") { |file| file.puts source_text }
      end

      it "models the feature file's name" do
        expect(feature_file.name).to eq(@default_feature_file_name)
      end

      it "models the feature file's path" do
        expect(feature_file.path).to eq(feature_file_path)
      end

      it "models the feature file's feature" do
        feature_name = feature_file.feature.name

        expect(feature_name).to eq('Test feature')
      end

      it "models the feature file's comments" do
        source_text = "# feature comment
                       @tag1 @tag2 @tag3
                       #{@feature_keyword}: A feature with everything it could have

                       Including a description
                       and then some.

                         # background comment
                         #{@background_keyword}:

                         Background
                         description

                           #{@step_keyword} a step
                           # table comment
                             | value1 |
                             # table row comment
                             | value2 |
                           #{@step_keyword} another step

                         # scenario comment
                         @scenario_tag
                         #{@scenario_keyword}:

                         Scenario
                         description

                         #{@step_keyword} a step
                         #{@step_keyword} another step
                           \"\"\"
                           some text
                           \"\"\"

                         # outline comment
                         @outline_tag
                         #{@outline_keyword}:

                         Outline
                         description

                           # step comment
                           #{@step_keyword} a step
                           # table comment
                             | value2 |
                           # step comment
                           #{@step_keyword} another step
                             # doc string comment
                             \"\"\"
                             some text
                             \"\"\"

                         # example comment
                         @example_tag
                         #{@example_keyword}:

                         Example
                         description

                           # row comment
                           | param |
                           | value |
                       # final comment"

        File.open(feature_file_path, "w") { |file| file.puts source_text }

        feature_file = clazz.new(feature_file_path)
        comments = feature_file.comments.collect { |comment| comment.text }


        expected_comments = ['# feature comment',
                             '# background comment',
                             '# table comment',
                             '# table row comment',
                             '# scenario comment',
                             '# outline comment',
                             '# step comment',
                             '# table comment',
                             '# step comment',
                             '# doc string comment',
                             '# example comment',
                             '# row comment']

        # gherkin 2.x 'loses' comments that are not followed by some element
        expected_comments << '# final comment' unless Gem.loaded_specs['gherkin'].version.version[/^2\./]


        expect(comments).to match_array(expected_comments)
      end


      # gherkin 3.x does not accept empty feature files
      context 'an empty feature file', :gherkin3 => false do

        let(:source_text) { '' }
        let(:feature_file_path) { "#{@default_file_directory}/#{@default_feature_file_name}" }
        let(:feature_file) { clazz.new(feature_file_path) }

        before(:each) do
          File.open(feature_file_path, "w") { |file| file.puts source_text }
        end


        it "models the feature file's feature" do
          expect(feature_file.feature).to be_nil
        end

      end

    end

    it 'properly sets its child models' do
      file_path = "#{@default_file_directory}/#{@default_feature_file_name}"

      File.open(file_path, "w") { |file|
        file.puts("#{@feature_keyword}: Test feature")
      }

      file = clazz.new(file_path)
      feature = file.feature

      expect(feature.parent_model).to equal(file)
    end


    describe 'getting ancestors' do

      before(:each) do
        file_path = "#{@default_file_directory}/feature_file_test_file.feature"
        File.open(file_path, 'w') { |file| file.write("#{@feature_keyword}: Test feature") }
      end

      let(:directory) { CukeModeler::Directory.new(@default_file_directory) }
      let(:feature_file) { directory.feature_files.first }


      it 'can get its directory' do
        ancestor = feature_file.get_ancestor(:directory)

        expect(ancestor).to equal(directory)
      end

      it 'returns nil if it does not have the requested type of ancestor' do
        ancestor = feature_file.get_ancestor(:example)

        expect(ancestor).to be_nil
      end

    end


    describe 'feature file output' do

      context 'from source text' do

        let(:source_text) { "#{@feature_keyword}: Test feature" }
        let(:feature_file_path) { "#{@default_file_directory}/#{@default_feature_file_name}" }
        let(:feature_file) { clazz.new(feature_file_path) }

        before(:each) do
          File.open(feature_file_path, "w") { |file| file.puts source_text }
        end


        it 'can output a feature file' do
          feature_file_output = feature_file.to_s

          expect(feature_file_output).to eq(feature_file_path)
        end

      end

      it 'can be remade from its own output' do
        path = "#{@default_file_directory}/#{@default_feature_file_name}"
        File.open(path, "w") { |file| file.puts "#{@feature_keyword}:" }

        source = path
        feature_file = clazz.new(source)

        feature_file_output = feature_file.to_s
        remade_feature_file_output = clazz.new(feature_file_output).to_s

        expect(remade_feature_file_output).to eq(feature_file_output)
      end

    end

  end

end
