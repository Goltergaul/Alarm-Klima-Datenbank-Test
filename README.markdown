== Dokumentation Alarm Datenbank

  22. Januar 2012 - Multimedia Technology - Master
  Dominik Goltermann (dgoltermann.mmt-m2011@fh-salzburg.ac.at)
  Hubert Hölzl (hhoelzl.mmt-m2011@fh-salzburg.ac.at)

=== Technologie

Als Framework wurde Ruby on Rails in der Version 3.1.3, Ruby in der Version 1.9.2 und als Datenbank MongoDB in der Version 2.0.1 verwendet. Zur Verbindung von Rails und MongoDB wurde das gem “MongoMapper” eingesetzt, weitere gems wie “json”, “bson” oder “chunky_png” dienen den verschiedenen Ausgabeformaten. Als Testrechner diente ein Intel Core i7-2630QM CPU @ 2.00Ghz (Quadcore) mit 7.7 GB Arbeitsspeicher. Architektur: Ubuntu 11.10 @ x86_64

=== Datenbankstruktur

Da MongoDB eine dokumentbasierende Datenbank ist, konnten wir die Struktur der Collections schon recht ähnlich an die Struktur der Ausgabe selbst anlehnen. Dies hat den Vorteil, dass die Ausgabe sowie die Speicherung der Daten selbst im JSON Format erfolgt, was große Umkonvertierungen bei den Abfragen erspart und sich positiv auf die Perfromance des Systems auswirkt.

Gespeichert werden die Daten in einer einzigen Collections (“climas”) im JSON Format:

  {
  	"_id" : ObjectId("4f16aa9eeea8a88067defc59"),
  	"model" : "Europe",
  	"year" : 2001,
  	"month" : 1,
  	"scenario" : "BAMBU",
  	"data" : {
  		"pre" : [[null,null,null,...,...][null,134.3,null,...,...]],
  		"tmp" : [[null,null,null,...,...][null,134.3,null,...,...]],
  		"gdd" : [[null,null,null,...,...][null,134.3,null,...,...]]
  	}
  }
			
Im Aufbau ist zu erkennen, dass es sich bei den Schlüsseln model, year, month und scenario um redundante Daten handelt, die aufgrund von Performance Vorteilen bewusst mehrfach gespeichert werden. Somit entfällt dass Abfragen über ForeignKeys auf andere Collections. Da jedoch genau diese Schlüssel bei jeder Abfrage benötigt werden, wurden darauf Indexes gesetzt.

Das Feld “data” enthält drei Schlüssel pre, tmp und gdd. Darin befindet sich jeweils ein zweidimensionales Sparse Array (gefüllt mit null und Float Werten). Die Indexes des 2D Arrays repräsentiert die Koordinate auf dem Europa Model.
Datenimport

Der Import der Dateien läuft in zwei Schritten ab. Als Erstes werden die Rohdaten in ein JSON Format umgewandelt, das MongoDB importieren kann, was auch den zeitaufwändigsten Schritt darstellt. Als Zweites werden die erzeugten JSON Dateien in die Datenbank importiert.
Umwandlung der Daten

Die Umwandlung der Daten geschieht mithilfe eines Rake Tasks in der Datei lib/tasks/import.rake. Mit dem Befehl

  rake alarm:import_all

werden alle Dateien importiert. Die Pfade und Dateinamen sind in zwei Variablen (files und @path) am Anfang der Datei definiert. Mit einigen RegExp Regeln wird erkannt, ob es sich bei der aktuellen Zeile um Koordinaten oder um Headerinformationen handelt. Für jedes Model, Szenario, Jahr und Monat wird ein Dokument angelegt. Falls das Dokument schon vorhanden ist, wird es mit den Werten der Koordinaten aktualisiert und abgespeichert.
So ergibt sich die oben genannte Form der JSON Datei.
Import der Daten

Die Umwandlung hat nun drei Dateien erzeugt, die nacheinander mit dem Befehl

  mongo_import -d “#alarm-development” -c climas alarm1.json

import wird.

=== Applikationsstruktur

