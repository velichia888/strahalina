import Foundation

/// Minimal, hand-rolled loading/error/data state — deliberately not a
/// third-party dependency, a plain enum is all this phase needs.
enum LoadState<T> {
    case loading
    case loaded(T)
    case failed(Error)

    var value: T? {
        if case .loaded(let value) = self { return value }
        return nil
    }
}
