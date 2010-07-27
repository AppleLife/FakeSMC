/*
 *  ATICard.h
 *  FakeSMCRadeon
 *
 *  Created by Slice on 24.07.10.
 *  Copyright 2010 Applelife.ru. All rights reserved.
 *
 */

#ifndef _ATICARD_H 
#define _ATICARD_H

#include <IOKit/IOService.h>
#include <IOKit/pci/IOPCIDevice.h>
#include "FakeSMCBinding.h"
#include "radeon_chipsets.h"

#define GPU_OVERCLOCKING (1<<0)
#define MEM_OVERCLOCKING (1<<1)
#define COOLBITS_OVERCLOCKING (1<<2)
#define PIPELINE_MODDING (1<<3)
#define GPU_FANSPEED_MONITORING (1<<4) /* Fanspeed monitoring based on fan voltage */
#define BOARD_TEMP_MONITORING (1<<5) /* Board temperature */
#define GPU_TEMP_MONITORING (1<<6) /* Internal GPU temperature */
#define I2C_FANSPEED_MONITORING (1<<7) /* Fanspeed monitoring using a i2c sensor chip */
#define I2C_AUTOMATIC_FANSPEED_CONTROL (1<<8) /* The sensor supports automatic fanspeed control */
#define SMARTDIMMER (1<<9) /* Smartdimmer support for mobile GPUs */
#define GPU_ID_MODDING (1<<10) /* PCI id modding is supported on this board */


#define INVID8(offset) (mmio_base[offset])
#define INVID16(offset) OSReadLittleInt16((mmio_base), offset)
#define INVID(offset) OSReadLittleInt32((mmio_base), offset)
#define OUTVID(offset,val) OSWriteLittleInt32((mmio_base), offset, val)

class ATICard : public FakeSMCBinding
{
public:
	UInt32			chipID;
	UInt16			family;
	IOPCIDevice *	VCard;
	
private:
	volatile UInt8* mmio_base;
	IOMemoryMap *	mmio;
	RADEONCardInfo*	rinfo;
	UInt32			Caps;
	UInt32			tReg;
	int				card_number;
	
//	Binding*			m_Sensor;
//	Binding*			m_Controller;  //todo
	
//	void			FlushList(Binding* start);	
	void			getRadeonInfo	();
//	void			setup_R5xx		();  //todo
	void			setup_R6xx		();
	void			setup_R7xx		();
	void			setup_Evergreen	();
		
protected:
//	IOService*		m_Service;  //???
public:
	Binding* tempSensor;
	Binding* boardSensor;
	Binding* fanSensor;  
	UInt32			read32			(UInt32 reg);
	bool			initialize		(void);
	
};


#endif