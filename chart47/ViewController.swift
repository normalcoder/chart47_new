import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    lazy var tableView: UITableView = {
        let t = UITableView()
        t.separatorStyle = .none
        t.allowsSelection = false
        t.delegate = self
        t.dataSource = self
        view.addSubview(t)
        return t
    }()
    
    lazy var cells: [ChartCell] = {
        return (0..<1).map { ChartCell($0, scrollView: tableView) }
    }()
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cells[indexPath.section]
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return chartCellHeight
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return tableHeaderHeight
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return TableHeader()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Statistics"
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        tableView.frame = view.bounds
        cells.forEach { $0.redraw() }
    }
}

