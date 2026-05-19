// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// Interface for any non-play effects.
class tt_Effect abstract
{
  abstract void doEffect();
}

class tt_Effects : tt_Effect
{
  static tt_Effects of(Array<tt_Effect> effects)
  {
    let result = new("tt_Effects");
    result._effects.move(effects);
    return result;
  }

  override void doEffect()
  {
    foreach (effect : _effects)
      effect.doEffect();
  }

  private Array<tt_Effect> _effects;
}

// Implements tt_Effect by calling other tt_Effect if there is some tt_Origin.
class tt_Gunner : tt_Effect
{
  static tt_Gunner of(tt_OriginSource originSource, tt_Effect effect)
  {
    let result = new("tt_Gunner");
    result._originSource = originSource;
    result._effect       = effect;
    return result;
  }

  override void doEffect()
  {
    if (_originSource.getOrigin() != NULL) _effect.doEffect();
  }

  private tt_OriginSource _originSource;
  private tt_Effect       _effect;
}

class tt_AnswerResetter : tt_Effect
{
  static tt_AnswerResetter of(tt_AnswerStateSource answerStateSource,
                              tt_AnswerSource      answerSource)
  {
    let result = new("tt_AnswerResetter");
    result._answerStateSource = answerStateSource;
    result._answerSource      = answerSource;
    result._oldAnswerState    = tt_AnswerState.Unknown;
    return result;
  }

  override void doEffect()
  {
    let newAnswerState = _answerStateSource.getAnswerState();
    if (!tt_AnswerState.isFinished(_oldAnswerState)
        && tt_AnswerState.isFinished(newAnswerState))
    {
      _answerStateSource.reset();
      _answerSource.reset();
    }

    _oldAnswerState = newAnswerState;
  }

  private tt_AnswerStateSource _answerStateSource;
  private tt_AnswerSource      _answerSource;

  private int _oldAnswerState;
}

// Watches for answer state source and reports match or not match
// when the state changes from Preparing to Ready.
//
// Match is determined by tt_OriginSource result being not NULL.
class tt_MatchWatcher : tt_Effect
{
  static tt_MatchWatcher of(tt_AnswerStateSource answerStateSource,
                            tt_AnswerReporter    answerReporter,
                            tt_OriginSource      originSource)
  {
    let result = new("tt_MatchWatcher");

    result._answerStateSource = answerStateSource;
    result._answerReporter    = answerReporter;
    result._originSource      = originSource;
    result._oldAnswerState    = tt_AnswerState.Unknown;

    return result;
  }

  override void doEffect()
  {
    let newAnswerState = _answerStateSource.getAnswerState();
    if (!tt_AnswerState.isReady(_oldAnswerState)
        && tt_AnswerState.isReady(newAnswerState))
    {
      let isMatched = (_originSource.getOrigin() != NULL);
      if (isMatched)
      {
        _answerReporter.reportMatch();
      }
      else
      {
        _answerReporter.reportNotMatch();
      }
    }

    _oldAnswerState = newAnswerState;
  }

  private tt_AnswerStateSource _answerStateSource;
  private tt_AnswerReporter    _answerReporter;
  private tt_OriginSource      _originSource;

  private int  _oldAnswerState;
}

class tt_TargetOriginSender : tt_Effect
{
  static tt_TargetOriginSender of(tt_OriginSource targetOriginSource)
  {
    let result = new("tt_TargetOriginSender");
    result._targetOriginSource = targetOriginSource;
    return result;
  }

  override void doEffect()
  {
    vector3 origin = _targetOriginSource.getOrigin().getVector();
    EventHandler.sendNetworkCommand("tt_target",
                                    NET_DOUBLE, origin.x,
                                    NET_DOUBLE, origin.y,
                                    NET_DOUBLE, origin.z);
  }

  private tt_OriginSource _targetOriginSource;
}
