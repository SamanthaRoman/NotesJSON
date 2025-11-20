import SwiftUI
import UniformTypeIdentifiers

// A minimal FileDocument wrapperfor exporting JSON via .fileExporter
public struct JSONFile: FileDocument {
    public static var readableContentTypes: [UTType] = [.json]
    public var data: Data
    
    public init(data: Data) { self.data = data } //initallizer called to export - feed data externally and mapped internally
    
    public init(configuration: ReadConfiguration) throws { // initializer called to import - overload
        self.data = configuration.file.regularFileContents ?? Data() // if regularFileContents is nill store data content
    }
    
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { // return an instance of FileWrapper
        .init(regularFileWithContents: data)
    }
}
