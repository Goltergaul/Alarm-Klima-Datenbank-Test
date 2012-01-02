class YearlyAverage  
  def self.map var
  values = "#{var}: this.data.#{var}"
  if var == "all"
    values = "pre: this.data.pre, tmp: this.data.tmp, gdd: this.data.gdd"
  end
<<JScript
    function(){  
        if(this.data.tmp) {
          emit(1,{
            #{values}
          }); 
        }
    }  
JScript
  end  
  
  def self.reduce var
  values = "#{var}: reduceArr[0].#{var}"
  if var == "all"
    values = "pre: reduceArr[0].pre, tmp: reduceArr[0].tmp, gdd: reduceArr[0].gdd"
  end
<<JScript  
    function(key, reduceArr) { 
      var result = { 
        #{values}
      }; 
    
      for(var i=1;i<reduceArr.length;i++) {
        for(var variable in reduceArr[i]) {
          for(var x=0;x<reduceArr[i][variable].length;x++) {
            if(!reduceArr[i][variable][x]) { continue; }
            for(var y=0;y<reduceArr[i][variable][x].length;y++) {
              if(!reduceArr[i][variable][x][y]) {continue;}
              result[variable][x][y] = result[variable][x][y] + reduceArr[i][variable][x][y];
            }
          }
        }
      }
    
      if(reduceArr.length > 1) {
        for(var variable in reduceArr[i]) {
          for(var x=0;x<result[variable].length;x++) {
            if(!result[variable][x]) { continue; }
            for(var y=0;y<result[variable][x].length;y++) {
              result[variable][x][y] = result[variable][x][y] / reduceArr.length;
            }
          }
        }
      }
    
      return result;
    
    } 
JScript
  end  
  
  def self.build variable, query
    Clima.collection.map_reduce(map(variable), reduce(variable), :query => query, :out => {:inline => true}, :raw => true)  
  end
    
end