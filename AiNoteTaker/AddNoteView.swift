import SwiftUI

struct AddNoteView: View {
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: NoteStore
    
    // Existing note হলে edit mode
    var editingNote: Note? = nil
    
    // Gemini থেকে AI result এলে এখানে আসবে
    var aiResult: GeminiNoteResult? = nil
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var reminderDate: Date = Date().addingTimeInterval(3600)
    
    var body: some View {
        
        Form {
            
            // MARK: - Note Details
            
            Section("Note Details") {
                
                TextField(
                    "Title",
                    text: $title
                )
                
                TextField(
                    "Description",
                    text: $description,
                    axis: .vertical
                )
                .lineLimit(3...6)
            }
            
            // MARK: - Reminder
            
            Section("Reminder") {
                
                DatePicker(
                    "Date & Time",
                    selection: $reminderDate,
                    displayedComponents: [
                        .date,
                        .hourAndMinute
                    ]
                )
            }
            
            // MARK: - Save
            
            Section {
                
                Button {
                    saveNote()
                } label: {
                    
                    Text(
                        editingNote == nil
                        ? "Save"
                        : "Update"
                    )
                    .frame(maxWidth: .infinity)
                    .fontWeight(.semibold)
                }
                .disabled(
                    title
                        .trimmingCharacters(
                            in: .whitespaces
                        )
                        .isEmpty
                )
            }
        }
        .navigationTitle(
            editingNote == nil
            ? "New Note"
            : "Edit Note"
        )
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadInitialData()
        }
    }
    
    // MARK: - Load Initial Data
    
    private func loadInitialData() {
        
        // যদি edit mode হয়
        if let note = editingNote {
            
            title = note.title
            description = note.description
            reminderDate = note.reminderDate
            
            return
        }
        
        // যদি Gemini থেকে result আসে
        if let result = aiResult {
            
            title = result.title
            description = result.description
            
            if let date = makeDate(
                dateString: result.date,
                timeString: result.time
            ) {
                reminderDate = date
            }
        }
    }
    
    // MARK: - Convert AI Date + Time to Date
    
    private func makeDate(
        dateString: String,
        timeString: String
    ) -> Date? {
        
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(
            identifier: "en_US_POSIX"
        )
        formatter.timeZone = .current
        
        return formatter.date(
            from: "\(dateString) \(timeString)"
        )
    }
    
    // MARK: - Save Note
    
    private func saveNote() {
        
        let trimmedTitle = title.trimmingCharacters(
            in: .whitespaces
        )
        
        let trimmedDesc = description.trimmingCharacters(
            in: .whitespaces
        )
        
        // MARK: UPDATE
        
        if let existing = editingNote {
            
            var updated = existing
            
            updated.title = trimmedTitle
            updated.description = trimmedDesc
            updated.reminderDate = reminderDate
            
            store.update(updated)
            
            // পুরনো notification cancel
            NotificationManager.shared
                .cancelNotification(for: existing)
            
            // নতুন notification schedule
            NotificationManager.shared
                .scheduleNotification(for: updated)
            
        } else {
            
            // MARK: NEW NOTE
            
            let newNote = Note(
                title: trimmedTitle,
                description: trimmedDesc,
                reminderDate: reminderDate
            )
            
            store.add(newNote)
            
            // Notification schedule
            NotificationManager.shared
                .scheduleNotification(for: newNote)
        }
        
        dismiss()
    }
}

#Preview("New Note") {
    
    NavigationStack {
        
        AddNoteView()
            .environmentObject(NoteStore())
    }
}
