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
            var remoteCompleted = false

            let timeoutObservable = Observable.just(()).delay(timeout, scheduler: MainScheduler.instance)
            timeoutObservable.subscribe(onNext: { _ in
                if let cachedData = cache.load() {
                    observer.onNext(cachedData)
                    observer.onCompleted()
                }

                if !remoteCompleted {
                    reporter.reportTimeoutError()
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
                    if let apiError = error as? APIError,
                       case .parsing = apiError {
                        if let cachedData = cache.load() {
                            observer.onNext(cachedData)
                            observer.onCompleted()
                        } else {
                            observer.onError(error)
                        }
                        reporter.reportParsingError()

                    } else {
                        observer.onError(error)
                        cache.clear()
                        reporter.reportHTTPError()
                    }
                }, onCompleted: {
                    remoteCompleted = true
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
    func clear()
}

protocol ErrorReporterProtocol {
    func reportHTTPError()
    func reportParsingError()
    func reportTimeoutError()
}

enum APIError: Error, Equatable {
    case http
    case parsing
}
