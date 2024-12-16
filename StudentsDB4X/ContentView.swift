import SwiftUI

struct ContentView: View {
    @StateObject private var studentsClass = StudentsClass()
    private var studentsDB: StudentsDB
    @State private var selectedStudentID: String?

    @State private var uploadStatus: String? // Pro zobrazení statusu uploadu

    init() {
        let studentsClass = StudentsClass()
        self._studentsClass = StateObject(wrappedValue: studentsClass)
        self.studentsDB = StudentsDB(studentsClass: studentsClass)
    }
    
    var body: some View {
        NavigationSplitView {
            VStack {
                Button("Refresh") {
                    studentsDB.fetchStudents()
                }
                .padding()
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                List(studentsClass.students, id: \.id, selection: $selectedStudentID) { student in
                    Text("\(student.id)")
                        .font(.headline)
                }
                .navigationTitle("Students")
            }
        } detail: {
            if let selectedID = selectedStudentID,
                let studentIndex = studentsClass.students.firstIndex(where: { $0.id == selectedID }) {
                let bindingStudent = $studentsClass.students[studentIndex]
                
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(Student.EditableFields.allCases, id: \.self) { field in
                        HStack {
                            Text(field.displayName)
                                .frame(width: 100, alignment: .trailing)
                                .font(.headline)
                            TextField("Enter \(field.displayName)", text: bindingStudent[dynamicMember: field.keyPath])
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    Spacer() // Posune tlačítko Upload dolů
                    Button("Upload") {
                        Task {
                            if await studentsDB.updateStudent(bindingStudent.wrappedValue) {
                                uploadStatus = "Student updated successfully"
                            } else {
                                uploadStatus = "Failed to update student"
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    if let status = uploadStatus {
                        Text(status)
                            .foregroundColor(status.contains("successfully") ? .green : .red)
                            .font(.caption)
                            .padding(.top)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding()
            } else {
                Text("Select a student")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding()
            }
        }
    }
}

// Rozšíření třídy Student pro dynamické přístupy a pole
extension Student {
    enum EditableFields: CaseIterable {
        case firstName, lastName, email, javaExam
        
        var displayName: String {
            switch self {
            case .firstName: return "First Name"
            case .lastName: return "Last Name"
            case .email: return "Email"
            case .javaExam: return "Java Exam"
            }
        }
        
        var keyPath: WritableKeyPath<Student, String> {
            switch self {
            case .firstName: return \Student.first_name
            case .lastName: return \Student.last_name
            case .email: return \Student.email
            case .javaExam: return \Student.java_examAsString
            }
        }
    }
    
    // Převod javaExam na řetězec
    var java_examAsString: String {
        get { "\(java_exam)" }
        set {
            if let intValue = Int(newValue) {
                // Omezíme hodnotu mezi 0 a 100
                java_exam = min(max(intValue, 0), 100)
            } else {
                // Pokud je hodnota neplatná, zanecháme původní
                print("Invalid input: \(newValue). Keeping the original value.")
            }
        }
    }
}
