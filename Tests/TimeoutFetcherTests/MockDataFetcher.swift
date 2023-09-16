//
//  MockDataFetcher.swift
//
//
//  Created by Hugues Telolahy on 16/09/2023.
//
@testable import TimeoutFetcher
import RxSwift

struct MockDataFetcher: DataFetcherProtocol {
    let result: Result<String, Error>
    let delay: RxTimeInterval

    func fetch() -> Observable<String> {
        switch result {
        case .success(let value):
            Observable.just(value)
                .delay(delay, scheduler: MainScheduler.instance)
        case .failure(let error):
            Observable.error(error)
                .delay(delay, scheduler: MainScheduler.instance)
        }
    }
}
