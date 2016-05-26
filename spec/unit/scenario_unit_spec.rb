require 'spec_helper'

SimpleCov.command_name('Scenario') unless RUBY_VERSION.to_s < '1.9.0'

describe 'Scenario, Unit' do

  let(:clazz) { CukeModeler::Scenario }
  let(:scenario) { clazz.new }


  describe 'common behavior' do

    it_should_behave_like 'a modeled element'
    it_should_behave_like 'a named element'
    it_should_behave_like 'a described element'
    it_should_behave_like 'a stepped element'
    it_should_behave_like 'a tagged element'
    it_should_behave_like 'a sourced element'
    it_should_behave_like 'a raw element'

  end


  describe 'unique behavior' do

    it 'can be parsed from stand alone text' do
      source = 'Scenario: test scenario'

      expect { @element = clazz.new(source) }.to_not raise_error

      # Sanity check in case instantiation failed in a non-explosive manner
      @element.name.should == 'test scenario'
    end

    it 'provides a descriptive filename when being parsed from stand alone text' do
      source = "bad scenario text \n Scenario:\n And a step\n @foo "

      expect { clazz.new(source) }.to raise_error(/'cuke_modeler_stand_alone_scenario\.feature'/)
    end

    it 'stores the original data generated by the parsing adapter', :gherkin4 => true do
      scenario = clazz.new("Scenario: test scenario")
      raw_data = scenario.raw_element

      expect(raw_data.keys).to match_array([:type, :tags, :location, :keyword, :name, :steps])
      expect(raw_data[:type]).to eq(:Scenario)
    end

    it 'stores the original data generated by the parsing adapter', :gherkin3 => true do
      scenario = clazz.new("Scenario: test scenario")
      raw_data = scenario.raw_element

      expect(raw_data.keys).to match_array([:type, :tags, :location, :keyword, :name, :steps])
      expect(raw_data[:type]).to eq(:Scenario)
    end

    it 'stores the original data generated by the parsing adapter', :gherkin2 => true do
      scenario = clazz.new("Scenario: test scenario")
      raw_data = scenario.raw_element

      expect(raw_data.keys).to match_array(['keyword', 'name', 'line', 'description', 'id', 'type'])
      expect(raw_data['keyword']).to eq('Scenario')
    end

    it 'contains steps and tags' do
      tags = [:tag_1, :tag_2]
      steps = [:step_1, :step_2]
      everything = steps + tags

      scenario.steps = steps
      scenario.tags = tags

      expect(scenario.children).to match_array(everything)
    end

    describe 'scenario output edge cases' do

      it 'is a String' do
        scenario.to_s.should be_a(String)
      end


      context 'a new scenario object' do

        let(:scenario) { clazz.new }


        it 'can output an empty scenario' do
          expect { scenario.to_s }.to_not raise_error
        end

        it 'can output a scenario that has only a name' do
          scenario.name = 'a name'

          expect { scenario.to_s }.to_not raise_error
        end

        it 'can output a scenario that has only a description' do
          scenario.description = 'a description'

          expect { scenario.to_s }.to_not raise_error
        end

      end

    end

  end

end
