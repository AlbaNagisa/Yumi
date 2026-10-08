import Testing

@Suite struct MoveRulesTests {
    let home = "/Users/someone"

    @Test func installedCopiesAreLeftAlone() {
        #expect(MoveRules.offer(bundlePath: "/Applications/Yumi.app", home: home, installedExists: true, mineBuild: 7, installedBuild: 7) == .none)
        #expect(MoveRules.offer(bundlePath: home + "/Applications/Yumi.app", home: home, installedExists: false, mineBuild: 7, installedBuild: 0) == .none)
    }

    @Test func developerBuildsAreLeftAlone() {
        #expect(MoveRules.offer(bundlePath: home + "/Library/Developer/Xcode/DerivedData/Yumi-abc/Build/Products/Debug/Yumi.app", home: home, installedExists: true, mineBuild: 7, installedBuild: 7) == .none)
        #expect(MoveRules.offer(bundlePath: "/tmp/x/build/dd/Build/Products/Release/Yumi.app", home: home, installedExists: false, mineBuild: 7, installedBuild: 0) == .none)
    }

    @Test func aDownloadWithNoInstalledCopyIsOfferedAMove() {
        #expect(MoveRules.offer(bundlePath: home + "/Downloads/Yumi/Yumi.app", home: home, installedExists: false, mineBuild: 7, installedBuild: 0) == .move)
    }

    @Test func aNewerDownloadOffersToReplaceTheInstalledCopy() {
        #expect(MoveRules.offer(bundlePath: home + "/Downloads/Yumi.app", home: home, installedExists: true, mineBuild: 8, installedBuild: 7) == .replace)
    }

    @Test func anOlderOrEqualDownloadOffersToOpenTheInstalledCopy() {
        #expect(MoveRules.offer(bundlePath: home + "/Downloads/Yumi.app", home: home, installedExists: true, mineBuild: 7, installedBuild: 7) == .openInstalled)
        #expect(MoveRules.offer(bundlePath: home + "/Desktop/Yumi.app", home: home, installedExists: true, mineBuild: 6, installedBuild: 7) == .openInstalled)
    }

    @Test func aTranslocatedRunIsToldToDrag() {
        #expect(MoveRules.offer(bundlePath: "/private/var/folders/ab/T/AppTranslocation/1234/d/Yumi.app", home: home, installedExists: false, mineBuild: 7, installedBuild: 0) == .drag)
    }
}
