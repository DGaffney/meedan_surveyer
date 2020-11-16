class Util
  def self.build_indices
    SurveyItem.index(survey_id: 1)
    SurveyItem.index(survey_id: 1, id: 1)
    SurveyItem.create_indexes
    Annotation.index(survey_item_id: 1)
    Annotation.index(survey_id: 1, annotator_id: 1)
    Annotation.index(survey_id: 1)
    Annotation.create_indexes
  end

  def self.clear_db
    [Survey, SurveyItem, Annotation, Annotator, DisclaimerSignature].collect(&:destroy_all)
  end
end