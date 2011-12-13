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
end