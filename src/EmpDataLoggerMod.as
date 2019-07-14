import com.Utils.Archive;
import com.GameInterface.Log;


//import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import com.Utils.ID32;
import com.GameInterface.Inventory;
import com.GameInterface.InventoryItem;
import com.GameInterface.CraftingInterface;

/**
 * SkeletonMod provides a very simple implementation for drawing and dragging a coloured box about the screen.
 * 
 * @author Icarus James
 */

 
	
///////////////////////////
//////// REQUIRED /////////
///////////////////////////
class EmpDataLoggerMod
{    
	
	private var m_swfRoot: MovieClip; // Our root MovieClip

		
	//Variables from maXPert
	private var m_UpgradeInventory:Inventory;
	private var m_swfroot:MovieClip;
	private var resultItemID;
	
	//Variables from EmpowermentHelper
    private var EMPOWER_SLOT_0:Number = 3;
    private var EMPOWER_SLOT_1:Number = 4;
    private var EMPOWER_SLOT_2:Number = 5;
    private var EMPOWER_SLOT_3:Number = 6;
	private var EMPOWER_SLOT_4:Number = 7; 


	private var debug:Boolean
	
	private var StartXP_Talisman:Number
	private var StartXP_Glyph:Number
	private var StartXP_Signet:Number
	private var FodderXP_Base:Number
	private var FodderXP_EmbeddedSignet:Number
	private var FodderXP_EmbeddedGlyph:Number
	private var EndXP_Talisman:Number
	private var EndXP_Glyph:Number
	private var EndXP_Signet:Number
	private var EmpoweredItemType:String
	private var FodderItemQuality:String
	private var NumFodderItems:Number
	
	
    public function EmpDataLoggerMod(swfRoot: MovieClip) 
    {
		// Store a reference to the root MovieClip
		m_swfRoot = swfRoot;
		
		m_UpgradeInventory = new Inventory(new ID32(_global.Enums.InvType.e_Type_GC_CraftingInventory, Character.GetClientCharID().GetInstance()));
		
		// Persistent data needed to determine upgrade results
		StartXP_Talisman = -1;
		StartXP_Glyph = -1;
		StartXP_Signet = -1;
		EndXP_Talisman = -1;
		EndXP_Glyph = -1;
		EndXP_Signet = -1;
		EmpoweredItemType = "";
		FodderItemQuality = "";
		NumFodderItems = -1;
		FodderXP_Base = 0;
		FodderXP_EmbeddedGlyph = 0;
		FodderXP_EmbeddedSignet = 0;

		debug = false;
    }
	
	public function OnLoad() {
		// Register the crafting result signal
		CraftingInterface.SignalCraftingResultFeedback.Connect(EmpowermentWindowUpdateHandler, this);
		PrintChatText("EmpDataLogger Loaded!");
		// testing
		//m_UpgradeInventory.SignalItemAdded.Connect(ItemsChanged, this)
		//m_UpgradeInventory.SignalItemMoved.Connect(ItemsChanged, this)
		//m_UpgradeInventory.SignalItemRemoved.Connect(ItemsChanged, this)
		//m_UpgradeInventory.SignalItemStatChanged.Connect(ItemStatChanged, this)
		
	}
	
	public function OnUnload() {
		CraftingInterface.SignalCraftingResultFeedback.Disconnect(EmpowermentWindowUpdateHandler, this);
		// testing
		//m_UpgradeInventory.SignalItemAdded.Disconnect(ItemsChanged, this)
		//m_UpgradeInventory.SignalItemMoved.Disconnect(ItemsChanged, this)
		//m_UpgradeInventory.SignalItemRemoved.Disconnect(ItemsChanged, this)
		//m_UpgradeInventory.SignalItemStatChanged.Disconnect(ItemStatChanged, this)
		
	}
	
