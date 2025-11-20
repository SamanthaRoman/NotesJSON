//
//  ExportImport.swift
//  NotesJSON
//
//  Created by Samantha Roman on 11/17/25.
//

import Foundation
import CoreData

// MARK: - DTO for portable JSON
public struct NoteDTO: Codable, Hashable {
    public let title: String
    public let content: String
    public let timestamp: Data
}

struct NoteKey: Hashable {
    let title: String
    let timestamp: Date
}

// Map Core Data -> DTO
public func makeDTOs(from notes: [Note]) -> [NoteDTO] {
    notes.compactMap {n in
        guard let title = n.title,
              let content = n.content,
              let ts = n.timestamp else { return nill }
        return NoteDTO(title: title, content: content, timestamp: ts)
    }
}

//Fetch all notes with a consistent sort
public func fetchAllNotes(_ ctx: NSManagedObjectContext) throws -> [Note] {
    let req: NSFetchRequest<Note> = Note.fetchRequest()
    req.sortDescriptors = [NSSortDescriptor(keyPath: \Note.timestamp, ascending: false)]
    return try ctx.fetch(req)
}

// MARK: - FileManager helpers
public func documentsURL() -> URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
}

public func printDocumentsURL() {
    let u = documentsURL()
    print("📁 Documents URL:", u.path)
}

//Programmatic export to Documents with timestamped filename
@discardableResult
public func exportNotesToDocuments(_ notes: [Note]) throws -> URL {
    let dtos = makeDTOs(from: notes)
    let data = try JSONEncoder().encode(dtos)
    let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
    let url = documentsURL().appendingPathComponent("notes-\(stamp).json")
    try data.write(to: url, options: .atomic)
    print("✅ Exported to:", url.path)
    return url
}

// Decode from Data -> [DTO]
public func decodeNoteDTOs(from data: Data) throws -> [NoteDTO] {
    try JSONDecoder().decode([NoteDTO].self, from: data)
}

// Import from URL -> Core Data
public func importNotes(from url: URL, into ctx: NSManagedObjectContext, replace: Bool) throws {
    let data = try Data(contentsOf: url)
    let dtos = try decodeNoteDTOs(from: data)
    try importNotes(from: dtos, into: ctx, replace: replace)
}

// Import from DTOs -> Core Data (replace or merge)
public func importNotes(from dtos: [NoteDTO], into ctx: NSManagedObjectContext, replace: Bool) throws {
    if replace {
        try deleteAllNotes(in: ctx)
    }
    // Build a set for dedupe if merging
    var existingKeys = Set<NoteKey>()
    
    if !replace {
        let existing = try fetchAllNotes(ctx)
        existingKeys = Set(existing.compactMap { keyFor($0) })
    }
    
    for dto in dtos {
        let key = NoteKey(title: dto.title, timestamp: dto.timestamp)
        if replace || !existingKeys.contains(key) {
            let n = Note(context: ctx)
            n.title = dto.title
            n.content = dto.content
            n.timestamp = dto.timestamp
        }
    }
    try ctx.save()
    print ("✅ Import complete. replace=\(replace) count=\(dtos.count)")
}

// Delete all notes (batch delete)
public func deleteAllNotes(in ctx: NSManagedObjectContext) throws {
    let f: NSFetchRequest<NSFetchRequestResult> = Note.fetchRequest()
    let d = NSBatchDeleteRequest(fetchRequest: f)
    try ctx.save()
    print("🗑️ All notes deleted.")
}

// Build a dedupe key for a Note
private func keyFor(_ note: Note) -> NoteKey? {
    guard let title = note.title, let ts = note.timestamp else { return nil }
    return NoteKey(title: title, timestamp: ts)
}















