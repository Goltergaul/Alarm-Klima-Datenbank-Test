class PropdiffController < ApplicationController
  respond_to :json, :bson
  
  def get
    response = { :prop => "diff",
                 :model_name => params[:model],
                 :scenario_name => params[:scenario],
                 :year_a => params[:year_a].to_i,
                 :year_b => params[:year_b].to_i,
               }
    
    query = {:model => params[:model], :scenario => params[:scenario]}
    query_a = {:year => params[:year_a].to_i}
    query_b = {:year => params[:year_b].to_i}
    query_a.merge! query
    query_b.merge! query
    keep = ""
    
    # format: /propdiff/Mo/Sc/Y1/M1/Y2/M2/Var.Out
    # difference between two month -> result with min, max, avg
    if (1..12).include? params[:function_a].to_i
      query_a[:month] = params[:function_a].to_i
      query_b[:month] = params[:function_b].to_i
    end
    
    match_a = Propval.build params[:variable], query_a
    match_a = match_a["results"][0]["value"]
    match_b = Propval.build params[:variable], query_b
    match_b = match_b["results"][0]["value"]
    
    # delete min, max, or avg
    unless (1..12).include? params[:function_a].to_i or params[:function_a]=="all"
      keep = params[:function_a]
    end
    match = Propval.diff match_a, match_b, keep
    
    response[:data] = match
    
    respond_with(response) do |format|
      format.json
      format.bson do
        send_data BSON.serialize(response)
      end
    end
  end
end
