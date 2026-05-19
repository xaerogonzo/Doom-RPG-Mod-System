// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// Represents the mode in which Typist operates.
class tt_Mode
{
  enum _
  {
    Unknown, // Should never be used. Only for detecting uninitialized variables.
    Combat,  // Typist is focused on destroying the targets.
    Explore, // Typist is focused on movement and exploration.
    None,    // None of the above.
  }
}

// This interface represents a source of modes.
// See: tt_Mode.
class tt_ModeSource abstract
{
  abstract int getMode();
}

// Implements tt_ModeSource by examining the specified tt_KnownTargetSource.
class tt_AutoModeSource : tt_ModeSource
{
  static tt_AutoModeSource of(tt_KnownTargetSource knownTargetSource)
  {
    let result = new("tt_AutoModeSource");
    result._knownTargetSource = knownTargetSource;
    return result;
  }

  override int getMode()
  {
    return _knownTargetSource.isEmpty() ? tt_Mode.Explore : tt_Mode.Combat;
  }

  private tt_KnownTargetSource _knownTargetSource;
}

// Implements tt_ModeSource by reading other tt_ModeSource, and switching to
// Exploration mode only if some time has passed or there is no enemies around.
class tt_DelayedCombatModeSource : tt_ModeSource
{
  static tt_DelayedCombatModeSource of(tt_Clock        clock,
                                       tt_ModeSource   modeSource,
                                       tt_TargetSource targetSource)
  {
    let result = new("tt_DelayedCombatModeSource");

    result._clock        = clock;
    result._modeSource   = modeSource;
    result._targetSource = targetSource;

    result._switchDetected = false;
    result._oldMode        = tt_Mode.None;
    result._switchToExploreMoment = 0;

    return result;
  }

  override int getMode()
  {
    int topMode = _modeSource.getMode();

    if (topMode != tt_Mode.Explore)
    {
      // let others decide.
      _oldMode = topMode;
      return tt_Mode.None;
    }

    bool wasCombat        = _oldMode == tt_Mode.Combat;
    bool isExplore        =  topMode == tt_Mode.Explore;
    bool areEnemiesAround = !_targetSource.getTargets().isEmpty();

    if (wasCombat && isExplore && areEnemiesAround)
    {
      _switchDetected        = true;
      _switchToExploreMoment = _clock.getNow();
    }

    _oldMode = topMode;

    if (!_switchDetected)
    {
      return tt_Mode.None;
    }

    bool timeIsUp = _clock.since(_switchToExploreMoment) > DELAY;

    if (timeIsUp)
    {
      _switchDetected = false;
    }

    return timeIsUp ? tt_Mode.None : tt_Mode.Combat;
  }

  const DELAY = TICRATE * 1; // 1 second

  private tt_Clock        _clock;
  private tt_ModeSource   _modeSource;
  private tt_TargetSource _targetSource;

  private int _switchDetected;
  private int _oldMode;
  private int _switchToExploreMoment;
}

// Implements ModeSource by taking the first mode from ModeSources
// list that is not NONE.
class tt_ModeCascade : tt_ModeSource
{
  static tt_ModeCascade of(Array<tt_ModeSource> modeSources)
  {
    let result = new("tt_ModeCascade");
    result._modeSources.move(modeSources);
    return result;
  }

  override int getMode()
  {
    foreach (source : _modeSources)
    {
      int mode = source.getMode();
      if (mode != tt_Mode.None) return mode;
    }

    return tt_Mode.None;
  }

  private Array<tt_ModeSource> _modeSources;
}

// This is an interface for storing and retrieving mode.
class tt_ModeStorage : tt_ModeSource abstract
{
  abstract void setMode(int mode);
}

// Implements tt_ModeSource by reading other mode source, and
// reporting an event when the mode has changed.
class tt_ReportedModeSource : tt_ModeSource
{
  static tt_ReportedModeSource of(tt_ModeReporter reporter, tt_ModeSource modeSource)
  {
    let result = new("tt_ReportedModeSource");

    result._reporter   = reporter;
    result._modeSource = modeSource;

    result._oldMode = tt_Mode.None;

    return result;
  }

