
import CryptoKit

// MARK: - 절대 따라하지 말 것. 분석용 악취 코드 모음
// TODO: 리팩터링 필요
// FIXME: 보안 점검 필요

let globalCache: NSMutableDictionary = [:] // thread-unsafe 전역 mutable 상태
var globalCounter = 0                       // 전역 변경 가능 상태
let HARDCODED_PASSWORD = "P@ssw0rd!"       // 하드코딩 비밀번호 (보안 핫스팟)
let API_KEY = "sk_live_1234567890abcdef"   // 하드코딩 API 키 (보안 핫스팟)

protocol BadProtocol {
    func doSomething(_ value: Any?) -> Any?
    func risky(_ text: String) -> String
}

class UnsafeManager: NSObject, URLSessionDelegate, BadProtocol {
    public var users: [String] = [] // public mutable state
    public var dataSource: [String: Any] = [:]

    // 불필요한 싱글톤 흉내
    static let shared = UnsafeManager()

    // 마법값 범벅
    private let retryCount = 3
    private let timeoutSeconds = 42
    private let baseURL = "http://example.com" // HTTP (ATS 위반 가능성)
    private let fixedDelay = 1.337

    // 강제 언래핑과 강제 캐스팅 연타
    func doSomething(_ value: Any?) -> Any? {
        let x = value as! [String: Any] // 위험한 as!
        let y = x["number"] as! Int     // 위험한 as!
        return y + 1
    }

    // 취약한 난수: 토큰 생성에 Int.random 사용 (보안 핫스팟)
    func generateInsecureToken() -> String {
        let n = Int.random(in: 0..<999_999) // crypto로 쓰면 안 됨
        return "T-\(n)"
    }

    // 취약한 해시: MD5 사용
    func insecureHash(_ input: String) -> String {
        let digest = Insecure.MD5.hash(data: input.data(using: .utf8)!)
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }

    // 빈 catch, 예외 삼키기
    func risky(_ text: String) -> String {
        do {
            if text.count > 10 {
                throw NSError(domain: "Bad", code: -1)
            }
            return text.uppercased()
        } catch {
            // 아무것도 안 함 (문제)
        }
        return text
    }

    // 메인스레드 블로킹, 로그로 민감정보 노출
    func logAndBlock() {
        print("API_KEY=\(API_KEY), PASSWORD=\(HARDCODED_PASSWORD)") // 민감정보 로그
        Thread.sleep(forTimeInterval: 2) // 메인 블로킹 가능성
    }

    // 중복 코드 #1
    func duplicate1(a: Int, b: Int) -> Int {
        if a > 10 {
            if b > 10 {
                if a % 2 == 0 {
                    if b % 3 == 0 {
                        return a + b
                    } else {
                        return a - b
                    }
                } else {
                    if b % 5 == 0 {
                        return a * b
                    } else {
                        return a / (b == 0 ? 1 : b)
                    }
                }
            } else {
                return a + 42 + b
            }
        } else {
            return (a - 7) * (b + 13)
        }
    }

    // 중복 코드 #2 (duplicate1과 거의 동일)
    func duplicate2(a: Int, b: Int) -> Int {
        if a > 10 {
            if b > 10 {
                if a % 2 == 0 {
                    if b % 3 == 0 {
                        return a + b
                    } else {
                        return a - b
                    }
                } else {
                    if b % 5 == 0 {
                        return a * b
                    } else {
                        return a / (b == 0 ? 1 : b)
                    }
                }
            } else {
                return a + 42 + b
            }
        } else {
            return (a - 7) * (b + 13)
        }
    }

    // 거대한 복잡도 메서드
    func overComplex(_ s: String) -> Int {
        var score = 0
        for c in s {
            switch c {
            case "a", "A": score += 1
            case "b", "B": score += 2
            case "c", "C": score += 3
            case "d", "D": score += 4
            case "e", "E": score += 5
            case "f", "F": score += 6
            case "g", "G": score += 7
            case "h", "H": score += 8
            case "i", "I": score += 9
            case "j", "J": score += 10
            case "k", "K": score += 11
            case "l", "L": score += 12
            case "m", "M": score += 13
            case "n", "N": score += 14
            case "o", "O": score += 15
            case "p", "P": score += 16
            case "q", "Q": score += 17
            case "r", "R": score += 18
            case "s", "S": score += 19
            case "t", "T": score += 20
            case "u", "U": score += 21
            case "v", "V": score += 22
            case "w", "W": score += 23
            case "x", "X": score += 24
            case "y", "Y": score += 25
            case "z", "Z": score += 26
            default:
                if c == "!" { score += 100 } else if c == "?" { score += 50 } else if c == "#" { score -= 10 } else { score += 0 }
            }
        }
        if score > 1000 { print("High score") } else { if score > 500 { print("Mid score") } else { if score > 100 { print("Low score") } else { print("Tiny score") } } }
        return score
    }