	public function Activate(config: Archive) {
		// Some example code for loading variables from an Archive
		//var testVariable: String = String(config.FindEntry("MyTestVariableToStore", "Not found"));
		//var testVariableNumber: Number = Number(config.FindEntry("MyTestVariableNumberToStore", 15));
	}
	
	public function Deactivate(): Archive {
		// Some example code for saving variables to an Archive
		var archive: Archive = new Archive();	
		//archive.AddEntry("MyTestVariableToStore", "Hello");
		
		return archive;
	}
	
	
	
	
	/////////////////////////////////
	//////// EVENT HANDLING /////////
	/////////////////////////////////
	
	private function EmpowermentWindowUpdateHandler(result:Number, numItems:Number, feedback:String, items:Array, percentChance:Number) {
		
		DebugMsg("---EWUH----")
		DebugMsg("result: " + string(result))
		DebugMsg("feedback: " + feedback)
		DebugDataDump();
		
		if (result == 7 ) {
			// this is the flag for moving items around. Every time we do this, we want to 
			// flush the persistent data and refresh it
			FlushPersistantEmpowermentData();
			NumFodderItems = GetUsedEmpowermentSlotData();		
			UpdateItemXPData(items, result);
		} 
		else if (result == 9) {		
			// this is the flag for a completed empowerment. We don't want to flush old data here,
			// we just want to get the XP for the completed item from UpdateItemXPData and then
			// write the result to the log file
			UpdateItemXPData(items, result);	
			WriteEmpowermentResult();			
		}
	}
	
	private function WriteEmpowermentResult():Void {
		
		var actualXP:Number = 0;
		var StartXP:Number;
		var EndXP:Number;
		var FodderXP:Number = 0;
		var CritResult:String = "";
		
		//start by assuming it was a weapon/talisman upgrade
		actualXP = ( StartXP_Talisman - EndXP_Talisman );
		StartXP = StartXP_Talisman;
		EndXP = EndXP_Talisman;
		
		//if it wasn't a talisman, actualXP will be zero. If so, check for glyph upgrade.
		if ( actualXP <= 0 ) { 
			actualXP = ( StartXP_Glyph - EndXP_Glyph ); 
			StartXP = StartXP_Glyph;
			EndXP = EndXP_Glyph;
			EmpoweredItemType = "Glyph"; 			
		}
		//likewise, if it wasn't a glyph, actualXP will still be zero, and it was a signet
		if ( actualXP <= 0 ) { 
			actualXP = ( StartXP_Signet - EndXP_Signet ); 
			StartXP = StartXP_Signet;
			EndXP = EndXP_Signet;
			EmpoweredItemType = "Signet"; 
		}
		
		// Check for Fodder when upgrading glyphs/signets inside of a weapon/talisman
		// In this case FodderXP_Base will be zero, but one of the embedded values will be nonzero
		if ( FodderXP_Base<= 0 && FodderXP_EmbeddedGlyph > 0 ) {
			FodderXP = FodderXP_EmbeddedGlyph;
		} else if ( FodderXP_Base <= 0 && FodderXP_EmbeddedSignet > 0 ) {
			FodderXP = FodderXP_EmbeddedSignet;
		} else {
			FodderXP = FodderXP_Base;
		}

		//now we have to be careful. Since we don't have direct feedback on whether an empowerment
		//was crit or not, we have to get it from data. Unfortunately, if we max an item out, 
		//EndXP will be zero (but we catch it with -1), and this becomes difficult. So handle that special case first:
		
		if ( EndXP <= 0 ) {
			if ( actualXP > ( FodderXP + 1 ) ) {
				// if actualXP > FodderXP + 1, then we know we crit, so we can keep that
				actualXP -= 1; //subtract 1 since EndXP=-1 if we max out an item
				CritResult = "Y";
			}
			else {
				// bust. We can't tell if this crit or not. We can dump the data, but label it as an unknown result
				CritResult = "?";
			}
		}
		else {
			CritResult = (actualXP > ( FodderXP + 1 ) ) ? "Y" : "N";  
			// I don't think +1 is needed here, since this should never trigger in that situation... but it doesn't hurt so...
		}
		
		var outputStr:String = "";
				
		outputStr += EmpoweredItemType + ",";
		outputStr += string(StartXP) + "," ;
		outputStr += string(NumFodderItems) + ",";
		outputStr += string(FodderItemQuality) + ",";
		outputStr += string(FodderXP) + ",";
		outputStr += string(EndXP) + ",";
		outputStr += string(actualXP) + ",";
		outputStr += CritResult;
		
		DebugMsg("----Results----")
		DebugDataDump();
		PrintChatText("--Results: " + outputStr);
		
		// dump the output to the ClientLog.txt file
		Log.Error("EmpDataLoggerDump", outputStr);
		
		// Flush data again, this fixes some weird issues with upgrading socketed glyphs to max followed by fusion and another upgrade
		FlushPersistantEmpowermentData();
	}
	
