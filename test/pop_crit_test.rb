require 'test/unit'
require File.dirname(__FILE__) + '/../../../../config/boot.rb'
require File.dirname(__FILE__) + '/../../../../config/environment.rb'
require File.dirname(__FILE__) + '/../lib/pop_crit.rb'

class PopCritTest < Test::Unit::TestCase
  include PopCrit
  
  def setup
    @test_params = {"fn"=>"Chris", "test_array"=>[1,2,3]}
    @test_array = [["first_name","=","Chris"], ["test_array", "IN", [1,2,3]], ["last_name", "=", "-1"]]
  end
  
  def test_empty_params_returns_empty_array
    assert_equal [""], process_criteria_params({})
  end
  
  def test_default_behavior_resulsts_in_equals_operator_for_non_array_fields
    assert_equal ["first_name = ?", "Chris"], process_criteria_params({"first_name"=>"Chris"})
  end
  
  def test_default_behavior_results_in_operator_for_multi_select_with_parens
    assert_equal ["test_array IN (?)", [1,2,3]], process_criteria_params({"test_array" => [1,2,3]})
  end

  def test_override_fields_array_renames_field
    options = {:override_fields=>{:test_array=>{:field_name=>"company_id"}, :fn=>{:field_name=>"first_name"}}}
    assert_equal ["company_id IN (?) AND first_name = ?", [1,2,3], "Chris"], process_criteria_params(@test_params, options)
  end
  
  def test_override_fields_array_replaces_operator
    options = {:override_fields=>{:test_array=>{:operator=>"NOT IN"}, :fn=>{:operator=>"<>"}}}
    assert_equal ["test_array NOT IN (?) AND fn <> ?", [1,2,3], "Chris"], process_criteria_params(@test_params, options)
  end
  
  def test_override_fields_array_doesnt_allow_non_in_operator_for_array_value
    options = {:override_fields=>{:test_array=>{:operator=>"="}, :fn=>{:operator=>"<>"}}}
    assert_not_equal ["test_array = (?) AND fn <> ?", [1,2,3], "Chris"], process_criteria_params(@test_params, options)
  end
  
  def test_override_fields_array_properly_substitutes_value
    options = {:override_fields=>{:test_array=>{:value=>[5,6,7]}, :fn=>{:operator=>"<>"}}}
    assert_equal ["test_array IN (?) AND fn <> ?", [5,6,7], "Chris"], process_criteria_params(@test_params, options)
  end
  
  def test_override_fields_array_adds_starts_with_value
    options = {:override_fields=>{:fn=>{:value_starts_with=>"%"}}}
    assert_equal ["test_array IN (?) AND fn = ?", [1,2,3], "%Chris"], process_criteria_params(@test_params, options)
  end
  
  def test_override_fields_array_adds_ends_with_value
    options = {:override_fields=>{:fn=>{:value_ends_with=>"%"}}}
    assert_equal ["test_array IN (?) AND fn = ?", [1,2,3], "Chris%"], process_criteria_params(@test_params, options)
  end
  
  def test_skip_value_defaults_to_negative_one_and_ejects_criteria_with_value
    assert_equal ["test_array IN (?)", [1,2,3]], process_criteria_params({"fn"=>"-1", "test_array"=>[1,2,3]})
  end
  
  def test_skip_value_option_replaces_negative_one_default
    assert_equal ["test_array IN (?)", [1,2,3]], process_criteria_params({"fn"=>"all", "test_array"=>[1,2,3]}, {:skip_value=>"all"})
  end
  
  def test_sql_to_keep_option_adds_raw_sql_to_front_of_criteria
    options = {:sql_to_keep=>"company_id <> 2"}
    assert_equal ["company_id <> 2 AND test_array IN (?) AND fn = ?", [1,2,3], "Chris"], process_criteria_params(@test_params, options)
  end
  
  def test_array_assembles_criteria
    assert_equal ["first_name = ? AND test_array IN (?)", "Chris", [1,2,3]], process_criteria_array(@test_array)
  end
  
  def test_array_reset_skip_value_default
    assert_equal ["first_name = ? AND test_array IN (?) AND last_name = ?", "Chris", [1,2,3], "-1"], process_criteria_array(@test_array, {:skip_value=>"all"})
  end
  
  def test_array_add_sql_to_keep
    assert_equal ["company_id <> 1 AND first_name = ? AND test_array IN (?)", "Chris", [1,2,3]], process_criteria_array(@test_array, {:sql_to_keep=>"company_id <> 1"})
  end
end
