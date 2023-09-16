import XCTest
@testable import TimeoutFetcher
import RxSwift
import RxBlocking

final class TimeoutFetcherTests: XCTestCase {

    func test_WhenAPISucceedsBeforeCache_ShouldReturnRemoteData() throws {
        // Given
        let api = MockDataFetcher(result: .success("Remote data"), delay: .milliseconds(1))
        let cache = MockDataFetcher(result: .success("Cached data"), delay: .milliseconds(2))
        let sut = MyService(api: api, cache: cache)

        // When
        let result = try sut.getData().toBlocking().first()

        // Assert
        XCTAssertEqual(result, "Remote data")
    }

    func test_WhenAPISucceedsAfterCache_ShouldReturnCachedData() throws {
        // Given
        let api = MockDataFetcher(result: .success("Remote data"), delay: .milliseconds(3))
        let cache = MockDataFetcher(result: .success("Cached data"), delay: .milliseconds(2))
        let sut = MyService(api: api, cache: cache)

        // When
        let result = try sut.getData().toBlocking().first()

        // Assert
        XCTAssertEqual(result, "Cached data")
    }
}
