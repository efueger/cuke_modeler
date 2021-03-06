require "#{File.dirname(__FILE__)}/../spec_helper"


describe 'Gherkin2Adapter, Integration', :gherkin2 => true do

  let(:clazz) { CukeModeler::Gherkin2Adapter }
  let(:adapter) { clazz.new }
  let(:source_text) { "# feature comment
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
                       # final comment" }
  let(:feature_file) { path = "#{@default_file_directory}/#{@default_feature_file_name}"
                       File.open(path, "w") { |file| file.puts source_text }

                       CukeModeler::FeatureFile.new(path) }
  let(:feature) { feature_file.feature }


  it "does not store parsing data for a feature file's children" do
    model = feature_file

    expect(model.parsing_data).to eq([])
  end

  it "does not store parsing data for a feature's children" do
    model = feature

    expect(model.parsing_data['comments']).to be_nil
    expect(model.parsing_data['tags']).to be_nil
    expect(model.parsing_data['elements']).to be_nil
  end

  it "does not store parsing data for a background's children" do
    model = feature.background

    expect(model.parsing_data['comments']).to be_nil
    expect(model.parsing_data['steps']).to be_nil
  end

  it "does not store parsing data for a scenario's children" do
    model = feature.scenarios.first

    expect(model.parsing_data['comments']).to be_nil
    expect(model.parsing_data['tags']).to be_nil
    expect(model.parsing_data['steps']).to be_nil
  end

  it "does not store parsing data for an outline's children" do
    model = feature.outlines.first

    expect(model.parsing_data['comments']).to be_nil
    expect(model.parsing_data['tags']).to be_nil
    expect(model.parsing_data['steps']).to be_nil
    expect(model.parsing_data['examples']).to be_nil
  end

  it "does not store parsing data for an example's children" do
    model = feature.outlines.first.examples.first

    expect(model.parsing_data['comments']).to be_nil
    expect(model.parsing_data['tags']).to be_nil
    expect(model.parsing_data['rows']).to be_nil
  end

  it "does not store parsing data for an example row's children" do
    model = feature.outlines.first.examples.first.rows.first

    expect(model.parsing_data['comments']).to be_nil
    expect(model.parsing_data['cells']).to be_nil
  end

  it "does not store parsing data for a step's children, table" do
    model = feature.outlines.first.steps.first

    expect(model.parsing_data['comments']).to be_nil
    expect(model.parsing_data['rows']).to be_nil
  end

  it "does not store parsing data for a step's children, doc string" do
    model = feature.outlines.first.steps.last

    expect(model.parsing_data['comments']).to be_nil
    expect(model.parsing_data['doc_string']).to be_nil
  end

  it "does not store parsing data for a table's children" do
    model = feature.outlines.first.steps.first.block

    expect(model.parsing_data).to be_empty
  end

  it "does not store parsing data for a table row's children" do
    model = feature.outlines.first.steps.first.block.rows.first

    expect(model.parsing_data['comments']).to be_nil
    expect(model.parsing_data['cells']).to be_nil
  end


  describe 'stuff that is in no way part of the public API and entirely subject to change' do

    it 'provides a useful explosion message if it encounters an entirely new type of test' do
      partial_feature_ast = {"elements" => [{"type" => "some_unknown_type"}]}

      expect { adapter.adapt_feature!(partial_feature_ast, []) }.to raise_error(ArgumentError, /Unknown.*some_unknown_type/)
    end

  end

end
