#define ALIEN_HEALTH_DESCRIPTION_100 "<span class='noticealien'>They are in perfect health.</span>"
#define ALIEN_HEALTH_DESCRIPTION_99 "<span class='warning'>They are slightly injured.</span>"
#define ALIEN_HEALTH_DESCRIPTION_75	"<span class='warning'>They look injured.</span>"
#define ALIEN_HEALTH_DESCRIPTION_50 "<span class='warning'>They are very hurt!</span>"
#define ALIEN_HEALTH_DESCRIPTION_25 "<span class='warning'><b>They are heavily injured and limping badly!</b></span>"
#define ALIEN_HEALTH_DESCRIPTION_0 "<span class='warning'><b>They are on the verge of death!</b></span>"
#define ALIEN_HEALTH_DESCRIPTION_DEAD "<span class='warning'>They have deceased.</span>"

/mob/living/carbon/alien
	var/footstep_sound = "alien_step"
	var/footstep_volume = 25
	var/footstep_range = 10 //Maximum range you can hear them moving around. Will be very quiet at maximum range and much less when walking/sneaking.
	var/strength = 1		//Arbitrary value used for damage and swiftness when performing things like ripping open doors.
/mob/living/carbon/alien/humanoid/hunter
	strength = 2

/mob/living/carbon/alien/humanoid/queen
	strength = 3


//Movement related stuff.
/mob/living/carbon/alien/movement_delay()
	. += ..()
	if(pulling)//Slowdown when pulling something to prevent cheesy tacklespam running
		. += 1.5

/mob/living/movement_delay()
	. = ..()
	if(!isalien(src) && (locate(/obj/structure/alien/weeds) in loc))
		. += 1

/mob/living/carbon/alien/larva
	footstep_sound = null

//Breathing noises
/mob/living/carbon/alien/humanoid/check_breath(datum/gas_mixture/breath)
	if(breath && breath.total_moles() > 0)
		var/soundrange
		switch(m_intent)
			if("walk")
				soundrange = -6
			if("run")
				soundrange = -3
		playsound(get_turf(src), pick('sound/arf/alien/voice/lowHiss2.ogg', 'sound/arf/alien/voice/lowHiss3.ogg', 'sound/arf/alien/voice/lowHiss4.ogg'), 75, 0, soundrange)
	..()


//Universal health indicator
/mob/living/carbon/alien/humanoid/handle_regular_hud_updates()
	..()
	if(healths)
		if(stat != DEAD)
			var/health_percent = round((health/maxHealth)*100)
			switch(health_percent)
				if(100 to INFINITY)
					healths.icon_state = "health0"
				if(76 to 99)
					healths.icon_state = "health1"
				if(51 to 75)
					healths.icon_state = "health2"
				if(26 to 50)
					healths.icon_state = "health3"
				if(1 to 25)
					healths.icon_state = "health4"
				else
					healths.icon_state = "health5"
		else
			healths.icon_state = "health6"

/mob/living/carbon/alien/humanoid/admin
	name = "alien"
	caste = "h"
	maxHealth = 100
	health = 100
	icon_state = "alienh"
	has_fine_manipulation = TRUE
	default_alien_organs = list(/obj/item/organ/internal/brain/xeno,
	 					/obj/item/organ/internal/xenos/hivenode,
	 					/obj/item/organ/internal/xenos/plasmavessel/drone,
	 					/obj/item/organ/internal/xenos/acidgland,
	 					/obj/item/organ/internal/xenos/resinspinner)

/mob/living/carbon/alien/humanoid/admin/New()
	..()
	add_language("Galactic Common")


/obj/machinery/door/airlock/attack_alien(mob/living/carbon/alien/humanoid/user)
	add_fingerprint(user)
	user.changeNext_move(CLICK_CD_MELEE)
	if(isElectrified())
		shock(user, 100) //Mmm, fried xeno!
		return
	if(!density) //Already open
		return
	if(locked || welded) //Extremely generic, as aliens only understand the basics of how airlocks work.
		to_chat(user, "<span class='warning'>[src] refuses to budge!</span>")
		return
	if(user.a_intent == "help")//Only pry the airlock if they're not on help intent
		return attack_hand(user)
	user.visible_message("<span class='warning'>[user] begins prying open [src].</span>",\
						"<span class='noticealien'>You begin digging your claws into [src] with all your might!</span>",\
						"<span class='warning'>You hear groaning metal...</span>")
	var/time_to_open = 5
	if(hasPower())
		time_to_open = max(0,(60 - 10*user.strength)) //Powered airlocks take longer to open, and are loud.
		playsound(src, 'sound/machines/airlock_alien_prying.ogg', 100, 1)


	if(do_after(user, time_to_open, target = src))
		if(density && !open(2)) //The airlock is still closed, but something prevented it opening. (Another player noticed and bolted/welded the airlock in time!)
			to_chat(user, "<span class='warning'>Despite your efforts, [src] managed to resist your attempts to open it!</span>")

