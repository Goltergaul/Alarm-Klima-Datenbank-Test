load 'config/initializers/mongo.rb'

namespace :alarm do
  task :edit => :environment do
    
    unless ENV.include?("model") and ENV.include?("scenario") and ENV.include?("year") and 
      ENV.include?("month") and ENV.include?("variable") and 
      ENV.include?("x") and ENV.include?("y")
      raise "Please specify params
      eg. rake alarm:edit model=Europe scenario=BAMBU year=2011 month=5 variable=pre x=100 y=100 value=23.4"
    end
    
    models = ["Europe"]
    scenarios = ["BAMBU","GRAS","SEDG"]
    year_range = 2001..2100
    month_range = 1..12
    variables = ["pre","tmp","gdd","all"]
    x_range = 0..257
    y_range = 0..227
    
    model = ENV["model"]
    scenario = ENV["scenario"]
    year = ENV["year"].to_i
    month = ENV["month"].to_i
    variable = ENV["variable"]
    x = ENV["x"].to_i
    y = ENV["y"].to_i
    value = ENV["value"]
    original_value = nil
    
    unless models.include? model
      raise "Wrong model name, available: Europe."
    end
    
    unless scenarios.include? scenario
      raise "Wrong scenario name, available: BAMBU, GRAS, SEDG."
    end
    
    unless year_range.include? year.to_i
      raise "Wrong year, must be in range from 2001-2100."
    end
    
    unless month_range.include? month.to_i
      raise "Wrong month, must be in range from 1-12 or a function Min, Max, Avg"
    end
    
    unless variables.include? variable
      raise "Wrong variable, must be tmp, pre, gdd or all."
    end
    
    unless x_range.include? x
      raise "Wrong x value, must be in range from 0..257"
    end
    
    unless y_range.include? y
      raise "Wrong y value, must be in range from 0..227"
    end
    
    if value=="" and value===/^[\d]+(\.[\d]+){0,1}$/
      raise "Wrong or no value given. Please specify a float or integer"
    else
      value = value.to_f
    end
    
    doc = Clima.find_by_year_and_month_and_model_and_scenario year, month, model, scenario
    data = doc.data[variable]
    
    if data[x].nil?
      data[x] = []
    end
    
    if data[x][y].nil?
      original_value = "nil"
    else
      original_value = data[x][y]
    end
    
    data[x][y] = value
    doc.save!
    
    puts "Original value <<#{original_value}>>
at #{x},#{y} in model \"#{model}\", scenario \"#{scenario}\" for #{year}/#{month} in variable \"#{variable}\"
changed to <<#{value}>>"
  end
end