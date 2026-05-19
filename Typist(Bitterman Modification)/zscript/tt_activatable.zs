// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// This interface represents a game element that can be activated by the same
// way the target is damaged. Such elements can be considered generic targets.
class tt_Activatable abstract
{
  abstract void activate();

  abstract tt_Strings getCommands();

  abstract bool isVisible();
}

class tt_PassThrough : tt_Activatable
{
  static tt_PassThrough of(tt_PassThroughInputManager passThroughInputManager,
                           tt_StringCvar passThroughSetting)
  {
    let result = new("tt_PassThrough");
    result._inputManager = passThroughInputManager;
    result._passThroughSetting = passThroughSetting;
    result._commands = tt_Strings.ofOne("");
    return result;
  }

  override void activate()
  {
    _inputManager.setPassThrough();
  }

  override tt_Strings getCommands()
  {
    _commands.set(0, _passThroughSetting.get());
    return _commands;
  }

  override bool isVisible()
  {
    return true;
  }

  private tt_PassThroughInputManager _inputManager;
  private tt_StringSetting _passThroughSetting;
  private tt_Strings       _commands;
}

// Contains Activatables and activates() ones with commands matching answer.
class tt_CommandDispatcher : tt_Activatable
{
  static tt_CommandDispatcher of(tt_AnswerSource       answerSource,
                                 Array<tt_Activatable> activatables,
                                 tt_AnswerReporter     answerReporter,
                                 tt_AnswerStateSource  answerStateSource,
                                 tt_BoolSetting        fastConfirmation)
  {
    let result = new("tt_CommandDispatcher");

    result._answerSource      = answerSource;
    result._activatables.Copy(activatables);
    result._answerReporter    = answerReporter;
    result._answerStateSource = answerStateSource;
    result._fastConfirmation  = fastConfirmation;
    result._commands          = tt_Strings.of();

    return result;
  }

  override void activate()
  {
    let answerState = _answerStateSource.getAnswerState();
    if (!tt_AnswerState.isReady(answerState) && !_fastConfirmation.get()) return;

    let answer       = _answerSource.getAnswer();
    let answerString = answer.getString();

    foreach (activatable : _activatables)
    {
      bool isActivated = tryActivate(activatable, answerString);

      if (isActivated)
      {
        _answerReporter.reportMatch();
        _answerSource.reset();
        _answerStateSource.reset();
        return;
      }
    }
  }

  override tt_Strings getCommands()
  {
    _commands.clear();

    foreach (activatable : _activatables)
    {
      if (!activatable.isVisible()) continue;

      let commands = activatable.getCommands();

      uint nCommands = commands.size();
      for (uint c = 0; c < nCommands; ++c)
        _commands.add(commands.at(c));
    }

    return _commands;
  }

  override bool isVisible()
  {
    return true;
  }

  private bool tryActivate(tt_Activatable activatable, string answer)
  {
    let commands = activatable.getCommands();

    uint nCommands = commands.size();
    for (uint c = 0; c < nCommands; ++c)
    {
      string command    = commands.at(c);
      bool   isMatching = (command == answer);

      if (isMatching)
      {
        activatable.activate();
        return true;
      }
    }

    return false;
  }

  private tt_AnswerSource       _answerSource;
  private Array<tt_Activatable> _activatables;
  private tt_AnswerReporter     _answerReporter;
  private tt_AnswerStateSource  _answerStateSource;
  private tt_BoolSetting        _fastConfirmation;
  private tt_Strings            _commands;
}
