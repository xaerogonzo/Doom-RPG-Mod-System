// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// Represents a target that already has been seen and registered.
class tt_KnownTarget
{
  static tt_KnownTarget of(tt_Target target, tt_Question question)
  {
    let result = new("tt_KnownTarget");

    result._target   = target;
    result._question = question;

    return result;
  }

  tt_Target getTarget() const { return _target; }

  tt_Question getQuestion() const { return _question; }

  private tt_Target   _target;
  private tt_Question _question;
}

// Represents a list of known targets.
class tt_KnownTargets
{
  static tt_KnownTargets of()
  {
    return new("tt_KnownTargets");
  }

  // Returns a target in this list.
  tt_KnownTarget at(uint index) const
  {
    return _targets[index];
  }

  // Returns a number of targets in this list.
  uint size() const
  {
    return _targets.size();
  }

  // Returns true if this target list contains a target with the specified id.
  bool contains(tt_Target target) const
  {
    return (find(target) != size());
  }

  tt_KnownTarget findTarget(tt_Target target) const
  {
    uint index = find(target);
    return (index == size()) ? NULL : at(index);
  }

  // Adds a target to this list.
  void add(tt_KnownTarget target)
  {
    _targets.push(target);
  }

  void addMany(tt_KnownTargets targets)
  {
    uint nTargets = targets.size();
    for (uint i = 0; i < nTargets; ++i)
    {
      _targets.push(targets.at(i));
    }
  }

  // Removes a target from the list.
  // If the target is not in the list, does nothing.
  void remove(tt_Target target)
  {
    uint index = find(target);
    if (index != size()) { _targets.Delete(index); }
  }

  void clear() { _targets.clear(); }

  // Searches for a target with a particular id.
  // Returns index on success, the total number of targets on failure.
  private uint find(tt_Target target) const
  {
    uint nTargets = size();
    for (uint i = 0; i < nTargets; ++i)
    {
      if (_targets[i].getTarget().isEqual(target)) { return i; }
    }
    return nTargets;
  }

  private Array<tt_KnownTarget> _targets;
}

// This interface represents a source of known targets.
// See tt_KnownTarget.
class tt_KnownTargetSource abstract
{
  // Returns the currently registered (known) targets.
  abstract tt_KnownTargets getTargets() const;

  // Returns true if there are no targets in this source.
  abstract bool isEmpty() const;
}

// Implements tt_KnownTargetSource by reading other
// tt_KnownTargetSource only if the data is stale.
class tt_KnownTargetSourceCache : tt_KnownTargetSource
{
  static tt_KnownTargetSourceCache of(tt_KnownTargetSource targetSource,
                                      tt_StaleMarker staleMarker)
  {
    let result = new("tt_KnownTargetSourceCache");

    result._targetSource = targetSource;
    result._staleMarker  = staleMarker;

    return result;
  }

  override tt_KnownTargets getTargets()
  {
    ensureUpdated();
    return _targets;
  }

  override bool isEmpty()
  {
    ensureUpdated();
    return (_targets.size() == 0);
  }

  private void ensureUpdated()
  {
    if (_staleMarker.isStale())
    {
      _targets = _targetSource.getTargets();
    }
  }

  private tt_KnownTargetSource _targetSource;
  private tt_StaleMarker       _staleMarker;

  private tt_KnownTargets _targets;
}

// Implements tt_KnownTargetSource by reading from targets from
// tt_TargetSource, assigning them questions, and storing them.
//
// Deactivated targets are removed from storage.
class tt_TargetRegistry : tt_KnownTargetSource
{
  static tt_TargetRegistry of(tt_TargetSource targetSource,
                              tt_Lesson lesson,
                              tt_TargetSource disabledTargetSource)
  {
    let result = new("tt_TargetRegistry");

    result._targetSource = targetSource;
    result._lesson       = lesson;
    result._disabledTargetSource = disabledTargetSource;

    result._registry = tt_KnownTargets.of();
    result._newKnownTargets = tt_KnownTargets.of();
    result._pruned = tt_KnownTargets.of();

    return result;
  }

  override tt_KnownTargets getTargets()
  {
    update();
    return _registry;
  }

  override bool isEmpty()
  {
    update();
    return (_registry.size() == 0);
  }

  private void update()
  {
    let newTargets = _targetSource.getTargets();
    merge(newTargets);

    let disabledTargets = _disabledTargetSource.getTargets();
    subtract(disabledTargets);

    pruneNulls();
  }

  // Adds targets that are not already registered to the registry.
  //
  // Given that tt_KnownTargets.contains() is O(n), this function is O(n^2).
  // Optimization possible.
  private void merge(tt_Targets targets)
  {
    uint nTargets = targets.size();

    for (uint i = 0; i < nTargets; ++i)
    {
      let target   = targets.at(i);
      let existing = _registry.findTarget(target);

      if (existing == NULL)
      {
        let knownTarget = makeKnownTarget(target);

        if (knownTarget != NULL)
          _newKnownTargets.add(knownTarget);
      }
    }

    _registry.addMany(_newKnownTargets);
    _newKnownTargets.clear();
  }

  // Given that tt_KnownTargets.remove() is at least O(n), this function is
  // at least O(n^2).
  // Optimization possible.
  private void subtract(tt_Targets targets)
  {
    uint nTargets = targets.size();
    for (uint i = 0; i < nTargets; ++i)
    {
      _registry.remove(targets.at(i));
    }
  }

