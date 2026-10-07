import Foundation
import Combine

struct GeminiNoteResult: Codable {
    let title: String
    let description: String
    let date: String
    let time: String
}

@MainActor
final class GeminiService: ObservableObject {
    
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private var apiKey: String {
        ProcessInfo.processInfo.environment["Gemini_Api_Key"] ?? ""
    }
    
    func generateNote(from text: String) async -> GeminiNoteResult? {
        
        isLoading = true
        errorMessage = ""
        
        defer {
            isLoading = false
        }
        
        let urlString = "https://generativelanguage.googleapis.com/v1beta/interactions"
        
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid Gemini API URL."
            return nil
        }
        
        let today = Date().formatted(
            .dateTime
                .year()
                .month()
                .day()
        )
        
        let prompt = """
        You are an AI assistant for a reminder note-taking app.
        
        Today's date is \(today).
        
        Convert the user's spoken note into structured reminder information.
        
        User's spoken text:
        "\(text)"
        
        Rules:
        1. Create a short clear title.
        2. Create a useful description.
        3. Extract the intended reminder date.
        4. Extract the intended reminder time.
        5. If the user says tomorrow, calculate the date from today's date.
        6. If no date is mentioned, use today's date.
        7. If no time is mentioned, use 09:00.
        8. Return only the requested JSON structure.
        """
        
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "title": [
                    "type": "string"
                ],
                "description": [
                    "type": "string"
                ],
                "date": [
                    "type": "string",
                    "description": "Date in YYYY-MM-DD format"
                ],
                "time": [
                    "type": "string",
                    "description": "Time in HH:mm 24-hour format"
                ]
            ],
            "required": [
                "title",
                "description",
                "date",
                "time"
            ]
        ]
        
        let body: [String: Any] = [
            "model": "gemini-3.5-flash-lite",
            "input": prompt,
            "response_format": [
                "type": "text",
                "mime_type": "application/json",
                "schema": schema
            ]
        ]
        
        do {
            
            var request = URLRequest(url: url, timeoutInterval: 30.0)
            request.httpMethod = "POST"
            request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Invalid server response."
                return nil
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let serverMessage = String(data: data, encoding: .utf8) ?? "Unknown Gemini API error."
                print("Gemini API Error:", serverMessage)
                
                if httpResponse.statusCode == 503 {
                    errorMessage = "Gemini server is busy (503). Please try again in a few seconds."
                } else {
                    errorMessage = "Gemini API error: \(httpResponse.statusCode)"
                }
                return nil
            }
            
            let decodedResponse = try JSONDecoder().decode(GeminiInteractionResponse.self, from: data)
            
            guard let outputText = decodedResponse.outputText else {
                errorMessage = "Gemini returned no text."
                return nil
            }
            
            guard let jsonData = outputText.data(using: .utf8) else {
                errorMessage = "Could not read Gemini JSON."
                return nil
            }
            
            let result = try JSONDecoder().decode(GeminiNoteResult.self, from: jsonData)
            return result
            
        } catch {
            print("Gemini error:", error)
            errorMessage = "Gemini request failed: \(error.localizedDescription)"
            return nil
        }
    }
}

// MARK: - Gemini Response

struct GeminiInteractionResponse: Decodable {
    let steps: [GeminiStep]?
    
    var outputText: String? {
        guard let steps = steps else { return nil }
        for step in steps.reversed() {
            if let content = step.content {
                for item in content.reversed() {
                    if let text = item.text {
                        return text
                    }
                }
            }
        }
        return nil
    }
}

struct GeminiStep: Decodable {
    let content: [GeminiContent]?
}

struct GeminiContent: Decodable {
    let text: String?
}
