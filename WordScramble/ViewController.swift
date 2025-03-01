//
//  ViewController.swift
//  WordScramble
//
//  Created by Илья Колесников on 03.02.2025.
//

import UIKit

class ViewController: UITableViewController {
    
    var allWords = [String]()
    var usedWords = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(promptForAnswer))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(restartGame))
        
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            if let startWords = try? String(contentsOf: startWordsURL, encoding: String.defaultCStringEncoding) {
                allWords = startWords.components(separatedBy: "\n")
            }
        }
        if allWords.isEmpty {
            allWords = ["Silkworm"]
        }
        
        startGame()
        // Do any additional setup after loading the view.
    }
    
    @objc func promptForAnswer() {
        let ac = UIAlertController(title: "Enter a word", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self, weak ac] _ in
            guard let answer = ac?.textFields?[0].text else { return }
            self?.submit(answer)
        }
        ac.addAction(submitAction)
        present(ac, animated: true)
    }
    
    @objc func startGame() {
        let userDefaults = UserDefaults.standard
        if let savedStartWord = userDefaults.data(forKey: "savedStartWord") {
            let jsonDecoder = JSONDecoder()
            do {
                title = try jsonDecoder.decode(String.self, from: savedStartWord)
            } catch {
                print("Failed to load words: \(error)")
            }
        } else {
            title = allWords.randomElement()
            saveStartWord()
        }
        if let savedUsedWords = userDefaults.data(forKey: "usedWords") {
            let jsonDecoder = JSONDecoder()
            do {
                usedWords = try jsonDecoder.decode([String].self, from: savedUsedWords)
            } catch {
                print("Failed to load words: \(error)")
            }
        } else {
            usedWords.removeAll(keepingCapacity: true)
            saveUsedWords()
        }
        
        tableView.reloadData()
    }
    
    @objc func restartGame() {
        title = allWords.randomElement()
        usedWords.removeAll(keepingCapacity: true)
        saveStartWord()
        saveUsedWords()
        tableView.reloadData()
    }
    
    func isPossible(word: String) -> Bool {
        guard var tempWord = title?.lowercased() else { return false }
        
        for letter in word {
            if let position = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: position)
            } else {
                return false
            }
        }
        return true
    }
    
    func isOriginal(word: String) -> Bool {
        return !usedWords.contains(word.lowercased())
    }
    
    func isReal(word: String) -> Bool {
        
        if word.count < 3 {
            return false
        } else {
            let checker = UITextChecker()
            let range = NSRange(location: 0, length: word.utf16.count)
            let mispelledRange = checker.rangeOfMisspelledWord(in: word.lowercased(), range: range, startingAt: 0, wrap: false, language: "en")
            
            return mispelledRange.location == NSNotFound
        }
        
    }
    
    func showErrorMessage(errorTitle: String, errorMessage: String) {
        let alertController = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
    
    func submit(_ answer: String) {
        let lowercasedAnswer = answer.lowercased()
        
        if isPossible(word: lowercasedAnswer) {
            if isOriginal(word: lowercasedAnswer) {
                if isReal(word: lowercasedAnswer) {
                    if lowercasedAnswer == title?.lowercased() {
                        showErrorMessage(errorTitle: "This is a start word", errorMessage: "You can't use start word")
                    } else {
                        usedWords.insert(lowercasedAnswer, at: 0)
                        let indexPath = IndexPath(row: 0, section: 0)
                        tableView.insertRows(at: [indexPath], with: .automatic)
                        saveUsedWords()
                        return
                    }
                    
                } else {
                    showErrorMessage(errorTitle: "Word not recognised", errorMessage: "You can only submit real words.")
                }
            } else {
                showErrorMessage(errorTitle: "Word used already", errorMessage: "Be more original!")
            }
        } else {
            guard let title = title?.lowercased() else { return }
            showErrorMessage(errorTitle: "Word not possible", errorMessage: "You can't spell that word from \(title)")
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usedWords.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Word", for: indexPath)
        cell.textLabel?.text = usedWords[indexPath.row]
        return cell
    }
    
    func saveStartWord() {
        let jsonEncoder = JSONEncoder()
        if let savedData = try? jsonEncoder.encode(title) {
            let defaults = UserDefaults.standard
            defaults.set(savedData, forKey: "savedStartWord")
        }
    }
    
    func saveUsedWords() {
        let jsonEncoder = JSONEncoder()
        if let savedData = try? jsonEncoder.encode(usedWords) {
            let defaults = UserDefaults.standard
            defaults.set(savedData, forKey: "usedWords")
        }
    }
    
    func loadUsedWords() {
        let userDefaults = UserDefaults.standard
        if let savedUsedWords = userDefaults.data(forKey: "usedWords") {
            let jsonDecoder = JSONDecoder()
            do {
                usedWords = try jsonDecoder.decode([String].self, from: savedUsedWords)
            } catch {
                print("Failed to load words: \(error)")
            }
        }
    }
    
    func loadStartWord() {
        let userDefaults = UserDefaults.standard
        if let savedStartWord = userDefaults.data(forKey: "savedStartWord") {
            let jsonDecoder = JSONDecoder()
            do {
                title = try jsonDecoder.decode(String.self, from: savedStartWord)
            } catch {
                print("Failed to load words: \(error)")
            }
        }
    }


}

