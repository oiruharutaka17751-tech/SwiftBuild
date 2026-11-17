import SwiftUI
import UIKit
import Charts

// MARK: - PersonData.swift
//import SwiftUI
//
//// 1. ข้อมูลบุคคล
//struct Person: Codable, Identifiable, Equatable {
//    var id = UUID()
//    var name: String
//    var imageData: Data
//    var image: UIImage? { UIImage(data: imageData) }
//}
//
//// 2. ผลลัพธ์แต่ละข้อ
//struct QuestionResult: Codable, Identifiable {
//    var id = UUID()
//    let personName: String
//    let isCorrect: Bool
//}
//
//// 3. ประวัติการเล่น (เช็คชื่อตัวแปรให้ตรงกับ GameView)
//struct GameRecord: Codable, Identifiable {
//    var id = UUID()
//    let date: Date
//    let totalQuestions: Int
//    let correctAnswers: Int
//    let wrongAnswers: Int // ต้องมีตัวนี้เพื่อรองรับค่า numberOfQuestions - score
//    let details: [QuestionResult]
//}
//
//class DataManager: ObservableObject {
//    @Published var people: [Person] = []
//    @Published var gameHistory: [GameRecord] = []
//    
//    init() {
//        loadData()
//        loadHistory()
//    }
//    
//    // --- ฟังก์ชันจัดการข้อมูล ---
//    func addPerson(_ person: Person) {
//        people.append(person)
//        saveData()
//    }
//    
//    func deleteHistory(at offsets: IndexSet) {
//            gameHistory.remove(atOffsets: offsets)
//            saveHistory() // เรียกฟังก์ชันบันทึกข้อมูลลงเครื่องด้วย
//        }
//    
//    func removePerson(at index: Int) {
//        people.remove(at: index)
//        saveData()
//    }
//    
//    func addGameRecord(_ record: GameRecord) {
//        gameHistory.insert(record, at: 0)
//        saveHistory()
//    }
//    
//    // --- ระบบ Save/Load (UserDefaults) ---
//    private func saveData() {
//        if let encoded = try? JSONEncoder().encode(people) {
//            UserDefaults.standard.set(encoded, forKey: "PeopleKey")
//        }
//    }
//    
//    private func loadData() {
//        if let data = UserDefaults.standard.data(forKey: "PeopleKey"),
//           let decoded = try? JSONDecoder().decode([Person].self, from: data) {
//            people = decoded
//        }
//    }
//    
//    private func saveHistory() {
//        if let encoded = try? JSONEncoder().encode(gameHistory) {
//            UserDefaults.standard.set(encoded, forKey: "HistoryKey")
//        }
//    }
//    
//    private func loadHistory() {
//        if let data = UserDefaults.standard.data(forKey: "HistoryKey"),
//           let decoded = try? JSONDecoder().decode([GameRecord].self, from: data) {
//            gameHistory = decoded
//        }
//    }
//}

// เพิ่มโครงสร้างข้อมูลสำหรับพล็อตจุดในกราฟ
struct ChartData: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
    let type: String // "ถูก" หรือ "ผิด"
}

struct Person: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var imageData: Data
    var image: UIImage? { UIImage(data: imageData) }
}

struct QuestionResult: Codable, Identifiable {
    var id = UUID()
    let personName: String
    let isCorrect: Bool
}

struct GameRecord: Codable, Identifiable {
    var id = UUID()
    let date: Date
    let totalQuestions: Int
    let correctAnswers: Int
    let wrongAnswers: Int // <--- ต้องมีตัวนี้
    let details: [QuestionResult]
}

class DataManager: ObservableObject {
    @Published var people: [Person] = []
    @Published var gameHistory: [GameRecord] = []
    
    init() { loadData(); loadHistory() }
    
    func addPerson(_ person: Person) { people.append(person); saveData() }
    
    // แก้ไขให้รับ IndexSet เพื่อแก้ Error .onDelete
    func removePerson(at offsets: IndexSet) {
        people.remove(atOffsets: offsets)
        saveData()
    }
    
    func addGameRecord(_ record: GameRecord) {
        gameHistory.insert(record, at: 0)
        saveHistory()
    }
    
    func deleteHistory(at offsets: IndexSet) {
        gameHistory.remove(atOffsets: offsets)
        saveHistory()
    }
    
