////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                            OpenCollar - appearance                             //
//                                 version 3.960                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

//handle appearance menu
//handle saving position on detach, and restoring it on httpdb_response

string g_sSubMenu = "Appearance";
string g_sParentMenu = "Main";

string CTYPE = "collar";

list g_lMenuIDs;//3-strided list of avkey, dialogid, menuname
integer g_iMenuStride = 3;

string POSMENU = "Position";
string ROTMENU = "Rotation";
string SIZEMENU = "Size";

list g_lLocalButtons = [POSMENU, ROTMENU, SIZEMENU]; //["Position", "Rotation", "Size"];
list g_lButtons;
float g_fSmallNudge=0.0005;
float g_fMediumNudge=0.005;
float g_fLargeNudge=0.05;
float g_fNudge=0.005; // g_fMediumNudge;
float g_fRotNudge;

// SizeScale

list SIZEMENU_BUTTONS = [ "-1%", "-2%", "-5%", "-10%", "+1%", "+2%", "+5%", "+10%", "100%" ]; // buttons for menu
list g_lSizeFactors = [-1, -2, -5, -10, 1, 2, 5, 10, -1000]; // actual size factors
list g_lPrimStartSizes; // area for initial prim sizes (stored on rez)
integer g_iScaleFactor = 100; // the size on rez is always regarded as 100% to preven problem when scaling an item +10% and than - 10 %, which would actuall lead to 99% of the original size
integer g_iSizedByScript = FALSE; // prevent reseting of the script when the item has been chnged by the script

string TICKED = "☒ ";
string UNTICKED = "☐ ";

string APPLOCK = "LooksLock";
integer g_iAppLock = FALSE;
string g_sAppLockToken = "Appearance_Lock";

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer COMMAND_RLV_RELAY = 507;

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
                            //str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
integer LM_SETTING_EMPTY = 2004;//sent by httpdb script when a token has no value in the db

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

integer ANIM_START = 7000;//send this with the name of an anim in the string part of the message to play the anim
integer ANIM_STOP = 7001;//send this with the name of an anim in the string part of the message to stop the anim
integer CPLANIM_PERMREQUEST = 7002;//id should be av's key, str should be cmd name "hug", "kiss", etc
integer CPLANIM_PERMRESPONSE = 7003;//str should be "1" for got perms or "0" for not.  id should be av's key
integer CPLANIM_START = 7004;//str should be valid anim name.  id should be av
integer CPLANIM_STOP = 7005;//str should be valid anim name.  id should be av

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

//string UPMENU = "â†‘";//when your menu hears this, give the parent menu
string UPMENU = "BACK";

key g_kWearer;

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" 
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
} 

integer GetOwnerChannel(key kOwner, integer iOffset)
{
    integer iChan = (integer)("0x"+llGetSubString((string)kOwner,2,7)) + iOffset;
    if (iChan>0)
    {
        iChan=iChan*(-1);
    }
    if (iChan > -10000)
    {
        iChan -= 30000;
    }
    return iChan;
}
Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    if (kID == g_kWearer)
    {
        llOwnerSay(sMsg);
    }
    else if (llGetAgentSize(kID) != ZERO_VECTOR)
    {
        llInstantMessage(kID,sMsg);
        if (iAlsoNotifyWearer)
        {
            llOwnerSay(sMsg);
        }
    }
    else // remote request
    {
        llRegionSayTo(kID, GetOwnerChannel(g_kWearer, 1111), sMsg);
    }
}

Debug(string sStr)
{
    //llOwnerSay(llGetScriptName() + ": " + sStr);
}
string GetScriptID()
{
    // strip away "OpenCollar - " leaving the script's individual name
    list parts = llParseString2List(llGetScriptName(), ["-"], []);
    return llStringTrim(llList2String(parts, 1), STRING_TRIM) + "_";
}
string PeelToken(string in, integer slot)
{
    integer i = llSubStringIndex(in, "_");
    if (!slot) return llGetSubString(in, 0, i);
    return llGetSubString(in, i + 1, -1);
}
integer MinMaxUnscaled(vector vSize, float fScale)
{
    if (fScale < 1.0)
    {
        if (vSize.x <= 0.01)
            return TRUE;
        if (vSize.y <= 0.01)
            return TRUE;
        if (vSize.z <= 0.01)
            return TRUE;
    }
    else
    {
        if (vSize.x >= 10.0)
            return TRUE;
        if (vSize.y >= 10.0)
            return TRUE;
        if (vSize.z >= 10.0)
            return TRUE;
    }
    return FALSE;
}

