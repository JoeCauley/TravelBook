//
//  TableViewController.swift
//  TravelBook
//
//  Created by Joseph Cauley on 10/7/19.
//  Copyright © 2019 Joseph Cauley. All rights reserved.
//

import UIKit
import CoreData

class TableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var placesTable: UITableView!
    
        //Working arrays to load title and id from Places object
        var titleArray = [String]()
        var idArray = [UUID]()
    
        //Working arrays to send a title and id to Map View to diplay a saved record.
        var chosenTitle = ""
        var chosenId: UUID?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Implement top right add place button
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(goToMapView))
        
        //Assigns placeTable table view as a delegate and datasource or UITableView
        placesTable.delegate = self
        placesTable.dataSource = self

        //Function call to get data from Places Entity in CoreData
        getData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newPlace"), object: nil)
    }
    
    @objc func getData() {
        
        //Standard code to set up connection to CoreData and fetch records.
        //Create an instance of the AppDelegate and context
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(request)
        //If there are records to read...
            if results.count > 0 {
                
        //Do not duplicate data in table
                self.titleArray.removeAll(keepingCapacity: false)
                self.idArray.removeAll(keepingCapacity: false)
                
        //Loop through records in PLaces Entity and fill titleArray and idArray
                for result in results as! [NSManagedObject] {
                    
                    if let title = result.value(forKey: "name") as? String {
                        self.titleArray.append(title)
                    }
                    
                    if let id = result.value(forKey: "id") as? UUID {
                        self.idArray.append(id)
                    }
                    placesTable.reloadData()
                }
            }
        } catch {
            print("Error loading Data") //Not a real catch solution
        }
        
    }
    
    //When top right add button clicked, sends focus to Map View
    @objc func goToMapView () {
        chosenTitle = ""
        performSegue(withIdentifier: "toMapView", sender: nil)
        
    }
    
    //Allocates as many rows as are members of titleArray
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleArray.count
    }
    
    //Creates UITableView cell objects for each member of titleArray and put the title text in each.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = titleArray[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chosenTitle = titleArray[indexPath.row]
        chosenId = idArray[indexPath.row]
        performSegue(withIdentifier: "toMapView", sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapView" {
            let destinationVC = segue.destination as! ViewController
            destinationVC.selectedTitle = chosenTitle
            destinationVC.selectedId = chosenId
            
        }
    }

}
