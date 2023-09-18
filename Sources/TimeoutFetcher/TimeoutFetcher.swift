// The Swift Programming Language
// https://docs.swift.org/swift-book

import RxSwift

protocol MyServiceProtocol {
    func getData() -> Observable<String>
}

struct MyService: MyServiceProtocol {
    let remote: DataFetcherProtocol
    let cache: LocalStorageProtocol
    let timeout: RxTimeInterval
    let reporter: ErrorReporterProtocol

    /// Set `disposeBag` as property of `MyService`
    /// to prevent stopping `remoteObservable` after emitting `cacheObservable`
    let disposeBag = DisposeBag()

    func getData() -> Observable<String> {
        Observable.create { observer in

            let timeoutObservable = Observable.just(()).delay(timeout, scheduler: MainScheduler.instance)
            timeoutObservable.subscribe(onNext: { _ in
                if let cachedData = cache.load() {
                    observer.onNext(cachedData)
                    observer.onCompleted()
                    // reporter.reportError(APIError.timeout)
                }
            })
            .disposed(by: disposeBag)

            let remoteObservable = remote.fetch()
            remoteObservable.subscribe(
                onNext: { data in
                    observer.onNext(data)
                    observer.onCompleted()
                    cache.save(data)
                }, onError: { error in
                    observer.onError(error)
                    reporter.reportError(error)
                })
            .disposed(by: disposeBag)

            return Disposables.create()
        }
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
    case timeout
}

enum CacheError: Error, Equatable {
    case notFound
}