integer MinMaxScaled(vector vSize, float fScale)
{
    if (fScale < 1.0)
    {
        if (vSize.x < 0.01)
            return TRUE;
        if (vSize.y < 0.01)
            return TRUE;
        if (vSize.z < 0.01)
            return TRUE;
    }
    else
    {
        if (vSize.x > 10.0)
            return TRUE;
        if (vSize.y > 10.0)
            return TRUE;
        if (vSize.z > 10.0)
            return TRUE;
    }
    return FALSE;
}


Store_StartScaleLoop()
{
    g_lPrimStartSizes = [];
    integer iPrimIndex;
    vector vPrimScale;
    vector vPrimPosit;
    list lPrimParams;
    if (llGetNumberOfPrims()<2) 
    {
        vPrimScale = llGetScale();
        g_lPrimStartSizes += vPrimScale.x;
    }
    else
    {
        for (iPrimIndex = 1; iPrimIndex <= llGetNumberOfPrims(); iPrimIndex++ )
        {
            lPrimParams = llGetLinkPrimitiveParams( iPrimIndex, [PRIM_SIZE, PRIM_POSITION]);
            vPrimScale=llList2Vector(lPrimParams,0);
            vPrimPosit=(llList2Vector(lPrimParams,1)-llGetRootPosition())/llGetRootRotation();
            g_lPrimStartSizes += [vPrimScale,vPrimPosit];
        }
    }
    g_iScaleFactor = 100;
}

ScalePrimLoop(integer iScale, integer iRezSize, key kAV)
{
    integer iPrimIndex;
    float fScale = iScale / 100.0;
    list lPrimParams; 
    vector vPrimScale;
    vector vPrimPos;
    vector vSize;
    if (llGetNumberOfPrims()<2) 
    {
        vSize = llList2Vector(g_lPrimStartSizes,0);
        if (MinMaxUnscaled(llGetScale(), fScale) || !iRezSize)
        {
            Notify(kAV, "The object cannot be scaled as you requested; prims are already at minimum or maximum size.", TRUE);
            return;
        }
        else if (MinMaxScaled(fScale * vSize, fScale) || !iRezSize)
        {
            Notify(kAV, "The object cannot be scaled as you requested; prims would surpass minimum or maximum size.", TRUE);
            return;
        }
        else
        {
            llSetScale(fScale * vSize); // not linked prim
        }
    }
    else
    {
        if  (!iRezSize)
        {
            // first some checking
            for (iPrimIndex = 1; iPrimIndex <= llGetNumberOfPrims(); iPrimIndex++ )
            {
                lPrimParams = llGetLinkPrimitiveParams( iPrimIndex, [PRIM_SIZE, PRIM_POSITION]);
                vPrimScale = llList2Vector(g_lPrimStartSizes, (iPrimIndex  - 1)*2);

                if (MinMaxUnscaled(llList2Vector(lPrimParams,0), fScale))
                {
                    Notify(kAV, "The object cannot be scaled as you requested; prims are already at minimum or maximum size.", TRUE);
                    return;
                }
                else if (MinMaxScaled(fScale * vPrimScale, fScale))
                {
                    Notify(kAV, "The object cannot be scaled as you requested; prims would surpass minimum or maximum size.", TRUE);
                    return;
                }
            }
        }
        Notify(kAV, "Scaling started, please wait ...", TRUE);
        g_iSizedByScript = TRUE;
        for (iPrimIndex = 1; iPrimIndex <= llGetNumberOfPrims(); iPrimIndex++ )
        {
//            lPrimParams = llGetLinkPrimitiveParams(iPrimIndex, [PRIM_SIZE, PRIM_POSITION]);
            vPrimScale = fScale * llList2Vector(g_lPrimStartSizes, (iPrimIndex - 1)*2);
            vPrimPos = fScale * llList2Vector(g_lPrimStartSizes, (iPrimIndex - 1)*2+1);
            if (iPrimIndex == 1) 
            {
                llSetLinkPrimitiveParamsFast(iPrimIndex, [PRIM_SIZE, vPrimScale]);
            }
            else 
            {
                llSetLinkPrimitiveParamsFast(iPrimIndex, [PRIM_SIZE, vPrimScale, PRIM_POSITION, vPrimPos]);
            }
        }
        g_iScaleFactor = iScale;
        g_iSizedByScript = TRUE;
        Notify(kAV, "Scaling finished, the "+CTYPE+" is now on "+ (string)g_iScaleFactor +"% of the rez size.", TRUE);
    }
}


