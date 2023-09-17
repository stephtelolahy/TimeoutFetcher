// The Swift Programming Language
// https://docs.swift.org/swift-book

import RxSwift

struct MyService {
    let remote: DataFetcherProtocol
    let cache: LocalStorageProtocol
    let timeout: RxTimeInterval
    let reporter: ErrorReporterProtocol

    func getData() -> Observable<String> {
        let remoteObservable = remote.fetch()
            .do(onNext: { content in
                cache.save(content)
            }, onError: { error in
                reporter.reportError(error)
            })

        let cacheObservable: Observable<String>
        if let cachedData = cache.load() {
            cacheObservable = Observable
                .just(cachedData)
                .delay(timeout, scheduler: MainScheduler.instance)
        } else {
            cacheObservable = Observable.never()
        }

        return Observable.amb([remoteObservable, cacheObservable])
    }
}

protocol DataFetcherProtocol {
    func fetch() -> Observable<String>
}

protocol LocalStorageProtocol {
    func load() -> String?
    func save(_ content: String)
}

protocol ErrorReporterProtocol {
    func reportError(_ error: Error)
}

enum APIError: Error, Equatable {
    case http
    case parsing
}
