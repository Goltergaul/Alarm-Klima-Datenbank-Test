def readfile f
  
  handle = File.open(f,"r")
  
  model = "Europe"
  variable = ""
  multi=0.0
  start_year=0
  end_year=0
  scenario = File.basename(f).split(".")[0]
  
  handle.lines.each do |line|
    if index = line.index("Variable=")
      variable = line[(index+10)..(index+12)]
    end
    
    if match = line.match(/Years=(\d+)-(\d+)/)
      start_year = match[1].to_i
      end_year = match[2].to_i
    end
    
    if match = line.match(/Multi=\s*(\d+\.\d+)/)
      multi = match[1].to_f
      break
    end
  end
  
  x = y = year = 0
  handle.lines.each do |line|
    if match = line.match(/Grid-ref=\s*(\d+),\s*(\d+)/)
      x = match[1].to_i
      y = match[2].to_i
      year = start_year
      puts "#{x},#{y}"
    else
      month_values = line.scan(/\w+/)
      12.times do |month|
        value = month_values[month]
        doc = Clima.find_or_create_by_model_and_year_and_month_and_scenario :model => model, :year => year, :month => month+1, :scenario => scenario
        doc.data = Hash.new if !doc.data
        doc.data[variable]= Array.new if !doc.data[variable]
        doc.data[variable][x]= Array.new if !doc.data[variable][x]
        doc.data[variable][x][y] = value
        doc.save!
      end
      year += 1
    end
    
  end
  
  handle.close
end


namespace :alarm do
  desc "Import Alarm Clima Data"
  task :import => :environment do
    Dir.glob("#{Rails.root}/db/alarm/*").each do|f|
      readfile f
    end
  end
end