ForceUpdate()
{
    //workaround for https://jira.secondlife.com/browse/VWR-1168
    llSetText(".", <1,1,1>, 1.0);
    llSetText("", <1,1,1>, 1.0);
}

AdjustPos(vector vDelta)
{
    if (llGetAttached())
    {
        llSetPos(llGetLocalPos() + vDelta);
        ForceUpdate();
    }
}

AdjustRot(vector vDelta)
{
    if (llGetAttached())
    {
        llSetLocalRot(llGetLocalRot() * llEuler2Rot(vDelta));
        ForceUpdate();
    }
}

RotMenu(key kAv, integer iAuth)
{
    string sPrompt = "\nAdjust the "+CTYPE+"'s rotation.\n\nNOTE: Arrows refer to the neck joint.";
    list lMyButtons = ["tilt up ↻", "right ↷", "tilt left ↙", "tilt down ↺", "left ↶", "tilt right ↘"];// ria change
    key kMenuID = Dialog(kAv, sPrompt, lMyButtons, [UPMENU], 0, iAuth);
    integer iMenuIndex = llListFindList(g_lMenuIDs, [kAv]);
    list lAddMe = [kAv, kMenuID, ROTMENU];
    if (iMenuIndex == -1)
    {
        g_lMenuIDs += lAddMe;
    }
    else
    {
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, lAddMe, iMenuIndex, iMenuIndex + g_iMenuStride - 1);
    }
}

PosMenu(key kAv, integer iAuth)
{
    string sPrompt = "\nAdjust the "+CTYPE+"'s position.\n\nNOTE: Arrows refer to the neck joint.\n\nCurrent nudge strength is: ";
    list lMyButtons = ["left ←", "up ↑", "forward ↳", "right →", "down ↓", "backward ↲"];// ria iChange
    if (g_fNudge!=g_fSmallNudge) lMyButtons+=["▸"];
    else sPrompt += "▸";
    if (g_fNudge!=g_fMediumNudge) lMyButtons+=["▸▸"];
    else sPrompt += "▸▸";
    if (g_fNudge!=g_fLargeNudge) lMyButtons+=["▸▸▸"];
    else sPrompt += "▸▸▸";
    
    key kMenuID = Dialog(kAv, sPrompt, lMyButtons, [UPMENU], 0, iAuth);
    integer iMenuIndex = llListFindList(g_lMenuIDs, [kAv]);
    list lAddMe = [kAv, kMenuID, POSMENU];
    if (iMenuIndex == -1)
    {
        g_lMenuIDs += lAddMe;
    }
    else
    {
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, lAddMe, iMenuIndex, iMenuIndex + g_iMenuStride - 1);    
    }
}

SizeMenu(key kAv, integer iAuth)
{
    string sPrompt = "\nAdjust the "+CTYPE+"'s scale.\n\nIt is based on the size the "+CTYPE+" has upon rezzing. You can change back to this size by using '100%'.\n\nCurrent size: " + (string)g_iScaleFactor + "%\n\nWARNING: Make a backup copy of your "+CTYPE+" first! Considering the massive variation of designs, this feature is not granted to work in all cases. Possible rendering bugs mean having to right-click your "+CTYPE+" first to see the actual result.";
    key kMenuID = Dialog(kAv, sPrompt, SIZEMENU_BUTTONS, [UPMENU], 0, iAuth);
    integer iMenuIndex = llListFindList(g_lMenuIDs, [kAv]);
    list lAddMe = [kAv, kMenuID, SIZEMENU];
    if (iMenuIndex == -1)
    {
        g_lMenuIDs += lAddMe;
    }
    else
    {
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, lAddMe, iMenuIndex, iMenuIndex + g_iMenuStride - 1);
    }
        Debug("FreeMem: " + (string)llGetFreeMemory());
}

