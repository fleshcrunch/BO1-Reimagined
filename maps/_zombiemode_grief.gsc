#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;

init()
{
	if(level.gamemode == "survival")
	{
		return;
	}

	grief_precache();

	level thread include_powerups();

	level thread post_all_players_connected();

	level thread turn_power_on();

	level thread open_doors();

	level thread disable_special_rounds();

	level thread disable_box_weapons();
}

grief_precache()
{
	PrecacheString( &"REIMAGINED_YOU_WIN" );
	PrecacheString( &"REIMAGINED_YOU_LOSE" );

	PrecacheString( &"REIMAGINED_ANOTHER_CHANCE" );
	PrecacheString( &"REIMAGINED_ENEMY_DOWN" );
	PrecacheString( &"REIMAGINED_ALL_ENEMIES_DOWN" );
	PrecacheString( &"REIMAGINED_SURVIVE_TO_WIN" );

	level._effect["grief_shock"] = LoadFX("grief/fx_grief_shock");

	PrecacheShader("waypoint_cia");
	PrecacheShader("waypoint_cdc");

	precacheModel("bo2_c_zom_hazmat_viewhands");
	precacheModel("bo2_c_zom_player_cdc_fb");
	precacheModel("bo2_c_zom_suit_viewhands");
	precacheModel("bo2_c_zom_player_cia_fb");
}

include_powerups()
{
	include_powerup("grief_empty_clip");
	include_powerup("grief_lose_points");
	include_powerup("grief_half_points");
	include_powerup("grief_half_damage");
	include_powerup("grief_slow_down");
	include_powerup("meat");
	wait_network_frame();
	level.zombie_powerup_array = [];
	level.zombie_powerup_array = array("fire_sale", "grief_empty_clip", "grief_lose_points", "grief_half_points", "grief_half_damage", "grief_slow_down", "meat");
	maps\_zombiemode_powerups::randomize_powerups();
}

post_all_players_connected()
{
	flag_wait("all_players_connected");

	setup_grief_teams();

	setup_grief_logo();

	players = get_players();
	for(i=0;i<players.size;i++)
	{
		players[i] setup_grief_msg();

		players[i] thread take_tac_nades_when_used();

		if(level.gamemode == "ffa")
		{
			players[i] thread instant_bleedouts();
		}
	}
}

instant_bleedouts()
{
	self endon( "disconnect" );

	while(1)
	{
		self waittill("player_downed");
		self.bleedout_time = 0;
	}
}

is_team_valid()
{
	players = get_players();
	for(i=0;i<players.size;i++)
	{
		if(players[i].vsteam == self.vsteam && is_player_valid(players[i]))
		{
			return true;
		}
	}
	return false;
}

setup_grief_teams()
{
	players = get_players();
	array = array("cdc", "cia");
	array = array_randomize(array);
	for(i=0;i<players.size;i++)
	{
		if(level.gamemode == "ffa" || level.gamemode == "gg" || level.gamemode == "turned")
		{
			if(!IsDefined(level.vsteam))
			{
				level.vsteam = random(array);
			}
			players[i].vsteam = "ffa" + (i + 1);
		}
		else
		{
			if(i / players.size < .5)
			{
				players[i].vsteam = array[0];
			}
			else
			{
				players[i].vsteam = array[1];
			}
		}
	}
}

setup_grief_logo()
{
	players = get_players();
	for(i=0;i<players.size;i++)
	{
		if(IsDefined(level.vsteam))
		{
			players[i] SetClientDvar("vs_logo", level.vsteam + "_logo");
		}
		else
		{
			players[i] SetClientDvar("vs_logo", players[i].vsteam + "_logo");
		}
		players[i] SetClientDvar("vs_logo_on", 1);
	}
}

disable_special_rounds()
{
	if(level.script == "zombie_cod5_sumpf" || level.script == "zombie_cod5_factory" || level.script == "zombie_theater")
	{
		level thread disable_dog_rounds();
	}
	else if(level.script == "zombie_pentagon")
	{
		level thread disable_thief_rounds();
	}
	else if(level.script == "zombie_cosmodrome")
	{
		level thread disable_monkey_rounds();
	}
}

disable_dog_rounds()
{
	flag_wait( "all_players_connected" );
	level.next_dog_round = 0;
}

disable_thief_rounds()
{
	flag_wait( "power_on" );
	wait_network_frame();
	level.prev_thief_round = 0;
	level.next_thief_round = 999;
}

disable_monkey_rounds()
{
	flag_wait( "perk_bought" );
	wait_network_frame();
	level.next_monkey_round = 0;
}

disable_character_dialog()
{
	while(1)
	{
		level.player_is_speaking = 1;
		level.cosmann_is_speaking = 1;
		wait .1;
	}
}

