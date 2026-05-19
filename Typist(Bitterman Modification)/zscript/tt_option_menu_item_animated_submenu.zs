// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

class OptionMenuItemtt_AnimatedSubmenu : OptionMenuItemSubmenu
{
  // Signature mirrors OptionMenuItemSubmenu.Init().
  OptionMenuItemtt_AnimatedSubmenu Init( string label
                                       , Name   command
                                       , int    param    = 0
                                       , bool   centered = false
                                       )
  {
    Super.Init(label, command, param, centered);

    _originalLabel  = stringTable.Localize(label);
    _originalLength = _originalLabel.CodePointCount();
    _period         = DELAY_TICS + _originalLength * CHARACTER_TIMEOUT_TICS;

    return self;
  }

  override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected)
  {
    int highlightedLetterIndex = _state / CHARACTER_TIMEOUT_TICS;

    if (highlightedLetterIndex < _originalLength)
    {
      int letterCode;
      int charPos = 0;
      for (int i = 0; i < highlightedLetterIndex; ++i)
      {
        [letterCode, charPos] = _originalLabel.GetNextCodePoint(charPos);
      }

      string left           = _originalLabel.Left(charPos);
      [letterCode, charPos] = _originalLabel.GetNextCodePoint(charPos);
      string right          = _originalLabel.Mid(charPos, _originalLabel.Length() - charPos);

      mLabel = string.format("%s\cd%c\c-%s", left, letterCode, right);
    }
    else
    {
      mLabel = _originalLabel;
    }

    ++_state;
    if (_state >= _period)
    {
      _state = 0;
    }

    return Super.Draw(desc, y, indent, selected);
  }

  const DELAY_TICS = 5 * TICRATE;
  const CHARACTER_TIMEOUT_TICS = 3;

  private int    _state;
  private int    _period;
  private string _originalLabel;
  private int    _originalLength;
}
