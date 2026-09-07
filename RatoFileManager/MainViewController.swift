import UIKit

final class MainViewController: UIViewController {
    private enum Constants {
        static let appTitle = "RATO FILE MANAGER"
        static let cellReuseIdentifier = "FileCell"
    }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let fileManager = FileManager.default
    private let documentsURL: URL
    private var currentDirectoryURL: URL
    private var items: [URL] = []

    init() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .standardizedFileURL
        self.documentsURL = documentsURL
        currentDirectoryURL = documentsURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .standardizedFileURL
        self.documentsURL = documentsURL
        currentDirectoryURL = documentsURL
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
        configureNavigationBar()
        configureTableView()
        reloadDirectory()
    }

    private func configureAppearance() {
        view.backgroundColor = UIColor(red: 0.05, green: 0.06, blue: 0.08, alpha: 1)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.05, green: 0.06, blue: 0.08, alpha: 1)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.systemGreen,
            .font: UIFont.boldSystemFont(ofSize: 18)
        ]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .systemGreen
    }

    private func configureNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Criar Pasta",
            style: .plain,
            target: self,
            action: #selector(createFolder)
        )
        updateNavigationTitleAndBackButton()
    }

    private func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorColor = UIColor.systemGreen.withAlphaComponent(0.25)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.cellReuseIdentifier)

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func reloadDirectory() {
        do {
            items = try fileManager.contentsOfDirectory(
                at: currentDirectoryURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ).sorted(by: sortItems)
            updateNavigationTitleAndBackButton()
            tableView.reloadData()
        } catch {
            presentError(title: "Não foi possível abrir a pasta", error: error)
        }
    }

    private func sortItems(_ first: URL, _ second: URL) -> Bool {
        let firstIsDirectory = (try? first.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
        let secondIsDirectory = (try? second.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false

        if firstIsDirectory != secondIsDirectory {
            return firstIsDirectory
        }
        return first.lastPathComponent.localizedCaseInsensitiveCompare(second.lastPathComponent) == .orderedAscending
    }

    private func updateNavigationTitleAndBackButton() {
        let isAtDocumentsRoot = currentDirectoryURL == documentsURL
        title = isAtDocumentsRoot ? Constants.appTitle : currentDirectoryURL.lastPathComponent
        navigationItem.leftBarButtonItem = isAtDocumentsRoot ? nil : UIBarButtonItem(
            title: "Voltar",
            style: .plain,
            target: self,
            action: #selector(goToParentDirectory)
        )
    }

    @objc private func goToParentDirectory() {
        guard currentDirectoryURL != documentsURL else { return }
        currentDirectoryURL.deleteLastPathComponent()
        reloadDirectory()
    }

    @objc private func createFolder() {
        let alert = UIAlertController(
            title: "Nova Pasta",
            message: "Digite o nome da nova pasta.",
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = "Nome da pasta"
            textField.autocapitalizationType = .words
        }
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Criar", style: .default) { [weak self, weak alert] _ in
            guard let self,
                  let rawName = alert?.textFields?.first?.text else { return }

            let folderName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard self.isValidFolderName(folderName) else {
                self.presentMessage(title: "Nome inválido", message: "Escolha um nome que não contenha barras e não seja apenas ponto.")
                return
            }

            do {
                let folderURL = self.currentDirectoryURL.appendingPathComponent(folderName, isDirectory: true)
                try self.fileManager.createDirectory(at: folderURL, withIntermediateDirectories: false)
                self.reloadDirectory()
            } catch {
                self.presentError(title: "Não foi possível criar a pasta", error: error)
            }
        })
        present(alert, animated: true)
    }

    private func isValidFolderName(_ name: String) -> Bool {
        !name.isEmpty && name != "." && name != ".." && !name.contains("/")
    }

    private func presentFileOptions(for fileURL: URL, sourceRect: CGRect) {
        let alert = UIAlertController(
            title: fileURL.lastPathComponent,
            message: "Escolha uma ação.",
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "Compartilhar / Exportar", style: .default) { [weak self] _ in
            self?.share(fileURL)
        })
        alert.addAction(UIAlertAction(title: "Excluir", style: .destructive) { [weak self] _ in
            self?.delete(fileURL)
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))

        configurePopover(alert.popoverPresentationController, sourceView: tableView, sourceRect: sourceRect)
        present(alert, animated: true)
    }

    private func share(_ fileURL: URL) {
        let activityController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        let center = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        configurePopover(activityController.popoverPresentationController, sourceView: view, sourceRect: center)
        present(activityController, animated: true)
    }

    private func delete(_ fileURL: URL) {
        do {
            try fileManager.removeItem(at: fileURL)
            reloadDirectory()
        } catch {
            presentError(title: "Não foi possível excluir o item", error: error)
        }
    }

    private func configurePopover(
        _ popover: UIPopoverPresentationController?,
        sourceView: UIView,
        sourceRect: CGRect
    ) {
        popover?.sourceView = sourceView
        popover?.sourceRect = sourceRect
        popover?.permittedArrowDirections = []
    }

    private func presentError(title: String, error: Error) {
        presentMessage(title: title, message: error.localizedDescription)
    }

    private func presentMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension MainViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellReuseIdentifier, for: indexPath)
        let itemURL = items[indexPath.row]
        let isDirectory = (try? itemURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false

        var configuration = UIListContentConfiguration.subtitleCell()
        configuration.text = itemURL.lastPathComponent
        configuration.textProperties.color = .white
        configuration.secondaryText = isDirectory ? "Pasta" : "Arquivo"
        configuration.secondaryTextProperties.color = .lightGray
        configuration.image = UIImage(systemName: isDirectory ? "folder.fill" : "doc.fill")
        configuration.imageProperties.tintColor = isDirectory ? .systemGreen : .lightGray
        cell.contentConfiguration = configuration
        cell.backgroundColor = .clear
        cell.accessoryType = isDirectory ? .disclosureIndicator : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let itemURL = items[indexPath.row]
        let isDirectory = (try? itemURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false

        if isDirectory {
            currentDirectoryURL = itemURL
            reloadDirectory()
        } else {
            presentFileOptions(for: itemURL, sourceRect: tableView.rectForRow(at: indexPath))
        }
    }
}
