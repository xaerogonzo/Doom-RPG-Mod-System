// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// Interface for getting player info and player pawn.
class tt_PlayerSource abstract
{
  abstract PlayerInfo getInfo();

  abstract PlayerPawn getPawn();

  abstract int getNumber();
}

// Implements tt_PlayerSource by returning player by player number.
class tt_PlayerSourceImpl : tt_PlayerSource
{
  static tt_PlayerSourceImpl of(int playerNumber)
  {
    let result           = new ("tt_PlayerSourceImpl");
    result._playerNumber = playerNumber;
    return result;
  }

  override PlayerInfo getInfo() { return players[_playerNumber]; }

  override PlayerPawn getPawn() { return getInfo().mo; }

  override int getNumber() { return _playerNumber; }

  private int _playerNumber;
}
