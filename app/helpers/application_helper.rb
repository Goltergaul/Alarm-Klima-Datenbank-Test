module ApplicationHelper
  def getPNG values, var
    width = 300
    height = 300
    min_value = nil
    max_value = nil
    sum = 0
    cnt = 0
    
    pre = {:variable => "pre", :data => values[:pre]}
    tmp = {:variable => "tmp", :data => values[:tmp]}
    gdd = {:variable => "gdd", :data => values[:gdd]}
    
    output_image = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::TRANSPARENT)
    
    var_arr = [pre,tmp,gdd]
    images = []
    
    var_arr.each do |hash|
      values = hash[:data]
      variable = hash[:variable]
      next if values.nil?
      
      output_image = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::TRANSPARENT)
      images.push(output_image)
      
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
          #next if value.nil?
          y = 228 - y
          output_image[x,y] = getColor(variable, value, min_value, max_value)
        end unless arr.nil?
      end
      
    end
    
    if var.downcase=="all"
      output_image = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::TRANSPARENT)
      red=0
      green=0
      blue=0
      (0..257).each do |x|
        (0..227).each do |y|
          images.each do |image|
            color = image.get_pixel(x,y)
            r = ChunkyPNG::Color.r(color)
            g = ChunkyPNG::Color.g(color)
            b = ChunkyPNG::Color.b(color)
            red = r unless r==0
            green = g unless g==0
            blue = b unless b==0
          end
          unless red==0 and green==0 and blue==0
            output_image[x,y] = ChunkyPNG::Color.rgb(red, green, blue)
          end
        end
      end
    end
    output_image
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
      when "all"
        red = 255
        green = 255
        blue = 255
    end
    if value.nil?
      return ChunkyPNG::Color.rgba(red, green, blue, 0)
    end
    range = max - min
    percent = value / range
    red = (red*percent).to_i
    green = (green*percent).to_i
    blue = (blue*percent).to_i
    
    blue=0
    green=0
    
    ChunkyPNG::Color.rgb(red, green, blue)
  end
end
