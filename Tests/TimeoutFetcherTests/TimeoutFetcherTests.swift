import XCTest
@testable import TimeoutFetcher
import RxSwift
import RxBlocking

final class TimeoutFetcherTests: XCTestCase {

    private let mockRemote = MockDataFetcher()
    private let mockCache = MockLocalStorage()
    private let mockReporter = MockErrorReporter()
    private lazy var sut = MyService(remote: mockRemote,
                                     cache: mockCache,
                                     timeout: .milliseconds(2),
                                     reporter: MockErrorReporter())
    private let disposeBag = DisposeBag()

    // MARK: - Result

    func test_WhenAPISucceeds_BeforeTimeout_ShouldReturnRemoteData() throws {
        // Given
        mockRemote.result = .success("remote-data")
        mockRemote.delay = .milliseconds(1)
        mockCache.cachedData = "cached-data"

        // When
        let result = try sut.getData().toBlocking().first()

        // Then
        XCTAssertEqual(result, "remote-data")
    }

    func test_WhenAPIFailsHTTP_BeforeTimeout_ShouldReturnAPIError() throws {
        // Given
        mockRemote.result = .failure(APIError.http)
        mockRemote.delay = .milliseconds(1)
        mockCache.cachedData = "cached-data"

        // When
        // Then
        XCTAssertThrowsError(try sut.getData().toBlocking().toArray()) { error in
            XCTAssertEqual(error as? APIError, .http)
        }
    }

    func test_WhenAPIFailsParsing_BeforeTimeout_CacheSucceeds_ShouldReturnCachedData() throws {
        // Given
        mockRemote.result = .failure(APIError.parsing)
        mockRemote.delay = .milliseconds(1)
        mockCache.cachedData = "cached-data"

        // When
        let result = try sut.getData().toBlocking().first()

        // Then
        XCTAssertEqual(result, "cached-data")
    }

    func test_WhenAPIFailsParsing_BeforeTimeout_CacheFails_ShouldReturnAPIError() throws {
        // Given
        mockRemote.result = .failure(APIError.parsing)
        mockRemote.delay = .milliseconds(1)

        // When
        // Then
        XCTAssertThrowsError(try sut.getData().toBlocking().toArray()) { error in
            XCTAssertEqual(error as? APIError, .parsing)
        }
    }

    func test_WhenAPISucceeds_AfterTimeout_CacheSucceeds_ShouldReturnCachedData() throws {
        // Given
        mockRemote.result = .success("remote-data")
        mockRemote.delay = .milliseconds(3)
        mockCache.cachedData = "cached-data"

        // When
        let result = try sut.getData().toBlocking().first()

        // Then
        XCTAssertEqual(result, "cached-data")
    }

    func test_WhenAPISucceeds_AfterTimeout_CacheFails_ShouldReturnRemoteData() throws {
        // Given
        mockRemote.result = .success("remote-data")
        mockRemote.delay = .milliseconds(3)

        // When
        let result = try sut.getData().toBlocking().first()

        // Then
        XCTAssertEqual(result, "remote-data")
    }

    func test_WhenAPIFailsHTTP_AfterTimeout_CacheSucceeds_ShouldReturnCachedData() throws {
        // Given
        mockRemote.result = .failure(APIError.http)
        mockRemote.delay = .milliseconds(3)
        mockCache.cachedData = "cached-data"

        // When
        let result = try sut.getData().toBlocking().first()

        // Then
        XCTAssertEqual(result, "cached-data")
    }

    func test_WhenAPIFailsHTTP_AfterTimeout_CacheFails_ShouldReturnAPIError() throws {
        // Given
        mockRemote.result = .failure(APIError.http)
        mockRemote.delay = .milliseconds(3)

        // When
        // Then
        XCTAssertThrowsError(try sut.getData().toBlocking().toArray()) { error in
            XCTAssertEqual(error as? APIError, .http)
        }
    }

    func test_WhenAPIFailsParsing_AfterTimeout_CacheSucceeds_ShouldReturnCachedData() throws {
        // Given
        mockRemote.result = .failure(APIError.parsing)
        mockRemote.delay = .milliseconds(3)
        mockCache.cachedData = "cached-data"

        // When
        let result = try sut.getData().toBlocking().first()

        // Then
        XCTAssertEqual(result, "cached-data")
    }

    func test_WhenAPIFailsParsing_AfterTimeout_CacheFails_ShouldReturnAPIError() throws {
        // Given
        mockRemote.result = .failure(APIError.parsing)
        mockRemote.delay = .milliseconds(3)

        // When
        // Then
        XCTAssertThrowsError(try sut.getData().toBlocking().toArray()) { error in
            XCTAssertEqual(error as? APIError, .parsing)
        }
    }

    // MARK: - Caching

    func test_WhenAPISucceeds_ShouldUpdateCache() throws {
        // Given
        mockRemote.result = .success("remote-data")
        mockRemote.delay = .milliseconds(3)

        let expectation = XCTestExpectation(description: "updating cache")
        var savedData: String?
        mockCache.saveSubject.subscribe(onNext: { data in
            savedData = data
            expectation.fulfill()
        }).disposed(by: disposeBag)

        // When
        _ = sut.getData().toBlocking().materialize()

        // Then
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(savedData, "remote-data")
    }

    func test_WhenAPIFailsHTTP_ShouldDeleteCache() throws {
        // Given
        mockRemote.result = .failure(APIError.http)
        mockRemote.delay = .milliseconds(3)

        let expectation = XCTestExpectation(description: "deleting cache")
        mockCache.clearSubject.subscribe(onNext: { _ in
            expectation.fulfill()
        }).disposed(by: disposeBag)

        // When
        _ = sut.getData().toBlocking().materialize()

        // Then
        wait(for: [expectation], timeout: 1)
    }

    func test_WhenAPIFailsParsing_ShouldNotDeleteCache() throws {
        // Given
        mockRemote.result = .failure(APIError.parsing)
        mockRemote.delay = .milliseconds(3)

        let expectation = XCTestExpectation(description: "not deleting cache")
        expectation.isInverted = true
        mockCache.clearSubject.subscribe(onNext: { _ in
            expectation.fulfill()
        }).disposed(by: disposeBag)

        // When
        _ = sut.getData().toBlocking().materialize()

        // Then
        wait(for: [expectation], timeout: 1)
    }

    /*

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

        // Then
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

        // Then
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

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(reportedError as? APIError, .parsing)
    }
     */
}
