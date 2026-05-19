// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// Represents an answer to a tt_Question.
// See tt_Question.
class tt_Answer
{
  static tt_Answer of(String answer = "")
  {
    let result = new("tt_Answer");
    result._answer = answer;
    return result;
  }

  string getString() const
  {
    return _answer;
  }

  void append(string character)
  {
    _answer = _answer .. character;
  }

  void deleteLastCharacter()
  {
    _answer.deleteLastCharacter();
  }

  private string _answer;
}

// This interface represents a source of answers.
class tt_AnswerSource : tt_KeyProcessor abstract
{
  abstract tt_Answer getAnswer();

  // Clears answer.
  abstract void reset();
}

// Implements tt_AnswerSource by taking another tt_AnswerSource,
// and only passing keys to it if a key was pressed down after the game mode
// has changed to Combat.
class tt_InputBlockAfterCombat : tt_AnswerSource
{
  static tt_InputBlockAfterCombat of(tt_AnswerSource answerSource,
                                     tt_ModeSource   modeSource,
                                     tt_ModeSource   oldModeSource)
  {
    let result = new("tt_InputBlockAfterCombat");

    result._answerSource  = answerSource;
    result._modeSource    = modeSource;
    result._oldModeSource = oldModeSource;

    result._isLocked = false;

    return result;
  }

  void update()
  {
    int mode    = _modeSource.getMode();
    int oldMode = _oldModeSource.getMode();

    if (oldMode != tt_Mode.Combat && mode == tt_Mode.Combat)
    {
      _isLocked = true;
    }
  }

  override tt_Answer getAnswer()
  {
    return _answerSource.getAnswer();
  }

  override void processKey(tt_Character character)
  {
    if (character.getEventType() == UiEvent.Type_KeyDown)
    {
      _isLocked = false;
    }

    if (!_isLocked)
    {
      _answerSource.processKey(character);
    }
  }

  override void reset() {}

  private tt_AnswerSource _answerSource;
  private tt_ModeSource   _modeSource;
  private tt_ModeSource   _oldModeSource;

  private bool _isLocked;
}

// Implements tt_AnswerSource by receiving player key inputs and
// composing an answer from them.
class tt_PlayerInput : tt_AnswerSource
{
  static tt_PlayerInput of(tt_ModeStorage      modeStorage,
                           tt_KeyPressReporter keyPressReporter)
  {
    let result = new("tt_PlayerInput");

    result._modeStorage      = modeStorage;
    result._keyPressReporter = keyPressReporter;

    result._answer = tt_Answer.of();

    return result;
  }

  override tt_Answer getAnswer()
  {
    return _answer;
  }

  override void processKey(tt_Character character)
  {
    int type = character.getType();
    switch (type)
    {
    case tt_Character.NONE: break;

    case tt_Character.PRINTABLE:
      _answer.append(character.getCharacter());
      _keyPressReporter.report();
      break;

    case tt_Character.BACKSPACE:      _answer.deleteLastCharacter(); break;
    case tt_Character.CTRL_BACKSPACE: reset();                       break;
    // ESCAPE is intentionally not handled here — the engine processes it
    // to open the pause menu. Combat mode is preserved while the menu is
    // open and resumes naturally when the player closes it.
    }
  }

  override void reset()
  {
    _answer = tt_Answer.of();
  }

  private tt_ModeStorage      _modeStorage;
  private tt_KeyPressReporter _keyPressReporter;

  private tt_Answer _answer;
}
