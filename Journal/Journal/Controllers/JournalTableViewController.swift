//
//  JournalTableViewController.swift
//  Journal
//
//  Created by Jaswitha Reddy G on 5/2/23.
//

import UIKit

class JournalTableViewController: UITableViewController {
    
    var journal: [Journal] = LocalStorageManager.sharedInstance.journals
    var filteredJournal =  LocalStorageManager.sharedInstance.journals
    let search = UISearchController(searchResultsController: nil)
    var sections: [(month: String, journals: [Journal])] = []
    
    //
    // MARK: - Lifecycle
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(handleRefreshControl),
                                            for: .valueChanged)
        
        // Search Controller
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Type something here to search"
        navigationItem.searchController = search
        
        setupSections()
        showEntriesForToday()
        
        let onThisDayButton = UIBarButtonItem(title: "On This Day", style: .plain, target: self, action: #selector(showOnThisDayEntries))
            navigationItem.rightBarButtonItem = onThisDayButton
    }
    
    @objc func showOnThisDayEntries() {
        showEntriesForToday()
    }
    
    /// Allow the table to be refreshed when navigating back from a segue
    @IBAction func unwindAndReload(unwindSegue: UIStoryboardSegue) {
        reloadDataAndTable()
    }
    
    // This does not work as
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // TODO: Make sure that all the data on the screen is updated to match the data
        reloadDataAndTable()
    }
    
    
    //
    // MARK: - Data Handling
    //
    func reloadDataAndTable() {
        journal = LocalStorageManager.sharedInstance.journals
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    @objc func handleRefreshControl() {
        // Dismiss the refresh control and reload the table
        DispatchQueue.main.async {
            self.tableView.refreshControl?.endRefreshing()
            self.reloadDataAndTable()
        }
        showEntriesForToday()
    }
    
    func setupSections() {
        sections = []
        
        // Sort the journals by date in descending order
        let sortedJournals = journal.sorted { $0.date > $1.date }
        
        // Group journals by month
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        
        var currentMonth = ""
        var currentSectionJournals: [Journal] = []
        
        for journal in sortedJournals {
            let month = dateFormatter.string(from: journal.date)
            
            if month != currentMonth {
                // Start a new section
                if !currentSectionJournals.isEmpty {
                    sections.append((month: currentMonth, journals: currentSectionJournals))
                }
                
                currentMonth = month
                currentSectionJournals = []
            }
            
            currentSectionJournals.append(journal)
        }
        
        if !currentSectionJournals.isEmpty {
            // Add the last section
            sections.append((month: currentMonth, journals: currentSectionJournals))
        }
    }
    
    //
    // MARK: - Table view data source
    //
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if search.isActive && search.searchBar.text != "" {
            return filteredJournal.count
        }
        return sections[section].journals.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].month
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let journal: Journal
        if search.isActive && search.searchBar.text != "" {
            journal = filteredJournal[indexPath.row]
        } else {
            journal = sections[indexPath.section].journals[indexPath.row]
        }
        
        cell.textLabel?.text = journal.note
        
        if let imagePath = journal.imageName {
            cell.imageView?.image = ImageManager.sharedInstance.getImage(imagePath, thumbnail: true)
        } else {
            cell.imageView?.image = nil
        }
        
        return cell
    }
    
    private func showEntriesForToday() {
        let today = Date()
        
        self.filteredJournal = journal.filter { entry in
            let calendar = Calendar.current
            let entryDate = calendar.startOfDay(for: entry.date)
            let todayDate = calendar.startOfDay(for: today)
            return calendar.isDate(entryDate, inSameDayAs: todayDate)
        }
        
        setupSections()
        tableView.reloadData()
    }

}
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    


extension JournalTableViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        print(text)
        filterJournal(for: text)
    }
    
    private func filterJournal(for searchText: String) {
        // TODO: Add ability to filter by `tags` property
        self.filteredJournal = journal.filter { entry in
            // entry.tags
            return entry.note!.lowercased().contains(searchText.lowercased())
        }
        setupSections()
        tableView.reloadData()
    }
}
