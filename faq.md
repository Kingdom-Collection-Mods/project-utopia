ai_evaluate_production_method building_commercial_factory pm_consumer_goods_plastic_process STATE_KANTO

-nographics -handsoff -scripted_tests

..\..\vic3-tiger.exe "D:\Freddy\Documents\Paradox Interactive\Victoria 3\mod\project-utopia" --no-color > res.txt

https://github.com/kaiser-chris/gate-mod/blob/master/documentation/RESOURCES.md

Very helpful for stuff like this
gate_start_magic_project = {
    custom_tooltip = {
        text = effect_gate_start_magic_project
        set_local_variable = {
            name = gate_project_name
            value = flag:$project$
        }
        set_local_variable = {
            name = monthly_cost
            value = $monthly_cost$
        }
        set_local_variable = {
            name = months
            value = $months$
        }
        add_journal_entry = {
            type = $project$
        }
        set_variable = {
            name = gate_magic_project
            value = je:$project$
        }
    }
}

 effect_gate_start_magic_project: "Start #bold [SCOPE.GetLocalVariable('gate_project_name').GetFlagName]#! [concept_gate_project]. This project will take #v [SCOPE.GetLocalVariable('months').GetValue|0] months#! and will cost us @money!#r -#![SCOPE.GetLocalVariable('monthly_cost').GetValue|-0v] every month."