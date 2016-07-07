import UIKit
import XCPlayground

XCPSetExecutionShouldContinueIndefinitely(true)

func makeRequest(request: NSURLRequest, onCompletion: (data: NSData?, response: NSURLResponse?,error: NSError?) -> Void) {
  let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
  let dataTask = session.dataTaskWithRequest(request, completionHandler: onCompletion)
  dataTask.resume()
}

enum HTTPMethod : String {
  case GET = "GET"
  case POST = "POST"
  case PUT = "PUT"
  case DELETE = "DELETE"
}
enum HTTPError : ErrorType {
  case GenericError
  case FoundationError(NSError)
}

protocol Requestable {
  func getRequest() -> NSURLRequest
}

extension Requestable {
  typealias GenericSuccessBlock = (data :NSData, response: NSURLResponse) -> Void
  typealias GenericFailureBlock = (error: HTTPError) -> Void
  func execute(onSuccess: GenericSuccessBlock, onFailure: GenericFailureBlock) {
    makeRequest(getRequest()) { (data, response, error) in
      if let dataUnwrapped = data,responseUnwrapped = response {
        onSuccess(data: dataUnwrapped, response: responseUnwrapped)
      } else {
        onFailure(error: HTTPError.FoundationError(error!))
      }
    }
  }
}

protocol HTTPRequestable : Requestable {
  func getEndpoint() -> NSURL
  func getHTTPBody() -> NSData?
  func getHTTPMethod() -> HTTPMethod
}

extension HTTPRequestable {
  func getRequest() -> NSURLRequest {
    let request = NSMutableURLRequest(URL: getEndpoint())
    request.HTTPBody = getHTTPBody()
    request.HTTPMethod = getHTTPMethod().rawValue
    return request
  }
}

protocol HTTPGetRequest : HTTPRequestable {
  func getURLString() -> String
  func getQueryParameters() -> [String : String]?
}

extension HTTPGetRequest {
  func getEndpoint() -> NSURL {
    guard let queryParams = getQueryParameters() else {
      return NSURL(string: getURLString())!
    }
    let components = NSURLComponents(string: getURLString())!
    let queryItems = queryParams.map { (key,value) -> NSURLQueryItem in
      return NSURLQueryItem(name: key, value: value)
    }
    components.queryItems = queryItems
    return components.URL!
  }

  func getHTTPBody() -> NSData? {
    return nil
  }

  func getHTTPMethod() -> HTTPMethod {
    return .GET
  }
}

struct HTTPBinRequest : HTTPGetRequest {
  let queryParams : [String : String]

  func getQueryParameters() -> [String : String]? {
    return queryParams
  }

  func getURLString() -> String {
    return "https://httpbin.org/get"
  }
}

let request = HTTPBinRequest(queryParams: ["userId" : "123446"])
request.execute({ (data, response) in
  let string = NSString(data: data, encoding: NSUTF8StringEncoding)!
  }) { (error) in
}

protocol ResponseParsable {
  associatedtype ResponseModel
  func parse(data: NSData) -> ResponseModel
}

struct HTTPBinResponse {
  let origin : String
  let url : String
}

extension HTTPBinRequest : ResponseParsable {
  func parse(data: NSData) -> HTTPBinResponse {
    let dict = try! NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as! [String : AnyObject]
    let origin = dict["origin"] as! String
    let url = dict["url"] as! String
    return HTTPBinResponse(origin: origin, url: url)
  }
}

extension Requestable where Self : ResponseParsable {
  typealias SucessCallback = (response: Self.ResponseModel) -> Void
  func execute(onSuccess: SucessCallback, onFailure: GenericFailureBlock) {
    execute({ (data, response) in
      onSuccess(response: self.parse(data))
    }, onFailure: onFailure)
  }
}


let request2 = HTTPBinRequest(queryParams: ["hwllo": "world"])
request2.execute({ (response) in
  print(response.origin)
  print(response.url)
  }) { (error) in
}

