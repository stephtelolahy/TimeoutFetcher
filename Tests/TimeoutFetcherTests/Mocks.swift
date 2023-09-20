//
//  Mocks.swift
//
//
//  Created by Hugues Telolahy on 16/09/2023.
//
@testable import TimeoutFetcher
import RxSwift
import Foundation
import XCTest

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
    let saveExpectation = XCTestExpectation(description: "save expectation")
    let clearExpectation = XCTestExpectation(description: "clear expectation")
    var savedData: String?

    func load() -> String? {
        cachedData
    }

    func save(_ data: String) {
        savedData = data
        saveExpectation.fulfill()
    }

    func clear() {
        clearExpectation.fulfill()
    }
}

class MockErrorReporter: ErrorReporterProtocol {
    let reportTimeoutExpectation = XCTestExpectation(description: "reportTimeoutError expectation")
    let reportHTTPExpectation = XCTestExpectation(description: "reportHTTPError expectation")
    let reportParsingExpectation = XCTestExpectation(description: "reportParsingError expectation")

    func reportHTTPError() {
        reportHTTPExpectation.fulfill()
    }

    func reportParsingError() {
        reportParsingExpectation.fulfill()
    }

    func reportTimeoutError() {
        reportTimeoutExpectation.fulfill()
    }
}
