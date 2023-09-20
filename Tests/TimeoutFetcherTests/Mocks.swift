//
//  Mocks.swift
//
//
//  Created by Hugues Telolahy on 16/09/2023.
//
@testable import TimeoutFetcher
import RxSwift

class MockDataFetcher: DataFetcherProtocol {
    var result: Result<String, Error>?
    var delay: RxTimeInterval = .never
    
    func fetch() -> Observable<String> {
        switch result {
        case .success(let value):
            Observable.just(value).delaySubscription(delay, scheduler: MainScheduler.instance)
        case .failure(let error):
            Observable.error(error).delaySubscription(delay, scheduler: MainScheduler.instance)
        default:
            fatalError("undefined result")
        }
    }
}

class MockLocalStorage: LocalStorageProtocol {
    var cachedData: String?
    let saveSubject = PublishSubject<String>()
    let clearSubject = PublishSubject<Void>()

    func load() -> String? {
        cachedData
    }
    
    func save(_ data: String) {
        saveSubject.onNext(data)
    }

    func clear() {
        clearSubject.onNext(())
    }
}

class MockErrorReporter: ErrorReporterProtocol {
    let reportHTTPSubject = PublishSubject<Void>()
    let reportParsingSubject = PublishSubject<Void>()
    let reportTimeoutSubject = PublishSubject<Void>()

    func reportHTTPError() {
        reportHTTPSubject.onNext(())
    }

    func reportParsingError() {
        reportParsingSubject.onNext(())
    }

    func reportTimeoutError() {
        reportTimeoutSubject.onNext(())
    }
}
