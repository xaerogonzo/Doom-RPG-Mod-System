// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// Handles the game for one player.
class tt_PlayerHandler abstract
{
  abstract void reset(int playerNumber);

  abstract void processKey(tt_Character character);

  // Type is from InputEvent.EGenericEvent.
  abstract void processInput(int type);

  abstract void tick();

  abstract void reportDead(Actor dead);

  abstract bool isCapturingKeys();

  // Mode is from tt_Mode.
  abstract void setMode(int mode);

  // Mode is from tt_Mode.
  abstract int getMode() const;

  // Bypasses all lock logic — panic button for when the player is stuck.
  abstract void triggerEmergencyExit();

  // Returns the LOS-confirmed visible target source so the server can feed
  // it to tt_EnemySpeedController, preventing premature enemy slow-down.
  abstract tt_KnownTargetSource getVisibleTargetSource();

  ui abstract void draw(RenderEvent event);
}

// Handles Typist.pk3 features for one player.
class tt_PlayerSupervisor : tt_PlayerHandler
{
  static tt_PlayerSupervisor of(int playerNumber)
  {
    let result = new("tt_PlayerSupervisor");
    result.reset(playerNumber);
    return result;
  }

  override void reset(int playerNumber)
  {
    let playerSource = tt_PlayerSourceImpl.of(playerNumber);
    let clock        = tt_TotalClock      .of();

    let soundPlayer = tt_PlayerSoundPlayer
      .of(playerSource,
          tt_BoolCvar.of(playerSource, "tt_sound_enabled"),
          tt_IntCvar.of(playerSource, "tt_sound_theme"));

    let answerReporter   = tt_SoundAnswerReporter  .of(soundPlayer);
    let modeReporter     = tt_SoundModeReporter    .of(soundPlayer);
    let isTypingEnabled  = tt_BoolCvar.of(playerSource, "tt_sound_typing_enabled");
    let keyPressReporter = tt_SoundKeyPressReporter.of(soundPlayer, isTypingEnabled);

    let manualModeSource = tt_SettableMode .of();
    let playerInput      = tt_PlayerInput  .of(manualModeSource, keyPressReporter);
    let deathReporter    = tt_DeathReporter.of();

    let originSource     = tt_PlayerOriginSource.of(playerSource);
    let targetRadar      = tt_TargetRadar       .of(originSource);
    let radarStaleMarker = tt_StaleMarkerImpl   .of(clock);
    let radarCacheDirty  = tt_TargetSourceCache .of(targetRadar, radarStaleMarker);
    let radarCache       = tt_TargetSourcePruner.of(radarCacheDirty);
    let lesson           = makeLesson(playerSource);

    let targetRegistry = makeTargetRegistry(radarCache, lesson, deathReporter, clock);

    let answerStateSource = tt_PressedAnswerState.of();

    let visibleTargetSource = tt_VisibleKnownTargetSource.of(targetRegistry,
                                                             playerSource);
    let pressMatcher = tt_QuestionAnswerMatcher
      .of(visibleTargetSource, playerInput, answerStateSource);

    let hastyMatcher = tt_HastyQuestionAnswerMatcher
      .of(visibleTargetSource, playerInput, answerReporter);

    let fastConfirmation   = tt_BoolCvar.of(playerSource, "tt_fast_confirmation");
    let targetOriginSource = tt_OriginSourceCache
      .of(tt_SelectableOriginSource.of(hastyMatcher, pressMatcher, fastConfirmation),
          tt_StaleMarkerImpl.of(clock));

    let projector      = tt_Projector           .of(visibleTargetSource, playerSource);
    let widgetRegistry = tt_TargetWidgetRegistry.of(projector);
    let widgetSorter   = tt_SorterByDistance    .of(widgetRegistry, originSource);

    let autoModeSource = tt_AutoModeSource.of(visibleTargetSource);
    let lockedCombat   = tt_LockedCombatModeSource.of(manualModeSource,
                                                       visibleTargetSource,
                                                       playerSource);
    Array<tt_ModeSource> modeSources = {
      tt_AutomapModeSource.of(),
      lockedCombat,         // overrides manual Explore if LOS targets exist
      manualModeSource,
      tt_DelayedCombatModeSource.of(clock, autoModeSource, radarCache),
      autoModeSource
    };

    let modeSource = tt_ReportedModeSource.of(modeReporter,
                                              tt_ModeCascade.of(modeSources));

    let inputManager = tt_PassThroughInputManager
      .of(tt_InputByModeManager.of(modeSource, playerInput));

    Array<tt_Activatable> commands = {
      tt_PassThrough.of(inputManager,
                        tt_StringCvar.of(playerSource, "tt_command_pass_through"))
    };

    let commandDispatcher = tt_CommandDispatcher.of(playerInput,
                                                    commands,
                                                    answerReporter,
                                                    answerStateSource,
                                                    fastConfirmation);

    let oldModeSource         = tt_SettableMode.of();
    let inputBlockAfterCombat = tt_InputBlockAfterCombat
      .of(playerInput, modeSource, oldModeSource);

    let scaleSetting = tt_PositiveIntCvar.of(playerSource, "tt_view_scale");
    let infoPanel = tt_InfoPanel.of(modeSource,
                                    playerInput,
                                    commandDispatcher,
                                    visibleTargetSource,
                                    scaleSetting);

    Array<tt_View> views = {
      tt_TargetOverlay.of(widgetSorter, playerInput, scaleSetting, modeSource),
      tt_Frame.of(modeSource),
      infoPanel
    };

    let targetSender = tt_TargetOriginSender.of(targetOriginSource);

    Array<tt_Effect> effects = {
      tt_Gunner.of(targetOriginSource, targetSender),
      tt_AnswerResetter.of(answerStateSource, playerInput),
      tt_MatchWatcher.of(answerStateSource, answerReporter, targetOriginSource)
    };

    Array<tt_KeyProcessor> keyProcessors = {inputBlockAfterCombat, answerStateSource};

    _keyProcessor       = tt_KeyProcessors.of(keyProcessors);
    _deathReporter      = deathReporter;
    _targetRegistry     = targetRegistry;
    _view               = tt_ConditionalView.of(tt_Views.of(views));
    _modeSource         = modeSource;
    _targetWidgetSource = projector;
    _commandDispatcher  = commandDispatcher;
    _manualModeSource   = manualModeSource;
    _inputManager       = inputManager;
    _oldModeSource      = oldModeSource;
    _inputBlockAfterCombat = inputBlockAfterCombat;
    _effects            = tt_Effects.of(effects);
    _lockedCombat       = lockedCombat;
    _visibleTargetSource = visibleTargetSource;
  }

