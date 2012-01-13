class MapdiffController < ApplicationController
  respond_to :json, :png
  
  def get
    
    response = { :map => "diff",
                 :model_name => params[:model],
                 :scenario_name => params[:scenario],
                 :year_a => params[:year_a].to_i,
                 :year_b => params[:year_b].to_i,
                 :function_a => params[:function_a],
                 :function_b => params[:function_b] }
    
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

    response[:data] = diff_result

    respond_with(response) do |format|
      format.json
      format.png do
        png = getPNG response[:data], params[:variable]
        send_data png, :type =>"image/png", :disposition => 'inline'
      end
    end
  end
end
