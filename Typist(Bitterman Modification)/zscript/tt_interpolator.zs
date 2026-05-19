// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

class tt_DoubleInterpolator
{
  static tt_DoubleInterpolator of() { return new("tt_DoubleInterpolator"); }

  ui void update()
  {
    _currentValue = (_destination > _currentValue)
      ? min(_destination, _currentValue + _step)
      : max(_destination, _currentValue - _step);
  }

  ui double getValue() const { return _currentValue; }

  ui void reset(double destination, double step)
  {
    _destination = destination;
    _step = step;
  }

  private ui double _destination;
  private ui double _currentValue;
  private ui double _step;
}
