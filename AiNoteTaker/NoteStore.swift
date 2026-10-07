import Foundation
import Combine

class NoteStore: ObservableObject {
    @Published var notes: [Note] = []

    private let saveKey = "saved_notes"

    init() {
        load()
    }

    // MARK: - Add / Delete
    func add(_ note: Note) {
        notes.append(note)
        sortAndSave()
    }

    func delete(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        save()
    }

    func update(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
            sortAndSave()
        }
    }

    // MARK: - Persistence
    private func sortAndSave() {
        notes.sort { $0.reminderDate < $1.reminderDate }
        save()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(notes)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Failed to save notes:", error)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }
        do {
            notes = try JSONDecoder().decode([Note].self, from: data)
            notes.sort { $0.reminderDate < $1.reminderDate }
        } catch {
            print("Failed to load notes:", error)
        }
    }
}
