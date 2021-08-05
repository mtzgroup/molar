//
//  MoleculeSelectionViewController.swift
//  MolAR
//
//  Created by Sukolsak on 2/19/21.
//

import UIKit

protocol MoleculeSelectionViewControllerDelegate: AnyObject {
    func moleculeSelectionViewController(_ selectionViewController: MoleculeSelectionViewController, didSelectMolecule: String)
}

class MoleculeSelectionViewController: UITableViewController {
    var molecules: [String] = ["a"]
    var selectedMolecule: String = "a"

    weak var delegate: MoleculeSelectionViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .light))
    }

    override func viewWillLayoutSubviews() {
        preferredContentSize = CGSize(width: 250, height: tableView.contentSize.height)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let molecule = molecules[indexPath.row]
        delegate?.moleculeSelectionViewController(self, didSelectMolecule: molecule)
        dismiss(animated: true, completion: nil)
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return molecules.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) // as! UITableViewCell
        let molecule = molecules[indexPath.row]
        if molecule == selectedMolecule {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        cell.textLabel!.text = molecule
        return cell
    }
}
