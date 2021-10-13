#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <hitboxchanger>

ArrayList g_hModelList;
ArrayList g_hDefaultModel;
Handle h_convar_Coef;

enum {
    HB_head = 0,
    HB_neck,
    HB_pelvis,
    HB_spine0,
    HB_spine1,
    HB_spine2,
    HB_spine3,
    HB_leg_upper_L,
    HB_leg_upper_R,
    HB_leg_lower_L,
    HB_leg_lower_R,
    HB_ankle_L,
    HB_ankle_R,
    HB_hand_L,
    HB_hand_R,
    HB_arm_upper_L,
    HB_arm_lower_L,
    HB_arm_upper_R,
    HB_arm_lower_R,
}

public void OnPluginStart(){
    g_hModelList = new ArrayList(1);
    g_hDefaultModel = new ArrayList(2, 1);
    h_convar_Coef = CreateConVar("hb_size", "6");

    HookEvent("player_spawn", HE_PlayerSpawned, EventHookMode_Post);

    AutoExecConfig(true, "hitbox_fix");
}
public void OnMapStart(){
    ResizeArray(g_hDefaultModel, 0);
    ResizeArray(g_hModelList, 0);
}
public Action HE_PlayerSpawned(Event event, const char[] name, bool dontBroadcast){
    int client = GetClientOfUserId(event.GetInt("userid"));
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);

    RegisterModel(client);

    return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
    char sWeaponName[32];
    GetEdictClassname(GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon"), sWeaponName, sizeof(sWeaponName));
    if(!StrEqual(sWeaponName, "weapon_awp"))
        return Plugin_Continue;
    damage = float(GetEntProp(victim, Prop_Send, "m_iHealth"));
    ClientCommand(attacker, "play weapons/flashbang/flashbang_explode1_distant.wav");
	SetEntPropFloat(attacker, 0, "m_flHealthShotBoostExpirationTime", GetGameTime() + 1.0, 0);
    return Plugin_Changed;
}
stock void RegisterModel(int client){
    char sModelName[256];
    
    GetClientModel(client, sModelName, sizeof(sModelName));
    int iModelIndex = PrecacheModel(sModelName);

    if(FindValueInArray(g_hModelList, iModelIndex, 0) > -1) return;  

    int b_pelvis = FindBone("pelvis", iModelIndex),
        b_spine2 = FindBone("spine_2", iModelIndex);
    
    Hitbox hb_pelvis, hb_spine2;
    hb_pelvis.CopyFromModel(iModelIndex, HB_pelvis, b_pelvis);
    hb_spine2.CopyFromModel(iModelIndex, HB_spine2, b_spine2);

    float fMerge[2];
    fMerge[0] = hb_pelvis.radius;
    fMerge[1] = hb_spine2.radius;

    hb_pelvis.radius *= GetConVarFloat(h_convar_Coef);
    hb_spine2.radius *= GetConVarFloat(h_convar_Coef);

    hb_pelvis.CopyToModel(iModelIndex, HB_pelvis, b_pelvis);
    hb_spine2.CopyToModel(iModelIndex, HB_spine2, b_spine2);

    ResizeArray(g_hDefaultModel, GetArraySize(g_hDefaultModel) + 1);
    SetArrayArray(g_hDefaultModel, PushArrayCell(g_hModelList, iModelIndex), fMerge);

    LogMessage("[HITBOX FIX] Model %s registered and applied changes!", sModelName);
}