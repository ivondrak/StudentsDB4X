import SwiftUI

struct ContentView: View {
    @StateObject private var studentsClass = StudentsClass()
    private var studentsDB: StudentsDB
    
    init() {
        let studentsClass = StudentsClass()
        self._studentsClass = StateObject(wrappedValue: studentsClass)
        self.studentsDB = StudentsDB(studentsClass: studentsClass)
    }
    
    var body: some View {
        NavigationView {
            List(studentsClass.students) { student in
                VStack(alignment: .leading) {
                    Text("\(student.firstName) \(student.lastName)")
                        .font(.headline)
                }
            }
            .navigationTitle("Students")
            .toolbar {
                Button("Refresh") {
                    studentsDB.fetchStudents()
                }
            }
        }
    }
}
