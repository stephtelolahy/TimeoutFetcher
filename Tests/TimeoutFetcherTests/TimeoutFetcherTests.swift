import XCTest
@testable import TimeoutFetcher
import RxSwift
import RxBlocking

final class TimeoutFetcherTests: XCTestCase {

    func test_WhenAPISucceeds_AndCacheSucceeds_AndAPIFirst_ShouldReturnRemoteData() throws {
        // Given
        let api = MockDataFetcher(result: .success("Remote data"), delay: .milliseconds(1))
        let cache = MockDataFetcher(result: .success("Cached data"), delay: .milliseconds(2))
        let sut = MyService(api: api, cache: cache)

        // When
        let result = try sut.getData().toBlocking().first()

        // Assert
        XCTAssertEqual(result, "Remote data")
    }

    func test_WhenAPISucceeds_AndCacheSucceeds_AndCacheFirst_ShouldReturnCachedData() throws {
        // Given
        let api = MockDataFetcher(result: .success("Remote data"), delay: .milliseconds(2))
        let cache = MockDataFetcher(result: .success("Cached data"), delay: .milliseconds(1))
        let sut = MyService(api: api, cache: cache)

        // When
        let result = try sut.getData().toBlocking().first()

        // Assert
        XCTAssertEqual(result, "Cached data")
    }

    func test_WhenAPIsucceeds_AndCacheFails_ShouldReturnRemoteData() throws {
        // Given
        let api = MockDataFetcher(result: .success("Remote data"), delay: .milliseconds(1))
        let cache = MockDataFetcher(result: .failure(DataFetchError.notFound))
        let sut = MyService(api: api, cache: cache)

        // When
        let result = try sut.getData().toBlocking().first()

        // Assert
        XCTAssertEqual(result, "Remote data")
    }

    func test_WhenAPIFails_AndCacheSucceeds_ShouldReturnCachedData() throws {
        // Given
        let api = MockDataFetcher(result: .failure(DataFetchError.http))
        let cache = MockDataFetcher(result: .success("Cached data"), delay: .milliseconds(1))
        let sut = MyService(api: api, cache: cache)

        // When
        let result = try sut.getData().toBlocking().first()

        // Assert
        XCTAssertEqual(result, "Cached data")
    }

    func test_WhenAPIFails_AndCacheFails_ShouldReturnAPIError() throws {
        // Given
        let api = MockDataFetcher(result: .failure(DataFetchError.http))
        let cache = MockDataFetcher(result: .failure(DataFetchError.notFound))
        let sut = MyService(api: api, cache: cache)
        // When
        let result = sut.getData().toBlocking().materialize()

        // Assert
        switch result {
        case .completed:
            XCTFail("Expected result to complete with error")
        case .failed(let elements, let error):
            XCTAssertEqual(elements, [])
            XCTAssertEqual(error as? DataFetchError, .http)
        }
    }
}

enum DataFetchError: Error, Equatable {
    case http
    case parsing
    case notFound
}
