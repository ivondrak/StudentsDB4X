import Foundation

class Student: Identifiable, Codable, Hashable {
    var id: String
    var first_name: String
    var last_name: String
    var email: String
    var java_exam: Int
    
    init(id: String, first_name: String, last_name: String, email: String, java_exam: Int) {
        self.id = id
        self.first_name = first_name
        self.last_name = last_name
        self.email = email
        self.java_exam = java_exam
    }
    
    static func == (lhs: Student, rhs: Student) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class StudentsClass: ObservableObject {
    @Published var students: [Student] = []
    
    func addStudents(_ newStudents: [Student]) {
        students = newStudents
    }
    
    func getStudent(at index: Int) -> Student? {
        guard index >= 0 && index < students.count else {
            return nil
        }
        return students[index]
    }
    
    func getStudentCount() -> Int {
        return students.count
    }
}

class StudentsDB: @unchecked Sendable {
    private let baseURL = "http://localhost:3030"
    private weak var studentsClass: StudentsClass?
    
    init(studentsClass: StudentsClass) {
        self.studentsClass = studentsClass
    }
    
    func fetchStudents() {
        // Zajistíme, že Playground bude pokračovat v běhu
        guard let url = URL(string: "\(baseURL)/students") else {
            print("Invalid URL")
            return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Error fetching students: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data returned")
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("JSON Response: ", jsonString)
            }
            
            do {
                let decoder = JSONDecoder()
                let students = try decoder.decode([Student].self, from: data)
                
                // Update StudentsClass on the main thread
                DispatchQueue.main.async {
                    self?.studentsClass?.addStudents(students)
                }
            } catch {
                print("Error decoding students: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    func updateStudent(_ student: Student) async -> Bool {
        guard let url = URL(string: "\(baseURL)/students/\(student.id)") else {
            print("Invalid URL")
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(student)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("Student updated successfully: \(String(data: data, encoding: .utf8) ?? "")")
                return true
            } else {
                print("Failed to update student: \(response)")
                return false
            }
        } catch {
            print("Error updating student: \(error.localizedDescription)")
            return false
        }
    }
}
