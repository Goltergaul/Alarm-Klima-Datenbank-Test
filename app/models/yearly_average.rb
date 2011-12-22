class YearlyAverage  
  def self.map  
<<JScript
    function(){  
        if(this.data.pre) {
          emit(1,{pre: this.data.pre}); 
        }
    }  
JScript
  end  
  
  def self.reduce   
<<JScript  
    function(key, reduceArr) { 
      var result = { pre: reduceArr[0].pre }; 
    
      for(var i=1;i<reduceArr.length;i++) {
        for(var x=0;x<reduceArr[i].pre.length;x++) {
          if(!reduceArr[i].pre[x]) { continue; }
          for(var y=0;y<reduceArr[i].pre[x].length;y++) {
            if(!reduceArr[i].pre[x][y]) {continue;}
            result.pre[x][y] = result.pre[x][y] + reduceArr[i].pre[x][y];
          }
        }
      }
    
      if(reduceArr.length > 1) {
        for(var x=0;x<result.pre.length;x++) {
          if(!result.pre[x]) { continue; }
          for(var y=0;y<result.pre[x].length;y++) {
            result.pre[x][y] = result.pre[x][y] / reduceArr.length;
          }
        }
      }
    
      return result;
    
    } 
JScript
  end  
  
  def self.build query
    Clima.collection.map_reduce(map, reduce, :query => query, :out => {:inline => true}, :raw => true)  
  end
    
end