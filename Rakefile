load('environment.rb')

task :import_survey do
  ARGV.each do |a|
    task a.to_sym do
    end
  end
  filename = ARGV[1]
  manifest = JSON.parse(File.read(filename))
  survey = Survey.generate_from_manifest(manifest)
  puts survey.id
end

task :generate_annotator do
  ARGV.each do |a|
    task a.to_sym do
    end
  end
  identifier = ARGV[1]
  a = Annotator.new(identifier: identifier)
  a.save!
  puts a.id
end

task :list_surveys do
  Survey.all.each do |survey|
    puts "#{survey.name},#{survey.type},#{survey.id}"
  end
end

task :export_survey do
  ARGV.each do |a|
    task a.to_sym do
    end
  end
  survey_id = ARGV[1]
  Survey.find(survey_id).export_annotations(survey_id+"_export.json")
end

task :clear_database do
  Util.clear_db
  Util.build_indices
end
