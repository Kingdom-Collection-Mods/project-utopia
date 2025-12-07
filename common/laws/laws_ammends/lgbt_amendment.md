ut_lgbt_same_sex_unions_amendment = {

    parent = law_lgbt_rights_3 # optional reference to a law that dictates what stances IGs and movements have toward this amendment

 

    allowed_laws = {
        law_lgbt_rights_3
    }

 

    modifier = {}

 

    tax_modifier_very_low = {}

    tax_modifier_low = {}

    tax_modifier_medium = {}

    tax_modifier_high = {}

    tax_modifier_very_high = {}

 

    possible = {

        always = yes

    }

 

   can_repeal = {       always = yes    }

 

    ai_will_revoke = {

        always = no

    }

}

ut_lgbt_same_sex_marriage_amendment = {

    parent = law_lgbt_rights_3 # optional reference to a law that dictates what stances IGs and movements have toward this amendment

 

    allowed_laws = {
        law_lgbt_rights_3
    }

 

    modifier = {}

 

    tax_modifier_very_low = {}

    tax_modifier_low = {}

    tax_modifier_medium = {}

    tax_modifier_high = {}

    tax_modifier_very_high = {}

 

    possible = {
        NOT = { has_law = law_state_atheism }
    }

 

   can_repeal = {       always = yes    }

 

    ai_will_revoke = {

        always = no

    }

}

ut_lgbt_sexual_self_determination_amendment = {

    parent = law_lgbt_rights_3 # optional reference to a law that dictates what stances IGs and movements have toward this amendment

 

    allowed_laws = {
        law_lgbt_rights_3
    }

 

    modifier = {}
 

    tax_modifier_very_low = {}

    tax_modifier_low = {}

    tax_modifier_medium = {}

    tax_modifier_high = {}

    tax_modifier_very_high = {}
 

    possible = {
    }

 

   can_repeal = {       always = yes    }

 

    ai_will_revoke = {
        always = no
    }
}