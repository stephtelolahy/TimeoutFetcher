import XCTest
@testable import TimeoutFetcher
import RxSwift
import RxBlocking

final class TimeoutFetcherTests: XCTestCase {

    private let mockReporter = MockErrorReporter()

    func test_WhenAPISucceedsBeforeTimeout_ShouldReturnRemoteData_AndUpdateCache() throws {
        // Given
        let mockRemote = MockDataFetcher(result: .success("remote-data"), delay: .milliseconds(1))
        let mockCache = MockLocalStorage(cachedData: nil)
        let sut = MyService(remote: mockRemote,
                            cache: mockCache,
                            timeout: .milliseconds(2),
                            reporter: mockReporter)

        // When
        let result = try sut.getData().toBlocking().first()

        // Assert
        XCTAssertEqual(result, "remote-data")
        XCTAssertEqual(mockCache.savedData, "remote-data")
    }

    func test_WhenAPISucceedsAfterTimeout_CacheSucceeds_ShouldReturnCachedData_AndUpdateCache_AndReportError() throws {
        // Given
        let mockRemote = MockDataFetcher(result: .success("remote-data"), delay: .milliseconds(2))
        let mockCache = MockLocalStorage(cachedData: "cached-data")
        let sut = MyService(remote: mockRemote,
                            cache: mockCache,
                            timeout: .milliseconds(1),
                            reporter: mockReporter)

        // When
        let result = try sut.getData().toBlocking().first()

        // Assert
        XCTAssertEqual(result, "cached-data")
        XCTAssertEqual(mockCache.savedData, "remote-data")
        XCTAssertEqual(mockReporter.reportedError as? APIError, .timeout)
    }

    func test_WhenAPIsucceedsAfterTimeout_CacheFails_ShouldReturnRemoteData_AndUpdateCache_AndReportError() throws {
        // Given
        let mockRemote = MockDataFetcher(result: .success("remote-data"), delay: .milliseconds(2))
        let mockCache = MockLocalStorage(cachedData: nil)
        let sut = MyService(remote: mockRemote,
                            cache: mockCache,
                            timeout: .milliseconds(1),
                            reporter: mockReporter)

        // When
        let result = try sut.getData().toBlocking().first()

        // Assert
        XCTAssertEqual(result, "remote-data")
        XCTAssertEqual(mockCache.savedData, "remote-data")
        XCTAssertEqual(mockReporter.reportedError as? APIError, .timeout)
    }

    func test_WhenAPIFails_CacheSucceeds_ShouldReturnCachedData_AndReportError() throws {
        // Given
        let mockRemote = MockDataFetcher(result: .failure(APIError.parsing))
        let mockCache = MockLocalStorage(cachedData: "cached-data")
        let sut = MyService(remote: mockRemote,
                            cache: mockCache,
                            timeout: .milliseconds(1),
                            reporter: mockReporter)

        // When
        let result = try sut.getData().toBlocking().first()

        // Assert
        XCTAssertEqual(result, "cached-data")
        XCTAssertEqual(mockReporter.reportedError as? APIError, .parsing)
    }

    func test_WhenAPIFails_CacheFails_ShouldReturnAPIError_AndReportError() throws {
        // Given
        let mockRemote = MockDataFetcher(result: .failure(APIError.http))
        let mockCache = MockLocalStorage(cachedData: nil)
        let sut = MyService(remote: mockRemote,
                            cache: mockCache,
                            timeout: .milliseconds(1),
                            reporter: mockReporter)

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