  private tt_KnownTarget makeKnownTarget(tt_Target target) const
  {
    let question = _lesson.getQuestion();

    if (question == NULL)
    {
      return NULL;
    }

    let newKnownTarget = tt_KnownTarget.of(target, question);

    return newKnownTarget;
  }

  private void pruneNulls()
  {
    uint nTargets = _registry.size();
    for (uint i = 0; i < nTargets; ++i)
    {
      let target      = _registry.at(i).getTarget();
      let targetActor = target.getActor();

      if (targetActor != NULL)
        _pruned.add(_registry.at(i));
    }

    tt_KnownTargets temp = _registry;
    _registry = _pruned;
    _pruned   = temp;
    _pruned.clear();
  }

  private tt_TargetSource   _targetSource;
  private tt_Lesson _lesson;
  private tt_TargetSource   _disabledTargetSource;

  private tt_KnownTargets _registry;
  private tt_KnownTargets _newKnownTargets;
  private tt_KnownTargets _pruned;
}

// Implements tt_KnownTargetSource by providing only targets visible to player.
class tt_VisibleKnownTargetSource : tt_KnownTargetSource
{
  static tt_VisibleKnownTargetSource of(tt_KnownTargetSource base,
                                        tt_PlayerSource playerSource)
  {
    let result = new("tt_VisibleKnownTargetSource");
    result._base = base;
    result._playerSource = playerSource;
    result._targets = tt_KnownTargets.of();
    return result;
  }

  override tt_KnownTargets getTargets() const
  {
    _targets.clear();

    if (_base.isEmpty()) return _targets;

    let pawn = _playerSource.getPawn();
    if (pawn == NULL) return _targets;

    let  baseTargets = _base.getTargets();
    uint targetCount = baseTargets.size();

    for (uint i = 0; i < targetCount; ++i)
    {
      let target = baseTargets.at(i);
      if (isVisible(target, pawn)) _targets.add(target);
    }

    return _targets;
  }

  override bool isEmpty() const
  {
    if (_base.isEmpty()) return true;

    let pawn = _playerSource.getPawn();
    if (pawn == NULL) return true;

    let  baseTargets = _base.getTargets();
    uint targetCount = baseTargets.size();
    for (uint i = 0; i < targetCount; ++i)
      if (isVisible(baseTargets.at(i), pawn)) return false;

    return true;
  }

  // Uses LineTrace to test whether the player has a clear shot at the enemy.
  // Samples 5 points on the enemy: center, head, feet, left shoulder, right
  // shoulder. If ANY trace reaches the enemy, they count as a valid target.
  //
  // The cross-pattern handles enemies on stairs, behind ledges, or at angles
  // where a purely vertical sample line would be fully occluded.
  // Play-const hack: LineTrace is not const.
  private play bool isVisible(tt_KnownTarget target, Actor pawn) const
  {
    let enemy = target.getTarget().getActor();
    if (enemy == NULL) return false;

    vector3 eyePos = pawn.pos;
    eyePos.z += pawn.player ? pawn.player.viewheight : pawn.height * 0.75;

    double  mid      = enemy.height * 0.5;
    double  shoulder = enemy.radius * 0.4; // tighter to avoid bypassing cover

    // Vertical samples
    vector3 toCenter = enemy.pos + (0, 0, mid);
    vector3 toHead   = enemy.pos + (0, 0, enemy.height - 4);
    vector3 toFeet   = enemy.pos + (0, 0, 4);

    // Horizontal samples — offset perpendicular to the enemy->player direction.
    // ZScript vector2 math: rotate toPlayer 90 degrees for a perpendicular offset.
    vector2 toPlayer = pawn.pos.xy - enemy.pos.xy;
    double  fwdLen   = toPlayer.length();
    vector2 perp;
    if (fwdLen > 0)
    {
      double scale = shoulder / fwdLen;
      perp.x = -toPlayer.y * scale;
      perp.y =  toPlayer.x * scale;
    }
    else
    {
      perp.x = shoulder;
      perp.y = 0;
    }
    vector3 toLeft  = (enemy.pos.x + perp.x, enemy.pos.y + perp.y, enemy.pos.z + mid);
    vector3 toRight = (enemy.pos.x - perp.x, enemy.pos.y - perp.y, enemy.pos.z + mid);

    return traceHitsEnemy(pawn, eyePos, toCenter, enemy)
        || traceHitsEnemy(pawn, eyePos, toHead,   enemy)
        || traceHitsEnemy(pawn, eyePos, toFeet,   enemy)
        || traceHitsEnemy(pawn, eyePos, toLeft,   enemy)
        || traceHitsEnemy(pawn, eyePos, toRight,  enemy);
  }

  // Fires a LineTrace from eyePos toward dest.
  // Returns true if the first solid actor hit is the expected enemy.
  //
  // GZDoom pitch convention matches atan2 usage in tt_VerticalAimer:
  // negative pitch = looking up, positive = looking down. So we negate asin().
  private play bool traceHitsEnemy(Actor pawn, vector3 origin,
                                   vector3 dest, Actor enemy) const
  {
    vector3 dir  = dest - origin;
    double  dist = dir.length();
    if (dist < 1) return false;

    double angle = VectorAngle(dir.x, dir.y);
    double pitch = -asin(dir.z / dist);
    double oz    = origin.z - pawn.pos.z;

    FLineTraceData trace;
    pawn.LineTrace(angle, dist, pitch, TRF_SolidActors,
                   offsetz: oz, data: trace);
    return (trace.HitType == TRACE_HitActor && trace.HitActor == enemy);
  }

  private tt_KnownTargetSource _base;
  private tt_PlayerSource _playerSource;
  private tt_KnownTargets _targets;
}
