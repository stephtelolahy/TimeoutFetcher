import XCTest
@testable import TimeoutFetcher
import RxSwift
import RxBlocking

final class TimeoutFetcherTests: XCTestCase {

    private let disposeBag = DisposeBag()

    // MARK: - Result

    func test_WhenAPISucceeds_BeforeTimeout_ShouldReturnRemoteData() throws {
        // Given
        let mockRemote = MockDataFetcher(result: .success("remote-data"), delay: .milliseconds(1))
        let mockCache = MockLocalStorage(cachedData: "cached-data")
        let sut = MyService(remote: mockRemote,
                            cache: mockCache,
                            timeout: .milliseconds(2),
                            reporter: MockErrorReporter())

        // When
        let result = try sut.getData().toBlocking().first()

        // Assert
        XCTAssertEqual(result, "remote-data")
    }

    func test_WhenAPIFailsHTTP_BeforeTimeout_ShouldReturnAPIError() throws {
        // Given
        let mockRemote = MockDataFetcher(result: .failure(APIError.http), delay: .milliseconds(1))
        let mockCache = MockLocalStorage(cachedData: "cached-data")
        let sut = MyService(remote: mockRemote,
                            cache: mockCache,
                            timeout: .milliseconds(2),
                            reporter: MockErrorReporter())

        // When
        let result = sut.getData().toBlocking().materialize()

        // Assert
        switch result {
        case .completed:
            XCTFail("Expected result to complete with error")
        case .failed(let elements, let error):
            XCTAssertEqual(elements, [])
            XCTAssertEqual(error as? APIError, .http)
        }
    }

    func test_WhenAPIFailsParsing_BeforeTimeout_CacheSucceeds_ShouldReturnCachedData() throws {
        // Given
        let mockRemote = MockDataFetcher(result: .failure(APIError.parsing), delay: .milliseconds(1))
        let mockCache = MockLocalStorage(cachedData: "cached-data")
        let sut = MyService(remote: mockRemote,
                            cache: mockCache,
                            timeout: .milliseconds(2),
                            reporter: MockErrorReporter())

        // When
        let result = try sut.getData().toBlocking().first()

        // Assert
        XCTAssertEqual(result, "remote-data")
    }

    func test_WhenAPIFailsParsing_BeforeTimeout_CacheFails_ShouldReturnAPIError() throws {
        // Given
        let mockRemote = MockDataFetcher(result: .failure(APIError.parsing), delay: .milliseconds(1))
        let mockCache = MockLocalStorage(cachedData: nil)
        let sut = MyService(remote: mockRemote,
                            cache: mockCache,
                            timeout: .milliseconds(2),
                            reporter: MockErrorReporter())

        // When
        let result = sut.getData().toBlocking().materialize()

        // Assert
        switch result {
        case .completed:
            XCTFail("Expected result to complete with error")
        case .failed(let elements, let error):
            XCTAssertEqual(elements, [])
            XCTAssertEqual(error as? APIError, .parsing)
        }
    }

    func test_WhenAPISucceeds_AfterTimeout_CacheSucceeds_ShouldReturnCachedData() throws {
        // Given
        let mockRemote = MockDataFetcher(result: .success("remote-data"), delay: .milliseconds(2))
        let mockCache = MockLocalStorage(cachedData: "cached-data")
        let sut = MyService(remote: mockRemote,
                            cache: mockCache,
                            timeout: .milliseconds(1),
                            reporter: MockErrorReporter())

        // When
        let result = try sut.getData().toBlocking().first()

        // Assert
        XCTAssertEqual(result, "cached-data")
    }

    func test_WhenAPISucceeds_AfterTimeout_CacheFails_ShouldReturnRemoteData() throws {
        // Given
        let mockRemote = MockDataFetcher(result: .success("remote-data"), delay: .milliseconds(2))
        let mockCache = MockLocalStorage(cachedData: nil)
        let sut = MyService(remote: mockRemote,
                            cache: mockCache,
                            timeout: .milliseconds(1),
                            reporter: MockErrorReporter())

        // When
        let result = try sut.getData().toBlocking().first()

        // Assert
        XCTAssertEqual(result, "remote-data")
    }

