import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    private static let bundledSeedStoreName = "RecipeSaverSeed"

    let container: NSPersistentContainer

    init() {
        let storeURL = Self.persistentStoreURL()
        Self.bootstrapBundledSeedStoreIfNeeded(destinationStoreURL: storeURL)

        container = NSPersistentContainer(name: "RecipeSaver")
        if let description = container.persistentStoreDescriptions.first {
            description.url = storeURL
            description.setOption(
                true as NSNumber,
                forKey: NSMigratePersistentStoresAutomaticallyOption
            )
            description.setOption(
                true as NSNumber,
                forKey: NSInferMappingModelAutomaticallyOption
            )
        }
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("CoreData failed to load: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        migrateHaveAtHomeItems()
    }

    // v2.1: convert any legacy haveAtHome items to needed (safe no-op if none exist)
    private func migrateHaveAtHomeItems() {
        let context = container.viewContext
        let request: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        request.predicate = NSPredicate(format: "state == %@", "haveAtHome")
        guard let items = try? context.fetch(request), !items.isEmpty else { return }
        items.forEach { $0.state = GroceryState.needed.rawValue }
        try? context.save()
    }

    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("CoreData save error: \(error)")
        }
    }

    private static func persistentStoreURL() -> URL {
        NSPersistentContainer
            .defaultDirectoryURL()
            .appendingPathComponent("RecipeSaver.sqlite")
    }

    private static func bootstrapBundledSeedStoreIfNeeded(destinationStoreURL: URL) {
        let fm = FileManager.default
        guard !fm.fileExists(atPath: destinationStoreURL.path) else { return }
        guard let bundledStoreURL = Bundle.main.url(
            forResource: bundledSeedStoreName,
            withExtension: "sqlite"
        ) else { return }

        do {
            try fm.createDirectory(
                at: destinationStoreURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            try fm.copyItem(at: bundledStoreURL, to: destinationStoreURL)

            // Copy WAL sidecars when present so the seed store opens consistently.
            for suffix in ["-wal", "-shm"] {
                let sourcePath = bundledStoreURL.path + suffix
                let destinationPath = destinationStoreURL.path + suffix
                guard fm.fileExists(atPath: sourcePath) else { continue }
                try fm.copyItem(atPath: sourcePath, toPath: destinationPath)
            }
        } catch {
            // Fall back to an empty persistent store if bundle copy fails.
        }
    }
}
