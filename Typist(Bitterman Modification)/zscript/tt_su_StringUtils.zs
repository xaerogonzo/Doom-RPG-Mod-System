// SPDX-FileCopyrightText: © 2024 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// StringUtils module version: 1.4.0
// StringUtils is a part of DoomToolbox: https://github.com/mmaulwurff/doom-toolbox/

class tt_su_su { 
static clearscope string join(Array<string> strings, string delimiter = ", ")
{
  uint nStrings = strings.size();
  if (nStrings == 0) return "";

  string result = strings[0];

  for (uint i = 1; i < nStrings; ++i)
    result.appendFormat("%s%s", delimiter, strings[i]);

  return result;
}

static clearscope string repeat(string aString, int times)
{
  // Make the specified number of spaces using padding format.
  string result = string.format("%*d", times + 1, 0);
  result.deleteLastCharacter();
  result.replace(" ", aString);
  return result;
}

static clearscope string boolToString(bool value)
{
  return value ? "true" : "false";
}

static clearscope bool isWordDelimiter(int character)
{
  if (character == tt_su_Ascii.HYPHEN_MINUS) return false;

  if (character < tt_su_Ascii.DIGIT_ZERO) return true;
  if (tt_su_Ascii.COLON <= character
      && character <= tt_su_Ascii.COMMERCIAL_AT) return true;
  if (tt_su_Ascii.LEFT_SQUARE_BRACKET <= character
      && character <= tt_su_Ascii.GRAVE_ACCENT) return true;
  if (tt_su_Ascii.LEFT_CURLY_BRACKET <= character
      && character <= tt_su_Ascii.DELETE) return true;

  // Various unicode spaces.
  if (0x2000 <= character && character <= 0x200B) return true;

  static const int unicodeDelimiters[] =
  {
    0x0085, // next line
    0x00A0, // non-breaking space
    0x2028, // line separator
    0x2029, // paragraph separator
    0x202F, // narrow non-breaking space
    0x205F, // medium mathematical space
    0x3000  // ideographic space
  };

  foreach (unicodeDelimiter : unicodeDelimiters)
    if (character == unicodeDelimiter) return true;

  return false;
}

static clearscope void splitByWords(string text, out Array<string> words)
{
  int length = text.length();
  string currentWord;
  for (int i = 0; i < length;)
  {
    int character;
    [character, i] = text.getNextCodePoint(i);

    if (!isWordDelimiter(character))
    {
      currentWord.appendCharacter(character);
      continue;
    }

    if (currentWord.length() != 0)
    {
      words.push(currentWord);
      currentWord = "";
    }
  }

  if (currentWord.length() != 0)
    words.push(currentWord);
} }

class tt_su_Description
{
  
  string compose() { return tt_su_su.join(mFields); }
  
  tt_su_Description add(string name, string value)
  {
    mFields.push(name .. ": " .. value);
    return self;
  }
  
  tt_su_Description addObject(string name, Object anObject)
  {
    if (anObject == NULL) return add(name, "NULL");
  
    string className = anObject.getClassName();
    return add(name, className);
  }
  
  tt_su_Description addClass(string name, Class aClass)
  {
    if (aClass == NULL) return add(name, "NULL");
    return add(name, aClass.getClassName());
  }
  
  tt_su_Description addBool(string name, bool value)
  {
    return add(name, tt_su_su.boolToString(value));
  }
  
  tt_su_Description addInt(string name, int value)
  {
    return add(name, string.format("%d", value));
  }
  
  tt_su_Description addFloat(string name, double value)
  {
    return add(name, string.format("%.2f", value));
  }
  
  tt_su_Description addDamageFlags(string name, EDmgFlags flags)
  {
    Array<string> results;
    if (flags & DMG_NO_ARMOR)          results.push("DMG_NO_ARMOR");
    if (flags & DMG_INFLICTOR_IS_PUFF) results.push("DMG_INFLICTOR_IS_PUFF");
    if (flags & DMG_THRUSTLESS)        results.push("DMG_THRUSTLESS");
    if (flags & DMG_FORCED)            results.push("DMG_FORCED");
    if (flags & DMG_NO_FACTOR)         results.push("DMG_NO_FACTOR");
    if (flags & DMG_PLAYERATTACK)      results.push("DMG_PLAYERATTACK");
    if (flags & DMG_FOILINVUL)         results.push("DMG_FOILINVUL");
    if (flags & DMG_FOILBUDDHA)        results.push("DMG_FOILBUDDHA");
    if (flags & DMG_NO_PROTECT)        results.push("DMG_NO_PROTECT");
    if (flags & DMG_USEANGLE)          results.push("DMG_USEANGLE");
    if (flags & DMG_NO_PAIN)           results.push("DMG_NO_PAIN");
    if (flags & DMG_EXPLOSION)         results.push("DMG_EXPLOSION");
    if (flags & DMG_NO_ENHANCE)        results.push("DMG_NO_ENHANCE");
  
    return add(name, tt_su_su.join(results));
  }
  