    func test_WhenAPIFailsHTTP_AfterTimeout_CacheSucceeds_ShouldReturnCachedData() throws {
        // Given
        let mockRemote = MockDataFetcher(result: .failure(APIError.http), delay: .milliseconds(2000))
        let mockCache = MockLocalStorage(cachedData: "cached-data")
        let sut = MyService(remote: mockRemote,
                            cache: mockCache,
                            timeout: .milliseconds(10),
                            reporter: MockErrorReporter())

        // When
        let result = try sut.getData().toBlocking().first()

        // Assert
        XCTAssertEqual(result, "cached-data")
    }

    func test_WhenAPIFailsHTTP_AfterTimeout_CacheFails_ShouldReturnAPIError() throws {
        // Given
        let mockRemote = MockDataFetcher(result: .failure(APIError.http), delay: .milliseconds(2))
        let mockCache = MockLocalStorage(cachedData: nil)
        let sut = MyService(remote: mockRemote,
                            cache: mockCache,
                            timeout: .milliseconds(1),
                            reporter: MockErrorReporter())

        // When
        let result = sut.getData().toBlocking().materialize()

        // Assert
        switch result {
        case .completed:
            XCTFail("Expected result to complete with error")
        case .failed(let elements, let error):
            XCTAssertEqual(elements, [])
            XCTAssertEqual(error as? APIError, .http)
        }
    }

    func test_WhenAPIFailsParsing_AfterTimeout_CacheSucceeds_ShouldReturnCachedData() throws {
        // Given
        let mockRemote = MockDataFetcher(result: .failure(APIError.parsing), delay: .milliseconds(2))
        let mockCache = MockLocalStorage(cachedData: "cached-data")
        let sut = MyService(remote: mockRemote,
                            cache: mockCache,
                            timeout: .milliseconds(1),
                            reporter: MockErrorReporter())

        // When
        let result = try sut.getData().toBlocking().first()

        // Assert
        XCTAssertEqual(result, "cached-data")
    }

    func test_WhenAPIFailsParsing_AfterTimeout_CacheFails_ShouldReturnAPIError() throws {
        // Given
        let mockRemote = MockDataFetcher(result: .failure(APIError.parsing), delay: .milliseconds(2))
        let mockCache = MockLocalStorage(cachedData: nil)
        let sut = MyService(remote: mockRemote,
                            cache: mockCache,
                            timeout: .milliseconds(1),
                            reporter: MockErrorReporter())

        // When
        let result = sut.getData().toBlocking().materialize()

        // Assert
        switch result {
        case .completed:
            XCTFail("Expected result to complete with error")
        case .failed(let elements, let error):
            XCTAssertEqual(elements, [])
            XCTAssertEqual(error as? APIError, .parsing)
        }
    }