DoMenu(key kAv, integer iAuth)
{
    list lMyButtons;
    string sPrompt;
    if (g_iAppLock)
    {
        sPrompt = "\nThe appearance of the "+CTYPE+" has been locked.\n\nAn owner must unlock it to allow modification.";
        lMyButtons = [TICKED + APPLOCK];
    }
    else
    {
        sPrompt = "\nChange the looks, adjustment and size of your "+CTYPE+".\n\nwww.opencollar.at/appearance";
    
        lMyButtons = [UNTICKED + APPLOCK] + g_lButtons + g_lLocalButtons ;
        //lMyButtons += llListSort(g_lLocalButtons + g_lButtons, 1, TRUE);
    }
    key kMenuID = Dialog(kAv, sPrompt, lMyButtons, [UPMENU], 0, iAuth);
    integer iMenuIndex = llListFindList(g_lMenuIDs, [kAv]);
    list lAddMe = [kAv, kMenuID, g_sSubMenu];
    if (iMenuIndex == -1)
    {
        g_lMenuIDs += lAddMe;
    }
    else
    {
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, lAddMe, iMenuIndex, iMenuIndex + g_iMenuStride - 1);    
    }    
}

default
{
    state_entry()
    {
        g_kWearer = llGetOwner();       
        g_fRotNudge = PI / 32.0;//have to do this here since we can't divide in a global var declaration   

        Store_StartScaleLoop();
        
        Debug("FreeMem: " + (string)llGetFreeMemory());
    }
    
    on_rez(integer iParam)
    {
        llResetScript();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            //llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
            g_lButtons = []; // flush buttons before
            llMessageLinked(LINK_SET, MENUNAME_REQUEST, g_sSubMenu, "");
        }
        else if (iNum == MENUNAME_RESPONSE)
        {
            list lParts = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParts, 0) == g_sSubMenu)
            {//someone wants to stick something in our menu
                string button = llList2String(lParts, 1);
                if (llListFindList(g_lButtons, [button]) == -1)
                {
                    g_lButtons = llListSort(g_lButtons + [button], 1, TRUE);
                }
            }
        }
        else if (iNum >= COMMAND_OWNER && iNum <= COMMAND_WEARER)
        {
            list lParams = llParseString2List(sStr, [" "], []);
            string sCommand = llToLower(llList2String(lParams, 0));
            string sValue = llToLower(llList2String(lParams, 1));
            if (sCommand == "menu" && llGetSubString(sStr, 5, -1) == g_sSubMenu)
            {
                //someone asked for our menu
                //give this plugin's menu to id
                if (kID!=g_kWearer && iNum!=COMMAND_OWNER)
                {
                    Notify(kID,"You are not allowed to change the "+CTYPE+"'s appearance.", FALSE);
                    llMessageLinked(LINK_SET, iNum, "menu " + g_sParentMenu, kID);
                }
                else DoMenu(kID, iNum);
            }
            /*else if (sStr == "refreshmenu")
            {
                g_lButtons = [];
                llMessageLinked(LINK_SET, MENUNAME_REQUEST, g_sSubMenu, "");
            }*/
            else if (sStr == "appearance")
            {
                if (kID!=g_kWearer && iNum!=COMMAND_OWNER)
                {
                    Notify(kID,"You are not allowed to change the "+CTYPE+"'s appearance.", FALSE);
                }
                else DoMenu(kID, iNum);
            }
            else if (sStr == "rotation")
            {
                if (kID!=g_kWearer && iNum!=COMMAND_OWNER)
                {
                    Notify(kID,"You are not allowed to change the "+CTYPE+"'s rotation.", FALSE);
                }
                else if (g_iAppLock)
                {
                    Notify(kID,"The appearance of the "+CTYPE+" is locked. You cannot access this menu now!", FALSE);
                    DoMenu(kID, iNum);
                }
                else RotMenu(kID, iNum);
             }
            else if (sStr == "position")
            {
                if (kID!=g_kWearer && iNum!=COMMAND_OWNER)
                {
                    Notify(kID,"You are not allowed to change the "+CTYPE+"'s position.", FALSE);
                }
                else if (g_iAppLock)
                {
                    Notify(kID,"The appearance of the "+CTYPE+" is locked. You cannot access this menu now!", FALSE);
                    DoMenu(kID, iNum);
                }
                else PosMenu(kID, iNum);
            }
            else if (sStr == "size")
            {
                if (kID!=g_kWearer && iNum!=COMMAND_OWNER)
                {
                    Notify(kID,"You are not allowed to change the "+CTYPE+"'s size.", FALSE);
                }
                else if (g_iAppLock)
                {
                    Notify(kID,"The appearance of the "+CTYPE+" is locked. You cannot access this menu now!", FALSE);
                    DoMenu(kID, iNum);
                }
                else SizeMenu(kID, iNum);
            }
            else if (sCommand == "lockappearance")
            {
                if (iNum == COMMAND_OWNER)
                {
                    g_iAppLock = (sValue!="0");
                    if(g_iAppLock) llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sAppLockToken + "=1", "");
                    else llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sAppLockToken, "");
                }
                else Notify(kID,"Only owners can use this option.", FALSE);
            }
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);

            if (sToken == g_sAppLockToken)
            {
                g_iAppLock = (integer)sValue;
            }
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1)
            {
                //got a menu response meant for us.  pull out values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);          
                string sMessage = llList2String(lMenuParams, 1);                                         
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);
                //remove stride from g_lMenuIDs
                //we have to subtract from the index because the dialog id comes in the middle of the stride
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);                  
                if (sMenuType == g_sSubMenu)
                {
                    if (sMessage == UPMENU)
                    {
                        //give kID the parent menu
                        llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                    }
                    else if(llGetSubString(sMessage, llStringLength(TICKED), -1) == APPLOCK)
                    {
                        integer lock = llGetSubString(sMessage, 0, llStringLength(UNTICKED) - 1) == UNTICKED;
                        // Hack: change local lock state in order for the menu to appear updated
                        //      without waiting for the result of the "lockappearance" asynchronous call.
                        //      We use this call here is because appearance lock has to be propagated
                        //      to other scripts. Thus we cannot prevent the local handler from
                        //      being called too although we would be better with just calling a
                        //      shared function (synchronously).
                        //      The alternative would be calling DoMenu in the "lockappearance" LM
                        //      handler, using a global variable such as g_iRemenu
                        //      ... which we do not like anymore.
                        //      The only drawback is to make sure the auth test remains consistant
                        //      in both places: here and in the "lockappearance" handler.
                        if (iAuth == COMMAND_OWNER) g_iAppLock = lock;
                        // /Hack
                        if (lock) llMessageLinked(LINK_SET, iAuth, "lockappearance 1", kAv);
                        else llMessageLinked(LINK_SET, iAuth, "lockappearance 0", kAv);
                        DoMenu(kAv, iAuth);
                    }
                    else if (~llListFindList(g_lLocalButtons, [sMessage]))
                    {
                        //we got a response for something we handle locally
                        if (sMessage == POSMENU)
                        {
                            PosMenu(kAv, iAuth);
                        }
                        else if (sMessage == ROTMENU)
                        {
                            RotMenu(kAv, iAuth);
                        }
                        else if (sMessage == SIZEMENU)
                        {
                            SizeMenu(kAv, iAuth);
                        }
                    }
                    else if (~llListFindList(g_lButtons, [sMessage]))
                    {
                        //we got a submenu selection
                        llMessageLinked(LINK_SET, iAuth, "menu " + sMessage, kAv);
                    }                                
                }
                else if (sMenuType == POSMENU)
                {
                    if (sMessage == UPMENU)
                    {
                        DoMenu(kAv, iAuth);
                        return;
                    }
                    else if (llGetAttached())
                    {
                        if (sMessage == "forward ↳")
                        {
                            AdjustPos(<g_fNudge, 0, 0>);
                        }
                        else if (sMessage == "left ←")
                        {
                            AdjustPos(<0, g_fNudge, 0>);                
                        }
                        else if (sMessage == "up ↑")
                        {
                            AdjustPos(<0, 0, g_fNudge>);                
                        }            
                        else if (sMessage == "backward ↲")
                        {
                            AdjustPos(<-g_fNudge, 0, 0>);                
                        }            
                        else if (sMessage == "right →")
                        {
                            AdjustPos(<0, -g_fNudge, 0>);                    
                        }            
                        else if (sMessage == "down ↓")
                        {
                            AdjustPos(<0, 0, -g_fNudge>);                
                        }                            
                        else if (sMessage == "▸")
                        {
                            g_fNudge=g_fSmallNudge;
                        }
                        else if (sMessage == "▸▸")
                        {
                            g_fNudge=g_fMediumNudge;                
                        }
                        else if (sMessage == "▸▸▸")
                        {
                            g_fNudge=g_fLargeNudge;                
                        }
                    }
                    else
                    {
                        Notify(kAv, "Sorry, position can only be adjusted while worn",FALSE);
                    }
                    PosMenu(kAv, iAuth);                    
                }
                else if (sMenuType == ROTMENU)
                {
                    if (sMessage == UPMENU)
                    {
                        DoMenu(kAv, iAuth);
                        return;
                    }
                    else if (llGetAttached())
                    {
                        if (sMessage == "tilt right ↘") // was tilt up
                        {
                            AdjustRot(<g_fRotNudge, 0, 0>);
                        }
                        else if (sMessage == "tilt up ↻") // was right
                        {
                            AdjustRot(<0, g_fRotNudge, 0>);             
                        }
                        else if (sMessage == "right ↷") // was tilt left
                        {
                            AdjustRot(<0, 0, g_fRotNudge>);           
                        }            
                        else if (sMessage == "tilt left ↙") // was tilt down
                        {
                            AdjustRot(<-g_fRotNudge, 0, 0>);              
                        }            
                        else if (sMessage == "tilt down ↺") // was left
                        {
                            AdjustRot(<0, -g_fRotNudge, 0>);              
                        }            
                        else if (sMessage == "left ↶") // was tilt right
                        {
                            AdjustRot(<0, 0, -g_fRotNudge>);            
                        }                        
                    }
                    else
                    {
                        Notify(kAv, "Sorry, position can only be adjusted while worn", FALSE);
                    }
                    RotMenu(kAv, iAuth);                     
                }
                else if (sMenuType == SIZEMENU)
                {
                    if (sMessage == UPMENU)
                    {
                        DoMenu(kAv, iAuth);
                        return;
                    }
                    else
                    {
                        integer iMenuCommand = llListFindList(SIZEMENU_BUTTONS, [sMessage]);
                        if (iMenuCommand != -1)
                        {
                            integer iSizeFactor = llList2Integer(g_lSizeFactors, iMenuCommand);
                            if (iSizeFactor == -1000)
                            {
                                // ResSize requested
                                if (g_iScaleFactor == 100)
                                {
                                    Notify(kAv, "Resizing canceled; the "+CTYPE+" is already at original size.", FALSE); 
                                }
                                else
                                {
                                    ScalePrimLoop(100, TRUE, kAv);
                                }
                            }
                            else
                            {
                                ScalePrimLoop(g_iScaleFactor + iSizeFactor, FALSE, kAv);
                            }
                        }
                        SizeMenu(kAv, iAuth);
                    }
                }
            }            
        }
        else if (iNum == DIALOG_TIMEOUT)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1)
            {
                //remove stride from g_lMenuIDs
                //we have to subtract from the index because the dialog id comes in the middle of the stride
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);                          
            }            
        }
    } 
    
    changed(integer iChange)
    {
        if (iChange & (CHANGED_SCALE))
        {
            if (g_iSizedByScript)
            // the item had ben rescaled by the script, do NOT reset the script and store new positions
            {
                // ignore the event and trigger timer to reset flag. needed as we got the event twice after scaling
                llSetTimerEvent(0.5);
            }
            else
            // it was a user change, so we have to store the basic values again
            {
                    Store_StartScaleLoop();
            }
        }
        if (iChange & (CHANGED_SHAPE | CHANGED_LINK))
        {
            Store_StartScaleLoop();
        }
    }
    
    timer()
    {
        // the timer is needed as the changed_size even is triggered twice
        llSetTimerEvent(0);
        if (g_iSizedByScript)
            g_iSizedByScript = FALSE;
    }
}
