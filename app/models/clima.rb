class Clima
  include MongoMapper::Document
  
  key :model, String
  key :scenario, String
  key :year, Integer
  key :month, Integer
  key :data, Hash
end