    // --- ระบบ Save/Load (ห้ามลบ) ---
    func saveData() {
        if let encoded = try? JSONEncoder().encode(people) {
            UserDefaults.standard.set(encoded, forKey: "PeopleKey")
        }
    }
    func saveHistory() {
        if let encoded = try? JSONEncoder().encode(gameHistory) {
            UserDefaults.standard.set(encoded, forKey: "HistoryKey")
        }
    }
    func loadData() {
        if let data = UserDefaults.standard.data(forKey: "PeopleKey"),
           let decoded = try? JSONDecoder().decode([Person].self, from: data) { people = decoded }
    }
    func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "HistoryKey"),
           let decoded = try? JSONDecoder().decode([GameRecord].self, from: data) { gameHistory = decoded }
    }
}

// MARK: - GameView.swift
struct GameView: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    
    // Game States
    @State private var numberOfQuestions = 5
    @State private var isGameStarted = false
    @State private var currentQuestionIndex = 0
    @State private var score = 0
    @State private var isAnswered = false
    @State private var selectedAnswer: Person? = nil
    @State private var currentOptions: [Person] = []
    @State private var correctPerson: Person? = nil
    @State private var isTypeShowImage = Bool.random()
    @State private var gameResults: [QuestionResult] = []

    var body: some View {
        VStack {
            if dataManager.people.count < 4 {
                warningView
            } else if !isGameStarted {
                setupView
            } else if currentQuestionIndex < numberOfQuestions {
                playingView
            } else {
                summaryView
            }
        }
        .navigationTitle("Memory test")
        .navigationBarTitleDisplayMode(.inline)
    }

    // --- ส่วนหน้าจอย่อย ---
    
    private var warningView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.badge.plus").font(.system(size: 80)).foregroundColor(.orange)
            Text("Insufficient information").font(.title2.bold())
            Text("Please add at least 4 people.\n In the add name to family before starting to play.").multilineTextAlignment(.center)
            Button("Ok") { dismiss() }.buttonStyle(.borderedProminent)
        }
    }

    private var setupView: some View {
        VStack(spacing: 30) {
            Text("quantity").font(.largeTitle.bold())
            HStack(spacing: 20) {
                ForEach([5, 10, 15], id: \.self) { num in
                    Button("\(num)") { numberOfQuestions = num }
                        .frame(width: 80, height: 80)
                        .background(numberOfQuestions == num ? Color.black : Color.gray.opacity(0.2))
                        .foregroundColor(numberOfQuestions == num ? .white : .black)
                        .clipShape(Circle()).font(.title.bold())
                }
            }
            Button("gamestart") { startGame() }
                .frame(maxWidth: .infinity, minHeight: 70)
                .background(Color.black).foregroundColor(.white).cornerRadius(20).font(.title.bold()).padding()
        }
    }

    private var playingView: some View {
        VStack(spacing: 20) {
            Text("number \(currentQuestionIndex + 1) / \(numberOfQuestions)").font(.headline)
            
            // โจทย์
            if isTypeShowImage {
                if let img = correctPerson?.image {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(width: 250, height: 250).clipShape(RoundedRectangle(cornerRadius: 15)).shadow(radius: 5)
                }
                Text("Who is this?").font(.system(size: 30, weight: .bold))
            } else {
                Text("Which one is \"\(correctPerson?.name ?? "")\" ?").font(.system(size: 30, weight: .bold)).frame(height: 250)
            }

            // ตัวเลือก
            LazyVGrid(columns: [GridItem(), GridItem()], spacing: 15) {
                ForEach(currentOptions) { person in
                    Button(action: { checkAnswer(person) }) {
                        VStack {
                            if isTypeShowImage {
                                Text(person.name).font(.title3.bold())
                            } else {
                                if let img = person.image {
                                    Image(uiImage: img).resizable().scaledToFill().frame(width: 120, height: 120).cornerRadius(10)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .background(buttonColor(for: person)).foregroundColor(.white).cornerRadius(15)
                    }.disabled(isAnswered)
                }
            }

            if isAnswered {
                Button("next") { nextQuestion() }.frame(maxWidth: .infinity, minHeight: 50).background(Color.black).foregroundColor(.white).cornerRadius(15)
            }
        }
        .padding()
    }

    private var summaryView: some View {
        VStack(spacing: 30) {
            Text("Good job!").font(.largeTitle.bold())
            Text("\(score) / \(numberOfQuestions)").font(.system(size: 80, weight: .black)).foregroundColor(.blue)
            Button("Save and exit.") {
                saveRecord()
                dismiss()
            }.frame(maxWidth: .infinity, minHeight: 70).background(Color.blue).foregroundColor(.white).cornerRadius(20).font(.title2.bold()).padding()
        }
    }

    // --- Logic ---
    
    func startGame() {
        isGameStarted = true
        currentQuestionIndex = 0
        score = 0
        gameResults = []
        generateQuestion()
    }

    func generateQuestion() {
        isAnswered = false
        selectedAnswer = nil
        isTypeShowImage = Bool.random()
        let shuffled = dataManager.people.shuffled()
        correctPerson = shuffled.first
        currentOptions = Array(shuffled.prefix(4)).shuffled()
    }

    func checkAnswer(_ person: Person) {
        selectedAnswer = person
        isAnswered = true
        let isCorrect = (person.id == correctPerson?.id)
        if isCorrect { score += 1 }
        gameResults.append(QuestionResult(personName: correctPerson?.name ?? "", isCorrect: isCorrect))
    }

    func nextQuestion() {
        if currentQuestionIndex + 1 < numberOfQuestions {
            currentQuestionIndex += 1
            generateQuestion()
        } else {
            currentQuestionIndex += 1
        }
    }

    func buttonColor(for person: Person) -> Color {
        if !isAnswered { return .blue }
        if person.id == correctPerson?.id { return .green }
        if person.id == selectedAnswer?.id { return .red }
        return .gray.opacity(0.5)
    }

    // ... โค้ดส่วนเล่นเกม (ข้ามมาส่วนบันทึกผล) ...
    func saveRecord() {
        let newRecord = GameRecord(
            date: Date(),
            totalQuestions: numberOfQuestions,
            correctAnswers: score,
            wrongAnswers: numberOfQuestions - score, // คำนวณตรงนี้
            details: gameResults
        )
        dataManager.addGameRecord(newRecord)
    }
}

// MARK: - ManageDataView.swift
struct ManageDataView: View {
    @ObservedObject var dataManager: DataManager
    @State private var name = ""; @State private var image: UIImage?; @State private var showPicker = false

    var body: some View {
        VStack {
            VStack(spacing: 15) {
                if let img = image {
                    Image(uiImage: img).resizable().scaledToFill().frame(width: 120, height: 120).clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.badge.plus").font(.system(size: 80)).foregroundColor(.gray)
                }
                Button("select image") { showPicker = true }.buttonStyle(.bordered)
                TextField("enter name", text: $name).textFieldStyle(RoundedBorderTextFieldStyle()).padding(.horizontal)
                Button("add") {
                    if let imgData = image?.jpegData(compressionQuality: 0.5) {
                        dataManager.addPerson(Person(name: name, imageData: imgData))
                        name = ""; image = nil
                    }
                }.disabled(name.isEmpty || image == nil).buttonStyle(.borderedProminent)
            }.padding().background(Color.gray.opacity(0.1)).cornerRadius(15).padding()

            List {
                ForEach(dataManager.people) { p in
                    HStack {
                        if let img = p.image { Image(uiImage: img).resizable().frame(width: 50, height: 50).clipShape(Circle()) }
                        Text(p.name)
                    }
                }
                .onDelete(perform: dataManager.removePerson) // แก้ไขตรงนี้
            }
        }
        .navigationTitle("Manage contacts")
        .toolbar { EditButton() } // เพิ่มปุ่ม Edit เพื่อให้ลบง่ายขึ้น
        .sheet(isPresented: $showPicker) { ImagePicker(selectedImage: $image) }
    }
}

// โค้ดสำหรับตัวเลือกรูปภาพ
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController(); p.delegate = context.coordinator; return p
    }
    func updateUIViewController(_ ui: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ p: ImagePicker) { parent = p }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            parent.selectedImage = info[.originalImage] as? UIImage; parent.dismiss()
        }
    }
}

