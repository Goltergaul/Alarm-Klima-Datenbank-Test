class MapvalController < ApplicationController
  respond_to :json
  
  def get
    
    response = { :map => "val",
                 :model_name => params[:model],
                 :scenario_name => params[:scenario],
                 :year => params[:year].to_i }
    
    if ["Min", "Max", "Avg"].include? params[:month_function]
      model = Clima.getBuilder params[:month_function]
      match = model.build params[:variable], {
          :year => params[:year].to_i, 
          :model => params[:model], 
          :scenario => params[:scenario]
        }
      response[:function] = params[:month_function]
      response[:data] = match["results"][0]["value"]
    else
      match = Clima.find_by_year_and_month_and_model_and_scenario params[:year].to_i, params[:month_function].to_i, params[:model], params[:scenario]
      response[:month] = params[:month_function].to_i
      response[:data] = match[:data]
    end

    respond_with(response)
  end
end