store_player_weapons()
{
	self.weaponInventory = self GetWeaponsList();

	self.lastActiveStoredWeap = self GetCurrentWeapon();
	if(self.lastActiveStoredWeap == "microwavegun_zm")
	{
		self.lastActiveStoredWeap = "microwavegundw_zm";
	}
	self SetLastStandPrevWeap( self.lastActiveStoredWeap );

	self.melee = self get_player_melee_weapon();
	self.lethal = self get_player_lethal_grenade();
	self.tac = self get_player_tactical_grenade();
	self.mine = self get_player_placeable_mine();
	
	self.hadpistol = false;
	for( i = 0; i < self.weaponInventory.size; i++ )
	{
		weapon = self.weaponInventory[i];
		
		switch( weapon )
		{
			
		case "syrette_sp": 
		
		case "zombie_perk_bottle_doubletap": 
		case "zombie_perk_bottle_revive":
		case "zombie_perk_bottle_jugg":
		case "zombie_perk_bottle_sleight":
		case "zombie_perk_bottle_marathon":
		case "zombie_perk_bottle_nuke":
		case "zombie_perk_bottle_deadshot":
		case "zombie_perk_bottle_additionalprimaryweapon":

		case "zombie_knuckle_crack":

		case "zombie_bowie_flourish":
		case "zombie_sickle_flourish":
			self TakeWeapon( weapon );
			self.lastActiveStoredWeap = "none";
			continue;
		}

		self.weaponAmmo[weapon]["clip"] = self GetWeaponAmmoClip( weapon );
		self.weaponAmmo[weapon]["stock"] = self GetWeaponAmmoStock( weapon );

		self.weaponAmmo[weapon]["clip_dual_wield"] = undefined;
		dual_wield_name = WeaponDualWieldWeaponName( weapon );
		if ( dual_wield_name != "none" )
		{
			self.weaponAmmo[dual_wield_name]["clip"] = self GetWeaponAmmoClip( dual_wield_name );
		}

		//dont store the weapon attachment name as the last active weapon or can't switch to it
		wep_prefix = GetSubStr(weapon, 0, 3);
		alt_wep = WeaponAltWeaponName(weapon);
		if(alt_wep != "none" && (wep_prefix == "gl_" || wep_prefix == "mk_" || wep_prefix == "ft_"))
		{
			self.lastActiveStoredWeap = alt_wep;
		}
	}
}

giveback_player_weapons()
{	
	for( i = 0; i < self.weaponInventory.size; i++ )
	{
		weapon = self.weaponInventory[i];

		switch( weapon )
		{
		// this player was killed while reviving another player
		case "syrette_sp": 

		case "zombie_perk_bottle_doubletap": 
		case "zombie_perk_bottle_revive":
		case "zombie_perk_bottle_jugg":
		case "zombie_perk_bottle_sleight":
		case "zombie_perk_bottle_marathon":
		case "zombie_perk_bottle_nuke":
		case "zombie_perk_bottle_deadshot":
		case "zombie_perk_bottle_additionalprimaryweapon":

		case "zombie_knuckle_crack":

		case "zombie_bowie_flourish":
		case "zombie_sickle_flourish":
			continue;
		}

		if ( !maps\_zombiemode_weapons::is_weapon_upgraded( weapon ) )
		{
			self GiveWeapon( weapon );
		}
		else
		{
			self GiveWeapon( weapon, 0, self maps\_zombiemode_weapons::get_pack_a_punch_weapon_options( weapon ) );
		}
		self SetWeaponAmmoClip( weapon, self.weaponAmmo[weapon]["clip"] );

		if ( WeaponType( weapon ) != "grenade" )
		{
			self SetWeaponAmmoStock( weapon, self.weaponAmmo[weapon]["stock"] );

			dual_wield_name = WeaponDualWieldWeaponName( weapon );
			if ( dual_wield_name != "none" && IsDefined(self.weaponAmmo[dual_wield_name]["clip"]) )
			{
				self SetWeaponAmmoClip( dual_wield_name, self.weaponAmmo[dual_wield_name]["clip"] );
			}
		}
	}

	self set_player_melee_weapon(self.melee);
	self thread maps\_zombiemode::set_melee_actionslot();
	
	self set_player_lethal_grenade(self.lethal);

	if(IsDefined(self.tac))
	{
		self set_player_tactical_grenade(self.tac);
	}

	if(IsDefined(self.mine))
	{
		self giveweapon(self.mine);
		self set_player_placeable_mine(self.mine);
		self setactionslot(4,"weapon",self.mine);
		self setweaponammoclip(self.mine,2);
	}

	if( self.lastActiveStoredWeap != "none" && self.lastActiveStoredWeap != "mine_bouncing_betty" && self.lastActiveStoredWeap != "claymore_zm" && self.lastActiveStoredWeap != "spikemore_zm" 
		&& self.lastActiveStoredWeap != "combat_knife_zm" && self.lastActiveStoredWeap != "combat_bowie_knife_zm" && self.lastActiveStoredWeap != "combat_sickle_knife_zm" )
	{
		self SwitchToWeapon( self.lastActiveStoredWeap );
	}
	else
	{
		primaryWeapons = self GetWeaponsListPrimaries();
		if( IsDefined( primaryWeapons ) && primaryWeapons.size > 0 )
		{
			self SwitchToWeapon( primaryWeapons[0] );
		}
		else
		{
			self thread switch_to_combat_knife();
		}
	}
}

switch_to_combat_knife()
{
	wait_network_frame();

	melee = self get_player_melee_weapon();
	if(IsDefined(melee))
	{
		wep = "combat_" + melee;
		self SwitchToWeapon(wep);
	}
}

