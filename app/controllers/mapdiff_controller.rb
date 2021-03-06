class MapdiffController < ApplicationController
  respond_to :json, :png, :bson
  
  def get
    response = { :map => "diff",
                 :model_name => params[:model],
                 :scenario_name => params[:scenario],
                 :year_a => params[:year_a].to_i,
                 :year_b => params[:year_b].to_i
               }
    
    if ["Min", "Max", "Avg"].include? params[:function_a]
      
      response[:function_a] = params[:function_a]
      response[:function_b] = params[:function_b]
      
      query = {
        :year => params[:year].to_i, 
        :model => params[:model], 
        :scenario => params[:scenario]
      }
        
      model_a = Clima.getBuilder params[:function_a]
      model_b = Clima.getBuilder params[:function_b]
      data_a = model_a.build params[:variable], :year => params[:year_a].to_i, 
                                                :model => params[:model], 
                                                :scenario => params[:scenario]
                                                
      data_b = model_b.build params[:variable], :year => params[:year_b].to_i, 
                                                :model => params[:model], 
                                                :scenario => params[:scenario]
                                                
      diff_result = Clima.diff data_a["results"][0]["value"], data_b["results"][0]["value"]
    else
      # params[:function_a] ist in diesem fall der monat
      data_a = Clima.find_by_year_and_month_and_model_and_scenario params[:year_a].to_i, params[:function_a].to_i, params[:model], params[:scenario]
      data_b = Clima.find_by_year_and_month_and_model_and_scenario params[:year_b].to_i, params[:function_b].to_i, params[:model], params[:scenario]
      diff_result = Clima.diff data_a["data"], data_b["data"]
      
      diff_result = removeNonUsedVariables diff_result, params[:variable]
      
      response[:month_a] = params[:function_a]
      response[:month_b] = params[:function_b]
    end

    response[:data] = diff_result

    respond_with(response) do |format|
      format.json
      format.png do
        png = getPNG response[:data]
        send_data png, :type =>"image/png", :disposition => 'inline'
      end
      format.bson do
        send_data BSON.serialize(response)
      end
    end
  end
end
