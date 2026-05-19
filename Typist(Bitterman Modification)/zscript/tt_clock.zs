// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// Provides access to time.
class tt_Clock abstract
{
  // Provides access to getting points in time.
  // Returns a moment in time.
  abstract int getNow();

  // Provides a way to determine how many ticks passed since a moment in time.
  // moment: a moment in time, received from getNow().
  // Returns a number of ticks since  moment.
  abstract int since(int moment);
}

// Implements tt_Clock by getting total time since game start.
class tt_TotalClock : tt_Clock
{
  static tt_TotalClock of()
  {
    let result = new("tt_TotalClock");
    return result;
  }

  override int getNow()
  {
    return Level.totalTime;
  }

  override int since(int moment)
  {
    return getNow() - moment;
  }
}
