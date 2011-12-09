def readfile f
  handle = File.open(f,"r")
  variable = ""
  multi=0.0
  start_year=0
  end_year=0
  
  handle.lines.each do |line|
    if index = line.index("Variable=")
      variable = line[(index+10)..(index+12)]
    end
    
    if match = line.match(/Years=(\d+)-(\d+)/)
      start_year = match[1]
      end_year = match[2]
    end
    
    if match = line.match(/Multi=\s*(\d+\.\d+)/)
      multi = match[1]
      break
    end
  end
  
  handle.lines.each do |line|
    if match = line.match(/Grid-ref=\s*(\d+),\s*(\d+)/)
      x = match[1]
      y = match[2]
      puts "x: #{x} y: #{y}"
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