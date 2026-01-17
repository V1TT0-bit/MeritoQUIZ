import SwiftUI

struct QuizQuestion: Identifiable, Hashable, Codable {
    var id = UUID()
    let text: String
    let answers: [String]
    let correctAnswerIndex: Int
    
    enum CodingKeys: String, CodingKey {
        case text, answers, correctAnswerIndex
    }
}

struct QuizCategory: Identifiable, Hashable, Codable {
    var id = UUID()
    let title: String
    let description: String
    let iconName: String
    let questions: [QuizQuestion]
    
    enum CodingKeys: String, CodingKey {
        case title, description, iconName, questions
    }
}

class QuizData {
    static var categories: [QuizCategory] = load("questions.json")
  
    static func load<T: Decodable>(_ filename: String) -> T {
        let data: Data
        
        guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
        else {
            fatalError("Nie znaleziono pliku \(filename) w głównym bundle.")
        }
        
        do {
            data = try Data(contentsOf: file)
        } catch {
            fatalError("Nie udało się załadować pliku \(filename) z głównego bundle:\n\(error)")
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            fatalError("Nie udało się sparsować pliku \(filename) jako \(T.self):\n\(error)")
        }
    }
}

extension Color {
    static let themeAccent = Color(hex: "0057FF")
    static let themeBackground = Color(hex: "F2F2F7")
    
    static let answerIdleBg = Color(hex: "DDF4FF")
    static let answerIdleText = Color.black
    static let answerSelectedBg = Color(hex: "0057FF")
    static let answerCorrectBg = Color(hex: "34C759")
    static let answerWrongBg = Color(hex: "FF3B30")
    static let whiteText = Color.white
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct AnswerButton: View {
    let text: String
    let state: AnswerState
    let action: () -> Void

    var backgroundColor: Color {
        switch state {
        case .idle, .disabled: return .answerIdleBg
        case .selected: return .answerSelectedBg
        case .correct: return .answerCorrectBg
        case .wrong: return .answerWrongBg
        }
    }
    
    var textColor: Color {
        switch state {
        case .idle, .disabled: return .answerIdleText
        default: return .whiteText
        }
    }

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(textColor)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(backgroundColor)
                .cornerRadius(16)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(state != .idle)
        .opacity(state == .disabled ? 0.6 : 1.0)
    }
}

enum AnswerState { case idle, selected, correct, wrong, disabled }

struct QuizSelectionCard: View {
    let category: QuizCategory
    
    var body: some View {
        HStack(spacing: 16) {
            Image(category.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.themeAccent)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.title)
                    .font(.headline)
                    .foregroundColor(.black)
                Text(category.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.themeAccent)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}


struct WelcomeView: View {
    var onStartTap: () -> Void
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image("illustration_welcome")
                .resizable()
                .scaledToFit()
                .frame(height: 250)
                .scaleEffect(appear ? 1.0 : 0.8)
                .opacity(appear ? 1.0 : 0.0)
                .animation(.spring(duration: 0.8), value: appear)
            
            VStack(spacing: 16) {
                Text("No witaj, mądralo z WSB Merito! 😎")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Wchodzisz do świata quizu. Wybierz kategorię i sprawdź się!")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .opacity(appear ? 1.0 : 0.0)
            .offset(y: appear ? 0 : 20)
            .animation(.easeOut(duration: 0.8).delay(0.2), value: appear)
            
            Spacer()
            
            Button(action: { onStartTap() }) {
                Text("Do dzieła!")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(Color.themeAccent)
                    .cornerRadius(28)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.bottom, 40)
            .opacity(appear ? 1.0 : 0.0)
            .animation(.spring().delay(0.4), value: appear)
        }
        .padding()
        .background(Color.themeBackground.ignoresSafeArea())
        .onAppear {
            appear = true
        }
    }
}

