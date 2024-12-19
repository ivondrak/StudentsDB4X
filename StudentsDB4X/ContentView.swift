import SwiftUI

struct ContentView: View {
    @StateObject private var studentsClass = StudentsClass()
    private var studentsDB: StudentsDB
    @State private var selectedStudentID: String?
    @State private var showNewStudentDialog = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var newStudent = Student(id: "", first_name: "Firstname", last_name: "Lastname", email: "lastname@email.com", java_exam: 0)
        

    init() {
        let studentsClass = StudentsClass()
        self._studentsClass = StateObject(wrappedValue: studentsClass)
        self.studentsDB = StudentsDB(studentsClass: studentsClass)
    }
    
    var body: some View {
        NavigationSplitView {
            VStack {
                HStack {
                    Button("Refresh") {
                        studentsDB.fetchStudents()
                    }
                    .buttonStyle(.borderedProminent)
                    //.frame(maxWidth: .infinity, alignment: .leading)

                    Button("New") {
                        newStudent = Student(id: "", first_name: "Firstname", last_name: "Lastname", email: "lastname@email.com", java_exam: 0)
                        showNewStudentDialog = true
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
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
                    HStack {
                        Button("Upload") {
                            Task {
                                if await studentsDB.updateStudent(bindingStudent.wrappedValue) {
                                    alertMessage = "Student updated successfully!"
                                } else {
                                    alertMessage = "Failed to update student!"
                                }
                                showAlert = true
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Delete") {
                            Task {
                                if await studentsDB.deleteStudent(withId: selectedID) {
                                    alertMessage = "Student deleted successfully!"
                                    studentsDB.fetchStudents()
                                    selectedStudentID = nil
                                } else {
                                    alertMessage = "Failed to delete student!"
                                }
                                showAlert = true
                            }
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding()
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Alert"),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
            } else {
                Text("Select a student")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding()
            }
        }
        .sheet(isPresented: $showNewStudentDialog) {
            let bindingNewStudent = $newStudent
            VStack {
                Text("New Student")
                    .font(.title2)
                    .padding()
                
                Form {
                    TextField("ID: ", text: $newStudent.id)
                    TextField("First Name: ", text: $newStudent.first_name)
                    TextField("Last Name: ", text: $newStudent.last_name)
                    TextField("Email: ", text: $newStudent.email)
                    TextField("Java Exam", value: $newStudent.java_exam, formatter: NumberFormatter())
                }
                .padding()

                HStack {
                    Button("Cancel") {
                        showNewStudentDialog = false
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Add") {
                        Task {
                            if studentsClass.students.contains(where: { $0.id == newStudent.id }) {
                                alertMessage = "ID already exists!"
                            } else if studentsClass.students.contains(where: { $0.email == newStudent.email }) {
                                alertMessage = "Email already exists!"
                            } else if newStudent.id.isEmpty || newStudent.first_name.isEmpty || newStudent.last_name.isEmpty || newStudent.email.isEmpty {
                                alertMessage = "All fields must be filled!"
                            } else {
                                // Přidání nového studenta
                                if await studentsDB.addStudent(bindingNewStudent.wrappedValue) {
                                    alertMessage = "Student added successfully!"
                                    studentsDB.fetchStudents() // Refresh seznamu
                                    showNewStudentDialog = false
                                }
                                else {
                                    alertMessage = "Something went wrong!"
                                    studentsDB.fetchStudents() // Refresh seznamu
                                    showNewStudentDialog = false
                                }
                            }
                            showAlert = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("Alert"),
                            message: Text(alertMessage),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                }
                .padding()
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Alert"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// Rozšíření třídy Student pro dynamické přístupy a pole
extension Student {
    enum EditableFields: CaseIterable {
        case firstName, lastName, email, javaExam
        
        var displayName: String {
            switch self {
            case .firstName: return "First Name:"
            case .lastName: return "Last Name:"
            case .email: return "Email:"
            case .javaExam: return "Java Exam:"
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
