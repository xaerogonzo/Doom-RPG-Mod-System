// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// Helps managing user input.
class tt_InputManager abstract
{
  abstract void manageInput();

  abstract bool isCapturingKeys();
}

// Implements tt_InputManager by examining the current and old Typist mode.
// Input is reset when the game mode is changed.
class tt_InputByModeManager : tt_InputManager
{
  static tt_InputByModeManager of(tt_ModeSource modeSource,
                                  tt_PlayerInput playerInput)
  {
    let result = new("tt_InputByModeManager");

    result._modeSource  = modeSource;
    result._playerInput = playerInput;

    result._oldMode = tt_Mode.Unknown;

    return result;
  }

  override void manageInput()
  {
    int  mode             = _modeSource.getMode();
    bool isCapturingKeys  = (mode == tt_Mode.Combat);
    bool wasCapturingKeys = (_oldMode != tt_Mode.Combat);

    if (wasCapturingKeys && isCapturingKeys == false)
    {
      _playerInput.reset();
    }

    _oldMode = mode;
  }

  override bool isCapturingKeys()
  {
    int mode = _modeSource.getMode();
    return (mode == tt_Mode.Combat);
  }

  private tt_ModeSource  _modeSource;
  private tt_PlayerInput _playerInput;

  private int _oldMode;
}

// Doesn't capture keys when pass through is set, otherwise acts as base.
class tt_PassThroughInputManager : tt_InputManager
{
  static tt_PassThroughInputManager of(tt_InputManager base)
  {
    let result = new("tt_PassThroughInputManager");
    result._base = base;
    result._passThrough = PassThroughDisabled;
    return result;
  }

  override void manageInput()
  {
    _base.manageInput();
  }

  override bool isCapturingKeys()
  {
    if (_passThrough != PassThroughDisabled) return false;

    return _base.isCapturingKeys();
  }

  void setPassThrough()
  {
    _passThrough = WaitingForKeyDown;
  }

  void processInput(int type)
  {
    switch (_passThrough)
    {
      case PassThroughDisabled:
        return;

      case WaitingForKeyDown:
        if (type == InputEvent.Type_KeyDown)
          _passThrough = WaitingForKeyUp;
        return;

      case WaitingForKeyUp:
        if (type == InputEvent.Type_KeyUp)
          _passThrough = PassThroughDisabled;
        return;
    }
  }

  private tt_InputManager _base;
  private int _passThrough;

  enum _
  {
    PassThroughDisabled,
    WaitingForKeyDown,
    WaitingForKeyUp
  }
}