grief(eAttacker, sMeansOfDeath, sWeapon, iDamage, eInflictor, sHitLoc)
{
	if(sWeapon == "mine_bouncing_betty" && self getstance() == "prone" && sMeansOfDeath == "MOD_GRENADE_SPLASH")
		return;

	//only nades, mines, flops, and scavenger do actual damage
	//TODO - add molotov damage
	if(!self HasPerk( "specialty_flakjacket" ))
	{
		//80 DoDamage = 25 actual damage
		if(sMeansOfDeath == "MOD_GRENADE_SPLASH" && (sWeapon == "frag_grenade_zm" || sWeapon == "sticky_grenade_zm" || sWeapon == "stielhandgranate"))
		{
			//nades
			//if(self.health > 25)
			self DoDamage( 80, eInflictor.origin );
			//else
			//	radiusdamage(self.origin,10,self.health + 100,self.health + 100);
		}
		else if( eAttacker HasPerk( "specialty_flakjacket" ) && isdefined( eAttacker.divetoprone ) && eAttacker.divetoprone == 1 && sMeansOfDeath == "MOD_GRENADE_SPLASH" )
		{
			//flops
			self DoDamage( 80, eAttacker.origin );//for flops, the origin of the player must be used
		}
		else if((sMeansOfDeath == "MOD_GRENADE_SPLASH" && (is_placeable_mine( sWeapon ) || is_tactical_grenade( sWeapon ) || sWeapon == "sniper_explosive_zm" || sWeapon == "sniper_explosive_zm")))
		{
			//claymores, spikemores, betties, dolls, and scavenger
			self DoDamage( 80, eInflictor.origin );
		}
	}

	self thread slowdown(sWeapon, sMeansOfDeath, eAttacker, sHitLoc);

	if(sMeansOfDeath == "MOD_MELEE" 
		|| sWeapon == "knife_ballistic_zm" || sWeapon == "knife_ballistic_upgraded_zm" || sWeapon == "knife_ballistic_bowie_zm" || sWeapon == "knife_ballistic_bowie_upgraded_zm")
	{
		self thread push(eAttacker, sWeapon, sMeansOfDeath);
	}
}

slowdown(weapon, mod, eAttacker, loc)
{
	if(!IsDefined(self.slowdown_wait))
	{
		self.slowdown_wait = false;
	}

	if(weapon == "mine_bouncing_betty" && self getstance() == "prone")
		return;

	eAttacker thread grief_damage_points(self);

	//player is already slowed down, don't slow them down again
	if(self.slowdown_wait)
	{
		return;
	}

	self.slowdown_wait = true;

	eAttacker thread grief_downed_points(self);

	PlayFXOnTag( level._effect["grief_shock"], self, "back_mid" );
	self AllowSprint(false);
	self setblur( 1, .1 );

	if(maps\_zombiemode_weapons::is_weapon_upgraded(weapon) || is_placeable_mine(weapon) || is_tactical_grenade(weapon) || weapon == "sniper_explosive_zm" || ( eAttacker HasPerk( "specialty_flakjacket" ) && eAttacker.divetoprone == 1 && mod == "MOD_GRENADE_SPLASH"))
	{
		self setMoveSpeedScale( self.move_speed * .2 );	
	}
	else
	{
		self setMoveSpeedScale( self.move_speed * .3 );
	}

	wait( .75 );//.75 * 1.5 = 1.125

	self setMoveSpeedScale( 1 );
	if(!self.is_drinking)
		self AllowSprint(true);
	self setblur( 0, .2 );

	self.slowdown_wait = false;
}

push(eAttacker, sWeapon, sMeansOfDeath) //prone, bowie/ballistic crouch, bowie/ballistic, crouch, regular
{
	if(self.push_wait == false)
	{
		amount = 0;
		self.push_wait = true;
		if( self GetStance() == "prone" )
		{
			wait .75;
			self.push_wait = false;
			return;
		}
		else if(eAttacker._bowie_zm_equipped || eAttacker._sickle_zm_equipped || sWeapon == "knife_ballistic_zm" || sWeapon == "knife_ballistic_upgraded_zm")
		{
			if(self GetStance() == "crouch")
			{
				amount = 150;
			}
			else
			{
				amount = 450;
			}
		}
		else
		{
			if(self GetStance() == "crouch")
			{
				amount = 100;
			}
			else
			{
				amount = 300;	
			}
		}
		self SetVelocity( VectorNormalize( self.origin - eAttacker.origin ) * (amount, amount, amount) );
		wait .75;
		self.push_wait = false;
	}
}

grief_damage_points(gotgriefed)
{
	if(gotgriefed.health < gotgriefed.maxhealth && is_player_valid(self))
	{
		points = int(10 * self.zombie_vars["zombie_point_scalar"]);
		self maps\_zombiemode_score::add_to_player_score( points );
	}
}

grief_downed_points(gotgriefed)
{
	//self notify("monitor downed points");
	//self endon("monitor downed points");
	gotgriefed endon( "player_downed" );

	if(!IsDefined(gotgriefed.vs_attackers))
	{
		gotgriefed.vs_attackers = [];
	}

	if(is_in_array(gotgriefed.vs_attackers, self))
	{
		return;
	}

	gotgriefed.vs_attackers = array_add(gotgriefed.vs_attackers, self);

	while(gotgriefed.health < gotgriefed.maxhealth || gotgriefed.slowdown_wait)
	{
		wait_network_frame();
	}

	gotgriefed.vs_attackers = array_remove_nokeys(gotgriefed.vs_attackers, self);

	/*while(gotgriefed.health < gotgriefed.maxhealth)
	{
		if(!is_player_valid(gotgriefed))
		{
			if(is_player_valid(self))
			{
				points = round_up_to_ten(int(gotgriefed.score * .05));
				self maps\_zombiemode_score::add_to_player_score( points );
			}
			return;
		}

		wait_network_frame();
	}*/

	/*if(!is_player_valid(gotgriefed) && is_player_valid(self))
	{
		points = round_up_to_ten(int(gotgriefed.score * .05));
		self maps\_zombiemode_score::add_to_player_score( points );
	}*/
}

