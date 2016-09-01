//
//  InterfaceController.swift
//  DCTrains WatchKit Extension
//
//  Created by Peter Olsen on 12/19/15.
//  Copyright © 2015 Peter Olsen. All rights reserved.
//

import WatchKit
import Foundation


class TableRowController: NSObject {
    @IBOutlet weak var destination: WKInterfaceLabel!
    @IBOutlet weak var minutes: WKInterfaceLabel!
}

class IncidentController: NSObject {
    @IBOutlet weak var text: WKInterfaceLabel!
}


class InterfaceController: WKInterfaceController {
    @IBOutlet var incidents: WKInterfaceTable?
    @IBOutlet var ballstonWest: WKInterfaceTable?
    @IBOutlet var ballstonEast: WKInterfaceTable?
    @IBOutlet var tysons: WKInterfaceTable?
    @IBOutlet var metroCenter: WKInterfaceTable?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        if ballstonWest != nil {
            loadDataFor(ballstonWest!, station: "K04", track: "2")
        } else if ballstonEast != nil {
            loadDataFor(ballstonEast!, station: "K04", track: "1")
        } else if tysons != nil {
            loadDataFor(tysons!, station: "N02", track: "1")
        } else if metroCenter != nil {
            loadDataFor(metroCenter!, station: "C01", track: "2")
        } else if incidents != nil {
            loadIncidents(incidents!)
        }
    }
    
    func loadDataFor(_ table: WKInterfaceTable, station: String, track: String) {
        func setTableText(_ s: String) {
            table.setNumberOfRows(1, withRowType: "default")
            let row = table.rowController(at: 0) as! TableRowController
            row.destination.setText(s)
            row.minutes.setText(" ")
        }
        
        setTableText("Loading...")
        
        let urlPath = "https://api.wmata.com/StationPrediction.svc/json/GetPrediction/\(station)"
        guard let url = URL(string: urlPath) else {
            setTableText("Bad URL")
            return
        }
        let config = URLSessionConfiguration.ephemeral
        config.httpAdditionalHeaders = ["api_key": api_key]
        config.timeoutIntervalForRequest = TimeInterval(5)
        
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: url, completionHandler: {
            data, response, error in
            
            var results: [(line: String, dest: String, min: String)] = []
            
            guard let data = data else {
                setTableText("No data")
                return
            }
            
            var json: Any
            do {
                json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
            } catch {
                setTableText("Bad JSON")
                return
            }
            
            guard let dict = json as? NSDictionary else {
                setTableText("Bad return")
                return
            }
            
            guard let trainArray = dict["Trains"] as? NSArray else {
                setTableText("Bad trains")
                return
            }
            
            for trainDict in trainArray {
                guard let train = trainDict as? NSDictionary else {
                    setTableText("Bad train")
                    return
                }
                guard var destination = train["Destination"] as? String else {
                    setTableText("Bad dest")
                    return
                }
                switch destination {
                case "ssenger":
                    destination = "NoPassngrs"
                default:
                    break
                }
                
                guard let line = train["Line"] as? String else {
                    setTableText("Bad line")
                    return
                }
                
                guard let group = train["Group"] as? String else {
                    setTableText("Bad group")
                    return
                }
                guard var minutes = train["Min"] as? String else {
                    setTableText("Bad min")
                    return
                }
                minutes = minutes.capitalized
                
                if group == track {
                    results.append((line: line, dest: destination, min: minutes))
                }
            }
            if results.count == 0 {
                setTableText("No trains")
                return
            }
            table.setNumberOfRows(results.count, withRowType: "default")
            for (index, result) in results.enumerated() {
                let row = table.rowController(at: index) as! TableRowController
                let lineColor: UIColor
                switch result.line {
                case "SV":
                    lineColor = UIColor.lightGray
                case "OR":
                    lineColor = UIColor.orange
                case "BL":
                    lineColor = UIColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0)
                case "RD":
                    lineColor = UIColor.red
                case "GR":
                    lineColor = UIColor.green
                case "YL":
                    lineColor = UIColor.yellow
                default:
                    lineColor = UIColor.white
                }
                let dest = NSAttributedString(string: result.dest, attributes: [NSForegroundColorAttributeName:lineColor])
                row.destination.setAttributedText(dest)
                row.minutes.setText(result.min)
            }
        })
        task.resume()
    }
    
    func loadIncidents(_ table: WKInterfaceTable) {
        func setTableText(_ s: String) {
            table.setNumberOfRows(1, withRowType: "default")
            let row = table.rowController(at: 0) as! IncidentController
            row.text.setText(s)
        }
        
        setTableText("Loading...")
        
        let urlPath = "https://api.wmata.com/Incidents.svc/json/Incidents"
        guard let url = URL(string: urlPath) else {
            setTableText("Bad URL")
            return
        }
        let config = URLSessionConfiguration.ephemeral
        config.httpAdditionalHeaders = ["api_key": api_key]
        config.timeoutIntervalForRequest = TimeInterval(5)
        
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: url, completionHandler: {
            data, response, error in
            
            var results: [String] = []
            
            if error != nil {
                setTableText(error!.localizedDescription)
                return
            }
            
            guard let data = data else {
                setTableText("No data")
                return
            }
            
            var json: Any
            do {
                json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
            } catch {
                setTableText("Bad JSON")
                return
            }
            
            guard let dict = json as? NSDictionary else {
                setTableText("Bad return")
                return
            }
            
            guard let incidentArray = dict["Incidents"] as? NSArray else {
                setTableText("Bad incidents")
                return
            }
            
            for incidentDict in incidentArray {
                guard let incident = incidentDict as? NSDictionary else {
                    setTableText("Bad incident")
                    return
                }
                guard let description = incident["Description"] as? String else {
                    setTableText("Bad description")
                    return
                }
                results.append(description)
            }
            if results.count == 0 {
                setTableText("No incidents")
                return
            }
            table.setNumberOfRows(results.count, withRowType: "default")
            for (index, result) in results.enumerated() {
                let row = table.rowController(at: index) as! IncidentController
                row.text.setText(result)
            }
        })
        task.resume()
    }
    
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
}
