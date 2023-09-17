//
//  Mocks.swift
//
//
//  Created by Hugues Telolahy on 16/09/2023.
//
@testable import TimeoutFetcher
import RxSwift

struct MockDataFetcher: DataFetcherProtocol {
    let result: Result<String, Error>
    var delay: RxTimeInterval = .never

    func fetch() -> Observable<String> {
        switch result {
        case .success(let value):
            Observable.just(value)
                .delay(delay, scheduler: MainScheduler.instance)
        case .failure(let error):
            Observable.error(error)
        }
    }
}

struct MockLocalStorage: LocalStorageProtocol {
    let cachedData: String?
    let savedData = PublishSubject<String>()

    func load() -> String? {
        cachedData
    }

    func save(_ data: String) {
        savedData.onNext(data)
    }
}

struct MockErrorReporter: ErrorReporterProtocol {
    let reportedError = PublishSubject<Error>()

    func reportError(_ error: Error) {
        reportedError.onNext(error)
    }
}