grief_bleedout_points(dead_player)
{
	players = get_players();
	for( i = 0; i < players.size; i++ )
	{
		if(is_player_valid(players[i]) && players[i].vsteam != dead_player.vsteam)
		{
			points = round_up_to_ten(int(players[i].score * .1));
			players[i] maps\_zombiemode_score::add_to_player_score( points );
		}
		/*else if(is_player_valid(players[i]) && players[i].vsteam == dead_player.vsteam)
		{
			points = round_up_to_ten(int(players[i].score * .1));
			players[i] maps\_zombiemode_score::minus_to_player_score( points );
		}*/
	}
}

setup_grief_msg()
{
	self.grief_hud1 = NewClientHudElem( self );
	self.grief_hud1.alignX = "center";
	self.grief_hud1.alignY = "middle";
	self.grief_hud1.horzAlign = "center";
	self.grief_hud1.vertAlign = "middle";
	self.grief_hud1.y -= 100;
	self.grief_hud1.foreground = true;
	self.grief_hud1.fontScale = 2;
	self.grief_hud1.alpha = 0;
	self.grief_hud1.color = ( 1.0, 1.0, 1.0 );

	self.grief_hud2 = NewClientHudElem( self );
	self.grief_hud2.alignX = "center";
	self.grief_hud2.alignY = "middle";
	self.grief_hud2.horzAlign = "center";
	self.grief_hud2.vertAlign = "middle";
	self.grief_hud2.y -= 75;
	self.grief_hud2.foreground = true;
	self.grief_hud2.fontScale = 2;
	self.grief_hud2.alpha = 0;
	self.grief_hud2.color = ( 1.0, 1.0, 1.0 );
}

grief_msg()
{
	self notify("grief_msg");
	self endon("grief_msg");

	players_alive = get_number_of_valid_players();
	enemies_alive = self get_number_of_valid_enemy_players();
	if(!is_player_valid(self))
		enemies_alive -= 1;

	self.grief_hud1.alpha = 0;
	self.grief_hud2.alpha = 0;

	if(flag("round_restarting"))
	{
		self.grief_hud1 SetText( &"REIMAGINED_ANOTHER_CHANCE" );
		self.grief_hud1 FadeOverTime( 1 );
		self.grief_hud1.alpha = 1;
		self thread grief_msg_fade_away(self.grief_hud1);
	}
	else if (enemies_alive >= 1)
	{
		self.grief_hud1 SetText( &"REIMAGINED_ENEMY_DOWN", enemies_alive );
		self.grief_hud1 FadeOverTime( 1 );
		self.grief_hud1.alpha = 1;
		self thread grief_msg_fade_away(self.grief_hud1);
	}
	else if (enemies_alive == 0 && players_alive >= 1)
	{
		self.grief_hud1 SetText( &"REIMAGINED_ALL_ENEMIES_DOWN" );
		self.grief_hud1 FadeOverTime( 1 );
		self.grief_hud1.alpha = 1;
		self thread grief_msg_fade_away(self.grief_hud1);
		wait(2.5);
		self.grief_hud2 SetText( &"REIMAGINED_SURVIVE_TO_WIN" );
		self.grief_hud2 FadeOverTime( 1 );
		self.grief_hud2.alpha = 1;
		self thread grief_msg_fade_away(self.grief_hud2);
	}	
}

grief_msg_fade_away(text)
{
	self endon("grief_msg");

	wait( 3.0 );

	text FadeOverTime( 1 );
	text.alpha = 0;
	//text delete();
}

round_restart(same_round)
{
	flag_set("round_restarting");
	flag_clear( "spawn_zombies");

	//let player who just downed get last stand stuff initialized first
	wait_network_frame();
	level notify( "round_restarted" );

	players = get_players();
	for(i=0;i<players.size;i++)
	{
		players[i].bleedout_time = 0;
	}

	wait(1);

	zombs = getaispeciesarray("axis");
	for(i=0;i<zombs.size;i++)
	{
		if(zombs[i].animname == "zombie" || zombs[i].animname == "zombie_dog" || zombs[i].animname == "quad_zombie")
			zombs[i] DoDamage( zombs[i].health + 2000, (0,0,0) );
	}

	maps\_zombiemode::ai_calculate_amount(); //reset the amount of zombies in a round

	level.powerup_drop_count = 0; //restarts the amount of powerups you can earn this round

	if( !IsDefined( level.custom_spawnPlayer ) )
	{
		// Custom spawn call for when they respawn from spectator
		level.custom_spawnPlayer = maps\_zombiemode::spectator_respawn;
	}
	players = get_players();
	for(i=0;i<players.size;i++)
	{
		players[i] [[level.spawnPlayer]]();
	}

	wait_network_frame();//needed for stored weapons to work correctly and round_restarting flag was being cleared too soon

	for(i=0;i<players.size;i++)
	{
		players[i] notify( "round_restarted" );
		players[i].rebuild_barrier_reward = 0;
		players[i] DoDamage( 0, (0,0,0) );//fix for health not being correct
		players[i] TakeAllWeapons();
		players[i] giveback_player_weapons();
		players[i].is_drinking = false;
		players[i] SetStance("stand");

		if(level.gamemode != "snr")
			players[i] thread grief_msg();

		if(level.gamemode == "snr")
		{
			if(players[i].score < 5000)
			{
				players[i].score = 5000;
				players[i] maps\_zombiemode_score::set_player_score_hud();
			}
		}
	}

	level thread maps\_zombiemode::award_grenades_for_survivors(); //get 2 extra grenades when you spawn back in

	/*if(level.script == "zombie_pentagon")
		level thread maps\zombie_pentagon_amb::play_pentagon_announcer_vox( "zmb_vox_pentann_defcon_reset" );
	else
		level thread play_sound_2d( "sam_nospawn" );*/

	if(level.gamemode == "snr")
	{
		if(!isdefined(same_round))
			level.snr_round++;
		chalk_one_up_snr();
	}

	flag_set( "spawn_zombies");
	flag_clear("round_restarting");
}

