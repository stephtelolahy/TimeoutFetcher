import XCTest
@testable import TimeoutFetcher
import RxSwift
import RxBlocking

final class TimeoutFetcherTests: XCTestCase {

    private let mockReporter = MockErrorReporter()

    func test_WhenAPISucceeds_CacheSucceeds_APIFirst_ShouldReturnRemoteData_AndUpdateCache() throws {
        // Given
        let remote = MockDataFetcher(result: .success("Remote data"), delay: .milliseconds(1))
        let cache = MockDataFetcher(result: .success("Cached data"), delay: .milliseconds(2))
        let sut = MyService(remote: remote, cache: cache, reporter: mockReporter)

        // When
        let result = try sut.getData().toBlocking().first()

        // Assert
        XCTAssertEqual(result, "Remote data")
    }

    func test_WhenAPISucceeds_CacheSucceeds_CacheFirst_ShouldReturnCachedData_AndUpdateCache() throws {
        // Given
        let remote = MockDataFetcher(result: .success("Remote data"), delay: .milliseconds(2))
        let cache = MockDataFetcher(result: .success("Cached data"), delay: .milliseconds(1))
        let sut = MyService(remote: remote, cache: cache, reporter: mockReporter)

        // When
        let result = try sut.getData().toBlocking().first()

        // Assert
        XCTAssertEqual(result, "Cached data")
    }

    func test_WhenAPIsucceeds_CacheFails_ShouldReturnRemoteData_AndUpdateCache() throws {
        // Given
        let remote = MockDataFetcher(result: .success("Remote data"), delay: .milliseconds(1))
        let cache = MockDataFetcher(result: .failure(CacheError.notFound))
        let sut = MyService(remote: remote, cache: cache, reporter: mockReporter)

        // When
        let result = try sut.getData().toBlocking().first()

        // Assert
        XCTAssertEqual(result, "Remote data")
    }

    func test_WhenAPIFails_CacheSucceeds_ShouldReturnCachedData_AndReportError() throws {
        // Given
        let remote = MockDataFetcher(result: .failure(APIError.parsing))
        let cache = MockDataFetcher(result: .success("Cached data"), delay: .milliseconds(1))
        let sut = MyService(remote: remote, cache: cache, reporter: mockReporter)

        // When
        let result = try sut.getData().toBlocking().first()

        // Assert
        XCTAssertEqual(result, "Cached data")
        XCTAssertEqual(mockReporter.reportedError as? APIError, .parsing)
    }

    func test_WhenAPIFails_CacheFails_ShouldReturnAPIError_AndReportError() throws {
        // Given
        let remote = MockDataFetcher(result: .failure(APIError.http))
        let cache = MockDataFetcher(result: .failure(CacheError.notFound))
        let sut = MyService(remote: remote, cache: cache, reporter: mockReporter)
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

        XCTAssertEqual(mockReporter.reportedError as? APIError, .http)
    }
}

enum APIError: Error, Equatable {
    case http
    case parsing
}

enum CacheError: Error {
    case notFound
}
