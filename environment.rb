require 'csv'
require 'pry'
require 'sinatra'
require 'sidekiq'
require 'sidekiq/api'
require 'json'
require 'nokogiri'
require 'restclient'
require 'mongoid'
require 'dgaff'

Mongoid.load!("mongoid.yml", :development)

Dir[File.dirname(__FILE__) + '/handlers/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/extensions/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/models/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/tasks/*.rb'].each {|file| require file }

def build_indices
  SurveyItem.index(survey_id: 1)
  SurveyItem.index(survey_id: 1, id: 1)
  SurveyItem.create_indexes
  Annotation.index(survey_item_id: 1)
  Annotation.index(survey_id: 1, annotator_id: 1)
  Annotation.index(survey_id: 1)
  Annotation.create_indexes
end