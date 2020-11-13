class Annotation
  include Mongoid::Document
  include Mongoid::Timestamps
  field :survey_id, type: BSON::ObjectId
  field :survey_item_id, type: BSON::ObjectId
  field :response
  field :annotator_id, type: BSON::ObjectId
  field :ip, type: String
  field :fingerprint, type: String
  field :render_time, type: Time
  field :completion_time, type: Time
  field :offensive, type: Boolean
  field :manual_responses, type: Hash
  
  def clean_attributes
    self.attributes.except("_id", "survey_id", "survey_item_id")
  end
end