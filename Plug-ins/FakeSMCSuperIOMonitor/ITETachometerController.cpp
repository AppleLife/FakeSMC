/*
 *  ITETachometerController.cpp
 *  FakeSMCSuperIOMonitor
 *
 *  Created by Mozodojo on 13/06/10.
 *  Copyright 2010 mozodojo. All rights reserved.
 *
 */

#include "ITETachometerController.h"

void ITETachometerController::ForcePWM(UInt8 slope)
{
	DebugLog("Forcing Fan #%d SLOPE=0x%x", m_Offset, slope);
	
	outb(m_Address+ITE_ADDRESS_REGISTER_OFFSET, ITE_FAN_FORCE_PWM_REG[m_Offset]);
	outb(m_Address+ITE_DATA_REGISTER_OFFSET, slope);
}

void ITETachometerController::Initialize()
{
	bool* valid;
	
	//Back up temperature sensor selection
	m_Default = ITE_ReadByte(m_Address, ITE_FAN_FORCE_PWM_REG[m_Offset], valid);
	
	if (valid)
	{
		char tmpKey[5];
		char value[2];
		
		UInt16 initial = m_Maximum = ITE_ReadTachometer(m_Address, m_Offset, valid);
		
		//Forcing maximum speed
		ForcePWM(0x7f);
		
		UInt16 last = initial, count = 0;
		
		//Waiting cooler will speed up to maximum
		while (count < 5)
		{
			IOSleep(1000);
			
			m_Maximum = ITE_ReadTachometer(m_Address, m_Offset, valid);
			
			if (m_Maximum < last + 50)
			{
				count++;
			}
			else 
			{
				last = m_Maximum;
			}
		};
	
		//Restore temperature sensor selection
		ForcePWM(m_Default);
			
		m_Maximum = m_Maximum / 50 * 50;
		
		DebugLog("Fan #%d MAX=%drpm", m_Offset, m_Maximum);
		
		value[0] = (m_Maximum << 2) >> 8;
		value[1] = (m_Maximum << 2) & 0xff;
				
		snprintf(tmpKey, 5, "F%dMx", m_Index);
		FakeSMCAddKey(tmpKey, "fpe2", 2, value);
		
		initial = initial / 50 * 50;
		
		value[0] = (initial << 2) >> 8;
		value[1] = (initial << 2) & 0xff;
		
		snprintf(tmpKey, 5, "F%dTg", m_Index);
		FakeSMCAddKey(tmpKey, "fpe2", 2, value);
				
		if (m_Maximum > initial + 50)
		{
			value[0] = 0;//(initial << 2) >> 8;
			value[1] = 0;//(initial << 2) & 0xff;
					
			m_Key = (char*)IOMalloc(5);
			snprintf(m_Key, 5, "F%dMn", m_Index);
					
			InfoLog("Binding key %s", m_Key);
					
			FakeSMCAddKey(m_Key, "fpe2", 2, value, this);
		}
		else 
		{
			value[0] = (initial << 2) >> 8;
			value[1] = (initial << 2) & 0xff;
			
			m_Key = (char*)IOMalloc(5);
			snprintf(m_Key, 5, "F%dMn", m_Index);
			
			FakeSMCAddKey(m_Key, "fpe2", 2, value);
		}
	}	
}

void ITETachometerController::OnKeyRead(__unused const char* key, __unused char* data)
{
}

void ITETachometerController::OnKeyWrite(__unused const char* key, char* data)
{
	UInt16 hi = data[0] << 6;
	UInt16 lo = data[1] >> 2;
	UInt16 rpm = hi | lo;
	
	if (rpm <= m_Maximum)
	{
		UInt8 slope = (rpm * 0x7f) / m_Maximum;
			
		if (slope == 0)
		{
			ForcePWM(m_Default);
		}
		else 
		{
			DebugLog("Fan #%d SLOPE=0x%x RPM=%drpm", m_Offset, slope, rpm);
				
			outb(m_Address + ITE_ADDRESS_REGISTER_OFFSET, ITE_START_PWM_VALUE_REG[m_Offset]);
			outb(m_Address + ITE_DATA_REGISTER_OFFSET, slope);
		}
	}
}