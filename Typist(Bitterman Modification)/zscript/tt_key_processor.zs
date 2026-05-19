// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// This interface represents an entity that processes input keys.
class tt_KeyProcessor abstract
{
  abstract void processKey(tt_Character character);
}

// Implements tt_KeyProcessor interface by calling several instances
// of tt_KeyProcessor.
class tt_KeyProcessors : tt_KeyProcessor
{
  static tt_KeyProcessors of(Array<tt_KeyProcessor> keyProcessors)
  {
    let result = new("tt_KeyProcessors");
    result._keyProcessors.copy(keyProcessors);
    return result;
  }

  override void processKey(tt_Character character)
  {
    foreach (keyProcessor : _keyProcessors)
      keyProcessor.processKey(character);
  }

  private Array<tt_KeyProcessor> _keyProcessors;
}
