module ApplicationHelper
  def removeNonUsedVariables data, var
    unless var=="all"
      data.delete("pre") unless var=="pre"
      data.delete("tmp") unless var=="tmp"
      data.delete("gdd") unless var=="gdd"
    end
    data
  end

  def getPNG values
    width = 259
    height = 229
    range = []
    
    pre = {:variable => "pre", :data => values["pre"]}
    tmp = {:variable => "tmp", :data => values["tmp"]}
    gdd = {:variable => "gdd", :data => values["gdd"]}
    
    var_arr = [pre,tmp,gdd]
    images = []
    
    output_image = nil
    
    var_arr.each do |hash|
      values = hash[:data]
      variable = hash[:variable]
      next if values.nil?
      
      png = {:variable => variable, :data => []}
      
      # get min/max values for current variable
      minmax = getMinMax values
    
      values.each_with_index do |arr, x|
        png[:data][x] = []
        arr.each_with_index do |value, y|
          y = 228 - y
          png[:data][x][y] = getValue(value, minmax)
        end unless arr.nil?
      end
      images.push(png)
    end
    
    # ALL the variables are used -> combine the pngs from the images array
    output_image = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::TRANSPARENT)
    (0..257).each do |x|
      (0..227).each do |y|
        
        rgb = {"tmp" => 0, "pre" => 0, "gdd" => 0, :write => false}
        
        images.each do |image|
          color = image[:data][x][y]
          next if color.nil?
          rgb[image[:variable]] = color
          rgb[:write] = true
        end
        
        if rgb[:write]
          output_image[x,y] = ChunkyPNG::Color.rgb(rgb["tmp"], rgb["pre"], rgb["gdd"])
        end
        
      end
    end
    
    # return the output_image, either a single var or ALL varshblock
    output_image
  end
  
  def getMinMax values
    min_value = nil
    max_value = nil
    values.each_with_index do |arr, x|
      arr.each_with_index do |value, y|
        next if value.nil?
        min_value = value if min_value.nil?
        max_value = value if max_value.nil?
        min_value = value if value < min_value
        max_value = value if value > max_value
      end unless arr.nil?
    end
    return [min_value, max_value]
  end
  
  def getValue value, minmax
    min = minmax[0]
    max = minmax[1]
    
    if value.nil?
      return nil
    end
    
    if min < 0
      range = max + min.abs
      if range > 0
        percent = (value + min.abs) / range
      else
        percent = 0
      end
    else
      range = max - min
      if range > 0
        percent = value / range
      else
        percent = 0
      end
    end
    
    return (255*percent).round.to_i
  end
  
  def wrongFormat?
    error = false
    reasons = []
    puts params
    
    models = ["Europe"]
    scenarios = ["BAMBU","GRAS","SEDG"]
    year_range = 2001..2100
    month_range = 1..12
    variables = ["pre","tmp","gdd","all"]
    functions = ["Max", "Min", "Avg"]
    
    unless models.include? params[:model]
      error = true
      reasons.push("Wrong model name, available: Europe.")
    end
    
    unless scenarios.include? params[:scenario]
      error = true
      reasons.push("Wrong scenario name, available: BAMBU, GRAS, SEDG.")
    end
    
    unless year_range.include?(params[:year].to_i)
      error = true
      reasons.push("Wrong year, must be in range from 2001-2100.")
    end
    
    unless month_range.include?(params[:month_function].to_i) and functions.include?(params[:month_function].to_i)
      error = true
      reasons.push("Wrong month, must be in range from 1-12 or a function Min, Max, Avg")
    end
    
    unless variables.include?(params[:variable])
      error = true
      reasons.push("Wrong variable, must be tmp, pre, gdd or all.")
    end
    
    if error
      errorHash = {
        :response => 500,
        :message => "Can't process, you gave me a wrong format!",
        :reasons => reasons
      }
      
      respond_with(errorHash)
      
      return true
    else
      return false
    end
  end
end