set_grief_viewmodel()
{
	if(IsDefined(level.vsteam))
	{
		if(level.vsteam == "cdc")
		{
			self SetViewModel("bo2_c_zom_hazmat_viewhands");
		}
		else if(level.vsteam == "cia")
		{
			self SetViewModel("bo2_c_zom_suit_viewhands");
		}
	}
	else
	{
		if(self.vsteam == "cdc")
		{
			self SetViewModel("bo2_c_zom_hazmat_viewhands");
		}
		else if(self.vsteam == "cia")
		{
			self SetViewModel("bo2_c_zom_suit_viewhands");
		}
	}
}

set_grief_model()
{
	self DetachAll();
	if(IsDefined(level.vsteam))
	{
		if(level.vsteam == "cdc")
		{
			self setModel("bo2_c_zom_player_cdc_fb");
		}
		else if(level.vsteam == "cia")
		{
			self setModel( "bo2_c_zom_player_cia_fb" );
		}
	}
	else
	{
		if(self.vsteam == "cdc")
		{
			self setModel("bo2_c_zom_player_cdc_fb");
		}
		else if(self.vsteam == "cia")
		{
			self setModel( "bo2_c_zom_player_cia_fb" );
		}
	}
	self.voice = "american";
	self.skeleton = "base";
}

stop_shellshock_when_spectating()
{
	while(1)
	{
		if(!is_player_valid(self))
		{
			self StopShellShock();
			break;
		}
		wait(.05);
	}
}

player_weapons_watcher()//gives player m1911 if they have no weapons; takes away m1911 if they have upgraded m1911; takes away additional weapons
{
	self endon( "disconnect" );
	while ( 1 )
	{
		if(is_player_valid(self) && !self.is_drinking && !level.round_restart && !self HasWeapon("syrette_sp"))
		{
			if(self GetCurrentWeapon() == "knife_zm" || self GetCurrentWeapon() == "bowie_knife_zm" || self GetCurrentWeapon() == "sickle_knife_zm" || self GetCurrentWeapon() == "stielhandgranate" || self GetCurrentWeapon() == "frag_grenade_zm")
			{
				self GiveWeapon("m1911_zm");
				self SwitchToWeapon("m1911_zm");
			}
			else if(self HasWeapon("m1911_zm") && self HasWeapon("m1911_upgraded_zm"))
			{
				self TakeWeapon("m1911_zm");
				self SwitchToWeapon("m1911_upgraded_zm");
			}
			weapon_limit = 2;
			if ( self HasPerk( "specialty_additionalprimaryweapon" ) )
			{
				weapon_limit = 3;
			}
			primaryWeapons = self GetWeaponsListPrimaries();
			if(primaryWeapons.size > weapon_limit && self HasWeapon("m1911_zm"))
			{
				self TakeWeapon("m1911_zm");
				self SwitchToWeapon(primaryWeapons[0]);
			}
		}
		wait .05;
	}
}

take_tac_nades_when_used()
{
	self endon( "disconnect" );
	//self endon( "death" );
	while(1)
	{
		tac_nade = self get_player_tactical_grenade();
		if(IsDefined(tac_nade) && self GetFractionMaxAmmo(tac_nade) == 0)
		{
			self TakeWeapon(tac_nade);
		}
		wait .05;
	}
}

//disable certain box weapons
disable_box_weapons()
{
	//wait for guns to be registered
	wait_network_frame();

	if(IsDefined(level.zombie_weapons["zombie_cymbal_monkey"]))
		level.zombie_weapons["zombie_cymbal_monkey"].is_in_box = false;

	if(IsDefined(level.zombie_weapons["crossbow_explosive_zm"]))
		level.zombie_weapons["crossbow_explosive_zm"].is_in_box = false;

	if(IsDefined(level.zombie_weapons["zombie_black_hole_bomb"]))
		level.zombie_weapons["zombie_black_hole_bomb"].is_in_box = false;
}

