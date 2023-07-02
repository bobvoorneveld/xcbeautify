import Foundation

struct GitHubRenderer: OutputRendering {
    private enum AnnotationType: String {
        case notice
        case warning
        case error
    }

    let colored: Bool = false

    private func outputGitHubActionsLog(
        annotationType: AnnotationType,
        fileComponents: FileComponents? = nil,
        message: String
    ) -> String {
        let formattedFileComponents = fileComponents?.formatted ?? ""
        return "::\(annotationType) \(formattedFileComponents)::\(message)"
    }

    func formatCompileError(group: CompileErrorCaptureGroup, additionalLines: @escaping () -> (String?)) -> String {
        let filePath = group.filePath
        let fileComponents = filePath.asFileComponents()
        let reason = group.reason

        // Read 2 additional lines to get the error line and cursor position
        let line: String = additionalLines() ?? ""
        let cursor: String = additionalLines() ?? ""

        let message = """
            \(Symbol.asciiError): \(reason)
            \(line)
            \(cursor)
            """

        return outputGitHubActionsLog(
            annotationType: .error,
            fileComponents: fileComponents,
            message: message
        )
    }

    func formatCompileWarning(group: CompileWarningCaptureGroup, additionalLines: @escaping () -> (String?)) -> String {
        let filePath = group.filePath
        let fileComponents = filePath.asFileComponents()
        let reason = group.reason

        // Read 2 additional lines to get the warning line and cursor position
        let line: String = additionalLines() ?? ""
        let cursor: String = additionalLines() ?? ""

        let message = """
            \(Symbol.asciiWarning): \(reason)
            \(line)
            \(cursor)
            """

        return outputGitHubActionsLog(
            annotationType: .warning,
            fileComponents: fileComponents,
            message: message
        )
    }

    func formatCompleteError(line: String) -> String {
        return outputGitHubActionsLog(
            annotationType: .error,
            message: Symbol.asciiError + " " + line
        )
    }

    func formatCompleteWarning(line: String) -> String {
        return outputGitHubActionsLog(
            annotationType: .warning,
            message: Symbol.asciiWarning + " " + line
        )
    }

    func formatDuplicateLocalizedStringKey(group: DuplicateLocalizedStringKeyCaptureGroup) -> String {
        let message = group.warningMessage
        return outputGitHubActionsLog(
            annotationType: .warning,
            message: Symbol.asciiWarning + " " + message
        )
    }

    func formatError(group: ErrorCaptureGroup) -> String {
        let errorMessage = group.wholeError
        return outputGitHubActionsLog(
            annotationType: .error,
            message: Symbol.asciiError + " " + errorMessage
        )
    }

    func formatFailingTest(group: FailingTestCaptureGroup) -> String {
        let indent = "    "
        let file = group.file
        let fileComponents = file.asFileComponents()
        let testCase = group.testCase
        let failingReason = group.reason
        let message = indent + TestStatus.fail + " "  + testCase + ", " + failingReason
        return outputGitHubActionsLog(
            annotationType: .error,
            fileComponents: fileComponents,
            message: message
        )
    }

    func formatFileMissingError(group: FileMissingErrorCaptureGroup) -> String {
        let reason = group.reason
        let filePath = group.filePath
        let fileComponents = filePath.asFileComponents()
        let message = "\(Symbol.asciiError): \(reason)"
        return outputGitHubActionsLog(
            annotationType: .error,
            fileComponents: fileComponents,
            message: message
        )
    }

    func formatLdWarning(group: LDWarningCaptureGroup) -> String {
        let prefix = group.ldPrefix
        let warningMessage = group.warningMessage
        let message = "\(Symbol.asciiWarning) \(prefix)\(warningMessage)"
        return outputGitHubActionsLog(
            annotationType: .warning,
            message: message
        )
    }

    func formatLinkerDuplicateSymbolsError(group: LinkerDuplicateSymbolsCaptureGroup) -> String {
        let reason = group.reason
        let message = "\(Symbol.asciiError) \(reason)"
        return outputGitHubActionsLog(annotationType: .error, message: message)
    }

