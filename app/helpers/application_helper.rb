module ApplicationHelper
  def getPNG values, var
    width = 259
    height = 229
    range = []
    
    pre = {:variable => "pre", :data => values[:pre]}
    tmp = {:variable => "tmp", :data => values[:tmp]}
    gdd = {:variable => "gdd", :data => values[:gdd]}
    
    var_arr = [pre,tmp,gdd]
    images = []
    
    output_image = nil
    
    var_arr.each do |hash|
      values = hash[:data]
      variable = hash[:variable]
      next if values.nil?
      
      png = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::TRANSPARENT)
      
      # get min/max values for current variable
      minmax = getMinMax values
    
      values.each_with_index do |arr, x|
        arr.each_with_index do |value, y|
          y = 228 - y
          png[x,y] = getColor(variable, value, minmax)
        end unless arr.nil?
      end
      images.push(png)
    end
    
    # only pre OR tmp OR gdd is used
    if images.length==1
      output_image = images.first
    else
      # ALL the variables are used -> combine the pngs from the images array
      output_image = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::TRANSPARENT)
      (0..257).each do |x|
        (0..227).each do |y|
          red=0
          green=0
          blue=0
          images.each do |image|
            color = image.get_pixel(x,y)
            next if color==0
            r = ChunkyPNG::Color.r(color)
            g = ChunkyPNG::Color.g(color)
            b = ChunkyPNG::Color.b(color)
            red = r unless r==0
            green = g unless g==0
            blue = b unless b==0
          end
          
          unless red==0 and green==0 and blue==0
            unless red==255 and green==255 and blue==255
              output_image[x,y] = ChunkyPNG::Color.rgba(red, green, blue, 255)
            end
          end
          
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
  
  def getColor variable, value, minmax
    min = minmax[0]
    max = minmax[1]
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
    
    if min < 0
      range = max + min.abs
      percent = (value + min.abs) / range
    else
      range = max - min
      percent = value / range
    end
    
    red = (red*percent).to_i
    green = (green*percent).to_i
    blue = (blue*percent).to_i
    
    ChunkyPNG::Color.rgba(red, green, blue, 255)
  end
end