    // 비검증 입력으로 SQL 문자열 조립 (SQL Injection 위험)
    func findUserSQL(name: String) -> String {
        // 예: SELECT * FROM users WHERE name = '<입력값>'
        let query = "SELECT * FROM users WHERE name = '\(name)';" // 취약
        return query
    }

    // HTTP 사용 + 인증서 무시 설정(보안 치명적)
    func fetchInsecure(path: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "\(baseURL)/\(path)")! // 강제 언래핑
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        session.dataTask(with: url) { data, _, _ in
            // strong self 캡처 (메모리 릭 가능)
            self.users.append("fetched")
            completion(data.flatMap { String(data: $0, encoding: .utf8) })
        }.resume()
    }

    // 모든 인증서 신뢰 (절대 금지)
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let trust = challenge.protectionSpace.serverTrust {
            let cred = URLCredential(trust: trust) // 검증 없이 통과
            completionHandler(.useCredential, cred)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    // deprecated API 사용
    func unsafeUnarchive(_ data: Data) -> Any? {
        // 경고: deprecated
        return NSKeyedUnarchiver.unarchiveObject(with: data)
    }

    // 불필요한 해시값 의존 (hashValue는 안정적 식별자 아님)
    func unstableKey(_ obj: NSObject) -> String {
        return "key_\(obj.hashValue)"
    }

    // 무의미한 예외 사용 + 강제 언래핑
    func nonsense(_ json: String) -> [String: Any] {
        let data = json.data(using: .utf8)!
        let any = try? JSONSerialization.jsonObject(with: data, options: [])
        return any as! [String: Any]
    }

    // 리소스 누수 가능성: 파일 핸들 제대로 닫지 않거나 에러 무시
    func readFile(path: String) -> String {
        let handle = FileHandle(forReadingAtPath: path)! // 강제 언래핑
        let d = handle.readDataToEndOfFile()
        // 닫지 않음 (누수 가능)
        return String(data: d, encoding: .utf8) ?? ""
    }

    // 불필요한 동기화/데드락 유발 소지
    func badLocking() {
        let sem = DispatchSemaphore(value: 0)
        DispatchQueue.main.async {
            // 메인에서 신호 주지 않으면 영원히 대기할 수 있음
            // sem.signal() 누락
        }
        _ = sem.wait(timeout: .now() + 0.1)
    }

    // 불필요한 옵셔널 체이닝/강제 언래핑 혼용
    func mixedOptionals(_ s: String?) -> Int {
        if s != nil {
            return s!.count
        }
        return (s?.count)!
    }

    // 무한 재귀 위험 (조건부 탈출 부실)
    func badRecursive(_ n: Int) -> Int {
        if n == 0 { return 0 }
        if n < 0 { return badRecursive(n - 1) } // 더 악화
        return badRecursive(n - 1) + 1
    }

    // 쓸데없는 큰 switch + 디폴트 빠짐
    func weekday(_ i: Int) -> String {
        switch i {
        case 1: return "Mon"
        case 2: return "Tue"
        case 3: return "Wed"
        case 4: return "Thu"
        case 5: return "Fri"
        case 6: return "Sat"
        // default 없음 (문제)
        case 7: return "Sun"
        default: return "Unknown"
        }
    }

    // 의미 없는 파라미터, 미사용 변수 잔뜩
    func junk(a: Int, b: Int, c: Int) -> Int {
        _ = a + b + c
        let x = 10; let y = 20; let z = 30
        return x + y + z // a,b,c 무시
    }

    // 강제 try
    func forceTry() {
        let url = URL(string: "http://invalid")!
        let data = try! Data(contentsOf: url) // 강제 try (크래시 위험)
        print(data.count)
    }

    // 불필요한 중첩/로컬 함수
    func nested() {
        func a() { func b() { func c() { print("deep") } ; c() } ; b() }
        a()
    }
}

// 사용 예시(분석용 실행 경로)
func runBadDemo() {
    let m = UnsafeManager.shared
    globalCounter += 1
    globalCache["k"] = Date()
    _ = m.generateInsecureToken()
    _ = m.insecureHash("secret")
    m.logAndBlock()
    _ = m.duplicate1(a: 11, b: 13)
    _ = m.duplicate2(a: 11, b: 13)
    _ = m.overComplex("AbcDef!!??##")
    _ = m.findUserSQL(name: "admin' OR 1=1 --")
    m.fetchInsecure(path: "api/v1/info") { text in
        print(text ?? "nil")
    }
    _ = m.unsafeUnarchive(Data())
    _ = m.unstableKey(NSObject())
    _ = m.nonsense("{\"k\":1}")
    _ = m.readFile(path: "/etc/hosts")
    m.badLocking()
    _ = m.mixedOptionals(nil)
    _ = m.badRecursive(3)
    _ = m.weekday(9) // default 없음
    _ = m.junk(a: 1, b: 2, c: 3)
    // m.forceTry() // 실행 시 크래시 가능, 주석 풀면 더 많은 이슈
    m.nested()
}

