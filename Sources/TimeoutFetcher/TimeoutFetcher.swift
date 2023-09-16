// The Swift Programming Language
// https://docs.swift.org/swift-book

import RxSwift

struct MyService {
    let remote: DataFetcherProtocol
    let cache: DataFetcherProtocol

    func getData() -> Observable<String> {
        let remoteFetch = remote.fetch()
        let cacheLoad = cache.fetch()

        return Observable.amb([remoteFetch, cacheLoad])
    }
}

protocol DataFetcherProtocol {
    func fetch() -> Observable<String>
}
