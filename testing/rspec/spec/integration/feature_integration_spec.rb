require "#{File.dirname(__FILE__)}/../spec_helper"


describe 'Feature, Integration' do

  let(:clazz) { CukeModeler::Feature }
  let(:feature) { clazz.new }


  describe 'common behavior' do

    it_should_behave_like 'a model, integration'

  end

  describe 'unique behavior' do

    it 'can be instantiated with the minimum viable Gherkin' do
      source = "#{@feature_keyword}:"

      expect { clazz.new(source) }.to_not raise_error
    end

    it 'can parse text that uses a non-default dialect' do
      original_dialect = CukeModeler::Parsing.dialect
      CukeModeler::Parsing.dialect = 'en-au'

      begin
        source_text = "# language: en-au
                       Pretty much: Feature name"

        expect { @model = clazz.new(source_text) }.to_not raise_error

        # Sanity check in case modeling failed in a non-explosive manner
        expect(@model.name).to eq('Feature name')
      ensure
        # Making sure that our changes don't escape a test and ruin the rest of the suite
        CukeModeler::Parsing.dialect = original_dialect
      end
    end

    it 'provides a descriptive filename when being parsed from stand alone text' do
      source = 'bad feature text'

      expect { clazz.new(source) }.to raise_error(/'cuke_modeler_stand_alone_feature\.feature'/)
    end

    it 'properly sets its child models' do
      source = "@a_tag
                #{@feature_keyword}: Test feature
                  #{@background_keyword}: Test background
                  #{@scenario_keyword}: Test scenario
                  #{@outline_keyword}: Test outline
                  #{@example_keyword}: Test Examples
                    | param |
                    | value |"


      feature = clazz.new(source)
      background = feature.background
      scenario = feature.tests[0]
      outline = feature.tests[1]
      tag = feature.tags[0]


      expect(outline.parent_model).to equal(feature)
      expect(scenario.parent_model).to equal(feature)
      expect(background.parent_model).to equal(feature)
      expect(tag.parent_model).to equal(feature)
    end

    it 'stores the original data generated by the parsing adapter', :gherkin4 => true do
      feature = clazz.new("@tag\n#{@feature_keyword}: test feature\ndescription\n#{@background_keyword}:\n#{@scenario_keyword}:")
      data = feature.parsing_data

      expect(data.keys).to match_array([:type, :tags, :location, :language, :keyword, :name, :children, :description])
      expect(data[:type]).to eq(:Feature)
    end

    it 'stores the original data generated by the parsing adapter', :gherkin3 => true do
      feature = clazz.new("@tag\n#{@feature_keyword}: test feature\ndescription\n#{@background_keyword}:\n#{@scenario_keyword}:")
      data = feature.parsing_data

      expect(data.keys).to match_array([:type, :tags, :location, :language, :keyword, :name, :scenarioDefinitions, :comments, :background, :description])
      expect(data[:type]).to eq(:Feature)
    end

    it 'stores the original data generated by the parsing adapter', :gherkin2 => true do
      feature = clazz.new("@tag\n#{@feature_keyword}: test feature\ndescription\n#{@background_keyword}:\n#{@scenario_keyword}:")
      data = feature.parsing_data

      expect(data.keys).to match_array(['keyword', 'name', 'line', 'description', 'id', 'uri', 'elements', 'tags'])
      expect(data['keyword']).to eq('Feature')
    end

    it 'trims whitespace from its source description' do
      source = ["#{@feature_keyword}:",
                '  ',
                '        description line 1',
                '',
                '   description line 2',
                '     description line 3               ',
                '',
                '',
                '',
                "  #{@scenario_keyword}:"]
      source = source.join("\n")

      feature = clazz.new(source)
      description = feature.description.split("\n", -1)

      expect(description).to eq(['     description line 1',
                                 '',
                                 'description line 2',
                                 '  description line 3'])
    end

    it 'can selectively access its scenarios and outlines' do
      scenarios = [CukeModeler::Scenario.new, CukeModeler::Scenario.new]
      outlines = [CukeModeler::Outline.new, CukeModeler::Outline.new]

      feature.tests = scenarios + outlines

      expect(feature.scenarios).to match_array(scenarios)
      expect(feature.outlines).to match_array(outlines)
    end


    describe 'model population' do

      context 'from source text' do

        it "models the feature's keyword" do
          source_text = "#{@feature_keyword}:"
          feature = CukeModeler::Feature.new(source_text)

          expect(feature.keyword).to eq(@feature_keyword)
        end

        it "models the feature's source line" do
          source_text = "#{@feature_keyword}:"
          feature = CukeModeler::Feature.new(source_text)

          expect(feature.source_line).to eq(1)
        end


        context 'a filled feature' do

          let(:source_text) { "@tag_1 @tag_2
                               #{@feature_keyword}: Feature Foo

                                   Some feature description.

                                 Some more.
                                     And some more.

                                 #{@background_keyword}: The background
                                   #{@step_keyword} some setup step

                                 #{@scenario_keyword}: Scenario 1
                                   #{@step_keyword} a step

                                 #{@outline_keyword}: Outline 1
                                   #{@step_keyword} a step
                                 #{@example_keyword}:
                                   | param |
                                   | value |

                                 #{@scenario_keyword}: Scenario 2
                                   #{@step_keyword} a step

                                 #{@outline_keyword}: Outline 2
                                   #{@step_keyword} a step
                                 #{@example_keyword}:
                                   | param |
                                   | value |" }
          let(:feature) { clazz.new(source_text) }


          it "models the feature's name" do
            expect(feature.name).to eq('Feature Foo')
          end

          it "models the feature's description" do
            description = feature.description.split("\n", -1)

            expect(description).to eq(['  Some feature description.',
                                       '',
                                       'Some more.',
                                       '    And some more.'])
          end

          it "models the feature's background" do
            expect(feature.background.name).to eq('The background')
          end

          it "models the feature's scenarios" do
            scenario_names = feature.scenarios.collect { |scenario| scenario.name }

            expect(scenario_names).to eq(['Scenario 1', 'Scenario 2'])
          end

          it "models the feature's outlines" do
            outline_names = feature.outlines.collect { |outline| outline.name }

            expect(outline_names).to eq(['Outline 1', 'Outline 2'])
          end

          it "models the feature's tags" do
            tag_names = feature.tags.collect { |tag| tag.name }

            expect(tag_names).to eq(['@tag_1', '@tag_2'])
          end

        end


        context 'an empty feature' do

          let(:source_text) { "#{@feature_keyword}:" }
          let(:feature) { clazz.new(source_text) }


          it "models the feature's name" do
            expect(feature.name).to eq('')
          end

          it "models the feature's description" do
            expect(feature.description).to eq('')
          end

          it "models the feature's background" do
            expect(feature.background).to be_nil
          end

          it "models the feature's scenarios" do
            expect(feature.scenarios).to eq([])
          end

          it "models the feature's outlines" do
            expect(feature.outlines).to eq([])
          end

          it "models the feature's tags" do
            expect(feature.tags).to eq([])
          end

        end

      end

    end


    it 'knows how many test cases it has' do
      source_1 = "#{@feature_keyword}: Test feature"

      source_2 = "#{@feature_keyword}: Test feature
                    #{@scenario_keyword}: Test scenario
                    #{@outline_keyword}: Test outline
                      #{@step_keyword} a step
                    #{@example_keyword}: Test examples
                      |param|
                      |value_1|
                      |value_2|"

      feature_1 = clazz.new(source_1)
      feature_2 = clazz.new(source_2)


      expect(feature_1.test_case_count).to eq(0)
      expect(feature_2.test_case_count).to eq(3)
    end


    describe 'getting ancestors' do

      before(:each) do
        source = "#{@feature_keyword}: Test feature"

        file_path = "#{@default_file_directory}/feature_test_file.feature"
        File.open(file_path, 'w') { |file| file.write(source) }
      end

      let(:directory) { CukeModeler::Directory.new(@default_file_directory) }
      let(:feature) { directory.feature_files.first.feature }


      it 'can get its directory' do
        ancestor = feature.get_ancestor(:directory)

        expect(ancestor).to equal(directory)
      end

      it 'can get its feature file' do
        ancestor = feature.get_ancestor(:feature_file)

        expect(ancestor).to equal(directory.feature_files.first)
      end

      it 'returns nil if it does not have the requested type of ancestor' do
        ancestor = feature.get_ancestor(:test)

        expect(ancestor).to be_nil
      end

    end


    describe 'feature output' do

      it 'can be remade from its own output' do
        source = "@tag1 @tag2 @tag3
                  #{@feature_keyword}: A feature with everything it could have

                  Including a description
                  and then some.

                    #{@background_keyword}:

                    Background
                    description

                      #{@step_keyword} a step
                        | value1 |
                      #{@step_keyword} another step

                    @scenario_tag
                    #{@scenario_keyword}:

                    Scenario
                    description

                      #{@step_keyword} a step
                      #{@step_keyword} another step
                        \"\"\"
                        some text
                        \"\"\"

                    @outline_tag
                    #{@outline_keyword}:

                    Outline
                    description

                      #{@step_keyword} a step
                        | value2 |
                      #{@step_keyword} another step
                        \"\"\"
                        some text
                        \"\"\"

                    @example_tag
                    #{@example_keyword}:

                    Example
                    description

                      | param |
                      | value |"
        feature = clazz.new(source)

        feature_output = feature.to_s
        remade_feature_output = clazz.new(feature_output).to_s

        expect(remade_feature_output).to eq(feature_output)
      end


      context 'from source text' do

        it 'can output an empty feature' do
          source = ["#{@feature_keyword}:"]
          source = source.join("\n")
          feature = clazz.new(source)

          feature_output = feature.to_s.split("\n", -1)

          expect(feature_output).to eq(["#{@feature_keyword}:"])
        end

        it 'can output a feature that has a name' do
          source = ["#{@feature_keyword}: test feature"]
          source = source.join("\n")
          feature = clazz.new(source)

          feature_output = feature.to_s.split("\n", -1)

          expect(feature_output).to eq(["#{@feature_keyword}: test feature"])
        end

        it 'can output a feature that has a description' do
          source = ["#{@feature_keyword}:",
                    'Some description.',
                    'Some more description.']
          source = source.join("\n")
          feature = clazz.new(source)

          feature_output = feature.to_s.split("\n", -1)

          expect(feature_output).to eq(["#{@feature_keyword}:",
                                        '',
                                        'Some description.',
                                        'Some more description.'])
        end

        it 'can output a feature that has tags' do
          source = ['@tag1 @tag2',
                    '@tag3',
                    "#{@feature_keyword}:"]
          source = source.join("\n")
          feature = clazz.new(source)

          feature_output = feature.to_s.split("\n", -1)

          expect(feature_output).to eq(['@tag1 @tag2 @tag3',
                                        "#{@feature_keyword}:"])
        end

        it 'can output a feature that has a background' do
          source = ["#{@feature_keyword}:",
                    "#{@background_keyword}:",
                    "#{@step_keyword} a step"]
          source = source.join("\n")
          feature = clazz.new(source)

          feature_output = feature.to_s.split("\n", -1)

          expect(feature_output).to eq(["#{@feature_keyword}:",
                                        '',
                                        "  #{@background_keyword}:",
                                        "    #{@step_keyword} a step"])
        end

        it 'can output a feature that has a scenario' do
          source = ["#{@feature_keyword}:",
                    "#{@scenario_keyword}:",
                    "#{@step_keyword} a step"]
          source = source.join("\n")
          feature = clazz.new(source)

          feature_output = feature.to_s.split("\n", -1)

          expect(feature_output).to eq(["#{@feature_keyword}:",
                                        '',
                                        "  #{@scenario_keyword}:",
                                        "    #{@step_keyword} a step"])
        end

        it 'can output a feature that has an outline' do
          source = ["#{@feature_keyword}:",
                    "#{@outline_keyword}:",
                    "#{@step_keyword} a step",
                    "#{@example_keyword}:",
                    '|param|',
                    '|value|']
          source = source.join("\n")
          feature = clazz.new(source)

          feature_output = feature.to_s.split("\n", -1)

          expect(feature_output).to eq(["#{@feature_keyword}:",
                                        '',
                                        "  #{@outline_keyword}:",
                                        "    #{@step_keyword} a step",
                                        '',
                                        "  #{@example_keyword}:",
                                        '    | param |',
                                        '    | value |'])
        end

        it 'can output a feature that has everything' do
          source = ['@tag1 @tag2 @tag3',
                    "#{@feature_keyword}: A feature with everything it could have",
                    'Including a description',
                    'and then some.',
                    "#{@background_keyword}:",
                    'Background',
                    'description',
                    "#{@step_keyword} a step",
                    '|value1|',
                    "#{@step_keyword} another step",
                    '@scenario_tag',
                    "#{@scenario_keyword}:",
                    'Scenario',
                    'description',
                    "#{@step_keyword} a step",
                    "#{@step_keyword} another step",
                    '"""',
                    'some text',
                    '"""',
                    '@outline_tag',
                    "#{@outline_keyword}:",
                    'Outline ',
                    'description',
                    "#{@step_keyword} a step ",
                    '|value2|',
                    "#{@step_keyword} another step",
                    '"""',
                    'some text',
                    '"""',
                    '@example_tag',
                    "#{@example_keyword}:",
                    'Example',
                    'description',
                    '|param|',
                    '|value|']
          source = source.join("\n")
          feature = clazz.new(source)

          feature_output = feature.to_s.split("\n", -1)

          expect(feature_output).to eq(['@tag1 @tag2 @tag3',
                                        "#{@feature_keyword}: A feature with everything it could have",
                                        '',
                                        'Including a description',
                                        'and then some.',
                                        '',
                                        "  #{@background_keyword}:",
                                        '',
                                        '  Background',
                                        '  description',
                                        '',
                                        "    #{@step_keyword} a step",
                                        '      | value1 |',
                                        "    #{@step_keyword} another step",
                                        '',
                                        '  @scenario_tag',
                                        "  #{@scenario_keyword}:",
                                        '',
                                        '  Scenario',
                                        '  description',
                                        '',
                                        "    #{@step_keyword} a step",
                                        "    #{@step_keyword} another step",
                                        '      """',
                                        '      some text',
                                        '      """',
                                        '',
                                        '  @outline_tag',
                                        "  #{@outline_keyword}:",
                                        '',
                                        '  Outline',
                                        '  description',
                                        '',
                                        "    #{@step_keyword} a step",
                                        '      | value2 |',
                                        "    #{@step_keyword} another step",
                                        '      """',
                                        '      some text',
                                        '      """',
                                        '',
                                        '  @example_tag',
                                        "  #{@example_keyword}:",
                                        '',
                                        '  Example',
                                        '  description',
                                        '',
                                        '    | param |',
                                        '    | value |'])
        end

      end


      context 'from abstract instantiation' do

        let(:feature) { clazz.new }


        it 'can output a feature that has only tags' do
          feature.tags = [CukeModeler::Tag.new]

          expect { feature.to_s }.to_not raise_error
        end

        it 'can output a feature that has only a background' do
          feature.background = [CukeModeler::Background.new]

          expect { feature.to_s }.to_not raise_error
        end

        it 'can output a feature that has only scenarios' do
          feature.tests = [CukeModeler::Scenario.new]

          expect { feature.to_s }.to_not raise_error
        end

        it 'can output a feature that has only outlines' do
          feature.tests = [CukeModeler::Outline.new]

          expect { feature.to_s }.to_not raise_error
        end

      end

    end

  end


  describe 'stuff that is in no way part of the public API and entirely subject to change' do

    it 'provides a useful explosion message if it encounters an entirely new type of feature child' do
      begin
        $old_method = CukeModeler::Parsing.method(:parse_text)


        # Monkey patch the parsing method to mimic what would essentially be Gherkin creating new types of language objects
        module CukeModeler
          module Parsing
            class << self
              def parse_text(source_text, filename)
                result = $old_method.call(source_text, filename)

                result.first['feature']['elements'].first['type'] = :some_unknown_type

                result
              end
            end
          end
        end


        expect { clazz.new("#{@feature_keyword}:\n#{@scenario_keyword}:\n#{@step_keyword} foo") }.to raise_error(ArgumentError, /Unknown.*some_unknown_type/)
      ensure
        # Making sure that our changes don't escape a test and ruin the rest of the suite
        module CukeModeler
          module Parsing
            class << self
              define_method(:parse_text, $old_method)
            end
          end
        end
      end
    end

  end

end
