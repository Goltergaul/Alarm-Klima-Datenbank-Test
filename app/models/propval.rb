class Propval
  def self.map var
    values = "{#{var}: {min: null, max: null, sum: 0, cnt: 0}}"
    if var == "all"
      values = "{
        pre: {min: null, max: null, sum: 0, cnt: 0},
        tmp: {min: null, max: null, sum: 0, cnt: 0},
        gdd: {min: null, max: null, sum: 0, cnt: 0}
      }"
    end
<<JScript
  function() {
    if(this.data) {
      var result = #{values};
    
      var doc = this.data;
    
      for(var variable in result) {
        for(var x=0;x<doc[variable].length;x++) {
          if(!doc[variable][x]) { continue; }
          for(var y=0;y<doc[variable][x].length;y++) {
            var value = doc[variable][x][y];
            if(!value) {continue;}
          
            // store for avg calc
            result[variable]["sum"] += value;
            result[variable]["cnt"]++;
          
            // min
            if(result[variable]["min"]==null) {
              result[variable]["min"] = value;
            } else {
              if(value < result[variable]["min"])
                result[variable]["min"] = value;
            }
            // max
            if(result[variable]["max"]==null) {
              result[variable]["max"] = value;
            } else {
              if(value > result[variable]["max"])
                result[variable]["max"] = value;
            }
          }
        }
      }
    
      emit(1, result);
    }
  }
JScript
  end  
  
  def self.reduce
<<JScript  
  function(key, reduceArr) {
    result = reduceArr[0];
  
    // loop through all results
    for(var i=0;i<reduceArr.length;i++) {
      // current document
      var doc = reduceArr[i];

      for(var variable in doc) {
        var value = doc[variable];
      
        // store for avg calc
        result[variable]["sum"] += value["sum"];
        result[variable]["cnt"] += value["cnt"];
        // min
        if(value["min"] < result[variable]["min"])
          result[variable]["min"] = value["min"];
        // max
        if(value["max"] > result[variable]["max"])
          result[variable]["max"] = value["max"];
      }
    }

    return result;

  }
JScript
  end
  
  def self.finalize
<<JScript
  function(key, value) {
    for(var variable in value) {
      var result = value[variable];
      result["avg"] = result["sum"] / result["cnt"];
      delete result["sum"];
      delete result["cnt"];
    }
  
    return value;
  }
JScript
  end
  
  def self.build variable, query
    Clima.collection.map_reduce(map(variable), reduce, :query => query, :out => {:inline => true}, :raw => true, :finalize => finalize)  
  end
    
end