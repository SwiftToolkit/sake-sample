import ArgumentParser
import Foundation
import Sake
import SwiftShell

@CommandGroup
struct ReleaseCommands {
    struct ReleaseArguments: ParsableArguments {
        @Argument(help: "Version number")
        var version: String

        func validate() throws {
            guard version.range(of: #"^\d+\.\d+\.\d+$"#, options: .regularExpression) != nil else {
                throw ValidationError("Invalid version number. It should be in the format 'x.y.z'")
            }
        }
    }

    public static var githubRelease: Command {
        Command(
            description: "Create a GitHub release with binary artifacts",
            dependencies: [
                bumpVersion,
                buildReleaseArtifacts,
                createAndPushTag,
                draftReleaseWithArtifacts,
            ]
        )
    }

    static var bumpVersion: Command {
        Command(
            description: "Bump version",
            skipIf: { context in
                let arguments = try ReleaseArguments.parse(context.arguments)
                try arguments.validate()

                let version = arguments.version
                let versionFilePath = "\(context.projectRoot)/Sources/Version.swift"
                let currentVersion = try String(contentsOfFile: versionFilePath)
                    .split(separator: "\"")[1]
                if currentVersion == version {
                    print("Version is already \(version). Skipping bumping...".ansiBlue)
                    return true
                }

                return false
            },
            run: { context in
                let arguments = try ReleaseArguments.parse(context.arguments)
                try arguments.validate()
                let version = arguments.version

                let versionFilePath = "\(context.projectRoot)/Sources/Version.swift"
                let versionFileContent = """
                // This file is autogenerated. Do not edit.
                let cowsayCLIVersion = "\(version)"

                """
                try versionFileContent.write(toFile: versionFilePath, atomically: true, encoding: .utf8)

                try runAndPrint("git", "add", versionFilePath)
                try runAndPrint("git", "commit", "-m", "chore(release): Bump version to \(version)")
                print("Version bumped to \(version)".ansiBlue)
            }
        )
    }