// 주석으로 가려진 죽은 코드 예시 (코드 스멜 유발 가능)
// f


import Foundation

public final class WMFArticleDataController {
    
    private let mediaWikiService: WMFService?
    
    public init(mediaWikiService: WMFService? = WMFDataEnvironment.current.mediaWikiService) {
        self.mediaWikiService = mediaWikiService
    }
    
    public struct ArticleInfoRequest {
        let needsWatchedStatus: Bool
        let needsRollbackRights: Bool
        let needsCategories: Bool
        
        public init(needsWatchedStatus: Bool, needsRollbackRights: Bool, needsCategories: Bool) throws {
            self.needsWatchedStatus = needsWatchedStatus
            self.needsRollbackRights = needsRollbackRights
            self.needsCategories = needsCategories
            
            guard needsWatchedStatus == true ||
                    needsRollbackRights == true ||
                    needsCategories == true else {
                throw WMFServiceError.invalidRequest
            }
        }
    }
    
    struct ArticleInfoResponse: Codable {

        struct Query: Codable {

            struct Page: Codable {
                
                struct Category: Codable {
                    let ns: Int
                    let title: String
                }
                
                let title: String
                let watched: Bool?
                let watchlistexpiry: String?
                let categories: [Category]?
            }

            struct UserInfo: Codable {
                let name: String
                let rights: [String]
            }

            let pages: [Page]
            let userinfo: UserInfo?
        }

        let query: Query
    }
    
    public struct WMFArticleInfoResponse {
        public let watched: Bool
        public let watchlistExpiry: Date?
        public let userHasRollbackRights: Bool?
        public let categories: [String]
    }

    
    /// Fetches possible info needed from MediaWiki for a particular article. Watch status, user rollback rights, categories. The idea here is to fetch all we need for article display in a single call so the app only needs to make an API call to MediaWiki once upon article view.
    /// - Parameters:
    ///   - title: Title of the article
    ///   - project: Project the article belongs to (EN Wiki, etc)
    ///   - request: Request struct to fetch certain pieces of data. So far can support watchlist status and user rollback rights.
    ///   - completion: Completion block called when API has completed
    public func fetchArticleInfo(title: String, project: WMFProject, request: ArticleInfoRequest, completion: @escaping (Result<WMFArticleInfoResponse, Error>) -> Void) {
         
        guard let mediaWikiService else {
             completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
             return
         }
        

         var parameters = [
                     "action": "query",
                     "titles": title,
                     "errorsuselocal": "1",
                     "errorformat": "html",
                     "format": "json",
                     "formatversion": "2"
                 ]
        
        if request.needsWatchedStatus {
            parameters["prop"] = "info"
            parameters["inprop"] = "watched"
        }
        
        if request.needsCategories {
            if request.needsWatchedStatus {
                parameters["prop"] = "info|categories"
            } else {
                parameters["prop"] = "categories"
            }
            
            parameters["clshow"] = "!hidden"
            parameters["cllimit"] = "500"
        }

        if request.needsRollbackRights {
            parameters["meta"] = "userinfo"
            parameters["uiprop"] = "rights"
        }

         guard let url = URL.mediaWikiAPIURL(project: project) else {
             return
         }

         let request = WMFMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWiki, parameters: parameters)

        mediaWikiService.performDecodableGET(request: request) { (result: Result<ArticleInfoResponse, Error>) in
             switch result {
             case .success(let response):

                guard let firstPage = response.query.pages.first else {
                 completion(.failure(WMFDataControllerError.unexpectedResponse))
                 return
                }

                let watched = firstPage.watched ?? false
                let userHasRollbackRights = response.query.userinfo?.rights.contains("rollback")
                 
                var watchlistExpiry: Date? = nil
                if let watchlistExpiryString = firstPage.watchlistexpiry {
                  watchlistExpiry = DateFormatter.mediaWikiAPIDateFormatter.date(from: watchlistExpiryString)
                }
                 
                 var categoryTitles: [String] = []
                 if let responseCategories = firstPage.categories {
                    for category in responseCategories {
                        categoryTitles.append(category.title)
                    }
                 }

                 let status = WMFArticleInfoResponse(watched: watched, watchlistExpiry: watchlistExpiry, userHasRollbackRights: userHasRollbackRights, categories: categoryTitles)
                 completion(.success(status))
             case .failure(let error):
                 completion(.failure(WMFDataControllerError.serviceError(error)))
             }
         }
     }
}
