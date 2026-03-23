import SwiftUI

struct UnitSelectionView: View {
    @Binding var path: NavigationPath
    let file: String

    @State private var units: [String] = []
    @State private var selectedUnits: Set<String> = []
    @State private var isLoading = true

    var allSelected: Bool { selectedUnits.count == units.count }

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                Spacer()
                ProgressView("Searching for units…")
                Spacer()
            } else {
                selectAllButton
                unitList
            }

            continueButton
        }
        .navigationTitle("Select Units")
        .onAppear(perform: loadUnits)
    }

    // MARK: - Subviews

    private var selectAllButton: some View {
        HStack {
            Spacer()
            Button(allSelected ? "Deselect All" : "Select All") {
                selectedUnits = allSelected ? [] : Set(units)
            }
            .font(.subheadline)
            .padding(.horizontal)
        }
    }

    private var unitList: some View {
        List(units, id: \.self) { unit in
            Button {
                if selectedUnits.contains(unit) {
                    selectedUnits.remove(unit)
                } else {
                    selectedUnits.insert(unit)
                }
            } label: {
                HStack {
                    Image(systemName: selectedUnits.contains(unit) ? "checkmark.square.fill" : "square")
                        .foregroundColor(selectedUnits.contains(unit) ? .blue : .secondary)
                        .font(.system(size: 20))
                    Text("Unit \(unit)")
                        .foregroundColor(.primary)
                    Spacer()
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var continueButton: some View {
        Button {
            let sorted = Array(selectedUnits).sorted()
            path.append(QuizRoute.chapterSelection(file: file, units: sorted))
        } label: {
            Text("Continue to Chapters")
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedUnits.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .disabled(selectedUnits.isEmpty)
        .padding(.horizontal)
        .padding(.bottom)
    }

    // MARK: - Data

    private func loadUnits() {
        DispatchQueue.global(qos: .userInitiated).async {
            let found = QuizDataService(file: file)?.allUnits ?? []
            DispatchQueue.main.async {
                isLoading = false
                if found.isEmpty {
                    path.append(QuizRoute.chapterSelection(file: file, units: []))
                } else {
                    units = found
                }
            }
        }
    }
}
