// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// Represents an attack target.
class tt_Target
{
  static tt_Target of(Actor a)
  {
    let result = new("tt_Target");
    result._actor = a;
    result._origin = tt_Origin.of((0, 0, 0));
    return result;
  }

  // Get position in game space of this target.
  tt_Origin getPosition() const
  {
    vector3 position = _actor.pos;
    // Aim at upper chest (75% height) rather than center (50%) to compensate
    // for the player shot origin being at eye level above the aim indicator.
    position.z += _actor.height * 0.75;

    _origin.setVector(position);
    return _origin;
  }

  bool isEqual(tt_Target other) const
  {
    return other._actor == _actor;
  }

  Actor getActor() const
  {
    return _actor;
  }

  private Actor     _actor;
  private tt_Origin _origin;
}

// Represent a list of Targets.
class tt_Targets
{
  static tt_Targets of() { return new("tt_Targets"); }

  // Returns a target in this list.
  tt_Target at(uint index) const { return _targets[index]; }

  // Returns a number of targets in this list.
  uint size() const { return _targets.size(); }

  // Returns true if this target list contains a target with the specified id.
  bool contains(tt_Target target) const { return find(target) != size(); }

  bool isEmpty() const { return (size() == 0); }

  // Adds a target to this list.
  void add(tt_Target target) { _targets.push(target); }

  void clear() { _targets.clear(); }

  // Searches for a target with a particular id.
  // Returns index on success, the total number of targets on failure.
  private uint find(tt_Target target) const
  {
    uint nTargets = size();
    for (uint i = 0; i < nTargets; ++i)
      if (_targets[i].isEqual(target)) return i;
    return nTargets;
  }

  private Array<tt_Target> _targets;
}

// This interface represents a source of targets.
// See: tt_Target.
class tt_TargetSource abstract
{
  abstract tt_Targets getTargets();
}

// Implements tt_TargetSource by scanning the world around the
// supplied origin for actors suitable to be targets.
class tt_TargetRadar : tt_TargetSource
{
  static tt_TargetRadar of(tt_OriginSource originSource)
  {
    let result = new("tt_TargetRadar");
    result._originSource = originSource;
    result._targets      = tt_Targets.of();
    return result;
  }

  override tt_Targets getTargets()
  {
    _targets.clear();

    let origin = _originSource.getOrigin().getVector();

    let iterator = ThinkerIterator.Create("Actor", Thinker.STAT_DEFAULT);
    Actor a;
    while (a = Actor(iterator.Next()))
    {
      if (tt_Math.isInEffectiveRange(a.pos, origin) && isSuitableForTargeting(a))
        _targets.add(tt_Target.of(a));
    }

    return _targets;
  }

  private static bool isSuitableForTargeting(Actor anActor)
  {
    bool isMonster    = anActor.bIsMonster;
    bool isDamageable = !anActor.bNoDamage;
    bool isAlive      = anActor.Health > 0;
    bool isFriendly   = anActor.bFriendly;
    bool wasFriendly  = getDefaultByType(anActor.getClass()).bFriendly;

    return isMonster && isDamageable && isAlive && !isFriendly && !wasFriendly;
  }

  private tt_OriginSource _originSource;
  private tt_Targets      _targets;
}

// Implements tt_TargetSource by collecting reports of
// dead things as a list of DisabledTargets.
class tt_DeathReporter : tt_TargetSource
{
  static tt_DeathReporter of()
  {
    let result = new("tt_DeathReporter");
    result._accumulatedTargets = tt_Targets.of();
    result._resultTargets      = tt_Targets.of();
    return result;
  }

  void reportDead(Actor thing)
  {
    let newDisabled = tt_Target.of(thing);
    _accumulatedTargets.add(newDisabled);
  }

  override tt_Targets getTargets()
  {
    tt_Targets temp = _resultTargets;
    _resultTargets = _accumulatedTargets;
    _accumulatedTargets = temp;
    _accumulatedTargets.clear();
    return _resultTargets;
  }

  private tt_Targets _accumulatedTargets;
  private tt_Targets _resultTargets;
}

// Implements tt_TargetSource by calling other tt_TargetSource only
// if previously received target is stale.
class tt_TargetSourceCache : tt_TargetSource
{
  static tt_TargetSourceCache of(tt_TargetSource targetSource,
                                 tt_StaleMarker staleMarker)
  {
    let result = new("tt_TargetSourceCache");

    result._targetSource = targetSource;
    result._staleMarker  = staleMarker;

    return result;
  }

  override tt_Targets getTargets()
  {
    if (_staleMarker.isStale())
    {
      _targets = _targetSource.getTargets();
    }

    return _targets;
  }

  private tt_TargetSource _targetSource;
  private tt_StaleMarker  _staleMarker;

  private tt_Targets _targets;
}

// Implements tt_TargetSource by pruning other tt_TargetSource from
// targets with null actors.
class tt_TargetSourcePruner : tt_TargetSource
{
  static tt_TargetSourcePruner of(tt_TargetSource targetSource)
  {
    let result = new("tt_TargetSourcePruner");
    result._targetSource = targetSource;
    result._targets = tt_Targets.of();
    return result;
  }

  override tt_Targets getTargets()
  {
    let targets = _targetSource.getTargets();

    _targets.clear();

    uint nTargets = targets.size();
    for (uint i = 0; i < nTargets; ++i)
    {
      tt_Target target = targets.at(i);
      if (target.getActor() != NULL)
        _targets.add(target);
    }

    return _targets;
  }

  private tt_TargetSource _targetSource;
  private tt_Targets      _targets;
}
