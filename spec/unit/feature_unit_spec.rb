require 'spec_helper'

SimpleCov.command_name('Feature') unless RUBY_VERSION.to_s < '1.9.0'

describe 'Feature, Unit' do

  let(:clazz) { CukeModeler::Feature }

  it_should_behave_like 'a feature element'
  it_should_behave_like 'a nested element'
  it_should_behave_like 'a containing element'
  it_should_behave_like 'a tagged element'
  it_should_behave_like 'a bare bones element'
  it_should_behave_like 'a prepopulated element'
  it_should_behave_like 'a sourced element'
  it_should_behave_like 'a raw element'

  let(:feature) { clazz.new }


  it 'can be parsed from stand alone text' do
    source = 'Feature: test feature'

    expect { @element = clazz.new(source) }.to_not raise_error

    # Sanity check in case instantiation failed in a non-explosive manner
    @element.name.should == 'test feature'
  end

  it 'provides a descriptive filename when being parsed from stand alone text' do
    source = 'bad feature text'

    expect { clazz.new(source) }.to raise_error(/'cuke_modeler_stand_alone_feature\.feature'/)
  end

  it 'stores the original data generated by the parsing adapter', :gherkin4 => true do
    feature = clazz.new('Feature: test feature')
    raw_data = feature.raw_element

    expect(raw_data.keys).to match_array([:type, :tags, :location, :language, :keyword, :name, :children])
    expect(raw_data[:type]).to eq(:Feature)
  end

  it 'stores the original data generated by the parsing adapter', :gherkin3 => true do
    feature = clazz.new('Feature: test feature')
    raw_data = feature.raw_element

    expect(raw_data.keys).to match_array([:type, :tags, :location, :language, :keyword, :name, :scenarioDefinitions, :comments])
    expect(raw_data[:type]).to eq(:Feature)
  end

  it 'stores the original data generated by the parsing adapter', :gherkin2 => true do
    feature = clazz.new('Feature: test feature')
    raw_data = feature.raw_element

    expect(raw_data.keys).to match_array(['keyword', 'name', 'line', 'description', 'id', 'uri'])
    expect(raw_data['keyword']).to eq('Feature')
  end

  it 'will complain about unknown element types' do
    parsed_element = {'description' => '',
                      'elements' => [{'keyword' => 'Scenario', 'description' => ''},
                                     {'keyword' => 'New Type', 'description' => ''}]}

    expect { clazz.new(parsed_element) }.to raise_error(ArgumentError)
  end

  it 'has a background - #background' do
    feature.should respond_to(:background)
  end

  it 'can get and set its background - #background, #background=' do
    feature.background = :some_background
    feature.background.should == :some_background
    feature.background = :some_other_background
    feature.background.should == :some_other_background
  end

  it 'knows whether or not it presently has a background - has_background?' do
    feature.background = :a_background
    feature.has_background?.should be_true
    feature.background = nil
    feature.has_background?.should be_false
  end

  it 'has tests - #tests' do
    feature.should respond_to(:tests)
  end

  it 'can get and set its tests - #tests, #tests=' do
    feature.tests = :some_tests
    feature.tests.should == :some_tests
    feature.tests = :some_other_tests
    feature.tests.should == :some_other_tests
  end

  it 'knows how many tests it has - #test_count' do
    feature.tests = []
    feature.test_count.should == 0
    feature.tests = [:test_1, :test_2]
    feature.test_count.should == 2
  end

  it 'contains backgrounds and tests' do
    tests = [:test_1, :test_2]
    background = :a_background
    everything = [background] + tests

    feature.background = background
    feature.tests = tests

    feature.contains.should =~ everything
  end

  it 'contains a background only if one is present' do
    tests = [:test_1, :test_2]
    background = nil
    everything = tests

    feature.background = background
    feature.tests = tests

    feature.contains.should =~ everything
  end

  it 'starts with no background' do
    feature.background.should == nil
  end

  it 'starts with no tests' do
    feature.tests.should == []
  end

  describe 'feature output edge cases' do

    it 'is a String' do
      feature.to_s.should be_a(String)
    end

    it 'can output an empty feature' do
      expect { feature.to_s }.to_not raise_error
    end

    it 'can output a feature that has only a name' do
      feature.name = 'a name'

      expect { feature.to_s }.to_not raise_error
    end

    it 'can output a feature that has only a description' do
      feature.description_text = 'a description'

      expect { feature.to_s }.to_not raise_error
    end

    it 'can output a feature that has only a tags' do
      feature.tags = ['a tag']

      expect { feature.to_s }.to_not raise_error
    end

  end

end
