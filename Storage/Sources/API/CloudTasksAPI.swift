//
//  ObjectACLAPI.swift
//  GoogleCloudKit
//
//  Created by Andrew Edwards on 5/20/18.
//

import NIO
import NIOHTTP1
import Foundation


public protocol TasksAPI {
  func create(
      location: String,
      queue: String,
      serviceAccount: String,
      httpMethod: String,
      url: String,
      body: Data) -> EventLoopFuture<EmptyResponse>
}

struct CreateRequestOidc: Codable {
  public var serviceAccountEmail: String
}

struct CreateRequestHttp: Codable {
  public var url: String
  public var httpMethod: String
  public var body: String
  public var oidcToken: CreateRequestOidc
}

struct CreateRequestTask: Codable {
  public var httpRequest: CreateRequestHttp
}

struct CreateRequest: Codable {
  public var task: CreateRequestTask
  public var responseView: String
}

public final class GoogleCloudTasksApi: TasksAPI {
    let endpoint = "https://cloudtasks.googleapis.com/v2beta3/"
    let request: GoogleCloudStorageRequest
    let encoder = JSONEncoder()
    init(request: GoogleCloudStorageRequest) {
        self.request = request
    }

  public func create(
    location: String,
    queue: String,
    serviceAccount: String,
    httpMethod: String,
    url: String,
    body: Data) -> EventLoopFuture<EmptyResponse> {

    let project = "projects/\(self.request.project)"
    let location = "locations/\(location)"
    let queue = "queues/\(queue)"
    let frag = "\(project)/\(location)/\(queue)"
    let url = "\(endpoint)\(frag)/tasks"
    
    let req = CreateRequest(
      task: CreateRequestTask(
        httpRequest: CreateRequestHttp(
          url: url,
          httpMethod: httpMethod,
          body: body.base64EncodedString(),
          oidcToken: CreateRequestOidc(
            serviceAccountEmail: serviceAccount
          )
        )
      ),
      responseView: "BASIC"
    )
    
    do {
      let data = try encoder.encode(req)
      return request.send(
        method: .POST,
        path: url,
        body: .data(data)
      )
    } catch {
      return self.request.eventLoop.makeFailedFuture(error)
    }
  }
}
