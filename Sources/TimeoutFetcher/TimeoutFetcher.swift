// The Swift Programming Language
// https://docs.swift.org/swift-book

import RxSwift

struct MyService {
    let api: DataFetcherProtocol
    let cache: DataFetcherProtocol

    func getData() -> Observable<String> {
        let apiFetch = api.fetch()
        let cacheLoad = cache.fetch()

        return Observable.amb([apiFetch, cacheLoad])
    }
}

protocol DataFetcherProtocol {
    func fetch() -> Observable<String>
}
