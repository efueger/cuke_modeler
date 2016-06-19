require 'spec_helper'

SimpleCov.command_name('Scenario') unless RUBY_VERSION.to_s < '1.9.0'

describe 'Scenario, Integration' do

  let(:clazz) { CukeModeler::Scenario }


  describe 'common behavior' do

    it_should_behave_like 'a modeled element, integration'

  end

  describe 'unique behavior' do

    it 'properly sets its child elements' do
      source = ['@a_tag',
                'Scenario: Test scenario',
                '  * a step']
      source = source.join("\n")

      scenario = clazz.new(source)
      step = scenario.steps.first
      tag = scenario.tags.first

      step.parent_model.should equal scenario
      tag.parent_model.should equal scenario
    end


    describe 'getting ancestors' do

      before(:each) do
        source = ['Feature: Test feature',
                  '',
                  '  Scenario: Test test',
                  '    * a step']
        source = source.join("\n")

        file_path = "#{@default_file_directory}/scenario_test_file.feature"
        File.open(file_path, 'w') { |file| file.write(source) }
      end

      let(:directory) { CukeModeler::Directory.new(@default_file_directory) }
      let(:scenario) { directory.feature_files.first.feature.tests.first }


      it 'can get its directory' do
        ancestor = scenario.get_ancestor(:directory)

        ancestor.should equal directory
      end

      it 'can get its feature file' do
        ancestor = scenario.get_ancestor(:feature_file)

        ancestor.should equal directory.feature_files.first
      end

      it 'can get its feature' do
        ancestor = scenario.get_ancestor(:feature)

        ancestor.should equal directory.feature_files.first.feature
      end

      it 'returns nil if it does not have the requested type of ancestor' do
        ancestor = scenario.get_ancestor(:test)

        ancestor.should be_nil
      end


      describe 'model population' do

        context 'from source text' do

          it "models the scenario's source line" do
            source_text = "Feature:

                           Scenario: foo
                             * step"
            scenario = CukeModeler::Feature.new(source_text).tests.first

            expect(scenario.source_line).to eq(3)
          end


          context 'a filled scenario' do

            let(:source_text) { "@tag1 @tag2 @tag3
                                 Scenario:
                                 * a step
                                 * another step" }
            let(:scenario) { clazz.new(source_text) }


            it "models the scenario's steps" do
              step_names = scenario.steps.collect { |step| step.base }

              expect(step_names).to eq(['a step', 'another step'])
            end

            it "models the scenario's tags" do
              tag_names = scenario.tags.collect { |tag| tag.name }

              expect(tag_names).to eq(['@tag1', '@tag2', '@tag3'])
            end

          end

          context 'an empty scenario' do

            let(:source_text) { 'Scenario:' }
            let(:scenario) { clazz.new(source_text) }


            it "models the scenario's steps" do
              expect(scenario.steps).to eq([])
            end

            it "models the scenario's tags" do
              expect(scenario.steps).to eq([])
            end

          end

        end

      end


      describe 'comparison' do

        it 'is equal to a background with the same steps' do
          source = "Scenario:
                      * step 1
                      * step 2"
          scenario = clazz.new(source)

          source = "Background:
                      * step 1
                      * step 2"
          background_1 = CukeModeler::Background.new(source)

          source = "Background:
                      * step 2
                      * step 1"
          background_2 = CukeModeler::Background.new(source)


          expect(scenario).to eq(background_1)
          expect(scenario).to_not eq(background_2)
        end

        it 'is equal to a scenario with the same steps' do
          source = "Scenario:
                      * step 1
                      * step 2"
          scenario_1 = clazz.new(source)

          source = "Scenario:
                      * step 1
                      * step 2"
          scenario_2 = clazz.new(source)

          source = "Scenario:
                      * step 2
                      * step 1"
          scenario_3 = clazz.new(source)


          expect(scenario_1).to eq(scenario_2)
          expect(scenario_1).to_not eq(scenario_3)
        end

        it 'is equal to an outline with the same steps' do
          source = "Scenario:
                      * step 1
                      * step 2"
          scenario = clazz.new(source)

          source = "Scenario Outline:
                      * step 1
                      * step 2
                    Examples:
                      | param |
                      | value |"
          outline_1 = CukeModeler::Outline.new(source)

          source = "Scenario Outline:
                      * step 2
                      * step 1
                    Examples:
                      | param |
                      | value |"
          outline_2 = CukeModeler::Outline.new(source)


          expect(scenario).to eq(outline_1)
          expect(scenario).to_not eq(outline_2)
        end

      end


      describe 'scenario output' do

        it 'can be remade from its own output' do
          source = ['@tag1 @tag2 @tag3',
                    'Scenario: A scenario with everything it could have',
                    '',
                    'Including a description',
                    'and then some.',
                    '',
                    '  * a step',
                    '    | value |',
                    '  * another step',
                    '    """',
                    '    some string',
                    '    """']
          source = source.join("\n")
          scenario = clazz.new(source)

          scenario_output = scenario.to_s
          remade_scenario_output = clazz.new(scenario_output).to_s

          expect(remade_scenario_output).to eq(scenario_output)
        end


        context 'from source text' do

          it 'can output a scenario that has steps' do
            source = ['Scenario:',
                      '* a step',
                      '|value|',
                      '* another step',
                      '"""',
                      'some string',
                      '"""']
            source = source.join("\n")
            scenario = clazz.new(source)

            scenario_output = scenario.to_s.split("\n")

            expect(scenario_output).to eq(['Scenario:',
                                           '  * a step',
                                           '    | value |',
                                           '  * another step',
                                           '    """',
                                           '    some string',
                                           '    """'])
          end

          it 'can output a scenario that has tags' do
            source = ['@tag1 @tag2',
                      '@tag3',
                      'Scenario:']
            source = source.join("\n")
            scenario = clazz.new(source)

            scenario_output = scenario.to_s.split("\n")

            expect(scenario_output).to eq(['@tag1 @tag2 @tag3',
                                           'Scenario:'])
          end

          it 'can output a scenario that has everything' do
            source = ['@tag1 @tag2 @tag3',
                      'Scenario: A scenario with everything it could have',
                      'Including a description',
                      'and then some.',
                      '* a step',
                      '|value|',
                      '* another step',
                      '"""',
                      'some string',
                      '"""']
            source = source.join("\n")
            scenario = clazz.new(source)

            scenario_output = scenario.to_s.split("\n")

            expect(scenario_output).to eq(['@tag1 @tag2 @tag3',
                                           'Scenario: A scenario with everything it could have',
                                           '',
                                           'Including a description',
                                           'and then some.',
                                           '',
                                           '  * a step',
                                           '    | value |',
                                           '  * another step',
                                           '    """',
                                           '    some string',
                                           '    """'])
          end

        end


        context 'from abstract instantiation' do

          let(:scenario) { clazz.new }


          it 'can output a scenario that has only tags' do
            scenario.tags = [CukeModeler::Tag.new]

            expect { scenario.to_s }.to_not raise_error
          end

          it 'can output a scenario that has only steps' do
            scenario.steps = [CukeModeler::Step.new]

            expect { scenario.to_s }.to_not raise_error
          end

        end

      end

    end

  end

end


