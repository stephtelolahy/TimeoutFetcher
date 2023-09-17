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
    /// to prevent stopping remoteObservable after emitting cached data
    let disposeBag = DisposeBag()

    func getData() -> Observable<String> {
        //        getDataUsingAmb()
        getDataUsingInnerSubscription()
    }

    private func getDataUsingInnerSubscription() -> Observable<String> {
        Observable.create { observer in
            var cacheCompleted = false
            var remoteCompleted = false

            let timeoutObservable = Observable<Bool>
                .just(true)
                .delay(timeout, scheduler: MainScheduler.instance)
            timeoutObservable.subscribe(onNext: { _ in
                guard !remoteCompleted else { return }
                if let cachedData = cache.load() {
                    observer.onNext(cachedData)
                    observer.onCompleted()
                    cacheCompleted = true
                }
            })
            .disposed(by: disposeBag)

            let remoteObservable = remote.fetch()
            remoteObservable.subscribe(
                onNext: { data in
                    if !cacheCompleted {
                        observer.onNext(data)
                        observer.onCompleted()
                        remoteCompleted = true
                    } else {
                        reporter.reportError(APIError.timeout)
                    }
                    cache.save(data)
                }, onError: { error in
                    if !cacheCompleted {
                        observer.onError(error)
                    }
                    reporter.reportError(error)
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
