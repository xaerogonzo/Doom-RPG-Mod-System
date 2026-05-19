// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// This interface represents a question.
class tt_Question abstract
{
  abstract bool isRight(string answer);

  abstract string getDescription();

  abstract string getHintFor(string answer);
}

class tt_FallbackQuestion : tt_Question
{
  static tt_FallbackQuestion of() { return new("tt_FallbackQuestion"); }

  override bool isRight(string answer) { return false; }

  override string getDescription()
  {
    return StringTable.localize("TT_FALLBACK_QUESTION");
  }

  override string getHintFor(string answer) { return getDescription(); }
}

// Implements tt_Question. The answer is right for this kind of question if it
// matches the string contained in this question.
class tt_Match : tt_Question
{
  static tt_Match of(string answer, string description)
  {
    let result = new("tt_Match");
    result._answer      = answer;
    result._description = description;
    return result;
  }

  override bool isRight(string answer)
  {
    return (_answer == answer);
  }

  override string getDescription()
  {
    return _description;
  }

  override string getHintFor(string answer)
  {
    return getColoredMatch(_answer, answer);
  }

  static string getColoredMatch(string origin, string matched)
  {
    string result;

    int originLength  = origin .codePointCount();
    int matchedLength = matched.codePointCount();
    int nChars        = min(originLength, matchedLength);
    int originPos     = 0;
    int matchedPos    = 0;

    for (int i = 0; i < nChars; ++i)
    {
      let [originCode,  nextOriginPos ] = origin .getNextCodePoint(originPos );
      let [matchedCode, nextMatchedPos] = matched.getNextCodePoint(matchedPos);

      int colorCode = (originCode == matchedCode)
        ? tt_su_Ascii.HYPHEN_MINUS // Use the base color.
        : tt_TextColorCodes.WrongAnswer;

      result.appendFormat("\c%c%c", colorCode, matchedCode);

      originPos  = nextOriginPos;
      matchedPos = nextMatchedPos;
    }

    // Everything that is beyond origin is wrong.
    if (matchedLength > originLength)
    {
      result.appendFormat("\c%c%s",
                          tt_TextColorCodes.WrongAnswer,
                          matched.mid(matchedPos));
    }

    return result;
  }

  private string _answer;
  private string _description;
}
