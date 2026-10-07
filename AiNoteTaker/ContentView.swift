import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var store: NoteStore
    
    @StateObject private var voiceRecorder = VoiceRecorder()
    @StateObject private var geminiService = GeminiService()
    
    @State private var showAddNote = false
    @State private var editingNote: Note? = nil
    
    @State private var aiResult: GeminiNoteResult? = nil
    
    var body: some View {
        
        NavigationStack {
            
            VStack(spacing: 25) {
                
                // MARK: - Voice Icon
                
                Image(
                    systemName: voiceRecorder.isRecording
                    ? "waveform"
                    : "waveform.and.mic"
                )
                .font(.system(size: 70))
                .foregroundColor(
                    voiceRecorder.isRecording ? .red : .blue
                )
                
                // MARK: - Title
                
                Text("AI Note Taker")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(
                    voiceRecorder.isRecording
                    ? "Listening..."
                    : "Create reminders using your voice or text."
                )
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
                
                // MARK: - Voice Button
                
                
                Button {
                    if voiceRecorder.isRecording {
                        voiceRecorder.stopRecording()
                    } else {
                        voiceRecorder.startRecording()
                    }
                } label: {
                
                    Label(
                        voiceRecorder.isRecording
                        ? "Stop Recording"
                        : "Record Voice",
                        systemImage: voiceRecorder.isRecording
                        ? "stop.fill"
                        : "mic.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(
                    voiceRecorder.isRecording
                    ? .red
                    : .blue
                )
                
                // MARK: - Recognized Text
                
                if !voiceRecorder.recognizedText.isEmpty {
                    
                    VStack(alignment: .leading, spacing: 8) {
                        
                        Text("Recognized Text")
                            .font(.headline)
                        
                        Text(voiceRecorder.recognizedText)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                            .padding()
                            .background(
                                Color.gray.opacity(0.1)
                            )
                            .cornerRadius(12)
                    }
                }
                
                // MARK: - Gemini AI Button
                
                if !voiceRecorder.recognizedText.isEmpty {
                    
                    Button {
                        
                        Task {
                            aiResult = await geminiService.generateNote(
                                from: voiceRecorder.recognizedText
                            )
                        }
                        
                    } label: {
                        
                        if geminiService.isLoading {
                            
                            ProgressView()
                                .frame(maxWidth: .infinity)
                            
                        } else {
                            
                            Label(
                                "Create Note with AI",
                                systemImage: "sparkles"
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .disabled(geminiService.isLoading)
                }
                
                // MARK: - Gemini Error
                
                if !geminiService.errorMessage.isEmpty {
                    
                    Text(geminiService.errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                
                // MARK: - AI Result
                
                if let result = aiResult {
                    
                    VStack(
                        alignment: .leading,
                        spacing: 12
                    ) {
                        
                        Text("AI Generated Note")
                            .font(.headline)
                        
                        VStack(
                            alignment: .leading,
                            spacing: 8
                        ) {
                            
                            Text("Title")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text(result.title)
                                .font(.headline)
                            
                            Divider()
                            
                            Text("Description")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text(result.description)
                            
                            Divider()
                            
                            HStack {
                                
                                Label(
                                    result.date,
                                    systemImage: "calendar"
                                )
                                
                                Spacer()
                                
                                Label(
                                    result.time,
                                    systemImage: "clock"
                                )
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            Button {
                                showAddNote = true
                            } label: {
                                Label("Review & Save Note", systemImage: "checkmark.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                            .padding(.top, 4)
                        }
                        .padding()
                        .background(
                            Color.purple.opacity(0.08)
                        )
                        .cornerRadius(12)
                    }
                }
                
                // MARK: - Voice Error
                
                if !voiceRecorder.errorMessage.isEmpty {
                    
                    Text(voiceRecorder.errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                
                // MARK: - Text Button
                
                Button {
                    showAddNote = true
                } label: {
                    Label(
                        "Type a Note",
                        systemImage: "square.and.pencil"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Divider()
                    .padding(.vertical)
                
                // MARK: - Notes
                
                if store.notes.isEmpty {
                    
                    VStack(spacing: 10) {
                        
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("No reminders yet")
                            .foregroundColor(.gray)
                        
                        Text("Tap Type a Note to add one")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                } else {
                    
                    List {
                        
                        ForEach(store.notes) { note in
                            
                            Button {
                                editingNote = note
                            } label: {
                                
                                VStack(
                                    alignment: .leading,
                                    spacing: 6
                                ) {
                                    
                                    Text(note.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    if !note.description.isEmpty {
                                        
                                        Text(note.description)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .lineLimit(2)
                                    }
                                    
                                    Label(
                                        note.reminderDate.formatted(
                                            date: .abbreviated,
                                            time: .shortened
                                        ),
                                        systemImage: "bell.fill"
                                    )
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { indexSet in
                            
                            indexSet.forEach { index in
                                
                                let note = store.notes[index]
                                
                                NotificationManager.shared
                                    .cancelNotification(for: note)
                                
                                store.delete(note)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("Home")
            
            // MARK: - New Note
            
            .sheet(isPresented: $showAddNote) {
                
                NavigationStack {
                    
                    AddNoteView(
                        aiResult: aiResult
                    )
                    .environmentObject(store)
                }
            }
            
            // MARK: - Edit Note
            
            .navigationDestination(item: $editingNote) { note in
                
                AddNoteView(editingNote: note)
                    .environmentObject(store)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NoteStore())
}
