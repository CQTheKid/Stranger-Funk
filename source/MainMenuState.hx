package;

import Achievements;
import editors.MasterEditorMenu;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;

using StringTools;

#if desktop
import Discord.DiscordClient;
#end

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.5.1'; // This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;

	var storyButton:FlxSprite;
	var freeplayButton:FlxSprite;
	var gaunletButton:FlxSprite;
	var settingButton:FlxSprite;
	var creditsButton:FlxSprite;
	var fuckingHilariousButton:FlxSprite;

	var warningText:FlxText;
	var notScientificallyPossible:Float = 0;

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;
	var somethingSelected:Bool = false;

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement);
		FlxG.mouse.visible = true;
		FlxCamera.defaultCameras = [camGame];

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.scrollFactor.set(0, 0);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;

		storyButton = new FlxSprite(200).loadGraphic(Paths.image('mainmenu/story'));
		storyButton.screenCenter(Y);
		storyButton.y += 500;
		storyButton.setGraphicSize(Std.int(storyButton.height * 0.2));
		storyButton.updateHitbox();
		add(storyButton);

		freeplayButton = new FlxSprite(storyButton.x + 300, storyButton.y - 1).loadGraphic(Paths.image('mainmenu/freeplay'));
		freeplayButton.setGraphicSize(Std.int(freeplayButton.height * 0.2));
		freeplayButton.updateHitbox();
		add(freeplayButton);

		// if (FlxG.random.bool(0.1))
		//	gaunletButton = new FlxSprite(freeplayButton.x + 325, storyButton.y + 7).loadGraphic(Paths.image('mainmenu/guanlet'));
		// else
		gaunletButton = new FlxSprite(freeplayButton.x + 325, storyButton.y + 7).loadGraphic(Paths.image('mainmenu/gauntletlocked'));
		gaunletButton.setGraphicSize(Std.int(gaunletButton.height * 0.27));
		gaunletButton.updateHitbox();
		add(gaunletButton);

		settingButton = new FlxSprite(gaunletButton.x - 19, storyButton.y + 400).loadGraphic(Paths.image('mainmenu/settings'));
		settingButton.setGraphicSize(Std.int(settingButton.height * 0.57));
		settingButton.updateHitbox();
		add(settingButton);

		creditsButton = new FlxSprite(gaunletButton.x - 140, storyButton.y + 575).loadGraphic(Paths.image('mainmenu/Creditsbutton'));
		creditsButton.setGraphicSize(Std.int(creditsButton.width * 0.45));
		creditsButton.updateHitbox();
		add(creditsButton);

		fuckingHilariousButton = new FlxSprite(creditsButton.x - 490, creditsButton.y).loadGraphic(Paths.image('mainmenu/Tonybutton'));
		fuckingHilariousButton.setGraphicSize(Std.int(fuckingHilariousButton.width * 0.45));
		fuckingHilariousButton.updateHitbox();
		add(fuckingHilariousButton);

		warningText = new FlxText(0, 680, 0, "Use Your Mouse To Select The Menu Buttons!", 28);
		warningText.scrollFactor.set();
		warningText.setFormat("VCR OSD Mono", 28, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		warningText.screenCenter(X);
		add(warningText);

		// NG.core.calls.event.logEvent('swag').send();

		#if ACHIEVEMENTS_ALLOWED
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
		{
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if (!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2]))
			{ // It's a friday night. Piss off ya wanker!
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end

		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement()
	{
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new TitleState());
		}

		if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(storyButton) && !somethingSelected)
		{
			somethingSelected = true;
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
			FlxFlicker.flicker(storyButton, 1, 0.06, false, false, function(flick:FlxFlicker)
			{
				MusicBeatState.switchState(new StoryMenuState());
				somethingSelected = false;
			});
		}

		if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(freeplayButton) && !somethingSelected)
		{
			somethingSelected = true;
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
			FlxFlicker.flicker(freeplayButton, 1, 0.06, false, false, function(flick:FlxFlicker)
			{
				FlxG.mouse.visible = false;
				MusicBeatState.switchState(new FreeplayState());
				somethingSelected = false;
			});
		}

		if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(gaunletButton) && !somethingSelected)
		{
			// MusicBeatState.switchState(new StoryMenuState());
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.camera.shake(0.025);
		}

		if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(settingButton) && !somethingSelected)
		{
			somethingSelected = true;
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
			FlxFlicker.flicker(settingButton, 1, 0.06, false, false, function(flick:FlxFlicker)
			{
				FlxG.mouse.visible = false;
				LoadingState.loadAndSwitchState(new options.OptionsState());
				somethingSelected = false;
			});
		}

		if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(creditsButton) && !somethingSelected)
		{
			somethingSelected = true;
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
			FlxFlicker.flicker(creditsButton, 1, 0.06, false, false, function(flick:FlxFlicker)
			{
				FlxG.mouse.visible = false;
				MusicBeatState.switchState(new CreditsState());
				somethingSelected = false;
			});
		}

		if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(fuckingHilariousButton) && !somethingSelected)
		{
			somethingSelected = true;
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
			FlxFlicker.flicker(fuckingHilariousButton, 1, 0.06, false, false, function(flick:FlxFlicker)
			{
				FlxG.sound.play(Paths.sound('gauntletWarning'));
				FlxG.camera.shake(0.025);
				somethingSelected = false;
			});
		}

		#if desktop
		else if (FlxG.keys.anyJustPressed(debugKeys))
		{
			MusicBeatState.switchState(new MasterEditorMenu());
		}
		#end

		super.update(elapsed);

		notScientificallyPossible += 180 * elapsed;
		warningText.alpha = 1 - Math.sin((Math.PI * notScientificallyPossible) / 180);
	}
}