turn_power_on()
{
	flag_wait( "all_players_spawned" );
	switch(level.script)
	{
		case "zombie_theater":
		case "zombie_pentagon":
		case "zombie_cosmodrome":
		case "zombie_coast":
			trig = getent("use_elec_switch","targetname");
			trig notify("trigger");	
			break;
		case "zombie_temple":
			left_power_switch_model = getEnt("elec_switch_left", "targetname");
			right_power_switch_model = getEnt("elec_switch_right", "targetname");	
			left_power_switch_model notsolid();
			left_power_switch_model rotateroll(-90);
			right_power_switch_model notsolid();
			right_power_switch_model rotateroll(-90);
			trig1 = getEnt( "power_trigger_left", "targetname" );
			trig2 = getEnt( "power_trigger_right", "targetname" );
			trig1 setHintString( "" );
			trig2 setHintString( "" );
			flag_set("power_on");
			break;
		case "zombie_moon":
			flag_wait( "all_players_spawned" );
			wait 5;
			trig = getent("use_elec_switch","targetname");
			trig notify("trigger");	
			break;
		case "zombie_cod5_asylum":
			trig = getent("use_master_switch","targetname");
			trig notify("trigger");
			break;
		case "zombie_cod5_factory":
			wait 1;//have to wait for bridge to go up first
			trig = getent("use_power_switch","targetname");
			trig notify("trigger");
			break;
	}
}

open_doors()
{
	flag_wait( "all_players_connected" );
	zombie_doors = GetEntArray( "zombie_door", "targetname" );
	zombie_debris = GetEntArray( "zombie_debris", "targetname" );
	if(level.script == "zombie_cod5_prototype")
	{
		zombie_doors[0] open_door();
		zombie_debris[0] clear_debris();
		zombie_debris[1] clear_debris();
		zombie_debris[2] clear_debris();
	}
	if(level.script == "zombie_cod5_asylum")
	{
		zombie_doors[1] open_door();
	}
	if(level.script == "zombie_cod5_sumpf")
	{
		zombie_doors[4] open_door();
		zombie_debris[0] clear_debris();
		zombie_debris[1] clear_debris();
	}
	if(level.script == "zombie_cod5_factory")
	{
		zombie_doors[2] open_door();
		zombie_doors[3] open_door();
	}
	if(level.script == "zombie_pentagon")
	{
		zombie_doors[0] open_door();
		zombie_doors[1] open_door();
		zombie_doors[0] delete();
		zombie_doors[1] delete();
		zombie_debris[0] clear_debris();
	}
	if(level.script == "zombie_cosmodrome")
	{
		zombie_doors[0] open_door();
		zombie_doors[2] open_door();
		zombie_doors[4] open_door();
		zombie_doors[8] open_door();
	}
}

open_door()
{
	self._door_open = true;
	self notify("door_opened");
	self maps\_zombiemode_blockers::door_opened();
}

clear_debris()
{
	tokens = Strtok( self.script_flag, "," );
	for ( i=0; i<tokens.size; i++ )
	{
		flag_set( tokens[i] );
	}
	junk = getentarray( self.target, "targetname" );
	for ( k = 0; k < junk.size; k++ )
	{
		junk[k] trigger_off();
		junk[k] connectpaths();
		junk[k] delete();
	}
	self delete();
	level notify ("junk purchased");
}

remove_ee_songs()
{
	switch(level.script)
	{
		case "zombie_cod5_prototype":
			song = getentarray("evt_egg_killme", "targetname");
			for(i=0;i<song.size;i++)
			{
				song[i] delete();
			}
			break;
		case "zombie_cod5_asylum":
		case "zombie_cod5_sumpf":
			song = getent("toilet", "targetname");
			song disable_trigger();
			break;
		case "zombie_cod5_factory":
			song1 = getent("meteor_one", "targetname");
			song2 = getent("meteor_two", "targetname");
			song3 = getent("meteor_three", "targetname");
			song1 disable_trigger();
			song2 disable_trigger();
			song3 disable_trigger();
			break;
		case "zombie_theater":
			song = GetEntArray( "meteor_egg_trigger", "targetname" );
			for(i=0;i<song.size;i++)
			{
				song[i] delete();
			}
			break;
		case "zombie_pentagon":
			level.phone_counter = -1;
			break;
		case "zombie_cosmodrome":
			song = GetEntArray( "mus_teddybear", "targetname" );
			for(i=0;i<song.size;i++)
			{
				song[i] delete();
			}
			break;
		case "zombie_coast":
		case "zombie_temple":
		case "zombie_moon":
			level.meteor_counter = -1;
			break;
	}
}

get_number_of_valid_enemy_players()
{
	players = get_players();
	num_player_valid = 0;
	for( i = 0 ; i < players.size; i++ )
	{
		if( is_player_valid(players[i]) && players[i].vsteam != self.vsteam )
			num_player_valid += 1;
	}	
	return num_player_valid;
}

get_number_of_valid_friendly_players()
{
	players = get_players();
	num_player_valid = 0;
	for( i = 0 ; i < players.size; i++ )
	{
		if( is_player_valid(players[i]) && players[i].vsteam == self.vsteam )
			num_player_valid += 1;
	}	
	return num_player_valid;
}

enable_mixed_rounds()
{
	level.mixed_rounds_enabled = true;
}

unlimited_powerups()
{
	while(1)
	{
		level.powerup_drop_count = 0;
		wait 1;
	}
}

unlimited_barrier_points()
{
	flag_wait( "all_players_connected" );
	players = get_players();
	while(1)
	{
		for(i=0;i<players.size;i++)
		{
			players[i].rebuild_barrier_reward = 0;
		}
		wait 1;
	}
}

increase_round_number()
{
	wait 1;
	level.round_number = 20;
}

increase_zombie_health()
{
	wait 1;
	while(1)
	{
		level.zombie_health = 2000;
		wait 1;
	}
}