/obj/machinery/door/proc/hasPower()
	return !(stat & NOPOWER)


/obj/structure/alien/weeds/attack_hand(mob/user)
	..()
	if(isturf(loc))
		return loc.attack_hand(user)

/obj/structure/alien/weeds/attack_alien(mob/living/carbon/alien/humanoid/user)
	..()
	return attack_hand(user)



/mob/living/carbon/alien/examine(mob/user)
	..()
	// crappy hacks because you can't do \his[src] etc. I'm sorry this proc is so unreadable, blame the text macros :<
	var/t_He = "It" //capitalised for use at the start of each line.
	var/t_his = "its"
//Commented for now because they're not in use and warnings aren't fun to look at :(
//	var/t_him = "it"
//	var/t_has = "has"
	var/t_is = "is"
	var/examine_health_info
	var/msg
	switch(gender)
		if(MALE)
			t_He = "He"
			t_his = "his"
//			t_him = "him"
		if(FEMALE)
			t_He = "She"
			t_his = "her"
//			t_him = "her"
		if(PLURAL)
			t_He = "They"
			t_his = "their"
//			t_him = "them"
//			t_has = "have"
			t_is = "are"
	//left hand
	if(l_hand && !(l_hand.flags & ABSTRACT))
		if(l_hand.blood_DNA)
			msg += "<span class='warning'>[t_He] [t_is] holding [bicon(l_hand)] [l_hand.gender==PLURAL?"some":"a"] [l_hand.blood_color != "#030303" ? "blood-stained":"oil-stained"] [l_hand.name] in [t_his] left hand!</span>\n"
		else
			msg += "[t_He] [t_is] holding [bicon(l_hand)] \a [l_hand] in [t_his] left hand.\n"
	//right hand
	if(r_hand && !(r_hand.flags & ABSTRACT))
		if(r_hand.blood_DNA)
			msg += "<span class='warning'>[t_He] [t_is] holding [bicon(r_hand)] [r_hand.gender==PLURAL?"some":"a"] [r_hand.blood_color != "#030303" ? "blood-stained":"oil-stained"] [r_hand.name] in [t_his] right hand!</span>\n"
		else
			msg += "[t_He] [t_is] holding [bicon(r_hand)] \a [r_hand] in [t_his] right hand.\n"
	//handcuffed?
	if(handcuffed)
		if(istype(handcuffed, /obj/item/weapon/restraints/handcuffs/cable/zipties))
			msg += "<span class='warning'>[t_He] [t_is] [bicon(handcuffed)] restrained with zipties!</span>\n"
		else if(istype(handcuffed, /obj/item/weapon/restraints/handcuffs/cable))
			msg += "<span class='warning'>[t_He] [t_is] [bicon(handcuffed)] restrained with cable!</span>\n"
		else
			msg += "<span class='warning'>[t_He] [t_is] [bicon(handcuffed)] handcuffed!</span>\n"
	//Basic health information.
	if(stat != DEAD)
		var/health_percent = round((health/maxHealth)*100)
		switch(health_percent)
			if(100 to INFINITY)
				examine_health_info = ALIEN_HEALTH_DESCRIPTION_100
			if(76 to 99)
				examine_health_info = ALIEN_HEALTH_DESCRIPTION_99
			if(51 to 75)
				examine_health_info = ALIEN_HEALTH_DESCRIPTION_75
			if(26 to 50)
				examine_health_info = ALIEN_HEALTH_DESCRIPTION_50
			if(1 to 25)
				examine_health_info = ALIEN_HEALTH_DESCRIPTION_25
			else
				examine_health_info = ALIEN_HEALTH_DESCRIPTION_0
	else
		examine_health_info = ALIEN_HEALTH_DESCRIPTION_DEAD
	msg += "[examine_health_info]\n"

	if(print_flavor_text())
		msg += "[print_flavor_text()]\n"

	to_chat(user, msg)



/mob/living/carbon/alien/verb/set_flavor()
	set name = "Set Flavour Text"
	set desc = "Sets an extended description of your character's features."
	set category = "IC"

	update_flavor_text()