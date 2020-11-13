class SurveyItem
  include Mongoid::Document
  include Mongoid::Timestamps
  field :survey_id, type: BSON::ObjectId
  field :content
end