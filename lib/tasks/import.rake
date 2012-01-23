load 'config/initializers/mongo.rb'
require 'benchmark'

@store = Hash.new
files = {1 => ["BAMBU.A2.HadCM3.2001-2100.pre", "BAMBU.A2.HadCM3.2001-2100.tmp", "BAMBU.A2.HadCM3.2001-2100.gdd"],
         2 => ["GRAS.A1FI.HadCM3.2001-2100.pre", "GRAS.A1FI.HadCM3.2001-2100.tmp", "GRAS.A1FI.HadCM3.2001-2100.gdd"],
         3 => ["SEDG.B1.HadCM3.2001-2100.pre", "SEDG.B1.HadCM3.2001-2100.tmp", "SEDG.B1.HadCM3.2001-2100.gdd"]}
#@path = "/Users/23tux/Desktop/geodata/"
@path = "#{Rails.root}/db/alarm/"

def readfile f
  
  handle = File.open(f,"r")
  linecount= handle.lines.count
  handle.close
  
  handle = File.open(f,"r")
  
  model = "Europe"
  variable = ""
  multi=0.0
  start_year=0
  end_year=0
  scenario = File.basename(f).split(".")[0]
  currentLine = 0
  
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
  startTime = Time.now
  wholeTime = Time.now
  count = 0
  
  handle.lines.each do |line|
    currentLine += 1
    if currentLine%10000 == 0
      percent = (currentLine.to_f/linecount.to_f*100.0).round(2)
      puts "#{percent}% (#{currentLine}/#{linecount}) of file #{f} done"
    end
    
    if count==0
      match = line.match(/Grid-ref=\s*(\d+),\s*(\d+)/)
      debug "Elapsed time: " + (Time.now - startTime).to_s + "s"
      debug "------------------------------"
      startTime = Time.now
      
      x = match[1].to_i
      y = match[2].to_i
      year = start_year
      debug "@store coordinate: x(#{x}), y(#{y})"
      debug "|"
      debug "|"
      
      # reset counter
      count=101
    else
      month_values = line.scan(/-?\w+/)
      12.times do |month|
        value = month_values[month]
        
        unless @store[model] and @store[model][scenario] and @store[model][scenario][year] and @store[model][scenario][year][month]
          @store[model] = Hash.new unless @store[model]
          @store[model][scenario] = Hash.new unless @store[model][scenario]
          @store[model][scenario][year] = Hash.new unless @store[model][scenario][year]
          @store[model][scenario][year][month] = {:model => model, :year => year, :month => month+1, :scenario => scenario}
          @store[model][scenario][year][month]["data"] = Hash.new
        end
        
        # 2D Array anlegen
        unless @store[model][scenario][year][month]["data"][variable]
          @store[model][scenario][year][month]["data"][variable] = Array.new
          # [Grid X,Y= 258, 228]
          (0..257).each do |i|
            @store[model][scenario][year][month]["data"][variable][i] = Array.new
            @store[model][scenario][year][month]["data"][variable][i][227] = nil
          end
        end
        
        @store[model][scenario][year][month]["data"][variable][x-1][y-1] = (value.to_i * multi).round(2)
      end
      year += 1
    end
    count-=1
  end
  
  debug ""
  debug ""
  debug ""
  debug "================================"
  debug "Import finished in " + (Time.now - wholeTime).to_s + " s"
  
  handle.close
end

def printFilename f
  debug ""
  debug "============================================="
  debug "Importing file: " + File.basename(f)
  debug "============================================="
  debug ""
end

def write2file
  startTime = Time.now
  puts "Writing to #{@path}../tmp/alarm#{ENV["szenario"]}.json"
  handle = File.open(@path + "../tmp/alarm#{ENV["szenario"]}.json", "a")
  @store.each_pair do |model, scenarios|
    scenarios.each_pair do |scenario, years|
      years.each_pair do |year, months|
        months.each_pair do |month, document|
          handle.write JSON(document) + "\n"
        end
      end
    end 
  end
  debug "Time for serializing json was " + (Time.now - startTime).to_s + "s"
  handle.close
end

namespace :alarm do
  desc "Import Alarm Clima Data"
  
  task :import_all => :environment do
    (1..3).each do |i|
      ENV["szenario"] = i.to_s
      Rake::Task["alarm:import"].invoke
    end
  end

  task :import => :environment do
    
    unless ENV.include?("szenario")
      raise "please specify szenario"
    end
    
    files[ENV["szenario"].to_i].each do |f|  
      f = @path + f
      printFilename f
      readfile f
    end
    write2file()
  end
  
end

def debug str
  puts str if ENV.include?("debug") 
end
