import Foundation

class Student: Identifiable, Codable {
    var id: String
    var firstName: String
    var lastName: String
    var email: String
    var javaExam: Int
    
    init(id: String, firstName: String, lastName: String, email: String, javaExam: Int) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.javaExam = javaExam
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

class StudentsDB {
    private let baseURL = "http://10.0.1.82:3030"
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
        print("URL: ", url)
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Error fetching students: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data returned")
                return
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
}