unlimited_zombies()
{
	wait 1;
	while(1)
	{
		level.zombie_total = 100;
		wait 1;
	}
}

increase_zombie_move_speed()
{
	wait 1;
	level.zombie_move_speed = 90;
}

increase_zombie_spawn_rate()
{
	wait 1;
	level.zombie_vars["zombie_spawn_delay"] = .5;
}

chalk_one_up_snr()
{
	huds = [];
	huds[0] = level.chalk_hud1;
	huds[1] = level.chalk_hud2;

	// Hud1 shader
	if( level.snr_round >= 1 && level.snr_round <= 5 )
	{
		huds[0] SetShader( "hud_chalk_" + level.snr_round, 64, 64 );
	}
	else if ( level.snr_round >= 5 && level.snr_round <= 10 )
	{
		huds[0] SetShader( "hud_chalk_5", 64, 64 );
	}

	// Hud2 shader
	if( level.snr_round > 5 && level.snr_round <= 10 )
	{
		huds[1] SetShader( "hud_chalk_" + ( level.snr_round - 5 ), 64, 64 );
	}

	// Display value
	if ( IsDefined( level.chalk_override ) )
	{
		huds[0] SetText( level.chalk_override );
		huds[1] SetText( " " );
	}
	else if( level.snr_round <= 5 )
	{
		huds[1] SetText( " " );
	}
	else if( level.snr_round > 10 )
	{
		huds[0].fontscale = 32;
		huds[0] SetValue( level.snr_round );
		huds[1] SetText( " " );
	}

	if(!isdefined(level.gamemode_intro_hud))
	{
		level.gamemode_intro_hud = true;
		level thread gamemode_intro_hud("Search & Rezurrect");
	}

	// Create "ROUND" hud text
	round = create_simple_hud();
	round.alignX = "center"; 
	round.alignY = "bottom";
	round.horzAlign = "user_center"; 
	round.vertAlign = "user_bottom";
	round.fontscale = 16;
	round.color = ( 1, 1, 1 );
	round.x = 0;
	round.y = -265;
	round.alpha = 0;
	round SetText( &"ZOMBIE_ROUND" );

//		huds[0] FadeOverTime( 0.05 );
	huds[0].color = ( 1, 1, 1 );
	huds[0].alpha = 0;
	huds[0].horzAlign = "user_center";
	huds[0].x = -5;
	huds[0].y = -200;

	huds[1] SetText( " " );

	// Fade in white
	round FadeOverTime( 1 );
	round.alpha = 1;

	huds[0] FadeOverTime( 1 );
	huds[0].alpha = 1;

	wait( 1 );

	// Fade to red
	round FadeOverTime( 2 );
	round.color = ( 0.21, 0, 0 );

	huds[0] FadeOverTime( 2 );
	huds[0].color = ( 0.21, 0, 0 );
	wait(2);

// 	if( (level.round_number <= 5 || level.round_number >= 11) && IsDefined( level.chalk_hud2 ) )
// 	{
// 		huds[1] = undefined;
// 	}
// 	
	for ( i=0; i<huds.size; i++ )
	{
		huds[i] FadeOverTime( 2 );
		huds[i].alpha = 1;
	}

	wait( 3 );

	if( IsDefined( round ) )
	{
		round FadeOverTime( 1 );
		round.alpha = 0;
	}

	wait( 0.25 );

	level notify( "intro_hud_done" );
	huds[0] MoveOverTime( 1.75 );
	huds[0].horzAlign = "user_left";
	//		huds[0].x = 0;
	huds[0].y = -4;
	huds[0].x = 64;
	wait( 2 );

	round destroy_hud();
	
	ReportMTU(level.round_number);	// In network debug instrumented builds, causes network spike report to generate.

	// Remove any override set since we're done with it
	if ( IsDefined( level.chalk_override ) )
	{
		level.chalk_override = undefined;
	}
}

snr_round_restart_watcher()
{
	level endon("end_game");
	flag_wait( "begin_spawning" );
	level.team1score = 0;
	level.team2score = 0;
	while(1)
	{
		players = get_players();
		for( i = 0 ; i < players.size; i++ )
		{
			if(!IsDefined(players[i].round_wins))
				players[i].round_wins = 0;
			if(players[i] get_number_of_valid_enemy_players() == 0 && players.size > 1)
			{
				wait .05;
				if(get_number_of_valid_players() == 0)
				{
					round_restart(true);
					continue;
				}
				if(players[i].vsteam == 0)
					level.team1score++;
				else
					level.team2score++;
				if(level.team1score == 3)
				{
					for( j = 0 ; j < players.size; j++ )
					{
						if(players[j].vsteam == 0)
						{
							players[j].won = true;
						}
					}
					level notify("end_game");
				}
				else if(level.team2score == 3)
				{
					for( j = 0 ; j < players.size; j++ )
					{
						if(players[j].vsteam == 1)
						{
							players[j].won = true;
						}
					}
					level notify("end_game");
				}
				else
				{
					round_restart();
				}
			}
		}
		wait .05;
	}
}