struct QuizSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showInfoModal = false
    @State private var animateItems = false
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                Color.themeAccent
                    .ignoresSafeArea(edges: .top)
                    .frame(height: 60)
                
                HStack {
                    Image("logo_header")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 32)
                    
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        Button(action: { showInfoModal = true }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            
            VStack(spacing: 20) {
                Text("Wybierz QUIZ")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                    .opacity(animateItems ? 1.0 : 0.0)
                    .animation(.easeIn(duration: 0.5), value: animateItems)
                
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(Array(QuizData.categories.enumerated()), id: \.element) { index, category in
                            NavigationLink(value: category) {
                                QuizSelectionCard(category: category)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .offset(y: animateItems ? 0 : 50)
                            .opacity(animateItems ? 1.0 : 0.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.1), value: animateItems)
                        }
                    }
                    .padding()
                }
            }
            Spacer()
        }
        .background(Color.themeBackground)
        .navigationBarHidden(true)
        .onAppear {
            animateItems = true
        }
        .alert("O Aplikacji", isPresented: $showInfoModal) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Twórca: Michał Witkowski nr 78421\nWersja: 1.0\nStudent na kierunku Informatyki")
        }
    }
}

struct QuizQuestionView: View {
    @Environment(\.dismiss) var dismiss
    let category: QuizCategory
    
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswerIndex: Int? = nil
    @State private var answerStates: [AnswerState] = [.idle, .idle, .idle, .idle]
    @State private var score = 0
    @State private var showResultsAlert = false
    
    var currentQuestion: QuizQuestion {
        category.questions[currentQuestionIndex]
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.themeAccent)
                        .font(.title3)
                }
                .buttonStyle(ScaleButtonStyle())
                
                Text("\(currentQuestionIndex + 1)/\(category.questions.count)")
                    .font(.headline)
                    .foregroundColor(.themeAccent)
                Spacer()
            }
            .padding()
            
            ProgressView(value: Double(currentQuestionIndex + 1), total: Double(category.questions.count))
                .accentColor(.themeAccent)
                .padding(.horizontal)
                .animation(.linear(duration: 0.5), value: currentQuestionIndex)
            
            Spacer()
            
            VStack {
                Text("Pytanie")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                
                Text(currentQuestion.text)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
                    .fixedSize(horizontal: false, vertical: true)
                    .id("QuestionText\(currentQuestionIndex)")
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                ForEach(0..<currentQuestion.answers.count, id: \.self) { index in
                    AnswerButton(
                        text: currentQuestion.answers[index],
                        state: answerStates[index]
                    ) {
                        handleAnswerTapped(index: index)
                    }
                    
                    .id("Answer\(currentQuestionIndex)-\(index)")
                    .transition(.move(edge: .bottom).combined(with: .opacity).animation(.spring().delay(Double(index) * 0.05)))
                }
            }
            .padding()
            
            Spacer()
        }
        .background(Color.themeBackground.ignoresSafeArea())
        .navigationBarHidden(true)
        .animation(.default, value: currentQuestionIndex)
        .alert("Koniec Quizu!", isPresented: $showResultsAlert) {
            Button("Wróć do menu") { dismiss() }
        } message: {
            Text("Kategoria: \(category.title)\nWynik: \(score)/\(category.questions.count)")
        }
    }
    
    func handleAnswerTapped(index: Int) {
        guard selectedAnswerIndex == nil else { return }
        selectedAnswerIndex = index
        withAnimation { answerStates[index] = .selected }
        
        for i in 0..<currentQuestion.answers.count where i != index { withAnimation { answerStates[i] = .disabled } }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let isCorrect = index == currentQuestion.correctAnswerIndex
            withAnimation {
                if isCorrect {
                    score += 1
                    answerStates[index] = .correct
                } else {
                    answerStates[index] = .wrong
                    answerStates[currentQuestion.correctAnswerIndex] = .correct
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if currentQuestionIndex < category.questions.count - 1 {
                    withAnimation {
                        currentQuestionIndex += 1
                        selectedAnswerIndex = nil
                        answerStates = [.idle, .idle, .idle, .idle]
                    }
                } else {
                    showResultsAlert = true
                }
            }
        }
    }
}

struct ContentView: View {
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            WelcomeView {
                navigationPath.append("SelectionScreen")
            }
            .navigationDestination(for: String.self) { dest in
                if dest == "SelectionScreen" {
                    QuizSelectionView()
                }
            }
            .navigationDestination(for: QuizCategory.self) { category in
                QuizQuestionView(category: category)
            }
        }
    }
}

#Preview {
    ContentView()
}