    static var buildReleaseArtifacts: Command {
        Command(
            description: "Build release artifacts",
            skipIf: { context in
                let arguments = try ReleaseArguments.parse(context.arguments)
                try arguments.validate()
                let version = arguments.version

                let targetsWithExistingArtifacts = Constants.buildTargets.filter { target in
                    let archivePath = context.projectRoot + "/" + executableArchivePath(target: target, version: version)
                    return FileManager.default.fileExists(atPath: archivePath)
                }
                if targetsWithExistingArtifacts.count == Constants.buildTargets.count {
                    print("All artifacts already exist. Skipping build...".ansiBlue)
                    return true
                }

                let existingArtifactTriples = targetsWithExistingArtifacts
                    .map(\.triple)
                context.storage["existing-artifacts-triples"] = existingArtifactTriples
                return false
            },
            run: { context in
                let arguments = try ReleaseArguments.parse(context.arguments)
                try arguments.validate()
                let version = arguments.version

                try FileManager.default.createDirectory(
                    atPath: Constants.buildArtifactsDirectory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                let existingArtifactsTriples = context.storage["existing-artifacts-triples"] as? [String] ?? []
                for target in Constants.buildTargets {
                    if existingArtifactsTriples.contains(target.triple) {
                        print("Skipping \(target.triple) as artifacts already exist".ansiBlue)
                        continue
                    }

                    print("Building executable for \(target.triple)".ansiBlue)
                    try interruptableRunAndPrint("swift", "package", "clean", interruptionHandler: context.interruptionHandler)

                    let swiftBuildFlags = ["--disable-sandbox", "--configuration", "release", "--triple", target.triple]
                    try interruptableRunAndPrint(
                        "swift", "build", swiftBuildFlags,
                        interruptionHandler: context.interruptionHandler
                    )

                    let binPath: String = run("swift", "build", swiftBuildFlags, "--show-bin-path").stdout
                    if binPath.isEmpty {
                        throw NSError(domain: "Fail to get bin path", code: -999)
                    }
                    let executablePath = binPath + "/\(Constants.executableName)"

                    print("Stripping executable for \(target.triple)".ansiBlue)
                    try interruptableRunAndPrint("strip", "-rSTx", executablePath, interruptionHandler: context.interruptionHandler)

                    print("Archiving executable for \(target.triple)".ansiBlue)
                    let executableArchivePath = context.projectRoot + "/" + executableArchivePath(target: target, version: version)
                    try interruptableRunAndPrint(
                        "zip", "-j", executableArchivePath, executablePath,
                        interruptionHandler: context.interruptionHandler
                    )
                }

                print("Release artifacts built successfully at '\(Constants.buildArtifactsDirectory)'".ansiBlue)
            }
        )
    }

    static var createAndPushTag: Command {
        Command(
            description: "Create and push a tag",
            skipIf: { context in
                let arguments = try ReleaseArguments.parse(context.arguments)
                try arguments.validate()

                let version = arguments.version

                let grepResult = run(bash: "git tag | grep \(arguments.version)")
                if grepResult.succeeded {
                    print("Tag \(version) already exists. Skipping creating tag...".ansiBlue)
                    return true
                }

                return false
            },
            run: { context in
                let arguments = try ReleaseArguments.parse(context.arguments)
                try arguments.validate()

                let version = arguments.version

                print("Creating and pushing tag \(version)".ansiBlue)
                try runAndPrint("git", "tag", version)
                try runAndPrint("git", "push", "origin", "tag", version)
                try runAndPrint("git", "push") // push local changes like version bump
                print("Tag \(version) created and pushed".ansiBlue)
            }
        )
    }

    static var draftReleaseWithArtifacts: Command {
        Command(
            description: "Draft a release on GitHub",
            dependencies: [MiseCommands.ensureGhInstalled],
            skipIf: { context in
                let arguments = try ReleaseArguments.parse(context.arguments)
                try arguments.validate()

                let tagName = arguments.version
                let ghViewResult = try run(
                    MiseCommands.miseBin(context),
                    "exec",
                    "--",
                    "gh",
                    "release",
                    "view",
                    tagName
                )
                if ghViewResult.succeeded {
                    print("Release \(tagName) already exists. Skipping...".ansiBlue)
                    return true
                }

                return false
            },
            run: { context in
                let arguments = try ReleaseArguments.parse(context.arguments)
                try arguments.validate()

                print("Drafting release \(arguments.version) on GitHub".ansiBlue)

                let tagName = arguments.version
                let releaseTitle = arguments.version
                let artifactsPaths = Constants.buildTargets
                    .map { target in
                        executableArchivePath(target: target, version: tagName)
                    }
                    .joined(separator: " ")
                let ghReleaseCommand = try """
                "\(MiseCommands.miseBin(context))" exec -- gh release create \
                \(tagName) \(artifactsPaths) \
                --title '\(releaseTitle)' \
                --draft \
                --verify-tag \
                --generate-notes
                """
                try runAndPrint(bash: ghReleaseCommand)

                print("Release \(arguments.version) available on GitHub".ansiBlue)
            }
        )
    }
}

// MARK: - Helpers

extension ReleaseCommands {
    private static func executableArchivePath(target: BuildTarget, version: String) -> String {
        "\(Constants.buildArtifactsDirectory)/\(Constants.executableName)-\(version)-\(target.triple).zip"
    }

    private struct BuildTarget {
        enum Arch {
            case x86
            case arm
        }

        enum OS {
            case macos
            case linux
        }

        let arch: Arch
        let os: OS

        var triple: String {
            switch (arch, os) {
            case (.x86, .macos): "x86_64-apple-macosx"
            case (.arm, .macos): "arm64-apple-macosx"
            case (.x86, .linux): "x86_64-unknown-linux-gnu"
            case (.arm, .linux): "aarch64-unknown-linux-gnu"
            }
        }
    }

    private enum Constants {
        static let swiftVersion = "6.0"
        static let buildArtifactsDirectory = ".build/artifacts"
        static let buildTargets: [BuildTarget] = [
            .init(arch: .arm, os: .macos),
            .init(arch: .x86, os: .macos),
            // .init(arch: .x86, os: .linux),
            // .init(arch: .arm, os: .linux),
        ]
        static let executableOriginalName = "Cowsay"
        static let executableName = "cowsay"
    }
}
