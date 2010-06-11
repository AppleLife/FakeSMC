/*
 *  FakeSMCPlugin.h
 *  fakesmc
 *
 *  Created by Mozodojo on 11/06/10.
 *  Copyright 2010 mozodojo. All rights reserved.
 *
 */

#ifndef FAKESMCPLUGIN_H
#define FAKESMCPLUGIN_H

#define DebugOn FALSE

#define LogPrefix "FakeSMCSuperIOMonitor: "
#define DebugLog(string, args...)	do { if (DebugOn) { IOLog (LogPrefix "[Debug] " string "\n", ## args); } } while(0)
#define WarningLog(string, args...) do { IOLog (LogPrefix "[Warning] " string "\n", ## args); } while(0)
#define InfoLog(string, args...)	do { IOLog (LogPrefix string "\n", ## args); } while(0)

class FakeSMCPlugin 
{
public:
	virtual void OnKeyRead(const char* key, char* data);
	virtual void OnKeyWrite(const char* key, char* data);
};

void FakeSMCAddKey (const char*, uint8_t, char*);
void FakeSMCAddKey (const char*, const char*, uint8_t, char*);
void FakeSMCAddKey (const char*, uint8_t, char*, FakeSMCPlugin*);
void FakeSMCAddKey (const char*, const char*, uint8_t, char*, FakeSMCPlugin*);
char* FakeSMCReadKey (const char*);
void FakeSMCRemoveKeyBinding (const char*);

inline bool CompareKeys(const char* key1, const char* key2)
{
	return ((key1[0] == key2[0]) && (key1[1] == key2[1]) && (key1[2] == key2[2]) && (key1[3] == key2[3]));
}

inline UInt8 GetFNum()
{
	char* data = FakeSMCReadKey("FNum");
	
	if(data != NULL)
	{
		return data[0];
	}
	
	return 0;
}

inline void UpdateFNum(UInt8 valueToAdd)
{
	char* data = FakeSMCReadKey("FNum");
	
	if(data == NULL)
	{
		char data[1];
		
		data[0] = valueToAdd;
		FakeSMCAddKey("FNum", 1, data);
		
		return;
	}
	else
	{
		UInt8 oldValue = data[0];
		
		data[0] = oldValue + valueToAdd;
	}
}

#endif