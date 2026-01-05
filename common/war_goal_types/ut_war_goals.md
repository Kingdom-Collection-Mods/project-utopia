some_war_goal = {
	icon = "gfx/interface/icons/war_goals/icon.dds"

	kind = war_goal_kind

	settings = {
        setting_1
        setting_2
	}

	execution_priority = 80

	contestion_type = control_type

	target_type = target_type

	possible = {
		# trigger to determine if a goal with its target data is listed when selecting a war goal in the diplo play panel
		# scopes: root = holder, creator_country, diplomatic_play, target_country, target_state, stakeholder, target_region, article_options
	}

	valid = {
		# trigger in addition to some basic validation code-side
		# scopes: root = holder, creator_country, diplomatic_play, target_country, target_state, stakeholder, target_region, article_options
	}

	maneuvers = {
		# script value
		# scopes: root = holder, creator_country, diplomatic_play, target_country, target_state, stakeholder, target_region, article_options
		value = 10
	}
	
	infamy = {
		# script value
		# scopes: root = holder, creator_country, diplomatic_play, target_country, target_state, stakeholder, target_region, article_options
		value = 15
	}

	on_enforced = {
		# script effect on top of the predefined code effect
		# scopes: root = holder, creator_country, diplomatic_play, target_country, target_state, stakeholder, target_region, article_options
	}

	ai = {
		is_significant_demand = yes
	}
}