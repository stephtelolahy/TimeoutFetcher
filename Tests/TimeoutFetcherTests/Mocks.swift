//
//  Mocks.swift
//
//
//  Created by Hugues Telolahy on 16/09/2023.
//
@testable import TimeoutFetcher
import RxSwift

class MockDataFetcher: DataFetcherProtocol {
    let result: Result<String, Error>
    let delay: RxTimeInterval

    init(result: Result<String, Error>, delay: RxTimeInterval = .never) {
        self.result = result
        self.delay = delay
    }

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

class MockLocalStorage: LocalStorageProtocol {
    let cachedData: String?
    var savedData: String?

    init(cachedData: String?) {
        self.cachedData = cachedData
    }

    func load() -> String? {
        cachedData
    }

    func save(_ data: String) {
        savedData = data
    }
}

class MockErrorReporter: ErrorReporterProtocol {
    var reportedError: Error?

    func reportError(_ error: Error) {
        reportedError = error
    }
}