Die Struktur der Applikation beginnt mit den 4 verschiedenen Routen für die 4 verschiedenen Controller: mapval, mapdiff, propval und propdiff. Diese Routen werden verwendet um die verschiedenen URL Formate zu unterscheiden. In den einzelnen Controllern hingegen wird überprüft ob es sich um Monate oder Funtionen wie Min, Max oder Avg handelt. Als Beispiel dient uns hier der mapval_controller.rb. 

```ruby
  class MapvalController < ApplicationController
    respond_to :json, :png, :bson
  
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
        match = Clima.find_by_year_and_month_and_model_and_scenario(
                                                  params[:year].to_i, 
                                                  params[:month_function].to_i, 
                                                  params[:model], 
                                                  params[:scenario]
                                                )

        match[:data] = removeNonUsedVariables match[:data], params[:variable]

        response[:month] = params[:month_function].to_i
        response[:data] = match[:data]
      end
    
    
        respond_with(response) do |format|
          format.json
          format.bson do
            send_data BSON.serialize(response)
          end
          format.png do
            png = getPNG response[:data]
            send_data png, :type =>"image/png", :disposition => 'inline'
          end
        end
      end
  end
```

Die einzige Methode “get” des Controllers handelt alle Zugriffe. Als erstes wird ein Response Hash angelegt, der im Nachhinein entweder um Monats oder um Funktionsangaben erweitert wird. Dann werden zwei Fälle unterschieden: Handelt es sich um eine Funktion (Min, Max, Avg) oder um einen Monat. Der einfachere Fall ist der Monat. Hier wird die Datenbank (mithilfe des MongoMappers) einfach auf Jahr, Monat, Model und Scenario abgefragt. Ein Helper (removeNonUsedVariables) entfernt nicht benötigte Variablen (Ausnahme: Variable = all). Am Ende der Datei im response Block wird noch auf die verschiedenen Ausgabe Formate abgefragt (dies wird später näher beschrieben).

Der schwierigere Fall ist, wenn es sich um eine Funktion handelt. Bei “Avg” zum Beispiel muss für jede Koordinate im angegebenen Jahr der Durchschnitt berechnet werden. Dies geschieht in der Clima.getBuilder Funktion des Clima Models (app/models/clima.rb). Diese Unterscheidet zwischen den drei Fällen “avg”, “max” und “min” und ruft die passenden Map/Reduce Funktionen auf. Als Beispiel dient hier die Klasse “YearlyMaximum”.

Die Map/Reduce Funktionalität von MongoDB ist eine Lösung um Berechnungen auf der Datenbank auszuführen. Dazu werden JavaScript Funktionen geschrieben, die direkt von der Datenbank ausgeführt werden um das Abfrageergebnis errechnen. In dieser Anwendung ist der Code dieser Funktionen in folgenden Models zu finden: Propval, YearlyAverage, YearlyMaximum und YearlyMinimum.
Ausgabeformate

Es werden drei verschiedene Ausgabe Formate unterstützt: JSON, BSON und PNG. PNG allerdings nur bei den MapDiff und MapVal Controllern. Die Ausgabe für JSON und BSON wird mithilfe des “json” und “bson” gems gelöst. Im respond_with Block eines jeden Controllers wird auf das Format der URL abgefragt, und das passende Gem kümmert sich um den Rest.

Der PNG Output ist erheblich aufwändiger. Hier wird einem Helper (getPNG), definiert in der app/helpers/application_helper.rb, die Daten übergeben, und dieser liefert ein PNG zurück. Dafür wird das gem “chunky_png” verwendet. Der Helper kümmert sich um die verschiedenen Variablen, die Auflösung und die Transparenz der Pixel. Jede Variable repräsentiert einen Kanal im RGB Modus: rot = tmp, grün = pre und blau = gdd. Wenn nur eine Variable abgefragt wird, so wird ein Bild erzeugt dass bei den höchsten Werten (abhängig von der Range aller Werte) die intensivste Farbe und bei den kleinsten Werten die dunkelste Farbe besitzt. Bei allen Werten (die Variable ist als “all”) wird ein Bild mit allen drei Farbkanälen erzeugt.