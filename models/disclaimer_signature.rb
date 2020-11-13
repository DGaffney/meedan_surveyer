class DisclaimerSignature
  include Mongoid::Document
  include Mongoid::Timestamps
  field :survey_id, type: BSON::ObjectId
  field :annotator_id, type: BSON::ObjectId
  field :ip, type: String
  field :fingerprint, type: String
end