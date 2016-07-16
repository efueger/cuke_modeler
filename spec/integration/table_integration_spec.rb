require 'spec_helper'

SimpleCov.command_name('Table') unless RUBY_VERSION.to_s < '1.9.0'

describe 'Table, Integration' do

  let(:clazz) { CukeModeler::Table }


  describe 'common behavior' do

    it_should_behave_like 'a modeled element, integration'

  end

  describe 'unique behavior' do

    it 'can be parsed from stand alone text' do
      source = '| a table |'

      expect { @element = clazz.new(source) }.to_not raise_error

      # Sanity check in case instantiation failed in a non-explosive manner
      cell_values = @element.rows.collect { |row| row.cells.collect { |cell| cell.value } }

      expect(cell_values).to eq([['a table']])
    end

    it 'stores the original data generated by the parsing adapter', :gherkin4 => true do
      table = clazz.new("| a table |")
      raw_data = table.raw_element

      expect(raw_data.keys).to match_array([:type, :location, :rows])
      expect(raw_data[:type]).to eq(:DataTable)
    end

    it 'stores the original data generated by the parsing adapter', :gherkin3 => true do
      table = clazz.new("| a table |")
      raw_data = table.raw_element

      expect(raw_data.keys).to match_array([:type, :location, :rows])
      expect(raw_data[:type]).to eq(:DataTable)
    end

    it 'stores the original data generated by the parsing adapter', :gherkin2 => true do
      table = clazz.new("| a table |")
      raw_data = table.raw_element

      # There is no parsing data for the table itself, only its rows
      expect(raw_data).to match_array([])
    end

    it 'can be instantiated with the minimum viable Gherkin' do
      source = '| a table |'

      expect { clazz.new(source) }.to_not raise_error
    end


    describe 'model population' do

      context 'from source text' do

        it "models the table's source line" do
          source_text = "Feature:

                           Scenario:
                             * step
                               | value |"
          table = CukeModeler::Feature.new(source_text).tests.first.steps.first.block

          expect(table.source_line).to eq(5)
        end


        context 'a filled table' do

          let(:source_text) { "| value 1 |
                               | value 2 |" }
          let(:table) { clazz.new(source_text) }


          it "models the table's rows" do
            table_cell_values = table.rows.collect { |row| row.cells.collect { |cell| cell.value } }

            expect(table_cell_values).to eq([['value 1'], ['value 2']])
          end

        end

      end

    end


    it 'properly sets its child elements' do
      source = ['| cell 1 |',
                '| cell 2 |']
      source = source.join("\n")

      table = clazz.new(source)
      row_1 = table.rows[0]
      row_2 = table.rows[1]

      row_1.parent_model.should equal table
      row_2.parent_model.should equal table
    end

    describe 'getting ancestors' do

      before(:each) do
        source = ['Feature: Test feature',
                  '',
                  '  Scenario: Test test',
                  '    * a step:',
                  '      | a | table |']
        source = source.join("\n")

        file_path = "#{@default_file_directory}/table_row_test_file.feature"
        File.open(file_path, 'w') { |file| file.write(source) }
      end

      let(:directory) { CukeModeler::Directory.new(@default_file_directory) }
      let(:table) { directory.feature_files.first.feature.tests.first.steps.first.block }


      it 'can get its directory' do
        ancestor = table.get_ancestor(:directory)

        ancestor.should equal directory
      end

      it 'can get its feature file' do
        ancestor = table.get_ancestor(:feature_file)

        ancestor.should equal directory.feature_files.first
      end

      it 'can get its feature' do
        ancestor = table.get_ancestor(:feature)

        ancestor.should equal directory.feature_files.first.feature
      end

      context 'a table that is part of a scenario' do

        before(:each) do
          source = 'Feature: Test feature
                    
                      Scenario: Test test
                        * a step:
                          | a | table |'

          file_path = "#{@default_file_directory}/doc_string_test_file.feature"
          File.open(file_path, 'w') { |file| file.write(source) }
        end

        let(:directory) { CukeModeler::Directory.new(@default_file_directory) }
        let(:table) { directory.feature_files.first.feature.tests.first.steps.first.block }


        it 'can get its scenario' do
          ancestor = table.get_ancestor(:scenario)

          expect(ancestor).to equal(directory.feature_files.first.feature.tests.first)
        end

      end

      context 'a table that is part of an outline' do

        before(:each) do
          source = 'Feature: Test feature
                    
                      Scenario Outline: Test outline
                        * a step:
                          | a | table |
                      Examples:
                        | param |
                        | value |'

          file_path = "#{@default_file_directory}/doc_string_test_file.feature"
          File.open(file_path, 'w') { |file| file.write(source) }
        end

        let(:directory) { CukeModeler::Directory.new(@default_file_directory) }
        let(:table) { directory.feature_files.first.feature.tests.first.steps.first.block }


        it 'can get its outline' do
          ancestor = table.get_ancestor(:outline)

          expect(ancestor).to equal(directory.feature_files.first.feature.tests.first)
        end

      end

      context 'a table that is part of a background' do

        before(:each) do
          source = 'Feature: Test feature
                    
                      Background: Test background
                        * a step:
                          | a | table |'

          file_path = "#{@default_file_directory}/doc_string_test_file.feature"
          File.open(file_path, 'w') { |file| file.write(source) }
        end

        let(:directory) { CukeModeler::Directory.new(@default_file_directory) }
        let(:table) { directory.feature_files.first.feature.background.steps.first.block }


        it 'can get its background' do
          ancestor = table.get_ancestor(:background)

          expect(ancestor).to equal(directory.feature_files.first.feature.background)
        end

      end

      it 'can get its step' do
        ancestor = table.get_ancestor(:step)

        ancestor.should equal directory.feature_files.first.feature.tests.first.steps.first
      end

      it 'returns nil if it does not have the requested type of ancestor' do
        ancestor = table.get_ancestor(:example)

        ancestor.should be_nil
      end

    end


    describe 'table output' do

      it 'can be remade from its own output' do
        source = ['| value1 | value2 |',
                  '| value3 | value4 |']
        source = source.join("\n")
        table = clazz.new(source)

        table_output = table.to_s
        remade_table_output = clazz.new(table_output).to_s

        expect(remade_table_output).to eq(table_output)
      end

      # This behavior should already be taken care of by the cell object's output method, but
      # the table object has to adjust that output in order to properly buffer column width
      # and it is possible that during that process it messes up the cell's output.

      it 'can correctly output a row that has special characters in it', :wip => true do
        source = ['| a value with \| |',
                  '| a value with \\\\ |',
                  '| a value with \\\\ and \| |']
        source = source.join("\n")
        table = clazz.new(source)

        table_output = table.to_s.split("\n")

        expect(table_output).to eq(['| a value with \|        |',
                                    '| a value with \\\\        |',
                                    '| a value with \\\\ and \| |'])
      end

      context 'from source text' do

        it 'can output an table that has a single row' do
          source = ['|value1|value2|']
          source = source.join("\n")
          table = clazz.new(source)

          table_output = table.to_s.split("\n")

          expect(table_output).to eq(['| value1 | value2 |'])
        end

        it 'can output an table that has multiple rows' do
          source = ['|value1|value2|',
                    '|value3|value4|']
          source = source.join("\n")
          table = clazz.new(source)

          table_output = table.to_s.split("\n")

          expect(table_output).to eq(['| value1 | value2 |',
                                      '| value3 | value4 |'])
        end

        it 'buffers row cells based on the longest value in a column' do
          source = ['|value 1| x|',
                    '|y|value 2|',
                    '|a|b|']
          source = source.join("\n")
          table = clazz.new(source)

          table_output = table.to_s.split("\n")

          expect(table_output).to eq(['| value 1 | x       |',
                                      '| y       | value 2 |',
                                      '| a       | b       |'])
        end

      end


      context 'from abstract instantiation' do

        let(:table) { clazz.new }


        it 'can output a table that only has row elements' do
          table.rows = [CukeModeler::TableRow.new]

          expect { table.to_s }.to_not raise_error
        end

      end

    end

  end

end
