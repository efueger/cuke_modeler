require 'spec_helper'

SimpleCov.command_name('Outline') unless RUBY_VERSION.to_s < '1.9.0'

describe 'Outline, Integration' do

  let(:clazz) { CukeModeler::Outline }


  describe 'common behavior' do

    it_should_behave_like 'a modeled element, integration'

  end

  describe 'unique behavior' do

    it 'can be instantiated with the minimum viable Gherkin', :gherkin3 => true do
      source = "Scenario Outline:
                Examples:
                  | param |
                  | value |"

      expect { clazz.new(source) }.to_not raise_error
    end

    it 'properly sets its child elements' do
      source = ['@a_tag',
                '  Scenario Outline:',
                '    * a step',
                '  Examples:',
                '    | param |',
                '    | value |']
      source = source.join("\n")

      outline = clazz.new(source)
      example = outline.examples.first
      step = outline.steps.first
      tag = outline.tags.first

      expect(example.parent_model).to equal(outline)
      expect(step.parent_model).to equal(outline)
      expect(tag.parent_model).to equal(outline)
    end


    describe 'getting ancestors' do

      before(:each) do
        source = ['Feature: Test feature',
                  '',
                  '  Scenario Outline: Test test',
                  '    * a step',
                  '  Examples: Test example',
                  '    | a param |',
                  '    | a value |']
        source = source.join("\n")

        file_path = "#{@default_file_directory}/outline_test_file.feature"
        File.open(file_path, 'w') { |file| file.write(source) }
      end

      let(:directory) { CukeModeler::Directory.new(@default_file_directory) }
      let(:outline) { directory.feature_files.first.feature.tests.first }


      it 'can get its directory' do
        ancestor = outline.get_ancestor(:directory)

        expect(ancestor).to equal(directory)
      end

      it 'can get its feature file' do
        ancestor = outline.get_ancestor(:feature_file)

        expect(ancestor).to equal(directory.feature_files.first)
      end

      it 'can get its feature' do
        ancestor = outline.get_ancestor(:feature)

        expect(ancestor).to equal(directory.feature_files.first.feature)
      end

      it 'returns nil if it does not have the requested type of ancestor' do
        ancestor = outline.get_ancestor(:test)

        expect(ancestor).to be_nil
      end


      describe 'model population' do

        context 'from source text' do

          it "models the outline's source line" do
            source_text = 'Feature:

                             Scenario Outline: foo
                               * step
                             Examples:
                               | param |
                               | value |'
            outline = CukeModeler::Feature.new(source_text).tests.first

            expect(outline.source_line).to eq(3)
          end


          context 'a filled outline' do

            let(:source_text) { '@tag1 @tag2 @tag3
                                 Scenario Outline:
                                   Given a <setup> step
                                   When an action step
                                   Then a <verification> step

                                 Examples: example 1
                                   | setup | verification |
                                   | x     | y            |
                                 Examples: example 2
                                   | setup | verification |
                                   | a     | b            |' }
            let(:outline) { clazz.new(source_text) }


            it "models the outline's steps" do
              step_names = outline.steps.collect { |step| step.base }

              expect(step_names).to eq(['a <setup> step', 'an action step', 'a <verification> step'])
            end

            it "models the outline's tags" do
              tag_names = outline.tags.collect { |tag| tag.name }

              expect(tag_names).to eq(['@tag1', '@tag2', '@tag3'])
            end

            it "models the outline's examples" do
              example_names = outline.examples.collect { |example| example.name }

              expect(example_names).to eq(['example 1', 'example 2'])
            end

          end


          # gherkin 3.x does not accept incomplete outlines
          context 'an empty outline', :gherkin3 => false do

            let(:source_text) { 'Scenario Outline:' }
            let(:outline) { clazz.new(source_text) }


            it "models the outline's steps" do
              expect(outline.steps).to eq([])
            end

            it "models the outline's tags" do
              expect(outline.tags).to eq([])
            end

            it "models the outline's examples" do
              expect(outline.examples).to eq([])
            end

          end

        end

      end


      describe 'comparison' do

        it 'is equal to a background with the same steps' do
          source = "Scenario Outline:
                      * step 1
                      * step 2
                    Examples:
                      | param |
                      | value |"
          outline = clazz.new(source)

          source = "Background:
                      * step 1
                      * step 2"
          background_1 = CukeModeler::Background.new(source)

          source = "Background:
                      * step 2
                      * step 1"
          background_2 = CukeModeler::Background.new(source)


          expect(outline).to eq(background_1)
          expect(outline).to_not eq(background_2)
        end

        it 'is equal to a scenario with the same steps' do
          source = "Scenario Outline:
                      * step 1
                      * step 2
                    Examples:
                      | param |
                      | value |"
          outline = clazz.new(source)

          source = "Scenario:
                      * step 1
                      * step 2"
          scenario_1 = CukeModeler::Scenario.new(source)

          source = "Scenario:
                      * step 2
                      * step 1"
          scenario_2 = CukeModeler::Scenario.new(source)


          expect(outline).to eq(scenario_1)
          expect(outline).to_not eq(scenario_2)
        end

        it 'is equal to an outline with the same steps' do
          source = "Scenario Outline:
                      * step 1
                      * step 2
                    Examples:
                      | param |
                      | value |"
          outline_1 = clazz.new(source)

          source = "Scenario Outline:
                      * step 1
                      * step 2
                    Examples:
                      | param |
                      | value |"
          outline_2 = clazz.new(source)

          source = "Scenario Outline:
                      * step 2
                      * step 1
                    Examples:
                      | param |
                      | value |"
          outline_3 = clazz.new(source)


          expect(outline_1).to eq(outline_2)
          expect(outline_1).to_not eq(outline_3)
        end

      end


      describe 'outline output' do

        it 'can be remade from its own output' do
          source = ['@tag1 @tag2 @tag3',
                    'Scenario Outline: An outline with everything it could have',
                    '',
                    'Some description.',
                    'Some more description.',
                    '',
                    '  * a step',
                    '    | value |',
                    '  * a <value> step',
                    '    """',
                    '      some string',
                    '    """',
                    '',
                    'Examples:',
                    '',
                    'Some description.',
                    'Some more description.',
                    '',
                    '  | value |',
                    '  | x     |',
                    '',
                    '@example_tag',
                    'Examples:',
                    '  | value |',
                    '  | y     |']
          source = source.join("\n")
          outline = clazz.new(source)

          outline_output = outline.to_s
          remade_outline_output = clazz.new(outline_output).to_s

          expect(remade_outline_output).to eq(outline_output)
        end


        context 'from source text' do

          # gherkin 3.x does not accept incomplete outlines
          it 'can output a outline that has steps', :gherkin3 => false do
            source = ['Scenario Outline:',
                      '  * a step',
                      '    | value |',
                      '  * another step',
                      '    """',
                      '    some string',
                      '    """']
            source = source.join("\n")
            outline = clazz.new(source)

            outline_output = outline.to_s.split("\n")

            expect(outline_output).to eq(['Scenario Outline:',
                                          '  * a step',
                                          '    | value |',
                                          '  * another step',
                                          '    """',
                                          '    some string',
                                          '    """'])
          end

          # gherkin 3.x does not accept incomplete outlines
          it 'can output a outline that has tags', :gherkin3 => false do
            source = ['@tag1 @tag2',
                      '@tag3',
                      'Scenario Outline:']
            source = source.join("\n")
            outline = clazz.new(source)

            outline_output = outline.to_s.split("\n")

            expect(outline_output).to eq(['@tag1 @tag2 @tag3',
                                          'Scenario Outline:'])
          end

          it 'can output a outline that has examples' do
            source = ['Scenario Outline:',
                      '* a step',
                      'Examples:',
                      '| value |',
                      '| x     |',
                      'Examples:',
                      '| value |',
                      '| y     |']
            source = source.join("\n")
            outline = clazz.new(source)

            outline_output = outline.to_s.split("\n")

            expect(outline_output).to eq(['Scenario Outline:',
                                          '  * a step',
                                          '',
                                          'Examples:',
                                          '  | value |',
                                          '  | x     |',
                                          '',
                                          'Examples:',
                                          '  | value |',
                                          '  | y     |'])
          end

          it 'can output a outline that has everything' do
            source = ['@tag1 @tag2 @tag3',
                      'Scenario Outline: A outline with everything it could have',
                      'Including a description',
                      'and then some.',
                      '* a step',
                      '|value|',
                      '* another step',
                      '"""',
                      'some string',
                      '"""',
                      '',
                      'Examples:',
                      '',
                      'Some description.',
                      'Some more description.',
                      '',
                      '| value |',
                      '| x     |',
                      '',
                      '@example_tag',
                      'Examples:',
                      '| value |',
                      '| y     |']
            source = source.join("\n")
            outline = clazz.new(source)

            outline_output = outline.to_s.split("\n")

            expect(outline_output).to eq(['@tag1 @tag2 @tag3',
                                          'Scenario Outline: A outline with everything it could have',
                                          '',
                                          'Including a description',
                                          'and then some.',
                                          '',
                                          '  * a step',
                                          '    | value |',
                                          '  * another step',
                                          '    """',
                                          '    some string',
                                          '    """',
                                          '',
                                          'Examples:',
                                          '',
                                          'Some description.',
                                          'Some more description.',
                                          '',
                                          '  | value |',
                                          '  | x     |',
                                          '',
                                          '@example_tag',
                                          'Examples:',
                                          '  | value |',
                                          '  | y     |'])
          end

        end


        context 'from abstract instantiation' do

          let(:outline) { clazz.new }


          it 'can output an outline that has only tags' do
            outline.tags = [CukeModeler::Tag.new]

            expect { outline.to_s }.to_not raise_error
          end

          it 'can output an outline that has only steps' do
            outline.steps = [CukeModeler::Step.new]

            expect { outline.to_s }.to_not raise_error
          end

          it 'can output an outline that has only examples' do
            outline.examples = [CukeModeler::Example.new]

            expect { outline.to_s }.to_not raise_error
          end

        end

      end

    end

  end

end
