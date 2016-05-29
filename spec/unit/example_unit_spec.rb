require 'spec_helper'

SimpleCov.command_name('Example') unless RUBY_VERSION.to_s < '1.9.0'

describe 'Example, Unit' do

  let(:clazz) { CukeModeler::Example }
  let(:example) { clazz.new }

  describe 'common behavior' do

    it_should_behave_like 'a modeled element'
    it_should_behave_like 'a named element'
    it_should_behave_like 'a described element'
    it_should_behave_like 'a tagged element'
    it_should_behave_like 'a sourced element'
    it_should_behave_like 'a raw element'

  end


  describe 'unique behavior' do

    it 'can be parsed from stand alone text' do
      source = ['Examples: test example',
                '|param| ',
                '|value|']

      source = source.join("\n")

      expect { @element = clazz.new(source) }.to_not raise_error

      # Sanity check in case instantiation failed in a non-explosive manner
      @element.name.should == 'test example'
    end

    # todo - add more tests like this to the 'barebones' test set
    it 'can be instantiated with the minimum viable Gherkin', :gherkin4 => true do
      source = ['Examples:']
      source = source.join("\n")

      expect { @element = clazz.new(source) }.to_not raise_error
    end

    # todo - add more tests like this to the 'barebones' test set
    it 'can be instantiated with the minimum viable Gherkin', :gherkin3 => true do
      source = ['Examples:',
                '|param|',
                '|value|']
      source = source.join("\n")

      expect { @element = clazz.new(source) }.to_not raise_error
    end

    # todo - add more tests like this to the 'barebones' test set
    it 'can be instantiated with the minimum viable Gherkin', :gherkin2 => true do
      source = ['Examples:',
                '|param|']
      source = source.join("\n")

      expect { @element = clazz.new(source) }.to_not raise_error
    end

    it 'provides a descriptive filename when being parsed from stand alone text' do
      source = 'bad example text'

      expect { clazz.new(source) }.to raise_error(/'cuke_modeler_stand_alone_example\.feature'/)
    end

    it 'stores the original data generated by the parsing adapter', :gherkin4 => true do
      example = clazz.new("Examples: test example\n|param|\n|value|")
      raw_data = example.raw_element

      expect(raw_data.keys).to match_array([:type, :tags, :location, :keyword, :name, :tableHeader, :tableBody])
      expect(raw_data[:type]).to eq(:Examples)
    end

    it 'stores the original data generated by the parsing adapter', :gherkin3 => true do
      example = clazz.new("Examples: test example\n|param|\n|value|")
      raw_data = example.raw_element

      expect(raw_data.keys).to match_array([:type, :tags, :location, :keyword, :name, :tableHeader, :tableBody])
      expect(raw_data[:type]).to eq(:Examples)
    end

    it 'stores the original data generated by the parsing adapter', :gherkin2 => true do
      example = clazz.new("Examples: test example\n|param|\n|value|")
      raw_data = example.raw_element

      expect(raw_data.keys).to match_array(['keyword', 'name', 'line', 'description', 'id', 'rows'])
      expect(raw_data['keyword']).to eq('Examples')
    end

    it 'has rows' do
      example.should respond_to(:rows)
    end

    it 'can change its rows' do
      expect(example).to respond_to(:rows=)

      example.rows = :some_rows
      expect(example.rows).to eq(:some_rows)
      example.rows = :some_other_rows
      expect(example.rows).to eq(:some_other_rows)
    end

    it 'can selectively access its parameter row' do
      expect(example).to respond_to(:parameter_row)
    end

    it 'can selectively access its argument rows' do
      expect(example).to respond_to(:argument_rows)
    end


    describe 'abstract instantiation' do

      context 'a new example object' do

        let(:example) { clazz.new }


        it 'starts with no rows' do
          expect(example.rows).to eq([])
        end

        it 'starts with no argument rows' do
          expect(example.argument_rows).to eq([])
        end

        it 'starts with no parameter row' do
          expect(example.parameter_row).to be_nil
        end

      end

    end


    describe '#add_row' do

      it 'can add a new example row' do
        clazz.new.should respond_to(:add_row)
      end

      # todo - move these tests because they are not unit tests because they use row objects
      it 'can add a new row as a hash, string values' do
        source = "Examples:\n|param1|param2|\n|value1|value2|"
        example = clazz.new(source)

        new_row = {'param1' => 'value3', 'param2' => 'value4'}
        example.add_row(new_row)

        expect(example.argument_rows.collect { |row| row.cells }).to eq([['value1', 'value2'], ['value3', 'value4']])
      end

      it 'can add a new row as a hash, non-string values' do
        source = "Examples:\n|param1|param2|\n|value1|value2|"
        example = clazz.new(source)

        new_row = {:param1 => 'value3', 'param2' => 4}
        example.add_row(new_row)

        expect(example.argument_rows.collect { |row| row.cells }).to eq([['value1', 'value2'], ['value3', '4']])
      end

      it 'can add a new row as a hash, random key order' do
        source = "Examples:\n|param1|param2|\n|value1|value2|"
        example = clazz.new(source)

        new_row = {'param2' => 'value4', 'param1' => 'value3'}
        example.add_row(new_row)

        expect(example.argument_rows.collect { |row| row.cells }).to eq([['value1', 'value2'], ['value3', 'value4']])
      end

      it 'can add a new row as an array, string values' do
        source = "Examples:\n|param1|param2|\n|value1|value2|"
        example = clazz.new(source)

        new_row = ['value3', 'value4']
        example.add_row(new_row)

        expect(example.argument_rows.collect { |row| row.cells }).to eq([['value1', 'value2'], ['value3', 'value4']])
      end

      it 'can add a new row as an array, non-string values' do
        source = "Examples:\n|param1|param2|param3|\n|value1|value2|value3|"
        example = clazz.new(source)

        new_row = [:value4, 5, 'value6']
        example.add_row(new_row)

        expect(example.argument_rows.collect { |row| row.cells }).to eq([['value1', 'value2', 'value3'], ['value4', '5', 'value6']])
      end

      it 'can only use a Hash or an Array to add a new row' do
        source = "Examples:\n|param|\n|value|"
        example = clazz.new(source)

        expect { example.add_row({}) }.to_not raise_error
        expect { example.add_row([]) }.to_not raise_error
        expect { example.add_row(:a_row) }.to raise_error(ArgumentError)
      end

      it 'trims whitespace from added rows' do
        source = "Examples:\n|param1|param2|\n|value1|value2|"
        example = clazz.new(source)

        hash_row = {'param1' => 'value3  ', 'param2' => '  value4'}
        array_row = ['value5', ' value6 ']
        example.add_row(hash_row)
        example.add_row(array_row)

        expect(example.argument_rows.collect { |row| row.cells }).to eq([['value1', 'value2'], ['value3', 'value4'], ['value5', 'value6']])
      end

      it 'will complain if a row is added and no parameters have been set' do
        example = clazz.new
        example.rows = []

        new_row = ['value1', 'value2']
        expect { example.add_row(new_row) }.to raise_error('Cannot add a row. No parameters have been set.')

        new_row = {'param1' => 'value1', 'param2' => 'value2'}
        expect { example.add_row(new_row) }.to raise_error('Cannot add a row. No parameters have been set.')
      end

      it 'does not modify its row input' do
        source = "Examples:\n|param1|param2|\n|value1|value2|"
        example = clazz.new(source)

        array_row = ['value1'.freeze, 'value2'.freeze].freeze
        expect { example.add_row(array_row) }.to_not raise_error

        hash_row = {'param1'.freeze => 'value1'.freeze, 'param2'.freeze => 'value2'.freeze}.freeze
        expect { example.add_row(hash_row) }.to_not raise_error
      end

    end

    describe '#remove_row' do

      it 'can remove an existing example row' do
        clazz.new.should respond_to(:remove_row)
      end

      it 'can remove an existing row as a hash' do
        source = "Examples:\n|param1|param2|\n|value1|value2|\n|value3|value4|"
        example = clazz.new(source)

        old_row = {'param1' => 'value3', 'param2' => 'value4'}
        example.remove_row(old_row)

        expect(example.argument_rows.collect { |row| row.cells }).to eq([['value1', 'value2']])
      end

      it 'can remove an existing row as a hash, random key order' do
        source = "Examples:\n|param1|param2|\n|value1|value2|\n|value3|value4|"
        example = clazz.new(source)

        old_row = {'param2' => 'value4', 'param1' => 'value3'}
        example.remove_row(old_row)

        expect(example.argument_rows.collect { |row| row.cells }).to eq([['value1', 'value2']])
      end

      it 'can remove an existing row as an array' do
        source = "Examples:\n|param1|param2|\n|value1|value2|\n|value3|value4|"
        example = clazz.new(source)

        old_row = ['value3', 'value4']
        example.remove_row(old_row)

        expect(example.argument_rows.collect { |row| row.cells }).to eq([['value1', 'value2']])
      end

      it 'can only use a Hash or an Array to remove an existing row' do
        expect { example.remove_row({}) }.to_not raise_error
        expect { example.remove_row([]) }.to_not raise_error
        expect { example.remove_row(:a_row) }.to raise_error(ArgumentError)
      end

      it 'trims whitespace from removed rows' do
        source = "Examples:\n|param1|param2|\n|value1|value2|\n|value3|value4|\n|value5|value6|"
        example = clazz.new(source)

        hash_row = {'param1' => 'value3  ', 'param2' => '  value4'}
        array_row = ['value5', ' value6 ']

        # todo - test these separately
        example.remove_row(hash_row)
        example.remove_row(array_row)

        expect(example.argument_rows.collect { |row| row.cells }).to eq([['value1', 'value2']])
      end

      it 'can gracefully remove a row from an example that has no rows' do
        example = clazz.new
        example.rows = []

        expect { example.remove_row({}) }.to_not raise_error
        expect { example.remove_row([]) }.to_not raise_error
      end

      it 'will not remove the parameter row' do
        source = "Examples:\n|param1|param2|\n|value1|value2|"
        example = clazz.new(source)

        hash_row = {'param1' => 'param1  ', 'param2' => '  param2'}
        array_row = ['param1', ' param2 ']

        example.remove_row(hash_row)
        expect(example.rows.collect { |row| row.cells }).to eq([['param1', 'param2'], ['value1', 'value2']])

        example.remove_row(array_row)
        expect(example.rows.collect { |row| row.cells }).to eq([['param1', 'param2'], ['value1', 'value2']])
      end

    end

    it 'contains rows and tags' do
      tags = [:tag_1, :tag_2]
      rows = [:row_1, :row_2]
      everything = rows + tags

      example.rows = rows
      example.tags = tags

      expect(example.children).to match_array(everything)
    end

    describe 'example output edge cases' do

      it 'is a String' do
        example.to_s.should be_a(String)
      end

      context 'a new example object' do

        let(:example) { clazz.new }


        it 'can output an empty example' do
          expect { example.to_s }.to_not raise_error
        end

        it 'can output an example that has only a name' do
          example.name = 'a name'

          expect { example.to_s }.to_not raise_error
        end

        it 'can output an example that has only a description' do
          example.description = 'a description'

          expect { example.to_s }.to_not raise_error
        end

      end

    end

  end

end
