MongoMapper.connection = Mongo::Connection.new('localhost', 27017)
MongoMapper.database = "#alarm-#{Rails.env}"

if defined?(PhusionPassenger)
   PhusionPassenger.on_event(:starting_worker_process) do |forked|
     MongoMapper.connection.connect if forked
   end
end

module BSON
  def self.to_sym
    to_s
  end
end