	private function ItemsChanged(inventoryID:com.Utils.ID32, itemPos:Number) {
		// Testing
		DebugMsg("---ItemsChanged Fired---")
		//FlushPersistantEmpowermentData();
	}
	
	private function ItemStatChanged( inventoryID:com.Utils.ID32, itemPos:Number, stat:Number, newValue:Number){
		// Testing
		DebugMsg("---ItemStatChanged Fired---")
		DebugMsg("stat: " + string(stat))
		DebugMsg("newValue: " + string(newValue))
	}
	
	
	///////////////////////////////////////
	//////// ITEM DATA MANAGEMENT /////////
	///////////////////////////////////////
	
	private function FlushPersistantEmpowermentData():Void {
		StartXP_Talisman = -1;
		StartXP_Glyph = -1;
		StartXP_Signet = -1;
		EndXP_Talisman = -1;
		EndXP_Glyph = -1;
		EndXP_Signet = -1;
		EmpoweredItemType = "";
		FodderItemQuality = "";
		NumFodderItems = -1;
		FodderXP_Base = -1;
		FodderXP_EmbeddedGlyph = -1;
		FodderXP_EmbeddedSignet = -1;
	}
	
	function GetUsedEmpowermentSlots():Number {
        var usedslots:Number = 0;
		
		for (var i = EMPOWER_SLOT_0; i <= EMPOWER_SLOT_4; i++)
        { 
            if (m_UpgradeInventory.GetItemAt(i)) usedslots++;
		}
        return usedslots;
	}
	
	function GetUsedEmpowermentSlotData():Number {
        var usedslots:Number = 0;
		var m_FodderItemTemp:InventoryItem;
		
		var ItemType:Number = -1;
		var Pips:Number = -1;
				        
		for (var i = EMPOWER_SLOT_0; i <= EMPOWER_SLOT_4; i++)
        { 
			m_FodderItemTemp = m_UpgradeInventory.GetItemAt(i);
            if (m_FodderItemTemp) {
				usedslots++;
				if (ItemType < 0 ) {
					ItemType = m_FodderItemTemp.m_ItemType;
					Pips = m_FodderItemTemp.m_Pips;
				} 
				else if ( ItemType != m_FodderItemTemp.m_ItemType || Pips != m_FodderItemTemp.m_Pips ) FodderItemQuality = "M"; 
				
				//DebugMsg("Slot " + string(i) + " pips: " + string(m_FodderItemTemp.m_Pips) + " itemType: " +  string(m_FodderItemTemp.m_ItemType) + " itemTypeGUI: " +  string(m_FodderItemTemp.m_ItemTypeGUI) );
			}
        }
		if ( FodderItemQuality != "M" ) {
			if ( Pips > 0 ) FodderItemQuality = string( Pips );
			else if ( ItemType == 3 ) FodderItemQuality = "D";
			else if (ItemType == 0 ) FodderItemQuality = "S";
			else FodderItemQuality = "????";
		}
        return usedslots;
}
	