    func formatLinkerUndefinedSymbolsError(group: LinkerUndefinedSymbolsCaptureGroup) -> String {
        let reason = group.reason
        let message = "\(Symbol.asciiError) \(reason)"
        return outputGitHubActionsLog(annotationType: .error, message: message)
    }

    func formatParallelTestCaseFailed(group: ParallelTestCaseFailedCaptureGroup) -> String {
        let testCase = group.testCase
        let device = group.device
        let time = group.time
        let message = "    \(TestStatus.fail) \(testCase) on '\(device)' (\(time) seconds)"
        return outputGitHubActionsLog(
            annotationType: .error,
            message: message
        )
    }

    func formatParallelTestingFailed(line: String, group: ParallelTestingFailedCaptureGroup) -> String {
        return outputGitHubActionsLog(
            annotationType: .error,
            message: line
        )
    }

    func formatRestartingTest(line: String, group: RestartingTestCaptureGroup) -> String {
        let indent = "    "
        let message = indent + TestStatus.fail + " "  + line
        return outputGitHubActionsLog(
            annotationType: .error,
            message: message
        )
    }

    func formatUIFailingTest(group: UIFailingTestCaptureGroup) -> String {
        let indent = "    "
        let file = group.file
        let fileComponents = file.asFileComponents()
        let failingReason = group.reason
        let message = indent + TestStatus.fail + ": " + failingReason
        return outputGitHubActionsLog(
            annotationType: .error,
            fileComponents: fileComponents,
            message: message
        )
    }

    func formatWarning(group: GenericWarningCaptureGroup) -> String {
        let warningMessage = group.wholeWarning
        let message = Symbol.asciiWarning + " " + warningMessage
        return outputGitHubActionsLog(
            annotationType: .warning,
            message: message
        )
    }

    func formatWillNotBeCodesignWarning(group: WillNotBeCodeSignedCaptureGroup) -> String {
        let warningMessage = group.wholeWarning
        let message = Symbol.asciiWarning + " " + warningMessage
        return outputGitHubActionsLog(
            annotationType: .warning,
            message: message
        )
    }

    func format(testSummary: TestSummary) -> String {
        if testSummary.isSuccess() {
            let message = "Tests Passed: \(testSummary.description)"
            return outputGitHubActionsLog(annotationType: .notice, message: message)
        } else {
            let message = "Tests Failed: \(testSummary.description)"
            return outputGitHubActionsLog(annotationType: .error, message: message)
        }
    }
}

extension GitHubRenderer {
    func formatTestSummary(isSuccess: Bool, description: String) -> String {
        if isSuccess {
            return outputGitHubActionsLog(
                annotationType: .notice,
                message: colored ? "Tests Passed: \(description)".s.Bold.f.Green : "Tests Passed: \(description)"
            )
        } else {
            return outputGitHubActionsLog(
                annotationType: .error,
                message: colored ? "Tests Failed: \(description)".s.Bold.f.Red : "Tests Failed: \(description)"
            )
        }
    }
}


private struct FileComponents {
    private let path: String
    private let line: Int?
    private let column: Int?

    init(path: String, line: Int?, column: Int?) {
        self.path = path
        self.line = line
        self.column = column
    }

    var formatted: String {
        guard let line else {
            return "file=\(path)"
        }

        guard let column else {
            return "file=\(path),line=\(line)"
        }

        return "file=\(path),line=\(line),col=\(column)"
    }
}

private extension String {

    func asFileComponents() -> FileComponents {
        let _components = self.split(separator: ":").map(String.init)
        assert((1...3).contains(_components.count))

        guard let path = _components[safe: 0] else {
            return FileComponents(path: self, line: nil, column: nil)
        }

        let components = _components.dropFirst().compactMap(Int.init)
        assert((0...2).contains(components.count))

        return FileComponents(path: path, line: components[safe: 0], column: components[safe: 1])
    }

}