  tt_su_Description addCvar(string name)
  {
    let aCvar = Cvar.getCvar(name, players[consolePlayer]);
    if (aCvar == NULL) return add(name, "NULL");
  
    switch (aCvar.getRealType())
      {
      case Cvar.CVAR_Bool: return addBool(name, tt_su_su.boolToString(aCvar.getInt()));
      case Cvar.CVAR_Int: return addInt(name, aCvar.getInt());
      case Cvar.CVAR_Float: return addFloat(name, aCvar.getFloat());
      case Cvar.CVAR_String: return add(name, aCvar.getString());
        // TODO: implement color:
      case Cvar.CVAR_Color: return addInt(name, aCvar.getInt());
      }
  
    return add(name, string.format("unknown type (%d)", aCvar.getRealType()));
  }
  
  /// SPAC - special activation types.
  tt_su_Description addSpac(string name, int flags)
  {
    Array<string> results;
    if (flags & SPAC_Cross)      results.push("SPAC_Cross");
    if (flags & SPAC_Use)        results.push("SPAC_Use");
    if (flags & SPAC_MCross)     results.push("SPAC_MCross");
    if (flags & SPAC_Impact)     results.push("SPAC_Impact");
    if (flags & SPAC_Push)       results.push("SPAC_Push");
    if (flags & SPAC_PCross)     results.push("SPAC_PCross");
    if (flags & SPAC_UseThrough) results.push("SPAC_UseThrough");
    if (flags & SPAC_AnyCross)   results.push("SPAC_AnyCross");
    if (flags & SPAC_MUse)       results.push("SPAC_MUse");
    if (flags & SPAC_MPush)      results.push("SPAC_MPush");
    if (flags & SPAC_UseBack)    results.push("SPAC_UseBack");
    if (flags & SPAC_Damage)     results.push("SPAC_Damage");
    if (flags & SPAC_Death)      results.push("SPAC_Death");
  
    return add(name, tt_su_su.join(results));
  }
  
  tt_su_Description addLine(string name, Line aLine)
  {
    return addInt(name, aLine.index());
  }
  
  tt_su_Description addSectorPart(string name, SectorPart part)
  {
    switch (part)
      {
      case SECPART_None:    return add(name, "SECPART_None");
      case SECPART_Floor:   return add(name, "SECPART_Floor");
      case SECPART_Ceiling: return add(name, "SECPART_Ceiling");
      case SECPART_3D:      return add(name, "SECPART_3D");
      }
  
    return add(name, string.format("unknown SECPART (%d)", part));
  }
  
  tt_su_Description addSector(string name, Sector aSector)
  {
    return addInt(name, aSector.index());
  }
  
  tt_su_Description addVector3(string name, vector3 vector)
  {
    return add(name, string.format("%.2f, %.2f, %.2f", vector.x, vector.y, vector.z));
  }
  
  tt_su_Description addState(string name, State aState)
  {
    return add(name, new("tt_su_Description").
               addInt("sprite", aState.sprite).
               addInt("frame", aState.Frame).compose());
  }
  private Array<string> mFields;
}

