// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// Entry point for Typist.pk3.
class tt_EventHandler : EventHandler
{
  override void worldTick()
  {
    _playerHandler.tick();
    _server.tick();
    self.IsUiProcessor = _playerHandler.isCapturingKeys();
  }

  override bool uiProcess(UiEvent event)
  {
    // Let escape pass through to the engine so it opens the pause menu.
    // Combat mode is preserved while the menu is open.
    if (event.type == UiEvent.Type_KeyDown && event.keyChar == tt_su_Ascii.ESCAPE)
      return false;

    let character = tt_Character.of(event.type, event.keyChar, event.isCtrl);
    _playerHandler.processKey(character);

    return false;
  }

  override bool inputProcess(InputEvent event)
  {
    _playerHandler.processInput(event.type);
    return false;
  }

  override void playerEntered(PlayerEvent event)
  {
    if (gameState != GS_Level && gameState != GS_StartUp) return;

    self.RequireMouse = true;

    if (_server == NULL) _server = tt_Server.of();

    int playerNumber = event.playerNumber;

    _server.addPlayer(playerNumber);
    tt_GameTweaks.tweakPlayer(players[playerNumber]);

    if (playerNumber == consolePlayer)
    {
      _playerHandler = tt_PlayerSupervisor.of(consolePlayer);
      _server.setVisibleTargetSource(consolePlayer,
                                     _playerHandler.getVisibleTargetSource());
    }
  }

  override void playerDisconnected(PlayerEvent event)
  {
    _server.removePlayer(event.playerNumber);
  }

  override void playerDied(PlayerEvent event)
  {
    _playerHandler.setMode(tt_Mode.Explore);
  }

  override void playerRespawned(PlayerEvent event)
  {
    _playerHandler.setMode(tt_Mode.None);
  }

  override void worldThingDied(WorldEvent event)
  {
    _playerHandler.reportDead(event.Thing);
  }

  override void worldLoaded(WorldEvent event)
  {
    bool isTitlemap = (level.mapName ~== "TITLEMAP");
    if (isTitlemap)
      destroy();
  }

  override void worldUnloaded(WorldEvent event)
  {
    self.IsUiProcessor = false;
  }

  override void renderOverlay(RenderEvent event)
  {
    _playerHandler.draw(event);
  }

  override void consoleProcess(ConsoleEvent event)
  {
    string command = event.Name;

    if (command.left(3) != "tt_") return;

    if      (command == "tt_unlock_mode"   ) _playerHandler.setMode(tt_Mode.None);
    else if (command == "tt_force_combat"  ) _playerHandler.setMode(tt_Mode.Combat);
    else if (command == "tt_reset_targets" ) _playerHandler.reset(consolePlayer);
    else if (command == "tt_emergency_exit") _playerHandler.triggerEmergencyExit();
  }

  override void networkCommandProcess(NetworkCommand command)
  {
    if (command.command == "tt_target")
    {
      double x = command.readDouble();
      double y = command.readDouble();
      double z = command.readDouble();

      _server.react(command.player, (x, y, z));
    }
  }

  int getMode() const { return _playerHandler.getMode(); }

  private tt_PlayerHandler _playerHandler;
  private tt_Server        _server;
}
