class Survey
  include Mongoid::Document
  include Mongoid::Timestamps
  field :survey_name, type: String
  field :survey_type, type: String
  field :description, type: String
  field :annotators_per_item, type: Integer
  field :annotations_per_annotator, type: Integer
  field :choices, type: Array
  field :choices_exclusive, type: Boolean
  field :disclaimer_signature_timeout, type: Integer
  field :disclaimer_text, type: String
  
  def default_disclaimer_text
    "<p>The items you will be annotating are taken from social media and misinformation tip lines relating to political and social issues during the 2019 Indian elections as well as events in 2020. Some items may contain offensive, violent, and/or hateful content. If you encounter such content, please flag it by checking the box \"This item contains offensive, violent, and/or hateful content\". If an item is too objectionable or disturbing for you to annotate, skip it by pressing 's'.</p>
    <p>We encourage you to take frequent breaks. You can stop the annotation work at any time, and when you re-open the link you will automatically continue from where you left off.</p>
    <p>If you have any concerns we strongly encourage you to speak to a member of Meedan before starting or at any point in the process.</p>"
  end

  def export_annotations(filename)
    export = {
      survey_name: self.survey_name,
      survey_type: self.survey_type,
      annotators_per_item: self.annotators_per_item,
      annotations_per_annotator: self.annotations_per_annotator,
      choices: self.choices,
      choices_exclusive: self.choices_exclusive,
      items: []
    }
    SurveyItem.where(survey_id: self.id).each do |survey_item|
      export[:items] << {
        content: survey_item.content,
        annotations: Annotation.where(survey_item_id: survey_item.id).collect(&:clean_attributes)
      }
    end
    f = File.open(filename, "w")
    f.write(export.to_json)
    f.close
  end

  def next_annotation(annotator)
    existing_cases = Annotation.where(survey_id: self.id, annotator_id: annotator.id)
    existing_survey_item_ids = existing_cases.collect(&:survey_item_id)
    if self.annotations_per_annotator.nil? || self.annotations_per_annotator > existing_cases.count
      all_items = SurveyItem.where(survey_id: self.id).to_a
      selectable_cases = all_items.reject{|x| existing_survey_item_ids.include?(x.id)}
      if selectable_cases.count > 0
        selectable_cases.to_a.shuffle.first
      else
        return nil
      end
    else
      return nil
    end
  end

  def self.record_response(params, request_ip)
    survey = Survey.find(params[:survey_id])
    survey_item = SurveyItem.find(params[:survey_item_id])
    annotator = Annotator.find(params[:annotator_id])
    selection_indices = params.select{|k,v| v.to_s.include?("response_")}.values.collect{|x| x.split("_").last.to_i}
    manually_entered_fields = Hash[params.select{|k,v| k.include?("specify") && selection_indices.include?(k.split("_")[1].to_i)}.collect{|k,v| [survey.choices[k.split("_")[1].to_i], v]}]
    offensive = (params[:offensive].nil? || params[:offensive].empty?) ? false : true
    if params[:existing_annotation_id]
      Annotation.find(params[:existing_annotation_id]).destroy
    end
    Annotation.new(
      survey_id: survey.id,
      survey_item_id: survey_item.id,
      annotator_id: annotator.id,
      response: selection_indices.empty? ? ["Skip"] : selection_indices.collect{|x| survey.choices[x]},
      ip: request_ip,
      offensive: offensive,
      manual_responses: manually_entered_fields,
      fingerprint: params[:fingerprint],
      render_time: Time.parse(params[:render_time]||Time.now.to_s),
      completion_time: params[:completion_time],
    ).save!
  end

  def self.generate_from_manifest(manifest)
    survey = Survey.new(
      survey_name: manifest["survey_name"],
      survey_type: manifest["survey_type"],
      description: manifest["description"],
      disclaimer_text: manifest["disclaimer_text"],
      annotators_per_item: manifest["annotators_per_item"],
      annotations_per_annotator: manifest["annotations_per_annotator"],
      choices: manifest["choices"],
      choices_exclusive: manifest["choices_exclusive"],
    )
    survey.save!
    manifest["items"].each do |item|
      SurveyItem.new(survey_id: survey.id, content: item).save!
    end
    survey
  end
  
  def self.generate_from_covid_nodes
    rows = CSV.read("/Users/dgaff/Code/claim_review_topic_modeling/covid_nodes.csv")
    items = rows[1..-1].collect{|x| rr = Hash[rows.first.zip(x)]; rr["text"] = rr["Translated Headline"]; rr}
    f = File.open("covid_survey.json", "w")
    f.write({
      survey_name: "COVID Fact Checks",
      survey_type: "categorization",
      annotators_per_item: 4,
      annotations_per_annotator: 100,
      choices: ["Government Actions & Civil Unrest", "Donald Trump", "Europe", "Asia", "Africa", "Home Remedies & Cures & Treatments", "Transmission & Case Counts", "Vaccine", "Origins", "Famous Patients", "Testing"],
      choices_exclusive: false,
      items: items
    }.to_json)
    f.close
  end

  def self.generate_from_claim_annotations
    files = ["translated_sampled_claim_annotation_bengali.csv",
    "translated_sampled_claim_annotation_hindi.csv",
    "translated_sampled_claim_annotation_malayalam.csv",
    "translated_sampled_claim_annotation_portuguese.csv",
    "translated_sampled_claim_annotation_tamil.csv"]
    files.each do |file|
      rows = CSV.read(file)
      items = rows[1..-1].collect{|x| rr = Hash[rows.first.collect{|xx| xx.gsub(".", "_")}.zip(x)]; rr["text"] = rr["Input_text"]; rr}
      f = File.open(file.gsub("csv", "json"), "w")
      f.write({
        survey_name: "Binary Claim Detection, #{file.split("_").last.split(".").first.capitalize}",
        survey_type: "categorization",
        annotators_per_item: 4,
        annotations_per_annotator: 100,
        choices: ["Yes", "No", "Unsure"],
        choices_exclusive: true,
        items: items
      }.to_json)
      f.close
      puts "bundle exec rake import_survey #{file.gsub("csv", "json")}"
    end
  end

  def self.generate_from_claim_annotations
    f = File.open("test.json", "w")
    f.write({
      survey_name: "Test",
      survey_type: "categorization",
      annotators_per_item: 4,
      annotations_per_annotator: 2,
      choices: ["Yes", "No"],
      choices_exclusive: true,
      items: [{text: "This is one"}, {text: "Yet another"}, {text: "And one more"}]
    }.to_json)
    f.close
  end

  def self.generate_from_claim_annotations
    f = File.open("covid_mechanical_turk_check.json", "w")
    rows = CSV.read("mechanical_turk_results.csv")
    hashed = rows[1..-2].collect{|r| h = Hash[rows.first.collect{|rr| rr.gsub(".", "_")}.zip(r)]; h["text"] = h["headline"]; h}
    f.write({
      survey_name: "COVID Fact Checks",
      survey_type: "categorization",
      annotators_per_item: 2,
      annotations_per_annotator: 100,
      choices: ["Government Actions & Civil Unrest", "Donald Trump", "Europe", "Asia", "Africa", "Home Remedies & Cures & Treatments", "Transmission & Case Counts", "Vaccine", "Origins", "Famous Patients", "Testing"],
      choices_exclusive: false,
      items: hashed
    }.to_json)
    f.close
  end
end