class tt_su_Ascii
{
  enum _
  {
    CHARACTER_NULL = 0,
    START_OF_HEADING = 1,
    START_OF_TEXT = 2,
    END_OF_TEXT = 3,
    END_OF_TRANSMISSION = 4,
    ENQUIRY = 5,
    ACKNOWLEDGE = 6,
    BELL = 7,
    BACKSPACE = 8,
    CHARACTER_TABULATION = 9,
    LINE_FEED_LF = 10,
    LINE_TABULATION = 11,
    FORM_FEED_FF = 12,
    CARRIAGE_RETURN_CR = 13,
    SHIFT_OUT = 14,
    SHIFT_IN = 15,
    DATA_LINK_ESCAPE = 16,
    DEVICE_CONTROL_ONE = 17,
    DEVICE_CONTROL_TWO = 18,
    DEVICE_CONTROL_THREE = 19,
    DEVICE_CONTROL_FOUR = 20,
    NEGATIVE_ACKNOWLEDGE = 21,
    SYNCHRONOUS_IDLE = 22,
    END_OF_TRANSMISSION_BLOCK = 23,
    CANCEL = 24,
    END_OF_MEDIUM = 25,
    SUBSTITUTE = 26,
    ESCAPE = 27,
    INFORMATION_SEPARATOR_FOUR = 28,
    INFORMATION_SEPARATOR_THREE = 29,
    INFORMATION_SEPARATOR_TWO = 30,
    INFORMATION_SEPARATOR_ONE = 31,
    SPACE = 32,
    EXCLAMATION_MARK = 33,
    QUOTATION_MARK = 34,
    NUMBER_SIGN = 35,
    DOLLAR_SIGN = 36,
    PERCENT_SIGN = 37,
    AMPERSAND = 38,
    APOSTROPHE = 39,
    LEFT_PARENTHESIS = 40,
    RIGHT_PARENTHESIS = 41,
    ASTERISK = 42,
    PLUS_SIGN = 43,
    COMMA = 44,
    HYPHEN_MINUS = 45,
    FULL_STOP = 46,
    SOLIDUS = 47,
    DIGIT_ZERO = 48,
    DIGIT_ONE = 49,
    DIGIT_TWO = 50,
    DIGIT_THREE = 51,
    DIGIT_FOUR = 52,
    DIGIT_FIVE = 53,
    DIGIT_SIX = 54,
    DIGIT_SEVEN = 55,
    DIGIT_EIGHT = 56,
    DIGIT_NINE = 57,
    COLON = 58,
    SEMICOLON = 59,
    LESS_THAN_SIGN = 60,
    EQUALS_SIGN = 61,
    GREATER_THAN_SIGN = 62,
    QUESTION_MARK = 63,
    COMMERCIAL_AT = 64,
    LATIN_CAPITAL_LETTER_A = 65,
    LATIN_CAPITAL_LETTER_B = 66,
    LATIN_CAPITAL_LETTER_C = 67,
    LATIN_CAPITAL_LETTER_D = 68,
    LATIN_CAPITAL_LETTER_E = 69,
    LATIN_CAPITAL_LETTER_F = 70,
    LATIN_CAPITAL_LETTER_G = 71,
    LATIN_CAPITAL_LETTER_H = 72,
    LATIN_CAPITAL_LETTER_I = 73,
    LATIN_CAPITAL_LETTER_J = 74,
    LATIN_CAPITAL_LETTER_K = 75,
    LATIN_CAPITAL_LETTER_L = 76,
    LATIN_CAPITAL_LETTER_M = 77,
    LATIN_CAPITAL_LETTER_N = 78,
    LATIN_CAPITAL_LETTER_O = 79,
    LATIN_CAPITAL_LETTER_P = 80,
    LATIN_CAPITAL_LETTER_Q = 81,
    LATIN_CAPITAL_LETTER_R = 82,
    LATIN_CAPITAL_LETTER_S = 83,
    LATIN_CAPITAL_LETTER_T = 84,
    LATIN_CAPITAL_LETTER_U = 85,
    LATIN_CAPITAL_LETTER_V = 86,
    LATIN_CAPITAL_LETTER_W = 87,
    LATIN_CAPITAL_LETTER_X = 88,
    LATIN_CAPITAL_LETTER_Y = 89,
    LATIN_CAPITAL_LETTER_Z = 90,
    LEFT_SQUARE_BRACKET = 91,
    REVERSE_SOLIDUS = 92,
    RIGHT_SQUARE_BRACKET = 93,
    CIRCUMFLEX_ACCENT = 94,
    LOW_LINE = 95,
    GRAVE_ACCENT = 96,
    LATIN_SMALL_LETTER_A = 97,
    LATIN_SMALL_LETTER_B = 98,
    LATIN_SMALL_LETTER_C = 99,
    LATIN_SMALL_LETTER_D = 100,
    LATIN_SMALL_LETTER_E = 101,
    LATIN_SMALL_LETTER_F = 102,
    LATIN_SMALL_LETTER_G = 103,
    LATIN_SMALL_LETTER_H = 104,
    LATIN_SMALL_LETTER_I = 105,
    LATIN_SMALL_LETTER_J = 106,
    LATIN_SMALL_LETTER_K = 107,
    LATIN_SMALL_LETTER_L = 108,
    LATIN_SMALL_LETTER_M = 109,
    LATIN_SMALL_LETTER_N = 110,
    LATIN_SMALL_LETTER_O = 111,
    LATIN_SMALL_LETTER_P = 112,
    LATIN_SMALL_LETTER_Q = 113,
    LATIN_SMALL_LETTER_R = 114,
    LATIN_SMALL_LETTER_S = 115,
    LATIN_SMALL_LETTER_T = 116,
    LATIN_SMALL_LETTER_U = 117,
    LATIN_SMALL_LETTER_V = 118,
    LATIN_SMALL_LETTER_W = 119,
    LATIN_SMALL_LETTER_X = 120,
    LATIN_SMALL_LETTER_Y = 121,
    LATIN_SMALL_LETTER_Z = 122,
    LEFT_CURLY_BRACKET = 123,
    VERTICAL_LINE = 124,
    RIGHT_CURLY_BRACKET = 125,
    TILDE = 126,
    DELETE = 127,
    END
  }

  const FIRST_PRINTABLE = SPACE;
  const CASE_DIFFERENCE = LATIN_SMALL_LETTER_A - LATIN_CAPITAL_LETTER_A;

  static bool isControlCharacter(int code)
  {
    return code < tt_su_Ascii.SPACE || code == tt_su_Ascii.DELETE;
  }
}