  override int getMode()
  {
    int newMode = _modeSource.getMode();

    if (newMode != _oldMode)
    {
      if (_oldMode != tt_Mode.None)
      {
        _reporter.report(newMode);
      }

      _oldMode = newMode;
    }

    return newMode;
  }

  private tt_ModeReporter _reporter;
  private tt_ModeSource   _modeSource;

  private int _oldMode;
}

// Implements ModeStorage by simply storing the mode that was set.
class tt_SettableMode : tt_ModeStorage
{
  static tt_SettableMode of()
  {
    let result = new("tt_SettableMode");

    result._mode = tt_Mode.None;

    return result;
  }

  override int getMode()
  {
    return _mode;
  }

  override void setMode(int mode)
  {
    _mode = mode;
  }

  private int _mode;
}

// Implements tt_ModeSource by overriding manual Explore requests back to
// Combat when there are still LineTrace-confirmed shootable targets.
//
// Features:
//   - Entry hysteresis: LOS must be confirmed for tt_combat_entry_ticks
//     consecutive ticks before the lock engages. Prevents flicker-locking
//     through thin geometry or brief exposure.
//   - Emergency exit: set via tt_emergency_exit console command. Bypasses
//     ALL lock logic unconditionally and resets after one use. Panic button.
//   - Manual exit allowed freely when no LOS targets exist.
class tt_LockedCombatModeSource : tt_ModeSource
{
  static tt_LockedCombatModeSource of(tt_ModeSource        manualModeSource,
                                      tt_KnownTargetSource visibleTargetSource,
                                      tt_PlayerSource      playerSource)
  {
    let result = new("tt_LockedCombatModeSource");
    result._manualModeSource    = manualModeSource;
    result._visibleTargetSource = visibleTargetSource;
    result._playerSource        = playerSource;
    result._losConfirmedTicks   = 0;
    result._lockEngaged         = false;
    result._emergencyExit       = false;
    return result;
  }

  // Called by tt_EventHandler when tt_emergency_exit fires.
  void triggerEmergencyExit() { _emergencyExit = true; }

  override int getMode()
  {
    // Emergency exit — unconditional, clears itself immediately.
    if (_emergencyExit)
    {
      _emergencyExit     = false;
      _lockEngaged       = false;
      _losConfirmedTicks = 0;
      return tt_Mode.None;
    }

    bool hasLosTargets = !_visibleTargetSource.isEmpty();

    // Update hysteresis counter.
    if (hasLosTargets)
    {
      int threshold = getEntryThreshold();
      _losConfirmedTicks = min(_losConfirmedTicks + 1, threshold);
      if (_losConfirmedTicks >= threshold)
        _lockEngaged = true;
    }
    else
    {
      _losConfirmedTicks = 0;
      _lockEngaged       = false;
    }

    // Only act when the player is explicitly trying to go to Explore.
    if (_manualModeSource.getMode() != tt_Mode.Explore) return tt_Mode.None;

    // Lock engaged and LOS targets exist — deny the manual exit.
    if (_lockEngaged && hasLosTargets) return tt_Mode.Combat;

    // No lock or no targets — manual exit allowed.
    return tt_Mode.None;
  }

  private int getEntryThreshold() const
  {
    let cv = CVar.GetCVar("tt_combat_entry_ticks", _playerSource.getInfo());
    if (cv != NULL) return max(1, cv.GetInt());
    return DEFAULT_ENTRY_TICKS;
  }

  const DEFAULT_ENTRY_TICKS = 15;

  private tt_ModeSource        _manualModeSource;
  private tt_KnownTargetSource _visibleTargetSource;
  private tt_PlayerSource      _playerSource;
  private int                  _losConfirmedTicks;
  private bool                 _lockEngaged;
  private bool                 _emergencyExit;
}

// Implements tt_ModeSource by choosing Explore mode on the automap.
class tt_AutomapModeSource : tt_ModeSource
{
  static tt_AutomapModeSource of()
  {
    return new("tt_AutomapModeSource");
  }

  override int getMode()
  {
    return automapActive ? tt_Mode.Explore : tt_Mode.None;
  }
}
