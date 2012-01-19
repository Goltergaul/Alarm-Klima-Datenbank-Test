class PropvalController < ApplicationController
  respond_to :json, :bson
  
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
    else
      response[:month] = params[:month]
    end
    
    match = Propval.build params[:variable], query
    
    response[:data] = match["results"][0]["value"]
    
    respond_with(response) do |format|
      format.json
      format.bson do
        send_data BSON.serialize(response)
      end
    end
  end
end
