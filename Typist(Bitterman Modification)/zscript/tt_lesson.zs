// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// Interface for getting Questions.
class tt_Lesson abstract
{
  abstract tt_Question getQuestion();
}

// Implements tt_Lesson by composing arithmetic tasks.
class tt_MathsLesson : tt_Lesson
{
  static tt_MathsLesson of()
  {
    let result = new("tt_MathsLesson");
    return result;
  }

  override tt_Question getQuestion()
  {
    int operation = random[typist](Addition, Division);

    switch (operation)
    {
    case Addition:       return makeAdditionQuestion();
    case Subtraction:    return makeSubtractionQuestion();
    case Multiplication: return makeMultiplicationQuestion();
    case Division:       return makeDivisionQuestion();
    }

    Console.printf("%s: getQuestion: unknown operation!", getClassName());
    return NULL;
  }

  private tt_Question makeAdditionQuestion()
  {
    int leftAddend  = random[typist](11, 49);
    int rightAddend = random[typist](11, 50);
    int sum         = leftAddend + rightAddend;

    string description = string.format("%d + %d", leftAddend,  rightAddend);
    string answer      = string.format("%d", sum);

    let question = tt_Match.of(answer, description);
    return question;
  }

  private tt_Question makeSubtractionQuestion()
  {
    int minuend    = random[typist](50, 99);
    int subtrahend = random[typist](11, 50);
    int difference = minuend - subtrahend;

    string description = string.format("%d - %d", minuend, subtrahend);
    string answer      = string.format("%d", difference);

    let question = tt_Match.of(answer, description);
    return question;
  }

  private tt_Question makeMultiplicationQuestion()
  {
    int multiplicand = random[typist](2, 9);
    int multiplier   = random[typist](2, 9);
    int product      = multiplicand * multiplier;

    string description = string.format("%d * %d", multiplicand, multiplier);
    string answer      = string.format("%d", product);

    let question = tt_Match.of(answer, description);
    return question;
  }

  private tt_Question makeDivisionQuestion()
  {
    int quotient = random[typist](2, 9);
    int divisor  = random[typist](2, 9);
    int dividend = quotient * divisor;

    string description = string.format("%d / %d", dividend, divisor);
    string answer      = string.format("%d", quotient);

    let question = tt_Match.of(answer, description);
    return question;
  }

  enum Operations
  {
    Addition,
    Subtraction,
    Multiplication,
    Division,
  }
}

class tt_SwitchableLesson
{
  static tt_SwitchableLesson of(tt_BoolSetting setting, tt_Lesson lesson)
  {
    let result = new("tt_SwitchableLesson");
    result._setting = setting;
    result._lesson  = lesson;
    return result;
  }

  bool isEnabled() { return _setting.get(); }
  tt_Lesson lesson() { return _lesson; }

  private tt_BoolSetting _setting;
  private tt_Lesson      _lesson;
}

class tt_MixedLesson : tt_Lesson
{
  static tt_MixedLesson of(Array<tt_SwitchableLesson> lessons)
  {
    let result = new("tt_MixedLesson");
    result._lessons.move(lessons);
    return result;
  }

  override tt_Question getQuestion()
  {
    _enabledLessons.clear();

    foreach (lesson : _lessons)
      if (lesson.isEnabled()) _enabledLessons.push(lesson.lesson());

    uint nEnabledLessons = _enabledLessons.size();
    if (nEnabledLessons == 0)
    {
      Console.printf("All lessons disabled");
      return tt_FallbackQuestion.of();
    }

    uint randomLessonIndex = random[typist](0, nEnabledLessons - 1);

    return _enabledLessons[randomLessonIndex].getQuestion();
  }

  private Array<tt_SwitchableLesson> _lessons;
  private Array<tt_Lesson> _enabledLessons;
}

// Implements tt_Lesson by composing a question from groups
// of characters enabled by settings.
class tt_RandomCharactersLesson : tt_Lesson
{
  static tt_RandomCharactersLesson of(tt_RandomCharactersLessonSettings settings)
  {
    let result = new("tt_RandomCharactersLesson");
    result._settings = settings;
    return result;
  }

  override tt_Question getQuestion()
  {
    string characters = composeCharacterRange();
    int    length     = _settings.getLessonLength();
    string picked     = pick(characters, length);

    if (picked.length() == 0)
    {
      Console.printf("Random characters lesson: no characters enabled");
      return tt_FallbackQuestion.of();
    }

    return tt_Match.of(picked, picked);
  }

