// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// Represents a character.
class tt_Character
{
  static tt_Character of(int type, int code, bool isCtrl)
  {
    let result = new("tt_Character");

    result._eventType = type;
    //Console.printf("type: %d, code: %d", type, code);

    // Normally, KeyUp events aren't registered, but releasing Enter or Space
    // key has special meaning, important for Hold Fire feature.
    if (type == UiEvent.Type_KeyUp &&
        (code == tt_su_Ascii.CARRIAGE_RETURN_CR || code == tt_su_Ascii.SPACE))
    {
      result._type = ENTER_UP;
      return result;
    }

    bool isChar    = (type == UiEvent.Type_Char);
    bool isDown    = (type == UiEvent.Type_KeyDown);
    bool isRepeat  = (type == UiEvent.Type_KeyRepeat);
    bool isControl = (code == tt_su_Ascii.BACKSPACE
                   || code == tt_su_Ascii.CARRIAGE_RETURN_CR
                   || code == tt_su_Ascii.SPACE
                   || code == tt_su_Ascii.ESCAPE);

    if (!isChar && !((isDown || isRepeat) && isControl))
    {
      result._type = NONE;
      return result;
    }

    if      (code == tt_su_Ascii.BACKSPACE)
      result._type = isCtrl ? CTRL_BACKSPACE : BACKSPACE;
    else if (code == tt_su_Ascii.DELETE)             result._type = CTRL_BACKSPACE;
    else if (code == tt_su_Ascii.CARRIAGE_RETURN_CR) result._type = ENTER;
    else if (code == tt_su_Ascii.SPACE)              result._type = ENTER;
    else if (code == tt_su_Ascii.ESCAPE)             result._type = ESCAPE;
    else if (code <  tt_su_Ascii.FIRST_PRINTABLE)    result._type = NONE;
    else
    {
      result._type      = PRINTABLE;
      result._character = string.format("%c", code);
    }

    return result;
  }

  enum _
  {
    NONE,
    PRINTABLE,
    BACKSPACE,
    CTRL_BACKSPACE,
    ENTER,
    ENTER_UP,
    ESCAPE,
  }

  int getType() const { return _type; }

  string getCharacter() const { return _character; }

  int getEventType() const { return _eventType; }

  private int    _type;
  private string _character;
  private int    _eventType;
}
