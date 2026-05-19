// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// Represents a point in space.
// Note that the Origin position cannot change once set.
class tt_Origin
{
  static tt_Origin of(vector3 pos)
  {
    let result = new("tt_Origin");
    result._pos = pos;
    return result;
  }

  vector3 getVector() const { return _pos; }
  void setVector(vector3 value) { _pos = value; }

  private vector3 _pos;
}

// This interface represents a source of origins.
class tt_OriginSource abstract
{
  // Returns the origin (coordinate in 3D space).
  // Getting the origin doesn't change it.
  abstract tt_Origin getOrigin();
}

// Implements OriginSource by finding an origin for a known target
// that fits to for the answer.
class tt_HastyQuestionAnswerMatcher : tt_OriginSource
{
  static tt_HastyQuestionAnswerMatcher of(tt_KnownTargetSource knownTargetSource,
                                          tt_AnswerSource      answerSource,
                                          tt_AnswerReporter    reporter)
  {
    let result = new("tt_HastyQuestionAnswerMatcher");
    result._knownTargetSource = knownTargetSource;
    result._answerSource      = answerSource;
    result._reporter          = reporter;
    return result;
  }

  override tt_Origin getOrigin()
  {
    let targets = _knownTargetSource.getTargets();
    if (targets == NULL || targets.size() == 0) { return NULL; }

    let answer = _answerSource.getAnswer();
    if (answer == NULL) { return NULL; }

    let result = findMatchedTarget(targets, answer);

    if (result != NULL)
    {
      _reporter.reportMatch();
      _answerSource.reset();
    }

    return result;
  }

  private tt_Origin findMatchedTarget(tt_KnownTargets targets, tt_Answer answer)
  {
    string answerString = answer.getString();
    uint nTargets = targets.size();
    for (uint i = 0; i < nTargets; ++i)
    {
      let target   = targets.at(i);
      let question = target.getQuestion();

      if (!question.isRight(answerString)) continue;

      let result = target.getTarget().getPosition();
      return result;
    }

    return NULL;
  }

  private tt_KnownTargetSource _knownTargetSource;
  private tt_AnswerSource      _answerSource;
  private tt_AnswerReporter    _reporter;
}

// Implements OriginSource by reading other OriginSource only if origin is stale.
class tt_OriginSourceCache : tt_OriginSource
{
  static tt_OriginSourceCache of(tt_OriginSource originSource,
                                 tt_StaleMarker staleMarker)
  {
    let result = new("tt_OriginSourceCache");

    result._originSource = originSource;
    result._staleMarker  = staleMarker;

    result._origin = NULL;

    return result;
  }

  override tt_Origin getOrigin()
  {
    if (_staleMarker.isStale())
    {
      _origin = _originSource.getOrigin();
    }

    return _origin;
  }

  private tt_OriginSource _originSource;
  private tt_StaleMarker  _staleMarker;

  private tt_Origin _origin;
}

// Implements tt_OriginSource by providing the center of the player pawn.
class tt_PlayerOriginSource : tt_OriginSource
{
  static tt_PlayerOriginSource of(tt_PlayerSource playerSource)
  {
    let result = new("tt_PlayerOriginSource");
    result._playerSource = playerSource;
    result._origin = tt_Origin.of((0, 0, 0));
    return result;
  }

  override tt_Origin getOrigin()
  {
    let pawn = _playerSource.getPawn();
    let pos  = pawn.pos;
    pos.z += pawn.height / 2;

    _origin.setVector(pos);
    return _origin;
  }

  private tt_PlayerSource _playerSource;
  private tt_Origin       _origin;
}

// Implements OriginSource by finding an origin for a known target that fits to
// for the answer. Searches far matching target only if answer state is Ready.
class tt_QuestionAnswerMatcher : tt_OriginSource
{
  static tt_QuestionAnswerMatcher of(tt_KnownTargetSource knownTargetSource,
                                     tt_AnswerSource      answerSource,
                                     tt_AnswerStateSource answerStateSource)
  {
    let result = new("tt_QuestionAnswerMatcher");
    result._knownTargetSource = knownTargetSource;
    result._answerSource      = answerSource;
    result._answerStateSource = answerStateSource;
    return result;
  }

  override tt_Origin getOrigin()
  {
    let targets = _knownTargetSource.getTargets();
    if (targets == NULL || targets.size() == 0) { return NULL; }

    let answer = _answerSource.getAnswer();
    if (answer == NULL) { return NULL; }

    let answerState = _answerStateSource.getAnswerState();
    if (!tt_AnswerState.isReady(answerState)) { return NULL; }

    let result = findMatchedTarget(targets, answer);

    return result;
  }

  private tt_Origin findMatchedTarget(tt_KnownTargets targets, tt_Answer answer)
  {
    string answerString = answer.getString();
    uint nTargets = targets.size();
    for (uint i = 0; i < nTargets; ++i)
    {
      let target   = targets.at(i);
      let question = target.getQuestion();

      if (!question.isRight(answerString)) continue;

      let result = target.getTarget().getPosition();
      return result;
    }

    return NULL;
  }

  private tt_KnownTargetSource _knownTargetSource;
  private tt_AnswerSource      _answerSource;
  private tt_AnswerStateSource _answerStateSource;
}

// Implements OriginSource by selecting one of the two supplied
// origin sources based on a value of tt_BoolSetting.
class tt_SelectableOriginSource : tt_OriginSource
{
  static tt_SelectableOriginSource of(tt_OriginSource source1,
                                      tt_OriginSource source2,
                                      tt_BoolSetting  fastConfirmation)
  {
    let result = new("tt_SelectableOriginSource");
    result._source1 = source1;
    result._source2 = source2;
    result._fastConfirmation = fastConfirmation;
    return result;
  }

  override tt_Origin getOrigin()
  {
    return _fastConfirmation.get()
      ? _source1.getOrigin()
      : _source2.getOrigin();
  }

  private tt_OriginSource _source1;
  private tt_OriginSource _source2;
  private tt_BoolSetting  _fastConfirmation;
}

// Implements tt_OriginSource by receiving the source from elsewhere.
class tt_ExternalOriginSource : tt_OriginSource
{
  static tt_ExternalOriginSource of()
  {
    let result = new("tt_ExternalOriginSource");
    return result;
  }

  override tt_Origin getOrigin()
  {
    return _origin;
  }

  void setOrigin(tt_Origin origin)
  {
    _origin = origin;
  }

  private tt_Origin _origin;
}
