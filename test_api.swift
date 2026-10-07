import Foundation

let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key="
let url = URL(string: urlString)!
var request = URLRequest(url: url)
request.httpMethod = "POST"

let dispatchGroup = DispatchGroup()
dispatchGroup.enter()

let task = URLSession.shared.dataTask(with: request) { data, response, error in
    if let httpResponse = response as? HTTPURLResponse {
        print("Status Code: \(httpResponse.statusCode)")
    }
    if let data = data, let body = String(data: data, encoding: .utf8) {
        print("Body: \(body)")
    }
    dispatchGroup.leave()
}
task.resume()

dispatchGroup.wait()
