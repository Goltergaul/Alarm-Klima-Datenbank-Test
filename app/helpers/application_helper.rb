module ApplicationHelper
  def getPNG values, variable
    min_value = nil
    max_value = nil
    sum = 0
    cnt = 0
    
    png = ChunkyPNG::Image.new(300, 300, ChunkyPNG::Color::TRANSPARENT)
    
    values.each_with_index do |arr, x|
      arr.each_with_index do |value, y|
        next if value.nil?
        min_value = value if min_value.nil?
        max_value = value if max_value.nil?
        min_value = value if value < min_value
        max_value = value if value > max_value
        
        cnt = cnt + 1
        sum = sum + value
      end unless arr.nil?
    end
    
    values.each_with_index do |arr, x|
      arr.each_with_index do |value, y|
        next if value.nil?
        y = 228 - y
        png[x,y] = getColor(variable, value, min_value, max_value)
      end unless arr.nil?
    end
    puts "Min value: #{min_value}"
    puts "Max value: #{max_value}"
    puts "Average: #{sum / cnt}"
    png
  end
  
  def getColor variable, value, min, max
    red = 0
    green = 0
    blue = 0
    case variable
      when "pre"
        red = 255
      when "tmp"
        green = 255
      when "gdd"
        blue = 255
    end
    range = max - min
    percent = value / range
    red = (red*percent).to_i
    green = (green*percent).to_i
    blue = (blue*percent).to_i
    
    ChunkyPNG::Color.rgb(red, green, blue)
  end
end
