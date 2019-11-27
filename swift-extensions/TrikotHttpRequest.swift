import Foundation
import TRIKOT_FRAMEWORK_NAME

public class TrikotHttpRequest: NSObject, HttpRequest {
    private let requestBuilder: RequestBuilder
    private let httpLogLevel: TrikotHttpLogLevel

    init(_ requestBuilder: RequestBuilder, httpLogLevel: TrikotHttpLogLevel) {
        self.requestBuilder = requestBuilder
        self.httpLogLevel = httpLogLevel
    }

    public func execute(cancellableManager: CancellableManager) -> Publisher {
        let resultPublisher = Publishers().behaviorSubject(value: nil)

        if let url = URL(string: (requestBuilder.baseUrl ?? "") + (requestBuilder.path ?? "")) {
            let urlRequest = NSMutableURLRequest(url: url, cachePolicy: requestBuilder.nsCachePolicy(), timeoutInterval: TimeInterval(requestBuilder.timeout))
            urlRequest.httpMethod = requestBuilder.method.name.uppercased()

            requestBuilder.headers.forEach { key, value in
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }

            if let body = requestBuilder.body as? KotlinByteArray {
                urlRequest.httpBody = ByteArrayNativeUtils().convert(byteArray: body)
            } else if let body = requestBuilder.body as? String {
                urlRequest.httpBody = body.data(using: .utf8)
            }

            let requestStartTime = Date()
            logRequest(urlRequest)
            let sessionTask = URLSession.shared.dataTask(with: urlRequest as URLRequest) { (data, urlResponse, error) in
                self.logResponse(request: urlRequest, data: data, urlResponse: urlResponse, error: error, requestStartTime: requestStartTime)
                if let error = error {
                    resultPublisher.error = MrFreeze().freeze(objectToFreeze: KotlinThrowable(message: error.localizedDescription)) as? KotlinThrowable
                } else {
                    let iosResponse = TrikotHttpResponse(data: data, response: urlResponse)
                    MrFreeze().freeze(objectToFreeze: iosResponse)
                    resultPublisher.value = iosResponse
                }
            }
            sessionTask.resume()
        } else {
            resultPublisher.error = KotlinThrowable(message: "Unable to create a valid URL")
        }

        return MrFreeze().freeze(objectToFreeze: resultPublisher) as! Publisher
    }

    private func logRequest(_ request: NSURLRequest) {
        guard httpLogLevel != .none else { return }

        var requestLog = "<Http Request>\n"
        requestLog += "\(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "<invalid url>")" + "\n"
        if httpLogLevel == .verbose {
            if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
                requestLog += "Headers:\n"
                headers.forEach { (key, value) in
                    requestLog += "  \(key): \(value)\n"
                }
            }
            if let body = request.httpBody {
                requestLog += "Body:\n"
                requestLog += (String(bytes: body, encoding: .utf8) ?? "<invalid body format>") + "\n"
            }
        }
        requestLog += "</Http Request>"
        print(requestLog)
    }

    private func logResponse(request: NSURLRequest, data: Data?, urlResponse: URLResponse?, error: Error?, requestStartTime: Foundation.Date) {
        var requestLog = "<Http Reponse>\n"
        requestLog += ("\(request.url?.absoluteString ?? "<invalid url>")") + "\n"
        let requestionDurationInMs = Int(Date().timeIntervalSince(requestStartTime) * 1000)
        requestLog += "Duration: \(requestionDurationInMs)ms\n"
        if let error = error {
            requestLog += "Error: \(error.localizedDescription)\n"
        } else if let httpUrlResponse = urlResponse as? HTTPURLResponse {
            requestLog += "Status Code: \(httpUrlResponse.statusCode)\n"
            if httpLogLevel == .verbose {
                if let headers = httpUrlResponse.allHeaderFields as? [String: String], !headers.isEmpty {
                    requestLog += "Headers:\n"
                    headers.forEach { (key, value) in
                        requestLog += "  \(key): \(value)\n"
                    }
                }
                if let data = data {
                    requestLog += "Body:\n"
                    requestLog += (String(bytes: data, encoding: .utf8) ?? "<invalid body format>") + "\n"
                }
            }
        }
        requestLog += "</Http Reponse>"
        print(requestLog)
    }
}

extension RequestBuilder {
    func nsCachePolicy() -> NSURLRequest.CachePolicy {
        switch method {
        case HttpMethod.post, HttpMethod.put, HttpMethod.delete_: return NSURLRequest.CachePolicy.reloadIgnoringCacheData
        default: return cachePolicy.nsCachePolicy()
        }
    }
}

extension CachePolicy {
    func nsCachePolicy() -> NSURLRequest.CachePolicy {
        switch self {
        case .reloadIgnoringCacheData : return NSURLRequest.CachePolicy.reloadIgnoringCacheData
        default: return NSURLRequest.CachePolicy.useProtocolCachePolicy
        }
    }
}
