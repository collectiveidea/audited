require 'mongo_mapper'

MongoMapper.connection = Mongo::Connection.new
MongoMapper.database = 'acts_as_audited'
