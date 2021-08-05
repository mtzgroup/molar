//
//  GalleryViewController.swift
//  MolAR
//
//  Created by Sukolsak on 3/10/21.
//

import UIKit
import QuickLook

protocol GalleryViewControllerDelegate: AnyObject {
    func galleryViewController(_ galleryViewController: GalleryViewController, didSelectItem: Item)
}


class GalleryViewController: UICollectionViewController, UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate, GalleryViewControllerDelegate {

    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>! = nil

    private var category: String?
    private var items: [Item] = []
    private var defaultItems: [Item] = []
    private var isSearchResults = false
    private var searchController: UISearchController!
    private var searchResultController: GalleryViewController!
    private var searchQuery = ""
    private var selectedURL: URL? = nil
    private var viewMode: Int = 0

    weak var delegate: GalleryViewControllerDelegate?

    func setItems(_ items: [Item]) {
        self.items = items
        var initialSnapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        initialSnapshot.appendSections([.main])
        initialSnapshot.appendItems(items)
        dataSource.apply(initialSnapshot, animatingDifferences: false)
    }

    static func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0 / 3.0),
                                             heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .fractionalWidth(1.0 / 3.0))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                         subitems: [item])

        let section = NSCollectionLayoutSection(group: group)

        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }

    static private func layoutForViewMode(_ viewMode: Int) -> UICollectionViewLayout {
        if viewMode == 1 {
            return createLayout();
        }
        let config = UICollectionLayoutListConfiguration(appearance: .plain)
        return UICollectionViewCompositionalLayout.list(using: config)
        

//        let tmp = UICollectionViewFlowLayout()
//        tmp.itemSize = CGSize(width: 150.0, height: 150.0)
//        return tmp
    }

    private func updateRightBarButton() {
        if category == nil {
            return
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: (viewMode == 0) ? "square.grid.2x2.fill" : "list.bullet"), style: .plain, target: self, action: #selector(switchView))
    }

    init(_ isSearchResults: Bool = false) {
        //super.init(collectionViewLayout: Self.createLayout())
        //let config = UICollectionLayoutListConfiguration(appearance: .plain)
        //super.init(collectionViewLayout: UICollectionViewCompositionalLayout.list(using: config))

        super.init(collectionViewLayout: Self.layoutForViewMode(viewMode))
        self.isSearchResults = isSearchResults
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        //collectionView.collectionViewLayout = Self.createLayout()

        collectionView.backgroundColor = .systemBackground


        if !isSearchResults {
            searchResultController = GalleryViewController(true)
            searchResultController.delegate = self

            searchController = UISearchController(searchResultsController: searchResultController)
            searchController.delegate = self
            searchController.searchResultsUpdater = self
            searchController.searchBar.autocapitalizationType = .none
            searchController.obscuresBackgroundDuringPresentation = false
            searchController.searchBar.placeholder = "Molecule name, SMILES, PDB ID" //"Enter a molecule name or a PDB ID"
            searchController.searchBar.delegate = self

            navigationItem.searchController = searchController
            updateRightBarButton()
            navigationItem.hidesSearchBarWhenScrolling = false

            definesPresentationContext = true

            if category == nil {
                navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "info.circle"), style: .plain, target: self, action: #selector(showAbout))
            }
        }


        //tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")


        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { (cell, indexPath, item) in
            var content = cell.defaultContentConfiguration() //UIListContentConfiguration.cell()
            //content.directionalLayoutMargins = .zero
            //content.axesPreservingSuperviewLayoutMargins = []

            if item.isSuggestion {
                content.text = item.text
                cell.accessories = []
            } else if item.isFolder {
                content.text = item.text
                cell.accessories = [.disclosureIndicator()]
            } else {
                cell.accessories = []
            }

            if !item.isSuggestion && (!item.isFolder || item.preview != nil) {
                if self.viewMode == 0 {
                    content.text = item.text
                    content.imageProperties.maximumSize = CGSize(width: 50.0, height: 50.0)
                } else {
                    content.text = nil
                    content.imageProperties.maximumSize = CGSize.zero
                }

                if let image = item.getLocalImage() {
                    content.image = image
                } else {
                    content.image = item.image
                    ImageCache.publicCache.load(url: item.imageURL() as NSURL, item: item) { image in
                        if let image = image, image != item.image {
                            var updatedSnapshot = self.dataSource.snapshot()
                            if let datasourceIndex = updatedSnapshot.indexOfItem(item) {
                                let item = self.items[datasourceIndex]
                                item.image = image
                                updatedSnapshot.reloadItems([item])
                                self.dataSource.apply(updatedSnapshot, animatingDifferences: false)
                            }
                        }
                    }
                }
            } else if item.isFolder {
                content.image = UIImage(systemName: "folder")!
                content.imageProperties.maximumSize = CGSize.zero
            } else {
                content.image = nil
                content.imageProperties.maximumSize = CGSize.zero
            }

            cell.contentConfiguration = content
        }

        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: Item) -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }

        /*
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) {
            (tableView: UITableView, indexPath: IndexPath, item: Item) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            /// - Tag: update
            var content = cell.defaultContentConfiguration()
            content.image = item.image
            ImageCache.publicCache.load(url: item.url as NSURL, item: item) { (fetchedItem, image) in
                if let img = image, img != fetchedItem.image {
                    var updatedSnapshot = self.dataSource.snapshot()
                    if let datasourceIndex = updatedSnapshot.indexOfItem(fetchedItem) {
                        let item = self.items[datasourceIndex]
                        item.image = img
                        updatedSnapshot.reloadItems([item])
                        self.dataSource.apply(updatedSnapshot, animatingDifferences: false)
                    }
                }
            }
            cell.contentConfiguration = content
            return cell
        }
 */

        //dataSource.defaultRowAnimation = .fade

        if !isSearchResults {
            defaultItems += Database.getItems(category: category)
            setItems(defaultItems)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !isSearchResults && searchController.isActive { // To fix the highlight not disappearing bug.
            guard let indexPaths = searchResultController.collectionView.indexPathsForSelectedItems else { return }
            for indexPath in indexPaths {
                searchResultController.collectionView.deselectItem(at: indexPath, animated: true)
            }
        }
    }

    // MARK: - Search stuff

    func updateSearchResults(for searchController: UISearchController) {
        let originalQuery = searchController.searchBar.text!
        if originalQuery == searchQuery {
            return
        }
        searchQuery = originalQuery
        let query = originalQuery.trimmingCharacters(in: CharacterSet.whitespaces)

        if isNamePotentiallyPDB(query) {
            let url = URL(string: "https://www.rcsb.org/search/suggester/rcsb_entry_container_identifiers.entry_id/" + query.lowercased())!
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                DispatchQueue.main.async {
                    if originalQuery != self.searchQuery {
                        return
                    }

                    guard let data = data,
                          let httpURLResponse = response as? HTTPURLResponse,
                          httpURLResponse.statusCode == 200 else {
                        self.searchResultController.setItems([])
                        return
                    }
                    let jsonData = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
                    if let topJSON = jsonData as? [Any] {
                        let suggestionItems: [Item] = topJSON.compactMap { x in
                            if let x = x as? String {
                                let name = x.replacingOccurrences(of: "<em>", with: "").replacingOccurrences(of: "</em>", with: "")
                                let item = Item(name: name.lowercased(), text: name, isPDB: true)
                                item.isSuggestion = true
                                return item
                            }
                            return nil
                        }

                        self.searchResultController.setItems(suggestionItems)
                        let collectionView = self.searchResultController.collectionView!
                        collectionView.contentOffset = CGPoint(x: 0, y: -collectionView.adjustedContentInset.top)
                    } else {
                        self.searchResultController.setItems([])
                    }

                }
            }
            task.resume()

        } else {
            let tmp = Database.search(query, isSuggestion: false)
            self.searchResultController.setItems(tmp)
            let collectionView = self.searchResultController.collectionView!
            collectionView.contentOffset = CGPoint(x: 0, y: -collectionView.adjustedContentInset.top)
        }
    }

    private func commitSearch(_ originalQuery: String) {
        //let originalQuery = searchBar.text!
        if originalQuery.count == 0 {
            //setItems(defaultItems)
            self.searchResultController.setItems([])
            return
        }

        let query = originalQuery.trimmingCharacters(in: CharacterSet.whitespaces)

        if isNamePDB(query) { // Not necessary. But just to reduce workload of our server.
            let url = URL(string: "https://data.rcsb.org/rest/v1/core/entry/" + query.lowercased())!
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                // TODO: Check if it's still the current query.
                guard let data = data,
                      let httpURLResponse = response as? HTTPURLResponse,
                      httpURLResponse.statusCode == 200 else {
                    // FIXME: Let users know
                    DispatchQueue.main.async {
                        //self.setItems([])
                        self.searchResultController.setItems([])
                    }
                    return
                }
                //print(String(data: data, encoding: .utf8)!)
                let jsonData = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
                if let topJSON = jsonData as? [String: Any],
                   let tmpStruct = topJSON["struct"] as? [String: Any],
                   let title = tmpStruct["title"] as? String {
                    DispatchQueue.main.async {
                        let searchResults = [Item(name: query.lowercased(), text: title, isPDB: true)]
                        //self.setItems(searchResults)
                        self.searchResultController.setItems(searchResults)
                    }
                } else {
                    DispatchQueue.main.async {
                        //self.setItems([])
                        self.searchResultController.setItems([])
                    }
                }
            }
            task.resume()
        } else {
            let tmp = Database.search(query, isSuggestion: false)
            self.searchResultController.setItems(tmp)
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        commitSearch(searchBar.text!)
    }

    // MARK: - UICollectionView

    private func viewControllerForItem(_ item: Item) -> UIViewController {
        if item.isFolder {
            let vc = GalleryViewController()
            vc.category = item.name
            vc.title = item.name
            return vc
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "moleculeViewController") as! MoleculeViewController
        vc.item = item
        return vc
    }

    private func selectItem(_ item: Item) {
        let vc = viewControllerForItem(item)
        self.navigationController?.pushViewController(vc, animated: true)
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        if !isSearchResults {
            selectItem(item)
        } else {
            delegate?.galleryViewController(self, didSelectItem: item)
        }
    }

    func galleryViewController(_ galleryViewController: GalleryViewController, didSelectItem item: Item) {
        selectItem(item)
    }

    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return nil }

        let vc = viewControllerForItem(item)
        let config = UIContextMenuConfiguration(identifier: "preview" as NSString,
                    previewProvider: { vc }, actionProvider: nil)
        return config
    }

    override func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        if let vc = animator.previewViewController {
            animator.addCompletion {
                let nav = self.navigationController ?? self.presentingViewController?.navigationController
                nav?.pushViewController(vc, animated: true)
            }
        }
    }

    @objc private func switchView() {
        viewMode = (viewMode + 1) % 2
        collectionView.collectionViewLayout = Self.layoutForViewMode(viewMode)
        updateRightBarButton()

        var updatedSnapshot = dataSource.snapshot()
        updatedSnapshot.reloadItems(items)
        dataSource.apply(updatedSnapshot, animatingDifferences: false)
    }

    @objc private func showAbout() {
        let vc = AboutViewController()
        vc.title = "Information"
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissAbout))

        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true, completion: nil)
    }

    @objc private func dismissAbout() {
        dismiss(animated: true, completion: nil)
    }
}