	private function UpdateItemXPData(items:Array, result:Number):Void {
	
		// A large chunk of this code was copy/pasted from maXPert.as. 
		// I've stripped out all of the unnecessary stuff and added result checking since this function is used for two purposes
		
		var m_ResultItem:InventoryItem = items[0];
		var m_StartItem:InventoryItem = InventoryItem(m_UpgradeInventory.GetItemAt(0));
		if (m_ResultItem) resultItemID = CreateID(m_ResultItem);
		else resultItemID = CreateID(m_StartItem);
		
		if (m_StartItem) {
			//checking if the item has glyph or signet slotted
			var GlyphSlotted = m_StartItem.m_ACGItem.m_TemplateID1;
			var SignetSlotted = m_StartItem.m_ACGItem.m_TemplateID2;
		//MAIN SLOT
			// If is NOT Glyph or Signet
			if (m_StartItem.m_RealType != 30129 && m_StartItem.m_RealType != 30133) {
				var MaxLevel:Number;
				//Hardcoded maxlevel, change if patched
				switch (m_StartItem.m_Rarity) {
					case 2:
						MaxLevel = 20;
						break
					case 3:
						MaxLevel = 25;
						break
					case 4:
						MaxLevel = 30;
						break
					case 5:
						MaxLevel = 35;
						break
					case 6:
						MaxLevel = 70;
						break
				}
								
				switch (m_StartItem.m_RealType ) {
					case 30104:
					case 30106:
					case 30107:
					case 30118:
					case 30112:
					case 30110:
					case 30111:
					case 30100:
					case 30101:
						EmpoweredItemType = "Weapon";
						break
					case 30131:
						EmpoweredItemType = "Talisman";
						break
				}
				
				if (MaxLevel && m_StartItem.m_Rank != MaxLevel) {
					var XpToNextRarity = Inventory.GetItemXPForLevel(m_StartItem.m_RealType, m_StartItem.m_Rarity, MaxLevel);
					
					if (result != 9 ) {
						StartXP_Talisman = XpToNextRarity - m_StartItem.m_XP;
					} 
					else {
						EndXP_Talisman = XpToNextRarity - m_StartItem.m_XP;
					}
					
					if (m_ResultItem) {
						FodderXP_Base= m_ResultItem.m_XP - m_StartItem.m_XP;
					}
				}
			}
			
			// else if Glyph
			else if (m_StartItem.m_RealType == 30129 && m_StartItem.m_Rank != 20) {
				EmpoweredItemType = "Glyph";
				var XpToNextRarity = Inventory.GetItemXPForLevel(30129, m_StartItem.m_GlyphRarity, 20);
				
					if (result != 9 ) {
						StartXP_Glyph = XpToNextRarity - m_StartItem.m_GlyphXP;
					}
					else {
						EndXP_Glyph = XpToNextRarity - m_StartItem.m_GlyphXP;
					}
				if (m_ResultItem) {
					FodderXP_Base= m_ResultItem.m_XP - m_StartItem.m_XP;
				}				
			}
			
			// else if Signet
			else if (m_StartItem.m_RealType == 30133 && m_StartItem.m_Rank != 20) {
				EmpoweredItemType = "Signet";
				var XpToNextRarity = Inventory.GetItemXPForLevel(30133, m_StartItem.m_SignetRarity, 20);				
				
				if ( result != 9 ) { 
					StartXP_Signet = XpToNextRarity - m_StartItem.m_SignetXP; 					
				}
				else {
					EndXP_Signet = XpToNextRarity - m_StartItem.m_SignetXP;
				}
				if (m_ResultItem) {
					FodderXP_Base= m_ResultItem.m_SignetXP - m_StartItem.m_SignetXP;
				}
			}
		//MAIN SLOT END
		//GLYPH SLOT START
			//if current item
			//a) Has a glyph slotted
			//b) Is not a glyph or signet(Handled by MAIN)
			if (GlyphSlotted && m_StartItem.m_RealType != 30133 && m_StartItem.m_RealType != 30129 && m_StartItem.m_GlyphRank != 20) {
				var XpToNextRarity = Inventory.GetItemXPForLevel(30129, m_StartItem.m_GlyphRarity, 20);
				
				if (result != 9 ) {
					StartXP_Glyph = XpToNextRarity - m_StartItem.m_GlyphXP;
				}
				else {
					EndXP_Glyph = XpToNextRarity - m_StartItem.m_GlyphXP;
				}
					
				if (m_ResultItem) {
					// this needs to be stored separately so it doesn't overwrite FodderXP for the main slot
					FodderXP_EmbeddedGlyph = m_ResultItem.m_GlyphXP - m_StartItem.m_GlyphXP;
				}
			}
		//GLYPH SLOT END
		//SIGNET SLOT START
			// Return if upgrade item is a weapon,as weapon signets should be ignored
			switch (m_StartItem.m_RealType) {
				case 30104:
				case 30106:
				case 30107:
				case 30118:
				case 30112:
				case 30110:
				case 30111:
				case 30100:
				case 30101:
					DebugMsg("--- UpdateItemXP 1 ---")
					DebugDataDump();
					return;
			}
			//if current item
			//a) is not a signet or glyph(Handled by MAIN)
			//b) has a signet slotted
			if (SignetSlotted && m_StartItem.m_RealType != 30133 && m_StartItem.m_RealType != 30129 && m_StartItem.m_SignetRank!=20) {
				var XpToNextRarity = Inventory.GetItemXPForLevel(30133, m_StartItem.m_SignetRarity, 20);
				
				if (result != 9 ) {
					StartXP_Signet = XpToNextRarity - m_StartItem.m_SignetXP;
				}
				else {
					EndXP_Signet = XpToNextRarity - m_StartItem.m_SignetXP;
				}				
				if (m_ResultItem) {
					// this needs to be stored separately so it doesn't overwrite FodderXP for the main weapon
					FodderXP_EmbeddedSignet = m_ResultItem.m_SignetXP - m_StartItem.m_SignetXP;
				}
			}
		//SIGNET SLOT END
		
		}
		DebugMsg("--- UpdateItemXP 2 ---")
		DebugDataDump();
		
	}
	//End UpdateItemXPData
	
