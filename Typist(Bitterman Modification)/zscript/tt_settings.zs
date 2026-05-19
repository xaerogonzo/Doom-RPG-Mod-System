// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

class tt_BoolSetting abstract
{
  abstract bool isDefined();

  abstract bool get();
}

class tt_IntSetting abstract
{
  abstract bool isDefined();

  abstract int get();
}

class tt_FloatSetting abstract
{
  abstract bool isDefined();

  abstract double get();
}

class tt_StringSetting abstract
{
  abstract bool isDefined();

  abstract string get();
}

// Provides access to a user or server bool Cvar.
class tt_BoolCvar : tt_BoolSetting
{
  static tt_BoolCvar of(tt_PlayerSource playerSource, string name)
  {
    let result = new("tt_BoolCvar");
    result._cvar = Cvar.getCvar(name, playerSource.getInfo());
    if (result._cvar != NULL && result._cvar.getRealType() != Cvar.CVAR_Bool)
      throwAbortException("%s Cvar is not bool", name);
    return result;
  }

  override bool isDefined() { return (_cvar != NULL); }
  override bool get()   { return _cvar.getInt();  }

  private Cvar _cvar;
}

// Provides access to a user or server bool Cvar. Protects against values < 1.
class tt_PositiveIntCvar : tt_IntSetting
{
  static tt_PositiveIntCvar of(tt_PlayerSource playerSource, string name)
  {
    let result = new("tt_PositiveIntCvar");
    result._cvar = Cvar.getCvar(name, playerSource.getInfo());
    if (result._cvar != NULL && result._cvar.getRealType() != Cvar.CVAR_Int)
      throwAbortException("%s Cvar is not int", name);
    return result;
  }

  override bool isDefined() { return (_cvar != NULL); }
  override int  get()       { return max(1, _cvar.getInt());  }

  private Cvar _cvar;
}

// Provides access to a user or server bool Cvar.
class tt_IntCvar : tt_IntSetting
{
  static tt_IntCvar of(tt_PlayerSource playerSource, string name)
  {
    let result = new("tt_IntCvar");
    result._cvar = Cvar.getCvar(name, playerSource.getInfo());
    if (result._cvar != NULL && result._cvar.getRealType() != Cvar.CVAR_Int)
      throwAbortException("%s Cvar is not int", name);
    return result;
  }

  override bool isDefined() { return (_cvar != NULL); }
  override int  get()       { return _cvar.getInt();  }

  private Cvar _cvar;
}

// Provides access to a user or server float Cvar.
class tt_FloatCvar : tt_FloatSetting
{
  static tt_FloatCvar of(tt_PlayerSource playerSource, string name)
  {
    let result = new("tt_FloatCvar");
    result._cvar = Cvar.getCvar(name, playerSource.getInfo());
    if (result._cvar != NULL && result._cvar.getRealType() != Cvar.CVAR_Float)
      throwAbortException("%s Cvar is not float", name);
    return result;
  }

  override bool   isDefined() { return (_cvar != NULL); }
  override double get() { return _cvar.getFloat(); }

  private Cvar _cvar;
}

// Provides access to a user or server string Cvar.
class tt_StringCvar : tt_StringSetting
{
  static tt_StringCvar of(tt_PlayerSource playerSource, string name)
  {
    let result = new("tt_StringCvar");
    result._cvar = Cvar.getCvar(name, playerSource.getInfo());
    if (result._cvar != NULL && result._cvar.getRealType() != Cvar.CVAR_String)
      throwAbortException("%s Cvar is not string", name);
    return result;
  }

  override bool   isDefined() { return (_cvar != NULL); }
  override string get() { return _cvar.getString(); }

  private Cvar _cvar;
}

// Represents settings for tt_RandomCharactersLesson.
class tt_RandomCharactersLessonSettings abstract
{
  abstract int getLessonLength();

  abstract bool isUppercaseLettersEnabled();

  abstract bool isLowercaseLettersEnabled();

  abstract bool isNumbersEnabled();

  abstract bool isPunctuationEnabled();

  abstract bool isSymbolsEnabled();

  abstract bool isCustomCharactersEnabled();

  abstract string getCustomCharacters();
}

// Implements tt_RandomCharactersLessonSettings by returning Cvar contents.
class tt_RandomCharactersLessonSettingsImpl : tt_RandomCharactersLessonSettings
{
  static tt_RandomCharactersLessonSettingsImpl of(tt_PlayerSource playerSource)
  {
    let result = new("tt_RandomCharactersLessonSettingsImpl");

    result._lessonLength       = tt_PositiveIntCvar.of(playerSource,
                                                       "tt_rc_length");
    result._isUppercaseEnabled = tt_BoolCvar.of(playerSource,
                                                "tt_rc_uppercase_letters_enabled");
    result._isLowercaseEnabled = tt_BoolCvar.of(playerSource,
                                                "tt_rc_lowercase_letters_enabled");
    result._isNumbersEnabled   = tt_BoolCvar.of(playerSource,
                                                "tt_rc_numbers_enabled");
    result._isPunctuationEnabled = tt_BoolCvar.of(playerSource,
                                                  "tt_rc_punctuation_enabled");
    result._isSymbolsEnabled     = tt_BoolCvar.of(playerSource,
                                                  "tt_rc_symbols_enabled");
    result._isCustomEnabled      = tt_BoolCvar.of(playerSource,
                                                  "tt_rc_custom_enabled");
    result._customCharacters     = tt_StringCvar.of(playerSource, "tt_rc_custom");

    return result;
  }

  override int  getLessonLength()           { return _lessonLength.get(); }
  override bool isUppercaseLettersEnabled() { return _isUppercaseEnabled.get(); }
  override bool isLowercaseLettersEnabled() { return _isLowercaseEnabled.get(); }
  override bool isNumbersEnabled()          { return _isNumbersEnabled.get(); }
  override bool isPunctuationEnabled()      { return _isPunctuationEnabled.get(); }
  override bool isSymbolsEnabled()          { return _isSymbolsEnabled.get(); }
  override bool isCustomCharactersEnabled() { return _isCustomEnabled.get(); }
  override string getCustomCharacters()     { return _customCharacters.get(); }

  private tt_PositiveIntCvar _lessonLength;
  private tt_BoolCvar   _isUppercaseEnabled;
  private tt_BoolCvar   _isLowercaseEnabled;
  private tt_BoolCvar   _isNumbersEnabled;
  private tt_BoolCvar   _isPunctuationEnabled;
  private tt_BoolCvar   _isSymbolsEnabled;
  private tt_BoolCvar   _isCustomEnabled;
  private tt_StringCvar _customCharacters;
}
