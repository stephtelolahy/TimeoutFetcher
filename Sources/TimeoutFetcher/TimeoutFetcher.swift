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
        //        getDataUsingAmb()
        getDataUsingSubscription()
    }

    private func getDataUsingSubscription() -> Observable<String> {
        Observable.create { observer in
            var cacheResult: Result<String, Error>?
            var remoteResult: Result<String, Error>?

            let timeoutObservable = Observable.just(())
                .delay(timeout, scheduler: MainScheduler.instance)

            timeoutObservable.subscribe(onNext: { _ in
                if let cachedData = cache.load() {
                    cacheResult = .success(cachedData)
                    switch remoteResult {
                    case .success:
                        break
                    case .failure:
                        observer.onNext(cachedData)
                        observer.onCompleted()
                    case nil:
                        observer.onNext(cachedData)
                        observer.onCompleted()
                    }

                } else {
                    cacheResult = .failure(CacheError.notFound)

                    switch remoteResult {
                    case .success:
                        break
                    case .failure(let apiError):
                        observer.onError(apiError)
                    case nil:
                        break // wait for API response
                    }
                }
            })
            .disposed(by: disposeBag)

            let remoteObservable = remote.fetch()
                .do(onNext: { data in
                    cache.save(data)
                }, onError: { error in
                    reporter.reportError(error)
                })

            remoteObservable.subscribe(
                onNext: { data in
                    remoteResult = .success(data)

                    switch cacheResult {
                    case .success:
                        reporter.reportError(APIError.timeout)
                    case .failure:
                        observer.onNext(data)
                        observer.onCompleted()
                        reporter.reportError(APIError.timeout)
                    case nil:
                        observer.onNext(data)
                        observer.onCompleted()
                    }
                }, onError: { error in
                    remoteResult = .failure(error)

                    switch cacheResult {
                    case .success:
                        break
                    case .failure:
                        observer.onError(error)
                    case nil:
                        break // wait for cache response
                    }
                })
            .disposed(by: disposeBag)

            return Disposables.create()
        }
    }

    private func getDataUsingAmb() -> Observable<String> {
        let remoteObservable = remote.fetch()
            .do(onNext: { data in
                cache.save(data)
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
    case timeout
}

enum CacheError: Error, Equatable {
    case notFound
}
