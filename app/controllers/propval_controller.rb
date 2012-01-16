class PropvalController < ApplicationController
  respond_to :json
  
  def get
    response = {
      :prop => "val",
      :model_name => params[:model],
      :scenario_name => params[:scenario]
    }
    
    query = {
      :model => params[:model], :scenario => params[:scenario]
    }
    
    if params[:year]!="all"
      response[:year] = params[:year].to_i
      query[:year] = params[:year].to_i
    end
    
    if params[:month]!="all"
      response[:month] = params[:month].to_i
      query[:month] = params[:month].to_i
    end
    
    match = Propval.build params[:variable], query
    
    response[:data] = match["results"][0]["value"]
    
    respond_with(response)
  end
end