    /*
    // MARK: - Caching

    func test_WhenAPISucceedsBeforeTimeout_ShouldUpdateCache() throws {
        // Given
        let mockRemote = MockDataFetcher(result: .success("remote-data"), delay: .milliseconds(1))
        let mockCache = MockLocalStorage(cachedData: "cached-data")
        let sut = MyService(remote: mockRemote,
                            cache: mockCache,
                            timeout: .milliseconds(2),
                            reporter: MockErrorReporter())
        let expectation = XCTestExpectation(description: "caching")
        var savedData: String?
        mockCache.savedData.subscribe(onNext: { data in
            savedData = data
            expectation.fulfill()
        }).disposed(by: disposeBag)

        // When
        _ = try sut.getData().toBlocking().first()

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(savedData, "remote-data")
    }

    func test_WhenAPISucceedsAfterTimeout_ShouldUpdateCache() throws {
        // Given
        let mockRemote = MockDataFetcher(result: .success("remote-data"), delay: .milliseconds(2))
        let mockCache = MockLocalStorage(cachedData: "cached-data")
        let sut = MyService(remote: mockRemote,
                            cache: mockCache,
                            timeout: .milliseconds(10),
                            reporter: MockErrorReporter())
        let expectation = XCTestExpectation(description: "caching")
        var savedData: String?
        mockCache.savedData.subscribe(onNext: { data in
            savedData = data
            expectation.fulfill()
        }).disposed(by: disposeBag)

        // When
        _ = try sut.getData().toBlocking().first()

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(savedData, "remote-data")
    }

    func test_WhenAPIsucceedsAfterTimeout_CacheFails_ShouldUpdateCache() throws {
        // Given
        let mockRemote = MockDataFetcher(result: .success("remote-data"), delay: .milliseconds(2))
        let mockCache = MockLocalStorage(cachedData: nil)
        let sut = MyService(remote: mockRemote,
                            cache: mockCache,
                            timeout: .milliseconds(10),
                            reporter: MockErrorReporter())
        let expectation = XCTestExpectation(description: "caching")
        var savedData: String?
        mockCache.savedData.subscribe(onNext: { data in
            savedData = data
            expectation.fulfill()
        }).disposed(by: disposeBag)

        // When
        _ = try sut.getData().toBlocking().first()

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(savedData, "remote-data")
    }

    // MARK: - Reporting

    func test_WhenAPISucceedsAfterTimeout_CacheSucceeds_ShouldReportError() throws {
        // Given
        let mockRemote = MockDataFetcher(result: .success("remote-data"), delay: .milliseconds(2))
        let mockCache = MockLocalStorage(cachedData: "cached-data")
        let mockReporter = MockErrorReporter()
        let sut = MyService(remote: mockRemote,
                            cache: mockCache,
                            timeout: .milliseconds(10),
                            reporter: mockReporter)
        let expectation = XCTestExpectation(description: "reporting")
        var reportedError: Error?
        mockReporter.reportedError.subscribe(onNext: { error in
            reportedError = error
            expectation.fulfill()
        }).disposed(by: disposeBag)

        // When
        _ = try sut.getData().toBlocking().first()

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(reportedError as? APIError, .timeout)
    }

    func test_WhenAPIsucceedsAfterTimeout_CacheFails_ShouldReportError() throws {
        // Given
        let mockRemote = MockDataFetcher(result: .success("remote-data"), delay: .milliseconds(2))
        let mockCache = MockLocalStorage(cachedData: nil)
        let mockReporter = MockErrorReporter()
        let sut = MyService(remote: mockRemote,
                            cache: mockCache,
                            timeout: .milliseconds(10),
                            reporter: mockReporter)
        let expectation = XCTestExpectation(description: "reporting")
        var reportedError: Error?
        mockReporter.reportedError.subscribe(onNext: { error in
            reportedError = error
            expectation.fulfill()
        }).disposed(by: disposeBag)

        // When
        _ = try sut.getData().toBlocking().first()

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(reportedError as? APIError, .timeout)
    }

    func test_WhenAPIFails_ShouldReportError() throws {
        // Given
        let mockRemote = MockDataFetcher(result: .failure(APIError.parsing))
        let mockCache = MockLocalStorage(cachedData: "cached-data")
        let mockReporter = MockErrorReporter()
        let sut = MyService(remote: mockRemote,
                            cache: mockCache,
                            timeout: .milliseconds(10),
                            reporter: mockReporter)
        let expectation = XCTestExpectation(description: "reporting")
        var reportedError: Error?
        mockReporter.reportedError.subscribe(onNext: { error in
            reportedError = error
            expectation.fulfill()
        }).disposed(by: disposeBag)

        // When
        _ = try sut.getData().toBlocking().first()

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(reportedError as? APIError, .parsing)
    }
     */
}