// MARK: - HistoryView.swift
struct HistoryView: View {
    @ObservedObject var dataManager: DataManager
    
    var body: some View {
        List {
            if dataManager.gameHistory.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("There is no playing history yet.")
                        .font(.title3)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            } else {
                ForEach(dataManager.gameHistory) { record in
                    NavigationLink(destination: HistoryDetailView(record: record)) {
                        HStack(spacing: 15) {
                            // ส่วนวงกลมแสดงคะแนน
                            ZStack {
                                Circle()
                                    .stroke(Color.blue.opacity(0.2), lineWidth: 5)
                                    .frame(width: 60, height: 60)
                                Text("\(record.correctAnswers)")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.date, style: .date)
                                    .font(.headline)
                                Text("all \(record.totalQuestions)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text(record.date, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                // แสดงจำนวนที่ผิด (ถ้ามี)
                                if record.wrongAnswers > 0 {
                                    Text("wrong \(record.wrongAnswers)")
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.red.opacity(0.1))
                                        .foregroundColor(.red)
                                        .cornerRadius(5)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
                .onDelete(perform: dataManager.deleteHistory)
            }
        }.navigationTitle("history")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // --- ส่วนที่เพิ่มใหม่: ปุ่มกดไปหน้ากราฟ ---
                    NavigationLink(destination: GameChartView(dataManager: dataManager)) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title3)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
    }
}

// --- หน้าแสดงรายละเอียดเมื่อกดดูแต่ละประวัติ ---
struct HistoryDetailView: View {
    let record: GameRecord
    
    var body: some View {
        List {
            Section(header: Text("สรุปผล")) {
                HStack {
                    Text("Correct answer")
                    Spacer()
                    Text("\(record.correctAnswers)").foregroundColor(.green).bold()
                }
                HStack {
                    Text("Wrong answer")
                    Spacer()
                    Text("\(record.wrongAnswers)").foregroundColor(.red).bold()
                }
            }
            
            Section(header: Text("information")) {
                ForEach(record.details) { result in
                    HStack {
                        Image(systemName: result.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result.isCorrect ? .green : .red)
                        Text(result.personName)
                        Spacer()
                        Text(result.isCorrect ? "correct" : "wrong")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("details")
    }
}

// MARK: - GameChartView.swift
struct GameChartView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedRange = "1 week"
    let ranges = ["1 day", "1 week", "1 month"]

    var body: some View {
        VStack {
            // ตัวเลือกช่วงเวลา 1 วัน, 1 สัปดาห์, 1 เดือน
            Picker("Range", selection: $selectedRange) {
                ForEach(ranges, id: \.self) { Text($0) }
            }
            .pickerStyle(.segmented)
            .padding()

            // ส่วนแสดงกราฟเส้น
            Chart {
                ForEach(filteredData) { data in
                    LineMark(
                        x: .value("Date", data.date),
                        y: .value("Count", data.count)
                    )
                    .foregroundStyle(by: .value("Type", data.type))
                    .interpolationMethod(.catmullRom) // ทำให้เส้นโค้งมน
                    
                    PointMark(
                        x: .value("Date", data.date),
                        y: .value("Count", data.count)
                    )
                    .foregroundStyle(by: .value("Type", data.type))
                }
            }
            .chartForegroundStyleScale([
                "Correct": .green, "Wrong": .red
            ])
            .frame(height: 300)
            .padding()

            Spacer()
        }
        .navigationTitle("Statistics")
    }

    // ฟังก์ชันกรองข้อมูลตามวันเวลาที่เลือก
    var filteredData: [ChartPoint] {
        let now = Date()
        let calendar = Calendar.current
        let startDate: Date

        switch selectedRange {
        case "1 day": startDate = calendar.date(byAdding: .day, value: -1, to: now)!
        case "1 week": startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        case "1 month": startDate = calendar.date(byAdding: .month, value: -1, to: now)!
        default: startDate = now
        }

        let filteredRecords = dataManager.gameHistory.filter { $0.date >= startDate }
        
        var points: [ChartPoint] = []
        for record in filteredRecords {
            points.append(ChartPoint(date: record.date, count: record.correctAnswers, type: "Correct"))
            points.append(ChartPoint(date: record.date, count: record.wrongAnswers, type: "Wrong"))
        }
        return points.sorted { $0.date < $1.date }
    }
}

// โครงสร้างข้อมูลสำหรับพล็อตจุดในกราฟ
struct ChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
    let type: String
}

// MARK: - ContentView.swift
struct ContentView: View {
    @StateObject var dataManager = DataManager()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                Text("family memories").font(.system(size: 45, weight: .black)).foregroundColor(.black).padding(.top)
                
                Spacer()
                
                NavigationLink(destination: GameView(dataManager: dataManager)) {
                    MenuButton(title: "start", icon: "play.circle.fill", color: .black)
                }
                
                NavigationLink(destination: ManageDataView(dataManager: dataManager)) {
                    MenuButton(title: "add name to family", icon: "person.badge.plus.fill", color: .black)
                }
                
                NavigationLink(destination: HistoryView(dataManager: dataManager)) {
                    MenuButton(title: "History", icon: "clock.fill", color: .black)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("หน้าหลัก")
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct MenuButton: View {
    let title: String; let icon: String; let color: Color
    var body: some View {
        HStack {
            Image(systemName: icon).font(.largeTitle)
            Text(title).font(.system(size: 28, weight: .bold))
        }
        .frame(maxWidth: .infinity, minHeight: 100).background(color).foregroundColor(.white).cornerRadius(20).shadow(radius: 5).padding(.horizontal)
    }
}

// MARK: - MyApp.swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