race_end_game()
{
	level endon("end_game");
	flag_wait( "all_players_spawned" );
	while(1)
	{
		level.team1score = 0;
		level.team2score = 0;
		players = get_players();
		for( i = 0 ; i < players.size; i++ )
		{
			if(players[i].vsteam == 0)
				level.team1score += players[i].kills;
			else
				level.team2score += players[i].kills;
		}
		if(level.team1score >= 250)
		{
			for( j = 0 ; j < players.size; j++ )
			{
				if(players[j].vsteam == 0)
					players[j].won = true;
			}
			level notify("end_game");
		}
		else if(level.team2score >= 250)
		{
			for( j = 0 ; j < players.size; j++ )
			{
				if(players[j].vsteam == 1)
					players[j].won = true;
			}
			level notify("end_game");
		}
		else if(level.round_number >= 30)
		{
			if(level.team1score > level.team2score)
			{
				for( j = 0 ; j < players.size; j++ )
				{
					if(players[j].vsteam == 0)
						players[j].won = true;
				}
			}
			else if(level.team1score < level.team2kills)
			{
				for( j = 0 ; j < players.size; j++ )
				{
					if(players[j].vsteam == 0)
						players[j].won = true;
				}
			}
			else
			{
				for( j = 0 ; j < players.size; j++ )
				{
					players[j].won = true;
				}
			}
			level notify("end_game");
		}
		wait .1;
	}
}

add_grief_logo(logo)
{
	wait 1.75;
	hud = create_simple_hud(self);
	hud.alignX = "left"; 
	hud.alignY = "bottom";
	hud.horzAlign = "user_left"; 
	hud.vertAlign = "user_bottom";
	//hud.color = ( 0.21, 0, 0 );
	//hud.x = x; 
	hud.y = -4; 
	hud.alpha = 1;
	hud.fontscale = 32.0;

	hud SetShader( logo, 64, 64 );

	return hud;
}

gamemode_intro_hud(gamemode_name)
{
	gamemode = create_simple_hud();
	gamemode.alignX = "center"; 
	gamemode.alignY = "bottom";
	gamemode.horzAlign = "user_center"; 
	gamemode.vertAlign = "user_bottom";
	gamemode.fontscale = 16;
	gamemode.color = ( 1, 1, 1 );
	gamemode.x = 0;
	gamemode.y = -300;
	gamemode.alpha = 0;
	gamemode SetText( gamemode_name );
	gamemode FadeOverTime( 1 );
	gamemode.alpha = 1;
	wait 1;
	gamemode FadeOverTime( 2 );
	gamemode.color = ( 0.21, 0, 0 );
	wait 5;
	gamemode FadeOverTime( 1 );
	gamemode.alpha = 0;
	return gamemode;
}

add_gamemode_hud()
{
	flag_wait( "all_players_spawned" );
	hud = create_simple_hud();
	hud.alignX = "left"; 
	hud.alignY = "top";
	hud.horzAlign = "user_left"; 
	hud.vertAlign = "user_top";
	hud.color = ( 0.21, 0, 0 );
	hud.fontscale = 9;
	hud.alpha = 1;
	while(1)
	{
		hud SetText("CDC: " + level.team1score + " | CIA: " + level.team2score);
		wait .05;
	}
}

race_points_handicap()
{
	while(1)
	{
		self waittill("player_revived");
		if (level.round_number > 6 && self.score < 1500)
		{
			self.score = 1500;
			self maps\_zombiemode_score::set_player_score_hud();
		}
	}
}

revive_grace_period()
{
	while(1)
	{
		self waittill("player_revived");
		self.ignoreme = true;
		wait 1;
		self.ignoreme = false;
	}
}

/*grief_revive_icon()
{
	self.waypointYel = newHudElem();
	self.waypointYel SetTargetEnt(self);
	self.waypointYel.sort = 20;
	self.waypointYel.alpha = 1;
	self.waypointYel setWaypoint( true, "waypoint_" + self.griefteamname );
	self.waypointYel.color = ( 1, .7, .1 );
	time = int(GetDvar("player_lastStandBleedoutTime"));
	self thread fade_over_time(time);
	//self.waypointYel fadeovertime( time );// / 1.25
	//self.waypointYel.color = ( 1, 0, 0 );
	self.waypointWhi = newHudElem();
	self.waypointWhi SetTargetEnt(self);
	self.waypointWhi.sort = 21;
	self.waypointWhi.alpha = 0;
	self.waypointWhi setWaypoint( true, "waypoint_" + self.griefteamname );
	self.waypointWhi.color = ( 1, 1, 1 );
	self thread grief_revive_icon_hide_show_think();
}

grief_revive_icon_hide_show_think()
{
	self endon( "player_revived" );
	self endon( "bled_out" );
	self endon( "round_restarted" );
	while( 1 )
	{
		if( isDefined( self.revivetrigger ) && isDefined( self.revivetrigger.beingRevived ) && self.revivetrigger.beingRevived )
		{
			self.waypointWhi.alpha = 1;
		}
		else
		{
			self.waypointWhi.alpha = 0;
		}
		wait 0.05;
	}
}

remove_grief_revive_icon()
{
	while(1)
	{
		self waittill_any("player_revived","bled_out","round_restarted");
		if(isdefined(self.waypointYel))
			self.waypointYel destroy_hud();
		if(isdefined(self.waypointWhi))
			self.waypointWhi destroy_hud();
	}
}*/

reduce_survive_zombie_amount()
{
	flag_wait( "all_players_spawned" );
	players = get_players();
	while(1)
	{
		for( i = 0; i < players.size; i++ )
		{
			if( players[i] get_number_of_valid_enemy_players() == 0  && players.size > 1 )
			{
				if(level.zombie_total > 100)
				{
					level.zombie_total = 100;
				}
			}
		}
		wait 1;
	}
}