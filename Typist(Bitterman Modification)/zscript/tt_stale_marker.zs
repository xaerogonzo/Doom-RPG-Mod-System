// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// This interface provides information when its instance becomes stale.
class tt_StaleMarker abstract
{
  // Update stale status.
  // Attention! Calling this function may change the state of tt_StaleMarker.
  // Returns true if this instance is currently stale.
  abstract bool isStale();
}

// Implements tt_StaleMarker by observing a tt_Clock.
class tt_StaleMarkerImpl : tt_StaleMarker
{
  // Creates an instance of tt_StaleMarkerImpl.
  // clock: dependency, a clock to be observed.
  // updateTicks: in how much ticks this marker becomes stale.
  static tt_StaleMarkerImpl of(tt_Clock clock, int updateTicks = 1)
  {
    let result = new("tt_StaleMarkerImpl");

    result._clock       = clock;

    result._updateTicks = updateTicks;
    result._isEmpty     = true;
    result._oldMoment   = 0;

    return result;
  }

  override bool isStale()
  {
    if (!shouldUpdate()) return false;

    _oldMoment = _clock.getNow();
    _isEmpty   = false;

    return true;
  }

  private bool shouldUpdate() const
  {
    if (_isEmpty) return true;

    int  passed     = _clock.since(_oldMoment);
    bool isObsolete = (passed >= _updateTicks);

    return isObsolete;
  }

  private tt_Clock _clock;

  private int  _updateTicks;
  private bool _isEmpty;
  private int  _oldMoment;
}