  override void processKey(tt_Character character)
  {
    _keyProcessor.processKey(character);
  }

  override void processInput(int type)
  {
    _inputManager.processInput(type);
  }

  override void tick()
  {
    _commandDispatcher.activate();
    _inputManager.manageInput();

    _inputBlockAfterCombat.update();
    _oldModeSource.setMode(_modeSource.getMode());

    _effects.doEffect();
  }

  override void reportDead(Actor dead)
  {
    _deathReporter.reportDead(dead);
  }

  override bool isCapturingKeys()
  {
    return _inputManager.isCapturingKeys();
  }

  override void setMode(int mode)
  {
    _manualModeSource.setMode(mode);
  }

  // Bypasses all lock logic unconditionally. Called by tt_EventHandler
  // when the tt_emergency_exit console command fires.
  override void triggerEmergencyExit()
  {
    _lockedCombat.triggerEmergencyExit();
    _manualModeSource.setMode(tt_Mode.Explore);
  }

  override tt_KnownTargetSource getVisibleTargetSource()
  {
    return _visibleTargetSource;
  }

  override int getMode() const { return _modeSource.getMode(); }

  override void draw(RenderEvent event)
  {
    _view.draw(event);
  }

private static tt_Lesson makeLesson(tt_PlayerSource playerSource)
  {
    let randomLessonSettings = tt_RandomCharactersLessonSettingsImpl.of(playerSource);

    Array<tt_SwitchableLesson> lessons = {
      tt_SwitchableLesson.of(tt_BoolCvar.of(playerSource, "tt_is_random_enabled"),
                             tt_RandomCharactersLesson.of(randomLessonSettings)),
      tt_SwitchableLesson.of(tt_BoolCvar.of(playerSource, "tt_is_maths_enabled"),
                             tt_MathsLesson.of()),
      tt_SwitchableLesson.of(tt_BoolCvar.of(playerSource, "tt_is_english_enabled"),
                             tt_StringSet.of("tt_1000")),
      tt_SwitchableLesson.of(tt_BoolCvar.of(playerSource, "tt_is_custom_enabled"),
                             tt_StringSet.of("typist_custom_text"))
    };

    return tt_MixedLesson.of(lessons);
  }

  private static tt_KnownTargetSource makeTargetRegistry(
    tt_TargetSource   targetSource,
    tt_Lesson         lesson,
    tt_TargetSource   deathReporter,
    tt_Clock          clock)
  {
    let registry      = tt_TargetRegistry .of(targetSource, lesson, deathReporter);
    let staleMarker   = tt_StaleMarkerImpl.of(clock);
    let registryCache = tt_KnownTargetSourceCache.of(registry, staleMarker);

    return registryCache;
  }

  private tt_KeyProcessor       _keyProcessor;
  private tt_KnownTargetSource  _targetRegistry;
  private tt_DeathReporter      _deathReporter;
  private tt_View               _view;
  private tt_ModeSource         _modeSource;
  private tt_TargetWidgetSource _targetWidgetSource;
  private tt_CommandDispatcher  _commandDispatcher;
  private tt_ModeStorage        _manualModeSource;
  private tt_PassThroughInputManager _inputManager;
  private tt_SettableMode       _oldModeSource;
  private tt_InputBlockAfterCombat _inputBlockAfterCombat;
  private tt_Effect             _effects;
  private tt_LockedCombatModeSource _lockedCombat;
  private tt_KnownTargetSource  _visibleTargetSource;
}
