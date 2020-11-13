class Site < Sinatra::Base
  # sets root as the parent-directory of the current file
  set :root, File.join(File.dirname(__FILE__), '..')
  # sets the view directory correctly
  set :views, Proc.new { File.join(root, "views") } 

  get "/surveys/:survey_id/:annotator_id/skip/:survey_item_id" do
    Survey.record_response(params, request.ip)
    redirect "/surveys/#{params[:survey_id]}/#{params[:annotator_id]}"
  end
  get "/surveys/disclaimer/:survey_id/:annotator_id" do
    @survey = Survey.find(params[:survey_id])
    @annotator = Annotator.find(params[:annotator_id])
    erb :disclaimer, :layout => :'layouts/main'      
  end

  post "/surveys/disclaimer/:survey_id/:annotator_id" do
    ds = DisclaimerSignature.where(
      survey_id: params[:survey_id],
      annotator_id: params[:annotator_id],
      ip: request.ip,
      fingerprint: params[:fingerprint],
    ).first_or_create
    ds.save!
    redirect "/surveys/#{params[:survey_id]}/#{params[:annotator_id]}"
  end

  get "/surveys/:survey_id/:annotator_id" do
    @survey = Survey.find(params[:survey_id])
    @annotator = Annotator.find(params[:annotator_id])
    @disclaimer_signature = DisclaimerSignature.where(survey_id: params[:survey_id], annotator_id: params[:annotator_id]).first
    if @disclaimer_signature.nil? || (@survey.disclaimer_signature_timeout && !@disclaimer_signature.nil? && (Time.now - @disclaimer_signature.created_at) > @survey.disclaimer_signature_timeout)
      redirect "/surveys/disclaimer/#{params[:survey_id]}/#{params[:annotator_id]}"
    end
    begin
      @render_time = Time.now
      @completed_count = Annotation.where(annotator_id: @annotator.id, survey_id: @survey.id).count
      survey_item_count = SurveyItem.where(survey_id: @survey.id).count
      @total = survey_item_count < @survey.annotations_per_annotator ? survey_item_count : @survey.annotations_per_annotator
      @to_go_count = @total-@completed_count
      if params[:annotation_id]
        @cur_annotation = Annotation.find(params[:annotation_id])
        @survey_item = SurveyItem.where(id: @cur_annotation.survey_item_id).first
        @prev_annotation = Annotation.where(annotator_id: @annotator.id, survey_id: @survey.id, :created_at.lt => @cur_annotation.created_at).order_by(:created_at.desc).first
      else
        @survey_item = @survey.next_annotation(@annotator)
        @prev_annotation = Annotation.where(annotator_id: @annotator.id, survey_id: @survey.id).order_by(:created_at.desc).first
      end
      if @survey_item
        erb :annotate, :layout => :'layouts/main'      
      else
        redirect "/done"
      end
    rescue
      erb :error, :layout => :'layouts/main'
    end
  end

  post "/surveys/:survey_id/:annotator_id" do
    begin
      params[:completion_time] = Time.now
      Survey.record_response(params, request.ip)
      redirect "/surveys/#{params[:survey_id]}/#{params[:annotator_id]}"
    rescue
      erb :error, :layout => :'layouts/main'
    end
  end

  get "/done" do
    erb :done, :layout => :'layouts/main'      
  end
  
  not_found do
    erb :error, :layout => :'layouts/main'
  end

  error do
    erb :error, :layout => :'layouts/main'
  end
end