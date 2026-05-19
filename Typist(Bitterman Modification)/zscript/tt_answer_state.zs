// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// Represents Answer state.
// See tt_Answer class.
class tt_AnswerState
{
  enum _
  {
    Unknown,
    Preparing,
    Ready,
    Finished
  }

  static bool isReady(int state) { return state >= Ready; }
  static bool isFinished(int state) { return state == Finished; }
}

// This interface provides access to tt_AnswerState.
class tt_AnswerStateSource : tt_KeyProcessor abstract
{
  // Returns value from tt_AnswerState.
  abstract int getAnswerState();

  abstract void reset();
}

// Implements tt_AnswerState by observing Enter and Space keys.
//
// The state is:
// - Preparing when no Enter or Space key is pressed.
// - Ready when Enter or Space key is pressed, but not yet released.
// - Finished when Enter or Space key is released.
//
// Note: space acts the same as Enter key, see tt_Character class for details.
class tt_PressedAnswerState : tt_AnswerStateSource
{
  static tt_PressedAnswerState of()
  {
    let result = new("tt_PressedAnswerState");
    result._answerState = DEFAULT_STATE;
    return result;
  }

  override void processKey(tt_Character character)
  {
    switch (character.getType())
    {
    case tt_Character.ENTER:    _answerState = tt_AnswerState.Ready;     break;
    case tt_Character.ENTER_UP: _answerState = tt_AnswerState.Finished;  break;
    case tt_Character.NONE:     break;
    default:                    _answerState = tt_AnswerState.Preparing; break;
    }
  }

  override int getAnswerState()
  {
    return _answerState;
  }

  override void reset()
  {
    _answerState = DEFAULT_STATE;
  }

  const DEFAULT_STATE = tt_AnswerState.Preparing;

  private int _answerState;
}
