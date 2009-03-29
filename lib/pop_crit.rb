# Created by Christopher Hazlett on 2009-03-25.
# Copyright 2009 Integrate Consulting LLC. All rights reserved.
# www.integratechange.com
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module PopCrit
  # ===========================================================================================================================   
  # process_submitted_criteria takes the following parameters:
  # ---------------------------------------------------
  # * <tt>params</tt> - the parameter array from the form submitting the dynamically created criteria
  # 
  # Takes the following options hash values
  # * <tt>:skip_value</tt> - Any criteria matching this string value will be ommitted from the final conditions array. Defaults to '-1'
  # * <tt>:sql_to_keep</tt> - Any additional sql or subquery you'd like to add to the criteria.  If left blank, it will be excluded.
  # * <tt>:override_fields</tt> - A hash that allows you to override the default processing of some or all of the submitted params, takes the following form:
  #       {:submitted_parameter=>{:field_name=>"first_name", :operator=>"[=, <>, >=, <=, like, NOT IN]", :value=>"", :value_ends_with=>"%", :value_starts_with=>"%"}
  #
  # ---------------------------------------------------
  # DEFAULT PROCESSING
  # ---------------------------------------------------
  #
  # The default behavior of processing parameters works like this:
  # Each key submitted in the params becomes the field name unless a replacement field name is found in the override option hash, so if you submit
  # {"first_name"=>"Chris"}, the default conditions created would be ["first_name = ?", "Chris"]
  #
  # ---------------------------------------------------
  # USING ALIASES OR HIDING FIELD NAMES IN YOUR FORM FIELDS
  # ---------------------------------------------------
  # If you wish to hide your table's field_names on the submitting form or use a table alias in the criteria, you would give a different name for the input tag.
  # 
  # <input name="fn" value="" />
  #
  # Then create an override_fields hash like the following
  #
  # :override_fields => {:fn => {:field_name=>"first_name"}} or :override_fields => {:fn => {:field_name=>"contacts.first_name"}}
  #
  # This will result in the following two conditions arrays, respectively
  #
  # ["first_name = ?", "Chris"], ["contacts.first_name = ?", "Chris"]
  # ===========================================================================================================================  
  def process_criteria_params(criteria, options = {})
    unless criteria == nil
      initiate_criteria(options)
    
      criteria.delete_if{|key, value| (value.blank? or value.to_s==@skip_value)}
     
      criteria.each do |key, value|
        options[:override_fields] != nil && options[:override_fields].include?(key.intern) ? override = options[:override_fields].find{|k,v| k.to_s==key}[1] : override = {}
        field_name = override[:field_name] ||= key
        final_val = override[:value] ||= value
        operator = override[:operator] ||= "="    
        operator = "IN" if final_val.class==Array && !operator.downcase.include?("in")
        final_val = "#{override[:value_starts_with]}#{final_val}#{override[:value_ends_with]}" if final_val.class != Array
        
        create_sql(field_name, operator, final_val.class == Array)
        @final_conditions.push final_val
      end 
    
      finalize_criteria(options)
    else
      []
    end
  end
  
  # ==========================================================================================
  # process_criteria_array processes a simple three part array submitted from a controller 
  # Use the process_criteria_array function when you don't need to process submitted criteria from a form 
  # Accepts the following paramters
  # * <tt>criteria</tt> - Accepts an array or three part arrays formed like so:
  #   [["field_name", "sql_operator (=, <>, >=, <=, like)", value], ["field_name", operator, value]]
  #
  # Takes the following options hash values
  # * <tt>:skip_value</tt> - Any criteria matching this string value will be ommitted from the final conditions array. Defaults to '-1'
  # * <tt>:sql_to_keep</tt> - Any additional sql or subquery you'd like to add to the criteria.  If left blank, it will be excluded.
  # ==========================================================================================
  def process_criteria_array(criteria, options = {})
    initiate_criteria(options)
    
    criteria.delete_if{|c| (c[2].blank? or c[2]==@skip_value or c[2] == nil)}
    
    criteria.each do |c|
      create_sql(c[0], c[1], c[2].class == Array)
      @final_conditions.push c[2]
    end
    
    finalize_criteria(options)
  end
  
  private
  def initiate_criteria(options)
    @sql = ""
    @skip_value = options[:skip_value] ||= "-1"
    @final_conditions = Array[]
  end
  
  def create_sql(field, operator, in_parens = false)
    in_parens == true ? holder = "(?)" : holder = "?"
    @sql += "#{field} #{operator} #{holder} AND "
  end  
  
  def finalize_criteria(options)
    trim_length = (@sql.length - 6)
    options[:sql_to_keep] != nil ? sql_to_keep = "#{options[:sql_to_keep]} AND " : sql_to_keep = ""
    arr_sql = Array[sql_to_keep + @sql.slice(0..trim_length)] 
    arr_sql + @final_conditions    
  end
end