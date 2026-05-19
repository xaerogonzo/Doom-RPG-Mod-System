// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// Interface for reporting answer matching events.
class tt_AnswerReporter abstract
{
  abstract void reportMatch();

  abstract void reportNotMatch();
}

// Implements tt_AnswerReporter by playing a sound.
class tt_SoundAnswerReporter : tt_AnswerReporter
{
  static tt_SoundAnswerReporter of(tt_SoundPlayer soundPlayer)
  {
    let result = new("tt_SoundAnswerReporter");
    result._soundPlayer = soundPlayer;
    return result;
  }

  override void reportMatch()
  {
    _soundPlayer.playSound("tt/match");
  }

  override void reportNotMatch()
  {
    _soundPlayer.playSound("tt/not-match");
  }

  private tt_SoundPlayer _soundPlayer;
}

// Interface for reporting key press events.
class tt_KeyPressReporter abstract
{
  abstract void report();
}

// Implements tt_KeyPressReporter by playing a sound.
// The sound won't play if it's disabled in settings.
class tt_SoundKeyPressReporter : tt_KeyPressReporter
{
  static tt_SoundKeyPressReporter of(tt_SoundPlayer soundPlayer,
                                     tt_BoolSetting isEnabledSetting)
  {
    let result = new("tt_SoundKeyPressReporter");
    result._soundPlayer      = soundPlayer;
    result._isEnabledSetting = isEnabledSetting;
    return result;
  }

  override void report()
  {
    if (_isEnabledSetting.get()) _soundPlayer.playSound("tt/click");
  }

  private tt_SoundPlayer _soundPlayer;
  private tt_BoolSetting _isEnabledSetting;
}

// Interface for reporting mode change events.
class tt_ModeReporter abstract
{
  abstract void report(int mode);
}

// Implements tt_ModeReporter by playing the corresponding sound for each mode.
class tt_SoundModeReporter : tt_ModeReporter
{
  static tt_SoundModeReporter of(tt_SoundPlayer soundPlayer)
  {
    let result = new("tt_SoundModeReporter");
    result._soundPlayer = soundPlayer;
    return result;
  }

  override void report(int mode)
  {
    switch (mode)
    {
    case tt_Mode.Unknown:
      Console.printf("%s: report: unknown mode!", getClassName());
      break;
    case tt_Mode.Combat:  _soundPlayer.playSound("tt/combat");  break;
    case tt_Mode.Explore: _soundPlayer.playSound("tt/explore"); break;
    case tt_Mode.None:    break;
    }
  }

  private tt_SoundPlayer _soundPlayer;
}

// This is an interface for playing sounds.
class tt_SoundPlayer abstract
{
  abstract void playSound(String soundId);
}

// Implements tt_SoundPlayer by playing sounds for a player.
// The sounds won't play if they are disabled in settings.
class tt_PlayerSoundPlayer : tt_SoundPlayer
{
  static tt_PlayerSoundPlayer of(tt_PlayerSource playerSource,
                                 tt_BoolSetting  enabledSetting,
                                 tt_IntSetting   themeSetting)
  {
    let result = new("tt_PlayerSoundPlayer");
    result._playerSource = playerSource;
    result._enabledSetting = enabledSetting;
    result._themeSetting   = themeSetting;
    return result;
  }

  override void playSound(String soundId)
  {
    if (isDisabled()) return;

    let player = _playerSource.getPawn();
    int theme  = _themeSetting.get();
    soundId.appendFormat("%d", theme);

    player.a_StartSound(soundId, CHAN_AUTO, SOUND_FLAGS);
  }

  private bool isDisabled()
  {
    return (!_enabledSetting.get());
  }

  const SOUND_FLAGS = CHANF_UI | CHANF_OVERLAP | CHANF_LOCAL;

  private tt_PlayerSource _playerSource;
  private tt_BoolSetting  _enabledSetting;
  private tt_IntSetting   _themeSetting;
}