  // This function is guaranteed to return non-empty strings.
  private string composeCharacterRange()
  {
    string characters;

    if (_settings.isUppercaseLettersEnabled()) characters.appendFormat("%s", UPPERCASE_LETTERS);
    if (_settings.isLowercaseLettersEnabled()) characters.appendFormat("%s", LOWERCASE_LETTERS);
    if (_settings.isNumbersEnabled()) characters.appendFormat("%s", NUMBERS);
    if (_settings.isPunctuationEnabled()) characters.appendFormat("%s", PUNCTUATION);
    if (_settings.isSymbolsEnabled())
    {
      // UZDoom cannot handle "\\" in a string, so add it manually.
      characters.AppendFormat("%s%c", SYMBOLS, tt_su_Ascii.REVERSE_SOLIDUS);
    }
    if (_settings.isCustomCharactersEnabled())
    {
      characters.AppendFormat("%s", _settings.getCustomCharacters());
    }

    return characters;
  }

  // This function is guaranteed to return non-empty strings.
  private static string pick(string characters, int number)
  {
    if (characters.length() == 0) return "";

    string result;
    int    lastCharacter = characters.CodePointCount() - 1;

    for (int i = 0; i < number; ++i)
    {
      int randomIndex = random[typist](0, lastCharacter);
      int character   = getCodePointAt(characters, randomIndex);

      result.appendFormat("%c", character);
    }

    return result;
  }

  // Attention! O(n)
  private static int getCodePointAt(String str, int index)
  {
    int letterCode;
    int charPos = 0;
    for (int i = 0; i <= index; ++i)
    {
      [letterCode, charPos] = str.GetNextCodePoint(charPos);
    }

    return letterCode;
  }

  const LOWERCASE_LETTERS = "abcdefghijklmnopqrstuvwxyz";
  const UPPERCASE_LETTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  const NUMBERS           = "0123456789";
  const PUNCTUATION       = ",.();:-'\"?!/";
  const SYMBOLS           = "~`@#$%^&*+=[]{}<>|";

  private tt_RandomCharactersLessonSettings _settings;
}

// Implements tt_Lesson by producing questions that contain
// string composed from random numbers and should match exactly to the answers.
class tt_RandomNumberSource : tt_Lesson
{
  static tt_RandomNumberSource of()
  {
    let result = new("tt_RandomNumberSource");
    return result;
  }

  override tt_Question getQuestion()
  {
    let stringLength = 3;
    let str          = "";

    for (int i = 0; i < stringLength; ++i)
    {
      int number = random[typist](tt_su_Ascii.DIGIT_ZERO, tt_su_Ascii.DIGIT_NINE);
      str.AppendFormat("%c", number);
    }

    let question = tt_Match.of(str, str);

    return question;
  }
}

// Implements tt_Lesson by reading a lump with words and
// randomly selecting words from this lump.
class tt_StringSet : tt_Lesson
{
  static tt_StringSet of(String lumpName)
  {
    int    lump     = Wads.findLump(lumpName, 0, Wads.AnyNamespace);
    string contents = Wads.readLump(lump);
    Array<string> words;
    tt_su_su.splitByWords(contents, words);

    Array<string> filteredWords;
    filterWords(words, filteredWords);

    let result = new("tt_StringSet");

    result._lumpName = lumpName;
    result._words.move(filteredWords);

    return result;
  }

  override tt_Question getQuestion()
  {
    int nWords = int(_words.size());
    if (nWords == 0)
    {
      Console.printf("%s: getQuestion: no words in lump %s.",
                     getClassName(),
                     _lumpName);
      return tt_FallbackQuestion.of();
    }

    int    wordIndex = random[typist](0, nWords - 1);
    string word      = _words[wordIndex];
    let    question  = tt_Match.of(word, word);

    return question;
  }

  // Removes too short words, removes duplicates.
  private static void filterWords(Array<String> input, out Array<String> result)
  {
    // Use map to remove duplicates.
    Map<string, int> wordSet;

    foreach (word : input)
    {
      if (word.codePointCount() > 1)
        wordSet.insert(word, 0);
    }

    foreach (word, value : wordSet)
      result.push(word);
  }

  private string        _lumpName;
  private Array<string> _words;
}
