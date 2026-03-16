# JLPTPrep 🇯🇵

> *Built by a foreigner living in Japan, studying for the JLPT every day.*

JLPTPrep is a native iOS app for studying Japanese at the N5 and N4 levels. Multiple choice quizzes, kanji practice, vocabulary drills, and grammar rules — all in one app, driven by CSV data so content is easy to update and expand.

**This is not a prototype.** It runs on my iPhone and I use it daily to study for JLPT N4.

---

## 📱 Screenshots

> *Coming soon*

---

## ✨ Features

- **Multiple choice quizzes** — 4-choice questions with instant answer feedback
- **Three study tracks** — Vocabulary (単語), Kanji (漢字), Grammar (文法) in separate CSV files
- **Unit & chapter filtering** — drill exactly what you want to study
- **Grammar rules viewer** — expandable rules with strikethrough notation and extended explanations
- **In-quiz grammar lookup** — tap "Grammar" or "More" mid-question to see the rule without leaving the quiz
- **Translation support** — translate any question or answer choice instantly via Apple's Translation API
- **Score tracking** — every quiz result saved with grade (Excellent / Good / Pass / Try Again)
- **Study time tracking** — cumulative time logged per quiz file and per session
- **CSV-driven content** — add or update questions by editing a spreadsheet, no code changes needed

---

## 📚 Content Coverage

| Level | Vocabulary | Kanji | Grammar |
|-------|-----------|-------|---------|
| N5    | ✅        | ✅    | ✅      |
| N4    | ✅        | ✅    | ✅      |
| N3    | 🔜 planned | 🔜 planned | 🔜 planned |

---

## 🛠️ Built With

- Swift
- SwiftUI
- Apple Translation API
- CSV data files (no backend, no internet required)
- Xcode 15+
- iOS 17+

---

## 🏗️ Architecture

```
JLPTPrep/
├── Quiz_Marker_IOSApp.swift   # App entry point
├── MainMenuView.swift         # Root navigation — Study, Scores, Times, Rules
├── StudyMenuView.swift        # CSV file selector (auto-discovers quiz files)
├── UnitSelectionView.swift    # Filter by unit
├── ChapterSelectionView.swift # Filter by chapter
├── QuestionCountView.swift    # Choose how many questions (stepper + text input)
├── QuizView.swift             # Active quiz — questions, choices, grammar, translation
├── QuizResultsView.swift      # Score screen with grade
├── GrammarRulesView.swift     # Expandable grammar reference
├── ScoreAndTimesViews.swift   # Score history + study time tracker
├── QuizLogic.swift            # QuizManager — state, scoring, question flow
├── QuizStore.swift            # Persistence — scores and sessions via UserDefaults
├── QuizDataService.swift      # CSV filtering — units, chapters, questions
├── CSVParser.swift            # Robust CSV parser (handles quotes, multiline)
├── Question.swift             # Question model
└── QuizRoute.swift            # NavigationStack route enum
```

---

## 🚀 Getting Started

### Requirements
- Xcode 15+
- iOS 17+ device or simulator
- A Mac to build

### Run It

```bash
git clone https://github.com/oo0speed0oo/Quiz_Marker_IOS.git
cd Quiz_Marker_IOS
open Quiz_Marker_IOS.xcodeproj
```

Hit **Run** in Xcode. The app auto-discovers any `.csv` files in the bundle — add your own quiz files and they appear in the Study menu automatically.

### CSV Format

```csv
question_number,unit_number,chapter_number,grammar_ref,question,choice_a,choice_b,choice_c,choice_d,answer
1,1,1,N4-1,彼女は毎日___を勉強します。,日本語,英語,数学,音楽,A
```

---

## 🗺️ Roadmap

- [x] N5 vocabulary, kanji, grammar
- [x] N4 vocabulary, kanji, grammar
- [x] Grammar rules viewer
- [x] Score + study time tracking
- [x] In-quiz translation (Apple Translation API)
- [ ] N3 content
- [ ] Flashcard mode
- [ ] Spaced repetition (SRS)
- [ ] App Store release

---

## 👤 Author

**Michael Placido** — English teacher turned iOS developer, Saitama, Japan 🇯🇵
Currently JLPT N5. Building this app to reach N4 and beyond.

- GitHub: [@oo0speed0oo](https://github.com/oo0speed0oo)
- Email: Mpfx01@gmail.com

---

*If you're also studying Japanese and want to use or contribute to this project, feel free to open an issue or PR.*
