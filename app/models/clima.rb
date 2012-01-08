class Clima
  include MongoMapper::Document
  
  ensure_index :model
  ensure_index :year
  ensure_index :month
  ensure_index :scenario
  
  key :model, String
  key :scenario, String
  key :year, Integer
  key :month, Integer
  key :data, Hash
  
  def self.getBuilder builder
    case builder
    when "Avg"
      YearlyAverage
    when "Max"
      YearlyMaximum
    when "Min"
      YearlyMinimum 
    end
  end
  
  # calculates difference between two data arrays
  def self.diff a, b
    b.each do |variable, values|
      values.each_with_index do |array, x|
        next if array.nil?
        array.each_with_index do |value, y|
          a[variable][x][y] = b[variable][x][y] - a[variable][x][y]
        end
      end
    end
    
    a
  end
end  