	//////////////////////////
	//////// UTILITY /////////
	//////////////////////////
	
	private function CreateID(Item:InventoryItem){
		if(Item) return string(Item.m_ACGItem.m_TemplateID0) + Item.m_ACGItem.m_TemplateID1 + Item.m_ACGItem.m_TemplateID2 + Item.m_XP;
	}
	
	private function DebugMsg(message:String): Void {
		if ( debug ) { 
			com.GameInterface.UtilsBase.PrintChatText(message);
		}
	}
	
	private function PrintChatText(message:String): Void {
		com.GameInterface.UtilsBase.PrintChatText(message);
	}
	
	private function DebugDataDump(){
		// now crib the data we want
		DebugMsg("-------Data-------");
		DebugMsg("EmpoweredItemType: " + string(EmpoweredItemType) );
		DebugMsg("Start XP T: " + string(StartXP_Talisman) + "  G: " + string(StartXP_Glyph) + "  S: " + string(StartXP_Signet));
		DebugMsg("NumFodderItems: " + string(NumFodderItems) );
		DebugMsg("FodderItemQuality: " + string(FodderItemQuality) );
		DebugMsg("Fodder XP: " + string(Math.max(FodderXP_Base, FodderXP_EmbeddedGlyph, FodderXP_EmbeddedSignet) ) );
		DebugMsg("End XP T: " + string(EndXP_Talisman) + "  G: " + string(EndXP_Glyph) + "  S: " + string(EndXP_Signet));
	}

}