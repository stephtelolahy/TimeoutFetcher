// The Swift Programming Language
// https://docs.swift.org/swift-book

import RxSwift

struct MyService {
    let remote: DataFetcherProtocol
    let cache: DataFetcherProtocol
    let reporter: ErrorReporterProtocol

    func getData() -> Observable<String> {
        let remoteFetch = remote.fetch()
            .do(onError: { error in
                reporter.reportError(error)
            })

        let cacheLoad = cache.fetch()
            .catch { _ in
                Observable.never()
            }

        return Observable.amb([remoteFetch, cacheLoad])
    }
}

protocol DataFetcherProtocol {
    func fetch() -> Observable<String>
}

protocol ErrorReporterProtocol {
    func reportError(_ error: Error)
}
