require 'csv'
require 'pry'
require 'sinatra'
require 'sidekiq'
require 'sidekiq/api'
require 'json'
require 'restclient'
require 'mongoid'
require 'dgaff'

Mongoid.load_configuration(clients: {
  default: {
    database: ENV["database"]||"surveyer",
    hosts: [ ENV["mongo_server"]+":27017" ],
  }
})

Dir[File.dirname(__FILE__) + '/handlers/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/extensions/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/models/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/tasks/*.rb'].each {|file| require file }
