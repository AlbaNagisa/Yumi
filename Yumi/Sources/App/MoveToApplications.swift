import AppKit

@MainActor
enum MoveToApplications {
    private static let skipKey = "moveToApplicationsSkipped"

    static func offerIfNeeded() {
        guard !IslandStudio.isOn, !UserDefaults.standard.bool(forKey: skipKey) else { return }
        let bundle = Bundle.main.bundleURL.standardizedFileURL
        let installed = URL(fileURLWithPath: "/Applications").appendingPathComponent(bundle.lastPathComponent)
        let exists = FileManager.default.fileExists(atPath: installed.path)
        let offer = MoveRules.offer(bundlePath: bundle.path, home: NSHomeDirectory(), installedExists: exists,
                                    mineBuild: build(Bundle.main), installedBuild: exists ? build(Bundle(url: installed)) : 0)
        switch offer {
        case .none:
            return
        case .drag:
            _ = ask(loc("Glisse-moi dans Applications"),
                    loc("Je tourne depuis une copie temporaire que macOS a faite de moi. Glisse Yumi.app dans Applications, puis relance-moi."),
                    buttons: [loc("OK")], suppression: false)
        case .move:
            let (response, skip) = ask(loc("Je ne suis pas dans Applications"),
                                       loc("Je tourne depuis \(folderName(bundle)). Rangé dans Applications, je serai plus simple à retrouver et à mettre à jour."),
                                       buttons: [loc("Me ranger dans Applications"), loc("Pas maintenant")])
            if skip { UserDefaults.standard.set(true, forKey: skipKey) }
            guard response == .alertFirstButtonReturn else { return }
            perform { try FileManager.default.moveItem(at: bundle, to: installed) } then: { relaunch(installed) }
        case .replace:
            let (response, skip) = ask(loc("Une version plus ancienne est dans Applications"),
                                       loc("Cette copie (\(version(Bundle.main))) tourne depuis \(folderName(bundle)). Je peux remplacer la version \(version(Bundle(url: installed))) d'Applications et repartir de là."),
                                       buttons: [loc("Remplacer"), loc("Pas maintenant")])
            if skip { UserDefaults.standard.set(true, forKey: skipKey) }
            guard response == .alertFirstButtonReturn else { return }
            perform {
                try FileManager.default.trashItem(at: installed, resultingItemURL: nil)
                try FileManager.default.moveItem(at: bundle, to: installed)
            } then: { relaunch(installed) }
        case .openInstalled:
            let (response, skip) = ask(loc("Une autre copie est dans Applications"),
                                       loc("Cette copie tourne depuis \(folderName(bundle)). Celle d'Applications est la version \(version(Bundle(url: installed))). Je peux ouvrir celle-là et mettre celle-ci à la corbeille."),
                                       buttons: [loc("Ouvrir celle d'Applications"), loc("Continuer ici")])
            if skip { UserDefaults.standard.set(true, forKey: skipKey) }
            guard response == .alertFirstButtonReturn else { return }
            try? FileManager.default.trashItem(at: bundle, resultingItemURL: nil)
            relaunch(installed)
        }
    }

    private static func ask(_ title: String, _ text: String, buttons: [String], suppression: Bool = true) -> (NSApplication.ModalResponse, Bool) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        alert.alertStyle = .informational
        for button in buttons { alert.addButton(withTitle: button) }
        alert.showsSuppressionButton = suppression
        alert.suppressionButton?.title = loc("Ne plus me le demander")
        NSApp.activate()
        let response = alert.runModal()
        return (response, alert.suppressionButton?.state == .on)
    }

    private static func perform(_ work: () throws -> Void, then success: () -> Void) {
        do {
            try work()
            success()
        } catch {
            _ = ask(loc("Je n'ai pas pu me déplacer"), error.localizedDescription, buttons: [loc("OK")], suppression: false)
        }
    }

    private static func folderName(_ bundle: URL) -> String {
        FileManager.default.displayName(atPath: bundle.deletingLastPathComponent().path)
    }

    private static func build(_ bundle: Bundle?) -> Int {
        Int(bundle?.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "") ?? 0
    }

    private static func version(_ bundle: Bundle?) -> String {
        bundle?.object(forInfoDictionaryKey: "YumiDisplayVersion") as? String ?? "?"
    }

    private static func relaunch(_ app: URL) -> Never {
        let quoted = app.path.replacingOccurrences(of: "'", with: "'\\''")
        let pid = ProcessInfo.processInfo.processIdentifier
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "while /bin/kill -0 \(pid) 2>/dev/null; do /bin/sleep 0.2; done; /usr/bin/open '\(quoted)'"]
        try? process.run()
        exit(0)
    }
}
