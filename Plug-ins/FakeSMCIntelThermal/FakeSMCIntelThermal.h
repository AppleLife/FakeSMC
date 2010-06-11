/* *  FakeSMCIntelThermal.h *  FakeSMCIntelThermal * *  Created by mozodojo on 18/05/10. *  Copyright 2010 mozodojo. All rights reserved. * */#include <IOKit/IOService.h>#include "IntelThermalPlugin.h"class FakeSMCIntelThermal : public IOService{    OSDeclareDefaultStructors(FakeSMCIntelThermal)    private:	IntelThermalPlugin* plugin;public:	virtual IOService*	probe(IOService *provider, SInt32 *score);    virtual bool		start(IOService *provider);	virtual bool		init(OSDictionary *properties=0);	virtual void		free(void);	virtual void		stop(IOService *provider);};