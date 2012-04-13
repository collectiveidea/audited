require 'mongo_mapper'
puts 'CONNECTION'

MongoMapper.connection = Mongo::Connection.new
MongoMapper.database = 'acts_as_audited'
