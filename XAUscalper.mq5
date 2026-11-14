#property strict
#property version   "1.10"
#property copyright "XAUscalper"
#property description "XAUscalper - gold scalping engine"

#define XS_BG      C'10,12,16'
#define XS_SHADOW  C'3,4,6'
#define XS_PANEL   C'17,20,27'
#define XS_TILE    C'24,28,38'
#define XS_TILE2   C'30,35,47'
#define XS_EDGE    C'46,54,70'
#define XS_TEXT    C'234,238,245'
#define XS_MUTED   C'128,138,156'
#define XS_GOLD    C'255,184,28'
#define XS_CYAN    C'56,214,255'
#define XS_GREEN   C'70,222,140'
#define XS_RED     C'255,86,86'
#define XS_AMBER   C'255,150,50'
#include <Generic/HashMap.mqh>





enum MDProtectionMode
{
   MDProtection_Broker=0, // Broker trailing only; ProfitLock is a separate switch
   MDProtection_Combined=1, // Moving broker SL + virtual profit protection
   MDProtection_VirtualOnly=2 // Fixed safety SL + virtual protection [recommended]
};

enum MDLockProfile
{
   MDLock_Classic=0, // Classic 50%: immediate ProfitLock [no Spike Shield]
   MDLock_ClassicShield=1, // Classic 50% + Spike Shield [default]
   MDLock_Gradual=2, // Gradual 35% -> 50% [no Spike Shield]
   MDLock_GradualShield=3 // Gradual 35% -> 50% + Spike Shield
};

enum MDSizingMode
{
   MDSizing_Fixed=0, // Fixed lot size
   MDSizing_Risk1=1, // Risk 1% of balance per trade
   MDSizing_Risk2=2, // Risk 2% of balance per trade
   MDSizing_Custom=3, // Custom risk percentage per trade
   MDSizing_Growth=4, // Growth: 1% risk, minimum 0.01 lot
   MDSizing_Auto=5 // AUTO: tester 2% / live fixed lot [default 0.01]
};

enum MDAiTradingMode
{
   MDAi_Off=0, // Without AI: base strategies, no AI filter
   MDAi_Conservative=1, // 2x AI Conservative: H1 pending recheck [default]
   MDAi_MoreTrades=2 // 2x AI More Trades: no H1 pending recheck
};

enum MDQuickSetup
{
   MDSetup_Default=0, // SET 1: five modules, 20-pip SL, classic 50% ProfitLock
   MDSetup_ModuleLocks=1, // SET 2: five modules, 20-pip SL, module-specific ProfitLock
   MDSetup_AllNine=2, // SET 3: all nine modules, 20-pip SL, classic 50% ProfitLock
   MDSetup_AllNineModuleLocks=3, // SET 4: all nine modules, 20-pip SL, module-specific ProfitLock
   MDSetup_Advanced=4 // Advanced: use the individual module and tuning switches below
};

enum MDAdaptiveSizeMode
{
   MDAdaptive_Normal=0, // Normal lot size
   MDAdaptive_Boost=1 // Base risk or 1.5x risk [AI + % risk only]
};

enum MDPropDrawdownMode
{
   MDPropDrawdown_Fixed=0, // Fixed reference: initial balance
   MDPropDrawdown_HighestBalance=1, // Moving reference: highest balance
   MDPropDrawdown_HighestEquity=2 // Moving reference: highest equity
};

enum MDPropDailyBaseline
{
   MDPropBaseline_Balance=0, // Balance at daily reset
   MDPropBaseline_Equity=1 // Equity at daily reset
};

enum MDPropDailyLossAmount
{
   MDPropDailyAmount_Initial=0, // Percent of initial balance
   MDPropDailyAmount_DailyReference=1 // Percent of daily reference
};

enum MDPropTrailingAmount
{
   MDPropTrailing_Fixed=0, // Fixed amount from initial balance
   MDPropTrailing_PeakPercent=1 // Percentage of the highest reference
};

enum MDWeekendScheduleMode
{
   MDWeekend_Automatic=0, // Automatic: use broker trading sessions
   MDWeekend_Custom=1 // Custom: my Friday and Monday broker times
};


input group "License"
input string LicenseKey=""; // License key

input group "Lot size"
input MDSizingMode LotMode=MDSizing_Auto; // Lot mode
input double FixedLot=0.01; // Fixed lot
input double RiskPercent=2.0; // Risk per trade [%, custom risk mode]
input double MaximumRiskLot=0.0; // Maximum lot for % risk [0 = no cap]

input group "Identity"
input int MagicNumber=33300; // Magic number
input string CommentText="XAUscalper"; // Order comment

// ---- internal settings (fixed, not user inputs) ----
const MDQuickSetup XSQuickSetup=MDSetup_Default;
const MDAiTradingMode AiTradingMode=MDAi_Conservative;
const MDAdaptiveSizeMode AdaptivePositionSize=MDAdaptive_Normal;
const double XSStopLossPips=20.0;
const MDProtectionMode XSProtectionMode=MDProtection_VirtualOnly;
const bool PersistVirtualTrailing=true;
const bool XSLockEnabled=true;
const double XSLockStartPer001=1.0;
const MDLockProfile XSLockProfile=MDLock_ClassicShield;
const double XSLockPercent=50.0;
const bool UseCustomBreakEvenTrailing=false;
const double CustomBreakEvenStartPips=10.0;
const double CustomBreakEvenLockPips=1.0;
const double CustomTrailingStartPips=20.0;
const double CustomTrailingDistancePips=10.0;
const double CustomTrailingStepPips=2.0;
const double XSTargetS2Pips=140.0;
const double XSCoreTargetPips=150.0;
const bool XSEnableS1=true;
const bool XSEnableS2=true;
const bool XSEnableS3=true;
const bool XSEnableS4=true;
const bool XSEnableS5=true;
const bool UsePerModuleTunedExits=true;
const bool XSAddOnA=false;
const bool XSAddOnB=false;
const bool XSAddOnC=false;
const bool XSAddOnD=false;
const int MaxSameDirectionPositions=8;
const bool AllowNettingAccount=false;
const int PreviousXSTradeIdentityBase=0;
const int PreviousXSTradeIdentity=0;
const bool UseTradingHours=false;
const int TradingStartHour=2;
const int TradingStartMinute=0;
const int TradingEndHour=19;
const int TradingEndMinute=0;
const bool DeletePendingOutsideHours=false;
const bool WeekendShieldEnabled=true;
const MDWeekendScheduleMode WeekendScheduleMode=MDWeekend_Automatic;
const int WeekendFridayCutoffMinutes=240;
const int WeekendReopenDelayMinutes=240;
const int WeekendFallbackFridayHour=20;
const int WeekendFallbackMondayHour=5;
const int WeekendCustomFridayHour=20;
const int WeekendCustomFridayMinute=0;
const int WeekendCustomMondayHour=5;
const int WeekendCustomMondayMinute=0;
const string NewsCurrency="USD";
const bool UseMajorEventControl=true;
const bool TradeDuringNFP=false;
const int NFPMinutesBefore=30;
const int NFPMinutesAfter=60;
const bool TradeDuringCPI=false;
const int CPIMinutesBefore=30;
const int CPIMinutesAfter=60;
const bool TradeDuringFOMC=false;
const int FOMCMinutesBefore=60;
const int FOMCMinutesAfter=150;
const bool XSCalendarShieldEnabled=false;
const bool FilterHighImpactNews=true;
const bool FilterModerateImpactNews=false;
const int NewsMinutesBefore=60;
const int NewsMinutesAfter=30;
const bool DeletePendingBeforeNews=true;
const bool NewsFailClosed=false;
const bool UseBuiltInMajorNewsBackup=true;
const bool WideSpreadProtectionEnabled=false;
const double WideSpreadMaxPoints=200.0;
const bool NormalDailyLimitEnabled=false;
const double NormalMaxDailyLossPercent=20.0;
const bool NormalDailyClosePositions=true;
const bool NormalDailyDeletePendings=true;
const string NormalDailyProtectionId="MAIN";
const bool PropFirmActive=false;
const string PropFirmChallengeId="MAIN";
const double PropFirmStartingBalance=0.0;
const double PropFirmProfitTargetPercent=8.0;
const double PropFirmMaxDailyLossPercent=5.0;
const double PropFirmMaxTotalDrawdownPercent=10.0;
const double PropFirmSafetyBufferPercent=0.5;
const bool PropFirmStopAtProfitTarget=true;
const bool PropFirmDeletePendingsWhenBlocked=true;
const bool PropFirmClosePositionsOnLimit=true;
const bool PropFirmClosePositionsAtTarget=false;
const MDPropDrawdownMode PropFirmDrawdownMode=MDPropDrawdown_Fixed;
const MDPropDailyBaseline PropFirmDailyBaseline=MDPropBaseline_Equity;
const MDPropDailyLossAmount PropFirmDailyLossAmount=MDPropDailyAmount_Initial;
const MDPropTrailingAmount PropFirmTrailingAmount=MDPropTrailing_Fixed;
const int PropFirmDailyResetHour=0;
const int PropFirmDailyResetMinute=0;
const int PropFirmMaximumExposureSlots=0;
const bool LotScalingEnabled=false;
const double LotScalingBaseBalance=0.0;
const double LotScalingBalanceStep=500.0;
const double LotScalingLotStep=0.01;
const double LotScalingMaxLot=0.03;
const bool LotScalingUseEquity=false;
const bool LotScalingOnlyUp=false;
const bool LotScalingPersistState=true;
const string LotScalingStateId="MAIN";
const bool AppendModuleToComment=false;
const bool PropFirmBlankOrderComment=false;
const bool ShowExecutionComparison=false;
const int ExecutionMinimumTrades=10;
const double ExecutionExcellentMax=0.05;
const double ExecutionGoodMax=0.15;
const double ExecutionNormalMax=0.35;
const double ExecutionPoorMax=0.75;
const bool XSDashboardVisible=true;
const double XSDashboardScale=1.0;
const bool ShowLaunchSplash=true;
const int LaunchSplashSeconds=3;
const bool FastBacktest=true;
const bool LocalLearningLogEnabled=false;







struct MDStrategyConfig
{
   int moduleIndex;
   string name;
   int strategyId;
   int coreSlot;
   ENUM_TIMEFRAMES pivotTimeframe;
   ENUM_TIMEFRAMES triggerTimeframe;
   int olderBars;
   int newerBars;
   int searchDepth;
   double minPivotDistance;
   double buyOffset;
   double sellOffset;
   int pendingLimit;
   double pendingSpacing;
   int expiryHours;
   double targetDistance;
   double protectionCoefficients[7];
   int protectionSelectors[4];
   double protectionThreshold;
   int positionLimit;
   double referencePrice;
   double protectionDistance;
   double stopDistance;
   double lockStart;
   double lockPercent;
   double primaryThreshold;
   double consensusThreshold;
   double priceScale;
};

struct MDPendingGeometry
{
   int moduleIndex;
   int coreSlot;
   bool buy;
   double pivotPrice;
   double entryPrice;
   double stopLoss;
   double takeProfit;
   datetime signalTime;
   datetime nominalExpiration;
   double primaryThreshold;
   double consensusThreshold;
};

bool MDStrategyEnabled(const int module,const int quickSetup,const bool &enabled[])
{
   if(module<0 || module>8) return false;
   if(quickSetup==4) return module<ArraySize(enabled) && enabled[module];
   return module<5 || quickSetup==2 || quickSetup==3;
}

int MDCurrentMagicModule(const long magic,const long currentBase,
                         const int quickSetup,const bool &enabled[])
{
   long identity=magic-currentBase;
   if(identity>=1 && identity<=5) return (int)identity-1;
   if(identity<6 || identity>9) return -1;
   int module=(int)identity-1;
   return MDStrategyEnabled(module,quickSetup,enabled) ? module : -1;
}

int MDRecognizeMagic(const long magic,const long currentBase,const int previousBase,
                     const int legacyBase,const int quickSetup,const bool &enabled[])
{
   int module=MDCurrentMagicModule(magic,currentBase,quickSetup,enabled);
   if(module>=0) return module;
   long identity=magic-(long)previousBase;
   if(previousBase>0 && identity>=1 && identity<=5) return (int)identity-1;
   if(legacyBase<=0) return -1;
   identity=magic-(long)legacyBase;
   if(identity<9 || identity>15) return -1;
   switch((int)identity)
   {
      case 9:  return 1;
      case 12: return 0;
      case 13: return 4;
      case 14: return 2;
      case 15: return 3;
   }
   return -1;
}

bool MDMatchesCurrentMagic(const long actualMagic,const long requestedMagic,
                          const long currentBase,const int quickSetup,
                          const bool &enabled[])
{
   int wanted=MDCurrentMagicModule(requestedMagic,currentBase,quickSetup,enabled);
   return wanted>=0 && MDCurrentMagicModule(actualMagic,currentBase,quickSetup,enabled)==wanted;
}

bool MDLoadStrategyConfig(const int module,const int quickSetup,const bool tunedExits,
                         const double stopLossPips,const double targetS2Pips,
                         const double coreTargetPips,const double globalLockStart,
                         const double globalLockPercent,const double primaryThreshold,
                         const double consensusThreshold,MDStrategyConfig &config)
{
   if(module<0 || module>8) return false;
   const string names[9]={"S1","S2","S3","S4","S5","S6","S7","S8","S9"};
   const int pivotTf[9]={16385,16385,16385,16385,16385,30,16385,16388,16385};
   const int triggerTf[9]={15,5,15,15,15,15,15,5,5};
   const int older[9]={30,26,25,26,7,18,25,5,5};
   const int newer[9]={19,24,23,20,5,5,5,2,18};
   const int depth[9]={110,140,145,235,200,120,120,120,200};
   const double distance[9]={160,120,10,80,40,300,80,80,0};
   const double buyOffset[9]={-120,-115,-60,-140,-150,-50,-100,50,-150};
   const double sellOffset[9]={-110,-145,-145,-170,-145,50,-100,-150,-150};
   const int batches[9]={3,5,5,5,3,3,3,5,3};
   const double spacing[9]={55,55,90,5,5,55,55,55,55};
   const int expiry[9]={30,20,60,55,15,30,30,15,60};
   const int positions[9]={99,5,5,20,99,99,99,99,99};
   const double referencePrice[9]={2600,2400,2600,2800,1900,2600,2600,2600,2600};
   const double protectionDistance[9]={110,140,90,130,700,110,110,110,110};
   const int slots[9]={0,1,2,3,4,0,3,3,3};
   const double tunedStops[9]={300,250,250,200,200,300,300,300,300};
   const double tunedStarts[9]={1.25,0.75,0.5,0.75,1.0,0.5,1.25,1.25,1.25};
   const double tunedLocks[9]={40,50,30,50,50,50,40,40,40};
   const double tunedConsensus[9]={0.53,0.53,0.56,0.53,0.53,0.56,0.53,0.56,0.56};
   const double coefficients[9][7]={
      {495,400,5000,1900,250,260,80},
      {500,1200,5000,1950,350,330,80},
      {450,900,5000,2800,350,340,30},
      {1250,650,5000,1950,250,270,0},
      {445,355,5000,1850,250,160,50},
      {495,400,5000,1900,250,260,80},
      {495,400,5000,1900,250,260,80},
      {495,400,5000,1900,250,260,80},
      {495,400,5000,1900,250,260,80}
   };
   const int selectors[9][4]={
      {16385,0,0,100},{16385,0,0,100},{16385,12,17,1000},
      {16385,15,3,1200},{16385,1,9,1500},{16385,0,0,100},
      {16385,0,0,100},{16385,0,0,100},{16385,0,0,100}
   };
   const double thresholds[9]={0,0,45,16,46,0,0,0,0};
   ZeroMemory(config);
   config.moduleIndex=module;
   config.name=names[module];
   config.strategyId=module+1;
   config.coreSlot=slots[module];
   config.pivotTimeframe=(ENUM_TIMEFRAMES)pivotTf[module];
   config.triggerTimeframe=(ENUM_TIMEFRAMES)triggerTf[module];
   config.olderBars=older[module];
   config.newerBars=newer[module];
   config.searchDepth=depth[module];
   config.minPivotDistance=distance[module];
   config.buyOffset=buyOffset[module];
   config.sellOffset=sellOffset[module];
   config.pendingLimit=batches[module];
   config.pendingSpacing=spacing[module];
   config.expiryHours=expiry[module];
   config.positionLimit=positions[module];
   config.referencePrice=referencePrice[module];
   config.protectionDistance=protectionDistance[module];
   for(int k=0;k<7;k++) config.protectionCoefficients[k]=coefficients[module][k];
   for(int k=0;k<4;k++) config.protectionSelectors[k]=selectors[module][k];
   config.protectionThreshold=thresholds[module];
   config.targetDistance=10.0*(module==1 ? targetS2Pips : coreTargetPips);
   bool original=quickSetup==4 && tunedExits;
   bool presetLocks=quickSetup==1 || quickSetup==3;
   config.stopDistance=original ? tunedStops[module] : 10.0*stopLossPips;
   config.lockStart=original || presetLocks ? tunedStarts[module] : globalLockStart;
   config.lockPercent=original || presetLocks ? tunedLocks[module] : globalLockPercent;
   config.primaryThreshold=original ? (module==6 ? 0.56 : 0.53) : primaryThreshold;
   config.consensusThreshold=original ? tunedConsensus[module] : consensusThreshold;
   config.priceScale=1.0;
   return true;
}

void MDScaleStrategyConfig(const MDStrategyConfig &base,const double previousDayOpen,
                          const double pipSize,const double point,const long stopsLevel,
                          const bool testerNonGoldMode,MDStrategyConfig &config)
{
   config=base;
   if(base.referencePrice>0.0)
   {
      config.priceScale=previousDayOpen>0.0 ? previousDayOpen/base.referencePrice : 1.0;
      config.minPivotDistance*=config.priceScale;
      config.buyOffset=MathRound(config.buyOffset*config.priceScale);
      config.sellOffset=MathRound(config.sellOffset*config.priceScale);
      for(int k=0;k<7;k++) config.protectionCoefficients[k]*=config.priceScale;
   }
   double minimumTarget=pipSize>0.0 ? 2.0*(double)stopsLevel*point/pipSize : 0.0;
   if(config.targetDistance<minimumTarget || config.targetDistance<=0.0)
      config.targetDistance=minimumTarget>0.0 ? minimumTarget : 1.0;
   if(testerNonGoldMode) config.pendingLimit=1;
}

bool MDHasNearbyPending(const double price,const double distance,const double &pendingPrices[])
{
   for(int i=0;i<ArraySize(pendingPrices);i++)
      if(MathAbs(pendingPrices[i]-price)<distance) return true;
   return false;
}

double MDFindPivot(const MDStrategyConfig &config,const bool buy,
                   const double bid,const double ask,const double pipSize,const int digits,
                   const MqlRates &bars[],const double &pendingPrices[])
{
   int required=config.searchDepth+2+config.olderBars;
   if(required<1 || ArraySize(bars)<required || !ArrayGetAsSeries(bars)) return 0.0;
   for(int shift=config.newerBars+1;shift<=config.searchDepth;shift++)
   {
      double pivot=buy ? bars[shift].high : bars[shift].low;
      if(buy ? pivot<=ask+config.minPivotDistance*pipSize
             : pivot>=bid-config.minPivotDistance*pipSize) continue;
      bool extreme=true;
      for(int k=shift-config.newerBars;k<=shift+config.olderBars;k++)
         if(buy ? bars[k].high>pivot : bars[k].low<pivot) { extreme=false; break; }
      if(!extreme) continue;
      for(int k=0;k<shift;k++)
         if(buy ? bars[k].high>pivot : bars[k].low<pivot) { extreme=false; break; }
      if(!extreme) continue;
      double entry=NormalizeDouble(pivot+(buy ? config.buyOffset : -config.sellOffset)*pipSize,digits);
      if(MDHasNearbyPending(entry,config.pendingSpacing*pipSize,pendingPrices)) continue;
      return NormalizeDouble(pivot,digits);
   }
   return 0.0;
}

bool MDPassPendingPlacementGates(const MDStrategyConfig &config,const bool buy,
                                 const double pivot,const double entry,const double pipSize,
                                 const double &pendingPrices[])
{
   if(MDHasNearbyPending(entry,config.pendingSpacing*pipSize,pendingPrices)) return false;
   int count=ArraySize(pendingPrices);
   if(count==config.pendingLimit && count>0)
   {
      double extreme=pendingPrices[0];
      for(int i=1;i<count;i++)
         extreme=buy ? MathMin(extreme,pendingPrices[i]) : MathMax(extreme,pendingPrices[i]);
      if(buy ? extreme<pivot : pivot<extreme) return false;
   }
   for(int i=0;i<count;i++)
      if(buy ? pendingPrices[i]<=entry : entry<=pendingPrices[i]) return false;
   return true;
}

void MDResolvePendingExpiration(const MDStrategyConfig &config,const datetime now,
                                const long supportedModes,const bool weekendShield,
                                const datetime nextWeekendCutoff,
                                const bool forcedMode,const ENUM_ORDER_TYPE_TIME cachedMode,
                                ENUM_ORDER_TYPE_TIME &type,datetime &expiration)
{
   type=ORDER_TIME_GTC;
   expiration=0;
   long duration=config.expiryHours>0 ? (long)config.expiryHours*3600 : 86400;
   if(forcedMode) { type=cachedMode; return; }
   if(weekendShield && (supportedModes&SYMBOL_EXPIRATION_SPECIFIED)!=0)
   {
      datetime candidate=(datetime)((long)now+duration);
      if(nextWeekendCutoff>now && nextWeekendCutoff<candidate) candidate=nextWeekendCutoff;
      if(candidate>now) { type=ORDER_TIME_SPECIFIED; expiration=candidate; return; }
   }
   if(supportedModes==0 || (supportedModes&SYMBOL_EXPIRATION_GTC)!=0) return;
   if((supportedModes&SYMBOL_EXPIRATION_DAY)!=0) { type=ORDER_TIME_DAY; return; }
   if((supportedModes&SYMBOL_EXPIRATION_SPECIFIED)!=0) type=ORDER_TIME_SPECIFIED;
   else if((supportedModes&SYMBOL_EXPIRATION_SPECIFIED_DAY)!=0) type=ORDER_TIME_SPECIFIED_DAY;
   else return;
   expiration=(datetime)((long)now+duration);
}

bool MDBuildPendingGeometry(const MDStrategyConfig &config,const bool buy,
                           const double pivot,const double bid,const double ask,
                           const double pipSize,const double point,const int digits,
                           const double stopDistancePrice,const double minimumBrokerDistance,
                           const datetime now,MDPendingGeometry &signal)
{
   ZeroMemory(signal);
   if(pivot<=0.0) return false;
   double entry=NormalizeDouble(pivot+(buy ? config.buyOffset : -config.sellOffset)*pipSize,digits);
   if(entry<=0.0) return false;
   if(buy ? entry-(point+minimumBrokerDistance)<=ask
          : bid<=point+minimumBrokerDistance+entry) return false;
   double stop=NormalizeDouble(entry+(buy ? -stopDistancePrice : stopDistancePrice),digits);
   double actualStopDistance=buy ? entry-stop : stop-entry;
   if(point*0.5+actualStopDistance<minimumBrokerDistance) return false;
   double takeProfit=NormalizeDouble(entry+(buy ? 1.0 : -1.0)*config.targetDistance*pipSize,digits);
   if((buy ? takeProfit-entry : entry-takeProfit)<minimumBrokerDistance)
      takeProfit=NormalizeDouble(entry+(buy ? minimumBrokerDistance : -minimumBrokerDistance),digits);
   signal.moduleIndex=config.moduleIndex;
   signal.coreSlot=config.coreSlot;
   signal.buy=buy;
   signal.pivotPrice=pivot;
   signal.entryPrice=entry;
   signal.stopLoss=stop;
   signal.takeProfit=takeProfit;
   signal.signalTime=now;
   signal.nominalExpiration=now+3600*(config.expiryHours<2 ? 1 : config.expiryHours);
   signal.primaryThreshold=config.primaryThreshold;
   signal.consensusThreshold=config.consensusThreshold;
   return true;
}



const uchar xsPrimaryBytes[14725]=
{
   8,8,18,54,83,99,97,108,112,101,114,32,100,101,116,101,114,109,105,110,105,115,116,105,99,32,112,97,121,111,102,102,
   45,119,101,105,103,104,116,101,100,32,78,117,109,80,121,32,116,114,97,105,110,101,114,32,118,50,58,155,111,10,39,10,
   8,102,101,97,116,117,114,101,115,10,12,102,101,97,116,117,114,101,95,109,101,97,110,18,8,99,101,110,116,101,114,101,
   100,34,3,83,117,98,10,44,10,8,99,101,110,116,101,114,101,100,10,13,102,101,97,116,117,114,101,95,115,99,97,108,
   101,18,12,115,116,97,110,100,97,114,100,105,122,101,100,34,3,68,105,118,10,35,10,12,115,116,97,110,100,97,114,100,
   105,122,101,100,10,4,119,49,95,48,18,5,109,109,49,95,48,34,6,77,97,116,77,117,108,10,26,10,5,109,109,49,
   95,48,10,4,98,49,95,48,18,6,112,114,101,49,95,48,34,3,65,100,100,10,24,10,6,112,114,101,49,95,48,18,
   8,104,105,100,100,101,110,95,48,34,4,84,97,110,104,10,31,10,8,104,105,100,100,101,110,95,48,10,4,119,50,95,
   48,18,5,109,109,50,95,48,34,6,77,97,116,77,117,108,10,27,10,5,109,109,50,95,48,10,4,98,50,95,48,18,
   7,108,111,103,105,116,95,48,34,3,65,100,100,10,26,10,7,108,111,103,105,116,95,48,18,6,112,114,111,98,95,48,
   34,7,83,105,103,109,111,105,100,10,35,10,12,115,116,97,110,100,97,114,100,105,122,101,100,10,4,119,49,95,49,18,
   5,109,109,49,95,49,34,6,77,97,116,77,117,108,10,26,10,5,109,109,49,95,49,10,4,98,49,95,49,18,6,112,
   114,101,49,95,49,34,3,65,100,100,10,24,10,6,112,114,101,49,95,49,18,8,104,105,100,100,101,110,95,49,34,4,
   84,97,110,104,10,31,10,8,104,105,100,100,101,110,95,49,10,4,119,50,95,49,18,5,109,109,50,95,49,34,6,77,
   97,116,77,117,108,10,27,10,5,109,109,50,95,49,10,4,98,50,95,49,18,7,108,111,103,105,116,95,49,34,3,65,
   100,100,10,26,10,7,108,111,103,105,116,95,49,18,6,112,114,111,98,95,49,34,7,83,105,103,109,111,105,100,10,35,
   10,12,115,116,97,110,100,97,114,100,105,122,101,100,10,4,119,49,95,50,18,5,109,109,49,95,50,34,6,77,97,116,
   77,117,108,10,26,10,5,109,109,49,95,50,10,4,98,49,95,50,18,6,112,114,101,49,95,50,34,3,65,100,100,10,
   24,10,6,112,114,101,49,95,50,18,8,104,105,100,100,101,110,95,50,34,4,84,97,110,104,10,31,10,8,104,105,100,
   100,101,110,95,50,10,4,119,50,95,50,18,5,109,109,50,95,50,34,6,77,97,116,77,117,108,10,27,10,5,109,109,
   50,95,50,10,4,98,50,95,50,18,7,108,111,103,105,116,95,50,34,3,65,100,100,10,26,10,7,108,111,103,105,116,
   95,50,18,6,112,114,111,98,95,50,34,7,83,105,103,109,111,105,100,10,35,10,12,115,116,97,110,100,97,114,100,105,
   122,101,100,10,4,119,49,95,51,18,5,109,109,49,95,51,34,6,77,97,116,77,117,108,10,26,10,5,109,109,49,95,
   51,10,4,98,49,95,51,18,6,112,114,101,49,95,51,34,3,65,100,100,10,24,10,6,112,114,101,49,95,51,18,8,
   104,105,100,100,101,110,95,51,34,4,84,97,110,104,10,31,10,8,104,105,100,100,101,110,95,51,10,4,119,50,95,51,
   18,5,109,109,50,95,51,34,6,77,97,116,77,117,108,10,27,10,5,109,109,50,95,51,10,4,98,50,95,51,18,7,
   108,111,103,105,116,95,51,34,3,65,100,100,10,26,10,7,108,111,103,105,116,95,51,18,6,112,114,111,98,95,51,34,
   7,83,105,103,109,111,105,100,10,35,10,12,115,116,97,110,100,97,114,100,105,122,101,100,10,4,119,49,95,52,18,5,
   109,109,49,95,52,34,6,77,97,116,77,117,108,10,26,10,5,109,109,49,95,52,10,4,98,49,95,52,18,6,112,114,
   101,49,95,52,34,3,65,100,100,10,24,10,6,112,114,101,49,95,52,18,8,104,105,100,100,101,110,95,52,34,4,84,
   97,110,104,10,31,10,8,104,105,100,100,101,110,95,52,10,4,119,50,95,52,18,5,109,109,50,95,52,34,6,77,97,
   116,77,117,108,10,27,10,5,109,109,50,95,52,10,4,98,50,95,52,18,7,108,111,103,105,116,95,52,34,3,65,100,
   100,10,26,10,7,108,111,103,105,116,95,52,18,6,112,114,111,98,95,52,34,7,83,105,103,109,111,105,100,10,35,10,
   12,115,116,97,110,100,97,114,100,105,122,101,100,10,4,119,49,95,53,18,5,109,109,49,95,53,34,6,77,97,116,77,
   117,108,10,26,10,5,109,109,49,95,53,10,4,98,49,95,53,18,6,112,114,101,49,95,53,34,3,65,100,100,10,24,
   10,6,112,114,101,49,95,53,18,8,104,105,100,100,101,110,95,53,34,4,84,97,110,104,10,31,10,8,104,105,100,100,
   101,110,95,53,10,4,119,50,95,53,18,5,109,109,50,95,53,34,6,77,97,116,77,117,108,10,27,10,5,109,109,50,
   95,53,10,4,98,50,95,53,18,7,108,111,103,105,116,95,53,34,3,65,100,100,10,26,10,7,108,111,103,105,116,95,
   53,18,6,112,114,111,98,95,53,34,7,83,105,103,109,111,105,100,10,35,10,12,115,116,97,110,100,97,114,100,105,122,
   101,100,10,4,119,49,95,54,18,5,109,109,49,95,54,34,6,77,97,116,77,117,108,10,26,10,5,109,109,49,95,54,
   10,4,98,49,95,54,18,6,112,114,101,49,95,54,34,3,65,100,100,10,24,10,6,112,114,101,49,95,54,18,8,104,
   105,100,100,101,110,95,54,34,4,84,97,110,104,10,31,10,8,104,105,100,100,101,110,95,54,10,4,119,50,95,54,18,
   5,109,109,50,95,54,34,6,77,97,116,77,117,108,10,27,10,5,109,109,50,95,54,10,4,98,50,95,54,18,7,108,
   111,103,105,116,95,54,34,3,65,100,100,10,26,10,7,108,111,103,105,116,95,54,18,6,112,114,111,98,95,54,34,7,
   83,105,103,109,111,105,100,10,35,10,12,115,116,97,110,100,97,114,100,105,122,101,100,10,4,119,49,95,55,18,5,109,
   109,49,95,55,34,6,77,97,116,77,117,108,10,26,10,5,109,109,49,95,55,10,4,98,49,95,55,18,6,112,114,101,
   49,95,55,34,3,65,100,100,10,24,10,6,112,114,101,49,95,55,18,8,104,105,100,100,101,110,95,55,34,4,84,97,
   110,104,10,31,10,8,104,105,100,100,101,110,95,55,10,4,119,50,95,55,18,5,109,109,50,95,55,34,6,77,97,116,
   77,117,108,10,27,10,5,109,109,50,95,55,10,4,98,50,95,55,18,7,108,111,103,105,116,95,55,34,3,65,100,100,
   10,26,10,7,108,111,103,105,116,95,55,18,6,112,114,111,98,95,55,34,7,83,105,103,109,111,105,100,10,35,10,12,
   115,116,97,110,100,97,114,100,105,122,101,100,10,4,119,49,95,56,18,5,109,109,49,95,56,34,6,77,97,116,77,117,
   108,10,26,10,5,109,109,49,95,56,10,4,98,49,95,56,18,6,112,114,101,49,95,56,34,3,65,100,100,10,24,10,
   6,112,114,101,49,95,56,18,8,104,105,100,100,101,110,95,56,34,4,84,97,110,104,10,31,10,8,104,105,100,100,101,
   110,95,56,10,4,119,50,95,56,18,5,109,109,50,95,56,34,6,77,97,116,77,117,108,10,27,10,5,109,109,50,95,
   56,10,4,98,50,95,56,18,7,108,111,103,105,116,95,56,34,3,65,100,100,10,26,10,7,108,111,103,105,116,95,56,
   18,6,112,114,111,98,95,56,34,7,83,105,103,109,111,105,100,10,115,10,6,112,114,111,98,95,48,10,6,112,114,111,
   98,95,49,10,6,112,114,111,98,95,50,10,6,112,114,111,98,95,51,10,6,112,114,111,98,95,52,10,6,112,114,111,
   98,95,53,10,6,112,114,111,98,95,54,10,6,112,114,111,98,95,55,10,6,112,114,111,98,95,56,18,20,101,110,115,
   101,109,98,108,101,95,112,114,111,98,97,98,105,108,105,116,121,34,6,67,111,110,99,97,116,42,11,10,4,97,120,105,
   115,24,1,160,1,2,18,25,83,99,97,108,112,101,114,69,110,116,114,121,81,117,97,108,105,116,121,50,50,50,51,86,
   50,42,94,8,1,8,18,16,1,66,12,102,101,97,116,117,114,101,95,109,101,97,110,74,72,153,32,206,61,164,148,179,
   61,55,243,188,61,230,243,3,62,248,45,23,63,163,201,146,60,203,244,85,190,248,52,140,190,167,198,60,62,161,172,195,
   190,2,132,226,62,58,37,114,62,148,176,90,62,185,195,165,63,107,8,173,62,190,39,198,63,211,75,232,63,232,212,133,
   63,42,95,8,1,8,18,16,1,66,13,102,101,97,116,117,114,101,95,115,99,97,108,101,74,72,157,10,154,62,19,208,
   144,62,106,43,148,62,5,139,171,62,117,196,251,62,122,245,127,63,209,191,56,63,229,182,25,63,20,211,58,63,241,59,
   9,63,214,94,142,62,110,103,32,62,194,199,154,61,165,129,154,62,30,144,166,63,172,179,203,63,14,100,246,63,168,155,
   121,63,42,143,9,8,18,8,16,16,1,66,4,119,49,95,48,74,128,9,180,93,124,62,92,203,138,62,221,15,55,60,
   136,160,76,189,182,188,10,190,189,120,95,60,133,104,148,62,240,211,2,189,67,91,240,60,61,160,131,190,182,34,91,62,
   49,50,111,62,155,149,73,62,68,218,218,189,143,72,132,189,136,40,204,62,131,66,175,62,11,126,176,61,91,210,159,62,
   173,118,130,189,110,49,223,62,117,52,18,61,166,173,35,190,230,53,142,190,161,124,109,190,51,145,192,62,143,99,155,189,
   175,18,26,63,237,80,16,189,162,161,39,62,136,196,117,62,150,32,97,62,252,242,190,189,108,191,93,189,132,41,179,189,
   60,37,141,61,157,241,40,190,19,133,98,190,240,94,250,61,106,112,207,62,161,113,95,62,180,120,47,190,60,17,86,60,
   253,74,136,61,177,42,250,61,49,168,84,61,39,5,237,60,212,63,170,62,36,97,69,62,107,15,90,189,233,83,187,190,
   188,199,164,60,154,194,25,190,141,203,102,189,28,80,88,190,107,139,132,190,133,4,204,190,59,110,35,189,219,139,132,190,
   50,173,46,62,12,221,205,62,109,110,230,61,167,38,90,190,65,208,74,189,125,225,0,189,130,136,166,62,25,177,12,62,
   42,72,151,61,39,247,23,190,187,180,79,190,101,128,26,62,181,173,109,190,197,113,177,190,230,226,223,189,87,138,197,189,
   6,190,112,190,155,237,40,61,186,167,84,63,125,145,111,62,125,247,30,190,249,114,6,63,137,131,222,61,8,224,158,61,
   135,130,48,62,115,141,89,61,243,12,218,188,204,19,167,189,242,46,87,190,99,239,101,190,108,71,67,190,189,81,189,62,
   166,20,158,189,155,19,45,61,138,128,176,61,167,160,13,190,29,208,208,189,168,193,83,190,219,179,116,190,16,74,250,189,
   192,146,134,61,179,158,175,62,90,249,103,62,21,79,36,190,69,9,237,61,81,96,113,190,168,98,71,189,20,20,245,62,
   226,219,86,60,253,254,251,61,176,20,134,61,250,24,145,60,37,213,194,189,232,13,145,189,122,102,199,62,76,64,116,189,
   152,58,138,189,59,27,255,62,13,15,226,190,182,143,250,190,66,17,192,60,159,249,170,190,1,117,62,61,190,254,30,62,
   206,16,235,190,22,46,160,190,128,187,34,62,75,156,4,63,159,111,240,187,116,147,173,189,196,188,15,190,225,186,144,60,
   244,62,118,59,160,41,172,61,139,202,34,62,101,139,5,190,182,114,46,190,125,142,178,61,108,151,249,189,88,211,95,190,
   178,8,113,61,28,207,137,61,49,117,82,190,163,131,22,190,237,216,42,62,224,170,88,190,232,248,232,190,125,110,163,189,
   233,194,63,61,20,222,117,61,255,97,11,62,85,41,196,61,33,65,1,190,77,21,72,190,150,4,35,189,157,125,82,60,
   189,66,124,190,53,202,10,61,34,186,36,62,212,30,29,189,60,191,154,61,222,128,62,62,44,79,166,190,89,215,208,61,
   69,5,151,190,145,50,83,62,193,4,111,62,90,0,200,190,113,168,22,190,231,187,48,190,222,187,182,61,152,235,136,62,
   59,237,207,189,44,25,2,190,142,61,61,190,228,18,103,190,213,5,24,189,55,19,203,61,188,5,184,190,103,218,246,189,
   17,200,124,61,227,218,146,60,39,72,243,61,102,111,51,189,115,91,38,190,28,15,177,190,7,13,50,62,97,133,147,62,
   122,212,156,189,205,188,161,190,10,216,35,189,225,153,18,188,85,4,187,61,133,22,75,190,239,107,52,62,55,122,180,61,
   242,150,12,63,230,216,164,189,24,90,215,60,118,5,109,62,175,208,128,190,131,210,80,62,93,201,149,62,140,6,13,62,
   102,28,225,189,218,48,158,62,134,191,187,190,242,205,242,190,15,164,112,190,72,15,23,190,246,46,163,189,153,41,7,190,
   184,20,178,62,203,129,109,62,194,99,102,190,41,180,70,190,76,83,78,60,45,165,47,62,222,18,64,62,57,217,50,62,
   14,196,145,190,155,111,46,190,65,51,133,61,138,158,230,61,241,105,38,62,179,250,165,190,24,199,15,190,105,194,56,61,
   242,35,58,189,227,178,205,60,244,47,96,190,167,216,166,189,246,30,105,61,247,206,108,62,54,63,82,190,224,162,202,60,
   43,130,18,62,177,159,20,62,205,75,5,190,67,143,41,61,30,183,79,189,104,186,185,61,15,190,239,61,139,9,106,190,
   176,193,168,62,83,215,147,190,64,107,238,62,169,179,17,190,234,13,204,190,10,230,100,61,159,13,193,190,45,249,63,190,
   29,142,132,62,32,161,170,187,254,250,168,189,167,34,91,62,95,210,248,61,24,161,197,189,135,241,80,190,175,42,81,61,
   38,229,91,190,45,117,222,190,101,211,133,62,196,77,40,61,215,130,9,190,108,90,228,189,97,197,136,62,233,217,221,189,
   31,139,128,190,171,197,247,62,179,26,235,62,120,246,145,187,27,145,71,190,225,122,55,189,210,61,87,62,115,184,195,61,
   166,127,221,62,192,198,64,190,109,25,42,62,80,59,155,58,143,85,60,190,246,9,108,190,229,137,21,62,102,181,134,190,
   138,234,97,61,28,157,71,62,34,75,189,190,251,23,141,62,75,32,8,190,42,76,8,16,16,1,66,4,98,49,95,48,
   74,64,94,1,166,60,138,182,37,189,61,210,30,61,22,190,129,61,93,31,74,189,123,206,207,60,112,254,133,188,31,105,
   190,59,202,217,156,189,217,29,107,188,209,177,138,189,205,8,186,60,208,107,41,189,2,36,44,187,250,39,87,188,152,98,
   186,188,42,78,8,16,8,1,16,1,66,4,119,50,95,48,74,64,159,66,206,62,20,223,132,190,187,13,139,188,97,216,
   95,61,147,204,24,62,76,181,156,190,94,25,167,61,250,219,137,189,197,100,130,62,39,103,178,61,252,147,100,61,178,251,
   53,190,216,219,187,62,154,205,213,189,129,20,143,62,142,38,90,189,42,16,8,1,16,1,66,4,98,50,95,48,74,4,
   117,57,53,187,42,143,9,8,18,8,16,16,1,66,4,119,49,95,49,74,128,9,39,163,62,61,59,132,154,190,18,238,
   179,62,23,48,156,190,132,224,221,61,31,109,55,190,118,129,213,190,246,0,228,189,193,124,129,190,42,16,78,190,85,2,
   5,63,171,198,1,62,214,123,173,62,55,54,29,188,234,203,24,62,231,231,134,62,20,133,110,190,95,193,175,190,70,111,
   30,62,123,43,40,190,112,253,73,59,76,18,75,190,144,12,192,62,211,7,167,61,169,60,148,190,139,16,217,62,205,149,
   249,61,146,240,108,190,155,64,43,59,106,109,92,190,205,52,122,62,225,157,163,189,63,33,155,190,65,96,43,62,233,29,
   159,190,169,47,140,190,61,109,169,190,196,3,145,189,71,212,56,62,129,162,137,62,240,13,54,62,195,68,120,190,31,213,
   199,190,195,180,92,189,24,161,99,190,123,78,170,190,81,20,203,61,38,53,148,188,32,254,215,62,134,125,140,62,24,123,
   68,189,178,10,40,61,103,219,200,188,219,160,51,190,49,37,243,190,128,50,200,190,147,159,168,190,190,33,53,62,6,17,
   51,190,251,76,248,62,248,56,18,190,200,78,133,189,18,233,255,62,9,38,16,61,90,100,215,189,145,70,16,189,211,199,
   112,190,109,172,134,62,225,181,139,190,140,78,146,190,161,204,8,61,173,203,158,190,217,52,168,61,23,239,171,60,201,165,
   150,189,13,5,207,189,207,149,46,190,94,62,129,62,159,122,169,185,180,235,145,190,144,190,63,62,41,110,146,62,144,163,
   143,189,102,211,167,61,192,90,132,189,162,26,35,62,244,57,67,61,61,5,183,189,83,93,189,190,229,163,155,188,205,68,
   4,63,127,159,66,190,136,236,44,62,107,232,117,189,25,175,211,61,194,31,159,60,149,138,37,63,78,21,4,190,130,51,
   183,62,194,135,153,61,210,169,10,62,11,128,131,190,213,38,86,190,222,199,146,62,49,147,191,60,138,108,199,190,240,195,
   184,62,243,174,169,190,77,120,139,62,177,146,54,62,199,255,52,62,185,8,3,187,139,216,118,190,231,68,229,62,30,60,
   207,189,237,108,89,62,64,192,68,190,12,32,97,61,249,9,124,62,247,82,24,190,41,39,80,61,36,81,95,188,132,177,
   84,190,210,215,128,189,228,246,80,61,226,38,201,189,192,131,191,189,146,133,8,190,59,141,76,188,185,150,84,62,48,174,
   226,190,127,226,22,62,10,59,122,190,89,29,156,190,56,233,206,60,104,157,133,188,222,185,194,189,119,62,19,190,158,211,
   131,62,227,64,114,61,85,198,240,189,146,245,146,61,241,148,80,60,20,67,211,62,238,214,48,190,136,194,209,59,74,245,
   0,190,180,31,179,61,183,173,234,190,164,74,161,61,173,56,12,62,159,107,228,59,247,249,112,188,184,241,124,190,97,50,
   176,189,17,164,147,190,134,37,146,62,118,113,28,189,26,78,133,62,133,71,101,62,191,103,173,189,22,143,169,188,78,186,
   248,61,41,86,233,189,27,230,194,189,208,217,229,190,70,181,4,189,50,13,16,62,166,211,214,62,167,96,212,189,214,89,
   184,188,118,8,167,61,109,39,95,61,50,92,1,62,214,14,81,62,59,232,192,189,11,239,164,190,228,67,17,190,188,76,
   240,62,83,20,215,189,6,62,193,189,195,217,142,61,250,105,103,62,231,79,208,189,33,176,12,190,99,70,88,62,48,54,
   214,190,197,145,105,190,91,247,87,189,2,197,157,60,190,179,115,62,71,53,214,189,71,40,48,189,231,163,25,62,105,176,
   218,190,77,17,177,189,124,253,38,61,152,182,236,189,66,121,155,189,165,242,12,190,40,249,143,189,134,252,184,189,248,179,
   73,62,186,154,167,62,224,115,21,62,30,145,23,62,227,151,62,189,140,25,67,62,9,46,15,190,55,95,55,190,241,143,
   31,190,141,46,157,62,84,120,9,62,158,46,137,61,117,17,217,60,83,214,203,61,25,121,218,61,57,5,50,62,27,208,
   71,61,58,101,59,62,220,237,17,187,184,69,160,190,235,214,76,62,249,21,203,61,246,211,90,190,185,209,5,191,74,194,
   162,61,216,165,59,62,65,218,200,190,78,25,108,59,90,49,241,189,73,105,18,62,90,18,179,60,190,128,143,62,175,87,
   203,189,216,207,91,190,171,243,14,190,246,28,230,61,150,185,14,63,198,125,72,190,75,217,99,190,250,162,165,190,215,99,
   232,187,3,239,149,187,120,81,9,191,30,159,31,62,99,15,72,190,48,152,84,58,12,232,239,62,4,164,186,189,89,0,
   242,190,116,95,165,189,82,70,60,62,181,6,158,190,114,209,185,190,8,8,243,61,64,198,211,188,40,107,184,62,91,76,
   138,60,200,37,250,190,112,94,175,61,32,222,223,62,82,41,95,190,113,64,121,62,185,165,28,62,244,90,130,188,24,157,
   77,190,87,92,69,62,95,27,181,189,184,20,214,61,129,223,210,189,55,225,140,62,187,113,136,190,143,81,87,189,83,229,
   64,190,183,251,180,189,229,94,226,61,7,114,202,61,123,150,194,190,225,128,144,190,206,61,21,190,106,65,33,60,100,23,
   104,190,37,253,114,62,107,146,177,190,37,182,52,189,146,59,231,190,175,195,157,60,42,76,8,16,16,1,66,4,98,49,
   95,49,74,64,216,155,48,189,215,128,129,188,2,119,92,61,210,92,85,60,147,175,87,61,206,191,36,61,214,118,31,61,
   112,28,144,188,9,198,61,61,244,223,34,189,184,3,32,61,244,39,137,61,143,183,10,61,95,67,122,188,221,157,143,60,
   76,187,65,61,42,78,8,16,8,1,16,1,66,4,119,50,95,49,74,64,38,37,186,190,195,210,76,62,102,15,57,190,
   226,29,206,61,234,89,103,62,146,93,182,60,93,77,173,190,118,26,139,62,178,182,247,189,55,108,55,61,126,142,38,62,
   170,159,241,189,237,183,138,61,1,174,98,190,83,143,64,62,61,62,124,190,42,16,8,1,16,1,66,4,98,50,95,49,
   74,4,175,229,154,187,42,143,9,8,18,8,16,16,1,66,4,119,49,95,50,74,128,9,50,175,211,188,238,134,130,190,
   124,236,214,188,198,76,0,190,98,25,146,62,63,18,21,62,204,49,235,61,79,6,2,62,173,41,184,189,253,167,184,190,
   113,214,30,190,13,157,4,190,138,36,250,62,139,134,221,61,82,161,168,189,185,14,202,62,195,31,106,62,229,12,74,62,
   21,15,86,187,95,201,242,189,97,159,253,61,144,128,200,62,106,241,54,190,183,231,3,189,3,90,181,188,107,205,117,62,
   140,36,50,189,247,128,134,62,38,180,155,190,117,35,79,190,194,53,78,62,169,62,189,190,37,102,245,60,86,240,91,62,
   49,166,3,62,230,63,190,190,164,114,60,61,114,108,153,61,150,250,222,189,23,56,167,189,244,241,13,189,158,120,22,190,
   65,61,152,190,190,148,233,60,170,247,185,190,210,233,18,62,82,199,7,62,14,106,10,187,127,184,130,62,95,14,153,62,
   31,243,197,60,244,38,165,60,107,69,72,62,71,30,70,62,49,176,112,62,97,172,71,62,162,94,105,60,133,199,114,190,
   117,144,145,189,19,159,193,59,48,192,197,190,242,195,157,62,94,93,179,189,121,13,169,62,164,112,238,189,197,27,28,62,
   64,233,79,62,236,126,79,189,67,143,255,189,59,101,120,190,102,141,235,61,173,134,74,61,119,204,224,61,127,105,157,190,
   32,27,181,62,48,244,23,62,156,148,207,189,224,73,29,62,111,169,185,60,212,130,0,190,109,155,223,62,34,167,110,61,
   37,153,139,190,79,103,129,190,70,244,139,190,14,249,210,190,230,181,64,62,217,178,11,61,199,128,1,190,173,99,148,60,
   224,75,220,61,132,37,240,61,12,91,53,190,231,60,49,189,86,46,233,189,18,129,101,189,234,100,127,189,28,204,83,62,
   45,2,198,189,36,250,106,190,1,157,214,190,110,57,146,62,218,163,47,62,95,0,3,191,189,155,108,190,160,146,21,63,
   50,244,117,190,172,173,43,190,115,102,169,190,102,195,180,189,28,62,153,61,211,64,136,189,91,226,53,190,140,29,88,61,
   155,59,129,62,36,246,200,62,165,46,75,190,83,200,167,61,223,227,245,61,223,54,145,62,167,112,132,190,57,87,17,189,
   255,247,168,62,95,141,111,189,78,0,167,190,22,50,100,62,12,225,79,189,171,60,180,60,239,70,79,190,2,98,13,62,
   71,237,223,62,35,131,225,189,109,230,182,190,226,111,154,189,56,219,145,62,183,253,150,62,11,155,141,190,214,204,174,62,
   244,21,117,62,112,145,44,188,201,181,208,61,190,242,142,62,246,232,239,189,228,24,189,62,179,189,179,189,208,80,1,190,
   100,56,184,190,179,162,234,61,143,19,219,190,169,109,142,189,128,246,130,61,0,37,176,190,165,220,165,190,5,171,148,61,
   15,160,8,62,225,212,36,62,132,254,170,62,77,232,215,189,97,40,199,62,6,237,181,189,210,136,59,62,166,60,195,190,
   50,75,49,190,136,70,36,62,126,60,169,62,73,78,106,61,188,83,26,62,195,233,123,190,15,79,76,61,91,81,157,62,
   250,31,62,189,132,192,148,190,2,93,109,189,231,191,3,62,85,178,221,189,255,187,195,190,96,48,111,62,5,162,61,61,
   163,133,14,190,91,128,245,189,57,57,27,190,221,207,24,62,36,33,181,190,80,114,171,190,170,168,162,61,248,94,172,62,
   198,68,85,188,49,107,141,59,190,135,219,60,1,90,247,190,64,173,11,191,90,208,139,190,229,91,157,61,184,174,104,62,
   143,61,185,190,158,59,18,189,172,117,249,62,168,93,99,62,35,25,53,190,213,175,160,186,41,253,177,62,196,56,203,190,
   60,155,15,190,141,43,243,189,104,60,80,62,25,107,202,190,29,188,64,62,12,25,229,62,250,92,158,190,121,73,49,61,
   237,39,16,190,176,169,70,62,122,139,140,62,35,121,5,189,224,64,8,189,100,134,208,190,145,66,221,190,14,225,24,189,
   12,137,20,61,19,222,129,189,121,134,5,190,7,25,243,189,252,92,15,62,216,23,51,62,120,106,131,62,221,180,117,61,
   175,160,37,62,91,93,160,61,100,7,135,62,64,173,109,190,74,148,14,62,135,82,235,61,125,92,221,188,199,65,38,190,
   183,222,244,61,248,131,184,62,135,248,42,189,229,172,187,62,8,43,37,62,219,101,156,190,96,96,8,63,159,142,14,190,
   189,120,34,62,93,29,83,190,239,21,21,62,56,28,102,61,181,184,94,62,149,236,200,190,109,97,89,60,64,242,134,61,
   168,131,94,61,161,82,162,190,175,27,160,185,65,186,225,190,165,118,10,190,131,92,70,190,104,96,49,62,110,238,166,62,
   53,189,101,62,160,18,214,61,131,153,79,189,190,195,43,189,124,82,168,190,187,104,160,62,90,152,32,62,160,58,18,62,
   20,175,1,191,122,47,189,62,2,109,67,62,10,37,25,59,108,217,76,63,152,152,120,188,160,36,68,189,62,170,222,190,
   207,50,173,190,177,47,189,62,47,184,240,61,32,31,239,62,88,48,151,190,45,236,90,190,57,16,192,189,95,176,44,190,
   79,20,152,62,235,7,217,62,48,87,0,62,82,166,51,62,234,232,6,62,184,213,156,190,42,76,8,16,16,1,66,4,
   98,49,95,50,74,64,145,72,152,60,27,68,209,187,148,161,3,188,47,88,52,60,208,185,56,60,133,158,49,188,38,169,
   125,59,86,157,82,188,168,152,83,59,138,128,206,58,167,215,106,188,55,91,95,60,23,106,179,188,241,97,10,59,248,65,
   253,187,107,93,207,60,42,78,8,16,8,1,16,1,66,4,119,50,95,50,74,64,18,202,20,188,94,115,209,62,17,209,
   204,190,244,57,67,190,53,2,141,62,92,195,145,188,100,119,141,190,66,44,200,62,204,31,219,190,48,248,214,189,144,4,
   151,61,5,102,172,190,31,40,169,61,72,132,129,62,144,2,75,61,19,213,198,190,42,16,8,1,16,1,66,4,98,50,
   95,50,74,4,175,29,96,188,42,143,9,8,18,8,16,16,1,66,4,119,49,95,51,74,128,9,62,121,136,189,170,242,
   165,189,193,217,55,62,128,117,1,63,246,47,134,62,158,194,121,61,110,178,161,62,93,183,153,61,84,8,59,61,87,196,
   174,190,247,162,68,189,245,183,94,61,9,195,43,62,88,38,52,190,227,165,62,61,126,58,195,189,18,140,49,188,218,47,
   48,190,63,22,81,190,224,236,32,190,179,233,136,62,171,118,111,61,65,221,155,61,181,207,190,190,79,29,134,62,19,201,
   147,62,142,213,214,188,46,101,155,61,145,232,75,190,114,106,54,190,70,67,0,189,195,215,45,60,249,146,21,190,71,137,
   173,190,124,103,9,189,8,65,98,62,83,47,146,190,134,168,196,60,181,135,98,188,24,77,10,63,204,135,23,190,192,111,
   3,62,159,226,177,62,183,196,189,61,42,234,136,190,214,159,137,190,203,241,82,189,212,118,4,61,77,8,155,62,11,123,
   249,188,86,95,62,63,2,35,215,190,195,13,176,62,102,65,213,190,13,206,29,62,104,127,219,189,196,243,201,190,184,249,
   18,61,9,68,19,62,201,202,130,190,193,125,182,61,28,153,7,189,139,190,12,60,47,3,175,61,213,34,58,189,102,107,
   12,62,132,65,141,62,50,118,123,190,6,55,17,61,112,87,203,62,124,103,58,190,114,87,183,61,123,212,184,61,214,183,
   111,190,78,24,168,62,116,68,211,189,20,101,64,190,131,167,185,60,130,171,2,62,56,253,171,189,115,54,141,190,38,32,
   160,61,145,105,228,61,1,195,98,61,213,160,1,190,229,132,189,61,213,178,4,190,220,31,87,188,113,132,3,62,174,205,
   83,61,238,23,0,61,56,60,142,190,157,114,26,63,72,254,4,62,114,179,188,62,173,214,127,190,31,224,188,189,79,111,
   250,189,110,59,170,188,186,46,227,62,231,100,22,189,232,62,14,190,42,80,224,189,211,255,213,62,111,74,118,62,174,159,
   244,58,16,149,146,189,191,236,107,62,20,107,8,62,237,187,129,189,54,142,255,190,215,70,44,190,192,201,106,62,114,170,
   150,62,86,72,54,189,103,62,178,189,62,77,189,61,70,14,22,63,232,252,208,61,51,143,171,187,204,99,50,63,192,163,
   216,190,197,10,18,190,247,245,75,189,224,41,62,62,77,123,70,190,54,207,225,61,215,88,29,189,102,182,10,190,122,229,
   207,61,129,254,190,190,63,51,219,189,238,182,120,61,231,138,156,62,23,73,140,62,31,169,19,189,170,85,17,189,240,182,
   81,190,46,69,181,61,29,92,178,61,178,92,49,190,193,196,48,62,200,104,102,189,246,188,18,62,88,117,35,190,40,125,
   227,185,72,71,184,59,13,142,39,61,189,218,119,62,100,251,149,61,116,216,68,61,249,85,117,62,90,1,147,189,13,54,
   6,62,149,28,1,62,239,225,60,190,180,156,192,60,116,108,144,62,191,170,129,62,235,99,7,62,184,27,64,189,79,18,
   7,59,50,234,176,190,98,215,215,189,61,224,151,188,96,97,9,190,224,202,143,62,241,73,63,190,24,103,1,190,204,131,
   7,190,61,125,190,62,233,154,66,60,1,69,208,61,81,231,134,188,50,254,140,62,248,98,134,62,11,37,176,189,17,130,
   130,60,64,158,69,62,125,168,54,62,122,28,14,62,205,213,243,189,197,212,243,188,195,194,100,62,7,120,91,62,91,176,
   67,190,252,254,205,189,201,61,5,62,123,117,15,190,101,156,219,188,198,9,90,61,77,17,197,189,135,251,65,189,95,140,
   107,190,137,104,87,62,236,75,10,190,253,61,105,62,41,89,20,190,19,197,75,62,107,215,172,190,162,11,242,189,123,82,
   196,62,153,220,142,190,7,37,112,190,223,106,182,189,235,119,194,61,87,33,167,190,8,156,17,63,59,159,45,62,33,143,
   20,190,139,252,20,190,205,207,193,188,30,0,213,60,204,45,124,190,109,212,211,62,32,107,155,62,116,0,172,190,139,66,
   154,190,38,122,189,60,104,98,191,190,69,32,61,62,173,112,14,62,22,68,165,60,75,158,197,188,239,172,216,60,147,249,
   156,62,113,145,179,190,128,120,103,62,145,54,244,189,137,134,196,189,51,111,6,189,242,161,4,190,255,105,20,190,200,184,
   111,190,227,44,27,190,142,149,246,61,42,149,227,62,163,141,61,62,82,82,42,190,78,225,45,62,0,30,211,61,1,238,
   41,190,151,249,195,190,187,66,191,61,38,8,100,62,133,236,230,189,9,220,135,190,235,226,96,190,220,240,55,187,215,68,
   62,191,49,219,206,62,207,99,154,190,96,214,224,61,165,233,131,60,48,10,188,189,168,56,181,62,37,199,251,190,185,152,
   195,189,225,173,254,60,190,166,13,188,37,4,227,189,117,89,230,61,242,160,9,190,74,160,200,62,151,168,168,62,26,92,
   181,190,183,85,113,60,195,144,166,62,109,135,73,190,177,216,127,189,13,161,164,61,1,148,236,61,250,77,97,61,170,248,
   31,62,60,253,136,190,178,193,74,191,183,195,212,188,228,27,175,190,43,250,4,63,47,214,9,62,253,110,245,190,67,232,
   167,189,254,144,81,62,56,53,56,190,253,247,134,61,107,61,212,62,131,125,37,61,63,183,192,189,42,76,8,16,16,1,
   66,4,98,49,95,51,74,64,140,39,85,187,87,74,108,189,111,249,4,188,254,97,50,61,111,134,249,58,40,185,66,188,
   166,50,57,187,241,129,30,189,160,63,109,59,162,222,21,61,67,104,23,61,138,80,209,58,66,95,145,187,195,190,147,188,
   144,47,196,59,240,197,17,189,42,78,8,16,8,1,16,1,66,4,119,50,95,51,74,64,58,166,221,190,124,234,77,62,
   250,30,4,190,68,31,66,190,139,46,2,189,151,238,113,188,58,74,181,61,108,244,252,61,130,62,93,190,77,159,32,62,
   85,223,172,190,189,22,130,190,246,196,73,62,74,124,10,191,186,186,135,189,4,141,21,62,42,16,8,1,16,1,66,4,
   98,50,95,51,74,4,96,144,178,187,42,143,9,8,18,8,16,16,1,66,4,119,49,95,52,74,128,9,102,5,97,61,
   133,155,80,62,203,178,116,62,242,41,31,61,245,202,145,189,13,28,116,190,240,126,145,62,213,159,167,61,89,241,68,187,
   65,133,2,190,240,92,206,62,231,213,148,62,112,109,55,188,24,76,44,190,49,242,212,62,49,113,127,190,22,73,125,189,
   7,13,162,62,22,222,178,61,27,88,156,61,65,56,166,61,59,192,19,62,77,241,62,61,161,236,188,62,174,187,23,189,
   58,95,45,62,36,86,77,189,121,59,232,189,26,207,130,190,158,50,149,190,123,201,58,190,137,231,251,61,40,229,175,190,
   57,126,40,190,23,132,28,188,83,221,99,61,157,23,164,60,107,75,99,190,198,75,9,189,26,157,58,62,115,104,215,190,
   69,97,4,190,51,234,170,190,223,182,169,190,48,186,207,188,233,157,2,190,234,128,221,62,12,207,185,61,55,34,88,62,
   57,205,21,190,142,50,212,190,156,109,19,189,43,50,212,189,217,112,6,63,141,152,52,60,213,216,208,189,195,199,191,189,
   84,231,193,61,180,227,120,190,18,148,176,190,184,64,130,190,87,215,153,190,55,44,10,62,144,93,23,62,230,37,122,190,
   126,54,152,188,71,223,226,187,47,48,209,62,90,21,150,62,41,34,181,62,207,214,132,62,93,37,80,190,32,37,41,62,
   145,60,116,62,110,183,29,190,28,148,219,61,158,154,235,189,119,166,159,188,191,193,194,189,223,181,133,60,181,111,16,62,
   17,230,52,190,2,62,49,62,28,126,79,62,129,101,9,61,189,145,23,62,95,126,166,190,239,252,7,62,18,150,89,61,
   195,81,0,62,113,250,210,61,254,54,165,62,32,99,37,61,122,252,30,189,111,97,10,190,112,109,175,189,34,67,40,190,
   106,67,209,189,251,182,91,190,69,182,126,189,118,195,65,62,168,64,134,190,220,46,17,58,60,185,53,62,124,201,26,61,
   160,179,43,62,209,52,237,61,71,229,105,61,104,148,16,62,161,43,224,62,125,132,22,62,84,81,36,189,118,169,148,190,
   132,11,5,191,122,55,226,61,95,235,154,62,182,234,173,189,59,150,68,62,135,55,76,62,239,145,35,190,50,250,190,190,
   185,134,62,189,35,162,155,190,95,212,177,62,255,76,28,190,203,11,190,62,150,61,190,190,40,66,44,190,159,110,194,190,
   152,112,125,60,189,211,198,188,43,103,154,190,170,100,13,63,58,21,129,190,213,57,199,189,192,171,11,62,203,52,132,190,
   0,174,192,189,41,167,93,62,237,83,122,190,60,161,48,62,241,214,154,61,5,43,89,190,98,163,13,190,31,249,130,189,
   202,83,142,62,164,31,239,61,137,178,33,63,153,98,177,62,51,151,14,62,109,169,45,189,86,116,148,189,57,41,105,62,
   149,175,129,190,232,186,64,190,180,160,204,61,158,113,60,61,22,223,66,186,72,82,214,190,254,117,141,190,226,182,98,62,
   112,84,108,190,107,108,153,62,126,226,191,60,14,29,194,60,54,130,203,189,224,6,36,189,57,34,12,63,19,212,168,62,
   21,93,173,62,115,59,151,62,124,211,172,59,208,12,32,62,66,83,53,61,176,144,99,190,219,64,85,61,70,166,5,188,
   214,119,72,190,153,115,107,190,35,111,240,61,19,49,8,191,147,217,11,191,160,115,138,62,151,94,216,62,125,68,39,190,
   67,205,3,190,254,143,129,190,116,214,169,190,10,131,111,62,72,98,75,190,109,141,160,62,173,119,19,61,35,25,155,190,
   82,109,216,188,1,50,38,190,77,101,152,62,223,242,114,187,108,61,85,62,212,7,204,62,187,160,32,62,89,146,97,188,
   209,246,30,190,134,207,171,62,245,43,248,62,160,174,69,188,35,2,129,190,187,109,223,62,45,219,200,187,30,195,241,190,
   207,234,46,189,13,148,98,189,215,121,160,190,18,250,10,190,115,227,143,190,24,24,144,62,83,41,43,62,177,54,32,61,
   77,179,183,190,6,8,130,190,95,193,220,62,91,7,86,190,118,56,165,60,117,14,139,60,18,75,77,190,57,137,5,63,
   28,50,57,189,251,236,82,190,73,18,167,62,157,64,148,61,135,228,123,62,123,203,238,190,130,114,81,61,82,249,123,189,
   221,12,180,190,73,176,174,190,156,237,147,189,68,34,138,190,161,124,126,190,46,53,134,61,114,92,75,62,180,103,238,61,
   0,46,181,190,98,11,8,191,252,218,4,190,167,1,157,188,199,251,166,190,213,153,36,62,186,153,165,62,51,209,103,62,
   211,157,69,189,232,236,190,62,193,145,165,61,251,156,158,62,136,45,134,190,121,31,167,62,195,19,36,189,99,106,113,190,
   111,77,10,62,66,220,28,62,192,63,153,58,86,79,208,61,119,158,10,61,172,144,210,190,238,92,130,188,86,37,122,60,
   36,227,35,190,4,0,45,62,231,67,120,190,7,59,175,189,180,24,30,189,240,250,178,62,58,103,201,62,153,18,164,62,
   255,45,141,190,18,170,12,190,251,209,64,62,80,82,234,61,171,88,7,63,152,130,144,56,176,55,212,189,252,207,215,189,
   142,221,139,190,37,224,184,187,196,239,235,61,100,191,232,62,172,184,94,190,184,127,12,62,169,4,128,190,42,76,8,16,
   16,1,66,4,98,49,95,52,74,64,65,205,93,61,163,220,156,60,111,138,53,61,207,83,80,187,218,158,226,188,235,180,
   127,189,142,29,57,61,34,198,32,189,97,134,178,61,56,225,30,61,250,117,193,61,222,174,18,61,196,17,169,61,53,61,
   33,188,80,29,109,186,84,46,214,188,42,78,8,16,8,1,16,1,66,4,119,50,95,52,74,64,200,212,192,189,130,85,
   18,61,91,210,55,62,103,30,166,189,157,33,16,62,0,111,96,62,247,187,54,190,193,184,107,62,226,255,242,189,105,228,
   163,62,197,61,156,190,231,205,95,62,37,11,71,190,44,17,116,190,248,22,196,62,231,126,158,190,42,16,8,1,16,1,
   66,4,98,50,95,52,74,4,224,78,92,188,42,143,9,8,18,8,16,16,1,66,4,119,49,95,53,74,128,9,48,59,
   162,62,215,86,38,62,59,219,180,61,39,22,146,59,156,168,16,61,211,227,218,61,235,160,154,189,179,240,240,61,102,225,
   59,189,22,1,66,190,112,235,236,62,96,108,222,190,227,0,134,62,113,41,25,190,230,39,55,187,52,168,15,190,87,84,
   145,62,252,78,41,190,200,74,11,62,5,235,255,58,175,140,250,61,150,6,16,62,63,12,34,63,251,81,163,190,223,152,
   53,190,166,4,178,61,182,11,113,189,246,78,243,189,178,47,13,62,253,29,210,190,238,185,28,62,207,53,176,189,217,3,
   81,62,180,168,143,190,172,125,24,60,225,233,232,189,212,70,23,189,105,241,183,190,126,217,113,62,2,57,66,189,204,79,
   90,62,213,231,136,190,61,167,234,62,168,36,19,62,85,168,231,62,147,108,134,190,216,175,169,61,232,233,67,189,230,225,
   246,62,183,181,136,188,35,45,33,62,152,67,216,189,144,230,71,190,148,95,173,189,24,250,88,62,146,159,219,190,221,249,
   76,62,8,207,87,61,135,63,112,189,228,20,167,189,168,66,249,189,6,72,109,189,89,112,163,190,237,14,194,190,159,127,
   192,190,141,167,96,60,187,207,164,190,235,85,161,62,70,27,240,189,29,24,27,62,123,237,56,61,9,96,183,61,56,120,
   141,62,72,121,161,190,124,154,25,62,157,128,152,189,24,208,202,61,109,74,141,190,62,218,43,62,67,234,187,190,150,245,
   100,188,197,153,204,61,55,185,165,189,108,187,22,62,43,17,189,189,137,51,162,62,225,81,15,190,133,85,172,190,39,73,
   146,189,42,85,254,61,77,5,188,62,207,72,216,61,203,120,149,190,124,19,229,62,45,15,175,189,209,237,9,190,55,146,
   41,190,172,236,91,60,140,28,163,189,139,203,218,61,24,252,15,190,65,138,137,61,43,178,241,189,149,136,18,189,136,120,
   159,60,12,109,143,62,94,242,213,62,151,200,131,190,180,254,24,190,6,252,71,61,95,167,114,62,67,48,150,190,198,43,
   107,190,66,2,162,62,163,209,181,62,136,79,175,190,36,147,61,62,149,240,217,62,34,124,132,187,249,196,245,60,85,238,
   135,190,215,111,133,61,219,115,14,190,0,207,228,62,150,128,172,61,47,7,255,190,85,105,214,190,171,189,21,190,124,203,
   137,58,170,197,214,61,124,54,88,188,101,169,101,190,23,30,130,190,192,252,155,62,53,7,234,190,149,61,18,62,215,90,
   60,62,108,111,79,190,43,22,16,62,166,9,251,189,74,106,214,189,237,136,115,61,111,227,167,62,208,244,157,62,90,122,
   227,61,37,87,97,62,14,98,154,62,196,2,110,62,145,167,140,190,170,20,242,62,23,133,207,190,162,205,179,62,73,59,
   183,190,84,127,200,60,138,109,228,190,44,145,24,61,86,220,22,191,47,145,7,62,43,216,159,190,50,168,0,63,116,90,
   64,63,150,134,51,62,94,93,83,62,242,8,161,61,164,183,21,62,184,80,178,62,124,196,86,62,20,55,2,62,10,116,
   111,62,63,195,147,190,245,104,156,61,65,159,226,61,18,251,33,189,195,207,160,62,181,222,243,189,204,117,145,188,142,120,
   65,60,55,130,113,190,15,183,152,62,128,235,128,61,137,163,39,190,52,158,127,62,217,31,9,190,194,67,182,62,239,196,
   147,189,250,247,183,190,44,157,8,62,17,173,161,190,76,15,185,190,72,130,241,189,2,9,225,190,246,217,161,62,213,9,
   87,62,69,187,116,62,249,110,129,62,168,113,239,60,18,120,217,61,62,124,193,186,182,255,143,190,124,14,196,189,53,33,
   87,62,94,153,62,189,100,180,2,190,204,96,108,60,114,247,103,189,86,88,221,61,93,6,41,189,123,102,25,190,202,69,
   137,189,122,73,51,62,57,96,23,62,78,221,7,190,212,169,149,189,178,251,101,190,121,98,164,60,189,244,2,190,177,223,
   161,189,93,155,153,190,96,182,225,62,82,218,19,189,8,248,139,62,63,89,211,189,42,144,211,62,178,72,180,189,98,23,
   6,62,58,253,255,189,77,131,41,190,78,9,170,190,178,35,157,190,59,104,145,62,212,206,81,59,73,251,32,190,88,146,
   14,191,24,54,132,61,197,41,113,189,214,157,98,190,98,178,173,62,247,179,146,190,243,207,76,190,185,42,175,60,149,125,
   153,190,185,10,101,190,199,126,143,188,129,198,53,62,206,234,119,61,247,252,42,190,97,137,112,62,139,115,231,188,118,60,
   255,189,102,3,78,61,23,143,165,190,35,20,135,61,55,124,7,62,185,117,149,190,64,7,163,190,94,159,244,62,14,46,
   11,188,17,90,211,62,49,92,248,187,213,171,31,188,164,185,223,61,107,232,57,190,214,250,136,62,112,27,81,190,43,216,
   89,190,221,206,183,61,142,196,80,190,191,66,22,187,5,86,182,62,39,132,201,190,230,176,166,190,102,114,58,62,90,240,
   243,189,2,157,15,61,35,73,174,59,106,95,61,62,119,186,72,188,68,100,194,61,4,127,96,187,71,151,177,190,6,239,
   96,62,5,127,102,58,118,180,182,62,150,242,113,62,188,201,33,190,167,201,17,61,14,77,91,61,241,43,18,62,42,76,
   8,16,16,1,66,4,98,49,95,53,74,64,227,143,89,188,59,25,117,61,51,226,59,61,220,0,23,61,77,79,70,60,
   0,183,161,60,6,141,28,188,205,3,15,61,209,118,25,60,210,114,67,61,85,135,212,188,154,19,154,58,6,214,233,60,
   157,129,7,61,184,117,239,188,112,42,135,60,42,78,8,16,8,1,16,1,66,4,119,50,95,53,74,64,196,89,186,61,
   151,139,45,61,83,14,187,189,239,145,113,190,100,57,71,62,232,123,138,190,163,136,54,189,100,171,38,190,77,10,22,191,
   231,187,162,190,217,92,15,62,223,90,66,62,88,217,158,190,42,236,140,61,75,131,197,61,57,18,166,189,42,16,8,1,
   16,1,66,4,98,50,95,53,74,4,93,52,152,188,42,143,9,8,18,8,16,16,1,66,4,119,49,95,54,74,128,9,
   32,208,120,62,100,26,82,190,14,50,139,190,126,81,115,62,48,111,237,189,20,164,209,62,138,196,209,61,198,217,22,59,
   16,193,158,62,35,253,135,189,69,24,63,62,30,225,138,189,159,200,81,60,190,255,231,60,183,227,47,190,234,79,229,62,
   159,167,59,62,248,16,134,61,42,218,199,188,216,210,221,189,95,113,176,189,87,221,225,62,11,4,201,60,52,111,158,62,
   239,242,215,61,88,98,5,62,21,58,218,61,198,59,12,190,151,152,85,188,57,14,153,190,238,195,63,189,172,180,245,61,
   68,249,244,62,80,255,13,190,36,175,243,189,120,40,223,62,247,64,75,190,13,210,221,188,253,231,136,188,211,47,173,189,
   129,252,107,62,211,212,162,60,26,222,255,61,164,114,141,190,77,180,2,190,192,236,170,62,160,36,57,190,28,194,3,190,
   182,96,69,62,129,40,155,190,132,165,25,62,47,11,46,62,228,48,161,60,138,131,242,61,149,93,38,61,16,53,166,62,
   247,171,28,62,208,156,149,62,152,15,240,61,151,112,95,188,137,52,49,61,190,101,13,60,41,138,184,188,55,69,173,61,
   69,50,86,188,115,69,197,61,145,208,131,190,233,89,168,62,62,36,140,62,254,66,100,62,158,103,162,189,140,96,250,190,
   12,108,65,189,64,54,209,189,232,14,72,189,42,228,1,63,156,118,34,190,16,50,114,190,121,3,134,62,113,141,81,62,
   58,56,41,190,133,214,197,62,91,112,129,62,84,142,10,190,120,0,250,60,69,123,10,190,233,122,99,189,91,78,90,190,
   167,106,151,189,198,170,26,61,236,46,18,62,61,225,2,62,60,6,73,62,2,180,0,190,54,195,106,62,50,17,60,190,
   239,196,73,61,91,231,68,62,207,24,3,61,60,248,139,62,69,11,110,62,38,223,37,190,238,189,28,60,215,96,185,61,
   166,21,137,190,180,228,155,62,125,66,73,190,176,73,155,61,205,26,5,190,37,240,63,62,175,109,245,61,114,6,36,190,
   154,93,216,61,74,240,64,190,178,189,66,189,238,122,227,190,175,96,177,62,179,163,252,190,89,21,7,190,129,113,158,190,
   63,60,132,190,228,229,206,190,102,251,169,189,143,1,60,62,232,58,218,62,9,98,41,189,156,210,225,61,24,108,214,190,
   134,135,135,59,68,198,210,189,56,254,198,61,152,215,161,61,85,1,143,189,33,159,215,189,173,5,226,189,53,68,107,190,
   142,2,75,61,89,226,42,61,247,69,97,62,252,71,84,62,64,215,130,62,180,197,57,190,195,23,216,189,72,214,246,62,
   179,121,234,189,212,14,2,190,35,145,170,60,166,101,25,62,44,229,231,189,79,69,71,61,171,137,17,61,238,150,157,62,
   129,55,52,62,82,172,132,190,233,232,23,189,42,129,36,62,39,58,130,190,198,86,170,190,190,255,240,62,177,178,106,189,
   242,2,99,62,50,99,15,62,54,77,114,62,133,121,210,61,214,136,90,189,5,158,123,62,228,39,188,60,84,50,170,190,
   27,195,171,189,112,10,114,61,83,68,93,190,100,192,99,190,20,163,86,189,156,58,198,60,27,216,138,62,224,251,138,62,
   171,224,144,62,58,239,167,189,96,129,249,188,204,159,146,188,184,125,103,190,130,196,155,190,178,31,181,60,159,242,66,62,
   175,200,26,190,109,12,146,62,195,208,50,61,173,210,16,190,223,76,65,62,75,56,19,189,110,193,88,62,209,98,12,60,
   213,189,183,189,18,61,13,190,59,108,80,190,224,252,192,61,22,177,252,189,247,108,211,189,61,199,30,190,193,84,198,60,
   149,49,123,62,240,132,120,190,232,97,158,62,129,32,46,62,94,41,57,189,108,196,48,62,171,2,36,190,152,24,58,190,
   163,0,248,61,21,173,46,189,16,39,199,190,2,60,140,62,121,38,169,61,217,18,200,62,86,235,249,189,248,123,158,62,
   242,177,75,61,186,4,175,190,254,73,239,61,12,132,206,61,212,176,176,190,144,139,145,62,58,200,115,190,155,5,81,190,
   193,32,151,62,185,182,67,62,120,146,137,190,40,146,226,59,80,18,96,62,229,12,195,189,180,181,0,189,46,88,30,62,
   197,252,246,62,162,240,117,61,105,210,133,189,219,153,171,190,56,204,60,190,190,113,215,189,202,205,56,62,125,47,24,62,
   186,254,173,189,194,206,186,189,171,172,17,190,68,173,124,62,175,146,125,190,197,22,184,60,22,76,82,61,130,223,234,190,
   55,135,24,189,135,36,205,62,88,49,45,190,139,27,168,62,180,233,102,62,4,212,151,62,181,209,90,188,201,68,170,189,
   11,128,251,190,150,9,152,189,182,85,82,62,252,35,205,189,165,228,121,188,103,68,105,62,5,3,57,190,93,169,58,189,
   70,70,160,60,166,118,250,189,205,10,239,189,129,95,76,189,78,182,96,62,194,83,23,61,80,13,132,188,120,78,174,189,
   192,179,37,63,149,212,231,60,128,255,244,190,150,242,77,190,135,240,8,190,197,66,150,61,243,102,106,189,243,247,244,60,
   193,67,129,61,109,87,181,61,227,21,116,62,94,167,128,61,54,218,219,60,113,107,156,190,10,119,166,190,178,65,155,190,
   42,76,8,16,16,1,66,4,98,49,95,54,74,64,6,113,196,61,150,105,152,189,216,248,3,62,117,249,149,188,55,233,
   71,189,134,10,115,189,157,129,210,188,223,225,246,60,200,226,13,189,253,221,49,61,43,241,96,189,79,3,17,61,74,194,
   25,188,52,39,137,189,128,45,142,188,75,53,39,189,42,78,8,16,8,1,16,1,66,4,119,50,95,54,74,64,51,171,
   107,62,120,64,165,62,168,189,83,62,164,186,136,186,94,77,122,61,36,245,210,61,189,157,48,188,194,172,54,62,226,24,
   145,62,64,4,141,190,136,253,43,61,129,78,209,61,231,145,119,62,255,8,29,62,92,122,159,189,174,151,18,190,42,16,
   8,1,16,1,66,4,98,50,95,54,74,4,214,43,148,188,42,143,9,8,18,8,16,16,1,66,4,119,49,95,55,74,
   128,9,65,114,4,60,56,166,134,62,134,86,104,190,116,85,75,61,216,19,47,62,149,34,135,190,46,64,107,62,227,0,
   216,61,183,92,0,190,202,61,153,190,61,31,177,61,232,72,179,189,196,30,238,189,129,121,248,60,90,233,133,62,155,135,
   14,62,106,136,195,61,227,56,52,61,64,79,116,61,107,225,198,61,98,91,196,62,171,121,78,189,160,137,188,61,44,172,
   152,62,93,238,12,190,225,75,64,190,254,189,48,189,135,217,82,62,230,69,154,62,44,136,86,62,61,97,180,62,173,195,
   149,190,40,233,198,189,159,107,10,59,70,174,135,189,253,109,39,189,227,159,28,190,193,250,137,190,42,151,243,62,168,147,
   238,60,219,187,155,61,72,106,195,189,242,50,246,61,220,93,121,61,217,111,113,189,118,22,124,190,8,51,206,188,55,62,
   224,189,191,97,152,190,89,113,136,62,89,242,204,189,172,139,137,190,149,85,19,62,179,93,103,62,40,198,65,189,207,112,
   22,190,194,222,200,189,100,7,236,58,24,117,187,189,242,244,14,190,124,242,28,190,117,105,148,189,235,199,134,61,125,187,
   189,190,128,18,122,190,58,46,44,190,253,249,18,189,14,242,156,189,144,41,159,190,158,163,181,189,67,114,50,62,24,41,
   183,189,63,204,210,61,43,253,248,190,239,93,32,62,30,20,74,190,74,149,32,62,134,26,3,62,202,166,81,62,162,44,
   157,190,25,189,149,61,62,6,204,61,96,146,216,62,103,245,192,61,163,220,240,188,118,115,181,189,69,96,86,61,64,26,
   139,62,168,154,204,189,106,171,190,189,127,74,192,62,251,198,37,190,102,164,160,190,219,139,149,189,232,170,8,190,1,115,
   171,188,119,20,49,190,71,109,111,190,7,3,7,62,232,19,128,190,59,26,93,190,175,107,151,62,175,31,92,61,248,209,
   233,61,118,165,172,61,60,195,103,62,178,101,230,61,22,207,232,188,193,79,178,189,201,39,19,59,246,84,234,189,238,97,
   117,190,40,79,52,189,132,72,4,61,97,31,99,61,93,79,208,62,83,30,246,189,111,150,152,190,116,67,98,190,97,98,
   55,61,104,68,138,188,222,155,64,61,109,247,177,190,62,217,151,190,154,176,175,61,156,187,21,62,116,202,78,189,102,143,
   91,62,176,113,96,190,252,240,245,190,3,59,4,61,160,132,193,62,192,226,205,189,147,215,218,62,31,230,213,189,214,42,
   142,188,231,255,160,187,77,169,4,61,9,5,132,190,29,192,14,189,172,221,215,61,254,117,107,190,57,249,159,190,34,194,
   7,190,243,153,251,189,22,137,82,60,9,16,252,188,155,2,181,189,206,131,247,188,234,2,174,61,240,216,28,190,48,105,
   146,61,251,195,238,188,49,161,207,188,193,143,84,62,34,135,194,190,52,107,247,189,74,37,124,62,203,59,134,188,198,145,
   131,62,128,117,193,62,156,175,31,189,69,58,56,61,66,25,46,190,236,148,243,59,126,149,147,189,38,91,29,63,187,47,
   1,63,26,72,66,62,184,145,15,191,179,174,246,190,241,75,122,62,21,95,176,62,149,135,90,190,43,101,112,60,219,131,
   121,189,36,96,144,62,106,185,77,61,120,61,17,187,231,68,144,187,111,0,189,190,104,151,11,191,80,211,34,190,180,196,
   64,60,31,83,244,61,54,210,231,189,30,113,106,61,23,22,148,62,55,147,60,190,244,185,29,190,85,83,66,190,98,214,
   76,189,135,23,21,189,95,99,137,190,105,115,198,61,144,174,4,60,119,67,6,191,102,35,8,62,96,163,105,62,98,172,
   127,62,141,211,119,190,5,87,98,189,86,47,182,62,133,98,180,62,99,114,29,190,149,121,196,188,224,101,190,62,186,26,
   9,190,83,83,207,62,115,1,142,61,161,231,106,190,32,234,150,61,99,218,216,61,41,154,193,190,43,146,39,61,218,157,
   78,61,106,190,99,190,61,212,207,189,221,157,171,62,46,97,193,189,186,138,205,61,241,33,111,188,195,106,187,61,213,156,
   9,62,61,219,137,62,27,253,99,59,197,103,36,61,76,8,172,62,224,26,73,61,128,215,69,62,64,180,29,62,87,239,
   135,190,234,138,233,186,247,70,163,189,108,175,162,62,197,104,252,188,212,29,119,60,29,45,248,188,97,167,215,61,147,21,
   185,62,9,72,87,62,226,62,136,62,126,43,79,62,175,116,207,61,74,24,153,190,205,44,82,190,49,136,156,188,156,43,
   20,190,177,90,187,61,139,40,132,190,72,34,184,190,47,137,138,62,58,162,192,62,168,20,150,189,123,208,141,189,178,203,
   47,62,148,111,113,61,162,150,97,61,235,138,81,62,247,233,197,61,15,117,11,190,78,104,129,61,130,97,246,189,25,53,
   157,189,160,185,128,190,1,21,101,190,90,4,145,189,185,121,24,62,167,186,204,62,56,106,10,189,67,227,52,190,191,24,
   157,62,53,61,96,62,189,129,159,61,100,158,162,190,94,2,199,61,242,21,185,190,203,110,125,190,46,159,254,61,135,37,
   0,62,28,166,206,61,95,166,197,190,107,255,5,189,99,17,101,60,150,108,247,61,48,253,23,61,174,60,96,62,50,122,
   216,189,42,76,8,16,16,1,66,4,98,49,95,55,74,64,239,247,88,59,145,177,138,188,38,225,29,60,242,160,213,187,
   130,110,111,188,233,166,212,57,105,21,156,187,4,254,22,60,98,0,169,59,199,179,120,60,252,30,216,58,60,27,5,61,
   220,43,22,60,219,196,185,60,23,62,195,187,230,146,158,187,42,78,8,16,8,1,16,1,66,4,119,50,95,55,74,64,
   194,8,228,61,158,106,107,62,162,93,3,60,78,140,129,62,138,128,181,189,184,249,237,61,198,211,165,61,59,169,28,61,
   218,147,52,189,126,144,195,61,67,162,125,61,118,9,219,189,137,70,163,189,210,139,254,189,40,29,59,62,73,64,125,189,
   42,16,8,1,16,1,66,4,98,50,95,55,74,4,166,25,124,188,42,143,9,8,18,8,16,16,1,66,4,119,49,95,
   56,74,128,9,18,111,243,188,66,164,142,190,250,144,195,62,19,10,38,190,225,115,215,189,181,27,2,190,211,111,59,62,
   231,120,63,188,0,34,221,188,120,181,169,190,151,233,235,189,181,119,154,62,215,137,178,61,185,71,9,191,25,41,175,61,
   135,6,93,62,187,252,235,61,6,128,231,189,118,149,122,61,220,252,69,190,242,198,220,189,222,119,63,62,232,112,23,62,
   187,5,252,189,241,125,39,62,82,26,27,190,162,43,34,189,42,175,29,62,11,63,172,61,255,114,29,62,220,220,4,191,
   190,145,93,190,67,64,247,189,20,111,16,190,244,7,86,62,51,66,114,62,161,207,12,190,190,209,47,62,154,193,195,61,
   35,232,43,190,177,59,240,61,130,205,30,189,151,126,120,62,194,175,13,189,126,79,230,188,11,220,185,188,150,73,165,62,
   39,240,14,62,104,181,107,187,62,96,19,190,11,29,68,61,121,254,104,190,239,111,73,188,202,98,31,62,90,104,123,190,
   206,26,118,190,231,20,19,190,150,16,196,189,125,181,187,62,228,9,61,62,86,250,120,189,122,1,113,62,70,6,29,62,
   102,8,169,61,155,37,180,188,202,166,155,61,120,113,53,61,7,20,119,190,25,86,28,190,113,157,117,190,226,227,131,189,
   216,104,166,62,87,179,35,190,151,253,24,190,211,58,136,188,53,69,12,191,57,9,112,190,255,226,126,189,41,218,193,189,
   191,25,19,189,145,205,117,62,46,245,44,61,190,157,38,190,171,36,67,190,76,140,32,189,103,241,7,62,86,222,14,189,
   104,28,229,189,65,154,191,189,149,54,172,189,135,188,77,190,69,116,212,61,0,251,101,61,37,62,42,190,22,243,106,189,
   201,18,9,62,187,68,163,61,99,142,241,190,241,81,167,189,60,222,30,62,162,228,8,188,161,25,165,61,130,87,39,62,
   146,110,35,62,23,26,120,190,59,16,136,62,163,220,155,190,196,223,202,62,93,81,135,190,108,143,126,62,74,252,9,190,
   34,205,160,62,68,103,12,189,27,131,179,189,161,139,218,61,52,40,108,190,44,248,39,190,70,14,211,61,104,242,5,190,
   136,185,168,62,77,244,135,61,171,68,201,62,111,148,217,189,242,78,32,191,155,42,212,188,134,20,33,187,252,160,252,189,
   48,105,214,60,167,45,216,62,89,251,179,61,239,176,48,190,234,243,220,188,32,160,110,190,55,195,101,190,5,8,180,189,
   123,194,130,61,30,71,196,190,205,189,147,189,42,82,143,188,27,147,178,190,201,216,73,190,43,12,180,189,11,65,156,62,
   0,26,210,62,138,147,67,61,105,85,133,190,161,31,248,61,38,23,23,186,158,190,8,189,25,63,116,62,24,105,134,190,
   74,18,29,62,162,115,1,61,112,226,183,61,23,223,95,62,133,53,168,190,94,78,211,189,61,213,169,61,227,77,239,190,
   140,243,119,189,16,213,109,189,122,182,234,189,10,133,197,60,210,55,52,190,123,204,222,190,110,159,27,62,186,154,86,189,
   121,134,159,190,226,56,15,190,70,132,42,191,47,82,22,62,50,160,156,190,7,1,185,59,213,195,48,190,70,121,138,190,
   23,203,144,62,150,47,34,62,197,251,141,190,47,223,97,62,37,146,190,61,118,104,142,62,134,187,194,61,160,74,166,190,
   111,140,129,190,238,13,26,62,36,74,58,190,241,196,148,62,41,122,38,190,217,21,102,190,173,192,10,191,227,14,73,190,
   213,76,28,61,255,252,149,190,106,202,16,190,58,19,88,59,249,125,166,189,92,206,36,62,118,255,74,190,245,96,24,62,
   51,83,57,62,205,183,96,190,196,76,60,190,55,174,6,60,161,254,157,190,220,57,245,61,120,176,180,188,21,119,25,61,
   235,40,154,62,86,170,85,189,220,59,255,190,8,83,241,60,157,207,195,188,142,102,90,190,207,135,216,189,156,237,5,62,
   94,168,64,61,47,106,24,62,93,246,61,61,175,89,83,62,21,98,184,190,196,128,128,62,210,112,240,61,196,203,3,188,
   232,62,210,189,202,221,54,60,242,13,181,61,179,38,66,60,188,139,53,62,124,255,22,190,190,233,66,59,184,213,40,62,
   46,135,39,188,61,146,197,190,34,234,4,63,63,231,12,190,192,142,116,189,29,49,49,190,222,113,197,61,23,75,223,62,
   108,169,49,62,112,139,109,61,195,177,159,61,136,112,232,61,90,9,166,62,123,81,222,189,155,249,168,62,216,36,41,190,
   237,89,147,59,231,181,76,189,166,211,59,61,25,2,58,190,27,103,4,191,224,82,101,61,93,218,70,63,8,157,49,60,
   181,170,250,189,26,204,31,62,3,109,2,62,212,26,140,61,204,251,146,62,191,238,112,190,227,248,117,189,61,140,59,190,
   82,62,224,60,229,126,139,62,33,98,17,190,134,109,117,189,248,63,96,61,138,140,22,62,124,176,77,62,117,11,22,190,
   153,189,216,62,58,155,18,190,1,46,3,188,151,62,171,62,107,189,97,62,20,110,204,62,208,9,87,62,210,207,116,62,
   111,50,133,61,198,173,109,188,149,182,198,190,32,155,120,189,30,30,29,191,205,161,93,61,99,187,45,61,94,187,181,190,
   242,40,81,190,42,76,8,16,16,1,66,4,98,49,95,56,74,64,35,7,177,60,186,243,52,189,77,85,54,60,177,60,
   99,189,32,163,195,188,212,226,34,189,117,29,113,60,62,9,130,188,187,244,123,60,230,149,129,60,24,250,164,188,205,31,
   122,60,43,245,81,188,255,192,209,188,113,131,168,61,96,4,4,61,42,78,8,16,8,1,16,1,66,4,119,50,95,56,
   74,64,131,249,155,60,200,95,147,61,73,247,103,190,125,79,227,61,31,138,229,61,252,10,240,61,175,217,91,62,139,0,
   106,190,237,141,101,190,13,104,213,62,215,22,164,61,91,208,25,190,19,13,31,63,140,246,143,190,94,63,106,190,30,185,
   59,62,42,16,8,1,16,1,66,4,98,50,95,56,74,4,212,199,157,188,90,26,10,8,102,101,97,116,117,114,101,115,
   18,14,10,12,8,1,18,8,10,2,8,1,10,2,8,18,98,38,10,20,101,110,115,101,109,98,108,101,95,112,114,111,
   98,97,98,105,108,105,116,121,18,14,10,12,8,1,18,8,10,2,8,1,10,2,8,9,66,4,10,0,16,13,114,40,
   10,15,116,114,97,105,110,105,110,103,95,112,101,114,105,111,100,18,21,50,48,50,50,45,48,49,45,48,49,47,50,48,
   50,51,45,49,50,45,51,49,114,42,10,17,118,97,108,105,100,97,116,105,111,110,95,112,101,114,105,111,100,18,21,50,
   48,50,52,45,48,49,45,48,49,47,50,48,50,52,45,49,50,45,51,49,114,146,2,10,13,102,101,97,116,117,114,101,
   95,111,114,100,101,114,18,128,2,109,111,100,117,108,101,95,97,97,97,97,59,109,111,100,117,108,101,95,98,98,98,98,
   59,109,111,100,117,108,101,95,99,99,99,99,99,99,59,109,111,100,117,108,101,95,100,100,100,100,100,59,109,111,100,117,
   108,101,95,101,101,101,101,101,101,101,59,115,105,100,101,95,98,117,121,95,115,101,108,108,59,104,111,117,114,95,115,105,
   110,59,104,111,117,114,95,99,111,115,59,100,111,119,95,115,105,110,59,100,111,119,95,99,111,115,59,101,102,102,105,99,
   105,101,110,99,121,95,100,49,95,53,59,101,102,102,105,99,105,101,110,99,121,95,100,49,95,50,48,59,97,116,114,95,
   112,99,116,95,104,49,95,49,52,59,97,116,114,95,112,99,116,95,100,49,95,49,52,59,100,49,95,114,101,116,117,114,
   110,53,95,100,105,114,95,97,116,114,59,104,49,95,109,111,109,101,110,116,117,109,49,50,95,100,105,114,95,97,116,114,
   59,104,49,95,116,114,101,110,100,53,48,95,100,105,114,95,97,116,114,59,101,110,116,114,121,95,100,105,115,116,97,110,
   99,101,95,104,49,95,97,116,114,114,58,10,18,116,114,97,105,110,105,110,103,95,111,98,106,101,99,116,105,118,101,18,
   36,112,97,121,111,102,102,45,119,101,105,103,104,116,101,100,32,98,105,110,97,114,121,32,99,114,111,115,115,32,101,110,
   116,114,111,112,121
};

const uchar xsConsensusBytes[14725]=
{
   8,8,18,54,83,99,97,108,112,101,114,32,100,101,116,101,114,109,105,110,105,115,116,105,99,32,112,97,121,111,102,102,
   45,119,101,105,103,104,116,101,100,32,78,117,109,80,121,32,116,114,97,105,110,101,114,32,118,50,58,155,111,10,39,10,
   8,102,101,97,116,117,114,101,115,10,12,102,101,97,116,117,114,101,95,109,101,97,110,18,8,99,101,110,116,101,114,101,
   100,34,3,83,117,98,10,44,10,8,99,101,110,116,101,114,101,100,10,13,102,101,97,116,117,114,101,95,115,99,97,108,
   101,18,12,115,116,97,110,100,97,114,100,105,122,101,100,34,3,68,105,118,10,35,10,12,115,116,97,110,100,97,114,100,
   105,122,101,100,10,4,119,49,95,48,18,5,109,109,49,95,48,34,6,77,97,116,77,117,108,10,26,10,5,109,109,49,
   95,48,10,4,98,49,95,48,18,6,112,114,101,49,95,48,34,3,65,100,100,10,24,10,6,112,114,101,49,95,48,18,
   8,104,105,100,100,101,110,95,48,34,4,84,97,110,104,10,31,10,8,104,105,100,100,101,110,95,48,10,4,119,50,95,
   48,18,5,109,109,50,95,48,34,6,77,97,116,77,117,108,10,27,10,5,109,109,50,95,48,10,4,98,50,95,48,18,
   7,108,111,103,105,116,95,48,34,3,65,100,100,10,26,10,7,108,111,103,105,116,95,48,18,6,112,114,111,98,95,48,
   34,7,83,105,103,109,111,105,100,10,35,10,12,115,116,97,110,100,97,114,100,105,122,101,100,10,4,119,49,95,49,18,
   5,109,109,49,95,49,34,6,77,97,116,77,117,108,10,26,10,5,109,109,49,95,49,10,4,98,49,95,49,18,6,112,
   114,101,49,95,49,34,3,65,100,100,10,24,10,6,112,114,101,49,95,49,18,8,104,105,100,100,101,110,95,49,34,4,
   84,97,110,104,10,31,10,8,104,105,100,100,101,110,95,49,10,4,119,50,95,49,18,5,109,109,50,95,49,34,6,77,
   97,116,77,117,108,10,27,10,5,109,109,50,95,49,10,4,98,50,95,49,18,7,108,111,103,105,116,95,49,34,3,65,
   100,100,10,26,10,7,108,111,103,105,116,95,49,18,6,112,114,111,98,95,49,34,7,83,105,103,109,111,105,100,10,35,
   10,12,115,116,97,110,100,97,114,100,105,122,101,100,10,4,119,49,95,50,18,5,109,109,49,95,50,34,6,77,97,116,
   77,117,108,10,26,10,5,109,109,49,95,50,10,4,98,49,95,50,18,6,112,114,101,49,95,50,34,3,65,100,100,10,
   24,10,6,112,114,101,49,95,50,18,8,104,105,100,100,101,110,95,50,34,4,84,97,110,104,10,31,10,8,104,105,100,
   100,101,110,95,50,10,4,119,50,95,50,18,5,109,109,50,95,50,34,6,77,97,116,77,117,108,10,27,10,5,109,109,
   50,95,50,10,4,98,50,95,50,18,7,108,111,103,105,116,95,50,34,3,65,100,100,10,26,10,7,108,111,103,105,116,
   95,50,18,6,112,114,111,98,95,50,34,7,83,105,103,109,111,105,100,10,35,10,12,115,116,97,110,100,97,114,100,105,
   122,101,100,10,4,119,49,95,51,18,5,109,109,49,95,51,34,6,77,97,116,77,117,108,10,26,10,5,109,109,49,95,
   51,10,4,98,49,95,51,18,6,112,114,101,49,95,51,34,3,65,100,100,10,24,10,6,112,114,101,49,95,51,18,8,
   104,105,100,100,101,110,95,51,34,4,84,97,110,104,10,31,10,8,104,105,100,100,101,110,95,51,10,4,119,50,95,51,
   18,5,109,109,50,95,51,34,6,77,97,116,77,117,108,10,27,10,5,109,109,50,95,51,10,4,98,50,95,51,18,7,
   108,111,103,105,116,95,51,34,3,65,100,100,10,26,10,7,108,111,103,105,116,95,51,18,6,112,114,111,98,95,51,34,
   7,83,105,103,109,111,105,100,10,35,10,12,115,116,97,110,100,97,114,100,105,122,101,100,10,4,119,49,95,52,18,5,
   109,109,49,95,52,34,6,77,97,116,77,117,108,10,26,10,5,109,109,49,95,52,10,4,98,49,95,52,18,6,112,114,
   101,49,95,52,34,3,65,100,100,10,24,10,6,112,114,101,49,95,52,18,8,104,105,100,100,101,110,95,52,34,4,84,
   97,110,104,10,31,10,8,104,105,100,100,101,110,95,52,10,4,119,50,95,52,18,5,109,109,50,95,52,34,6,77,97,
   116,77,117,108,10,27,10,5,109,109,50,95,52,10,4,98,50,95,52,18,7,108,111,103,105,116,95,52,34,3,65,100,
   100,10,26,10,7,108,111,103,105,116,95,52,18,6,112,114,111,98,95,52,34,7,83,105,103,109,111,105,100,10,35,10,
   12,115,116,97,110,100,97,114,100,105,122,101,100,10,4,119,49,95,53,18,5,109,109,49,95,53,34,6,77,97,116,77,
   117,108,10,26,10,5,109,109,49,95,53,10,4,98,49,95,53,18,6,112,114,101,49,95,53,34,3,65,100,100,10,24,
   10,6,112,114,101,49,95,53,18,8,104,105,100,100,101,110,95,53,34,4,84,97,110,104,10,31,10,8,104,105,100,100,
   101,110,95,53,10,4,119,50,95,53,18,5,109,109,50,95,53,34,6,77,97,116,77,117,108,10,27,10,5,109,109,50,
   95,53,10,4,98,50,95,53,18,7,108,111,103,105,116,95,53,34,3,65,100,100,10,26,10,7,108,111,103,105,116,95,
   53,18,6,112,114,111,98,95,53,34,7,83,105,103,109,111,105,100,10,35,10,12,115,116,97,110,100,97,114,100,105,122,
   101,100,10,4,119,49,95,54,18,5,109,109,49,95,54,34,6,77,97,116,77,117,108,10,26,10,5,109,109,49,95,54,
   10,4,98,49,95,54,18,6,112,114,101,49,95,54,34,3,65,100,100,10,24,10,6,112,114,101,49,95,54,18,8,104,
   105,100,100,101,110,95,54,34,4,84,97,110,104,10,31,10,8,104,105,100,100,101,110,95,54,10,4,119,50,95,54,18,
   5,109,109,50,95,54,34,6,77,97,116,77,117,108,10,27,10,5,109,109,50,95,54,10,4,98,50,95,54,18,7,108,
   111,103,105,116,95,54,34,3,65,100,100,10,26,10,7,108,111,103,105,116,95,54,18,6,112,114,111,98,95,54,34,7,
   83,105,103,109,111,105,100,10,35,10,12,115,116,97,110,100,97,114,100,105,122,101,100,10,4,119,49,95,55,18,5,109,
   109,49,95,55,34,6,77,97,116,77,117,108,10,26,10,5,109,109,49,95,55,10,4,98,49,95,55,18,6,112,114,101,
   49,95,55,34,3,65,100,100,10,24,10,6,112,114,101,49,95,55,18,8,104,105,100,100,101,110,95,55,34,4,84,97,
   110,104,10,31,10,8,104,105,100,100,101,110,95,55,10,4,119,50,95,55,18,5,109,109,50,95,55,34,6,77,97,116,
   77,117,108,10,27,10,5,109,109,50,95,55,10,4,98,50,95,55,18,7,108,111,103,105,116,95,55,34,3,65,100,100,
   10,26,10,7,108,111,103,105,116,95,55,18,6,112,114,111,98,95,55,34,7,83,105,103,109,111,105,100,10,35,10,12,
   115,116,97,110,100,97,114,100,105,122,101,100,10,4,119,49,95,56,18,5,109,109,49,95,56,34,6,77,97,116,77,117,
   108,10,26,10,5,109,109,49,95,56,10,4,98,49,95,56,18,6,112,114,101,49,95,56,34,3,65,100,100,10,24,10,
   6,112,114,101,49,95,56,18,8,104,105,100,100,101,110,95,56,34,4,84,97,110,104,10,31,10,8,104,105,100,100,101,
   110,95,56,10,4,119,50,95,56,18,5,109,109,50,95,56,34,6,77,97,116,77,117,108,10,27,10,5,109,109,50,95,
   56,10,4,98,50,95,56,18,7,108,111,103,105,116,95,56,34,3,65,100,100,10,26,10,7,108,111,103,105,116,95,56,
   18,6,112,114,111,98,95,56,34,7,83,105,103,109,111,105,100,10,115,10,6,112,114,111,98,95,48,10,6,112,114,111,
   98,95,49,10,6,112,114,111,98,95,50,10,6,112,114,111,98,95,51,10,6,112,114,111,98,95,52,10,6,112,114,111,
   98,95,53,10,6,112,114,111,98,95,54,10,6,112,114,111,98,95,55,10,6,112,114,111,98,95,56,18,20,101,110,115,
   101,109,98,108,101,95,112,114,111,98,97,98,105,108,105,116,121,34,6,67,111,110,99,97,116,42,11,10,4,97,120,105,
   115,24,1,160,1,2,18,25,83,99,97,108,112,101,114,69,110,116,114,121,81,117,97,108,105,116,121,50,50,50,51,86,
   50,42,94,8,1,8,18,16,1,66,12,102,101,97,116,117,114,101,95,109,101,97,110,74,72,153,32,206,61,164,148,179,
   61,55,243,188,61,230,243,3,62,248,45,23,63,163,201,146,60,87,199,57,190,229,123,115,190,246,27,52,62,21,24,195,
   190,2,132,226,62,58,37,114,62,148,176,90,62,185,195,165,63,107,8,173,62,190,39,198,63,211,75,232,63,232,212,133,
   63,42,95,8,1,8,18,16,1,66,13,102,101,97,116,117,114,101,95,115,99,97,108,101,74,72,157,10,154,62,19,208,
   144,62,106,43,148,62,5,139,171,62,117,196,251,62,122,245,127,63,138,72,53,63,203,188,35,63,131,24,59,63,76,204,
   9,63,214,94,142,62,110,103,32,62,194,199,154,61,165,129,154,62,30,144,166,63,172,179,203,63,14,100,246,63,168,155,
   121,63,42,143,9,8,18,8,16,16,1,66,4,119,49,95,48,74,128,9,244,204,128,62,23,91,140,62,153,237,203,60,
   82,24,52,189,10,225,29,190,117,81,125,60,26,20,139,62,214,53,218,188,151,166,179,60,148,54,122,190,255,159,93,62,
   195,177,110,62,82,197,58,62,119,42,167,189,1,231,153,189,178,10,214,62,189,162,179,62,198,70,163,61,85,126,142,62,
   226,170,66,189,61,23,225,62,167,117,40,60,173,58,17,190,219,59,140,190,19,208,106,190,245,191,196,62,177,15,149,189,
   93,47,15,63,208,35,1,189,202,228,26,62,162,77,126,62,55,130,49,62,201,178,196,189,42,61,139,189,53,116,161,189,
   183,128,170,61,201,197,34,190,203,206,90,190,35,156,8,62,31,66,197,62,24,67,91,62,126,14,70,190,228,39,2,61,
   159,155,118,61,37,16,243,61,223,96,28,61,51,83,6,61,213,69,177,62,184,212,45,62,170,51,23,189,54,99,189,190,
   179,157,91,187,109,118,63,190,101,70,215,188,69,50,94,190,192,22,112,190,111,94,210,190,75,144,158,189,46,62,140,190,
   94,26,64,62,166,206,190,62,92,153,17,62,79,119,114,190,85,165,147,189,98,107,200,188,164,130,176,62,164,206,20,62,
   35,143,78,61,51,92,11,190,158,218,59,190,48,143,15,62,84,11,93,190,153,10,168,190,195,77,171,189,217,11,200,189,
   126,99,122,190,33,196,23,61,23,113,79,63,189,249,124,62,119,254,231,189,94,193,2,63,148,9,215,61,67,26,162,61,
   223,97,95,62,1,182,62,61,90,229,32,188,73,53,144,189,16,169,74,190,42,155,112,190,158,105,82,190,14,200,176,62,
   217,137,150,189,192,237,55,61,26,27,191,61,31,134,16,190,152,204,193,188,218,251,79,190,159,100,127,190,20,135,245,189,
   142,116,87,61,103,220,166,62,121,218,89,62,94,37,31,190,142,193,206,61,192,113,114,190,54,6,249,188,158,232,225,62,
   144,160,142,60,161,149,231,61,114,97,114,61,46,175,213,60,121,35,152,189,70,123,144,189,32,211,203,62,196,78,97,189,
   182,102,148,189,219,57,254,62,190,150,221,190,60,14,243,190,64,224,189,60,13,158,162,190,118,222,12,61,93,166,23,62,
   5,145,237,190,243,163,158,190,196,76,52,62,181,96,4,63,199,13,113,188,92,104,192,189,61,225,12,190,208,248,157,60,
   64,84,132,59,139,29,176,61,13,76,29,62,122,14,6,190,140,130,22,190,42,107,172,61,106,155,176,189,158,183,74,190,
   211,66,105,61,6,6,138,61,22,167,68,190,68,199,24,190,161,35,59,62,159,181,104,190,193,187,244,190,116,144,115,189,
   33,33,77,61,255,196,138,61,65,57,11,62,56,144,226,61,202,101,242,189,92,25,73,190,71,100,148,188,19,228,10,61,
   223,91,126,190,91,46,132,61,151,230,18,62,233,146,141,188,154,159,160,61,189,102,75,62,199,205,160,190,12,106,189,61,
   48,161,151,190,194,130,78,62,154,47,119,62,133,239,188,190,113,229,27,190,174,129,36,190,13,23,214,61,41,162,131,62,
   135,70,220,189,250,13,238,189,247,204,74,190,172,63,91,190,65,117,164,189,182,126,198,61,7,205,177,190,208,253,254,189,
   170,212,55,61,129,205,144,60,156,216,224,61,248,229,29,189,223,123,43,190,134,16,171,190,190,98,42,62,33,96,139,62,
   64,104,116,189,221,59,159,190,230,84,127,189,218,131,160,58,141,119,156,61,227,108,88,190,241,121,31,62,111,187,146,61,
   31,84,19,63,158,168,135,189,57,218,131,60,210,29,128,62,201,5,135,190,23,217,91,62,127,52,149,62,66,92,24,62,
   145,190,33,190,101,94,161,62,139,81,187,190,167,161,234,190,4,53,115,190,243,129,35,190,5,94,163,189,141,172,18,190,
   59,0,173,62,47,109,103,62,120,153,78,190,187,210,68,190,250,141,177,59,101,98,24,62,67,248,51,62,211,120,51,62,
   67,210,158,190,237,28,65,190,52,209,93,61,232,153,216,61,22,178,58,62,150,233,155,190,128,123,45,190,13,36,41,61,
   202,23,231,188,131,102,136,60,107,110,103,190,21,74,89,189,128,202,21,61,230,212,111,62,170,53,51,190,23,25,223,60,
   114,108,11,62,102,90,38,62,6,181,50,190,22,124,158,61,47,82,10,190,163,166,155,61,7,157,24,62,59,63,105,190,
   127,12,165,62,30,89,154,190,46,233,240,62,192,77,8,190,153,59,195,190,219,234,49,61,99,137,205,190,27,218,81,190,
   228,164,134,62,234,231,33,189,164,5,38,189,177,127,75,62,3,247,70,62,38,233,184,189,134,230,84,190,101,83,102,61,
   116,13,99,190,156,119,224,190,7,156,134,62,192,50,39,61,226,165,12,190,169,172,247,189,235,229,121,62,59,237,219,189,
   173,50,134,190,174,84,233,62,230,179,240,62,128,229,232,58,69,213,101,190,57,177,90,189,206,209,76,62,82,127,139,61,
   236,189,224,62,143,72,88,190,190,230,56,62,28,39,195,187,199,71,35,190,193,99,113,190,100,57,13,62,158,103,136,190,
   173,90,134,61,88,10,31,62,86,135,189,190,142,73,145,62,199,227,26,190,42,76,8,16,16,1,66,4,98,49,95,48,
   74,64,163,180,161,60,149,157,21,189,59,201,36,61,109,120,104,61,239,204,72,189,30,110,189,60,235,171,90,188,34,21,
   230,60,184,178,157,189,209,51,111,188,36,79,82,189,199,44,229,60,101,40,43,189,64,116,30,58,155,68,216,188,174,26,
   32,188,42,78,8,16,8,1,16,1,66,4,119,50,95,48,74,64,31,5,193,62,84,116,144,190,149,250,213,60,96,77,
   91,61,246,70,30,62,60,138,153,190,115,167,183,61,127,249,14,189,33,114,130,62,42,104,192,61,216,169,80,61,139,240,
   53,190,240,19,187,62,208,130,246,189,191,24,139,62,201,30,158,189,42,16,8,1,16,1,66,4,98,50,95,48,74,4,
   197,136,236,187,42,143,9,8,18,8,16,16,1,66,4,119,49,95,49,74,128,9,76,67,47,61,5,158,205,190,90,115,
   143,62,10,79,158,190,247,51,210,60,155,32,213,189,31,176,191,190,14,132,217,189,166,224,138,190,97,105,30,190,193,205,
   224,62,45,7,226,61,239,72,132,62,169,222,74,187,224,142,83,62,234,86,145,62,69,175,83,190,241,89,181,190,207,168,
   224,61,88,203,54,190,4,87,68,60,197,202,2,190,67,244,219,62,210,211,195,61,213,137,118,190,180,149,155,62,34,109,
   51,61,118,74,57,190,208,36,114,187,201,119,84,190,199,211,105,62,78,100,93,189,137,40,131,190,146,139,36,62,197,248,
   131,190,166,226,128,190,146,112,157,190,68,176,28,190,25,124,109,62,66,176,158,62,105,251,176,61,2,152,83,190,120,121,
   181,190,5,109,140,189,144,28,13,190,175,49,162,190,35,215,50,62,10,80,146,59,59,143,193,62,219,123,160,62,14,176,
   91,187,109,51,170,60,249,104,10,61,76,76,233,189,25,114,5,191,119,35,217,190,189,237,136,190,152,191,243,61,2,194,
   23,190,109,132,212,62,111,40,10,190,5,161,123,189,2,176,212,62,75,102,208,60,125,138,219,189,47,100,187,188,122,172,
   98,190,173,125,136,62,39,19,146,190,83,59,156,190,214,80,204,59,253,25,163,190,48,34,209,61,1,59,23,61,146,6,
   197,188,146,119,143,189,44,171,49,190,146,198,128,62,216,226,70,189,181,202,157,190,26,15,114,62,254,113,156,62,16,215,
   176,189,83,43,32,62,136,253,188,189,203,250,145,62,169,19,130,61,71,130,230,189,154,84,142,190,162,88,142,57,23,19,
   11,63,46,65,54,190,142,229,3,62,96,126,165,189,30,62,189,61,154,235,55,189,28,219,19,63,201,14,225,189,198,15,
   185,62,144,31,217,61,246,192,164,61,150,112,110,190,107,226,100,190,167,106,172,62,112,161,148,61,166,62,141,190,204,78,
   201,62,6,14,177,190,221,210,135,62,167,201,193,61,22,50,13,62,68,7,149,188,8,68,72,190,25,70,212,62,108,124,
   201,188,102,104,104,62,47,92,106,190,7,197,95,61,4,159,108,62,55,108,227,189,79,112,156,188,199,119,196,188,197,205,
   86,190,153,143,248,188,148,30,171,61,151,94,0,190,41,106,176,189,145,70,147,189,65,246,102,189,66,241,95,62,152,122,
   215,190,1,69,53,62,243,146,144,190,44,44,82,190,114,102,159,61,30,43,36,189,116,50,167,189,110,53,180,189,11,204,
   147,62,33,165,26,61,139,88,8,190,61,18,163,61,226,113,70,61,130,246,220,62,215,204,57,190,155,169,130,61,122,14,
   65,190,75,82,138,61,194,167,32,191,7,198,89,62,24,127,62,62,168,62,180,60,83,111,212,60,44,179,55,190,198,246,
   225,188,76,127,116,190,89,197,120,62,143,80,69,61,174,78,138,62,106,174,45,62,52,10,43,190,149,97,4,61,135,12,
   127,61,136,90,153,189,185,92,212,189,252,190,35,191,32,111,118,189,97,39,6,62,105,238,6,63,61,79,217,189,208,237,
   212,187,31,108,139,61,216,155,167,61,154,194,209,61,227,176,95,62,148,36,11,190,111,21,135,190,184,147,164,189,134,10,
   6,63,180,143,165,189,244,114,10,190,194,153,68,62,133,180,156,62,162,240,147,189,102,12,225,189,96,249,53,62,215,239,
   209,190,243,47,88,190,38,253,198,188,133,154,3,61,20,184,157,62,12,8,46,190,15,205,129,189,31,156,82,62,132,69,
   225,190,70,111,153,189,52,151,25,188,168,68,232,60,65,54,193,189,249,183,198,189,113,240,72,190,51,32,81,189,142,17,
   87,62,178,6,199,62,250,196,76,62,195,97,209,61,134,58,197,189,13,156,134,62,8,171,58,190,185,254,180,189,137,221,
   40,190,17,110,86,62,152,66,75,62,42,168,76,61,111,142,80,188,219,204,88,61,35,33,220,61,152,240,253,61,125,60,
   237,59,26,91,54,62,182,166,28,61,138,44,130,190,74,204,16,62,180,135,93,62,158,51,155,190,156,155,240,190,69,118,
   54,61,88,240,49,62,219,237,207,190,61,198,20,62,4,86,15,189,165,192,202,61,157,190,110,61,139,162,77,62,207,104,
   94,189,52,172,72,190,190,54,140,189,200,198,103,61,190,140,36,63,158,11,118,190,18,28,129,190,220,194,159,190,224,184,
   216,188,74,220,130,60,75,93,16,191,175,252,157,62,83,81,5,190,106,255,39,60,229,207,221,62,122,19,149,189,249,33,
   214,190,67,84,149,189,61,159,39,62,190,102,197,190,184,98,162,190,33,200,113,62,175,243,6,189,19,47,170,62,152,79,
   46,61,105,148,255,190,164,108,60,61,25,143,251,62,138,101,57,190,230,114,39,62,156,155,90,62,101,186,255,58,142,55,
   84,190,179,221,87,62,133,164,69,189,172,59,219,60,247,8,195,61,84,129,159,62,80,138,151,190,2,176,212,189,75,168,
   63,190,156,15,54,190,108,159,253,61,189,71,238,60,239,84,197,190,117,75,158,190,235,94,0,190,97,96,215,60,205,27,
   37,190,68,73,110,62,247,156,169,190,169,27,125,189,13,212,18,191,147,93,50,62,42,76,8,16,16,1,66,4,98,49,
   95,49,74,64,87,250,213,189,180,73,68,188,28,97,98,62,223,96,230,60,189,12,32,62,142,130,79,62,140,214,146,60,
   205,156,156,189,5,199,5,62,205,127,23,188,100,12,46,61,86,85,66,61,55,75,76,61,177,205,150,188,158,73,157,61,
   159,190,207,61,42,78,8,16,8,1,16,1,66,4,119,50,95,49,74,64,75,130,173,190,52,155,84,62,1,128,94,190,
   11,105,216,61,98,54,136,62,24,85,226,61,244,223,175,190,125,190,135,62,15,75,4,190,48,142,21,187,9,144,13,62,
   115,98,188,189,55,124,108,61,164,7,75,190,128,177,121,62,132,33,125,190,42,16,8,1,16,1,66,4,98,50,95,49,
   74,4,233,46,70,58,42,143,9,8,18,8,16,16,1,66,4,119,49,95,50,74,128,9,92,81,128,188,239,190,108,190,
   148,67,182,188,136,21,241,189,203,196,136,62,85,37,219,61,86,49,241,61,181,59,239,61,187,5,190,189,230,50,186,190,
   251,34,58,190,93,242,204,189,61,99,231,62,12,52,155,61,1,22,140,189,123,206,181,62,130,232,65,62,245,98,85,62,
   68,245,98,188,101,106,8,190,170,91,224,61,24,179,135,62,75,9,36,190,6,143,39,189,3,199,94,188,12,116,110,62,
   205,61,29,189,49,170,130,62,243,102,150,190,233,202,105,190,132,173,39,62,119,92,204,190,195,151,214,184,211,147,118,62,
   64,248,0,62,97,148,174,190,169,189,68,61,142,46,165,61,208,90,220,189,209,132,120,189,93,75,46,189,163,58,86,190,
   155,127,99,190,103,18,130,60,51,31,181,190,231,163,28,62,163,104,157,61,129,49,77,187,13,41,125,62,23,177,147,62,
   36,65,204,60,17,149,242,60,30,185,57,62,157,104,23,62,105,102,128,62,134,241,57,62,45,26,91,61,150,87,113,190,
   197,225,102,189,245,18,87,60,183,37,202,190,206,68,144,62,60,86,228,189,103,108,149,62,139,47,181,189,4,226,254,61,
   179,94,93,62,103,1,16,189,110,27,217,189,203,69,53,190,53,11,221,61,204,69,93,61,127,136,184,61,250,162,120,190,
   14,37,161,62,56,62,21,62,251,179,158,189,31,7,68,62,170,120,52,61,138,216,134,189,242,213,198,62,28,205,192,61,
   166,214,173,190,61,141,111,190,251,7,130,190,68,6,200,190,123,103,64,62,98,233,130,61,6,229,4,190,114,138,176,188,
   203,252,9,62,178,64,16,62,97,12,47,190,160,57,130,186,159,206,142,189,137,56,197,189,226,91,32,189,161,208,90,62,
   147,26,214,189,3,23,122,190,221,206,192,190,209,169,120,62,38,215,239,61,67,207,238,190,138,232,92,190,80,41,8,63,
   135,138,78,190,58,157,66,190,57,231,153,190,96,0,118,189,35,167,156,61,122,171,41,189,194,26,17,190,191,36,136,61,
   69,187,125,62,100,193,190,62,97,209,68,190,172,14,109,61,250,19,27,62,68,126,136,62,165,173,116,190,169,110,39,188,
   127,52,170,62,188,152,66,189,236,204,175,190,141,38,94,62,192,67,134,189,144,250,170,60,81,205,26,190,71,117,248,61,
   201,141,221,62,248,45,14,190,88,195,167,190,56,254,44,190,214,2,110,62,169,214,173,62,26,111,148,190,103,112,162,62,
   63,229,134,62,61,188,102,186,222,205,223,61,239,127,130,62,103,105,173,189,33,243,180,62,249,82,205,189,207,137,171,189,
   72,167,168,190,171,105,220,61,182,7,228,190,192,233,134,189,145,25,180,61,230,186,179,190,151,59,173,190,254,37,230,60,
   68,186,209,61,41,225,80,62,210,116,157,62,117,108,242,189,12,221,199,62,150,60,226,189,215,85,44,62,68,242,192,190,
   74,17,65,190,205,91,33,62,32,35,181,62,36,11,18,60,185,10,75,62,232,87,115,190,208,196,32,60,48,142,175,62,
   107,130,70,189,189,132,147,190,238,200,54,189,144,122,227,61,144,179,51,190,117,211,199,190,0,179,95,62,149,125,4,61,
   43,113,201,189,198,171,33,190,114,35,20,190,35,245,35,62,158,20,177,190,44,91,170,190,217,85,129,61,6,143,186,62,
   43,48,52,58,175,77,16,61,234,127,254,188,254,222,237,190,37,77,11,191,185,130,129,190,22,206,137,61,248,169,124,62,
   109,105,170,190,81,202,132,189,40,64,230,62,91,105,97,62,173,201,5,190,41,68,179,59,114,86,195,62,36,117,178,190,
   113,231,5,190,61,55,167,189,58,189,41,62,109,196,201,190,8,18,57,62,124,79,249,62,6,174,128,190,67,194,4,61,
   78,247,7,190,121,186,51,62,93,177,141,62,112,78,79,185,16,197,40,189,187,136,202,190,59,190,215,190,63,122,80,60,
   10,138,125,188,165,136,62,189,58,87,160,189,17,68,7,190,162,87,249,61,47,7,19,62,96,69,67,62,190,255,148,61,
   93,167,13,62,128,126,167,61,225,237,146,62,58,160,70,190,211,11,25,62,242,76,4,62,18,96,95,58,198,167,32,190,
   70,8,105,61,33,56,173,62,86,118,153,189,111,85,194,62,40,181,44,62,179,104,154,190,83,237,244,62,205,207,34,190,
   18,128,229,61,222,154,17,190,219,51,25,62,8,130,171,61,66,9,122,62,206,102,217,190,106,217,99,60,51,135,99,61,
   157,197,78,188,24,179,142,190,88,185,160,60,166,13,218,190,236,67,236,189,137,36,61,190,251,182,23,62,184,13,153,62,
   149,23,108,62,150,150,23,62,27,82,229,188,66,107,37,189,124,57,146,190,83,34,158,62,114,27,254,61,167,129,226,61,
   36,9,26,191,134,26,204,62,194,6,61,62,155,219,189,61,185,218,66,63,122,111,138,188,213,152,69,189,102,177,194,190,
   17,212,185,190,17,21,180,62,138,60,225,61,206,129,153,62,240,66,160,190,173,190,51,190,177,89,227,188,218,221,92,190,
   110,65,158,62,31,123,222,62,180,141,14,62,91,218,7,62,110,230,141,61,163,85,188,190,42,76,8,16,16,1,66,4,
   98,49,95,50,74,64,54,64,76,60,248,174,113,60,44,62,65,189,44,203,144,188,107,202,135,61,254,52,239,60,177,79,
   123,188,105,193,182,188,139,230,63,59,182,54,247,188,229,140,14,189,183,156,202,60,181,137,109,189,86,92,131,60,148,140,
   245,188,231,105,53,61,42,78,8,16,8,1,16,1,66,4,119,50,95,50,74,64,15,208,0,188,245,233,193,62,179,189,
   194,190,32,144,57,190,164,12,113,62,48,203,128,188,112,140,133,190,158,28,199,62,107,114,214,190,223,244,182,189,216,58,
   158,61,185,89,171,190,223,253,162,61,3,117,120,62,62,43,69,61,93,11,188,190,42,16,8,1,16,1,66,4,98,50,
   95,50,74,4,91,202,193,188,42,143,9,8,18,8,16,16,1,66,4,119,49,95,51,74,128,9,166,124,111,189,215,127,
   205,189,142,113,70,62,177,244,3,63,176,39,128,62,26,13,94,61,224,182,151,62,96,65,52,61,208,176,37,61,57,125,
   167,190,157,228,230,188,31,209,176,61,44,199,35,62,78,255,38,190,58,45,77,61,182,2,215,189,212,160,28,189,74,48,
   43,190,239,129,114,190,73,222,73,190,62,102,62,62,251,240,144,61,118,60,164,61,228,29,170,190,82,39,131,62,155,105,
   153,62,236,222,214,188,236,9,88,61,16,135,65,190,201,142,62,190,131,247,7,189,165,222,225,60,200,106,19,190,18,254,
   159,190,65,130,167,188,231,70,78,62,84,67,57,190,212,36,153,184,198,97,77,188,76,131,7,63,149,96,49,190,78,82,
   13,62,219,138,171,62,114,138,159,61,255,204,136,190,217,127,142,190,127,164,44,189,22,193,168,60,169,99,145,62,16,98,
   167,188,135,188,53,63,13,247,214,190,129,69,120,62,39,120,202,190,212,96,35,62,244,25,204,189,176,203,199,190,21,121,
   11,61,57,60,11,62,212,18,111,190,141,111,229,61,132,233,17,189,154,152,22,60,38,195,179,61,4,90,52,189,54,130,
   13,62,208,91,144,62,217,76,103,190,13,185,25,61,145,147,183,62,169,186,56,190,55,9,222,61,123,109,187,61,171,184,
   88,190,154,152,164,62,22,17,237,189,227,219,71,190,143,126,119,60,105,149,199,61,214,83,168,189,235,14,147,190,165,27,
   163,61,50,201,2,62,128,11,89,61,217,45,77,189,3,88,198,61,98,240,27,190,50,234,140,188,209,75,226,61,123,192,
   137,61,245,224,202,60,8,150,157,190,223,151,24,63,0,251,22,62,156,90,185,62,243,134,120,190,79,120,209,189,86,68,
   211,189,185,128,96,189,231,228,207,62,193,117,199,188,177,212,16,190,158,238,215,189,148,238,214,62,47,115,106,62,249,78,
   236,186,188,219,165,189,173,7,72,62,65,126,254,61,139,18,138,189,237,12,254,190,160,94,47,190,14,93,105,62,157,200,
   151,62,96,126,227,188,0,142,155,189,28,242,205,61,58,216,19,63,25,178,218,61,103,128,211,188,88,167,48,63,222,134,
   203,190,63,6,8,190,27,46,49,189,120,117,47,62,23,154,55,190,103,190,210,61,179,209,240,188,18,197,19,190,59,108,
   224,61,169,179,187,190,73,180,222,189,153,180,77,61,222,123,152,62,241,101,140,62,12,104,43,189,220,205,33,189,93,218,
   90,190,126,27,177,61,184,239,155,61,31,125,34,190,94,45,46,62,170,21,50,189,183,244,14,62,255,122,20,190,167,15,
   211,187,62,192,225,188,215,43,222,60,160,109,99,62,209,101,161,61,210,130,136,61,56,203,119,62,1,190,173,189,183,193,
   229,61,149,223,252,61,199,98,72,190,147,247,50,61,47,208,144,62,206,171,133,62,119,116,0,62,0,208,226,188,132,248,
   133,188,76,202,181,190,149,37,195,189,95,209,24,60,50,177,4,190,227,243,139,62,139,64,68,190,31,49,9,190,72,79,
   31,190,152,220,198,62,34,148,40,61,10,87,165,61,89,172,134,187,123,122,145,62,194,189,132,62,235,37,186,189,68,4,
   16,58,171,181,59,62,254,107,42,62,28,20,199,61,207,255,239,189,150,115,100,188,249,217,104,62,198,56,76,62,149,85,
   38,190,176,58,175,189,180,236,25,62,245,204,16,190,232,157,29,188,161,211,132,61,36,21,184,189,33,199,17,189,9,154,
   127,190,184,210,129,62,88,125,215,189,19,167,110,62,78,2,27,190,140,1,41,62,13,64,189,190,129,92,226,189,56,82,
   185,62,210,229,130,190,11,184,99,190,137,186,240,189,42,93,207,61,5,249,167,190,171,251,9,63,185,243,40,62,23,15,
   6,190,224,65,29,190,139,229,13,189,187,133,60,61,71,233,125,190,57,83,216,62,42,113,166,62,18,230,182,190,49,247,
   141,190,214,149,118,60,216,72,206,190,179,140,87,62,8,129,1,62,137,107,137,60,127,213,15,186,97,251,31,60,7,194,
   166,62,134,14,183,190,4,28,87,62,31,48,221,189,26,148,185,189,56,142,190,187,81,72,245,189,160,115,48,190,105,50,
   91,190,29,81,28,190,58,221,221,61,129,83,217,62,131,206,55,62,218,34,46,190,163,47,60,62,247,131,244,61,102,93,
   46,190,180,90,189,190,232,103,0,62,171,179,87,62,43,207,204,189,137,73,147,190,95,89,106,190,189,221,149,59,114,125,
   59,191,37,139,211,62,187,234,146,190,13,130,193,61,81,236,255,60,116,112,224,189,20,131,182,62,138,214,254,190,126,27,
   170,189,200,29,29,61,227,185,134,58,177,127,7,190,250,253,227,61,244,59,11,190,6,13,194,62,182,205,166,62,74,114,
   178,190,131,173,112,60,144,206,152,62,12,144,71,190,83,197,31,189,149,153,135,61,16,221,218,61,204,222,94,61,151,225,
   30,62,135,216,134,190,119,239,77,191,36,77,185,187,113,225,164,190,194,197,13,63,254,100,26,62,72,18,2,191,100,160,
   189,189,223,140,56,62,228,74,81,190,80,39,144,61,3,147,211,62,1,44,70,61,235,34,174,189,42,76,8,16,16,1,
   66,4,98,49,95,51,74,64,208,108,200,59,193,215,152,189,97,112,34,60,95,241,117,61,171,193,26,61,174,80,82,188,
   107,251,177,59,186,167,81,189,39,11,187,188,183,249,59,61,163,38,58,61,156,141,62,188,237,194,118,188,208,41,231,187,
   238,14,195,60,125,98,85,189,42,78,8,16,8,1,16,1,66,4,119,50,95,51,74,64,19,185,216,190,223,163,86,62,
   168,72,249,189,243,151,86,190,57,14,200,188,2,94,223,188,130,93,208,61,252,203,14,62,129,184,104,190,98,204,26,62,
   155,136,152,190,185,24,134,190,120,175,62,62,228,133,4,191,126,226,93,189,113,147,17,62,42,16,8,1,16,1,66,4,
   98,50,95,51,74,4,48,134,54,188,42,143,9,8,18,8,16,16,1,66,4,119,49,95,52,74,128,9,130,89,128,61,
   161,84,85,62,169,83,109,62,19,148,224,60,113,106,139,189,58,4,105,190,67,123,148,62,129,43,186,61,7,236,32,188,
   247,142,12,190,124,238,214,62,141,22,155,62,94,118,158,187,227,17,33,190,182,249,222,62,17,163,129,190,221,182,92,189,
   216,95,159,62,112,146,180,61,125,165,140,61,21,178,181,61,148,77,22,62,175,136,52,61,148,48,191,62,154,133,25,189,
   52,155,47,62,197,237,119,189,70,154,245,189,165,41,133,190,57,1,150,190,15,65,48,190,151,251,254,61,91,50,162,190,
   219,31,52,190,150,46,3,188,184,139,42,61,44,27,4,61,54,221,104,190,157,59,58,189,209,186,71,62,179,186,193,190,
   220,48,248,189,184,169,172,190,207,166,169,190,123,206,193,188,57,61,8,190,125,2,221,62,150,178,174,61,156,115,80,62,
   191,47,12,190,141,38,207,190,175,104,46,189,61,189,181,189,141,24,11,63,186,254,233,187,15,187,218,189,18,186,235,189,
   129,215,164,61,89,55,134,190,29,200,178,190,152,11,135,190,124,62,159,190,201,239,19,62,163,99,16,62,93,146,119,190,
   241,146,173,188,164,50,133,188,197,86,216,62,120,210,139,62,29,228,174,62,182,226,138,62,146,241,99,190,68,135,69,62,
   235,230,130,62,206,18,3,190,205,148,201,61,55,17,209,189,24,236,128,187,230,38,2,190,33,82,4,61,157,58,15,62,
   14,127,46,190,108,174,36,62,169,244,74,62,249,228,62,61,95,178,11,62,105,99,168,190,82,112,14,62,200,170,141,61,
   112,54,239,61,61,25,214,61,73,249,162,62,113,173,22,61,100,166,64,188,27,18,5,190,73,155,165,189,195,237,33,190,
   253,201,233,189,193,141,93,190,190,89,135,189,253,58,35,62,209,54,129,190,218,184,208,60,249,186,49,62,165,63,94,61,
   196,223,44,62,146,253,241,61,162,181,52,61,22,251,24,62,194,140,221,62,106,52,15,62,124,68,66,189,63,196,144,190,
   44,158,3,191,147,188,225,61,232,79,116,62,146,29,220,188,9,198,67,62,254,89,65,62,200,229,28,190,179,80,182,190,
   123,114,27,189,107,135,155,190,186,198,194,62,222,97,15,190,221,181,176,62,118,133,200,190,195,166,37,190,117,175,191,190,
   158,39,204,187,153,246,167,59,162,221,170,190,254,84,10,63,28,67,109,190,80,145,224,189,137,130,44,62,186,133,130,190,
   63,72,195,189,180,192,85,62,73,48,116,190,75,249,47,62,206,173,173,61,178,220,69,190,98,185,7,190,99,227,125,189,
   248,122,150,62,108,78,12,62,212,86,24,63,127,132,174,62,240,70,19,62,17,147,16,189,75,160,121,189,56,220,91,62,
   147,169,127,190,21,166,78,190,204,60,187,61,218,187,25,61,18,22,142,188,186,174,195,190,174,15,140,190,210,29,109,62,
   106,191,91,190,146,186,147,62,45,26,21,61,255,45,45,60,67,170,3,190,6,164,30,189,50,184,11,63,135,125,179,62,
   198,51,164,62,192,220,158,62,54,195,92,187,82,0,48,62,46,130,75,61,65,139,102,190,20,9,120,61,177,106,210,187,
   214,232,43,190,254,216,113,190,88,2,251,61,50,91,251,190,119,38,17,191,207,126,139,62,210,152,204,62,76,222,39,190,
   16,239,246,189,218,195,130,190,7,222,168,190,24,68,128,62,224,158,73,190,241,94,156,62,7,225,73,61,48,203,156,190,
   193,220,89,187,96,37,56,190,61,45,143,62,111,78,186,188,180,121,100,62,64,102,204,62,234,41,45,62,43,187,181,188,
   46,90,25,190,29,73,161,62,150,160,249,62,131,85,177,188,121,231,138,190,18,93,212,62,158,150,26,188,247,110,246,190,
   121,53,36,189,222,109,123,189,217,181,169,190,228,217,244,189,180,251,133,190,247,228,123,62,249,47,49,62,230,128,188,60,
   252,133,169,190,177,130,134,190,162,114,228,62,0,209,106,190,61,22,8,61,218,152,62,60,98,13,78,190,175,103,8,63,
   86,81,26,189,138,98,57,190,225,241,166,62,143,220,196,61,174,185,128,62,45,175,243,190,8,103,58,61,45,157,159,189,
   164,204,175,190,30,51,187,190,80,62,139,189,25,10,150,190,47,46,121,190,225,111,171,61,223,111,68,62,44,69,244,61,
   244,232,195,190,158,97,13,191,241,33,5,190,179,230,125,189,29,17,159,190,53,226,54,62,54,131,170,62,14,98,81,62,
   62,197,98,189,144,127,184,62,168,211,167,61,31,127,159,62,107,224,139,190,198,196,158,62,37,137,44,189,14,148,126,190,
   104,86,11,62,175,85,52,62,141,33,13,189,241,33,177,61,207,198,6,61,106,170,208,190,2,165,119,188,209,236,24,60,
   199,149,29,190,96,62,19,62,192,165,116,190,146,225,172,189,158,202,124,189,35,123,184,62,68,186,194,62,82,60,164,62,
   225,74,149,190,10,213,16,190,77,253,76,62,39,95,6,62,115,152,9,63,119,51,193,188,130,137,196,189,19,208,192,189,
   112,132,149,190,169,132,32,59,51,14,221,61,70,194,228,62,36,221,76,190,34,97,247,61,127,95,120,190,42,76,8,16,
   16,1,66,4,98,49,95,52,74,64,50,134,49,61,236,45,29,188,198,185,174,60,6,99,245,186,178,212,50,189,248,172,
   127,189,233,107,108,61,231,61,17,189,135,212,142,61,61,160,174,58,221,154,139,61,240,147,176,60,205,240,144,61,8,247,
   251,59,46,133,213,188,155,34,184,187,42,78,8,16,8,1,16,1,66,4,119,50,95,52,74,64,54,147,216,189,22,7,
   31,61,197,208,49,62,103,118,132,189,56,230,28,62,36,235,100,62,190,44,48,190,80,37,82,62,70,160,255,189,179,143,
   159,62,227,197,158,190,104,198,85,62,94,7,60,190,185,120,103,190,50,225,194,62,203,76,161,190,42,16,8,1,16,1,
   66,4,98,50,95,52,74,4,137,133,191,188,42,143,9,8,18,8,16,16,1,66,4,119,49,95,53,74,128,9,16,206,
   156,62,228,46,30,62,83,28,211,61,157,120,236,59,128,85,14,61,249,65,219,61,34,5,138,189,79,107,19,62,63,65,
   89,189,47,230,53,190,212,3,230,62,71,42,229,190,161,8,131,62,244,98,25,190,97,149,26,189,137,147,255,189,194,248,
   132,62,158,161,32,190,108,253,25,62,90,46,161,59,173,46,1,62,109,86,18,62,218,60,30,63,219,192,166,190,205,10,
   29,190,99,64,148,61,205,211,114,189,245,227,226,189,226,117,10,62,60,128,203,190,14,222,38,62,8,129,126,189,159,177,
   77,62,51,24,130,190,135,170,91,60,132,37,2,190,170,75,56,189,209,204,180,190,52,21,77,62,144,126,34,189,105,39,
   74,62,119,54,142,190,128,183,232,62,88,148,33,62,151,186,223,62,5,92,107,190,157,224,206,61,122,206,245,188,164,165,
   239,62,11,117,141,189,148,83,42,62,206,189,174,189,184,104,86,190,46,218,170,189,204,179,91,62,238,22,213,190,34,169,
   66,62,67,54,90,61,222,131,57,189,16,243,193,189,66,79,234,189,167,182,149,189,104,5,168,190,143,154,182,190,195,112,
   182,190,67,224,4,61,120,140,166,190,78,76,163,62,63,209,223,189,207,134,40,62,4,62,80,61,241,230,156,61,195,98,
   144,62,185,73,159,190,160,27,12,62,128,61,145,189,72,129,216,61,244,99,139,190,85,156,34,62,178,238,209,190,42,136,
   170,188,150,9,9,62,224,198,172,189,209,51,31,62,53,208,212,189,65,180,162,62,63,6,17,190,82,202,177,190,215,113,
   165,189,30,49,234,61,189,182,196,62,138,34,249,61,34,243,145,190,182,69,232,62,75,126,156,189,131,19,9,190,5,69,
   27,190,4,74,217,58,118,248,142,189,21,179,220,61,218,127,21,190,203,146,145,61,231,205,206,189,193,220,230,188,91,172,
   238,60,153,21,151,62,32,202,220,62,214,81,128,190,146,65,18,190,203,129,38,61,79,86,107,62,238,245,136,190,197,102,
   112,190,82,64,139,62,101,158,186,62,210,243,165,190,248,225,40,62,157,58,224,62,168,239,134,60,134,1,107,61,43,144,
   125,190,175,116,155,61,220,67,40,190,226,106,216,62,242,29,171,61,113,60,247,190,184,32,209,190,127,19,228,189,167,143,
   52,60,91,234,25,62,95,223,68,189,20,113,109,190,11,236,113,190,81,151,143,62,104,248,236,190,73,225,17,62,14,162,
   32,62,20,76,102,190,225,140,34,62,236,168,240,189,13,234,2,190,50,101,88,61,50,68,188,62,216,44,147,62,142,82,
   247,61,116,6,74,62,128,29,146,62,193,120,117,62,236,114,142,190,244,68,240,62,122,165,193,190,53,230,173,62,17,193,
   182,190,167,36,2,61,50,143,232,190,156,18,17,61,251,244,24,191,215,145,204,61,12,188,141,190,42,44,252,62,148,27,
   68,63,172,172,68,62,206,75,47,62,88,164,129,61,151,26,50,62,213,156,151,62,75,142,40,62,162,15,184,61,6,124,
   102,62,56,234,153,190,187,81,194,61,171,190,244,61,130,159,30,189,182,152,171,62,207,212,223,189,101,191,235,188,90,55,
   36,60,57,140,123,190,110,101,158,62,242,64,101,61,144,176,42,190,90,93,147,62,173,12,9,190,121,1,182,62,115,182,
   151,189,201,223,167,190,67,247,11,62,14,228,156,190,236,135,179,190,117,221,237,189,142,218,226,190,160,153,156,62,27,55,
   99,62,97,121,131,62,120,24,107,62,38,2,95,60,119,114,224,61,1,3,27,189,106,168,134,190,206,98,240,189,83,126,
   68,62,23,180,174,189,254,97,2,190,61,215,102,60,244,46,157,189,28,95,17,62,244,72,74,189,145,82,32,190,35,71,
   141,189,5,164,65,62,71,136,29,62,164,237,221,189,226,82,187,189,133,110,96,190,148,12,157,60,163,152,230,189,107,150,
   121,189,188,5,141,190,138,113,217,62,163,69,87,189,209,219,139,62,215,124,230,189,191,14,185,62,147,4,131,189,61,199,
   2,62,1,156,188,189,214,191,77,190,159,146,175,190,107,187,141,190,61,62,132,62,112,102,111,188,151,10,59,190,153,78,
   17,191,103,106,89,61,28,254,50,189,41,176,65,190,176,93,172,62,101,124,138,190,43,252,70,190,161,227,143,60,64,228,
   152,190,105,162,132,190,56,207,164,60,203,99,77,62,188,155,83,61,195,109,52,190,244,175,132,62,49,192,237,187,181,67,
   217,189,59,225,146,61,178,113,166,190,145,103,51,61,168,204,34,62,136,82,146,190,82,13,153,190,48,87,237,62,245,227,
   45,189,60,217,194,62,105,2,214,187,3,5,128,188,72,208,227,61,129,84,76,190,140,62,131,62,227,170,60,190,108,122,
   88,190,112,32,161,61,166,160,90,190,55,8,164,187,233,15,197,62,210,184,204,190,44,223,161,190,63,155,72,62,248,106,
   198,189,4,230,202,61,248,63,241,188,132,251,24,62,205,227,205,188,17,28,225,61,73,233,100,188,162,116,188,190,14,248,
   58,62,165,57,162,188,171,208,195,62,250,64,132,62,64,222,62,190,68,135,151,61,33,57,200,61,29,145,68,62,42,76,
   8,16,16,1,66,4,98,49,95,53,74,64,96,215,228,56,115,162,218,61,249,91,60,61,82,177,186,60,13,74,10,61,
   197,35,213,60,109,109,149,188,214,57,44,61,45,27,226,58,130,3,28,61,31,97,69,188,50,114,154,60,159,247,187,60,
   68,132,126,61,77,4,199,188,19,161,191,60,42,78,8,16,8,1,16,1,66,4,119,50,95,53,74,64,8,73,220,61,
   126,185,122,61,11,26,238,189,198,250,103,190,13,161,40,62,233,151,126,190,25,37,49,189,16,2,40,190,164,113,18,191,
   40,228,172,190,42,165,41,62,88,56,47,62,94,36,159,190,192,236,194,61,208,60,180,61,176,170,139,189,42,16,8,1,
   16,1,66,4,98,50,95,53,74,4,254,33,186,187,42,143,9,8,18,8,16,16,1,66,4,119,49,95,54,74,128,9,
   94,246,96,62,192,218,75,190,142,119,161,190,195,144,150,62,215,41,211,189,245,246,212,62,49,112,98,62,13,169,65,189,
   24,5,162,62,181,158,3,190,55,54,135,62,2,158,115,189,247,233,136,57,224,184,158,60,24,169,235,188,125,56,245,62,
   54,168,43,62,159,29,146,61,54,55,0,189,65,140,42,190,17,141,139,189,201,190,236,62,98,14,174,61,26,59,212,62,
   247,111,227,61,119,177,192,61,212,220,31,62,215,38,186,189,144,13,224,188,27,67,173,190,94,150,187,60,155,66,145,61,
   16,233,8,63,52,51,29,190,219,236,30,190,255,39,9,63,233,2,58,190,1,196,220,188,225,213,102,190,35,71,160,189,
   237,188,138,62,173,106,253,59,61,235,63,62,212,47,105,190,18,88,28,190,67,231,168,62,2,81,27,190,179,48,2,190,
   60,163,51,62,191,35,152,190,61,201,80,62,205,214,58,62,110,81,3,61,140,0,23,62,184,61,47,62,233,47,173,62,
   32,86,1,62,5,25,194,62,210,207,27,62,210,29,48,188,217,251,126,61,115,15,215,58,65,24,245,60,241,199,189,60,
   76,4,35,60,173,43,196,61,35,189,113,190,77,34,193,62,6,188,128,62,112,83,115,62,142,134,13,190,230,197,253,190,
   10,23,151,188,182,226,160,189,153,75,1,189,132,99,238,62,40,104,17,190,5,70,96,190,72,44,194,61,19,127,142,62,
   50,189,239,189,216,209,189,62,254,124,104,62,32,23,8,190,104,98,255,56,105,107,41,190,251,237,246,189,72,88,58,190,
   125,251,194,189,142,220,194,61,195,83,103,62,58,75,232,61,220,142,93,62,70,139,118,189,118,156,20,62,126,63,62,189,
   144,25,195,60,78,76,97,62,249,144,219,58,176,55,148,62,197,11,152,62,130,209,69,190,158,92,252,186,235,244,181,61,
   251,202,112,190,61,11,160,62,183,196,157,190,156,9,157,61,150,78,90,190,163,231,34,62,56,194,209,61,255,90,5,190,
   71,188,228,61,109,37,63,190,25,2,26,189,235,77,1,191,110,48,182,62,161,25,202,190,91,93,139,190,67,112,146,190,
   148,78,97,190,178,87,161,190,85,136,16,190,104,69,10,62,178,8,193,62,64,76,11,189,71,26,7,62,230,175,232,190,
   82,207,5,61,7,252,10,190,72,206,173,61,112,114,154,61,122,54,240,189,184,32,244,189,6,233,111,190,154,144,102,190,
   39,56,74,61,71,111,192,61,246,142,96,62,65,250,86,62,129,64,128,62,0,218,176,189,166,24,240,189,246,207,252,62,
   37,217,2,190,34,74,188,189,40,58,251,60,14,246,11,62,74,252,215,189,172,240,24,62,55,45,137,61,146,103,168,62,
   234,61,253,61,92,193,53,190,89,160,134,61,126,150,9,62,112,214,93,190,243,203,125,190,189,218,133,62,85,40,164,189,
   120,239,64,62,113,250,0,62,168,110,12,62,40,97,242,61,249,76,41,189,213,59,155,62,27,11,216,60,190,140,183,190,
   85,10,236,189,113,34,21,62,184,226,90,190,207,188,151,190,113,77,159,60,255,140,133,58,200,135,156,62,234,85,48,62,
   84,91,117,62,171,87,159,189,236,135,138,189,139,209,191,188,149,128,153,190,252,113,128,190,244,224,33,62,76,86,56,62,
   132,163,79,190,140,227,155,62,115,230,172,59,93,121,21,190,10,76,65,62,23,29,100,60,29,170,192,62,165,86,134,189,
   86,249,202,189,160,23,65,189,235,215,30,190,249,170,186,61,10,195,218,189,20,104,210,188,231,93,54,190,84,183,64,61,
   220,97,143,62,59,210,90,190,101,200,222,62,241,132,219,61,143,47,37,189,234,28,233,61,129,27,75,190,205,64,18,190,
   249,99,210,61,221,19,122,59,179,237,186,190,225,183,162,62,70,12,171,61,56,254,213,62,44,39,166,189,59,219,176,62,
   91,163,172,61,228,77,130,190,2,114,20,62,208,128,18,61,135,38,124,190,114,135,181,62,182,94,82,190,174,250,248,189,
   51,97,132,62,127,5,101,62,102,16,141,190,174,165,58,59,40,100,93,62,165,113,166,188,121,148,39,190,204,105,28,62,
   65,76,242,62,79,202,221,188,66,24,182,189,102,145,211,190,196,231,11,190,25,139,10,190,49,207,191,61,184,158,34,62,
   115,104,8,190,120,58,197,188,65,117,31,190,118,169,156,62,39,128,75,190,53,28,46,60,55,136,142,61,244,36,194,190,
   197,44,181,188,105,172,166,62,24,141,58,190,118,45,162,62,55,77,24,62,174,83,141,62,135,93,184,189,83,13,200,186,
   54,198,228,190,62,134,57,189,26,198,238,61,253,25,2,190,100,96,219,188,53,105,143,62,87,117,223,190,157,45,66,189,
   58,116,52,60,14,245,172,189,140,19,207,189,254,146,208,189,157,63,27,62,235,201,5,61,90,126,1,61,152,47,184,189,
   85,144,17,63,36,45,246,60,61,187,0,191,153,55,111,190,4,238,169,189,70,88,136,61,186,20,186,190,185,145,143,61,
   15,153,134,60,72,21,106,61,96,87,150,62,164,152,164,61,93,131,60,62,242,86,169,190,9,178,149,190,121,207,155,190,
   42,76,8,16,16,1,66,4,98,49,95,54,74,64,68,129,131,61,166,209,53,189,148,134,97,61,255,138,81,188,121,126,
   230,188,33,24,120,188,30,150,243,60,93,133,71,187,229,35,247,188,140,133,255,60,87,7,167,188,33,80,107,187,249,143,
   211,188,106,198,10,189,106,187,98,60,15,120,203,188,42,78,8,16,8,1,16,1,66,4,119,50,95,54,74,64,253,216,
   33,62,104,23,165,62,207,73,48,62,212,231,199,59,115,65,150,60,241,57,147,61,194,18,38,60,25,221,67,62,52,52,
   134,62,90,182,75,190,204,36,253,60,203,65,129,61,61,122,61,62,126,230,231,61,33,15,243,187,58,63,222,189,42,16,
   8,1,16,1,66,4,98,50,95,54,74,4,160,43,90,188,42,143,9,8,18,8,16,16,1,66,4,119,49,95,55,74,
   128,9,4,16,76,186,113,45,125,62,193,88,83,190,70,200,18,61,16,67,54,62,28,51,131,190,230,245,103,62,63,234,
   140,61,38,174,208,189,8,69,152,190,208,172,191,61,50,213,94,189,187,18,223,189,57,163,13,61,65,162,123,62,127,90,
   20,62,173,89,205,61,2,211,125,61,212,177,228,61,146,57,211,61,150,129,201,62,138,46,55,189,193,245,244,61,247,187,
   145,62,147,43,4,190,244,243,50,190,245,207,160,187,43,72,34,62,189,175,143,62,150,186,66,62,133,69,179,62,66,187,
   157,190,236,6,24,189,86,9,235,60,229,251,184,60,71,97,104,188,44,254,44,190,198,52,67,190,163,178,243,62,109,116,
   196,61,250,218,42,188,234,195,191,188,199,56,33,62,25,121,59,60,237,96,178,189,110,160,129,190,42,177,35,188,37,14,
   8,190,63,175,138,190,67,73,130,62,54,91,27,189,22,82,134,190,44,198,32,62,139,96,78,62,185,14,215,188,131,147,
   0,190,79,24,94,189,181,161,3,189,135,34,156,189,108,104,223,189,119,43,235,189,248,188,98,189,186,126,77,61,177,33,
   176,190,23,155,140,190,59,173,58,190,68,157,9,190,101,181,185,189,250,4,152,190,158,134,237,189,123,43,7,62,133,79,
   3,190,223,13,218,61,104,53,1,191,217,77,168,61,75,50,51,190,206,105,28,62,40,145,12,62,191,164,79,62,129,89,
   139,190,103,198,168,61,38,10,16,62,254,43,236,62,19,142,201,61,86,214,28,189,158,140,42,189,19,35,97,61,28,234,
   132,62,54,133,65,190,113,37,245,189,69,196,194,62,197,43,65,190,161,78,157,190,58,242,151,189,9,93,185,189,189,248,
   13,189,68,56,41,190,219,122,103,190,93,14,138,61,186,92,130,190,104,143,85,190,187,94,157,62,14,92,228,60,0,37,
   228,61,169,176,182,61,245,73,98,62,55,200,254,61,141,254,18,189,166,12,158,189,195,190,223,57,110,79,214,189,117,72,
   101,190,32,217,82,189,201,109,10,61,241,133,135,61,57,110,202,62,205,253,220,189,214,192,156,190,37,226,102,190,185,57,
   0,61,97,42,31,189,214,133,117,60,157,72,163,190,138,131,149,190,192,110,176,61,182,237,22,62,51,143,43,189,228,179,
   100,62,45,233,61,190,27,92,251,190,55,113,166,61,53,141,191,62,206,221,139,189,103,100,234,62,198,199,244,189,114,90,
   169,188,193,120,145,59,110,17,202,188,94,115,130,190,169,127,5,189,152,7,182,61,250,23,83,190,29,149,159,190,111,30,
   254,189,219,139,172,189,68,5,29,60,107,57,239,59,147,248,211,189,183,146,80,188,173,94,9,62,187,63,18,190,101,203,
   165,61,241,66,175,189,111,231,210,188,222,44,47,62,3,214,184,190,226,10,231,189,134,187,119,62,240,146,48,60,61,250,
   118,62,95,35,199,62,174,156,152,188,241,11,143,60,115,12,24,190,195,156,179,187,148,169,168,189,74,202,23,63,217,165,
   191,62,184,79,53,62,211,10,11,191,87,139,240,190,8,108,123,62,165,169,178,62,11,150,100,190,220,22,211,60,245,6,
   142,189,158,122,136,62,99,238,5,61,39,69,222,60,242,181,55,59,50,185,185,190,68,162,28,191,172,121,249,189,119,203,
   199,188,155,214,9,62,175,86,238,189,161,18,201,60,25,238,145,62,228,6,35,190,147,32,27,190,105,81,66,190,234,60,
   90,189,231,123,45,189,114,66,126,190,38,228,187,61,125,80,201,60,191,161,5,191,134,178,9,62,187,1,82,62,51,143,
   35,62,197,151,122,190,33,181,78,189,241,172,170,62,243,181,171,62,162,93,35,190,116,246,66,189,132,72,189,62,135,229,
   251,189,134,19,201,62,81,178,207,61,236,171,70,190,121,11,206,61,185,123,163,61,54,208,191,190,59,198,4,61,22,27,
   159,61,205,92,113,190,39,153,162,189,134,61,157,62,132,10,11,190,51,203,158,61,19,199,49,189,211,42,199,61,42,244,
   191,61,23,126,156,62,135,7,200,60,46,224,141,60,21,175,175,62,4,238,12,61,110,69,65,62,105,76,14,62,65,53,
   137,190,180,253,207,188,95,47,152,188,121,89,160,62,183,3,76,189,51,229,242,60,28,158,200,188,72,244,230,61,197,163,
   174,62,194,72,73,62,255,84,116,62,217,85,204,61,202,182,98,61,186,62,147,190,196,11,91,190,138,196,74,188,140,238,
   42,190,137,106,16,62,215,143,154,190,79,21,198,190,43,88,156,62,251,237,205,62,75,161,73,189,61,210,168,189,186,90,
   91,62,99,21,57,61,53,113,69,61,182,55,149,62,241,180,239,61,46,106,254,189,103,249,231,61,145,167,246,189,31,242,
   65,189,48,193,135,190,92,239,104,190,43,65,121,189,59,252,13,62,183,240,220,62,181,200,243,188,204,127,20,190,179,8,
   154,62,141,236,137,62,208,227,203,61,96,248,43,190,98,69,221,61,154,71,200,190,209,152,67,190,122,29,74,62,212,195,
   44,62,106,169,147,61,113,22,194,190,167,157,51,188,232,186,27,61,36,0,178,61,184,67,167,60,190,48,92,62,197,137,
   252,189,42,76,8,16,16,1,66,4,98,49,95,55,74,64,87,170,16,60,130,69,55,189,251,93,251,60,17,30,29,188,
   160,112,11,189,0,193,167,187,42,60,187,59,58,207,27,189,233,1,109,60,215,213,3,61,35,121,214,186,7,199,141,61,
   213,223,46,60,65,225,63,61,255,158,131,188,105,11,140,187,42,78,8,16,8,1,16,1,66,4,119,50,95,55,74,64,
   230,231,230,61,175,127,95,62,35,121,216,60,72,131,116,62,55,253,152,189,74,251,15,62,49,162,194,61,31,0,82,61,
   239,232,132,189,58,162,200,61,176,159,143,61,38,223,196,189,124,207,170,189,170,166,235,189,137,172,25,62,18,124,132,189,
   42,16,8,1,16,1,66,4,98,50,95,55,74,4,202,237,17,189,42,143,9,8,18,8,16,16,1,66,4,119,49,95,
   56,74,128,9,212,249,99,189,150,150,137,190,56,201,186,62,136,4,32,190,55,171,208,189,95,216,248,189,67,54,65,62,
   17,80,100,188,223,197,10,189,45,67,169,190,112,77,202,189,171,67,140,62,26,124,162,61,217,123,11,191,41,171,175,61,
   24,116,90,62,38,124,223,61,58,29,14,190,199,84,144,61,92,66,93,190,152,10,237,189,147,215,60,62,241,247,18,62,
   55,42,247,189,5,142,62,62,112,136,32,190,7,80,71,189,160,195,36,62,183,98,135,61,120,85,43,62,91,200,7,191,
   127,227,119,190,133,217,99,189,99,126,10,190,70,177,69,62,100,223,129,62,98,250,224,189,64,109,67,62,57,86,238,61,
   191,64,55,190,23,137,227,61,192,64,235,188,24,96,118,62,201,1,72,189,101,222,108,188,68,234,10,189,197,89,157,62,
   212,86,30,62,208,97,123,189,236,148,18,190,199,144,81,61,2,223,100,190,210,107,137,188,99,245,16,62,162,71,128,190,
   250,161,119,190,93,51,26,190,172,247,182,189,236,219,186,62,136,86,44,62,161,34,108,189,200,100,103,62,46,171,43,62,
   192,105,173,61,101,191,110,189,224,41,186,61,194,244,253,60,145,88,110,190,110,140,28,190,104,12,106,190,20,118,121,189,
   181,188,157,62,50,33,44,190,164,182,11,190,202,56,101,188,225,53,10,191,205,170,98,190,49,185,147,189,4,245,191,189,
   164,202,141,188,178,254,219,62,204,118,85,61,161,235,44,190,138,20,39,190,145,57,203,188,66,156,16,62,138,73,225,188,
   230,14,241,189,255,217,195,189,140,145,207,189,181,12,81,190,23,233,199,61,126,173,140,61,178,112,41,190,221,163,111,189,
   233,82,34,62,141,57,20,62,1,72,238,190,90,154,180,189,170,17,29,62,245,201,38,58,35,107,184,61,129,214,49,62,
   220,239,25,62,94,208,102,190,188,192,134,62,180,170,150,190,96,178,198,62,173,103,124,190,169,154,125,62,101,124,4,190,
   248,65,147,62,109,237,73,188,219,43,190,189,118,232,218,61,62,221,94,190,171,196,16,190,30,14,223,61,49,95,1,190,
   112,208,171,62,195,136,84,61,170,232,202,62,200,190,190,189,254,17,28,191,88,17,193,187,72,88,69,188,244,40,9,190,
   15,1,68,61,4,120,16,63,41,247,217,61,132,171,50,190,119,12,34,189,201,179,111,190,61,62,114,190,128,130,210,189,
   138,113,129,61,186,204,202,190,77,178,175,189,80,11,38,188,234,170,174,190,104,174,81,190,36,105,189,189,106,162,154,62,
   16,235,207,62,82,90,142,61,77,221,119,190,30,91,229,61,136,19,23,60,175,33,1,188,123,5,123,62,119,245,129,190,
   162,96,15,62,127,101,252,60,100,24,187,61,245,136,131,62,188,225,180,190,49,202,203,189,234,233,165,61,194,110,240,190,
   162,24,130,189,170,115,10,190,91,204,196,189,215,7,159,60,167,1,44,190,84,68,218,190,81,215,36,62,140,45,78,189,
   123,120,160,190,108,247,12,190,76,80,40,191,244,169,44,62,164,244,163,190,102,10,40,60,170,221,42,190,123,138,135,190,
   15,175,139,62,7,177,138,62,159,118,140,190,97,227,105,62,0,85,187,61,88,73,159,62,26,32,232,61,3,146,155,190,
   247,110,114,190,163,62,0,62,75,116,60,190,52,67,157,62,255,44,40,190,38,236,82,190,189,73,6,191,73,176,94,190,
   48,145,163,61,180,101,197,190,164,107,9,190,144,250,233,187,185,232,111,189,161,42,42,62,252,176,53,190,135,109,23,62,
   173,91,54,62,182,24,93,190,227,47,44,190,130,68,211,60,3,112,166,190,221,89,3,62,123,70,48,189,32,184,133,60,
   52,71,157,62,163,135,208,187,226,177,249,190,223,80,37,61,183,221,244,59,156,214,114,190,244,190,147,189,7,172,17,62,
   118,85,13,61,35,115,29,62,64,125,58,61,88,58,81,62,4,169,195,190,217,50,131,62,15,239,231,61,209,142,244,187,
   1,2,198,189,85,250,249,61,65,73,206,61,91,132,105,187,180,39,77,62,62,162,255,189,190,50,213,60,144,13,29,62,
   158,232,128,188,82,229,201,190,51,133,5,63,131,63,237,189,61,155,65,189,194,122,33,190,213,114,204,61,55,176,212,62,
   118,247,50,62,108,13,87,60,231,55,131,61,25,233,241,61,231,205,166,62,225,142,238,189,33,207,164,62,156,8,51,190,
   152,187,190,186,128,198,59,189,151,223,237,60,181,97,61,190,185,35,5,191,36,19,119,61,37,128,68,63,145,34,213,60,
   94,245,13,190,94,17,190,62,89,117,16,62,189,4,150,61,193,86,153,62,48,235,102,190,239,191,7,189,209,45,40,190,
   175,84,249,59,202,113,133,62,183,75,26,190,82,128,4,189,93,134,68,61,135,186,38,62,172,1,47,62,2,83,35,190,
   72,223,216,62,92,238,92,190,18,162,129,188,149,141,168,62,59,128,89,62,44,94,199,62,111,247,105,62,242,150,120,62,
   156,234,149,61,215,12,161,187,223,249,201,190,182,244,117,189,86,176,24,191,196,86,98,61,202,234,70,61,108,214,184,190,
   141,231,69,190,42,76,8,16,16,1,66,4,98,49,95,56,74,64,96,108,133,61,245,58,130,189,9,86,104,60,44,223,
   161,189,47,237,57,189,177,8,83,189,95,9,153,60,134,190,161,188,79,99,76,60,15,34,20,60,141,144,18,189,13,170,
   254,60,156,245,175,188,183,199,11,189,170,77,236,61,111,30,125,61,42,78,8,16,8,1,16,1,66,4,119,50,95,56,
   74,64,120,30,154,61,225,50,129,61,168,61,58,190,239,162,219,61,232,138,206,61,15,225,229,61,40,85,87,62,164,226,
   84,190,41,44,93,190,115,195,207,62,60,210,180,61,95,90,41,190,12,123,30,63,89,205,142,190,82,96,114,190,146,121,
   78,62,42,16,8,1,16,1,66,4,98,50,95,56,74,4,46,197,245,188,90,26,10,8,102,101,97,116,117,114,101,115,
   18,14,10,12,8,1,18,8,10,2,8,1,10,2,8,18,98,38,10,20,101,110,115,101,109,98,108,101,95,112,114,111,
   98,97,98,105,108,105,116,121,18,14,10,12,8,1,18,8,10,2,8,1,10,2,8,9,66,4,10,0,16,13,114,40,
   10,15,116,114,97,105,110,105,110,103,95,112,101,114,105,111,100,18,21,50,48,50,50,45,48,49,45,48,49,47,50,48,
   50,51,45,49,50,45,51,49,114,42,10,17,118,97,108,105,100,97,116,105,111,110,95,112,101,114,105,111,100,18,21,50,
   48,50,52,45,48,49,45,48,49,47,50,48,50,52,45,49,50,45,51,49,114,146,2,10,13,102,101,97,116,117,114,101,
   95,111,114,100,101,114,18,128,2,109,111,100,117,108,101,95,97,97,97,97,59,109,111,100,117,108,101,95,98,98,98,98,
   59,109,111,100,117,108,101,95,99,99,99,99,99,99,59,109,111,100,117,108,101,95,100,100,100,100,100,59,109,111,100,117,
   108,101,95,101,101,101,101,101,101,101,59,115,105,100,101,95,98,117,121,95,115,101,108,108,59,104,111,117,114,95,115,105,
   110,59,104,111,117,114,95,99,111,115,59,100,111,119,95,115,105,110,59,100,111,119,95,99,111,115,59,101,102,102,105,99,
   105,101,110,99,121,95,100,49,95,53,59,101,102,102,105,99,105,101,110,99,121,95,100,49,95,50,48,59,97,116,114,95,
   112,99,116,95,104,49,95,49,52,59,97,116,114,95,112,99,116,95,100,49,95,49,52,59,100,49,95,114,101,116,117,114,
   110,53,95,100,105,114,95,97,116,114,59,104,49,95,109,111,109,101,110,116,117,109,49,50,95,100,105,114,95,97,116,114,
   59,104,49,95,116,114,101,110,100,53,48,95,100,105,114,95,97,116,114,59,101,110,116,114,121,95,100,105,115,116,97,110,
   99,101,95,104,49,95,97,116,114,114,58,10,18,116,114,97,105,110,105,110,103,95,111,98,106,101,99,116,105,118,101,18,
   36,112,97,121,111,102,102,45,119,101,105,103,104,116,101,100,32,98,105,110,97,114,121,32,99,114,111,115,115,32,101,110,
   116,114,111,112,121
};

struct XSModelRequest
{
   int module;
   int coreSlot;
   bool buy;
   datetime signalTime;
   double entryPrice;
   double primaryThreshold;
   double consensusThreshold;
};

enum XSModelDecision
{
   XSModelAccepted=1,
   XSPrimaryRejected=2,
   XSConsensusRejected=3,
   XSModelsUnavailable=4,
   XSFeaturesUnavailable=5,
   XSPrimaryRunFailed=6,
   XSConsensusRunFailed=7,
   XSOutputInvalid=8,
   XSModelsBypassed=9
};

struct XSModelResult
{
   XSModelDecision reason;
   double primaryMean;
   double primaryDeviation;
   double primaryScore;
   double consensusMean;
   double consensusDeviation;
   double consensusScore;
   float features[18];
   float primaryProbabilities[9];
   float consensusProbabilities[9];
};

long xsPrimaryHandle=INVALID_HANDLE;
long xsConsensusHandle=INVALID_HANDLE;
bool xsModelsReady=false;

void ReleaseXSModels()
{
   if(xsPrimaryHandle!=INVALID_HANDLE) OnnxRelease(xsPrimaryHandle);
   if(xsConsensusHandle!=INVALID_HANDLE) OnnxRelease(xsConsensusHandle);
   xsPrimaryHandle=INVALID_HANDLE;
   xsConsensusHandle=INVALID_HANDLE;
   xsModelsReady=false;
}

bool AggregateXSPredictions(const vectorf &values,double &mean,double &deviation)
{
   mean=0.0;
   deviation=0.0;
   if(values.Size()!=9) return false;
   for(int i=0;i<9;i++)
   {
      double value=(double)values[i];
      if(value<0.0 || value>1.0 || !MathIsValidNumber(value)) return false;
      mean+=value;
   }
   mean/=9.0;
   double variance=0.0;
   for(int i=8;i>=0;i--)
   {
      double difference=(double)values[i]-mean;
      variance+=difference*difference;
   }
   deviation=MathSqrt(variance/9.0);
   return MathIsValidNumber(deviation);
}

bool InitializeXSModels()
{
   ReleaseXSModels();
   ResetLastError();
   xsPrimaryHandle=OnnxCreateFromBuffer(xsPrimaryBytes,ONNX_USE_CPU_ONLY);
   if(xsPrimaryHandle==INVALID_HANDLE) return false;
   xsConsensusHandle=OnnxCreateFromBuffer(xsConsensusBytes,ONNX_USE_CPU_ONLY);
   if(xsConsensusHandle==INVALID_HANDLE)
   {
      ReleaseXSModels();
      return false;
   }
   const long inputShape[2]={1,18};
   const long outputShape[2]={1,9};
   if(!OnnxSetInputShape(xsPrimaryHandle,0,inputShape) ||
      !OnnxSetOutputShape(xsPrimaryHandle,0,outputShape) ||
      !OnnxSetInputShape(xsConsensusHandle,0,inputShape) ||
      !OnnxSetOutputShape(xsConsensusHandle,0,outputShape))
   {
      ReleaseXSModels();
      return false;
   }
   const float referenceFeatures[18]={(float)0.0,(float)0.0,(float)0.0,(float)0.0,(float)1.0,(float)-1.0,(float)-0.5,(float)-0.8660253882408142,(float)0.9749279022216797,(float)-0.22252093255519867,(float)0.176705002784729,(float)0.10834600031375885,(float)0.1581369936466217,(float)1.0710079669952393,(float)0.5519970059394836,(float)0.04907400161027908,(float)3.9849870204925537,(float)1.5247869491577148};
   vectorf featureProbe(18),primary(9),consensus(9);
   for(int i=0;i<18;i++) featureProbe[i]=referenceFeatures[i];
   double primaryMean,primaryDeviation,consensusMean,consensusDeviation;
   bool valid=OnnxRun(xsPrimaryHandle,ONNX_NO_CONVERSION,featureProbe,primary) &&
              OnnxRun(xsConsensusHandle,ONNX_NO_CONVERSION,featureProbe,consensus) &&
              AggregateXSPredictions(primary,primaryMean,primaryDeviation) &&
              AggregateXSPredictions(consensus,consensusMean,consensusDeviation);
   if(valid)
      valid=MathAbs(primaryMean-0.44308578)<=0.00002 &&
            MathAbs(primaryDeviation-0.02864060)<=0.00002 &&
            MathAbs(consensusMean-0.45247273)<=0.00002 &&
            MathAbs(consensusDeviation-0.03099993)<=0.00002;
   if(!valid)
   {
      ReleaseXSModels();
      return false;
   }
   xsModelsReady=true;
   return true;
}

int XSClosedBarShift(const ENUM_TIMEFRAMES timeframe,const datetime signalTime)
{
   int shift=iBarShift(_Symbol,timeframe,signalTime,false);
   return shift<0 ? -1 : shift+1;
}

bool XSReadClosedCloses(const ENUM_TIMEFRAMES timeframe,const datetime signalTime,
                           const int count,double &closes[])
{
   int shift=XSClosedBarShift(timeframe,signalTime);
   if(shift<0) return false;
   ArraySetAsSeries(closes,true);
   return CopyClose(_Symbol,timeframe,shift,count,closes)>=count;
}

double XSMeanTrueRange(const ENUM_TIMEFRAMES timeframe,const datetime signalTime)
{
   int shift=XSClosedBarShift(timeframe,signalTime);
   if(shift<0) return -1.0;
   MqlRates bars[];
   ArraySetAsSeries(bars,true);
   if(CopyRates(_Symbol,timeframe,shift,15,bars)<15) return -1.0;
   double total=0.0;
   for(int i=0;i<14;i++)
   {
      double gaps=MathMax(MathAbs(bars[i].high-bars[i+1].close),
                          MathAbs(bars[i].low-bars[i+1].close));
      total+=MathMax(bars[i].high-bars[i].low,gaps);
   }
   return total/14.0;
}

double XSDailyEfficiency(const datetime signalTime,const int periods)
{
   double closes[];
   if(!XSReadClosedCloses(PERIOD_D1,signalTime,periods+1,closes)) return -1.0;
   double path=0.0;
   for(int i=0;i<periods;i++) path+=MathAbs(closes[i]-closes[i+1]);
   return path>0.0 ? MathAbs(closes[0]-closes[periods])/path : 0.0;
}

double XSRangePercent(const ENUM_TIMEFRAMES timeframe,const datetime signalTime)
{
   double closes[];
   if(!XSReadClosedCloses(timeframe,signalTime,1,closes) || closes[0]<=0.0) return -1.0;
   double range=XSMeanTrueRange(timeframe,signalTime);
   return range>=0.0 ? range*100.0/closes[0] : -1.0;
}

double XSDirectionalDisplacement(const ENUM_TIMEFRAMES timeframe,const datetime signalTime,
                                     const int periods,const bool buy)
{
   double closes[];
   if(!XSReadClosedCloses(timeframe,signalTime,periods+1,closes)) return -999.0;
   double range=XSMeanTrueRange(timeframe,signalTime);
   if(range<=0.0) return -999.0;
   double difference=closes[0]-closes[periods];
   return (buy ? difference : -difference)/range;
}

bool BuildXSFeatures(const XSModelRequest &request,vectorf &features)
{
   if(request.module<0 || request.module>=9 || request.signalTime<1 || request.entryPrice<=0.0)
      return false;
   MqlDateTime time;
   if(!TimeToStruct(request.signalTime,time)) return false;
   double measures[8];
   measures[0]=XSDailyEfficiency(request.signalTime,5);
   measures[1]=XSDailyEfficiency(request.signalTime,20);
   measures[2]=XSRangePercent(PERIOD_H1,request.signalTime);
   measures[3]=XSRangePercent(PERIOD_D1,request.signalTime);
   measures[4]=XSDirectionalDisplacement(PERIOD_D1,request.signalTime,5,request.buy);
   measures[5]=XSDirectionalDisplacement(PERIOD_H1,request.signalTime,12,request.buy);
   measures[6]=-999.0;
   measures[7]=-999.0;
   double closes[];
   if(XSReadClosedCloses(PERIOD_H1,request.signalTime,50,closes))
   {
      double total=0.0;
      for(int i=0;i<50;i++) total+=closes[i];
      double range=XSMeanTrueRange(PERIOD_H1,request.signalTime);
      if(range>0.0)
      {
         double difference=total/-50.0+closes[0];
         measures[6]=(request.buy ? difference : -difference)/range;
      }
   }
   if(XSReadClosedCloses(PERIOD_H1,request.signalTime,1,closes))
   {
      double range=XSMeanTrueRange(PERIOD_H1,request.signalTime);
      if(range>0.0)
         measures[7]=(request.buy ? request.entryPrice-closes[0] : closes[0]-request.entryPrice)/range;
   }
   for(int i=0;i<8;i++)
      if(!MathIsValidNumber(measures[i]) || MathAbs(measures[i])>=100.0) return false;
   if(measures[0]<0.0 || measures[1]<0.0 || measures[2]<=0.0 || measures[3]<=0.0) return false;
   features.Resize(18);
   features.Fill(0.0f);
   int slot=request.module<5 ? request.module : 0;
   if(request.coreSlot>=0 && request.coreSlot<5) slot=request.coreSlot;
   features[slot]=1.0f;
   features[5]=request.buy ? 1.0f : -1.0f;
   const double fullTurn=6.283185307179586;
   features[6]=(float)MathSin(time.hour*fullTurn/24.0);
   features[7]=(float)MathCos(time.hour*fullTurn/24.0);
   features[8]=(float)MathSin(time.day_of_week*fullTurn/7.0);
   features[9]=(float)MathCos(time.day_of_week*fullTurn/7.0);
   for(int i=0;i<8;i++) features[i+10]=(float)measures[i];
   return true;
}

void ResetXSModelResult(XSModelResult &result)
{
   result.reason=XSModelsUnavailable;
   result.primaryMean=-999.0;
   result.primaryDeviation=-999.0;
   result.primaryScore=-999.0;
   result.consensusMean=-999.0;
   result.consensusDeviation=-999.0;
   result.consensusScore=-999.0;
   ArrayInitialize(result.features,-999.0f);
   ArrayInitialize(result.primaryProbabilities,-999.0f);
   ArrayInitialize(result.consensusProbabilities,-999.0f);
}

void CopyXSModelSnapshot(const vectorf &values,float &snapshot[],const int count)
{
   if(values.Size()!=(ulong)count) return;
   for(int i=0;i<count;i++) snapshot[i]=values[i];
}

bool XSAiModeUsesFilter(const int mode)
{
   return mode==1 || mode==2;
}

bool EvaluateXSModels(const XSModelRequest &request,const bool filterEnabled,
                          const bool collectRejectedConsensus,XSModelResult &result)
{
   ResetXSModelResult(result);
   if(!filterEnabled)
   {
      result.reason=XSModelsBypassed;
      return true;
   }
   if(!xsModelsReady || xsPrimaryHandle==INVALID_HANDLE ||
      xsConsensusHandle==INVALID_HANDLE) return false;
   vectorf features(18),primary(9),consensus(9);
   features.Fill(-999.0f);
   primary.Fill(-999.0f);
   consensus.Fill(-999.0f);
   bool featuresBuilt=BuildXSFeatures(request,features);
   CopyXSModelSnapshot(features,result.features,18);
   if(!featuresBuilt)
   {
      result.reason=XSFeaturesUnavailable;
      return false;
   }
   bool primaryRan=OnnxRun(xsPrimaryHandle,ONNX_NO_CONVERSION,features,primary);
   CopyXSModelSnapshot(primary,result.primaryProbabilities,9);
   if(!primaryRan)
   {
      result.reason=XSPrimaryRunFailed;
      return false;
   }
   if(!AggregateXSPredictions(primary,result.primaryMean,result.primaryDeviation))
   {
      result.reason=XSOutputInvalid;
      return false;
   }
   result.primaryScore=result.primaryMean-0.25*result.primaryDeviation;
   if(result.primaryScore<request.primaryThreshold)
   {
      result.reason=XSPrimaryRejected;
      if(collectRejectedConsensus)
      {
         bool consensusRan=OnnxRun(xsConsensusHandle,ONNX_NO_CONVERSION,features,consensus);
         CopyXSModelSnapshot(consensus,result.consensusProbabilities,9);
         double mean,deviation;
         if(consensusRan && AggregateXSPredictions(consensus,mean,deviation))
         {
            result.consensusMean=mean;
            result.consensusDeviation=deviation;
            result.consensusScore=mean;
         }
      }
      return false;
   }
   bool consensusRan=OnnxRun(xsConsensusHandle,ONNX_NO_CONVERSION,features,consensus);
   CopyXSModelSnapshot(consensus,result.consensusProbabilities,9);
   if(!consensusRan)
   {
      result.reason=XSConsensusRunFailed;
      return false;
   }
   if(!AggregateXSPredictions(consensus,result.consensusMean,result.consensusDeviation))
   {
      result.reason=XSOutputInvalid;
      return false;
   }
   result.consensusScore=result.consensusMean;
   result.reason=result.consensusScore>=request.consensusThreshold ? XSModelAccepted : XSConsensusRejected;
   return result.reason==XSModelAccepted;
}

double XSAdaptiveSizeMultiplier(const bool enabled,const int aiMode,const int sizingMode,
                                     const double primaryScore,const double consensusScore,
                                     const double trigger=0.577811425,
                                     const double baseMultiplier=1.0,const double boostedMultiplier=1.5)
{
   if(enabled && XSAiModeUsesFilter(aiMode) && sizingMode!=0 && sizingMode!=4 && sizingMode!=5 &&
      (primaryScore+consensusScore)*0.5>=trigger) return boostedMultiplier;
   return baseMultiplier;
}

struct XSCandidateContext
{
   bool valid;
   ulong candidateHigh;
   ulong candidateLow;
   long timeMilliseconds;
   datetime decisionTime;
   datetime refreshBar;
   datetime expiration;
   double pivot;
   double stopLoss;
   double takeProfit;
   double bid;
   double ask;
};

struct XSCandidateRecord
{
   XSCandidateContext context;
   XSModelRequest request;
   XSModelResult result;
   double lot;
   ulong inferenceMicroseconds;
};

struct XSCandidateLogState
{
   bool active;
   bool researcherInstrumentation;
   bool fault;
   bool handleOpen;
   int handle;
   int fileSlot;
   long writtenBytes;
   datetime lastFlush;
   ulong sessionId;
   ulong scopeId;
   string buildId;
   string folder;
   int count;
   int seenCount;
   int nextSeen;
   ulong dropped;
};

XSCandidateLogState xsCandidateLog;
XSCandidateRecord xsCandidateQueue[64];
ulong xsSeenCandidateHigh[512],xsSeenCandidateLow[512];

string XSCandidateCsvHeader()
{
   return "schema,record_id,session_id,time_msc,candidate_hi,candidate_lo,scope_id,build_id,feature_schema,module,side,decision_time,refresh_bar,expiration,pivot,entry,sl,tp,bid,ask,spread,lot,decision,primary_threshold,primary_penalty,primary_mean,primary_std,primary_quality,p00,p01,p02,p03,p04,p05,p06,p07,p08,consensus_threshold,consensus_penalty,consensus_mean,consensus_std,consensus_quality,c00,c01,c02,c03,c04,c05,c06,c07,c08,model_disagreement,inference_us,f00,f01,f02,f03,f04,f05,f06,f07,f08,f09,f10,f11,f12,f13,f14,f15,f16,f17,crc32";
}

string XSCandidateModuleCode(const int module)
{
   const string codes[9]={"S1","S2","S3","S4","S5","S6","S7","S8","S9"};
   return module>=0 && module<9 ? codes[module] : "UNKNOWN";
}

string XSModelDecisionText(const XSModelDecision decision)
{
   switch(decision)
   {
      case XSModelAccepted: return "ACCEPTED";
      case XSPrimaryRejected: return "VETO_PRIMARY";
      case XSConsensusRejected: return "VETO_CONSENSUS";
      case XSModelsUnavailable: return "AI_NOT_READY";
      case XSFeaturesUnavailable: return "FEATURE_ERROR";
      case XSPrimaryRunFailed: return "PRIMARY_INFERENCE_ERROR";
      case XSConsensusRunFailed: return "CONSENSUS_INFERENCE_ERROR";
      case XSOutputInvalid: return "MODEL_OUTPUT_ERROR";
      case XSModelsBypassed: return "BYPASS";
   }
   return "UNKNOWN";
}

string XSCsvNumber(const double value)
{
   return MathIsValidNumber(value) ? DoubleToString(value,8) : "nan";
}

void AppendXSCsvNumber(string &row,const double value)
{
   row+=","+XSCsvNumber(value);
}

int XSCsvChecksum(const string row)
{
   uint crc=0xffffffff;
   for(int i=0;i<StringLen(row);i++)
   {
      crc^=(uint)(StringGetCharacter(row,i)&0xff);
      for(int bit=0;bit<8;bit++) crc=(crc>>1)^((crc&1)!=0 ? (uint)0xedb88320 : (uint)0);
   }
   return (int)~crc;
}

string RenderXSCandidateCsv(const XSCandidateRecord &record,long &sharedRecordId)
{
   sharedRecordId++;
   string row="MDT2_CANDIDATE_V1,"+StringFormat("%I64d",sharedRecordId);
   row+=","+StringFormat("%I64u",xsCandidateLog.sessionId);
   row+=","+StringFormat("%I64d",record.context.timeMilliseconds);
   row+=","+StringFormat("%I64u",record.context.candidateHigh);
   row+=","+StringFormat("%I64u",record.context.candidateLow);
   row+=","+StringFormat("%I64u",xsCandidateLog.scopeId);
   row+=","+xsCandidateLog.buildId+",XAUSCALPER_5_18_V1";
   row+=","+XSCandidateModuleCode(record.request.module);
   row+=","+IntegerToString(record.request.buy ? 1 : -1);
   row+=","+IntegerToString((int)record.context.decisionTime);
   row+=","+IntegerToString((int)record.context.refreshBar);
   row+=","+IntegerToString((int)record.context.expiration);
   AppendXSCsvNumber(row,record.context.pivot);
   AppendXSCsvNumber(row,record.request.entryPrice);
   AppendXSCsvNumber(row,record.context.stopLoss);
   AppendXSCsvNumber(row,record.context.takeProfit);
   AppendXSCsvNumber(row,record.context.bid);
   AppendXSCsvNumber(row,record.context.ask);
   AppendXSCsvNumber(row,record.context.ask-record.context.bid);
   AppendXSCsvNumber(row,record.lot);
   row+=","+XSModelDecisionText(record.result.reason);
   AppendXSCsvNumber(row,record.request.primaryThreshold);
   AppendXSCsvNumber(row,0.25);
   AppendXSCsvNumber(row,record.result.primaryMean);
   AppendXSCsvNumber(row,record.result.primaryDeviation);
   AppendXSCsvNumber(row,record.result.primaryScore);
   for(int i=0;i<9;i++) AppendXSCsvNumber(row,(double)record.result.primaryProbabilities[i]);
   AppendXSCsvNumber(row,record.request.consensusThreshold);
   AppendXSCsvNumber(row,0.0);
   AppendXSCsvNumber(row,record.result.consensusMean);
   AppendXSCsvNumber(row,record.result.consensusDeviation);
   AppendXSCsvNumber(row,record.result.consensusScore);
   for(int i=0;i<9;i++) AppendXSCsvNumber(row,(double)record.result.consensusProbabilities[i]);
   AppendXSCsvNumber(row,MathAbs(record.result.primaryMean-record.result.consensusMean));
   row+=","+StringFormat("%I64u",record.inferenceMicroseconds);
   for(int i=0;i<18;i++) AppendXSCsvNumber(row,(double)record.result.features[i]);
   return row+","+IntegerToString(XSCsvChecksum(row))+"\r\n";
}

string XSCandidateLogPath(const int slot)
{
   return xsCandidateLog.folder+"\\MDT2_candidate_"+StringFormat("%02d",slot)+".csv";
}

bool OpenXSCandidateLogFile(const bool initial)
{
   const long capacity=4194304;
   int slot=(xsCandidateLog.fileSlot+1)%4;
   if(initial)
   {
      slot=-1;
      long newest=0;
      for(int i=0;i<4;i++)
      {
         string path=XSCandidateLogPath(i);
         if(!FileIsExist(path)) continue;
         int reader=FileOpen(path,FILE_READ|FILE_BIN|FILE_SHARE_READ|FILE_SHARE_WRITE);
         if(reader==INVALID_HANDLE) continue;
         long size=(long)FileSize(reader);
         FileClose(reader);
         if(size<0 || size>=capacity) continue;
         long modified=FileGetInteger(path,FILE_MODIFY_DATE);
         if(slot<0 || newest<=modified)
         {
            newest=modified;
            slot=i;
         }
      }
      if(slot<0)
      {
         for(int i=0;i<4;i++)
            if(!FileIsExist(XSCandidateLogPath(i))) { slot=i; break; }
         if(slot<0) slot=0;
      }
   }
   string path=XSCandidateLogPath(slot);
   if(!initial && FileIsExist(path) && !FileDelete(path)) return false;
   int handle=FileOpen(path,FILE_READ|FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_SHARE_READ,0,CP_UTF8);
   if(handle==INVALID_HANDLE) return false;
   FileSeek(handle,0,SEEK_END);
   long size=(long)FileSize(handle);
   if(size==0)
   {
      uint written=FileWriteString(handle,XSCandidateCsvHeader()+"\r\n");
      if(written==0) { FileClose(handle); return false; }
      size=(long)written;
   }
   xsCandidateLog.handle=handle;
   xsCandidateLog.handleOpen=true;
   xsCandidateLog.fileSlot=slot;
   xsCandidateLog.writtenBytes=size;
   xsCandidateLog.lastFlush=TimeLocal();
   return true;
}

void CloseXSCandidateLog()
{
   if(xsCandidateLog.handleOpen && xsCandidateLog.handle!=INVALID_HANDLE)
   {
      FileFlush(xsCandidateLog.handle);
      FileClose(xsCandidateLog.handle);
   }
   xsCandidateLog.handle=INVALID_HANDLE;
   xsCandidateLog.handleOpen=false;
   xsCandidateLog.active=false;
}

bool InitializeXSCandidateLog(const bool requested,const ulong sessionId,const ulong scopeId,
                                   const string buildId,const bool researcherInstrumentation=false)
{
   CloseXSCandidateLog();
   ZeroMemory(xsCandidateLog);
   xsCandidateLog.handle=INVALID_HANDLE;
   xsCandidateLog.researcherInstrumentation=researcherInstrumentation;
   xsCandidateLog.sessionId=sessionId;
   xsCandidateLog.scopeId=scopeId;
   xsCandidateLog.buildId=buildId;
   xsCandidateLog.folder=researcherInstrumentation ? "XAUscalperResearchTelemetry" : "XAUscalperTelemetry";
   if(!requested || (!researcherInstrumentation &&
      (MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_OPTIMIZATION)))) return true;
   FolderCreate(xsCandidateLog.folder);
   xsCandidateLog.active=OpenXSCandidateLogFile(true);
   xsCandidateLog.fault=!xsCandidateLog.active;
   return xsCandidateLog.active;
}

bool XSCandidateWasLogged(const ulong high,const ulong low)
{
   for(int i=0;i<xsCandidateLog.seenCount;i++)
      if(xsSeenCandidateHigh[i]==high && xsSeenCandidateLow[i]==low) return true;
   return false;
}

bool QueueXSCandidateLog(const XSCandidateContext &context,const XSModelRequest &request,
                             const XSModelResult &result,const ulong inferenceMicroseconds)
{
   if(!xsCandidateLog.active || !context.valid ||
      XSCandidateWasLogged(context.candidateHigh,context.candidateLow)) return false;
   if(xsCandidateLog.count>=64)
   {
      xsCandidateLog.dropped++;
      xsCandidateLog.fault=true;
      return false;
   }
   int index=xsCandidateLog.count++;
   xsCandidateQueue[index].context=context;
   xsCandidateQueue[index].request=request;
   xsCandidateQueue[index].result=result;
   xsCandidateQueue[index].lot=0.0;
   xsCandidateQueue[index].inferenceMicroseconds=inferenceMicroseconds;
   int seen=xsCandidateLog.seenCount<512 ? xsCandidateLog.seenCount++ : xsCandidateLog.nextSeen;
   xsSeenCandidateHigh[seen]=context.candidateHigh;
   xsSeenCandidateLow[seen]=context.candidateLow;
   if(xsCandidateLog.seenCount>=512) xsCandidateLog.nextSeen=(seen+1)%512;
   BeginXSRejectedShadow(context,request,result);
   return true;
}

bool FlushXSCandidateLog(long &sharedRecordId)
{
   if(xsCandidateLog.count==0) return true;
   if(!xsCandidateLog.active || xsCandidateLog.handle==INVALID_HANDLE) return false;
   string batch="";
   for(int i=0;i<xsCandidateLog.count;i++) batch+=RenderXSCandidateCsv(xsCandidateQueue[i],sharedRecordId);
   if(xsCandidateLog.writtenBytes+(long)StringLen(batch)>4194304)
   {
      FileFlush(xsCandidateLog.handle);
      FileClose(xsCandidateLog.handle);
      xsCandidateLog.handle=INVALID_HANDLE;
      if(!OpenXSCandidateLogFile(false)) { xsCandidateLog.fault=true; return false; }
   }
   uint written=FileWriteString(xsCandidateLog.handle,batch);
   if(written==0) { xsCandidateLog.fault=true; return false; }
   xsCandidateLog.writtenBytes+=(long)written;
   datetime now=TimeLocal();
   if(now-xsCandidateLog.lastFlush>=30)
   {
      FileFlush(xsCandidateLog.handle);
      xsCandidateLog.lastFlush=now;
   }
   xsCandidateLog.count=0;
   return true;
}

struct XSLearningEvent
{
   ulong candidateHigh,candidateLow;
   long timeMilliseconds;
   int eventType,transactionType,orderType,orderState,dealType;
   ulong orderRef,dealRef,positionRef;
   int retcode,terminalError;
   double requestedPrice,referencePrice,fillPrice,volume,bid,ask,stopLoss,takeProfit;
   ulong latencyMicroseconds;
   int module,side,reason;
};

struct XSLearningOutcome
{
   ulong candidateHigh,candidateLow;
   long timeMilliseconds;
   int kind,module,side,finalState,closeReason,qualityFlags;
   long openMilliseconds,closeMilliseconds;
   ulong orderRef,positionRef;
   double requestedEntry,entryVwap,entryVolume,entrySlippage,spreadDecision,spreadFill,maxSpread;
   double initialStopLoss,initialTakeProfit,initialRiskPrice,initialRiskMoney;
   double exitReference,exitVwap,exitVolume,exitSlippage,grossProfit,swap,commission,fee,netPnl,resultR;
   double mfePrice,maePrice,primaryMargin,consensusMargin;
};

struct XSRejectedShadow
{
   bool active;
   ulong candidateHigh,candidateLow;
   int module,side,state;
   long decisionMilliseconds,expirationMilliseconds,openMilliseconds;
   double entry,stopLoss,takeProfit,fillPrice,spreadDecision,spreadFill,maxSpread,mfe,mae;
   double primaryMargin,consensusMargin;
};

struct XSLearningFile
{
   bool handleOpen;
   int handle,slot;
   long writtenBytes,capacity;
   datetime lastFlush;
   string kind,header;
};

XSLearningEvent xsLearningEvents[256];
XSLearningOutcome xsLearningOutcomes[64];
XSRejectedShadow xsRejectedShadows[128];
int xsLearningEventCount=0,xsLearningOutcomeCount=0;
int xsActiveShadows[128],xsActiveShadowCount=0;
XSLearningFile xsEventFile,xsOutcomeFile;
bool xsLearningRequested=false;
datetime xsLearningRetryAfter=0;
long xsLearningRecordId=0;
double xsLearningPoint=0.0,xsLearningTickSize=0.0,xsLearningTickValue=0.0;

struct XSLearningPending
{
   bool active;
   ulong candidateHigh,candidateLow,orderRef;
   int module,side;
   long decisionMilliseconds;
   double entry,stopLoss,takeProfit,lot,spreadDecision,primaryMargin,consensusMargin;
};

struct XSLearningPosition
{
   bool active;
   ulong candidateHigh,candidateLow,orderRef,positionRef;
   int module,side,closeReason,qualityFlags;
   long openMilliseconds,closeMilliseconds;
   double requestedEntry,stopLoss,takeProfit,riskPrice,entryPriceVolume,entryVolume;
   double exitReferenceVolume,exitPriceVolume,exitVolume,grossProfit,swap,commission,fee;
   double mfe,mae,spreadDecision,spreadFill,maxSpread,primaryMargin,consensusMargin;
};

struct XSLearningTransaction
{
   long timeMilliseconds;
   int retries,transactionType,orderType,orderState,dealType;
   ulong orderRef,dealRef,positionRef;
   int retcode;
   double price,stopLoss,takeProfit,volume,bid,ask;
};

XSLearningPending xsLearningPending[256];
XSLearningPosition xsLearningPositions[64];
XSLearningTransaction xsLearningTransactions[256];
int xsLearningTransactionHead=0,xsLearningTransactionCount=0;

ulong XSLearningHashStep(const ulong seed,const ulong value)
{
   ulong result=(seed^value)*(ulong)0x100000001b3;
   return (result&(ulong)0x7fffffffffffffff)^(result>>32);
}

ulong XSLearningHashText(ulong seed,const string value)
{
   for(int i=0;i<StringLen(value);i++) seed=XSLearningHashStep(seed,(ulong)StringGetCharacter(value,i));
   return seed;
}

ulong XSLearningReference(const ulong ticket)
{
   return ticket==0 ? 0 : XSLearningHashStep(xsCandidateLog.scopeId,ticket);
}

long XSLearningTimestamp()
{
   MqlTick tick;
   if(SymbolInfoTick(_Symbol,tick) && tick.time_msc>0) return tick.time_msc;
   datetime now=TimeTradeServer();
   if(now<1) now=TimeCurrent();
   if(now<1) now=TimeLocal();
   return (long)now*1000;
}

string XSLearningEventName(const int eventType)
{
   switch(eventType)
   {
      case 1:return "SESSION_START";
      case 2:return "SESSION_END";
      case 10:return "ORDER_CHECK_REJECTED";
      case 11:return "ORDER_SEND_REJECTED";
      case 12:return "ORDER_PLACED";
      case 13:return "ORDER_ADDED";
      case 14:return "ORDER_UPDATED";
      case 15:return "ORDER_DELETED";
      case 20:return "ENTRY_DEAL";
      case 21:return "EXIT_DEAL";
      case 22:return "POSITION_CLOSED";
      case 30:return "SHADOW_PENDING";
      case 31:return "SHADOW_FILLED";
      case 32:return "SHADOW_TERMINAL";
      case 40:return "LOCAL_GATE";
   }
   return "UNKNOWN";
}

string XSLearningRowPrefix(const string schema,const long timeMilliseconds,
                                const ulong high,const ulong low)
{
   xsLearningRecordId++;
   return schema+","+StringFormat("%I64d",xsLearningRecordId)+","+
          StringFormat("%I64u",xsCandidateLog.sessionId)+","+StringFormat("%I64d",timeMilliseconds)+","+
          StringFormat("%I64u",high)+","+StringFormat("%I64u",low);
}

string RenderXSLearningEvent(const XSLearningEvent &event)
{
   string row=XSLearningRowPrefix("MDT2_EVENT_V1",event.timeMilliseconds,event.candidateHigh,event.candidateLow);
   row+=","+XSLearningEventName(event.eventType)+","+IntegerToString(event.transactionType);
   row+=","+IntegerToString(event.orderType)+","+IntegerToString(event.orderState)+","+IntegerToString(event.dealType);
   row+=","+StringFormat("%I64u",XSLearningReference(event.orderRef));
   row+=","+StringFormat("%I64u",XSLearningReference(event.dealRef));
   row+=","+StringFormat("%I64u",XSLearningReference(event.positionRef));
   row+=","+IntegerToString(event.retcode)+","+IntegerToString(event.terminalError);
   AppendXSCsvNumber(row,event.requestedPrice);
   AppendXSCsvNumber(row,event.referencePrice);
   AppendXSCsvNumber(row,event.fillPrice);
   AppendXSCsvNumber(row,event.volume);
   AppendXSCsvNumber(row,event.bid);
   AppendXSCsvNumber(row,event.ask);
   AppendXSCsvNumber(row,event.ask-event.bid);
   AppendXSCsvNumber(row,event.stopLoss);
   AppendXSCsvNumber(row,event.takeProfit);
   row+=","+StringFormat("%I64u",event.latencyMicroseconds)+","+XSCandidateModuleCode(event.module);
   row+=","+IntegerToString(event.side)+","+IntegerToString(event.reason);
   return row+","+IntegerToString(XSCsvChecksum(row))+"\r\n";
}

string RenderXSLearningOutcome(const XSLearningOutcome &outcome)
{
   string row=XSLearningRowPrefix("MDT2_OUTCOME_V1",outcome.timeMilliseconds,outcome.candidateHigh,outcome.candidateLow);
   row+=outcome.kind==1 ? ",REAL" : ",SHADOW_VETO";
   row+=","+XSCandidateModuleCode(outcome.module)+","+IntegerToString(outcome.side);
   row+=","+IntegerToString(outcome.finalState)+","+IntegerToString(outcome.closeReason)+","+IntegerToString(outcome.qualityFlags);
   row+=","+StringFormat("%I64d",outcome.openMilliseconds)+","+StringFormat("%I64d",outcome.closeMilliseconds);
   row+=","+StringFormat("%I64u",XSLearningReference(outcome.orderRef));
   row+=","+StringFormat("%I64u",XSLearningReference(outcome.positionRef));
   AppendXSCsvNumber(row,outcome.requestedEntry);
   AppendXSCsvNumber(row,outcome.entryVwap);
   AppendXSCsvNumber(row,outcome.entryVolume);
   AppendXSCsvNumber(row,outcome.entrySlippage);
   AppendXSCsvNumber(row,outcome.spreadDecision);
   AppendXSCsvNumber(row,outcome.spreadFill);
   AppendXSCsvNumber(row,outcome.maxSpread);
   AppendXSCsvNumber(row,outcome.initialStopLoss);
   AppendXSCsvNumber(row,outcome.initialTakeProfit);
   AppendXSCsvNumber(row,outcome.initialRiskPrice);
   AppendXSCsvNumber(row,outcome.initialRiskMoney);
   AppendXSCsvNumber(row,outcome.exitReference);
   AppendXSCsvNumber(row,outcome.exitVwap);
   AppendXSCsvNumber(row,outcome.exitVolume);
   AppendXSCsvNumber(row,outcome.exitSlippage);
   AppendXSCsvNumber(row,outcome.grossProfit);
   AppendXSCsvNumber(row,outcome.swap);
   AppendXSCsvNumber(row,outcome.commission);
   AppendXSCsvNumber(row,outcome.fee);
   AppendXSCsvNumber(row,outcome.netPnl);
   AppendXSCsvNumber(row,outcome.resultR);
   AppendXSCsvNumber(row,outcome.mfePrice);
   AppendXSCsvNumber(row,outcome.maePrice);
   AppendXSCsvNumber(row,outcome.primaryMargin);
   AppendXSCsvNumber(row,outcome.consensusMargin);
   return row+","+IntegerToString(XSCsvChecksum(row))+"\r\n";
}

bool QueueXSLearningEvent(const XSLearningEvent &event)
{
   if(!xsCandidateLog.active) return false;
   if(xsLearningEventCount>=256)
   {
      xsCandidateLog.dropped++;
      xsCandidateLog.fault=true;
      return false;
   }
   xsLearningEvents[xsLearningEventCount++]=event;
   return true;
}

bool QueueXSLearningOutcome(const XSLearningOutcome &outcome)
{
   if(!xsCandidateLog.active) return false;
   if(xsLearningOutcomeCount>=64)
   {
      xsCandidateLog.dropped++;
      xsCandidateLog.fault=true;
      return false;
   }
   xsLearningOutcomes[xsLearningOutcomeCount++]=outcome;
   return true;
}

void QueueXSLearningStateEvent(const int eventType,const ulong high,const ulong low,
                                   const long timeMilliseconds,const int module,const int side,const int reason=0)
{
   XSLearningEvent event;
   ZeroMemory(event);
   event.candidateHigh=high;event.candidateLow=low;event.timeMilliseconds=timeMilliseconds;
   event.eventType=eventType;event.module=module;event.side=side;event.reason=reason;
   QueueXSLearningEvent(event);
}

string XSLearningFilePath(const XSLearningFile &file,const int slot)
{
   return xsCandidateLog.folder+"\\MDT2_"+file.kind+"_"+StringFormat("%02d",slot)+".csv";
}

void CloseXSLearningFile(XSLearningFile &file)
{
   if(file.handleOpen && file.handle!=INVALID_HANDLE) { FileFlush(file.handle);FileClose(file.handle); }
   file.handle=INVALID_HANDLE;file.handleOpen=false;
}

bool OpenXSLearningFile(XSLearningFile &file,const bool initial)
{
   int slot=(file.slot+1)%4;
   if(initial)
   {
      slot=-1;
      long newest=0;
      for(int i=0;i<4;i++)
      {
         string path=XSLearningFilePath(file,i);
         if(!FileIsExist(path)) continue;
         int reader=FileOpen(path,FILE_READ|FILE_BIN|FILE_SHARE_READ|FILE_SHARE_WRITE);
         if(reader==INVALID_HANDLE) continue;
         long size=(long)FileSize(reader);
         FileClose(reader);
         if(size<0 || size>=file.capacity) continue;
         long modified=FileGetInteger(path,FILE_MODIFY_DATE);
         if(slot<0 || newest<=modified) { newest=modified;slot=i; }
      }
      if(slot<0)
      {
         for(int i=0;i<4;i++) if(!FileIsExist(XSLearningFilePath(file,i))) { slot=i;break; }
         if(slot<0) slot=0;
      }
   }
   string path=XSLearningFilePath(file,slot);
   if(!initial && FileIsExist(path) && !FileDelete(path)) return false;
   int handle=FileOpen(path,FILE_READ|FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_SHARE_READ,0,CP_UTF8);
   if(handle==INVALID_HANDLE) return false;
   FileSeek(handle,0,SEEK_END);
   long size=(long)FileSize(handle);
   if(size==0)
   {
      uint written=FileWriteString(handle,file.header+"\r\n");
      if(written==0) { FileClose(handle);return false; }
      size=(long)written;
   }
   file.handleOpen=true;file.handle=handle;file.slot=slot;file.writtenBytes=size;file.lastFlush=TimeLocal();
   return true;
}

bool WriteXSLearningBatch(XSLearningFile &file,const string batch)
{
   if(file.handle==INVALID_HANDLE || StringLen(batch)==0) return false;
   if(file.writtenBytes+(long)StringLen(batch)>file.capacity)
   {
      CloseXSLearningFile(file);
      if(!OpenXSLearningFile(file,false)) return false;
   }
   uint written=FileWriteString(file.handle,batch);
   if(written==0) return false;
   file.writtenBytes+=(long)written;
   datetime now=TimeLocal();
   if(now-file.lastFlush>=30) { FileFlush(file.handle);file.lastFlush=now; }
   return true;
}

bool FlushXSLearningLog()
{
   if(!FlushXSCandidateLog(xsLearningRecordId)) return false;
   string batch="";
   for(int i=0;i<xsLearningEventCount;i++) batch+=RenderXSLearningEvent(xsLearningEvents[i]);
   if(StringLen(batch)>0 && !WriteXSLearningBatch(xsEventFile,batch)) return false;
   xsLearningEventCount=0;
   batch="";
   for(int i=0;i<xsLearningOutcomeCount;i++) batch+=RenderXSLearningOutcome(xsLearningOutcomes[i]);
   if(StringLen(batch)>0 && !WriteXSLearningBatch(xsOutcomeFile,batch)) return false;
   xsLearningOutcomeCount=0;
   return true;
}

void SuspendXSLearningLog()
{
   CloseXSCandidateLog();
   CloseXSLearningFile(xsEventFile);
   CloseXSLearningFile(xsOutcomeFile);
   xsCandidateLog.fault=false;
   xsCandidateLog.count=0;xsLearningEventCount=0;xsLearningOutcomeCount=0;
   xsLearningTransactionHead=0;xsLearningTransactionCount=0;
   for(int i=0;i<256;i++) xsLearningPending[i].active=false;
   for(int i=0;i<64;i++) xsLearningPositions[i].active=false;
   for(int i=0;i<128;i++) xsRejectedShadows[i].active=false;
   xsActiveShadowCount=0;
   xsLearningRetryAfter=TimeLocal()+300;
}

void PrepareXSCandidateContext(const XSModelRequest &request,const datetime decisionTime,
                                    const datetime refreshBar,const datetime expiration,const double pivot,
                                    const double stopLoss,const double takeProfit,const double bid,const double ask,
                                    XSCandidateContext &context)
{
   ZeroMemory(context);
   if(!xsCandidateLog.active) return;
   double unit=xsLearningTickSize;
   if(unit<=0.0) unit=xsLearningPoint>0.0 ? xsLearningPoint : 0.01;
   long pivotUnits=(long)MathRound(pivot/unit),entryUnits=(long)MathRound(request.entryPrice/unit);
   ulong pivotKey=(ulong)(pivotUnits<0 ? -pivotUnits : pivotUnits);
   ulong entryKey=(ulong)(entryUnits<0 ? -entryUnits : entryUnits);
   ulong high=XSLearningHashStep(xsCandidateLog.scopeId,(ulong)(request.module+1));
   high=XSLearningHashStep(high,request.buy ? 1 : 2);
   high=XSLearningHashStep(high,(ulong)refreshBar);
   high=XSLearningHashStep(high,pivotKey);
   ulong low=XSLearningHashStep(xsCandidateLog.scopeId,(ulong)0x6c62272e07bb0142);
   low=XSLearningHashStep(low,entryKey);
   low=XSLearningHashStep(low,(ulong)refreshBar);
   low=XSLearningHashStep(low,(ulong)(request.module+17));
   if(high==0 && low==0) low=1;
   context.valid=true;context.candidateHigh=high;context.candidateLow=low;
   context.timeMilliseconds=XSLearningTimestamp();context.decisionTime=decisionTime;
   context.refreshBar=refreshBar;context.expiration=expiration;context.pivot=pivot;
   context.stopLoss=stopLoss;context.takeProfit=takeProfit;context.bid=bid;context.ask=ask;
}

void BeginXSRejectedShadow(const XSCandidateContext &context,const XSModelRequest &request,
                                const XSModelResult &result)
{
   if(result.reason!=XSPrimaryRejected && result.reason!=XSConsensusRejected) return;
   for(int i=0;i<128;i++)
   {
      if(xsRejectedShadows[i].active) continue;
      XSRejectedShadow shadow;
      ZeroMemory(shadow);
      shadow.active=true;shadow.candidateHigh=context.candidateHigh;shadow.candidateLow=context.candidateLow;
      shadow.module=request.module;shadow.side=request.buy ? 1 : -1;shadow.state=1;
      shadow.decisionMilliseconds=context.timeMilliseconds;shadow.expirationMilliseconds=(long)context.expiration*1000;
      shadow.entry=request.entryPrice;shadow.stopLoss=context.stopLoss;shadow.takeProfit=context.takeProfit;
      shadow.spreadDecision=MathMax(0.0,context.ask-context.bid);shadow.maxSpread=shadow.spreadDecision;
      shadow.primaryMargin=result.primaryScore-request.primaryThreshold;
      shadow.consensusMargin=result.consensusScore-request.consensusThreshold;
      xsRejectedShadows[i]=shadow;
      if(xsActiveShadowCount<128) xsActiveShadows[xsActiveShadowCount++]=i;
      QueueXSLearningStateEvent(30,shadow.candidateHigh,shadow.candidateLow,context.timeMilliseconds,shadow.module,shadow.side);
      return;
   }
}

void FinishXSRejectedShadow(const int index,const int finalState,const long timeMilliseconds,const double price)
{
   if(index<0 || index>=128 || !xsRejectedShadows[index].active) return;
   XSRejectedShadow shadow=xsRejectedShadows[index];
   XSLearningOutcome outcome;
   ZeroMemory(outcome);
   outcome.candidateHigh=shadow.candidateHigh;outcome.candidateLow=shadow.candidateLow;
   outcome.timeMilliseconds=timeMilliseconds;outcome.kind=2;outcome.module=shadow.module;
   outcome.side=shadow.side;outcome.finalState=finalState;outcome.qualityFlags=256;
   outcome.openMilliseconds=shadow.openMilliseconds;outcome.closeMilliseconds=timeMilliseconds;
   outcome.requestedEntry=shadow.entry;outcome.entryVwap=shadow.fillPrice;
   outcome.entryVolume=shadow.fillPrice>0.0 ? 0.01 : 0.0;
   if(shadow.fillPrice>0.0) outcome.entrySlippage=shadow.side>0 ? shadow.fillPrice-shadow.entry : shadow.entry-shadow.fillPrice;
   outcome.spreadDecision=shadow.spreadDecision;outcome.spreadFill=shadow.spreadFill;outcome.maxSpread=shadow.maxSpread;
   outcome.initialStopLoss=shadow.stopLoss;outcome.initialTakeProfit=shadow.takeProfit;
   outcome.initialRiskPrice=MathAbs(shadow.entry-shadow.stopLoss);
   if(xsLearningTickSize>0.0) outcome.initialRiskMoney=(outcome.initialRiskPrice/xsLearningTickSize)*xsLearningTickValue*0.01;
   outcome.exitReference=finalState==4 ? shadow.stopLoss : finalState==5 ? shadow.takeProfit : price;
   outcome.exitVwap=price;outcome.exitVolume=outcome.entryVolume;
   if(shadow.fillPrice>0.0 && price>0.0)
   {
      double movement=shadow.side>0 ? price-shadow.fillPrice : shadow.fillPrice-price;
      if(xsLearningTickSize>0.0) outcome.grossProfit=(movement/xsLearningTickSize)*xsLearningTickValue*0.01;
      outcome.netPnl=outcome.grossProfit;
      if(outcome.initialRiskMoney>0.0) outcome.resultR=outcome.grossProfit/outcome.initialRiskMoney;
      if(outcome.exitReference>0.0) outcome.exitSlippage=shadow.side>0 ? outcome.exitReference-price : price-outcome.exitReference;
   }
   outcome.mfePrice=shadow.mfe;outcome.maePrice=shadow.mae;
   outcome.primaryMargin=shadow.primaryMargin;outcome.consensusMargin=shadow.consensusMargin;
   QueueXSLearningOutcome(outcome);
   QueueXSLearningStateEvent(32,shadow.candidateHigh,shadow.candidateLow,timeMilliseconds,shadow.module,shadow.side,finalState);
   for(int i=0;i<xsActiveShadowCount;i++)
      if(xsActiveShadows[i]==index)
      {
         xsActiveShadows[i]=xsActiveShadows[--xsActiveShadowCount];
         break;
      }
   xsRejectedShadows[index].active=false;
}

void UpdateXSLearningQuote(const double bid,const double ask,const long timeMilliseconds)
{
   if(!xsCandidateLog.active || bid<=0.0 || ask<=0.0) return;
   UpdateXSLearningPositionsQuote(bid,ask);
   double spread=ask-bid;
   for(int active=0;active<xsActiveShadowCount;)
   {
      int index=xsActiveShadows[active];
      XSRejectedShadow shadow=xsRejectedShadows[index];
      if(shadow.state==1)
      {
         shadow.maxSpread=MathMax(shadow.maxSpread,spread);
         xsRejectedShadows[index]=shadow;
         if(shadow.expirationMilliseconds>0 && timeMilliseconds>=shadow.expirationMilliseconds)
         {
            FinishXSRejectedShadow(index,3,timeMilliseconds,0.0);
            continue;
         }
         if(shadow.side>0 ? ask>=shadow.entry : bid<=shadow.entry)
         {
            shadow.state=2;shadow.openMilliseconds=timeMilliseconds;
            shadow.fillPrice=shadow.side>0 ? ask : bid;shadow.spreadFill=spread;
            QueueXSLearningStateEvent(31,shadow.candidateHigh,shadow.candidateLow,timeMilliseconds,shadow.module,shadow.side);
         }
      }
      if(shadow.state==2)
      {
         double movement=shadow.side>0 ? bid-shadow.fillPrice : shadow.fillPrice-ask;
         shadow.mfe=MathMax(shadow.mfe,movement);shadow.mae=MathMin(shadow.mae,movement);
         shadow.maxSpread=MathMax(shadow.maxSpread,spread);
         xsRejectedShadows[index]=shadow;
         double exitPrice=shadow.side>0 ? bid : ask;
         int state=0;
         if(shadow.side>0 ? bid<=shadow.stopLoss : ask>=shadow.stopLoss) state=4;
         else if(shadow.side>0 ? bid>=shadow.takeProfit : ask<=shadow.takeProfit) state=5;
         else if(timeMilliseconds-shadow.openMilliseconds>=259200000) state=6;
         if(state!=0) { FinishXSRejectedShadow(index,state,timeMilliseconds,exitPrice);continue; }
      }
      xsRejectedShadows[index]=shadow;
      active++;
   }
}

bool InitializeXSLearningLog(const bool requested,const string symbol,const ulong magic,
                                  const double point,const double tickSize,const double tickValue,
                                  const string buildId,const bool researcherInstrumentation=false)
{
   if(xsLearningRequested) SuspendXSLearningLog();
   xsLearningRequested=requested && (researcherInstrumentation ||
                            (!MQLInfoInteger(MQL_TESTER) && !MQLInfoInteger(MQL_OPTIMIZATION)));
   xsLearningTransactionHead=0;xsLearningTransactionCount=0;
   for(int i=0;i<256;i++) ZeroMemory(xsLearningPending[i]);
   for(int i=0;i<64;i++) ZeroMemory(xsLearningPositions[i]);
   xsLearningRecordId=0;xsLearningEventCount=0;xsLearningOutcomeCount=0;xsActiveShadowCount=0;
   for(int i=0;i<128;i++) ZeroMemory(xsRejectedShadows[i]);
   xsLearningPoint=point;xsLearningTickSize=tickSize;xsLearningTickValue=tickValue;
   ZeroMemory(xsEventFile);ZeroMemory(xsOutcomeFile);
   xsEventFile.handle=INVALID_HANDLE;xsOutcomeFile.handle=INVALID_HANDLE;
   xsEventFile.kind="event";xsEventFile.capacity=2097152;xsEventFile.header="schema,record_id,session_id,time_msc,candidate_hi,candidate_lo,event,transaction_type,order_type,order_state,deal_type,order_ref,deal_ref,position_ref,retcode,terminal_error,requested_price,reference_price,fill_price,volume,bid,ask,spread,sl,tp,latency_us,module,side,reason,crc32";
   xsOutcomeFile.kind="outcome";xsOutcomeFile.capacity=2097152;xsOutcomeFile.header="schema,record_id,session_id,time_msc,candidate_hi,candidate_lo,kind,module,side,final_state,close_reason,quality_flags,open_msc,close_msc,order_ref,position_ref,requested_entry,entry_vwap,entry_volume,entry_slippage,spread_decision,spread_fill,max_spread,initial_sl,initial_tp,initial_risk_price,initial_risk_money,exit_reference,exit_vwap,exit_volume,exit_slippage,gross_profit,swap,commission,fee,net_pnl,result_r,mfe_price,mae_price,primary_margin,consensus_margin,crc32";
   ulong scope=XSLearningHashText((ulong)0x14650fb0739d0383,AccountInfoString(ACCOUNT_COMPANY));
   scope=XSLearningHashText(scope,AccountInfoString(ACCOUNT_SERVER));
   scope=XSLearningHashText(scope,symbol);
   scope=XSLearningHashStep(scope,(ulong)AccountInfoInteger(ACCOUNT_LOGIN));
   scope=XSLearningHashStep(scope,magic);
   ulong session=XSLearningHashStep(scope,(ulong)TimeLocal());
   session=XSLearningHashStep(session,GetMicrosecondCount());
   if(!InitializeXSCandidateLog(xsLearningRequested,session,scope,buildId,researcherInstrumentation))
   { xsLearningRetryAfter=TimeLocal()+300;return false; }
   if(!xsLearningRequested) return true;
   if(!OpenXSLearningFile(xsEventFile,true) || !OpenXSLearningFile(xsOutcomeFile,true))
   { SuspendXSLearningLog();return false; }
   RestoreXSLearningDedup();
   QueueXSLearningStateEvent(1,0,0,XSLearningTimestamp(),-1,0,0);
   return true;
}

void ServiceXSLearningLog()
{
   if(!xsLearningRequested) return;
   if(!xsCandidateLog.active)
   {
      if(TimeLocal()<xsLearningRetryAfter) return;
      if(!OpenXSCandidateLogFile(true) || !OpenXSLearningFile(xsEventFile,true) ||
         !OpenXSLearningFile(xsOutcomeFile,true)) { SuspendXSLearningLog();return; }
      RestoreXSLearningDedup();
      xsCandidateLog.active=true;
      QueueXSLearningStateEvent(1,0,0,XSLearningTimestamp(),-1,0,1);
   }
   if(!xsCandidateLog.fault) DrainXSLearningTransactions();
   if(xsCandidateLog.fault || !FlushXSLearningLog()) SuspendXSLearningLog();
}

void CloseXSLearningLog(const int reason)
{
   if(xsCandidateLog.active)
   {
      QueueXSLearningStateEvent(2,0,0,XSLearningTimestamp(),-1,0,reason);
      DrainXSLearningTransactions();
      FlushXSLearningLog();
   }
   SuspendXSLearningLog();
   xsLearningRequested=false;
}
int FindXSLearningPending(const ulong order)
{
   if(order==0) return -1;
   for(int i=0;i<256;i++) if(xsLearningPending[i].active && xsLearningPending[i].orderRef==order) return i;
   return -1;
}

int FindXSLearningPosition(const ulong position)
{
   if(position==0) return -1;
   for(int i=0;i<64;i++) if(xsLearningPositions[i].active && xsLearningPositions[i].positionRef==position) return i;
   return -1;
}

void UpdateXSLearningCandidateLot(XSCandidateContext &context,const double lot,const datetime expiration)
{
   if(!xsCandidateLog.active || context.candidateHigh==0 || context.candidateLow==0) return;
   if(expiration>0) context.expiration=expiration;
   for(int i=xsCandidateLog.count-1;i>=0;i--)
   {
      if(xsCandidateQueue[i].context.candidateHigh!=context.candidateHigh ||
         xsCandidateQueue[i].context.candidateLow!=context.candidateLow) continue;
      xsCandidateQueue[i].lot=lot;
      if(expiration>0) xsCandidateQueue[i].context.expiration=expiration;
      return;
   }
}

void RecordXSLearningOrderResult(const XSCandidateContext &context,const XSModelRequest &modelRequest,
                                     const XSModelResult &modelResult,const MqlTradeRequest &tradeRequest,
                                     const bool checkedRejected,const bool placed,const ulong order,const ulong deal,
                                     const uint retcode,const int terminalError,const ulong latencyMicroseconds)
{
   if(!xsCandidateLog.active) return;
   XSLearningEvent event;
   ZeroMemory(event);
   event.candidateHigh=context.candidateHigh;event.candidateLow=context.candidateLow;
   event.timeMilliseconds=XSLearningTimestamp();
   event.eventType=placed ? 12 : checkedRejected ? 10 : 11;
   event.orderType=(int)tradeRequest.type;event.orderRef=order;event.dealRef=deal;
   event.retcode=(int)retcode;event.terminalError=terminalError;
   event.requestedPrice=tradeRequest.price;event.volume=tradeRequest.volume;
   event.bid=context.bid;event.ask=context.ask;event.stopLoss=tradeRequest.sl;event.takeProfit=tradeRequest.tp;
   event.latencyMicroseconds=latencyMicroseconds;event.module=modelRequest.module;event.side=modelRequest.buy ? 1 : -1;
   QueueXSLearningEvent(event);
   if(!placed || order==0 || !context.valid) return;
   int index=FindXSLearningPending(order);
   if(index<0) for(int i=0;i<256;i++) if(!xsLearningPending[i].active) { index=i;break; }
   if(index<0) return;
   XSLearningPending pending;
   ZeroMemory(pending);
   pending.active=true;pending.candidateHigh=context.candidateHigh;pending.candidateLow=context.candidateLow;
   pending.orderRef=order;pending.module=modelRequest.module;pending.side=modelRequest.buy ? 1 : -1;
   pending.decisionMilliseconds=context.timeMilliseconds;pending.entry=modelRequest.entryPrice;
   pending.stopLoss=context.stopLoss;pending.takeProfit=context.takeProfit;pending.lot=tradeRequest.volume;
   pending.spreadDecision=MathMax(0.0,context.ask-context.bid);
   pending.primaryMargin=modelResult.primaryScore-modelRequest.primaryThreshold;
   pending.consensusMargin=modelResult.consensusScore-modelRequest.consensusThreshold;
   xsLearningPending[index]=pending;
}

void QueueXSLearningTransaction(const MqlTradeTransaction &transaction,const MqlTradeResult &result,
                                     const double bid,const double ask,const long timeMilliseconds)
{
   if(!xsCandidateLog.active || (transaction.symbol!="" && transaction.symbol!=_Symbol)) return;
   if(xsLearningTransactionCount>=256)
   {
      xsCandidateLog.dropped++;xsCandidateLog.fault=true;return;
   }
   int index=(xsLearningTransactionHead+xsLearningTransactionCount)%256;
   XSLearningTransaction item;
   ZeroMemory(item);
   item.timeMilliseconds=timeMilliseconds;item.transactionType=(int)transaction.type;
   item.orderType=(int)transaction.order_type;item.orderState=(int)transaction.order_state;item.dealType=(int)transaction.deal_type;
   item.orderRef=transaction.order;item.dealRef=transaction.deal;item.positionRef=transaction.position;item.retcode=(int)result.retcode;
   item.price=transaction.price;item.stopLoss=transaction.price_sl;item.takeProfit=transaction.price_tp;item.volume=transaction.volume;
   item.bid=bid;item.ask=ask;
   xsLearningTransactions[index]=item;
   xsLearningTransactionCount++;
}

void UpdateXSLearningPositionsQuote(const double bid,const double ask)
{
   if(!xsCandidateLog.active || bid<=0.0 || ask<=0.0) return;
   for(int i=0;i<64;i++)
   {
      if(!xsLearningPositions[i].active || xsLearningPositions[i].entryVolume<=0.0) continue;
      double entry=xsLearningPositions[i].entryPriceVolume/xsLearningPositions[i].entryVolume;
      double movement=xsLearningPositions[i].side>0 ? bid-entry : entry-ask;
      xsLearningPositions[i].mfe=MathMax(xsLearningPositions[i].mfe,movement);
      xsLearningPositions[i].mae=MathMin(xsLearningPositions[i].mae,movement);
      xsLearningPositions[i].maxSpread=MathMax(xsLearningPositions[i].maxSpread,ask-bid);
   }
}

bool XSLearningPositionExists(const ulong identifier)
{
   for(int i=0;i<PositionsTotal();i++)
      if(PositionGetTicket(i)!=0 && (ulong)PositionGetInteger(POSITION_IDENTIFIER)==identifier) return true;
   return false;
}

void FinalizeXSLearningPositions()
{
   long timestamp=XSLearningTimestamp();
   for(int i=0;i<64;i++)
   {
      XSLearningPosition position=xsLearningPositions[i];
      if(!position.active || position.entryVolume<=0.0 || position.exitVolume<=0.0 ||
         XSLearningPositionExists(position.positionRef)) continue;
      XSLearningOutcome outcome;
      ZeroMemory(outcome);
      outcome.candidateHigh=position.candidateHigh;outcome.candidateLow=position.candidateLow;
      outcome.timeMilliseconds=timestamp;outcome.kind=1;outcome.module=position.module;outcome.side=position.side;
      outcome.finalState=1;outcome.closeReason=position.closeReason;outcome.qualityFlags=position.qualityFlags;
      outcome.openMilliseconds=position.openMilliseconds;outcome.closeMilliseconds=position.closeMilliseconds;
      outcome.orderRef=position.orderRef;outcome.positionRef=position.positionRef;
      outcome.requestedEntry=position.requestedEntry;outcome.entryVwap=position.entryPriceVolume/position.entryVolume;
      outcome.entryVolume=position.entryVolume;
      outcome.entrySlippage=position.side>0 ? outcome.entryVwap-position.requestedEntry : position.requestedEntry-outcome.entryVwap;
      outcome.spreadDecision=position.spreadDecision;outcome.spreadFill=position.spreadFill;outcome.maxSpread=position.maxSpread;
      outcome.initialStopLoss=position.stopLoss;outcome.initialTakeProfit=position.takeProfit;outcome.initialRiskPrice=position.riskPrice;
      if(xsLearningTickSize>0.0) outcome.initialRiskMoney=(position.riskPrice/xsLearningTickSize)*xsLearningTickValue*position.entryVolume;
      outcome.exitReference=position.exitReferenceVolume/position.exitVolume;outcome.exitVwap=position.exitPriceVolume/position.exitVolume;
      outcome.exitVolume=position.exitVolume;
      if(outcome.exitReference>0.0) outcome.exitSlippage=position.side>0 ? outcome.exitReference-outcome.exitVwap : outcome.exitVwap-outcome.exitReference;
      outcome.grossProfit=position.grossProfit;outcome.swap=position.swap;outcome.commission=position.commission;outcome.fee=position.fee;
      outcome.netPnl=position.grossProfit+position.swap+position.commission+position.fee;
      if(outcome.initialRiskMoney>0.0) outcome.resultR=outcome.netPnl/outcome.initialRiskMoney;
      outcome.mfePrice=position.mfe;outcome.maePrice=position.mae;outcome.primaryMargin=position.primaryMargin;outcome.consensusMargin=position.consensusMargin;
      if(MathAbs(position.entryVolume-position.exitVolume)>0.00000001) outcome.qualityFlags|=8;
      QueueXSLearningOutcome(outcome);
      QueueXSLearningStateEvent(22,position.candidateHigh,position.candidateLow,timestamp,position.module,position.side,position.closeReason);
      for(int n=0;n<256;n++) if(xsLearningPending[n].active && xsLearningPending[n].orderRef==position.orderRef) xsLearningPending[n].active=false;
      xsLearningPositions[i].active=false;
   }
}

void ProcessXSLearningDeal(const XSLearningTransaction &item)
{
   ulong order=(ulong)HistoryDealGetInteger(item.dealRef,DEAL_ORDER);
   ulong identifier=(ulong)HistoryDealGetInteger(item.dealRef,DEAL_POSITION_ID);
   int entry=(int)HistoryDealGetInteger(item.dealRef,DEAL_ENTRY);
   int dealType=(int)HistoryDealGetInteger(item.dealRef,DEAL_TYPE);
   int pendingIndex=FindXSLearningPending(order),index=FindXSLearningPosition(identifier);
   if((entry==DEAL_ENTRY_IN || entry==DEAL_ENTRY_INOUT) && index<0 && pendingIndex>=0)
   {
      for(int i=0;i<64;i++) if(!xsLearningPositions[i].active) { index=i;break; }
      if(index<0) return;
      XSLearningPending pending=xsLearningPending[pendingIndex];
      XSLearningPosition position;
      ZeroMemory(position);
      position.active=true;position.candidateHigh=pending.candidateHigh;position.candidateLow=pending.candidateLow;
      position.orderRef=pending.orderRef;position.positionRef=identifier;position.module=pending.module;position.side=pending.side;
      position.qualityFlags=entry==DEAL_ENTRY_INOUT ? 3 : 1;
      position.openMilliseconds=HistoryDealGetInteger(item.dealRef,DEAL_TIME_MSC);
      position.requestedEntry=pending.entry;position.stopLoss=pending.stopLoss;position.takeProfit=pending.takeProfit;
      position.riskPrice=MathAbs(pending.entry-pending.stopLoss);position.spreadDecision=pending.spreadDecision;
      position.primaryMargin=pending.primaryMargin;position.consensusMargin=pending.consensusMargin;
      xsLearningPositions[index]=position;
   }
   if(index<0) return;
   XSLearningPosition position=xsLearningPositions[index];
   double volume=HistoryDealGetDouble(item.dealRef,DEAL_VOLUME),price=HistoryDealGetDouble(item.dealRef,DEAL_PRICE);
   long timestamp=HistoryDealGetInteger(item.dealRef,DEAL_TIME_MSC);
   position.closeMilliseconds=MathMax(position.closeMilliseconds,timestamp);
   position.grossProfit+=HistoryDealGetDouble(item.dealRef,DEAL_PROFIT);
   position.swap+=HistoryDealGetDouble(item.dealRef,DEAL_SWAP);
   position.commission+=HistoryDealGetDouble(item.dealRef,DEAL_COMMISSION);
   position.fee+=HistoryDealGetDouble(item.dealRef,DEAL_FEE);
   double spread=MathMax(0.0,item.ask-item.bid);
   position.maxSpread=MathMax(position.maxSpread,spread);
   XSLearningEvent event;
   ZeroMemory(event);
   event.candidateHigh=position.candidateHigh;event.candidateLow=position.candidateLow;event.timeMilliseconds=timestamp;
   event.transactionType=TRADE_TRANSACTION_DEAL_ADD;event.orderType=item.orderType;event.dealType=dealType;
   event.orderRef=order;event.dealRef=item.dealRef;event.positionRef=identifier;event.fillPrice=price;event.volume=volume;
   event.bid=item.bid;event.ask=item.ask;event.stopLoss=item.stopLoss;event.takeProfit=item.takeProfit;
   event.module=position.module;event.side=position.side;
   if(entry==DEAL_ENTRY_IN || entry==DEAL_ENTRY_INOUT)
   {
      position.entryPriceVolume+=volume*price;position.entryVolume+=volume;
      if(position.spreadFill<=0.0) position.spreadFill=spread;
      event.eventType=20;
      QueueXSLearningEvent(event);
   }
   if(entry==DEAL_ENTRY_OUT || entry==DEAL_ENTRY_INOUT || entry==DEAL_ENTRY_OUT_BY)
   {
      if(entry==DEAL_ENTRY_INOUT) position.qualityFlags|=2;
      double reference=order==0 ? 0.0 : HistoryOrderGetDouble(order,ORDER_PRICE_OPEN);
      if(order==0 || reference<=0.0) position.qualityFlags|=4;
      position.exitPriceVolume+=volume*price;position.exitVolume+=volume;position.exitReferenceVolume+=volume*reference;
      position.closeReason=(int)HistoryDealGetInteger(item.dealRef,DEAL_REASON);
      event.eventType=21;event.referencePrice=reference;event.reason=position.closeReason;
      QueueXSLearningEvent(event);
   }
   xsLearningPositions[index]=position;
}

void DrainXSLearningTransactions()
{
   for(int processed=0;processed<128 && xsLearningTransactionCount>0;processed++)
   {
      int head=xsLearningTransactionHead;
      XSLearningTransaction item=xsLearningTransactions[head];
      if(item.transactionType==TRADE_TRANSACTION_DEAL_ADD && item.dealRef!=0)
      {
         if(!HistoryDealSelect(item.dealRef))
         {
            xsLearningTransactions[head].retries++;
            if(xsLearningTransactions[head].retries<10) break;
         }
         else ProcessXSLearningDeal(item);
      }
      else if(item.transactionType!=TRADE_TRANSACTION_DEAL_ADD && item.orderRef!=0)
      {
         int index=FindXSLearningPending(item.orderRef);
         if(index>=0 && item.transactionType>=TRADE_TRANSACTION_ORDER_ADD && item.transactionType<=TRADE_TRANSACTION_ORDER_DELETE)
         {
            XSLearningPending pending=xsLearningPending[index];
            XSLearningEvent event;
            ZeroMemory(event);
            event.candidateHigh=pending.candidateHigh;event.candidateLow=pending.candidateLow;event.timeMilliseconds=item.timeMilliseconds;
            event.eventType=13+item.transactionType;event.transactionType=item.transactionType;event.orderType=item.orderType;
            event.orderState=item.orderState;event.dealType=item.dealType;event.orderRef=item.orderRef;event.dealRef=item.dealRef;
            event.positionRef=item.positionRef;event.retcode=item.retcode;event.fillPrice=item.price;event.volume=item.volume;
            event.bid=item.bid;event.ask=item.ask;event.stopLoss=item.stopLoss;event.takeProfit=item.takeProfit;
            event.module=pending.module;event.side=pending.side;
            QueueXSLearningEvent(event);
            if(item.transactionType==TRADE_TRANSACTION_ORDER_DELETE &&
               (item.orderState==ORDER_STATE_CANCELED || item.orderState==ORDER_STATE_REJECTED || item.orderState==ORDER_STATE_EXPIRED))
               xsLearningPending[index].active=false;
         }
      }
      xsLearningTransactionHead=(head+1)%256;xsLearningTransactionCount--;
   }
   FinalizeXSLearningPositions();
}

void RestoreXSLearningDedup()
{
   string path=XSCandidateLogPath(xsCandidateLog.fileSlot);
   int reader=FileOpen(path,FILE_READ|FILE_TXT|FILE_ANSI|FILE_SHARE_READ|FILE_SHARE_WRITE,0,CP_UTF8);
   if(reader==INVALID_HANDLE) return;
   while(!FileIsEnding(reader))
   {
      string line=FileReadString(reader);
      if(StringFind(line,"MDT2_CANDIDATE_V1,")!=0) continue;
      string columns[];
      if(StringSplit(line,',',columns)<7) continue;
      ulong high=(ulong)StringToInteger(columns[4]),low=(ulong)StringToInteger(columns[5]);
      if((high==0 && low==0) || XSCandidateWasLogged(high,low)) continue;
      int seen=xsCandidateLog.seenCount<512 ? xsCandidateLog.seenCount++ : xsCandidateLog.nextSeen;
      xsSeenCandidateHigh[seen]=high;xsSeenCandidateLow[seen]=low;
      if(xsCandidateLog.seenCount>=512) xsCandidateLog.nextSeen=(seen+1)%512;
   }
   FileClose(reader);
}









struct XSPositionSnapshot
{
   ulong ticket;
   ulong identifier;
   long magic;
   ENUM_POSITION_TYPE type;
   double volume;
   double openPrice;
   double profit;
   double swap;
   double stopLoss;
   double takeProfit;
};

struct XSProtectionState
{
   ulong identifier;
   double peakMoney;
   double peakPer001;
   double trackedVolume;
   double virtualStop;
   double lockedMoney;
   int confirmQuotes;
   long lastConfirmMsc;
};

struct XSProtectionConfig
{
   bool lockEnabled;
   bool adaptiveLock;
   bool spikeShield;
   int protectionMode;
   double lockStartPer001;
   double lockPercent;
   double adaptiveThreshold;
   double adaptiveLowPercent;
   double adaptiveHighPercent;
   int requiredConfirmQuotes;
   double spreadTrigger;
   double immediatePenetration;
   double pipSize;
   double point;
   int digits;
   double tickValue;
   double tickValueProfit;
   double tickValueLoss;
   double tickSize;
};

enum XSLockDecision
{
   MD_LOCK_NOT_TRIGGERED,
   MD_LOCK_WAIT_FOR_QUOTE,
   MD_LOCK_REQUEST_CLOSE
};

struct XSProtectionUpdate
{
   bool peakChanged;
   bool stopChanged;
   bool lockActive;
   XSLockDecision decision;
};

// Pure state functions. The event owner supplies one coherent position snapshot
// and owns persistence, close intents, permission checks and broker requests.
double MDNormalizeDecimal(const double value,const int digits)
{
   if(!MathIsValidNumber(value) || value<=-9223372036854775808.0 || value>=9223372036854775808.0)
      return value;
   const double integral=(double)(long)value;
   const double scale=MathPow(10.0,MathMin(11,MathMax(0,digits)));
   const double rounding=value>0.0 ? 0.5000001 : -0.5000001;
   return (double)(long)((value-integral)*scale+rounding)/scale+integral;
}

// Return the price whose profit plus swap is lockedMoney.
double MDLockPrice(const bool buy,const double openPrice,const double lockedMoney,
                   const double swap,const double volume,const double tickValue,
                   const double tickSize)
{
   if(!MathIsValidNumber(openPrice) || !MathIsValidNumber(lockedMoney) ||
      !MathIsValidNumber(swap) || !MathIsValidNumber(volume) ||
      !MathIsValidNumber(tickValue) || !MathIsValidNumber(tickSize) ||
      openPrice<=0.0 || lockedMoney<=0.0 || volume<=0.0 || tickValue<=0.0 || tickSize<=0.0)
      return 0.0;
   const double moneyPerPrice=(volume*tickValue)/tickSize;
   if(!MathIsValidNumber(moneyPerPrice) || moneyPerPrice<=0.0)
      return 0.0;
   const double delta=(lockedMoney-swap)/moneyPerPrice;
   const double price=openPrice+(buy ? delta : -delta);
   return MathIsValidNumber(price) && price>0.0 ? price : 0.0;
}

// Preserve the per-volume peak on partial closes.
bool MDUpdateProfitPeak(const double netProfit,const double volume,
                        XSProtectionState &state)
{
   if(volume<=0.0 || !MathIsValidNumber(volume))
      return false;
   const double difference=MathAbs(volume-state.trackedVolume);
   bool changed=difference>1e-9;
   if(changed)
   {
      if(state.trackedVolume>0.0 && volume<state.trackedVolume-1e-9)
         state.peakMoney=MathIsValidNumber(state.peakPer001) && state.peakPer001>0.0
                         ? (volume/0.01)*state.peakPer001 : 0.0;
      else if(state.trackedVolume<=0.0 || volume>state.trackedVolume+1e-9)
         state.peakPer001=MathIsValidNumber(state.peakMoney)
                          ? MathMax(0.0,state.peakMoney)/(volume/0.01) : 0.0;
   }
   if(netProfit>state.peakMoney)
   {
      state.peakMoney=netProfit;
      state.peakPer001=MathIsValidNumber(netProfit)
                       ? MathMax(0.0,netProfit)/(volume/0.01) : 0.0;
      changed=true;
   }
   state.trackedVolume=volume;
   return changed;
}

// Never loosen the existing virtual price.
bool MDTightenVirtualStop(const bool buy,const double requestedPrice,
                          const double point,const int digits,
                          XSProtectionState &state)
{
   if(requestedPrice<=0.0)
      return false;
   const double price=MDNormalizeDecimal(requestedPrice,digits);
   if(state.virtualStop>0.0)
   {
      if(buy && price<=state.virtualStop+point*0.5)
         return false;
      if(!buy && price>=state.virtualStop-point*0.5)
         return false;
   }
   state.virtualStop=price;
   return true;
}

// Quote identity is time_msc, not tick count.
XSLockDecision MDEvaluateLockCross(const XSPositionSnapshot &position,
                                       const MqlTick &tick,
                                       const XSProtectionConfig &config,
                                       XSProtectionState &state)
{
   if(!config.lockEnabled)
      return MD_LOCK_NOT_TRIGGERED;
   const bool buy=position.type==POSITION_TYPE_BUY;
   const double currentNet=position.profit+position.swap;
   const bool moneyCross=state.lockedMoney>0.0 && currentNet<=state.lockedMoney;
   const bool priceCross=state.virtualStop>0.0 &&
                         (buy ? tick.bid<=state.virtualStop : tick.ask>=state.virtualStop);
   if(!moneyCross && !priceCross)
   {
      state.confirmQuotes=0;
      state.lastConfirmMsc=0;
      return MD_LOCK_NOT_TRIGGERED;
   }
   if(config.spikeShield && config.protectionMode==2)
   {
      const double unit=config.pipSize>0.0 ? config.pipSize : config.point;
      double spread=0.0,penetration=0.0;
      if(unit>0.0)
      {
         spread=MathMax(0.0,(tick.ask-tick.bid)/unit);
         if(state.virtualStop>0.0)
            penetration=MathMax(0.0,(buy ? state.virtualStop-tick.bid
                                         : tick.ask-state.virtualStop)/unit);
      }
      if(spread>config.spreadTrigger && penetration<config.immediatePenetration)
      {
         const long quoteMsc=tick.time_msc>0 ? tick.time_msc : (long)tick.time*1000;
         if(state.lastConfirmMsc!=quoteMsc)
         {
            state.lastConfirmMsc=quoteMsc;
            ++state.confirmQuotes;
         }
         if(state.confirmQuotes<config.requiredConfirmQuotes)
            return MD_LOCK_WAIT_FOR_QUOTE;
      }
      state.confirmQuotes=0;
      state.lastConfirmMsc=0;
   }
   return MD_LOCK_REQUEST_CLOSE;
}

XSProtectionUpdate MDUpdateXSLock(const XSPositionSnapshot &position,
                                        const MqlTick &tick,
                                        const XSProtectionConfig &config,
                                        XSProtectionState &state)
{
   XSProtectionUpdate result;
   result.peakChanged=false;
   result.stopChanged=false;
   result.lockActive=false;
   result.decision=MD_LOCK_NOT_TRIGGERED;
   if(!config.lockEnabled || position.volume<=0.0)
      return result;
   result.peakChanged=MDUpdateProfitPeak(position.profit+position.swap,position.volume,state);
   if(state.peakMoney>0.0 && state.peakMoney>=(position.volume/0.01)*config.lockStartPer001)
   {
      const double percent=config.adaptiveLock
                           ? (state.peakPer001>=config.adaptiveThreshold
                              ? config.adaptiveHighPercent : config.adaptiveLowPercent)
                           : config.lockPercent;
      const double locked=state.peakMoney*(percent/100.0);
      if(locked>0.0)
      {
         state.lockedMoney=locked;
         result.lockActive=true;
         double value=locked-position.swap<0.0 ? config.tickValueLoss : config.tickValueProfit;
         if(!MathIsValidNumber(value) || value<=0.0)
            value=MathIsValidNumber(config.tickValue) ? MathMax(0.0,config.tickValue) : 0.0;
         const double price=MDLockPrice(position.type==POSITION_TYPE_BUY,position.openPrice,
                                        locked,position.swap,position.volume,value,config.tickSize);
         if(price>0.0)
            result.stopChanged=MDTightenVirtualStop(position.type==POSITION_TYPE_BUY,
                                                   MDNormalizeDecimal(price,config.digits),
                                                   config.point,config.digits,state);
         result.decision=MDEvaluateLockCross(position,tick,config,state);
      }
   }
   else if(state.virtualStop>0.0)
      result.decision=MDEvaluateLockCross(position,tick,config,state);
   return result;
}







struct XSVolumeRules
{
   double minimum;
   double maximum;
   double step;
   int digits;
};

// Risk lots use a grid anchored at the minimum.
double MDNormalizeRiskLots(const double requested,const XSVolumeRules &rules)
{
   const double step=rules.step>0.0 ? rules.step : 0.01;
   const double minimum=rules.minimum>0.0 ? rules.minimum : step;
   if(requested+1e-10<minimum)
      return 0.0;
   const double capped=rules.maximum>0.0 ? MathMin(requested,rules.maximum) : requested;
   const double lots=step*MathFloor((capped-minimum)/step+1e-7)+minimum;
   return lots>=minimum ? MDNormalizeDecimal(lots,rules.digits) : 0.0;
}

// Its step grid starts at zero.
double MDFixedLots(const double requested,const XSVolumeRules &rules)
{
   const double step=rules.step>0.0 ? rules.step : 0.01;
   const double lots=MathMax(rules.minimum,requested);
   const double capped=rules.maximum>0.0 ? MathMin(lots,rules.maximum) : lots;
   return MDNormalizeDecimal(MathFloor(capped/step+1e-7)*step,rules.digits);
}

int MDEffectiveSizingMode(const int configuredMode,const bool tester)
{
   return configuredMode==5 ? (tester ? 2 : 0) : configuredMode;
}

double MDRiskPercent(const int effectiveMode,const double customPercent)
{
   switch(effectiveMode)
   {
      case 1: return 1.0;
      case 2: return 2.0;
      case 3: return MathMax(0.0,customPercent);
      case 4: return 1.0;
   }
   return 0.0;
}

// Supply this normalized volume to OrderCalcProfit; use loss/probeVolume below.
double MDRiskProbeVolume(const XSVolumeRules &rules)
{
   if(rules.step<=0.0)
      return 0.0;
   const double minimum=rules.minimum>0.0 ? rules.minimum : rules.step;
   const double ceiling=rules.maximum>0.0 ? MathMin(1.0,rules.maximum) : 1.0;
   const double requested=MathMax(minimum,ceiling);
   const double volume=MDNormalizeDecimal(rules.step*MathFloor((requested-minimum)/rules.step+1e-7)
                                          +minimum,rules.digits);
   if(!MathIsValidNumber(volume) || volume<minimum ||
      (rules.maximum>0.0 && volume>rules.maximum))
      return 0.0;
   return volume;
}

// Caller supplies verified OrderCalcProfit.
double MDRiskLots(const int configuredMode,const bool tester,const double customPercent,
                  const double balance,const double probeVolume,const double probeProfit,
                  const double adaptiveMultiplier,const bool adaptiveEnabled,
                  const int aiMode,const double maximumRiskLot,const XSVolumeRules &rules)
{
   const int mode=MDEffectiveSizingMode(configuredMode,tester);
   const double percent=MDRiskPercent(mode,customPercent);
   if(percent<=0.0 || balance<=0.0 || probeVolume<=0.0 || probeProfit>=0.0)
      return 0.0;
   const double lossPerLot=-probeProfit/probeVolume;
   if(lossPerLot<=0.0)
      return 0.0;
   double multiplier=1.0;
   if(adaptiveEnabled && (aiMode==1 || aiMode==2) && mode!=0 && mode!=4 && configuredMode!=5)
      multiplier=adaptiveMultiplier;
   if(!MathIsValidNumber(multiplier) || multiplier<=0.0)
      return 0.0;
   double lots=((percent/100.0)*balance)/lossPerLot;
   if(configuredMode==4 && lots+1e-10<0.01)
   {
      if(maximumRiskLot>0.0 && maximumRiskLot+1e-10<0.01)
         return 0.0;
      return MDNormalizeRiskLots(0.01,rules);
   }
   if(lots+1e-10<rules.minimum)
      return 0.0;
   lots=MathMax(rules.minimum,lots*multiplier);
   if(maximumRiskLot>0.0)
      lots=MathMin(lots,maximumRiskLot);
   return MDNormalizeRiskLots(lots,rules);
}

// Retry scheduling is a deferred retry, never Sleep().
int MDCloseRetrySeconds(const uint retcode,const int lastError,const bool sent)
{
   if(retcode==10026)
      return 60;
   if(retcode==10027 || lastError==4752)
      return 1;
   if(retcode==10018)
      return 60;
   return retcode==10024 ? 2 : 1;
}

// Broker filling flags: prefer FOK, then IOC, otherwise RETURN (88e6c0).
ENUM_ORDER_TYPE_FILLING MDCloseFilling(const long fillingFlags)
{
   if((fillingFlags&SYMBOL_FILLING_FOK)!=0)
      return ORDER_FILLING_FOK;
   if((fillingFlags&SYMBOL_FILLING_IOC)!=0)
      return ORDER_FILLING_IOC;
   return ORDER_FILLING_RETURN;
}

enum MDExecutionLane
{
   MD_ENTRY_LANE=0,
   MD_MODIFY_LANE=1,
   MD_CLOSE_LANE=2,
   MD_DELETE_LANE=3
};

struct MDTradeContext
{
   string symbol;
   string server;
   long login;
   long currentBase;
   int previousBase;
   int legacyBase;
   int quickSetup;
   bool enabled[9];
   ENUM_TIMEFRAMES triggerTimeframes[9];
   bool tester;
   bool persistVirtual;
   bool tradeAllowed;
   bool entryAllowed;
   bool entryRetryAllowed;
   bool deleteAllowed;
   bool fastMode;
   bool measureTradeLatency;
   bool hasCachedTick;
   MqlTick cachedTick;
   datetime now;
   long tickSequence;
   double point;
   int digits;
   int protectionMode;
};

struct MDCloseIntent
{
   ulong identifier;
   int reason;
   datetime nextAttempt;
   int attempts;
   bool hadRetry;
   bool persistDirty;
   datetime persistRetry;
   datetime firstAbsence;
   int absenceCount;
   long lastAbsenceTick;
};

struct MDTrackedPosition
{
   XSProtectionState protection;
   MDCloseIntent close;
   double generalStop;
   datetime generalRetry;
   datetime mirrorRetry;
   bool migrationPending;
   bool migrationConflict;
   double migrationPeak;
   datetime migrationRetry;
};

struct MDExecutionState
{
   MDTrackedPosition positions[512];
   int positionCount;
   MDCloseIntent emergency[32];
   int emergencyCount;
   datetime laneUntil[4];
   datetime deleteNext;
   datetime closeBudgetSecond;
   int closeBudgetUsed;
   ulong lastBudgetPosition;
   ulong lastObjectMagic;
   int entrySendCount;
   bool expiryFallback;
   ENUM_ORDER_TYPE_TIME fallbackTimeType;
   datetime fallbackEarliestExpiry;
   bool pendingDirty;
   bool positionsDirty;
   bool persistenceDirty;
   ulong persistenceLastFlushMsc;
   bool cleanupPending;
   datetime cleanupNext;
   datetime takeProfitRepairNext;
   datetime pivotLowBar[9];
   datetime pivotHighBar[9];
   datetime pivotLowNext[9];
   datetime pivotHighNext[9];
   double pivotLowValue[9];
   double pivotHighValue[9];
   datetime recoveredBuyBar[9];
   datetime recoveredSellBar[9];
};

struct MDTradeOutcome
{
   bool attempted;
   bool sent;
   bool accepted;
   bool checkRejected;
   bool partial;
   bool presentAfter;
   bool coherentAbsence;
   int lastError;
   ulong latencyMicroseconds;
   double remainingVolume;
   MqlTradeRequest request;
   MqlTradeResult result;
   MqlTradeCheckResult check;
};

// The root event owner supplies its live entry gates here. The default consumes
// the context gates; overrides may re-evaluate news/spread after OrderCheck.
class MDExecutionHooks
{
public:
   virtual bool AllowTrade(const MDTradeContext &context) { return context.tradeAllowed; }
   virtual bool ReadQuote(const MDTradeContext &context,MqlTick &tick)
   { return MDProtectionTick(context,tick); }
   virtual bool AllowEntry(const MDTradeContext &context,const long magic,const ENUM_ORDER_TYPE type)
   { return context.entryAllowed; }
   virtual bool AllowEntryRetry(const MDTradeContext &context) { return context.entryRetryAllowed; }
   virtual void PendingDeleteResult(const ulong ticket,const bool sent,const uint retcode,const int error) {}
};

bool MDTradeAccepted(const bool sent,const uint retcode)
{
   return sent && (retcode==TRADE_RETCODE_PLACED || retcode==TRADE_RETCODE_DONE ||
                   retcode==TRADE_RETCODE_NO_CHANGES);
}

datetime MDReliableServerTime()
{
   const datetime current=TimeCurrent(),server=TimeTradeServer();
   const datetime latest=current>server ? current : server;
   return latest>0 ? latest : TimeLocal();
}

int MDLaneRetrySeconds(const MDExecutionLane lane,const uint retcode,const int error)
{
   if(retcode==TRADE_RETCODE_SERVER_DISABLES_AT) return 60;
   if(retcode==TRADE_RETCODE_CLIENT_DISABLES_AT || error==4752) return 1;
   if(retcode==TRADE_RETCODE_TIMEOUT || retcode==TRADE_RETCODE_LOCKED ||
      retcode==TRADE_RETCODE_CONNECTION) return 1;
   if(retcode==TRADE_RETCODE_MARKET_CLOSED) return 60;
   if(retcode==TRADE_RETCODE_TOO_MANY_REQUESTS) return 2;
   if(lane==MD_MODIFY_LANE && retcode==TRADE_RETCODE_INVALID_STOPS) return 1;
   if((lane==MD_MODIFY_LANE || lane==MD_DELETE_LANE) && retcode==TRADE_RETCODE_FROZEN) return 1;
   return 0;
}

bool MDRecordTradeFailure(MDExecutionState &state,const MDExecutionLane lane,
                          const uint retcode,const int error,const datetime now)
{
   const int delay=MDLaneRetrySeconds(lane,retcode,error);
   if(delay>0 && state.laneUntil[lane]<now+delay) state.laneUntil[lane]=now+delay;
   return retcode==TRADE_RETCODE_SERVER_DISABLES_AT ||
          retcode==TRADE_RETCODE_CLIENT_DISABLES_AT || error==4752;
}

void MDSendRequest(MqlTradeRequest &request,MDTradeOutcome &outcome,const bool measureLatency=false)
{
   outcome.request=request;
   ZeroMemory(outcome.result);
   ResetLastError();
   outcome.attempted=true;
   const ulong started=measureLatency ? GetMicrosecondCount() : 0;
   outcome.sent=OrderSend(request,outcome.result);
   outcome.latencyMicroseconds=started>0 ? GetMicrosecondCount()-started : 0;
   outcome.lastError=GetLastError();
   outcome.accepted=MDTradeAccepted(outcome.sent,outcome.result.retcode);
   outcome.partial=outcome.result.retcode==TRADE_RETCODE_DONE_PARTIAL;
}

bool MDReadPosition(const ulong ticket,XSPositionSnapshot &position)
{
   if(ticket==0 || !PositionSelectByTicket(ticket)) return false;
   position.ticket=ticket;
   position.identifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
   position.magic=PositionGetInteger(POSITION_MAGIC);
   position.type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   position.volume=PositionGetDouble(POSITION_VOLUME);
   position.openPrice=PositionGetDouble(POSITION_PRICE_OPEN);
   position.profit=PositionGetDouble(POSITION_PROFIT);
   position.swap=PositionGetDouble(POSITION_SWAP);
   position.stopLoss=PositionGetDouble(POSITION_SL);
   position.takeProfit=PositionGetDouble(POSITION_TP);
   return true;
}

// 895c40: this scan intentionally re-reads total while trading changes the list.
bool MDFindPositionByIdentifier(const MDTradeContext &context,const ulong identifier,
                                XSPositionSnapshot &position)
{
   for(int i=0;i<PositionsTotal();i++)
   {
      const ulong ticket=PositionGetTicket(i);
      if(ticket==0 || PositionGetString(POSITION_SYMBOL)!=context.symbol ||
         (ulong)PositionGetInteger(POSITION_IDENTIFIER)!=identifier) continue;
      if(MDRecognizeMagic(PositionGetInteger(POSITION_MAGIC),context.currentBase,
                          context.previousBase,context.legacyBase,context.quickSetup,context.enabled)<0)
         continue;
      return MDReadPosition(ticket,position);
   }
   return false;
}

void MDResetAbsence(MDCloseIntent &intent)
{
   intent.firstAbsence=0;
   intent.absenceCount=0;
   intent.lastAbsenceTick=-1;
}

// 8952c0 / 895ac0: all symbols are checked, then two different ticks and elapsed
// server time are required. A successful send is not proof that a position left.
bool MDConfirmPositionAbsent(const MDTradeContext &context,MDCloseIntent &intent)
{
   if(intent.identifier==0) return false;
   for(int i=0;i<PositionsTotal();i++)
      if(PositionGetTicket(i)!=0 && (ulong)PositionGetInteger(POSITION_IDENTIFIER)==intent.identifier)
      { MDResetAbsence(intent); return false; }
   if(intent.lastAbsenceTick==context.tickSequence) return false;
   intent.lastAbsenceTick=context.tickSequence;
   if(intent.absenceCount>0 && intent.firstAbsence>0)
   {
      ++intent.absenceCount;
      return context.now>intent.firstAbsence && intent.absenceCount>1;
   }
   intent.firstAbsence=context.now;
   intent.absenceCount=1;
   return false;
}

uint MDIdentityHash(const string text)
{
   uint hash=0x811c9dc5;
   for(int i=0;i<StringLen(text);i++) hash=(hash^(uint)StringGetCharacter(text,i))*0x1000193;
   return hash;
}

string MDPersistenceKey(const MDTradeContext &context,const string prefix,const ulong identifier)
{
   const uint hash=MDIdentityHash(context.server+"|"+context.symbol);
   return StringFormat("%s.%I64d.%d.%I64u",prefix,context.login,(int)hash,identifier);
}

string MDLegacyPersistenceKey(const MDTradeContext &context,const string prefix,
                              const ulong identifier,const int base)
{
   const uint hash=MDIdentityHash(context.server+"|"+context.symbol+"|"+IntegerToString(base));
   return StringFormat("%s.%I64d.%d.%I64u",prefix,context.login,(int)hash,identifier);
}

bool MDReadMigratedValue(const MDTradeContext &context,const string currentPrefix,
                         const string legacyPrefix,const ulong identifier,double &value)
{
   if(context.tester) return false;
   const string key=MDPersistenceKey(context,currentPrefix,identifier);
   if(GlobalVariableCheck(key)) { value=GlobalVariableGet(key); return true; }
   int bases[3];
   bases[0]=(int)context.currentBase; bases[1]=context.previousBase; bases[2]=context.legacyBase;
   for(int i=0;i<3;i++)
   {
      if(i>0 && bases[i]<=0) continue;
      const string legacy=MDLegacyPersistenceKey(context,legacyPrefix,identifier,bases[i]);
      if(!GlobalVariableCheck(legacy)) continue;
      value=GlobalVariableGet(legacy);
      GlobalVariableSet(key,value);
      return true;
   }
   return false;
}

void MDDeletePersistenceValue(const MDTradeContext &context,const string currentPrefix,
                              const string legacyPrefix,const ulong identifier)
{
   if(context.tester) return;
   GlobalVariableDel(MDPersistenceKey(context,currentPrefix,identifier));
   if(legacyPrefix=="") return;
   GlobalVariableDel(MDLegacyPersistenceKey(context,legacyPrefix,identifier,(int)context.currentBase));
   if(context.previousBase>0)
      GlobalVariableDel(MDLegacyPersistenceKey(context,legacyPrefix,identifier,context.previousBase));
   if(context.legacyBase>0)
      GlobalVariableDel(MDLegacyPersistenceKey(context,legacyPrefix,identifier,context.legacyBase));
}

void MDPersistCloseIntent(const MDTradeContext &context,MDCloseIntent &intent)
{
   if(context.tester || intent.identifier==0 || intent.reason==0) return;
   const string key=MDPersistenceKey(context,"XSCL4",intent.identifier);
   double stored=0.0;
   ResetLastError();
   const bool exists=GlobalVariableGet(key,stored);
   const int error=GetLastError();
   if(!exists && error!=0 && error!=4501)
   { intent.persistDirty=true; intent.persistRetry=context.now+1; return; }
   if(exists && stored==2.0 && intent.reason<2)
   { intent.reason=2; intent.persistDirty=true; intent.persistRetry=0; }
   if(exists && stored==(double)intent.reason && !intent.persistDirty) return;
   intent.persistDirty=true;
   if(context.now<intent.persistRetry) return;
   ResetLastError();
   bool saved=true;
   if(!exists) saved=GlobalVariableSet(key,(double)intent.reason)>0;
   else if(stored!=(double)intent.reason)
      saved=GlobalVariableSetOnCondition(key,(double)intent.reason,stored);
   if(saved)
   {
      ResetLastError();
      GlobalVariablesFlush();
      saved=GetLastError()==0;
   }
   intent.persistDirty=!saved;
   intent.persistRetry=saved ? 0 : context.now+1;
}

void MDPersistEmergencyReason(const MDTradeContext &context,MDCloseIntent &intent)
{
   if(context.tester || intent.identifier==0) return;
   double persisted=0.0;
   if(MDReadMigratedValue(context,"XSCL4","XSCL3",intent.identifier,persisted))
   {
      const int reason=(int)MathRound(persisted);
      if(reason==1 || reason==2) intent.reason=MathMax(intent.reason,reason);
   }
   if(GlobalVariableSet(MDPersistenceKey(context,"XSCL4",intent.identifier),(double)intent.reason)>0)
      GlobalVariablesFlush();
}

void MDPersistPositionPeak(const MDTradeContext &context,MDExecutionState &state,const int index)
{
   if(context.tester || index<0 || index>=state.positionCount) return;
   const ulong identifier=state.positions[index].protection.identifier;
   if(identifier==0 || state.positions[index].protection.trackedVolume<=0.0) return;
   const bool pending=state.positions[index].migrationPending;
   GlobalVariableSet(MDPersistenceKey(context,pending ? "XSPLO5" : "XSPLU5",identifier),
                     state.positions[index].protection.peakPer001);
   GlobalVariableSet(MDPersistenceKey(context,pending ? "XSPLOV5" : "XSPLV5",identifier),
                     state.positions[index].protection.trackedVolume);
   if(!pending)
      GlobalVariableSet(MDPersistenceKey(context,"XSPL4",identifier),state.positions[index].protection.peakMoney);
   state.persistenceDirty=true;
}

void MDRestorePositionState(const MDTradeContext &context,const XSPositionSnapshot &position,
                            MDTrackedPosition &slot)
{
   ZeroMemory(slot);
   slot.protection.identifier=position.identifier;
   slot.protection.trackedVolume=position.volume;
   slot.close.identifier=position.identifier;
   MDResetAbsence(slot.close);
   if(context.tester) return;
   double peak=0.0,unit=0.0,previousVolume=0.0;
   bool hasPeak=MDReadMigratedValue(context,"XSPL4","XSPL2",position.identifier,peak);
   if(!hasPeak)
   {
      const string oldest=StringFormat("XSPL.%I64d.%s.%I64u",context.login,context.symbol,position.identifier);
      if(GlobalVariableCheck(oldest))
      {
         hasPeak=true;
         peak=GlobalVariableGet(oldest);
         GlobalVariableSet(MDPersistenceKey(context,"XSPL4",position.identifier),peak);
      }
   }
   const bool hasUnit=GlobalVariableGet(MDPersistenceKey(context,"XSPLU5",position.identifier),unit)
                      && MathIsValidNumber(unit) && unit>=0.0;
   GlobalVariableGet(MDPersistenceKey(context,"XSPLV5",position.identifier),previousVolume);
   bool consistent=false;
   if(hasPeak && hasUnit && MathIsValidNumber(previousVolume) && previousVolume>0.0 &&
      MathIsValidNumber(peak) && peak>=0.0 && MathIsValidNumber(position.volume) && position.volume>0.0)
   {
      const double expected=(previousVolume/0.01)*unit;
      const double tolerance=MathMax(1e-8,MathMax(MathAbs(expected),MathAbs(peak))*1e-8);
      consistent=MathIsValidNumber(expected) && MathAbs(expected-peak)<=tolerance;
      if(consistent)
      {
         slot.protection.peakMoney=peak;
         slot.protection.peakPer001=unit;
         if(position.volume<previousVolume-1e-9)
            slot.protection.peakMoney=(position.volume/0.01)*unit;
         else if(position.volume>previousVolume+1e-9)
            slot.protection.peakPer001=peak/(position.volume/0.01);
      }
   }
   if(!consistent)
   {
      if((hasPeak || hasUnit) && position.volume>0.0 && MathIsValidNumber(position.volume) &&
         MathIsValidNumber(position.profit+position.swap))
      {
         slot.protection.peakMoney=MathMax(0.0,position.profit+position.swap);
         slot.protection.peakPer001=slot.protection.peakMoney/(position.volume/0.01);
      }
      slot.migrationConflict=hasUnit;
      slot.migrationPending=(hasPeak && peak>0.0) || hasUnit;
      slot.migrationPeak=slot.migrationPending ? peak : 0.0;
   }
   if(context.persistVirtual)
   {
      MDReadMigratedValue(context,"XSPF4","XSPF3",position.identifier,slot.generalStop);
      MDReadMigratedValue(context,"XSML4","XSML3",position.identifier,slot.protection.virtualStop);
   }
   double reason=0.0,retry=0.0;
   if(MDReadMigratedValue(context,"XSCL4","XSCL3",position.identifier,reason))
   {
      const int recovered=(int)MathRound(reason);
      if(recovered==1 || recovered==2) { slot.close.reason=recovered; slot.close.hadRetry=true; }
   }
   if(MDReadMigratedValue(context,"XSCLR4","XSCLR3",position.identifier,retry))
      slot.close.nextAttempt=(datetime)MathRound(retry);
}

int MDTrackPosition(const MDTradeContext &context,MDExecutionState &state,
                     const XSPositionSnapshot &position)
{
   if(position.identifier==0) return -1;
   int empty=-1;
   for(int i=0;i<state.positionCount;i++)
   {
      if(state.positions[i].protection.identifier==position.identifier)
      { MDResetAbsence(state.positions[i].close); return i; }
      if(empty<0 && state.positions[i].protection.identifier==0) empty=i;
   }
   if(empty<0 && state.positionCount<512) empty=state.positionCount++;
   if(empty<0) return -1;
   MDRestorePositionState(context,position,state.positions[empty]);
   MDPersistPositionPeak(context,state,empty);
   return empty;
}

bool MDSessionAllowsDelete(const string symbol,const datetime now)
{
   if(SymbolInfoInteger(symbol,SYMBOL_TRADE_MODE)==SYMBOL_TRADE_MODE_DISABLED) return false;
   MqlDateTime time,fromTime,toTime;
   TimeToStruct(now,time);
   const int seconds=time.hour*3600+time.min*60+time.sec;
   datetime from=0,to=0;
   if(!SymbolInfoSessionTrade(symbol,(ENUM_DAY_OF_WEEK)time.day_of_week,0,from,to)) return true;
   for(uint i=0;i<16;i++)
   {
      if(i>0 && !SymbolInfoSessionTrade(symbol,(ENUM_DAY_OF_WEEK)time.day_of_week,i,from,to)) break;
      TimeToStruct(from,fromTime); TimeToStruct(to,toTime);
      const int start=fromTime.hour*3600+fromTime.min*60+fromTime.sec;
      const int end=toTime.hour*3600+toTime.min*60+toTime.sec;
      if(start==end || (start<end ? seconds>=start && seconds<end : seconds>=start || seconds<end))
         return true;
   }
   return false;
}

bool MDResolveExpirationFallback(const string symbol,ENUM_ORDER_TYPE_TIME &type)
{
   const long flags=SymbolInfoInteger(symbol,SYMBOL_EXPIRATION_MODE);
   if(flags==0 || (flags&SYMBOL_EXPIRATION_GTC)!=0) { type=ORDER_TIME_GTC; return true; }
   if((flags&SYMBOL_EXPIRATION_DAY)!=0) { type=ORDER_TIME_DAY; return true; }
   return false;
}

void MDResolvePendingExpiration(const MDTradeContext &context,const MDExecutionState &state,
                                const int expiryHours,const bool weekendShield,
                                const datetime weekendCutoff,ENUM_ORDER_TYPE_TIME &type,datetime &expiration)
{
   const long flags=SymbolInfoInteger(context.symbol,SYMBOL_EXPIRATION_MODE);
   const datetime normal=context.now+(expiryHours>0 ? expiryHours*3600 : 86400);
   expiration=0;
   if(state.expiryFallback) { type=state.fallbackTimeType; return; }
   if(weekendShield && (flags&SYMBOL_EXPIRATION_SPECIFIED)!=0 && weekendCutoff>context.now)
   { type=ORDER_TIME_SPECIFIED; expiration=MathMin(normal,weekendCutoff); return; }
   if(flags==0 || (flags&SYMBOL_EXPIRATION_GTC)!=0) type=ORDER_TIME_GTC;
   else if((flags&SYMBOL_EXPIRATION_DAY)!=0) type=ORDER_TIME_DAY;
   else { type=(flags&SYMBOL_EXPIRATION_SPECIFIED)!=0 ? ORDER_TIME_SPECIFIED : ORDER_TIME_SPECIFIED_DAY;
          expiration=normal; }
}

bool MDPlacePending(const MDTradeContext &context,MDExecutionState &state,MDExecutionHooks &hooks,
                     const long magic,const ENUM_ORDER_TYPE type,const double volume,
                     const double entry,const double sl,const double tp,
                     const ENUM_ORDER_TYPE_TIME timeType,const datetime expiration,
                     const string comment,MDTradeOutcome &outcome)
{
   ZeroMemory(outcome);
   if(!context.entryAllowed || !hooks.AllowEntry(context,magic,type) || !hooks.AllowTrade(context) ||
      context.now<state.laneUntil[MD_ENTRY_LANE]) return false;
   MqlTradeRequest request={};
   request.action=TRADE_ACTION_PENDING;
   request.symbol=context.symbol;
   request.magic=(ulong)magic;
   request.type=type;
   request.volume=volume;
   request.price=MDNormalizeDecimal(entry,context.digits);
   request.sl=MDNormalizeDecimal(sl,context.digits);
   request.tp=MDNormalizeDecimal(tp,context.digits);
   request.type_time=timeType;
   request.expiration=expiration;
   request.comment=comment;
   request.type_filling=ORDER_FILLING_RETURN;
   request.deviation=5000;
   bool fallback=false;
   for(int attempt=0;attempt<2;attempt++)
   {
      if(attempt>0 && !hooks.AllowEntryRetry(context)) return false;
      ZeroMemory(outcome.check);
      outcome.request=request;
      ResetLastError();
      const ulong checkStarted=context.measureTradeLatency ? GetMicrosecondCount() : 0;
      const bool checked=OrderCheck(request,outcome.check);
      outcome.latencyMicroseconds=checkStarted>0 ? GetMicrosecondCount()-checkStarted : 0;
      outcome.lastError=GetLastError();
      if(attempt==0 && outcome.check.retcode==TRADE_RETCODE_INVALID_EXPIRATION &&
         (request.type_time==ORDER_TIME_SPECIFIED || request.type_time==ORDER_TIME_SPECIFIED_DAY) &&
         MDResolveExpirationFallback(context.symbol,request.type_time))
      { request.expiration=0; fallback=true; continue; }
      if(!checked)
      {
         outcome.checkRejected=true;
         MDRecordTradeFailure(state,MD_ENTRY_LANE,outcome.check.retcode,outcome.lastError,context.now);
         return false;
      }
      if(outcome.check.retcode==TRADE_RETCODE_NO_MONEY || outcome.check.margin_free<0.0)
      { outcome.checkRejected=true; return false; }
      if(!hooks.AllowEntry(context,magic,type)) return false;
      state.entrySendCount++;
      MDSendRequest(request,outcome,context.measureTradeLatency);
      if(outcome.accepted)
      {
         if(expiration>0 && (state.fallbackEarliestExpiry==0 || expiration<state.fallbackEarliestExpiry))
            state.fallbackEarliestExpiry=expiration;
         if(fallback)
         {
            state.expiryFallback=true;
            state.fallbackTimeType=request.type_time;
            if(expiration>0 && (state.fallbackEarliestExpiry==0 || expiration<state.fallbackEarliestExpiry))
               state.fallbackEarliestExpiry=expiration;
         }
         state.pendingDirty=true;
         return true;
      }
      MDRecordTradeFailure(state,MD_ENTRY_LANE,outcome.result.retcode,outcome.lastError,context.now);
      if(attempt==0 && outcome.result.retcode==TRADE_RETCODE_INVALID_EXPIRATION &&
         (request.type_time==ORDER_TIME_SPECIFIED || request.type_time==ORDER_TIME_SPECIFIED_DAY) &&
         MDResolveExpirationFallback(context.symbol,request.type_time))
      { request.expiration=0; fallback=true; continue; }
      return false;
   }
   return false;
}

void MDSchedulePositionCleanupAt(MDExecutionState &state,const datetime now)
{
   state.cleanupPending=true;
   if(state.cleanupNext<=0 || now<state.cleanupNext) state.cleanupNext=now;
}

void MDSchedulePositionCleanup(const MDTradeContext &context,MDExecutionState &state)
{
   MDSchedulePositionCleanupAt(state,context.now);
}

bool MDModifyPosition(const MDTradeContext &context,MDExecutionState &state,MDExecutionHooks &hooks,
                       const ulong ticket,const double sl,const double tp,MDTradeOutcome &outcome)
{
   ZeroMemory(outcome);
   for(int attempt=0;attempt<2;attempt++)
   {
      if(!hooks.AllowTrade(context) || context.now<state.laneUntil[MD_MODIFY_LANE] ||
         !PositionSelectByTicket(ticket)) return false;
      state.lastObjectMagic=(ulong)PositionGetInteger(POSITION_MAGIC);
      MqlTradeRequest request={};
      request.action=TRADE_ACTION_SLTP;
      request.position=ticket;
      request.symbol=PositionGetString(POSITION_SYMBOL);
      request.magic=(ulong)PositionGetInteger(POSITION_MAGIC);
      request.sl=MDNormalizeDecimal(sl,context.digits);
      request.tp=MDNormalizeDecimal(tp,context.digits);
      if(IsStopped())
      {
         outcome.sent=false;
         outcome.accepted=false;
         outcome.partial=false;
         outcome.result.retcode=TRADE_RETCODE_CLIENT_DISABLES_AT;
         outcome.lastError=0;
      }
      else MDSendRequest(request,outcome);
      if(outcome.accepted) return true;
      if(MDRecordTradeFailure(state,MD_MODIFY_LANE,outcome.result.retcode,outcome.lastError,context.now))
         return false;
   }
   return false;
}

bool MDDeletePending(const MDTradeContext &context,MDExecutionState &state,MDExecutionHooks &hooks,
                      const ulong ticket,const long requestMagic,MDTradeOutcome &outcome)
{
   ZeroMemory(outcome);
   if(!context.deleteAllowed || !hooks.AllowTrade(context) ||
      MDReliableServerTime()<state.laneUntil[MD_DELETE_LANE]) return false;
   const datetime sessionTime=MDReliableServerTime();
   if(sessionTime<state.deleteNext) return false;
   if(!MDSessionAllowsDelete(context.symbol,sessionTime)) { state.deleteNext=sessionTime+1; return false; }
   if(!OrderSelect(ticket)) return true;
   const ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
   if(type==ORDER_TYPE_BUY_STOP || type==ORDER_TYPE_SELL_STOP)
   {
      MqlTick tick;
      if(hooks.ReadQuote(context,tick))
      {
         const double freeze=(double)SymbolInfoInteger(context.symbol,SYMBOL_TRADE_FREEZE_LEVEL)*context.point;
         const double quote=type==ORDER_TYPE_BUY_STOP ? tick.ask : tick.bid;
         if(MathAbs(OrderGetDouble(ORDER_PRICE_OPEN)-quote)<=freeze+context.point) return false;
      }
   }
   MqlTradeRequest request={};
   request.action=TRADE_ACTION_REMOVE;
   request.order=ticket;
   request.magic=state.lastObjectMagic;
   if(IsStopped()) outcome.result.retcode=TRADE_RETCODE_CLIENT_DISABLES_AT;
   else MDSendRequest(request,outcome);
   hooks.PendingDeleteResult(ticket,outcome.sent,outcome.result.retcode,outcome.lastError);
   const datetime failureTime=MDLaneRetrySeconds(MD_DELETE_LANE,outcome.result.retcode,outcome.lastError)>0
                              ? MDReliableServerTime() : 0;
   MDRecordTradeFailure(state,MD_DELETE_LANE,outcome.result.retcode,outcome.lastError,failureTime);
   outcome.presentAfter=OrderSelect(ticket);
   if(!outcome.presentAfter) { state.pendingDirty=true; return true; }
   state.deleteNext=MDReliableServerTime()+MathMax(1,MDLaneRetrySeconds(MD_DELETE_LANE,outcome.result.retcode,outcome.lastError));
   return false;
}

bool MDClosePositionOnce(const MDTradeContext &context,const ulong ticket,MDTradeOutcome &outcome)
{
   ZeroMemory(outcome);
   if(IsStopped()) { outcome.result.retcode=TRADE_RETCODE_CLIENT_DISABLES_AT; return false; }
   if(!PositionSelectByTicket(ticket)) return false;
   const string symbol=PositionGetString(POSITION_SYMBOL);
   const ENUM_POSITION_TYPE side=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   const ENUM_SYMBOL_TRADE_EXECUTION execution=(ENUM_SYMBOL_TRADE_EXECUTION)SymbolInfoInteger(symbol,SYMBOL_TRADE_EXEMODE);
   const long flags=SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE);
   ENUM_ORDER_TYPE_FILLING filling=ORDER_FILLING_FOK;
   if(execution==SYMBOL_TRADE_EXECUTION_MARKET)
   {
      if((flags&SYMBOL_FILLING_FOK)!=0) filling=ORDER_FILLING_FOK;
      else if((flags&SYMBOL_FILLING_IOC)!=0) filling=ORDER_FILLING_IOC;
      else { outcome.result.retcode=TRADE_RETCODE_INVALID_FILL; return false; }
   }
   else if(execution==SYMBOL_TRADE_EXECUTION_EXCHANGE) filling=MDCloseFilling(flags);
   MqlTradeRequest request={};
   request.action=TRADE_ACTION_DEAL;
   request.position=ticket;
   request.symbol=symbol;
   request.volume=PositionGetDouble(POSITION_VOLUME);
   request.magic=(ulong)PositionGetInteger(POSITION_MAGIC);
   request.deviation=5000;
   request.type=side==POSITION_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
   request.price=SymbolInfoDouble(symbol,side==POSITION_TYPE_BUY ? SYMBOL_BID : SYMBOL_ASK);
   request.type_filling=filling;
   MDSendRequest(request,outcome);
   return outcome.sent;
}

// Validation lane 882fb0/883750/838aa0 is separate from the strategy entry lane.
double MDValidationStop(const MDTradeContext &context,const ENUM_ORDER_TYPE type,const MqlTick &tick)
{
   double point=SymbolInfoDouble(context.symbol,SYMBOL_POINT);
   if(point<=0.0) point=context.point;
   const long stops=SymbolInfoInteger(context.symbol,SYMBOL_TRADE_STOPS_LEVEL);
   const long freeze=SymbolInfoInteger(context.symbol,SYMBOL_TRADE_FREEZE_LEVEL);
   const double distance=MathMax((MathMax(stops,freeze)+10)*point,
                                 2.0*MathMax(tick.ask-tick.bid,point)+10.0*point);
   double tickSize=SymbolInfoDouble(context.symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tickSize<=0.0) tickSize=point;
   const double stop=type==ORDER_TYPE_BUY ? MathFloor((tick.bid-distance)/tickSize+1e-10)*tickSize
                                         : MathCeil((tick.ask+distance)/tickSize-1e-10)*tickSize;
   return MDNormalizeDecimal(stop,context.digits);
}

bool MDPlaceValidationTrade(const MDTradeContext &context,MDExecutionState &state,const ENUM_ORDER_TYPE type,
                             const double volume,const double sl,const string comment,
                             MDTradeOutcome &outcome)
{
   ZeroMemory(outcome);
   state.lastObjectMagic=(ulong)(context.currentBase+7777);
   for(int index=PositionsTotal()-1;index>=0;index--)
      if(PositionGetTicket(index)!=0 && PositionGetString(POSITION_SYMBOL)==context.symbol) return false;
   const long modes=SymbolInfoInteger(context.symbol,SYMBOL_ORDER_MODE);
   if((modes&(SYMBOL_ORDER_MARKET|SYMBOL_ORDER_SL))!=(SYMBOL_ORDER_MARKET|SYMBOL_ORDER_SL)) return false;
   const double minimum=SymbolInfoDouble(context.symbol,SYMBOL_VOLUME_MIN);
   const double maximum=SymbolInfoDouble(context.symbol,SYMBOL_VOLUME_MAX);
   const double step=SymbolInfoDouble(context.symbol,SYMBOL_VOLUME_STEP);
   const double limit=SymbolInfoDouble(context.symbol,SYMBOL_VOLUME_LIMIT);
   if(minimum<=0.0 || step<=0.0 || volume<minimum-1e-8 ||
      (maximum>0.0 && volume>maximum+1e-8) || (limit>0.0 && volume>limit+1e-8)) return false;
   const double grid=(volume-minimum)/step;
   if(MathAbs(grid-MathRound(grid))>1e-7) return false;
   MqlTick tick=context.cachedTick;
   if(!context.hasCachedTick && !SymbolInfoTick(context.symbol,tick)) return false;
   const double checkedPrice=type==ORDER_TYPE_BUY ? tick.ask : tick.bid;
   double margin=0.0;
   if(!OrderCalcMargin(type,context.symbol,volume,checkedPrice,margin) ||
      margin>AccountInfoDouble(ACCOUNT_MARGIN_FREE)+1e-8) return false;
   MqlTradeRequest request={};
   request.action=TRADE_ACTION_DEAL;
   request.symbol=context.symbol;
   request.magic=(ulong)(context.currentBase+7777);
   request.volume=volume;
   request.type=type;
   request.price=MDNormalizeDecimal(checkedPrice,context.digits);
   request.sl=sl;
   request.deviation=5000;
   request.comment=comment;
   request.type_filling=MDCloseFilling(SymbolInfoInteger(context.symbol,SYMBOL_FILLING_MODE));
   outcome.request=request;
   ResetLastError();
   const bool checked=OrderCheck(request,outcome.check);
   outcome.lastError=GetLastError();
   if(!checked || outcome.check.margin_free<-1e-8) { outcome.checkRejected=true; return false; }
   if(IsStopped()) { outcome.result.retcode=TRADE_RETCODE_CLIENT_DISABLES_AT; return false; }
   if(volume<=0.0) { outcome.result.retcode=TRADE_RETCODE_INVALID_VOLUME; return false; }
   if(type!=ORDER_TYPE_BUY && type!=ORDER_TYPE_SELL)
   { outcome.result.retcode=TRADE_RETCODE_INVALID; return false; }
   const long sendModes=SymbolInfoInteger(context.symbol,SYMBOL_ORDER_MODE);
   if((sendModes&SYMBOL_ORDER_MARKET)==0)
   { outcome.result.retcode=TRADE_RETCODE_INVALID_ORDER; return false; }
   if((sendModes&SYMBOL_ORDER_SL)==0) request.sl=0.0;
   const long execution=SymbolInfoInteger(context.symbol,SYMBOL_TRADE_EXEMODE);
   const long fillingFlags=SymbolInfoInteger(context.symbol,SYMBOL_FILLING_MODE);
   if(execution<SYMBOL_TRADE_EXECUTION_MARKET) request.type_filling=ORDER_FILLING_FOK;
   else
   {
      request.type_filling=MDCloseFilling(fillingFlags);
      if(execution==SYMBOL_TRADE_EXECUTION_MARKET && request.type_filling==ORDER_FILLING_RETURN)
      { outcome.result.retcode=TRADE_RETCODE_INVALID_FILL; return false; }
   }
   request.price=SymbolInfoDouble(context.symbol,type==ORDER_TYPE_BUY ? SYMBOL_ASK : SYMBOL_BID);
   MDSendRequest(request,outcome);
   outcome.accepted=outcome.sent && (outcome.result.retcode==TRADE_RETCODE_DONE ||
                                    outcome.result.retcode==TRADE_RETCODE_DONE_PARTIAL) && outcome.result.deal!=0;
   return outcome.accepted;
}

// Native 884320 closes once; history completion is checked by the event owner.
bool MDCloseValidationTrade(const MDTradeContext &context,MDExecutionState &state,
                             const ulong ticket,MDTradeOutcome &outcome)
{
   ZeroMemory(outcome);
   if(!PositionSelectByTicket(ticket)) { outcome.coherentAbsence=true; return true; }
   state.lastObjectMagic=(ulong)(context.currentBase+7777);
   if(IsStopped()) { outcome.result.retcode=TRADE_RETCODE_CLIENT_DISABLES_AT; return false; }
   MDClosePositionOnce(context,ticket,outcome);
   outcome.presentAfter=PositionSelectByTicket(ticket);
   outcome.coherentAbsence=!outcome.presentAfter;
   return outcome.coherentAbsence;
}

void MDClearCloseIntent(const MDTradeContext &context,MDCloseIntent &intent)
{
   MDDeletePersistenceValue(context,"XSCL4","XSCL3",intent.identifier);
   MDDeletePersistenceValue(context,"XSCLR4","XSCLR3",intent.identifier);
   intent.reason=0; intent.nextAttempt=0; intent.attempts=0; intent.hadRetry=false;
   intent.persistDirty=false; intent.persistRetry=0;
   MDResetAbsence(intent);
}

void MDClearPositionProtection(const MDTradeContext &context,MDTrackedPosition &slot)
{
   MDClearCloseIntent(context,slot.close);
   MDDeletePersistenceValue(context,"XSML4","XSML3",slot.protection.identifier);
   MDDeletePersistenceValue(context,"XSPF4","XSPF3",slot.protection.identifier);
   slot.protection.virtualStop=0.0; slot.protection.lockedMoney=0.0;
   slot.protection.confirmQuotes=0; slot.protection.lastConfirmMsc=0;
   slot.mirrorRetry=0; slot.generalStop=0.0; slot.generalRetry=0;
   if(!context.tester) GlobalVariablesFlush();
}

void MDLatchCloseReason(const MDTradeContext &context,const int reason,MDCloseIntent &intent)
{
   const int previous=intent.reason;
   if(intent.reason<reason)
   {
      intent.reason=reason;
      if(!context.tester) { intent.persistDirty=true; intent.persistRetry=0; }
   }
   if(previous==0)
   { intent.nextAttempt=0; intent.attempts=0; intent.hadRetry=false; MDResetAbsence(intent); }
}

void MDMarkRecoveredCloseBar(const MDTradeContext &context,MDExecutionState &state,
                             const XSPositionSnapshot &position)
{
   const int module=MDRecognizeMagic(position.magic,context.currentBase,context.previousBase,
                                    context.legacyBase,context.quickSetup,context.enabled);
   if(module<0 || module>=9) return;
   const datetime bar=iTime(context.symbol,context.triggerTimeframes[module],0);
   if(bar<=0) return;
   if(position.type==POSITION_TYPE_BUY) state.recoveredBuyBar[module]=bar;
   else if(position.type==POSITION_TYPE_SELL) state.recoveredSellBar[module]=bar;
}

bool MDProcessCloseIntent(const MDTradeContext &context,MDExecutionState &state,MDExecutionHooks &hooks,
                           MDCloseIntent &intent,const bool emergency,MDTradeOutcome &outcome)
{
   ZeroMemory(outcome);
   if(intent.identifier==0 || intent.reason==0) return false;
   if(!emergency) MDPersistCloseIntent(context,intent);
   XSPositionSnapshot position;
   if(!MDFindPositionByIdentifier(context,intent.identifier,position))
   {
      outcome.coherentAbsence=MDConfirmPositionAbsent(context,intent);
      state.positionsDirty=true;
      MDSchedulePositionCleanupAt(state,MDReliableServerTime());
      return outcome.coherentAbsence;
   }
   MDResetAbsence(intent);
   outcome.presentAfter=true;
   outcome.remainingVolume=position.volume;
   const datetime attemptTime=MDReliableServerTime();
   if(emergency && !context.tester)
   {
      double persisted=0.0;
      if(MDReadMigratedValue(context,"XSCLR4","XSCLR3",intent.identifier,persisted))
      { intent.nextAttempt=(datetime)MathMax((double)intent.nextAttempt,persisted); intent.hadRetry=true; }
   }
   if(attemptTime<intent.nextAttempt || !hooks.AllowTrade(context) ||
      MDReliableServerTime()<state.laneUntil[MD_CLOSE_LANE])
   { intent.hadRetry=true; return false; }
   if(intent.reason==1)
   {
      const datetime budgetSecond=MDReliableServerTime();
      if(state.closeBudgetSecond!=budgetSecond)
      { state.closeBudgetSecond=budgetSecond; state.closeBudgetUsed=0; }
      if(state.closeBudgetUsed>=2) { intent.hadRetry=true; return false; }
      ++state.closeBudgetUsed;
      state.lastBudgetPosition=intent.identifier;
   }
   intent.nextAttempt=attemptTime+1;
   if(emergency && !context.tester)
   {
      if(GlobalVariableSet(MDPersistenceKey(context,"XSCLR4",intent.identifier),(double)intent.nextAttempt)>0)
         GlobalVariablesFlush();
   }
   ++intent.attempts;
   const bool recovering=intent.hadRetry;
   state.lastObjectMagic=(ulong)position.magic;
   MDClosePositionOnce(context,position.ticket,outcome);
   XSPositionSnapshot remaining;
   outcome.presentAfter=MDFindPositionByIdentifier(context,intent.identifier,remaining);
   outcome.remainingVolume=outcome.presentAfter ? remaining.volume : 0.0;
   if(outcome.presentAfter) MDResetAbsence(intent);
   else MDConfirmPositionAbsent(context,intent);
   if(recovering && outcome.accepted) MDMarkRecoveredCloseBar(context,state,position);
   if(outcome.presentAfter || outcome.partial || !outcome.accepted) intent.hadRetry=true;
   if(!outcome.accepted && !outcome.partial)
   {
      const datetime failureTime=MDLaneRetrySeconds(MD_CLOSE_LANE,outcome.result.retcode,outcome.lastError)>0
                                 ? MDReliableServerTime() : 0;
      MDRecordTradeFailure(state,MD_CLOSE_LANE,outcome.result.retcode,outcome.lastError,failureTime);
   }
   intent.nextAttempt=attemptTime+MDCloseRetrySeconds(outcome.result.retcode,outcome.lastError,outcome.sent);
   if(emergency && !context.tester)
   {
      GlobalVariableSet(MDPersistenceKey(context,"XSCLR4",intent.identifier),(double)intent.nextAttempt);
      GlobalVariablesFlush();
   }
   state.positionsDirty=true;
   MDSchedulePositionCleanupAt(state,MDReliableServerTime());
   return false;
}

int MDEmergencyIntent(const ulong identifier,const int reason,MDExecutionState &state)
{
   int empty=-1;
   for(int i=0;i<state.emergencyCount;i++)
   {
      if(state.emergency[i].identifier==identifier) return i;
      if(empty<0 && state.emergency[i].identifier==0) empty=i;
   }
   if(empty<0 && state.emergencyCount<32) empty=state.emergencyCount++;
   if(empty<0) return -1;
   ZeroMemory(state.emergency[empty]);
   state.emergency[empty].identifier=identifier;
   MDResetAbsence(state.emergency[empty]);
   return empty;
}

// Manual snapshot consumption arms reason 1; the regular queue sends later.
bool MDArmManualClose(const MDTradeContext &context,MDExecutionState &state,const ulong ticket)
{
   XSPositionSnapshot position;
   if(!MDReadPosition(ticket,position) || position.identifier==0) return false;
   const int index=MDTrackPosition(context,state,position);
   if(index>=0)
   {
      MDLatchCloseReason(context,1,state.positions[index].close);
      MDPersistCloseIntent(context,state.positions[index].close);
      return true;
   }
   const int emergency=MDEmergencyIntent(position.identifier,1,state);
   if(emergency>=0)
   {
      MDLatchCloseReason(context,1,state.emergency[emergency]);
      MDPersistEmergencyReason(context,state.emergency[emergency]);
      return true;
   }
   MDCloseIntent direct={};
   direct.identifier=position.identifier;
   direct.reason=1;
   MDPersistEmergencyReason(context,direct);
   return false;
}

bool MDManualCloseIntentStatus(const MDTradeContext &context,const MDExecutionState &state,
                                const ulong identifier,bool &delayed)
{
   delayed=false;
   for(int i=0;i<state.positionCount;i++)
      if(state.positions[i].protection.identifier==identifier)
      { delayed=state.positions[i].close.persistDirty; return true; }
   double reason=0.0;
   if(MDReadMigratedValue(context,"XSCL4","XSCL3",identifier,reason))
   {
      const int recovered=(int)MathRound(reason);
      if(recovered==1 || recovered==2) return true;
   }
   delayed=true;
   return false;
}

// 8962b0 then 88e6c0 / 88cfc0. A true return means coherent absence only.
bool MDRequestFullClose(const MDTradeContext &context,MDExecutionState &state,MDExecutionHooks &hooks,
                        const ulong ticket,const int reason,MDTradeOutcome &outcome)
{
   ZeroMemory(outcome);
   XSPositionSnapshot position;
   if(!MDReadPosition(ticket,position) || position.identifier==0) return false;
   const int index=MDTrackPosition(context,state,position);
   if(index>=0)
   {
      MDLatchCloseReason(context,reason,state.positions[index].close);
      MDPersistCloseIntent(context,state.positions[index].close);
      const bool gone=MDProcessCloseIntent(context,state,hooks,state.positions[index].close,false,outcome);
      if(gone) MDClearPositionProtection(context,state.positions[index]);
      return gone;
   }
   const int emergency=MDEmergencyIntent(position.identifier,reason,state);
   if(emergency>=0)
   {
      MDLatchCloseReason(context,reason,state.emergency[emergency]);
      MDPersistEmergencyReason(context,state.emergency[emergency]);
      const bool gone=MDProcessCloseIntent(context,state,hooks,state.emergency[emergency],true,outcome);
      if(gone)
      {
         MDClearCloseIntent(context,state.emergency[emergency]);
         state.emergency[emergency].identifier=0;
         if(!context.tester) GlobalVariablesFlush();
      }
      return gone;
   }
   // Both bounded trackers are full: preserve the intent and attempt once.
   MDCloseIntent direct={};
   direct.identifier=position.identifier;
   MDResetAbsence(direct);
   MDLatchCloseReason(context,reason,direct);
   MDPersistEmergencyReason(context,direct);
   MDProcessCloseIntent(context,state,hooks,direct,true,outcome);
   return false;
}

void MDProcessCloseQueue(const MDTradeContext &context,MDExecutionState &state,MDExecutionHooks &hooks)
{
   MDTradeOutcome outcome;
   for(int i=0;i<state.positionCount;i++)
      if(state.positions[i].close.reason>0 &&
         MDProcessCloseIntent(context,state,hooks,state.positions[i].close,false,outcome))
         MDClearPositionProtection(context,state.positions[i]);
   for(int i=0;i<state.emergencyCount;i++)
      if(state.emergency[i].reason>0)
      {
         state.emergency[i].hadRetry=true;
         if(!MDProcessCloseIntent(context,state,hooks,state.emergency[i],true,outcome)) continue;
         MDClearCloseIntent(context,state.emergency[i]);
         state.emergency[i].identifier=0;
         if(!context.tester) GlobalVariablesFlush();
      }
}

// 8423c0: reclaim slots only after the same coherent-absence test used by exits.
void MDCleanupTrackedPositions(const MDTradeContext &context,MDExecutionState &state,MDExecutionHooks &hooks)
{
   if(!state.cleanupPending || context.now<state.cleanupNext) return;
   state.cleanupPending=false;
   bool pending=false;
   for(int i=0;i<state.positionCount;i++)
   {
      const ulong identifier=state.positions[i].protection.identifier;
      if(identifier==0) continue;
      bool present=false;
      for(int p=0;p<PositionsTotal();p++)
         if(PositionGetTicket(p)!=0 && (ulong)PositionGetInteger(POSITION_IDENTIFIER)==identifier)
         { present=true; break; }
      if(present) { MDResetAbsence(state.positions[i].close); continue; }
      if(state.positions[i].close.reason==0 && !context.tester)
      {
         double persisted=0.0;
         if(MDReadMigratedValue(context,"XSCL4","XSCL3",identifier,persisted))
         {
            const int reason=(int)MathRound(persisted);
            if(reason==1 || reason==2)
            { state.positions[i].close.reason=reason; state.positions[i].close.hadRetry=true;
              state.positions[i].close.nextAttempt=0; }
         }
      }
      if(state.positions[i].close.reason>0)
      {
         MDTradeOutcome outcome;
         if(MDProcessCloseIntent(context,state,hooks,state.positions[i].close,false,outcome))
            MDClearPositionProtection(context,state.positions[i]);
         pending=true;
         continue;
      }
      if(!MDConfirmPositionAbsent(context,state.positions[i].close)) { pending=true; continue; }
      MDDeletePersistenceValue(context,"XSPL4","XSPL2",identifier);
      MDDeletePersistenceValue(context,"XSPLU5","",identifier);
      MDDeletePersistenceValue(context,"XSPLV5","",identifier);
      MDDeletePersistenceValue(context,"XSPLO5","",identifier);
      MDDeletePersistenceValue(context,"XSPLOV5","",identifier);
      MDDeletePersistenceValue(context,"XSPF4","XSPF3",identifier);
      MDDeletePersistenceValue(context,"XSML4","XSML3",identifier);
      MDDeletePersistenceValue(context,"XSCL4","XSCL3",identifier);
      MDDeletePersistenceValue(context,"XSCLR4","XSCLR3",identifier);
      if(!context.tester)
      {
         int bases[3]; bases[0]=(int)context.currentBase; bases[1]=context.previousBase; bases[2]=context.legacyBase;
         for(int b=0;b<3;b++)
            if(b==0 || bases[b]>0) GlobalVariableDel(MDLegacyPersistenceKey(context,"XSVT2",identifier,bases[b]));
         GlobalVariableDel(StringFormat("XSPL.%I64d.%s.%I64u",context.login,context.symbol,identifier));
         GlobalVariableDel(StringFormat("XSVT.%I64d.%s.%I64u",context.login,context.symbol,identifier));
         state.persistenceDirty=true;
      }
      ZeroMemory(state.positions[i]);
      MDResetAbsence(state.positions[i].close);
   }
   state.cleanupPending=pending;
   state.cleanupNext=pending ? context.now+1 : 0;
}

// 843b10: at most one eligible legacy peak is resolved per invocation.
void MDResolveLegacyPeak(const MDTradeContext &context,MDExecutionState &state)
{
   if(context.tester) return;
   for(int i=0;i<state.positionCount;i++)
   {
      if(!state.positions[i].migrationPending || state.positions[i].migrationConflict ||
         state.positions[i].protection.identifier==0 || context.now<state.positions[i].migrationRetry) continue;
      state.positions[i].migrationRetry=context.now+30;
      XSPositionSnapshot position;
      if(!MDFindPositionByIdentifier(context,state.positions[i].protection.identifier,position)) continue;
      const double previousVolume=state.positions[i].protection.trackedVolume;
      if(MathAbs(position.volume-previousVolume)>1e-9)
      {
         if(MathIsValidNumber(position.volume) && position.volume>0.0)
         {
            if(previousVolume>0.0 && position.volume<previousVolume-1e-9)
            {
               const double unit=state.positions[i].protection.peakPer001;
               state.positions[i].protection.peakMoney=MathIsValidNumber(unit) && unit>0.0
                                                        ? (position.volume/0.01)*unit : 0.0;
            }
            else if(previousVolume<=0.0 || position.volume>previousVolume+1e-9)
            {
               const double peak=state.positions[i].protection.peakMoney;
               state.positions[i].protection.peakPer001=MathIsValidNumber(peak)
                                                       ? MathMax(0.0,peak)/(position.volume/0.01) : 0.0;
            }
         }
         state.positions[i].protection.trackedVolume=position.volume;
         MDPersistPositionPeak(context,state,i);
      }
      const double oldPeak=state.positions[i].migrationPeak;
      double observed=0.0;
      if(MathIsValidNumber(position.profit+position.swap) && MathIsValidNumber(position.volume) && position.volume>0.0)
         observed=MathMax(0.0,position.profit+position.swap)/(position.volume/0.01);
      if(!(oldPeak>0.0) || !HistorySelectByPosition(position.identifier)) return;
      const int count=HistoryDealsTotal();
      double added=0.0,removed=0.0;
      bool reversal=false;
      for(int d=0;d<count;d++)
      {
         const ulong deal=HistoryDealGetTicket(d);
         if(deal==0) return;
         const long type=HistoryDealGetInteger(deal,DEAL_TYPE);
         if(type!=DEAL_TYPE_BUY && type!=DEAL_TYPE_SELL) continue;
         const ENUM_DEAL_ENTRY entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal,DEAL_ENTRY);
         if(entry==DEAL_ENTRY_IN) added+=HistoryDealGetDouble(deal,DEAL_VOLUME);
         else if(entry==DEAL_ENTRY_INOUT) { reversal=true; break; }
         else if(entry==DEAL_ENTRY_OUT || entry==DEAL_ENTRY_OUT_BY) removed+=HistoryDealGetDouble(deal,DEAL_VOLUME);
      }
      if(!reversal && HistoryDealsTotal()!=count) return;
      const bool noReduction=removed<=1e-9 && added<=position.volume+1e-9;
      const bool coherent=MathIsValidNumber(oldPeak) && MathIsValidNumber(added) &&
                           MathIsValidNumber(position.volume) && position.volume>0.0 && added>0.0 &&
                           position.volume<=added+1e-9;
      if(!reversal && noReduction && !coherent) return;
      if(!reversal && noReduction && coherent)
      {
         observed=MathMax(observed,MathMax(0.0,oldPeak)/(added/0.01));
         state.positions[i].migrationPending=false;
      }
      else state.positions[i].migrationConflict=true;
      const double peak=MathMax(state.positions[i].protection.peakPer001,observed);
      state.positions[i].protection.peakPer001=peak;
      state.positions[i].protection.peakMoney=MathIsValidNumber(peak) && MathIsValidNumber(position.volume) && peak>0.0
                                              ? (position.volume/0.01)*peak : 0.0;
      state.positions[i].protection.trackedVolume=position.volume;
      MDPersistPositionPeak(context,state,i);
      if(!state.positions[i].migrationPending)
      {
         GlobalVariableDel(MDPersistenceKey(context,"XSPLO5",position.identifier));
         GlobalVariableDel(MDPersistenceKey(context,"XSPLOV5",position.identifier));
      }
      return;
   }
}

void MDFlushProtectionState(const MDTradeContext &context,MDExecutionState &state,const bool force)
{
   if(context.tester || !state.persistenceDirty) return;
   const ulong now=GetTickCount64();
   if(!force && state.persistenceLastFlushMsc!=0 && now-state.persistenceLastFlushMsc<1000) return;
   bool written=true;
   for(int i=0;i<state.positionCount;i++)
   {
      const ulong identifier=state.positions[i].protection.identifier;
      if(identifier==0) continue;
      const bool pending=state.positions[i].migrationPending;
      if(GlobalVariableSet(MDPersistenceKey(context,pending ? "XSPLO5" : "XSPLU5",identifier),
                           state.positions[i].protection.peakPer001)<=0) written=false;
      if(GlobalVariableSet(MDPersistenceKey(context,pending ? "XSPLOV5" : "XSPLV5",identifier),
                           state.positions[i].protection.trackedVolume)<=0) written=false;
      if(!pending && GlobalVariableSet(MDPersistenceKey(context,"XSPL4",identifier),
                                      state.positions[i].protection.peakMoney)<=0) written=false;
      if(context.persistVirtual)
      {
         if(state.positions[i].protection.virtualStop>0.0 &&
            GlobalVariableSet(MDPersistenceKey(context,"XSML4",identifier),state.positions[i].protection.virtualStop)<=0)
            written=false;
         if(state.positions[i].generalStop>0.0 &&
            GlobalVariableSet(MDPersistenceKey(context,"XSPF4",identifier),state.positions[i].generalStop)<=0)
            written=false;
      }
   }
   GlobalVariablesFlush();
   state.persistenceDirty=!written;
   state.persistenceLastFlushMsc=now;
}

bool MDHasSufficientMargin(const string symbol,const ENUM_ORDER_TYPE type,const double volume,const double entry)
{
   double margin=0.0;
   return OrderCalcMargin(type,symbol,volume,entry,margin) && margin*1.05<AccountInfoDouble(ACCOUNT_MARGIN_FREE);
}

struct MDExtraTrailingConfig
{
   bool enabled;
   double breakEvenStartPips;
   double breakEvenLockPips;
   double trailStartPips;
   double trailDistancePips;
   double trailStepPips;
};

double MDStopMinimumDistance(const MDTradeContext &context)
{
   const long stops=SymbolInfoInteger(context.symbol,SYMBOL_TRADE_STOPS_LEVEL);
   const long freeze=SymbolInfoInteger(context.symbol,SYMBOL_TRADE_FREEZE_LEVEL);
   return (double)MathMax(stops,freeze)*context.point+context.point;
}

bool MDProtectionTick(const MDTradeContext &context,MqlTick &tick)
{
   if(context.hasCachedTick) { tick=context.cachedTick; return true; }
   return SymbolInfoTick(context.symbol,tick);
}

double MDClampPhysicalStop(const MDTradeContext &context,const bool buy,const MqlTick &tick,
                           const double requested)
{
   double tickSize=SymbolInfoDouble(context.symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tickSize<=0.0) tickSize=context.point;
   if(tickSize<=0.0) return 0.0;
   const double distance=MDStopMinimumDistance(context);
   const double boundary=buy ? MathFloor((tick.bid-distance)/tickSize+1e-10)*tickSize
                              : MathCeil((tick.ask+distance)/tickSize-1e-10)*tickSize;
   return MDNormalizeDecimal(buy ? MathMin(requested,boundary) : MathMax(requested,boundary),context.digits);
}

bool MDStopReached(const bool buy,const double stop,const MqlTick &tick)
{
   return stop>0.0 && (buy ? tick.bid<=stop : tick.ask>=stop);
}

bool MDConfiguredStopAllowed(const MDTradeContext &context,const double distance)
{
   return distance+0.5*context.point>=
          (double)SymbolInfoInteger(context.symbol,SYMBOL_TRADE_STOPS_LEVEL)*context.point;
}

void MDMirrorXSStop(const MDTradeContext &context,MDExecutionState &state,MDExecutionHooks &hooks,
                      const ulong ticket,const int index,MDTradeOutcome &outcome)
{
   ZeroMemory(outcome);
   if(index<0 || context.protectionMode==2 || state.positions[index].protection.virtualStop<=0.0) return;
   XSPositionSnapshot position;
   if(!MDReadPosition(ticket,position)) return;
   const bool buy=position.type==POSITION_TYPE_BUY;
   const double desired=MDNormalizeDecimal(state.positions[index].protection.virtualStop,context.digits);
   if(position.stopLoss>0.0 && (buy ? desired-0.5*context.point<=position.stopLoss
                                    : position.stopLoss<=desired+0.5*context.point))
   { state.positions[index].mirrorRetry=0; return; }
   if(context.now<state.positions[index].mirrorRetry) return;
   MqlTick tick;
   if(!hooks.ReadQuote(context,tick)) { state.positions[index].mirrorRetry=context.now+1; return; }
   const double physical=MDClampPhysicalStop(context,buy,tick,desired);
   if(physical<=0.0 || (position.stopLoss>0.0 &&
      (buy ? physical<=position.stopLoss+context.point : physical>=position.stopLoss-context.point)))
   { state.positions[index].mirrorRetry=context.now+1; return; }
   if(!MDModifyPosition(context,state,hooks,ticket,physical,position.takeProfit,outcome))
   { state.positions[index].mirrorRetry=context.now+1; return; }
   if(!MDReadPosition(ticket,position)) return;
   const bool reached=buy ? position.stopLoss>=desired-0.5*context.point
                          : position.stopLoss<=desired+0.5*context.point;
   state.positions[index].mirrorRetry=reached ? 0 : context.now+1;
}

bool MDCheckGeneralStop(const MDTradeContext &context,MDExecutionState &state,MDExecutionHooks &hooks,
                        const XSPositionSnapshot &position,const MqlTick &tick,const int index,
                        const int closeReason,MDTradeOutcome &outcome)
{
   if(index<0 || context.protectionMode==0 ||
      !MDStopReached(position.type==POSITION_TYPE_BUY,state.positions[index].generalStop,tick)) return false;
   MDRequestFullClose(context,state,hooks,position.ticket,closeReason,outcome);
   return true;
}

// 893020: virtual protection remains monotonic even if the broker cannot mirror it.
void MDApplyGeneralTrail(const MDTradeContext &context,MDExecutionState &state,MDExecutionHooks &hooks,
                         const ulong ticket,const int index,const double requested,
                         const int closeReason,MDTradeOutcome &outcome)
{
   ZeroMemory(outcome);
   XSPositionSnapshot position;
   if(index<0 || !MDReadPosition(ticket,position)) return;
   const bool buy=position.type==POSITION_TYPE_BUY;
   double desired=MDNormalizeDecimal(requested,context.digits);
   const double old=state.positions[index].generalStop;
   if(old>0.0) desired=MDNormalizeDecimal(buy ? MathMax(old,desired) : MathMin(old,desired),context.digits);
   if(context.protectionMode!=0)
   {
      if(desired<=0.0) return;
      if(old<=0.0 || (buy ? desired>old+0.5*context.point : desired<old-0.5*context.point))
      {
         state.positions[index].generalStop=desired;
         if(context.persistVirtual && !context.tester)
         {
            GlobalVariableSet(MDPersistenceKey(context,"XSPF4",position.identifier),desired);
            state.persistenceDirty=true;
         }
      }
      MqlTick firstTick;
      if(SymbolInfoTick(context.symbol,firstTick) &&
         MDCheckGeneralStop(context,state,hooks,position,firstTick,index,closeReason,outcome)) return;
   }
   const datetime current=TimeCurrent();
   if(context.protectionMode!=0 && state.positions[index].generalStop>0.0 &&
      current<state.positions[index].generalRetry)
   {
      MqlTick waitingTick;
      if(SymbolInfoTick(context.symbol,waitingTick))
         MDCheckGeneralStop(context,state,hooks,position,waitingTick,index,closeReason,outcome);
      return;
   }
   if(!MDReadPosition(ticket,position)) return;
   MqlTick tick;
   if(!SymbolInfoTick(context.symbol,tick)) return;
   const double physical=MDClampPhysicalStop(context,buy,tick,desired);
   if(position.stopLoss>0.0 && (buy ? position.stopLoss>=desired-0.5*context.point
                                   : position.stopLoss<=desired+0.5*context.point)) return;
   const bool improves=physical>0.0 && (position.stopLoss<=0.0 ||
                       (buy ? physical>position.stopLoss+context.point : physical<position.stopLoss-context.point));
   if(improves && context.protectionMode!=2)
   {
      if(MDModifyPosition(context,state,hooks,ticket,physical,position.takeProfit,outcome))
      {
         if(!MDReadPosition(ticket,position)) return;
         if(buy ? position.stopLoss>=desired-0.5*context.point : position.stopLoss<=desired+0.5*context.point)
            return;
         state.positions[index].generalRetry=current+1;
         return;
      }
      if(context.protectionMode==0) return;
   }
   if(context.protectionMode==0) return;
   state.positions[index].generalRetry=current+1;
   MqlTick fresh;
   if(SymbolInfoTick(context.symbol,fresh)) MDCheckGeneralStop(context,state,hooks,position,fresh,index,closeReason,outcome);
}

double MDFindProtectionPivot(const string symbol,const MDStrategyConfig &config,const bool buy,
                             const double pipSize,const int digits)
{
   const ENUM_TIMEFRAMES timeframe=(ENUM_TIMEFRAMES)config.protectionSelectors[0];
   const int older=config.protectionSelectors[1],newer=config.protectionSelectors[2];
   if(newer+1>50 || Bars(symbol,timeframe)<newer+2+older) return 0.0;
   for(int shift=newer+1;shift<=50;shift++)
   {
      const double pivot=buy ? iLow(symbol,timeframe,shift) : iHigh(symbol,timeframe,shift);
      bool found=true;
      for(int i=shift;i>=shift-newer;i--)
         if(buy ? iLow(symbol,timeframe,i)<pivot : iHigh(symbol,timeframe,i)>pivot)
         { found=false; break; }
      if(!found) continue;
      for(int i=shift;i<=shift+older;i++)
         if(buy ? iLow(symbol,timeframe,i)<pivot : iHigh(symbol,timeframe,i)>pivot)
         { found=false; break; }
      if(found) return MDNormalizeDecimal(pivot+(buy ? -1.0 : 1.0)*config.protectionThreshold*pipSize,digits);
   }
   return 0.0;
}

double MDProtectionPivot(const MDTradeContext &context,MDExecutionState &state,
                          const MDStrategyConfig &config,const bool buy,const double pipSize)
{
   const int module=config.moduleIndex;
   if(!context.fastMode || module<0 || module>8)
      return MDFindProtectionPivot(context.symbol,config,buy,pipSize,context.digits);
   const datetime current=TimeCurrent();
   const datetime cachedBar=buy ? state.pivotLowBar[module] : state.pivotHighBar[module];
   const datetime next=buy ? state.pivotLowNext[module] : state.pivotHighNext[module];
   if(cachedBar<=0 || next<=current)
   {
      const ENUM_TIMEFRAMES timeframe=(ENUM_TIMEFRAMES)config.protectionSelectors[0];
      const datetime bar=iTime(context.symbol,timeframe,0);
      if(bar<=0) return MDFindProtectionPivot(context.symbol,config,buy,pipSize,context.digits);
      const int seconds=PeriodSeconds(timeframe);
      if(buy) state.pivotLowNext[module]=bar+(seconds>0 ? seconds : 60);
      else state.pivotHighNext[module]=bar+(seconds>0 ? seconds : 60);
      if(bar!=cachedBar)
      {
         const double value=MDFindProtectionPivot(context.symbol,config,buy,pipSize,context.digits);
         if(buy) { state.pivotLowBar[module]=bar; state.pivotLowValue[module]=value; }
         else { state.pivotHighBar[module]=bar; state.pivotHighValue[module]=value; }
         return value;
      }
   }
   return buy ? state.pivotLowValue[module] : state.pivotHighValue[module];
}

double MDTrailingCandidate(const XSPositionSnapshot &position,const MqlTick &tick,
                           const MDStrategyConfig &strategy,const XSProtectionConfig &config,
                           const MDExtraTrailingConfig &custom,const double generalStop,
                           const double pivotPrice)
{
   const bool buy=position.type==POSITION_TYPE_BUY;
   const bool useCustom=custom.enabled && !config.lockEnabled;
   const double unit=config.pipSize;
   const double beStart=useCustom ? custom.breakEvenStartPips*10.0 : strategy.protectionCoefficients[5];
   const double beLock=useCustom ? custom.breakEvenLockPips*10.0 : strategy.protectionCoefficients[6];
   const double trailStart=useCustom ? custom.trailStartPips*10.0 : strategy.protectionCoefficients[1];
   const double trailDistance=useCustom ? custom.trailDistancePips*10.0 : strategy.protectionCoefficients[0];
   double reference=position.stopLoss;
   if(useCustom && config.protectionMode!=0 && generalStop>0.0)
      reference=buy ? MathMax(reference,generalStop) : (reference>0.0 ? MathMin(reference,generalStop) : generalStop);
   double candidate=reference;
   if(buy)
   {
      if(tick.bid>position.openPrice+beStart*unit)
         candidate=MathMax(candidate,MDNormalizeDecimal(position.openPrice+beLock*unit,config.digits));
      if(tick.bid>position.openPrice+trailStart*unit)
         candidate=MathMax(candidate,MDNormalizeDecimal(tick.bid-trailDistance*unit,config.digits));
      if(!useCustom && strategy.protectionSelectors[1]>0 && pivotPrice>0.0 && pivotPrice>candidate &&
         pivotPrice<tick.bid-unit*strategy.protectionSelectors[3]) candidate=MDNormalizeDecimal(pivotPrice,config.digits);
      if(!useCustom) return candidate>position.stopLoss+config.point ? candidate : 0.0;
      return candidate>=reference+custom.trailStepPips*10.0*unit-0.25*config.point ? candidate : 0.0;
   }
   if(tick.ask<position.openPrice-beStart*unit)
   {
      const double be=MDNormalizeDecimal(position.openPrice-beLock*unit,config.digits);
      candidate=candidate>0.0 ? MathMin(candidate,be) : be;
   }
   if(tick.ask<position.openPrice-trailStart*unit)
   {
      const double trail=MDNormalizeDecimal(tick.ask+trailDistance*unit,config.digits);
      candidate=candidate>0.0 ? MathMin(candidate,trail) : trail;
   }
   if(!useCustom && strategy.protectionSelectors[1]>0 && pivotPrice>0.0 &&
      (candidate<=0.0 || pivotPrice<candidate) && pivotPrice>tick.ask+unit*strategy.protectionSelectors[3])
      candidate=MDNormalizeDecimal(pivotPrice,config.digits);
   if(!useCustom) return position.stopLoss<=0.0 || candidate<position.stopLoss-config.point ? candidate : 0.0;
   return reference<=0.0 || candidate<=reference-custom.trailStepPips*10.0*unit+0.25*config.point ? candidate : 0.0;
}

// One position at a time; traversal order belongs to the event owner (83ff60).
// fullStrategy=false is the native protection-only lane, without TP or core trail.
void MDProtectPosition(const MDTradeContext &context,MDExecutionState &state,MDExecutionHooks &hooks,
                        const ulong ticket,const MDStrategyConfig &strategy,
                        const XSProtectionConfig &config,const MDExtraTrailingConfig &custom,
                        const bool fullStrategy,const int closeReason,MDTradeOutcome &outcome)
{
   ZeroMemory(outcome);
   XSPositionSnapshot position;
   if(!MDReadPosition(ticket,position)) return;
   const int index=MDTrackPosition(context,state,position);
   if(index>=0 && state.positions[index].close.reason>0)
   {
      if(MDProcessCloseIntent(context,state,hooks,state.positions[index].close,false,outcome))
         MDClearPositionProtection(context,state.positions[index]);
      return;
   }
   if(index<0)
   {
      double storedReason=0.0;
      if(MDReadMigratedValue(context,"XSCL4","XSCL3",position.identifier,storedReason))
      {
         const int reason=(int)MathRound(storedReason);
         if(reason==1 || reason==2)
         {
            const int emergency=MDEmergencyIntent(position.identifier,reason,state);
            if(emergency>=0)
            {
               MDLatchCloseReason(context,reason,state.emergency[emergency]);
               state.emergency[emergency].hadRetry=true;
               if(MDProcessCloseIntent(context,state,hooks,state.emergency[emergency],true,outcome))
               {
                  MDClearCloseIntent(context,state.emergency[emergency]);
                  state.emergency[emergency].identifier=0;
                  if(!context.tester) GlobalVariablesFlush();
               }
            }
            else
            {
               MDCloseIntent direct={};
               direct.identifier=position.identifier;
               direct.reason=reason;
               direct.hadRetry=true;
               MDResetAbsence(direct);
               MDProcessCloseIntent(context,state,hooks,direct,true,outcome);
            }
            return;
         }
      }
   }
   MqlTick tick;
   if(!hooks.ReadQuote(context,tick)) return;
   const bool buy=position.type==POSITION_TYPE_BUY;
   if(config.lockEnabled && index>=0)
   {
      XSProtectionUpdate update=MDUpdateXSLock(position,tick,config,state.positions[index].protection);
      if(update.peakChanged) MDPersistPositionPeak(context,state,index);
      if(update.stopChanged && context.persistVirtual && !context.tester)
      {
         GlobalVariableSet(MDPersistenceKey(context,"XSML4",position.identifier),state.positions[index].protection.virtualStop);
         state.persistenceDirty=true;
      }
      if(update.decision==MD_LOCK_REQUEST_CLOSE)
      { MDRequestFullClose(context,state,hooks,ticket,closeReason,outcome); return; }
   }
   if(MDCheckGeneralStop(context,state,hooks,position,tick,index,closeReason,outcome)) return;
   if(!MDReadPosition(ticket,position)) return;
   if(MDStopReached(buy,position.stopLoss,tick))
   { MDRequestFullClose(context,state,hooks,ticket,closeReason,outcome); return; }
   if(position.stopLoss<=0.0)
   {
      if(!hooks.AllowTrade(context)) return;
      const double distance=strategy.stopDistance*config.pipSize;
      const double stop=MDNormalizeDecimal(position.openPrice+(buy ? -distance : distance),context.digits);
      double target=position.takeProfit;
      if(fullStrategy && target<=0.0)
         target=MDNormalizeDecimal(position.openPrice+(buy ? 1.0 : -1.0)*strategy.targetDistance*config.pipSize,context.digits);
      const bool crossed=!fullStrategy && (buy ? tick.bid<=stop : stop<=tick.ask);
      if(!MDConfiguredStopAllowed(context,distance) || crossed ||
         !MDModifyPosition(context,state,hooks,ticket,stop,target,outcome))
      { MDRequestFullClose(context,state,hooks,ticket,closeReason,outcome); return; }
      if(!MDReadPosition(ticket,position)) return;
      if(position.stopLoss<=0.0)
      { MDRequestFullClose(context,state,hooks,ticket,closeReason,outcome); return; }
   }
   else if(fullStrategy && position.takeProfit<=0.0 && TimeCurrent()>=state.takeProfitRepairNext && hooks.AllowTrade(context))
   {
      state.takeProfitRepairNext=TimeCurrent()+1;
      const double target=MDNormalizeDecimal(position.openPrice+(buy ? 1.0 : -1.0)*strategy.targetDistance*config.pipSize,context.digits);
      MDModifyPosition(context,state,hooks,ticket,position.stopLoss,target,outcome);
      if(!MDReadPosition(ticket,position)) return;
   }
   if(config.lockEnabled && index>=0 && context.protectionMode!=2)
   {
      MDMirrorXSStop(context,state,hooks,ticket,index,outcome);
      if(!MDReadPosition(ticket,position)) return;
   }
   if(!fullStrategy || index<0) return;
   double pivot=0.0;
   if((!custom.enabled || config.lockEnabled) && strategy.protectionSelectors[1]>0)
      pivot=MDProtectionPivot(context,state,strategy,buy,config.pipSize);
   const double candidate=MDTrailingCandidate(position,tick,strategy,config,custom,state.positions[index].generalStop,pivot);
   if(candidate<=0.0) return;
   if(context.protectionMode==0)
   {
      const double minimum=MDStopMinimumDistance(context);
      if(buy ? candidate>=tick.bid-minimum : candidate<=tick.ask+minimum) return;
   }
   MDApplyGeneralTrail(context,state,hooks,ticket,index,candidate,closeReason,outcome);
}










const int MDCW_MAX_PACKET_BYTES=1048576;
const int MDCW_ERROR_FORMAT=414001;
const int MDCW_ERROR_IDENTITY=414002;
const int MDCW_ERROR_SIZE=414003;
const int MDCW_ERROR_IO=414004;
const int MDCW_ERROR_LOOKUP=414006;

uint MDCWHashBytes(const uchar &bytes[],const int count)
{
   uint hash=2166136261;
   for(int i=0;i<count;i++) hash=(hash^(uint)bytes[i])*16777619;
   return hash;
}

uint MDCWHashString(const string value)
{
   uchar bytes[];
   int count=StringToCharArray(value,bytes,0,WHOLE_ARRAY,CP_UTF8);
   return count>0 ? MDCWHashBytes(bytes,count-1) : 0;
}

bool MDCWPutU32(uchar &bytes[],const uint value)
{
   int offset=ArraySize(bytes);
   if(offset>MDCW_MAX_PACKET_BYTES-4 || ArrayResize(bytes,offset+4,4096)!=offset+4) return false;
   for(int i=0;i<4;i++) bytes[offset+i]=(uchar)(value>>(8*i));
   return true;
}

bool MDCWPutU64(uchar &bytes[],const ulong value)
{
   int offset=ArraySize(bytes);
   if(offset>MDCW_MAX_PACKET_BYTES-8 || ArrayResize(bytes,offset+8,4096)!=offset+8) return false;
   for(int i=0;i<8;i++) bytes[offset+i]=(uchar)(value>>(8*i));
   return true;
}

bool MDCWPutString(uchar &bytes[],const string value,const int max_bytes)
{
   uchar encoded[];
   int count=StringToCharArray(value,encoded,0,WHOLE_ARRAY,CP_UTF8)-1;
   if(count<0 || count>max_bytes || !MDCWPutU32(bytes,(uint)count)) return false;
   int offset=ArraySize(bytes);
   if(count>MDCW_MAX_PACKET_BYTES-offset || ArrayResize(bytes,offset+count,4096)!=offset+count) return false;
   for(int i=0;i<count;i++) bytes[offset+i]=encoded[i];
   return true;
}

bool MDCWGetU32(const uchar &bytes[],int &position,const int end,uint &value)
{
   if(position<0 || end>ArraySize(bytes) || position>end-4) return false;
   value=0;
   for(int i=0;i<4;i++) value|=(uint)bytes[position+i]<<(8*i);
   position+=4;
   return true;
}

bool MDCWGetU64(const uchar &bytes[],int &position,const int end,ulong &value)
{
   if(position<0 || end>ArraySize(bytes) || position>end-8) return false;
   value=0;
   for(int i=0;i<8;i++) value|=(ulong)bytes[position+i]<<(8*i);
   position+=8;
   return true;
}

bool MDCWGetString(const uchar &bytes[],int &position,const int end,string &value,const int max_bytes)
{
   uint count=0;
   if(!MDCWGetU32(bytes,position,end,count) || count>(uint)max_bytes || count>(uint)(end-position)) return false;
   value=count==0 ? "" : CharArrayToString(bytes,position,count,CP_UTF8);
   uchar roundtrip[];
   if(StringToCharArray(value,roundtrip,0,WHOLE_ARRAY,CP_UTF8)-1!=(int)count) return false;
   for(uint i=0;i<count;i++) if(roundtrip[i]!=bytes[position+(int)i]) return false;
   position+=(int)count;
   return true;
}

bool MDCWBeginPacket(uchar &bytes[],const uint kind)
{
   ArrayResize(bytes,0);
   return MDCWPutU32(bytes,0x3443444d) && MDCWPutU32(bytes,41401) &&
          MDCWPutU32(bytes,kind) && MDCWPutU32(bytes,0);
}

bool MDCWFinishPacket(uchar &bytes[])
{
   int end=ArraySize(bytes),total=end+12;
   if(end<16 || total>MDCW_MAX_PACKET_BYTES) return false;
   for(int i=0;i<4;i++) bytes[12+i]=(uchar)((uint)total>>(8*i));
   uint checksum=MDCWHashBytes(bytes,end);
   return MDCWPutU32(bytes,0x21444e45) && MDCWPutU32(bytes,checksum) && MDCWPutU32(bytes,total);
}

bool MDCWValidatePacket(const uchar &bytes[],const uint kind,int &body_end)
{
   int total=ArraySize(bytes),position=0;
   if(total<28 || total>MDCW_MAX_PACKET_BYTES) return false;
   uint magic,version,packet_kind,declared,tail_magic,checksum,tail_length;
   if(!MDCWGetU32(bytes,position,total,magic) || !MDCWGetU32(bytes,position,total,version) ||
      !MDCWGetU32(bytes,position,total,packet_kind) || !MDCWGetU32(bytes,position,total,declared)) return false;
   if(magic!=0x3443444d || version!=41401 || packet_kind!=kind || declared!=(uint)total) return false;
   body_end=total-12;
   position=body_end;
   return MDCWGetU32(bytes,position,total,tail_magic) && MDCWGetU32(bytes,position,total,checksum) &&
          MDCWGetU32(bytes,position,total,tail_length) && tail_magic==0x21444e45 &&
          tail_length==(uint)total && checksum==MDCWHashBytes(bytes,body_end);
}

bool MDCWReadPacket(const string path,const uint kind,uchar &bytes[],int &body_end,int &error)
{
   error=0; body_end=0;
   ArrayResize(bytes,0);
   if(path=="") { error=MDCW_ERROR_IDENTITY; return false; }
   ResetLastError();
   int handle=FileOpen(path,FILE_READ|FILE_BIN);
   if(handle==INVALID_HANDLE) { error=GetLastError(); if(error==0) error=MDCW_ERROR_IO; return false; }
   ulong size=FileSize(handle);
   bool ok=size>=28 && size<=(ulong)MDCW_MAX_PACKET_BYTES;
   if(ok) ok=ArrayResize(bytes,(int)size)==(int)size;
   if(!ok) { FileClose(handle); error=MDCW_ERROR_SIZE; return false; }
   uint read=FileReadArray(handle,bytes,0,(int)size);
   int read_error=GetLastError();
   FileClose(handle);
   if((ulong)read!=size || read_error!=0) { error=read_error!=0 ? read_error : MDCW_ERROR_IO; return false; }
   if(!MDCWValidatePacket(bytes,kind,body_end)) { error=MDCW_ERROR_FORMAT; return false; }
   return true;
}

bool MDCWWritePacket(const string path,const uchar &bytes[],int &error)
{
   error=0;
   int size=ArraySize(bytes);
   if(path=="" || size<28 || size>MDCW_MAX_PACKET_BYTES) { error=MDCW_ERROR_SIZE; return false; }
   ResetLastError();
   int handle=FileOpen(path,FILE_WRITE|FILE_BIN);
   if(handle==INVALID_HANDLE) { error=GetLastError(); if(error==0) error=MDCW_ERROR_IO; return false; }
   uint written=FileWriteArray(handle,bytes,0,size);
   int write_error=GetLastError();
   FileFlush(handle);
   int flush_error=GetLastError();
   FileClose(handle);
   bool ok=written==(uint)size && write_error==0 && flush_error==0;
   if(!ok) error=write_error!=0 ? write_error : (flush_error!=0 ? flush_error : MDCW_ERROR_IO);
   return ok;
}




struct MDTimeWindow { long start; long end; };
struct MDWeekendConfig {
   bool enabled;
   int mode, cutoff_minutes, reopen_minutes;
   int fallback_friday_hour, fallback_monday_hour;
   int friday_hour, friday_minute, monday_hour, monday_minute;
};
struct MDWeekendState {
   long cutoff, resume;
   datetime refresh_at, next_change;
   bool broker_sessions, custom, blocked, pending_cleanup_done;
};
struct MDGuardActions { bool close_positions; bool delete_pending; };
struct MDNormalDailyConfig { bool enabled, prop_active; double loss_percent; bool close_positions, delete_pending; };
struct MDNormalDailyState { string prefix; long day; double reference; bool blocked, ready, actions_busy; };
struct MDPropConfig {
   bool enabled;
   double starting_balance, target_percent, daily_loss_percent, total_loss_percent, safety_percent;
   bool stop_at_target, delete_pending, close_at_limit, close_at_target;
   int drawdown_mode, daily_baseline, daily_amount, trailing_amount, reset_hour, reset_minute, max_slots;
};
struct MDPropState { string prefix; double baseline, high_water, daily_reference; long day; bool daily_blocked, total_blocked, target_reached, ready, actions_busy; };
struct MDNewsConfig {
   bool major_control, trade_nfp, trade_cpi, trade_fomc, calendar_shield, filter_high, filter_moderate, fail_closed;
   int nfp_before,nfp_after,cpi_before,cpi_after,fomc_before,fomc_after,news_before,news_after;
   bool official_backup;
   string currency;
};
struct MDNewsRawRecord { ulong value_id,event_id; datetime event_time; int importance; string name,event_code; };
struct MDNewsBatchMeta {
   bool complete,truncated;
   int history_error,lookup_error,lookup_failures;
   datetime requested_at,from_time,to_time;
};
struct MDNewsWindow { datetime event_time,start,end; string name; ulong value_id,event_id; string event_code; int kind; };
struct MDNewsCachedRecord { MDNewsRawRecord event; datetime observed_at; bool offset_known; int offset_seconds; };
struct MDOfficialNewsState {
   bool active,offset_known;
   int kind,offset_minutes;
   datetime event_utc,until_utc,next_event_utc;
   ulong last_refresh_ms;
   string name,next_name,status,warning;
};
struct MDNewsState {
   bool worker_started, first_check_complete, cache_healthy, blocked;
   ulong worker_started_ms;
   datetime cache_valid_until, event_time, known_until;
   string reason, confirmed_name;
   bool official_backup_active;
   datetime official_event_utc, official_until_utc;
};
struct MDSpreadState { bool blocked, pending_cleanup; ulong invalid_quotes, valid_quotes, wide_quotes, transitions; double maximum_spread; };

long MDWeekSecond(const long seconds) { long v=seconds%604800; return v<0 ? v+604800 : v; }
bool MDWrapContains(const long now,const long start,const long end) {
   if(start==end) return false;
   return start<end ? (start<=now && now<end) : (start<=now || now<end);
}
datetime MDServerNow() { datetime t=TimeTradeServer(); return t>0 ? t : TimeCurrent(); }
datetime MDBrokerNow() { datetime t=(datetime)MathMax((long)TimeCurrent(),(long)TimeTradeServer()); return t>0 ? t : TimeLocal(); }
long MDGuardDay(const datetime now,const int offset_seconds=0) {
   MqlDateTime t; TimeToStruct(now-offset_seconds,t); return (long)t.year*1000+t.day_of_year;
}
int MDSecondsOfDay(const datetime time) { MqlDateTime t; TimeToStruct(time,t); return t.hour*3600+t.min*60+t.sec; }
bool MDTradingHoursAllow(const bool enabled,const int start_hour,const int start_minute,const int end_hour,const int end_minute,const datetime now) {
   if(!enabled) return true;
   int start=start_hour*60+start_minute, end=end_hour*60+end_minute;
   if(start==end) return true;
   MqlDateTime t; TimeToStruct(now,t); return MDWrapContains(t.hour*60+t.min,start,end);
}

bool MDAppendSession(MDTimeWindow &rows[],const long start,const long end) {
   int n=ArraySize(rows); if(ArrayResize(rows,n+1)!=n+1) return false;
   rows[n].start=start; rows[n].end=end; return true;
}
// 82b380: all seven days, up to sixteen sessions per day; preserve equal-time full days.
bool MDResolveWeekend(const string symbol,const MDWeekendConfig &c,MDWeekendState &s,const datetime now,const bool force=false) {
   if(!force && now<s.refresh_at) return true;
   s.custom=(c.mode==1); s.broker_sessions=false;
   s.cutoff=5*86400+c.fallback_friday_hour*3600;
   s.resume=86400+c.fallback_monday_hour*3600;
   if(s.custom) {
      s.cutoff=5*86400+c.friday_hour*3600+c.friday_minute*60;
      s.resume=86400+c.monday_hour*3600+c.monday_minute*60;
   } else {
      MDTimeWindow rows[];
      for(int day=0;day<7;day++) for(int index=0;index<16;index++) {
         datetime from=0,to=0;
         if(!SymbolInfoSessionTrade(symbol,(ENUM_DAY_OF_WEEK)day,index,from,to)) break;
         int a=MDSecondsOfDay(from), b=MDSecondsOfDay(to);
         long start=day*86400+a, end=day*86400+b+(a>b?86400:0);
         if(a==b) end=start+86400;
         if(start>=604800 || start>=end) continue;
         if(end<=604800) { if(!MDAppendSession(rows,start,end)) return false; }
         else if(!MDAppendSession(rows,start,604800) || !MDAppendSession(rows,0,end-604800)) return false;
      }
      int n=ArraySize(rows);
      for(int i=1;i<n;i++) {
         MDTimeWindow item=rows[i]; int j=i-1;
         while(j>=0 && (rows[j].start>item.start || (rows[j].start==item.start && rows[j].end>item.end))) { rows[j+1]=rows[j]; j--; }
         rows[j+1]=item;
      }
      MDTimeWindow merged[];
      for(int i=0;i<n;i++) {
         int m=ArraySize(merged);
         if(m==0 || merged[m-1].end<rows[i].start) { if(!MDAppendSession(merged,rows[i].start,rows[i].end)) return false; }
         else if(merged[m-1].end<rows[i].end) merged[m-1].end=rows[i].end;
      }
      n=ArraySize(merged); long longest=-1, gap_start=0, gap_end=0;
      for(int i=0;i<n;i++) {
         long end=i+1<n ? merged[i+1].start : merged[0].start+604800;
         long gap=end-merged[i].end;
         if(longest<gap) { longest=gap; gap_start=merged[i].end; gap_end=end; }
      }
      if(longest>=21600 && MDWeekSecond(gap_start)/86400>=5 && MDWeekSecond(gap_start)/86400<=6 && MDWeekSecond(gap_end)<172800) {
         s.broker_sessions=true;
         s.cutoff=MDWeekSecond(gap_start-(long)c.cutoff_minutes*60);
         s.resume=MDWeekSecond(gap_end+(long)c.reopen_minutes*60);
      }
   }
   s.refresh_at=now+(s.custom || s.broker_sessions ? 21600 : 600);
   return true;
}
bool MDWeekendBlocked(const MDWeekendConfig &c,MDWeekendState &s,const datetime now) {
   if(!c.enabled) { s.blocked=false; s.next_change=0; return false; }
   MqlDateTime t; TimeToStruct(now,t);
   long current=t.day_of_week*86400+t.hour*3600+t.min*60+t.sec;
   bool blocked=MDWrapContains(MDWeekSecond(current),MDWeekSecond(s.cutoff),MDWeekSecond(s.resume));
   if(blocked!=s.blocked) { s.blocked=blocked; s.pending_cleanup_done=false; }
   long delta=(blocked?s.resume:s.cutoff)-current;
   s.next_change=(datetime)((long)now+(delta>0?delta:delta+604800));
   return blocked;
}
// 87f7a0: absence of broker sessions is allowed; disabled symbol trading is denied.
bool MDBrokerSessionAllows(const string symbol,const datetime now) {
   if(SymbolInfoInteger(symbol,SYMBOL_TRADE_MODE)==SYMBOL_TRADE_MODE_DISABLED) return false;
   MqlDateTime t; TimeToStruct(now,t); int current=t.hour*3600+t.min*60+t.sec;
   for(int i=0;i<16;i++) {
      datetime from=0,to=0;
      if(!SymbolInfoSessionTrade(symbol,(ENUM_DAY_OF_WEEK)t.day_of_week,i,from,to)) return i==0;
      int start=MDSecondsOfDay(from), end=MDSecondsOfDay(to);
      if(start==end || MDWrapContains(current,start,end)) return true;
   }
   return false;
}

uint MDGuardScopeHash(const string text) {
   uint h=2166136261;
   for(int i=0;i<StringLen(text);i++) h=(h^(uint)StringGetCharacter(text,i))*16777619;
   return h;
}
string MDGuardPrefix(const bool prop,const long login,const int scope_variant,const string server,const string symbol,const string protection_id) {
   return (prop?"MD33PF.":"MD38NDD.")+(string)login+"."+(string)scope_variant+"."+(string)(int)MDGuardScopeHash(server+"|"+symbol+"|"+protection_id)+".";
}
bool MDGuardWrite(const string prefix,const string key,const double value) { ResetLastError(); return GlobalVariableSet(prefix+key,value)>0; }
bool MDGuardRead(const string prefix,const string key,double &value) { if(!GlobalVariableCheck(prefix+key)) return false; value=GlobalVariableGet(prefix+key); return true; }
bool MDSaveNormalDaily(const MDNormalDailyConfig &c,MDNormalDailyState &s,const bool tester,const bool flush=true) {
   if(!c.enabled || c.prop_active || !s.ready || tester) return true;
   bool ok=MDGuardWrite(s.prefix,"DAY",(double)s.day);
   if(!MDGuardWrite(s.prefix,"DREF",s.reference)) ok=false;
   if(!MDGuardWrite(s.prefix,"BLK",s.blocked?1.0:0.0)) ok=false;
   if(flush) GlobalVariablesFlush(); return ok;
}
bool MDInitNormalDaily(const MDNormalDailyConfig &c,MDNormalDailyState &s,const bool tester,const datetime now,const double equity) {
   s.ready=false; if(!c.enabled || c.prop_active) return true;
   if(equity<=0) return false;
   double day=0,blocked=0;
   if(!tester && MDGuardRead(s.prefix,"DAY",day)) {
      s.day=(long)MathRound(day);
      if(!MDGuardRead(s.prefix,"DREF",s.reference) || !MDGuardRead(s.prefix,"BLK",blocked)) return false;
      s.blocked=blocked>0.5;
   } else { s.day=MDGuardDay(now); s.reference=equity; s.blocked=false; }
   if(s.day!=MDGuardDay(now)) { s.day=MDGuardDay(now); s.reference=equity; s.blocked=false; }
   if(s.reference<=0) return false;
   s.ready=true; s.actions_busy=false;
   if(!MDSaveNormalDaily(c,s,tester)) { s.ready=false; return false; }
   return true;
}
bool MDNormalDailyAllow(const MDNormalDailyConfig &c,MDNormalDailyState &s,const bool tester,const datetime now,const double equity,const bool act,const bool pending_close_verification,MDGuardActions &actions) {
   actions.close_positions=false; actions.delete_pending=false;
   if(!c.enabled || c.prop_active) return true;
   if(!s.ready || equity<=0) return false;
   long day=MDGuardDay(now); bool changed=day!=s.day;
   if(changed) { s.day=day; s.reference=equity; s.blocked=false; }
   if(!s.blocked && equity<=s.reference*(1.0-c.loss_percent/100.0)+1e-7) { s.blocked=true; changed=true; }
   if(changed && !MDSaveNormalDaily(c,s,tester)) { s.ready=false; return false; }
   if(act && s.blocked && !s.actions_busy) { actions.close_positions=c.close_positions; actions.delete_pending=c.delete_pending; }
   return !s.blocked && !pending_close_verification;
}
bool MDSaveProp(const MDPropConfig &c,MDPropState &s,const bool tester,const bool flush=true) {
   if(!c.enabled || !s.ready || tester) return true;
   bool ok=MDGuardWrite(s.prefix,"BASE",s.baseline);
   if(!MDGuardWrite(s.prefix,"HWM",s.high_water)) ok=false;
   if(!MDGuardWrite(s.prefix,"DAY",(double)s.day)) ok=false;
   if(!MDGuardWrite(s.prefix,"DREF",s.daily_reference)) ok=false;
   if(!MDGuardWrite(s.prefix,"DBLK",s.daily_blocked?1.0:0.0)) ok=false;
   if(!MDGuardWrite(s.prefix,"TBLK",s.total_blocked?1.0:0.0)) ok=false;
   if(!MDGuardWrite(s.prefix,"TARG",s.target_reached?1.0:0.0)) ok=false;
   if(flush) GlobalVariablesFlush(); return ok;
}
bool MDInitProp(const MDPropConfig &c,MDPropState &s,const bool tester,const datetime now,const double balance,const double equity) {
   s.ready=false; if(!c.enabled) return true;
   if(balance<=0) return false;
   double day=0,daily=0,total=0,target=0;
   if(!tester && MDGuardRead(s.prefix,"BASE",s.baseline)) {
      if(c.starting_balance>0 && MathAbs(s.baseline-c.starting_balance)>0.01) return false;
      if(!MDGuardRead(s.prefix,"HWM",s.high_water) || !MDGuardRead(s.prefix,"DAY",day) || !MDGuardRead(s.prefix,"DREF",s.daily_reference) || !MDGuardRead(s.prefix,"DBLK",daily) || !MDGuardRead(s.prefix,"TBLK",total) || !MDGuardRead(s.prefix,"TARG",target)) return false;
      s.day=(long)MathRound(day); s.daily_blocked=daily>0.5; s.total_blocked=total>0.5; s.target_reached=target>0.5;
   } else {
      s.baseline=c.starting_balance>0 ? c.starting_balance : balance;
      s.high_water=MathMax(s.baseline,c.drawdown_mode==2?equity:balance);
      s.day=MDGuardDay(now,(c.reset_hour*60+c.reset_minute)*60);
      s.daily_reference=c.daily_baseline!=0?equity:balance;
      s.daily_blocked=false; s.total_blocked=false; s.target_reached=false;
   }
   if(s.baseline<=0 || s.high_water<=0 || s.daily_reference<=0) return false;
   s.ready=true; s.actions_busy=false;
   if(!MDSaveProp(c,s,tester)) { s.ready=false; return false; }
   return true;
}
bool MDPropAllow(const MDPropConfig &c,MDPropState &s,const bool tester,const datetime now,const double balance,const double equity,const int exposure_slots,const bool act,MDGuardActions &actions) {
   actions.close_positions=false; actions.delete_pending=false;
   if(!c.enabled) return true;
   if(!s.ready) return false;
   long day=MDGuardDay(now,(c.reset_hour*60+c.reset_minute)*60);
   bool changed=day!=s.day;
   if(changed) { s.day=day; s.daily_blocked=false; s.daily_reference=c.daily_baseline!=0?equity:balance; }
   double water=c.drawdown_mode==2?equity:balance;
   if(c.drawdown_mode!=0 && water>s.high_water+1e-7) {
      s.high_water=water;
      if(!tester && !MDGuardWrite(s.prefix,"HWM",water)) { s.ready=false; return false; }
   }
   if(equity<=0 || balance<=0 || s.daily_reference<=0) return false;
   double daily_amount=c.daily_amount!=0?s.daily_reference:s.baseline;
   double daily_floor=s.daily_reference-(c.daily_loss_percent-c.safety_percent)*daily_amount/100.0;
   double reference=c.drawdown_mode!=0?s.high_water:s.baseline;
   double total_amount=(c.drawdown_mode!=0 && c.trailing_amount==0)?s.baseline:reference;
   double total_floor=reference-(c.total_loss_percent-c.safety_percent)*total_amount/100.0;
   if(!s.daily_blocked && equity<=daily_floor+1e-7) { s.daily_blocked=true; changed=true; }
   if(!s.total_blocked && equity<=total_floor+1e-7) { s.total_blocked=true; changed=true; }
   if(c.stop_at_target && !s.target_reached && balance>=s.baseline*(1+c.target_percent/100.0)-1e-7) { s.target_reached=true; changed=true; }
   if(changed && !MDSaveProp(c,s,tester)) { s.ready=false; return false; }
   bool limit=s.daily_blocked || s.total_blocked, target=s.target_reached && c.stop_at_target;
   if(act && !s.actions_busy && (limit || target)) {
      actions.close_positions=(limit && c.close_at_limit) || (target && c.close_at_target);
      actions.delete_pending=c.delete_pending;
   }
   return !limit && !target && (c.max_slots<=0 || exposure_slots<c.max_slots);
}


string MDNewsCurrency(string currency) {
   StringTrimLeft(currency);StringTrimRight(currency);StringToUpper(currency);
   if(currency=="") { currency=SymbolInfoString(_Symbol,SYMBOL_CURRENCY_PROFIT);if(currency=="") currency="USD"; }
   return currency;
}
bool MDNewsCurrencyValid(const string currency) {
   if(StringLen(currency)!=3) return false;
   for(int i=0;i<3;i++) { ushort c=StringGetCharacter(currency,i); if(c<'A' || c>'Z') return false; }
   return true;
}
// 8725a0: selected major-event exceptions do not disable the general importance filter.
int MDNewsEventKind(const string name,const string code) {
   string text=name+" "+code; StringToLower(text); StringReplace(text,"-"," "); StringReplace(text,"_"," ");
   bool speech=StringFind(text,"speech")>=0 || StringFind(text,"speaks")>=0 || StringFind(text,"member")>=0;
   if((StringFind(text,"fomc")>=0 && !speech) || StringFind(text,"federal funds rate")>=0 || StringFind(text,"fed interest rate decision")>=0 || StringFind(text,"federal reserve interest rate decision")>=0 || StringFind(text,"fed monetary policy statement")>=0) return 3;
   if(StringFind(text,"adp")>=0) return 0;
   if(StringFind(text,"nonfarm payroll")>=0 || StringFind(text,"non farm payroll")>=0 || StringFind(text,"non farm employment change")>=0 || StringFind(text,"nonfarm employment change")>=0 || StringFind(text,"employment situation")>=0) return 1;
   if(StringFind(text,"cleveland fed median cpi")>=0 || StringFind(text,"median cpi")>=0 || StringFind(text,"trimmed mean cpi")>=0 || StringFind(text,"sticky price cpi")>=0) return 0;
   if(StringFind(text,"consumer price index")>=0 || StringFind(text,"core cpi")>=0 || StringFind(text,"(cpi)")>=0 || StringFind(text,"cpi m/m")>=0 || StringFind(text,"cpi y/y")>=0) return 2;
   return 0;
}
bool MDNewsMajorPolicy(const MDNewsConfig &c,const int kind,int &before,int &after) {
   before=0; after=0; if(!c.major_control) return false;
   if(kind==1 && !c.trade_nfp) { before=c.nfp_before;after=c.nfp_after;return true; }
   if(kind==2 && !c.trade_cpi) { before=c.cpi_before;after=c.cpi_after;return true; }
   if(kind==3 && !c.trade_fomc) { before=c.fomc_before;after=c.fomc_after;return true; }
   return false;
}
bool MDSelectNewsPolicy(const MDNewsConfig &c,const MDNewsRawRecord &event,int &before,int &after,int &kind) {
   before=0;after=0;kind=MDNewsEventKind(event.name,event.event_code);
   bool selected=c.calendar_shield && ((event.importance==3 && c.filter_high) || (event.importance==2 && c.filter_moderate));
   if(selected) { before=c.news_before;after=c.news_after; }
   int major_before=0,major_after=0;
   if(MDNewsMajorPolicy(c,kind,major_before,major_after)) { selected=true;before=MathMax(before,major_before);after=MathMax(after,major_after); }
   return selected;
}
bool MDAppendNewsWindow(MDNewsWindow &rows[],const MDNewsRawRecord &event,const int before,const int after,const int kind) {
   datetime start=(datetime)((long)event.event_time-(long)before*60),end=(datetime)((long)event.event_time+(long)after*60);
   int count=ArraySize(rows);
   for(int i=0;i<count;i++) if(rows[i].event_id==event.event_id && rows[i].event_time==event.event_time && rows[i].start==start && rows[i].end==end) return true;
   if(count>=512 || ArrayResize(rows,count+1)!=count+1) return false;
   rows[count].event_time=event.event_time;rows[count].start=start;rows[count].end=end;rows[count].name=event.name;
   rows[count].value_id=event.value_id;rows[count].event_id=event.event_id;rows[count].event_code=event.event_code;rows[count].kind=kind;
   return true;
}
// 877370: failed/partial refreshes retain unexpired confirmed windows.
bool MDApplyNewsBatch(const MDNewsConfig &c,MDNewsState &s,MDNewsWindow &windows[],const MDNewsBatchMeta &meta,const MDNewsRawRecord &events[],const datetime now) {
   bool healthy=meta.complete && !meta.truncated && meta.history_error==0 && meta.lookup_error==0 && meta.lookup_failures==0 && meta.requested_at>0 && meta.requested_at<=now && now<=meta.requested_at+86400;
   int keep=0;for(int i=0;i<ArraySize(windows);i++) if(now<=windows[i].end) { if(keep!=i) windows[keep]=windows[i];keep++; }
   ArrayResize(windows,keep);
   for(int i=0;i<ArraySize(events);i++) {
      int before=0,after=0,kind=0;
      if(MDSelectNewsPolicy(c,events[i],before,after,kind) && now<=(datetime)((long)events[i].event_time+(long)after*60))
         if(!MDAppendNewsWindow(windows,events[i],before,after,kind)) healthy=false;
   }
   s.first_check_complete=true;s.cache_healthy=healthy;
   if(healthy) s.cache_valid_until=meta.requested_at+86400;
   return healthy;
}
// 871140: durable cache offsets are seconds and permit up to eighteen hours.
bool MDNewsCacheOffset(int &seconds) {
   seconds=0;datetime server=TimeTradeServer(),utc=TimeGMT();
   if(server<=0 || utc<=0) return false;
   long delta=(long)server-(long)utc;if(MathAbs((double)delta)>64800) return false;
   int rounded=(int)MathRound((double)delta/60.0)*60;
   if(MathAbs((double)(delta-rounded))>2.0) return false;
   seconds=rounded;return true;
}
bool MDNewsCacheRecordValid(const MDNewsCachedRecord &r,const datetime now) {
   if(r.event.value_id==0 || r.event.event_id==0 || r.event.event_time<=0 || r.event.importance<0 || r.event.importance>3 || r.observed_at<=0 || now<r.observed_at || r.event.name=="") return false;
   if(r.event.event_time<r.observed_at-86400 || r.observed_at+259200<r.event.event_time) return false;
   if(r.offset_known && (MathAbs((double)r.offset_seconds)>64800 || r.offset_seconds%60!=0)) return false;
   uchar name[],code[];
   int name_size=StringToCharArray(r.event.name,name,0,WHOLE_ARRAY,CP_UTF8)-1,code_size=StringToCharArray(r.event.event_code,code,0,WHOLE_ARRAY,CP_UTF8)-1;
   return name_size>=0 && name_size<=768 && code_size>=0 && code_size<=256;
}
bool MDAppendNewsCache(MDNewsCachedRecord &records[],const MDNewsCachedRecord &r,const datetime now) {
   if(!MDNewsCacheRecordValid(r,now)) return false;
   if(now<=0 || now<r.observed_at || r.observed_at+259200<now || r.event.event_time+86400<now) return true;
   int n=ArraySize(records);
   for(int i=0;i<n;i++) if(records[i].event.event_id==r.event.event_id && records[i].event.event_time==r.event.event_time) {
      if(records[i].observed_at<=r.observed_at) records[i]=r;return true;
   }
   if(n>=512 || ArrayResize(records,n+1)!=n+1) return false;
   records[n]=r;return true;
}
void MDPruneNewsCache(MDNewsCachedRecord &records[],const datetime now,const bool offset_known,const int offset_seconds) {
   int keep=0;
   if(now>0 && offset_known) for(int i=0;i<ArraySize(records);i++) if(records[i].observed_at<=now && now<=records[i].observed_at+259200 && now<=records[i].event.event_time+86400 && records[i].offset_known && records[i].offset_seconds==offset_seconds) { if(keep!=i) records[keep]=records[i];keep++; }
   ArrayResize(records,keep);
}
void MDRestoreConfirmedNews(const MDNewsConfig &c,MDNewsWindow &windows[],MDNewsCachedRecord &records[],const datetime now,const bool offset_known,const int offset_seconds) {
   MDPruneNewsCache(records,now,offset_known,offset_seconds);
   for(int i=0;i<ArraySize(records);i++) {
      int before=0,after=0,kind=0;
      if(MDSelectNewsPolicy(c,records[i].event,before,after,kind) && before>=0 && before<=1440 && after>=0 && after<=1440 && now<=(datetime)((long)records[i].event.event_time+(long)after*60)) MDAppendNewsWindow(windows,records[i].event,before,after,kind);
   }
}
// 835e90: finite target-version table, evaluated in UTC independently of calendar availability.
void MDUpdateOfficialNews(const MDNewsConfig &c,MDOfficialNewsState &s,const bool tester,const datetime utc,const datetime server,const datetime last_tick,const ulong now_ms) {
   if(s.last_refresh_ms!=0 && now_ms>=s.last_refresh_ms && now_ms-s.last_refresh_ms<500) return;
   s.last_refresh_ms=now_ms;s.active=false;s.kind=0;s.event_utc=0;s.until_utc=0;s.next_event_utc=0;s.name="";s.next_name="";s.warning="";s.offset_known=false;s.offset_minutes=0;
   if(tester) { s.status="TESTER_DISABLED";return; }
   if(!c.official_backup) { s.status="DISABLED_BY_USER";return; }
   if(MDNewsCurrency(c.currency)!="USD") { s.status="DISABLED_NON_USD_CURRENCY";return; }
   if(!c.major_control) { s.status="DISABLED_MAJOR_CONTROL_OFF";return; }
   if(c.trade_nfp && c.trade_cpi && c.trade_fomc) { s.status="NO_SELECTED_MAJOR_EVENTS";return; }
   if(utc<1735689600) { s.status="UTC_CLOCK_UNAVAILABLE";return; }
   long delta=(long)server-(long)utc;
   if(server>0 && (last_tick<=0 || MathAbs((double)((long)server-(long)last_tick))<=300) && MathAbs((double)delta)<=50400) {
      int minutes=(int)((delta+(delta<0?-30:30))/60);
      if(MathAbs((double)(delta-minutes*60))<=5) { s.offset_known=true;s.offset_minutes=minutes; }
   }
   const long times[]={1789581600,1790944200,1791981000,1793210400,1793971800,1794317400,1796391000,1796842800,1796909400,1801076400,1805306400,1808935200,1812564000,1816797600,1821031200,1824660000,1828292400};
   const int kinds[]={3,1,2,3,1,2,1,3,2,3,3,3,3,3,3,3,3};
   const string names[]={"OFFICIAL BACKUP: FOMC STATEMENT (SEP 2026)","OFFICIAL BACKUP: EMPLOYMENT SITUATION / NFP (SEP 2026)","OFFICIAL BACKUP: US CPI (SEP 2026)","OFFICIAL BACKUP: FOMC STATEMENT (OCT 2026)","OFFICIAL BACKUP: EMPLOYMENT SITUATION / NFP (OCT 2026)","OFFICIAL BACKUP: US CPI (OCT 2026)","OFFICIAL BACKUP: EMPLOYMENT SITUATION / NFP (NOV 2026)","OFFICIAL BACKUP: FOMC STATEMENT (DEC 2026)","OFFICIAL BACKUP: US CPI (NOV 2026)","OFFICIAL BACKUP: FOMC STATEMENT (JAN 2027; DATE TENTATIVE)","OFFICIAL BACKUP: FOMC STATEMENT (MAR 2027; DATE TENTATIVE)","OFFICIAL BACKUP: FOMC STATEMENT (APR 2027; DATE TENTATIVE)","OFFICIAL BACKUP: FOMC STATEMENT (JUN 2027; DATE TENTATIVE)","OFFICIAL BACKUP: FOMC STATEMENT (JUL 2027; DATE TENTATIVE)","OFFICIAL BACKUP: FOMC STATEMENT (SEP 2027; DATE TENTATIVE)","OFFICIAL BACKUP: FOMC STATEMENT (OCT 2027; DATE TENTATIVE)","OFFICIAL BACKUP: FOMC STATEMENT (DEC 2027; DATE TENTATIVE)"};
   long last[4]={0,0,0,0};
   for(int i=0;i<17;i++) {
      int before=0,after=0,kind=kinds[i];if(!MDNewsMajorPolicy(c,kind,before,after)) continue;
      last[kind]=MathMax(last[kind],times[i]);
      datetime start=(datetime)(times[i]-(long)before*60),end=(datetime)(times[i]+(long)after*60);
      if(start<=utc && utc<=end && s.until_utc<=end) { s.active=true;s.kind=kind;s.event_utc=(datetime)times[i];s.until_utc=end;s.name=names[i]; }
      if(utc<=times[i] && (s.next_event_utc==0 || times[i]<s.next_event_utc)) { s.next_event_utc=(datetime)times[i];s.next_name=names[i]; }
   }
   string missing="";
   for(int kind=1;kind<=3;kind++) { int before=0,after=0;if(MDNewsMajorPolicy(c,kind,before,after) && last[kind]+(long)after*60<utc) { if(missing!="") missing+=", ";missing+=(kind==1?"NFP":kind==2?"CPI":"FOMC"); } }
   if(missing!="") s.warning="UPDATE REQUIRED FOR: "+missing;
   s.status=s.active?"ACTIVE_OFFICIAL_UTC":s.warning==""?"READY_FINITE_OFFICIAL_UTC":s.next_event_utc>0?"PARTIAL_COVERAGE_UPDATE_REQUIRED":"EXHAUSTED_UPDATE_REQUIRED";
}

// 881d60 consumes confirmed windows. It does not construct or refresh the native calendar worker.
bool MDNewsBlocked(const MDNewsConfig &c,MDNewsState &s,const MDNewsWindow &windows[],const bool tester,const datetime now,const ulong now_ms,const bool backup_active,const datetime backup_event,const datetime backup_until,const string backup_name) {
   if(tester) return false;
   if(!(c.calendar_shield && (c.filter_high || c.filter_moderate)) && (!c.major_control || (c.trade_nfp && c.trade_cpi && c.trade_fomc))) return false;
   if(!s.first_check_complete && s.worker_started && now_ms-s.worker_started_ms>9999) { s.first_check_complete=true; s.cache_healthy=false; }
   s.blocked=false; s.reason=""; s.event_time=0; s.known_until=0; s.confirmed_name="";
   for(int i=0;i<ArraySize(windows);i++) if(windows[i].start<=now && now<=windows[i].end) {
      s.blocked=true;
      if(s.known_until<=windows[i].end) { s.known_until=windows[i].end; s.confirmed_name=windows[i].name; s.event_time=windows[i].event_time; }
   }
   s.official_backup_active=backup_active; s.official_event_utc=backup_event; s.official_until_utc=backup_until;
   if(backup_active) { s.blocked=true; if(s.confirmed_name=="") s.confirmed_name=backup_name; }
   if(s.blocked) s.reason=s.confirmed_name;
   else if(!s.first_check_complete) { s.blocked=true; s.reason="CALENDAR INITIAL CHECK PENDING / NO ORDER ACTION"; }
   else if(c.fail_closed && (!s.cache_healthy || s.cache_valid_until<now)) { s.blocked=true; s.reason="CALENDAR UNAVAILABLE / CACHE STALE"; }
   return s.blocked;
}
bool MDNewsCleanupRequired(const bool news_blocked,const bool delete_before_news,const MDNewsState &s) {
   return news_blocked && delete_before_news && (s.known_until>0 || s.official_backup_active) && s.confirmed_name!="";
}
// Spread cleanup is an execution-layer operation. This transition never clears its latch by price alone.
bool MDUpdateSpreadGuard(MDSpreadState &s,const MqlTick &quote,const bool tick_ok,const double pip_size,const double threshold,const double resume_ratio) {
   if(!tick_ok || !MathIsValidNumber(pip_size) || pip_size<=0 || !MathIsValidNumber(quote.bid) || !MathIsValidNumber(quote.ask) || quote.bid<=0 || quote.ask<quote.bid || quote.time_msc<=0) { s.invalid_quotes++; return false; }
   double spread=(quote.ask-quote.bid)/pip_size;
   if(!MathIsValidNumber(spread)) { s.invalid_quotes++; return false; }
   s.valid_quotes++; s.maximum_spread=MathMax(s.maximum_spread,spread);
   if(spread>threshold+1e-8) { s.wide_quotes++; if(!s.blocked) s.transitions++; s.blocked=true; s.pending_cleanup=true; }
   else if(spread<=threshold*resume_ratio+1e-8) s.blocked=false;
   return true;
}

uint MDNewsServerHash(const string server) {
   uchar bytes[];int n=StringToCharArray(server,bytes,0,WHOLE_ARRAY,CP_UTF8)-1;if(n<0) return 0;
   uint hash=2166136261;for(int i=0;i<n;i++) hash=(hash^bytes[i])*16777619;return hash;
}
struct MDNewsCacheState { bool loaded,dirty; ulong last_error_ms; };
string MDNewsCachePath(const long login,const string server,const string currency) {
   return "XAUscalperNewsCache418\\"+(string)login+"_"+(string)MDNewsServerHash(server)+"_"+currency;
}
void MDNewsCacheLog(MDNewsCacheState &s,const string action,const int error) {
   ulong now=GetTickCount64();if(s.last_error_ms!=0 && now-s.last_error_ms<60000) return;s.last_error_ms=now;
   Print("XAUscalper confirmed-news cache | action=",action," | error=",error," | no_calendar_health_claim=true | confirmed_RAM_windows_unchanged=true");
}
bool MDCopyNewsCache(MDNewsCachedRecord &to[],const MDNewsCachedRecord &from[]) {
   int n=ArraySize(from);if(ArrayResize(to,n)!=n) return false;
   for(int i=0;i<n;i++) to[i]=from[i];return true;
}
// 8719b0: validate the entire packet before publishing any record.
bool MDReadNewsCacheSlot(const string path,const long login,const string server,const string currency,const datetime now,MDNewsCachedRecord &records[],ulong &generation,int &error) {
   ArrayResize(records,0);generation=0;uchar bytes[];int end=0,pos=16;error=414002;
   if(!MDCWReadPacket(path,0xa352,bytes,end,error)) return false;
   uint tag=0,server_hash=0,count=0;ulong stored_login=0,created=0;string stored_server="",stored_currency="";
   if(!MDCWGetU32(bytes,pos,end,tag) || tag!=0xa34a || !MDCWGetU64(bytes,pos,end,stored_login) || !MDCWGetU32(bytes,pos,end,server_hash) || !MDCWGetString(bytes,pos,end,stored_server,256) || !MDCWGetString(bytes,pos,end,stored_currency,3) || !MDCWGetU64(bytes,pos,end,generation) || !MDCWGetU64(bytes,pos,end,created) || !MDCWGetU32(bytes,pos,end,count)) { error=414002;return false; }
   if(login<=0 || stored_login!=(ulong)login || stored_server!=server || server_hash!=MDNewsServerHash(server) || stored_currency!=currency || !MDNewsCurrencyValid(currency) || generation==0 || count>512 || (long)created<=0 || (long)now<(long)created || (long)now-(long)created>259200) { generation=0;error=414002;return false; }
   MDNewsCachedRecord parsed[];if(ArrayResize(parsed,(int)count)!=(int)count) { generation=0;error=414003;return false; }
   for(uint i=0;i<count;i++) {
      ulong observed=0,event_time=0;uint known=0,offset=0,importance=0;
      if(!MDCWGetU64(bytes,pos,end,observed) || !MDCWGetU32(bytes,pos,end,known) || !MDCWGetU32(bytes,pos,end,offset) || !MDCWGetU64(bytes,pos,end,parsed[i].event.value_id) || !MDCWGetU64(bytes,pos,end,parsed[i].event.event_id) || !MDCWGetU64(bytes,pos,end,event_time) || !MDCWGetU32(bytes,pos,end,importance) || !MDCWGetString(bytes,pos,end,parsed[i].event.name,768) || !MDCWGetString(bytes,pos,end,parsed[i].event.event_code,256)) { generation=0;error=414001;return false; }
      if((long)observed<0 || (long)event_time<0 || importance>3 || known>1 || offset>129600 || (known==0 && offset!=64800)) { generation=0;error=414001;return false; }
      parsed[i].observed_at=(datetime)observed;parsed[i].offset_known=known==1;parsed[i].offset_seconds=(int)offset-64800;parsed[i].event.event_time=(datetime)event_time;parsed[i].event.importance=(int)importance;
      if(!MDNewsCacheRecordValid(parsed[i],(datetime)created)) { generation=0;error=414001;return false; }
   }
   if(pos!=end) { generation=0;error=414001;return false; }
   int offset=0;bool offset_known=MDNewsCacheOffset(offset);MDPruneNewsCache(parsed,now,offset_known,offset);
   if(!MDCopyNewsCache(records,parsed)) { ArrayResize(records,0);generation=0;error=414003;return false; }
   error=0;return true;
}
bool MDMergeNewsCacheSlots(const string path,const long login,const string server,const string currency,const datetime now,MDNewsCachedRecord &records[],ulong &generation_a,ulong &generation_b) {
   generation_a=0;generation_b=0;bool merged=true;
   for(int slot=0;slot<2;slot++) {
      MDNewsCachedRecord loaded[];ulong generation=0;int error=0;
      if(MDReadNewsCacheSlot(path+(slot==0?".a.bin":".b.bin"),login,server,currency,now,loaded,generation,error)) {
         if(slot==0) generation_a=generation;else generation_b=generation;
         for(int i=0;i<ArraySize(loaded);i++) if(!MDAppendNewsCache(records,loaded[i],now)) merged=false;
      }
   }
   return merged;
}
void MDLoadConfirmedNewsCache(const bool enabled,const MDNewsConfig &c,MDNewsCacheState &cache,MDNewsCachedRecord &records[],MDNewsWindow &windows[],const long login,const string server,const datetime now) {
   if(!enabled || cache.loaded || now<=0) return;cache.loaded=true;
   string currency=MDNewsCurrency(c.currency),path=MDNewsCachePath(login,server,currency);ulong a=0,b=0;
   bool merged=MDMergeNewsCacheSlots(path,login,server,currency,now,records,a,b);int offset=0;bool known=MDNewsCacheOffset(offset);
   MDRestoreConfirmedNews(c,windows,records,now,known,offset);
   if(!merged) MDNewsCacheLog(cache,"load_capacity",414003);
}
bool MDEncodeNewsCache(const long login,const string server,const string currency,const datetime now,const ulong generation,const MDNewsCachedRecord &records[],uchar &bytes[]) {
   if(login<=0 || server=="" || !MDNewsCurrencyValid(currency) || generation==0 || ArraySize(records)>512) return false;
   if(!MDCWBeginPacket(bytes,0xa352) || !MDCWPutU32(bytes,0xa34a) || !MDCWPutU64(bytes,(ulong)login) || !MDCWPutU32(bytes,MDNewsServerHash(server)) || !MDCWPutString(bytes,server,256) || !MDCWPutString(bytes,currency,3) || !MDCWPutU64(bytes,generation) || !MDCWPutU64(bytes,(ulong)now) || !MDCWPutU32(bytes,(uint)ArraySize(records))) return false;
   for(int i=0;i<ArraySize(records);i++) {
      if(!MDNewsCacheRecordValid(records[i],now)) return false;
      if(!MDCWPutU64(bytes,(ulong)records[i].observed_at) || !MDCWPutU32(bytes,records[i].offset_known?1:0) || !MDCWPutU32(bytes,records[i].offset_known?(uint)(records[i].offset_seconds+64800):64800) || !MDCWPutU64(bytes,records[i].event.value_id) || !MDCWPutU64(bytes,records[i].event.event_id) || !MDCWPutU64(bytes,(ulong)records[i].event.event_time) || !MDCWPutU32(bytes,(uint)records[i].event.importance) || !MDCWPutString(bytes,records[i].event.name,768) || !MDCWPutString(bytes,records[i].event.event_code,256)) return false;
   }
   return MDCWFinishPacket(bytes);
}
// 850c00: lock, merge both generations, write and verify temporary packet, replace older slot.
bool MDSaveConfirmedNewsCache(const bool enabled,const MDNewsConfig &c,MDNewsCacheState &cache,MDNewsCachedRecord &records[],const long login,const string server,const datetime now) {
   if(!enabled || !cache.dirty || now<=0) return true;
   string currency=MDNewsCurrency(c.currency),path=MDNewsCachePath(login,server,currency);
   FolderCreate("XAUscalperNewsCache418");ResetLastError();int lock=FileOpen(path+".lock",FILE_BIN|FILE_READ|FILE_WRITE);
   if(lock==INVALID_HANDLE) { MDNewsCacheLog(cache,"save_deferred_lock",GetLastError());return false; }
   MDNewsCachedRecord merged[];
   if(!MDCopyNewsCache(merged,records)) { FileClose(lock);MDNewsCacheLog(cache,"save_allocation",414003);return false; }
   int offset=0;bool known=MDNewsCacheOffset(offset);MDPruneNewsCache(merged,now,known,offset);
   ulong a=0,b=0;bool merge_ok=MDMergeNewsCacheSlots(path,login,server,currency,now,merged,a,b);
   ulong generation=(a>b?a:b)+1;if(generation==0) generation=ULONG_MAX;
   string temporary=path+"."+(string)ChartID()+".tmp",target=path+(b<a?".b.bin":".a.bin");
   uchar bytes[];int error=414003;bool ok=merge_ok && MDEncodeNewsCache(login,server,currency,now,generation,merged,bytes) && MDCWWritePacket(temporary,bytes,error);
   if(ok) {
      MDNewsCachedRecord verified[];ulong verified_generation=0;
      ok=MDReadNewsCacheSlot(temporary,login,server,currency,now,verified,verified_generation,error) && verified_generation==generation && ArraySize(verified)==ArraySize(merged);
      if(ok) { ResetLastError();ok=FileMove(temporary,0,target,FILE_REWRITE);if(!ok) error=GetLastError(); }
   }
   if(!ok) { if(FileIsExist(temporary)) FileDelete(temporary);FileClose(lock);MDNewsCacheLog(cache,"save_failed_last_good_retained",error==0?414003:error);return false; }
   FileClose(lock);if(MDCopyNewsCache(records,merged)) cache.dirty=false;
   return !cache.dirty;
}
void MDCacheAcceptedNewsBatch(const bool enabled,const bool session_valid,const MDNewsConfig &c,MDNewsCacheState &cache,MDNewsCachedRecord &records[],MDNewsWindow &windows[],const MDNewsBatchMeta &meta,const MDNewsRawRecord &events[],const long login,const string server,const datetime now) {
   if(!enabled || !session_valid || login<=0 || !MDNewsCurrencyValid(MDNewsCurrency(c.currency)) || meta.requested_at<=0 || meta.requested_at>now || now-meta.requested_at>180 || meta.from_time<=0 || meta.to_time<=meta.from_time || meta.to_time-meta.from_time>604800 || ArraySize(events)>512) return;
   MDLoadConfirmedNewsCache(enabled,c,cache,records,windows,login,server,now);
   int offset=0;bool known=MDNewsCacheOffset(offset);MDPruneNewsCache(records,now,known,offset);
   for(int i=0;i<ArraySize(events);i++) if(meta.from_time<=events[i].event_time && events[i].event_time<=meta.to_time) {
      MDNewsCachedRecord row;row.event=events[i];row.observed_at=meta.requested_at;row.offset_known=known;row.offset_seconds=offset;
      if(MDAppendNewsCache(records,row,now)) cache.dirty=true;else MDNewsCacheLog(cache,"record_rejected_or_capacity",414003);
   }
   MDSaveConfirmedNewsCache(enabled,c,cache,records,login,server,now);
}










struct MDCWRequest {
   string session;
   long parent_chart,login;
   uint server_hash;
   string currency;
   ulong sequence;
   datetime requested_at,from_time,to_time;
};
struct MDCWResult {
   MDCWRequest request;
   MDNewsBatchMeta meta;
   datetime fetched_at;
   ulong elapsed_us;
};
struct MDCWWorkerState {
   MDCWRequest identity;
   bool ready,pending,busy;
   ulong last_sequence;
   int last_error;
   MDCWResult result;
   MDNewsRawRecord records[];
};
struct MDCWParentState {
   bool enabled,queued,ready,pending,slow_reported,startup_deadline,started,first_check_complete,health_lost;
   string session,object_name,currency;
   long helper_chart;
   int past_minutes,future_minutes,restarts,bootstrap_attempts,failed_batches;
   ulong started_ms,bootstrap_ms,request_ms,next_poll_ms,next_request_ms,next_notify_ms;
   ulong next_bootstrap_ms,cooldown_until_ms,sequence;
   MDCWRequest outstanding;
};

string XSPointerPath(const long chart)
{
   return "XSPtr\\p_"+(string)chart+".txt";
}

bool XSWritePointer(const long chart,const string session)
{
   FolderCreate("XSPtr");
   int handle=FileOpen(XSPointerPath(chart),FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(handle==INVALID_HANDLE) return false;
   uint written=FileWriteString(handle,session);
   FileClose(handle);
   int latest=FileOpen("XSPtr\\latest.txt",FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(latest!=INVALID_HANDLE) { FileWriteString(latest,session); FileClose(latest); }
   return written>0;
}

void XSDeletePointer(const long chart)
{
   if(chart>0) FileDelete(XSPointerPath(chart));
}

string XSWorkerSessionForChart()
{
   long chartIsObject=0;
   if(MQLInfoInteger(MQL_TESTER) || !ChartGetInteger(0,CHART_IS_OBJECT,0,chartIsObject) || chartIsObject==0) return "";
   string path=XSPointerPath(ChartID());
   if(!FileIsExist(path)) path="XSPtr\\latest.txt";
   if(!FileIsExist(path)) return "";
   int handle=FileOpen(path,FILE_READ|FILE_TXT|FILE_ANSI);
   if(handle==INVALID_HANDLE) return "";
   string session=FileReadString(handle);
   FileClose(handle);
   return session;
}

bool MDCWValidSession(const string session)
{
   int count=StringLen(session);
   if(count<7 || count>63 || StringSubstr(session,0,6)!="MD415_") return false;
   for(int i=0;i<count;i++)
   {
      ushort c=StringGetCharacter(session,i);
      if(c!='_' && !(c>='0' && c<='9') && !(c>='A' && c<='Z') && !(c>='a' && c<='z')) return false;
   }
   return true;
}

bool MDCWValidCurrency(const string currency)
{
   if(StringLen(currency)!=3) return false;
   for(int i=0;i<3;i++) { ushort c=StringGetCharacter(currency,i); if(c<'A' || c>'Z') return false; }
   return true;
}

string MDCWPath(const string session,const string leaf)
{
   return MDCWValidSession(session) ? "XAUscalperCalendar415\\"+session+"\\"+leaf : "";
}

bool MDCWValidIdentity(const MDCWRequest &r)
{
   return MDCWValidSession(r.session) && r.parent_chart>0 && r.login>0 && MDCWValidCurrency(r.currency);
}

bool MDCWValidRequest(const MDCWRequest &r)
{
   return MDCWValidIdentity(r) && r.sequence!=0 && r.requested_at>0 && r.from_time>0 &&
          r.to_time>r.from_time && r.to_time-r.from_time<=604800;
}

bool MDCWSameIdentity(const MDCWRequest &a,const MDCWRequest &b)
{
   return a.session==b.session && a.parent_chart==b.parent_chart && a.login==b.login &&
          a.server_hash==b.server_hash && a.currency==b.currency;
}

bool MDCWSameRequest(const MDCWRequest &a,const MDCWRequest &b)
{
   return MDCWSameIdentity(a,b) && a.sequence==b.sequence && a.requested_at==b.requested_at &&
          a.from_time==b.from_time && a.to_time==b.to_time;
}

bool MDCWCurrentAccount(const MDCWRequest &r)
{
   return r.login==AccountInfoInteger(ACCOUNT_LOGIN) && r.server_hash==MDCWHashString(AccountInfoString(ACCOUNT_SERVER));
}

bool MDCWResultCanPersist(const MDCWRequest &r,const datetime now,const int raw_count=0)
{
   return MDCWValidRequest(r) && MDCWCurrentAccount(r) && r.parent_chart==ChartID() &&
          r.requested_at<=now && now-r.requested_at<=180 && raw_count>=0 && raw_count<=512;
}

bool MDCWPutRequest(uchar &bytes[],const MDCWRequest &r)
{
   return MDCWPutString(bytes,r.session,63) && MDCWPutU64(bytes,(ulong)r.parent_chart) &&
          MDCWPutU64(bytes,(ulong)r.login) && MDCWPutU32(bytes,r.server_hash) &&
          MDCWPutString(bytes,r.currency,3) && MDCWPutU64(bytes,r.sequence) &&
          MDCWPutU64(bytes,(ulong)r.requested_at) && MDCWPutU64(bytes,(ulong)r.from_time) &&
          MDCWPutU64(bytes,(ulong)r.to_time);
}

bool MDCWGetRequest(const uchar &bytes[],int &pos,const int end,MDCWRequest &r)
{
   ulong parent,login,requested,from,to;
   if(!MDCWGetString(bytes,pos,end,r.session,63) || !MDCWGetU64(bytes,pos,end,parent) ||
      !MDCWGetU64(bytes,pos,end,login) || !MDCWGetU32(bytes,pos,end,r.server_hash) ||
      !MDCWGetString(bytes,pos,end,r.currency,3) || !MDCWGetU64(bytes,pos,end,r.sequence) ||
      !MDCWGetU64(bytes,pos,end,requested) || !MDCWGetU64(bytes,pos,end,from) ||
      !MDCWGetU64(bytes,pos,end,to)) return false;
   r.parent_chart=(long)parent; r.login=(long)login;
   r.requested_at=(datetime)requested; r.from_time=(datetime)from; r.to_time=(datetime)to;
   return true;
}

bool MDCWWriteRequest(const MDCWRequest &r,const uint kind,const string leaf,int &error)
{
   error=MDCW_ERROR_IDENTITY;
   if(!MDCWValidRequest(r)) return false;
   uchar bytes[];
   error=MDCW_ERROR_SIZE;
   if(!MDCWBeginPacket(bytes,kind) || !MDCWPutRequest(bytes,r) || !MDCWFinishPacket(bytes)) return false;
   return MDCWWritePacket(MDCWPath(r.session,leaf),bytes,error);
}

bool MDCWReadRequest(const string session,const uint kind,const string leaf,MDCWRequest &r,int &error)
{
   uchar bytes[]; int end,pos=16;
   if(!MDCWReadPacket(MDCWPath(session,leaf),kind,bytes,end,error)) return false;
   error=MDCW_ERROR_FORMAT;
   if(!MDCWGetRequest(bytes,pos,end,r) || pos!=end || !MDCWValidRequest(r) || r.session!=session) return false;
   error=0;
   return true;
}

bool MDCWValidRecord(const MDNewsRawRecord &r)
{
   return r.value_id!=0 && r.event_id!=0 && r.event_time>0 && r.importance>=0 && r.importance<=3;
}

bool MDCWWriteResult(const MDCWResult &r,const MDNewsRawRecord &records[],int &error)
{
   uchar bytes[];
   int count=ArraySize(records);
   error=MDCW_ERROR_SIZE;
   if(count>512 || !MDCWBeginPacket(bytes,3) || !MDCWPutRequest(bytes,r.request) ||
      !MDCWPutU32(bytes,(uint)r.meta.complete) || !MDCWPutU32(bytes,(uint)r.meta.truncated) ||
      !MDCWPutU32(bytes,(uint)r.meta.history_error) || !MDCWPutU32(bytes,(uint)r.meta.lookup_error) ||
      !MDCWPutU32(bytes,(uint)r.meta.lookup_failures) || !MDCWPutU64(bytes,(ulong)r.fetched_at) ||
      !MDCWPutU64(bytes,r.elapsed_us) || !MDCWPutU32(bytes,count)) return false;
   for(int i=0;i<count;i++)
      if(!MDCWPutU64(bytes,records[i].value_id) || !MDCWPutU64(bytes,records[i].event_id) ||
         !MDCWPutU64(bytes,(ulong)records[i].event_time) || !MDCWPutU32(bytes,records[i].importance) ||
         !MDCWPutString(bytes,records[i].name,768) || !MDCWPutString(bytes,records[i].event_code,256)) return false;
   return MDCWFinishPacket(bytes) && MDCWWritePacket(MDCWPath(r.request.session,"result.bin"),bytes,error);
}

bool MDCWReadResult(const string session,MDCWResult &r,MDNewsRawRecord &records[],int &error)
{
   uchar bytes[]; int end,pos=16;
   ArrayResize(records,0);
   if(!MDCWReadPacket(MDCWPath(session,"result.bin"),3,bytes,end,error)) return false;
   error=MDCW_ERROR_FORMAT;
   uint complete,truncated,history_error,lookup_error,failures,count;
   ulong fetched;
   if(!MDCWGetRequest(bytes,pos,end,r.request) || !MDCWValidRequest(r.request) || r.request.session!=session ||
      !MDCWGetU32(bytes,pos,end,complete) || !MDCWGetU32(bytes,pos,end,truncated) ||
      !MDCWGetU32(bytes,pos,end,history_error) || !MDCWGetU32(bytes,pos,end,lookup_error) ||
      !MDCWGetU32(bytes,pos,end,failures) || !MDCWGetU64(bytes,pos,end,fetched) ||
      !MDCWGetU64(bytes,pos,end,r.elapsed_us) || !MDCWGetU32(bytes,pos,end,count)) return false;
   if(complete>1 || truncated>1 || count>512 || failures>512 || (long)fetched<=0 ||
      (complete==1 && (truncated!=0 || history_error!=0 || lookup_error!=0 || failures!=0))) return false;
   if(ArrayResize(records,(int)count)!=(int)count) return false;
   for(uint i=0;i<count;i++)
   {
      ulong event_time; uint importance;
      if(!MDCWGetU64(bytes,pos,end,records[i].value_id) || !MDCWGetU64(bytes,pos,end,records[i].event_id) ||
         !MDCWGetU64(bytes,pos,end,event_time) || !MDCWGetU32(bytes,pos,end,importance) ||
         !MDCWGetString(bytes,pos,end,records[i].name,768) || !MDCWGetString(bytes,pos,end,records[i].event_code,256))
      { ArrayResize(records,0); return false; }
      records[i].event_time=(datetime)event_time; records[i].importance=(int)importance;
      if(!MDCWValidRecord(records[i])) { ArrayResize(records,0); return false; }
   }
   if(pos!=end) { ArrayResize(records,0); return false; }
   r.meta.complete=(complete==1); r.meta.truncated=(truncated==1);
   r.meta.history_error=(int)history_error; r.meta.lookup_error=(int)lookup_error; r.meta.lookup_failures=(int)failures;
   r.meta.requested_at=r.request.requested_at; r.meta.from_time=r.request.from_time; r.meta.to_time=r.request.to_time;
   r.fetched_at=(datetime)fetched;
   error=0;
   return true;
}

bool MDCWLeaseValid(const MDCWWorkerState &state)
{
   if(!MDCWValidIdentity(state.identity) || !MDCWCurrentAccount(state.identity)) return false;
   double lease=0;
   if(!GlobalVariableGet(state.identity.session,lease) || !MathIsValidNumber(lease) || lease<0) return false;
   double now=(double)GetTickCount64();
   return lease<=now && now-lease<=120000.0;
}

bool MDCWCheckLease(const MDCWWorkerState &state)
{
   if(MDCWLeaseValid(state)) return true;
   Print("XAUscalper calendar worker stopped | reason=identity/parent lease invalid");
   ExpertRemove();
   return false;
}

void MDCWReportError(MDCWWorkerState &state,const string operation,const int error)
{
   if(state.last_error==error) return;
   state.last_error=error;
   Print("XAUscalper calendar worker IPC | operation=",operation," | error=",error);
}

bool MDCWPublishReady(MDCWWorkerState &state)
{
   if(state.ready) return true;
   int error=0;
   if(!MDCWWriteRequest(state.identity,1,"ready.bin",error)) { MDCWReportError(state,"ready",error); return false; }
   state.ready=true; state.last_error=0;
   return true;
}

bool MDCWPublishPending(MDCWWorkerState &state)
{
   if(!MDCWCheckLease(state)) return false;
   if(!state.pending) return true;
   int error=0;
   if(!MDCWWriteResult(state.result,state.records,error)) { MDCWReportError(state,"result",error); return false; }
   state.pending=false; state.last_error=0;
   return true;
}

bool MDCWUtf8Fits(const string value,const int max_bytes)
{
   uchar bytes[];
   int count=StringToCharArray(value,bytes,0,WHOLE_ARRAY,CP_UTF8);
   return count>0 && count-1<=max_bytes;
}

bool MDCWQueryCalendar(MDCWWorkerState &state,const MDCWRequest &request)
{
   state.result.request=request;
   ZeroMemory(state.result.meta);
   state.result.meta.requested_at=request.requested_at;
   state.result.meta.from_time=request.from_time; state.result.meta.to_time=request.to_time;
   state.result.fetched_at=0; state.result.elapsed_us=0;
   ArrayResize(state.records,0);
   ulong started=GetMicrosecondCount();
   MqlCalendarValue values[512];
   ZeroMemory(values);
   ResetLastError();
   int count=CalendarValueHistory(values,request.from_time,request.to_time,NULL,request.currency);
   int history_error=GetLastError();
   if(!MDCWCheckLease(state)) return false;
   state.result.meta.history_error=(count<0 && history_error==0) ? MDCW_ERROR_FORMAT : history_error;
   state.result.meta.truncated=(history_error==5400 || count>512);
   state.result.meta.complete=(count>=0 && count<=512 && history_error==0);
   int candidates=count<0 ? (history_error==5400 ? 512 : 0) : MathMin(count,512);
   for(int i=0;i<candidates;i++)
   {
      if(!MDCWCheckLease(state)) return false;
      if(values[i].id==0 || values[i].event_id==0 || values[i].time<=0)
      {
         state.result.meta.complete=false;
         if(!state.result.meta.truncated) state.result.meta.lookup_error=MDCW_ERROR_FORMAT;
         continue;
      }
      MqlCalendarEvent event;
      ZeroMemory(event);
      ResetLastError();
      bool found=CalendarEventById(values[i].event_id,event);
      int lookup_error=GetLastError();
      if(!MDCWCheckLease(state)) return false;
      if(!found || lookup_error!=0 || event.id!=values[i].event_id)
      {
         state.result.meta.complete=false;
         state.result.meta.lookup_failures=1;
         state.result.meta.lookup_error=lookup_error!=0 ? lookup_error : MDCW_ERROR_LOOKUP;
         break;
      }
      if(!MDCWUtf8Fits(event.name,768) || !MDCWUtf8Fits(event.event_code,256))
      {
         state.result.meta.complete=false; state.result.meta.truncated=true;
         state.result.meta.lookup_error=MDCW_ERROR_SIZE;
         break;
      }
      int next=ArraySize(state.records);
      if(ArrayResize(state.records,next+1)!=next+1)
      {
         state.result.meta.complete=false; state.result.meta.truncated=true;
         state.result.meta.lookup_error=4004;
         break;
      }
      state.records[next].value_id=values[i].id; state.records[next].event_id=values[i].event_id;
      state.records[next].event_time=values[i].time; state.records[next].importance=(int)event.importance;
      state.records[next].name=event.name; state.records[next].event_code=event.event_code;
      if(!MDCWValidRecord(state.records[next]))
      {
         ArrayResize(state.records,next);
         state.result.meta.complete=false; state.result.meta.lookup_error=MDCW_ERROR_FORMAT;
         break;
      }
   }
   if(!MDCWCheckLease(state)) return false;
   state.result.fetched_at=TimeTradeServer();
   if(state.result.fetched_at<=0) state.result.fetched_at=request.requested_at;
   state.result.elapsed_us=GetMicrosecondCount()-started;
   state.last_sequence=request.sequence; state.pending=true;
   return MDCWPublishPending(state);
}

bool MDCWInitializeWorker(const string session,MDCWWorkerState &state)
{
   ZeroMemory(state);
   int error=0;
   if(MQLInfoInteger(MQL_TESTER) || !MDCWValidSession(session) ||
      !MDCWReadRequest(session,2,"request.bin",state.identity,error) || !MDCWLeaseValid(state))
   {
      Print("XAUscalper calendar helper initialization refused | invalid identity/lease | error=",error);
      return false;
   }
   state.last_sequence=state.identity.sequence;
   MDCWPublishReady(state);
   return true;
}

void MDCWWorkerChartEvent(MDCWWorkerState &state,const int id,const string session)
{
   if(id!=CHARTEVENT_CUSTOM+414 || session!=state.identity.session || state.busy) return;
   if(!MDCWCheckLease(state)) return;
   state.busy=true;
   if(MDCWPublishReady(state) && MDCWPublishPending(state))
   {
      MDCWRequest request; int error=0;
      if(!MDCWReadRequest(state.identity.session,2,"request.bin",request,error)) MDCWReportError(state,"request",error);
      else if(!MDCWSameIdentity(request,state.identity)) MDCWReportError(state,"request",MDCW_ERROR_IDENTITY);
      else if(request.sequence>state.last_sequence && MDCWCheckLease(state)) MDCWQueryCalendar(state,request);
   }
   state.busy=false;
}

bool MDCWPrepareTemplate(const string session)
{
   string folder="XAUscalperCalendar415\\"+session;
   FolderCreate("XAUscalperCalendar415"); FolderCreate(folder);
   string seed=folder+"\\seed.tpl";
   if(!ChartSaveTemplate(0,"\\Files\\"+seed)) return false;
   int handle=FileOpen(seed,FILE_READ|FILE_TXT|FILE_ANSI);
   if(handle==INVALID_HANDLE) return false;
   bool ok=FileSize(handle)<=1048576;
   string text=""; int lines=0;
   while(ok && !FileIsEnding(handle))
   {
      if(++lines>16384 || StringLen(text)>1048576) { ok=false; break; }
      ulong before=FileTell(handle);
      ResetLastError();
      string line=FileReadString(handle);
      if(GetLastError()!=0 || (!FileIsEnding(handle) && FileTell(handle)<=before)) { ok=false; break; }
      text+=line+"\n";
   }
   FileClose(handle);
   if(!ok) return false;
   FileDelete(seed);
   StringReplace(text,"\r","");
   int expert_start=StringFind(text,"<expert>\n"),expert_end=StringFind(text,"</expert>",expert_start);
   int indicator_start=StringFind(text,"<indicator>\nname=Main\n");
   int indicator_end=StringFind(text,"</indicator>",indicator_start);
   if(expert_start<0 || expert_end<expert_start || indicator_start<0 || indicator_end<indicator_start) return false;
   string expert=StringSubstr(text,expert_start,expert_end-expert_start+9);
   string header=StringSubstr(text,0,expert_start);
   int windows=StringFind(header,"windows_total="),windows_end=StringFind(header,"\n",windows);
   if(windows<0 || windows_end<windows) return false;
   header=StringSubstr(header,0,windows)+"windows_total=1"+StringSubstr(header,windows_end);
   string output=header+expert+"\n<window>\nheight=100.000000\nobjects=0\n"+
                 StringSubstr(text,indicator_start,indicator_end-indicator_start+12)+"\n</window>\n</chart>\n";
   StringReplace(output,"\n","\r\n");
   handle=FileOpen(folder+"\\worker.tpl",FILE_WRITE|FILE_TXT|FILE_UNICODE);
   if(handle==INVALID_HANDLE) return false;
   uint written=FileWriteString(handle,output);
   FileClose(handle);
   return written==(uint)(StringLen(output)*2);
}

void MDCWDisposeTransport(MDCWParentState &state)
{
   if(state.session!="")
   {
      XSDeletePointer(state.helper_chart);
      GlobalVariableDel(state.session);
      if(state.object_name!="") ObjectDelete(0,state.object_name);
      string leaves[]={"request.bin","result.bin","ready.bin","worker.tpl","seed.tpl"};
      for(int i=0;i<ArraySize(leaves);i++) FileDelete(MDCWPath(state.session,leaves[i]));
      FolderDelete("XAUscalperCalendar415\\"+state.session);
   }
   state.queued=false;
}

void MDCWClearTransportState(MDCWParentState &state)
{
   state.session=""; state.object_name=""; state.helper_chart=0;
   state.queued=false; state.ready=false; state.pending=false;
}

datetime MDCWServerNow()
{
   datetime now=TimeTradeServer();
   return now>0 ? now : TimeCurrent();
}

void MDCWBuildRequest(MDCWParentState &state,const datetime now,MDCWRequest &request)
{
   request.session=state.session; request.parent_chart=ChartID(); request.login=AccountInfoInteger(ACCOUNT_LOGIN);
   request.server_hash=MDCWHashString(AccountInfoString(ACCOUNT_SERVER)); request.currency=state.currency;
   request.sequence=++state.sequence; request.requested_at=now;
   request.from_time=now-state.past_minutes*60; request.to_time=now+86400+state.future_minutes*60;
}

bool MDCWBootstrap(MDCWParentState &state)
{
   if(!state.enabled || MQLInfoInteger(MQL_TESTER)) return false;
   ulong now=GetTickCount64();
   if(!state.started) { state.started=true; state.started_ms=now; }
   state.bootstrap_ms=now;
   state.bootstrap_attempts++;
   state.next_bootstrap_ms=now+(state.bootstrap_attempts>=3 ? 300000 : 60000);
   if(!MDCWValidCurrency(state.currency)) return false;
   state.session="MD415_"+(string)ChartID()+"_"+(string)now+"_"+(string)(GetMicrosecondCount()%100000);
   if(!MDCWValidSession(state.session) || !MDCWPrepareTemplate(state.session)) return false;
   if(!GlobalVariableTemp(state.session) || GlobalVariableSet(state.session,(double)now)==0) return false;
   datetime server_now=MDCWServerNow();
   if(server_now<=0) return false;
   state.sequence=0;
   MDCWRequest bootstrap_request;
   MDCWBuildRequest(state,server_now,bootstrap_request);
   int error=0;
   if(!MDCWWriteRequest(bootstrap_request,2,"request.bin",error)) return false;
   state.object_name="XAUscalperCalendar_"+state.session;
   if(!ObjectCreate(0,state.object_name,OBJ_CHART,0,0,0)) return false;
   ObjectSetString(0,state.object_name,OBJPROP_SYMBOL,_Symbol);
   ObjectSetInteger(0,state.object_name,OBJPROP_PERIOD,PERIOD_M15);
   ObjectSetInteger(0,state.object_name,OBJPROP_XDISTANCE,-1000);
   ObjectSetInteger(0,state.object_name,OBJPROP_XSIZE,1);
   ObjectSetInteger(0,state.object_name,OBJPROP_YSIZE,1);
   ObjectSetInteger(0,state.object_name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,state.object_name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,state.object_name,OBJPROP_ZORDER,0);
   state.helper_chart=ObjectGetInteger(0,state.object_name,OBJPROP_CHART_ID);
   if(state.helper_chart<=0 || state.helper_chart==ChartID()) return false;
   if(!XSWritePointer(state.helper_chart,state.session)) return false;
   state.queued=ChartApplyTemplate(state.helper_chart,"\\Files\\"+MDCWPath(state.session,"worker.tpl"));
   Print("XAUscalper calendar async startup | helper_queued=",state.queued,
         " | initial_grace_ms=10000 | helper_can_trade=false | awaiting_handshake=true");
   return state.queued;
}

void MDCWConfigureParent(MDCWParentState &state,const bool enabled,const string currency,const int past_minutes,const int future_minutes)
{
   ZeroMemory(state);
   state.enabled=enabled; state.currency=currency; state.past_minutes=past_minutes; state.future_minutes=future_minutes;
}

void MDCWRestart(MDCWParentState &state,const string reason)
{
   ulong now=GetTickCount64();
   if(state.restarts>=3)
   {
      Print("XAUscalper calendar worker restart budget exhausted | reason=",reason," | cooldown_seconds=300");
      MDCWDisposeTransport(state); MDCWClearTransportState(state);
      state.cooldown_until_ms=now+300000;
      return;
   }
   state.restarts++;
   Print("XAUscalper calendar worker restart | reason=",reason," | attempt=",state.restarts," / 3");
   MDCWDisposeTransport(state); MDCWClearTransportState(state);
   MDCWBootstrap(state);
}

void MDCWNotify(const MDCWParentState &state)
{
   EventChartCustom(state.helper_chart,414,0,0,state.session);
}

void MDCWAcknowledgeResult(MDCWParentState &state,const bool healthy)
{
   state.failed_batches=healthy ? 0 : MathMin(state.failed_batches+1,4);
   ulong delay=60000;
   if(state.failed_batches>1) delay=(ulong)(MathPow(2,state.failed_batches-1)*60000);
   state.next_request_ms=GetTickCount64()+delay;
}

bool MDCWParentPoll(MDCWParentState &state,MDCWResult &result,MDNewsRawRecord &records[])
{
   if(!state.enabled || MQLInfoInteger(MQL_TESTER)) return false;
   ulong now=GetTickCount64();
   if(!state.first_check_complete && state.started && now-state.started_ms>=10000)
   {
      state.startup_deadline=true; state.first_check_complete=true; state.health_lost=true;
   }
   if(now<state.next_poll_ms) return false;
   state.next_poll_ms=now+1000;
   if(!state.queued)
   {
      if(state.cooldown_until_ms!=0)
      {
         if(now<state.cooldown_until_ms) return false;
         state.cooldown_until_ms=0; state.restarts=0; state.bootstrap_attempts=0; state.next_bootstrap_ms=now;
      }
      else if(now<state.next_bootstrap_ms) return false;
      if(state.bootstrap_attempts>=3) state.bootstrap_attempts=0;
      MDCWDisposeTransport(state); MDCWClearTransportState(state); MDCWBootstrap(state);
      return false;
   }
   GlobalVariableSet(state.session,(double)now);
   int error=0;
   if(!state.ready)
   {
      MDCWRequest ready;
      bool valid=MDCWReadRequest(state.session,1,"ready.bin",ready,error) && MDCWCurrentAccount(ready) &&
                 ready.parent_chart==ChartID() && ready.currency==state.currency;
      if(!valid)
      {
         if(now>=state.next_notify_ms) { MDCWNotify(state); state.next_notify_ms=now+5000; }
         if(state.bootstrap_ms!=0 && now-state.bootstrap_ms>=30000) MDCWRestart(state,"READY_HANDSHAKE_TIMEOUT");
         return false;
      }
      state.ready=true;
      Print("XAUscalper calendar async worker ready | independent_thread=true | helper_can_trade=false");
   }
   if(!state.pending)
   {
      datetime server_now=MDCWServerNow();
      if(now<state.next_request_ms || server_now<=0) return false;
      MDCWBuildRequest(state,server_now,state.outstanding);
      if(!MDCWWriteRequest(state.outstanding,2,"request.bin",error))
      {
         state.next_request_ms=now+60000; state.health_lost=true;
         Print("XAUscalper calendar transport unavailable | request_write_error=",error);
         return false;
      }
      state.slow_reported=false; state.pending=true; state.request_ms=now;
      MDCWNotify(state); state.next_notify_ms=now+60000;
      return false;
   }
   if(MDCWReadResult(state.session,result,records,error) && MDCWSameRequest(result.request,state.outstanding) &&
      MDCWCurrentAccount(result.request) && result.request.parent_chart==ChartID() && result.request.currency==state.currency)
   {
      state.pending=false; state.first_check_complete=true; state.health_lost=false;
      return true;
   }
   if(!state.slow_reported && now-state.request_ms>=10000)
   {
      state.slow_reported=true; state.health_lost=true;
      Print("XAUscalper calendar worker slow | elapsed_ms=",now-state.request_ms," | protection_continues=true");
   }
   if(state.request_ms!=0 && now-state.request_ms>=90000) MDCWRestart(state,"CALENDAR_REQUEST_TIMEOUT");
   else if(now>=state.next_notify_ms) { MDCWNotify(state); state.next_notify_ms=now+60000; }
   return false;
}



















struct MDLotScalingConfig
{
   bool enabled,useEquity,onlyUp,persist;
   double baseBalance,balanceStep,lotStep,maxLot;
   string stateId;
};

struct MDConfiguration
{
   bool tester,optimization,goldSymbol,testerNonGoldMode,testerDailyOrHigher;
   bool strategyEnvironmentAllowed,fastBacktest,nettingAccount,newEntriesAllowed;
   bool timerEnabled,localLearningEnabled;
   int moduleCount,quickSetup,aiMode,sizingMode,effectiveSizingMode;
   bool enabled[9];
   MDStrategyConfig strategies[9];
   long currentBase;
   int previousBase,legacyBase;
   long qualityProbeMagic;
   double point,pipSize;
   int digits;
   double hardEntrySpreadPoints,primaryThreshold,consensusThreshold,primaryPenalty;
   bool adaptiveSizing;
   double adaptiveSizeThreshold,adaptiveBaseMultiplier,adaptiveBoostMultiplier;
   double fixedLot,customRiskPercent,maximumRiskLot;
   int maxSameDirectionPositions;
   bool lockEnabled,adaptiveLock,spikeShield,persistVirtual;
   int protectionMode;
   bool customBreakEvenTrailing;
   double breakEvenStart,breakEvenLock,trailingStart,trailingDistance,trailingStep;
   bool tradingHours,deleteOutsideHours;
   int startHour,startMinute,endHour,endMinute;
   bool wideSpreadProtection,deletePendingBeforeNews;
   double wideSpreadMaxPoints;
   MDWeekendConfig weekend;
   MDNormalDailyConfig normalDaily;
   MDPropConfig prop;
   MDNewsConfig news;
   MDLotScalingConfig lotScaling;
   string normalDailyId,challengeId,orderComment,calendarWorkerSession;
   bool appendModuleToComment,blankOrderComment;
};

bool MDConfigurationError(string &error,const string message)
{
   error="XAUscalper parameter error: "+message;
   return false;
}

bool MDIntegerInRange(const int value,const int minimum,const int maximum)
{
   return value>=minimum && value<=maximum;
}

// Native symbol classification uses these four literal substrings.
bool MDIsGoldSymbol(const string symbol)
{
   return StringFind(symbol,"XAU")>=0 || StringFind(symbol,"xau")>=0 ||
          StringFind(symbol,"GOLD")>=0 || StringFind(symbol,"gold")>=0;
}

bool MDValidateMagicConfiguration(const long currentBase,const int previousBase,
                                 const int legacyBase,const int quickSetup,
                                 const bool &enabled[],string &error)
{
   if(currentBase<1 || previousBase<0 || legacyBase<0)
      return MDConfigurationError(error,"current magic base must be positive and previous bases cannot be negative");
   long current[9],previous[5];
   for(int i=0;i<9;i++)
      current[i]=(i<5 || MDStrategyEnabled(i,quickSetup,enabled)) ? currentBase+i+1 : 0;
   for(int i=0;i<5;i++) previous[i]=previousBase>0 ? (long)previousBase+i+1 : 0;
   const long probe=currentBase+7777;
   for(int i=0;i<5;i++)
      if(previous[i]==probe)
         return MDConfigurationError(error,"a configured module magic collides with the internal quality-probe identity");
   for(int i=0;i<9;i++)
      for(int j=0;j<5;j++)
         if(current[i]>0 && previous[j]>0 && current[i]==previous[j])
            return MDConfigurationError(error,"current magic range collides with PreviousXSTradeIdentityBase");
   if(legacyBase>0)
   {
      const int offsets[5]={12,9,14,15,13};
      for(int k=0;k<5;k++)
      {
         const long oldMagic=(long)legacyBase+offsets[k];
         if(oldMagic==probe)
            return MDConfigurationError(error,"older-format magic collides with the internal quality-probe identity");
         for(int i=0;i<9;i++)
         {
            if(current[i]==oldMagic)
               return MDConfigurationError(error,"current magic range collides with a legacy XAUscalper identity");
            if(i<5 && previous[i]==oldMagic)
               return MDConfigurationError(error,"previous Magic Number range overlaps a legacy XAUscalper identity");
         }
      }
   }
   return true;
}

bool MDValidateInputConfiguration(string &error)
{
   error="";
   if(!MDIntegerInRange((int)XSLockProfile,0,3))
      return MDConfigurationError(error,"choose a valid ProfitLock profile");
   if(WideSpreadMaxPoints<=0 || !MathIsValidNumber(WideSpreadMaxPoints))
      return MDConfigurationError(error,"spread limit must be finite and positive");
   if(XSStopLossPips<=0 || !MathIsValidNumber(XSStopLossPips) || !MathIsValidNumber(XSStopLossPips*10.0))
      return MDConfigurationError(error,"Initial Stop Loss must be a finite positive number of gold pips");
   if(UseCustomBreakEvenTrailing &&
      (!(CustomBreakEvenStartPips>0) || !MathIsValidNumber(CustomBreakEvenStartPips) ||
       !(CustomBreakEvenLockPips>=0 && CustomBreakEvenLockPips<=CustomBreakEvenStartPips) ||
       !MathIsValidNumber(CustomBreakEvenLockPips) ||
       !(CustomTrailingStartPips>=CustomBreakEvenStartPips) || !MathIsValidNumber(CustomTrailingStartPips) ||
       !(CustomTrailingDistancePips>0) || !MathIsValidNumber(CustomTrailingDistancePips) ||
       !(CustomTrailingStepPips>0) || !MathIsValidNumber(CustomTrailingStepPips)))
      return MDConfigurationError(error,"custom break-even and trailing parameters are invalid");
   if(!MDIntegerInRange(TradingStartHour,0,23) || !MDIntegerInRange(TradingEndHour,0,23) ||
      !MDIntegerInRange(TradingStartMinute,0,59) || !MDIntegerInRange(TradingEndMinute,0,59))
      return MDConfigurationError(error,"trading hours must use 00:00 through 23:59 server time");
   if(!MDIntegerInRange(WeekendFridayCutoffMinutes,0,1440) || !MDIntegerInRange(WeekendReopenDelayMinutes,0,1440) ||
      !MDIntegerInRange(WeekendFallbackFridayHour,0,23) || !MDIntegerInRange(WeekendFallbackMondayHour,0,23) ||
      !MDIntegerInRange(WeekendCustomFridayHour,0,23) || !MDIntegerInRange(WeekendCustomMondayHour,0,23) ||
      !MDIntegerInRange(WeekendCustomFridayMinute,0,59) || !MDIntegerInRange(WeekendCustomMondayMinute,0,59))
      return MDConfigurationError(error,"weekend schedule parameters are invalid");
   if(LotScalingEnabled && LotScalingPersistState && StringLen(LotScalingStateId)==0)
      return MDConfigurationError(error,"LotScalingStateId cannot be empty when persistence is enabled");
   bool enabled[9];
   enabled[0]=XSEnableS1; enabled[1]=XSEnableS2; enabled[2]=XSEnableS3; enabled[3]=XSEnableS4;
   enabled[4]=XSEnableS5; enabled[5]=XSAddOnA; enabled[6]=XSAddOnB; enabled[7]=XSAddOnC; enabled[8]=XSAddOnD;
   if(!MDValidateMagicConfiguration(MagicNumber,PreviousXSTradeIdentityBase,
                                   PreviousXSTradeIdentity,(int)XSQuickSetup,enabled,error)) return false;
   if(!MDIntegerInRange(NFPMinutesBefore,0,1440) || !MDIntegerInRange(NFPMinutesAfter,0,1440) ||
      !MDIntegerInRange(CPIMinutesBefore,0,1440) || !MDIntegerInRange(CPIMinutesAfter,0,1440) ||
      !MDIntegerInRange(FOMCMinutesBefore,0,1440) || !MDIntegerInRange(FOMCMinutesAfter,0,1440) ||
      !MDIntegerInRange(NewsMinutesBefore,0,1440) || !MDIntegerInRange(NewsMinutesAfter,0,1440))
      return MDConfigurationError(error,"news windows must be 0 through 1440 minutes");
   if(XSLockStartPer001<0 || XSLockPercent<=0 || XSLockPercent>100)
      return MDConfigurationError(error,"ProfitLock start cannot be negative and protected percentage must be greater than 0 and no more than 100");
   if(!MDIntegerInRange((int)XSProtectionMode,0,2))
      return MDConfigurationError(error,"choose a valid protection mode");
   if(!MDIntegerInRange((int)LotMode,0,5))
      return MDConfigurationError(error,"choose a valid sizing mode");
   if(LotMode==MDSizing_Custom && !(RiskPercent>0 && RiskPercent<=100))
      return MDConfigurationError(error,"custom risk must be greater than zero and no more than 100 percent");
   if(MaximumRiskLot<0) return MDConfigurationError(error,"maximum risk lot cannot be negative");
   if(!MDIntegerInRange((int)AiTradingMode,0,2)) return MDConfigurationError(error,"choose a valid AI mode");
   if(!MDIntegerInRange((int)AdaptivePositionSize,0,1)) return MDConfigurationError(error,"choose a valid adaptive sizing mode");
   if(FixedLot<=0) return MDConfigurationError(error,"fixed lot must be greater than zero");
   if(XSTargetS2Pips<=0 || XSTargetS2Pips>1000 || XSCoreTargetPips<=0 || XSCoreTargetPips>1000)
      return MDConfigurationError(error,"target pips must be greater than zero and no more than 1000");
   if(PropFirmActive)
   {
      if(StringLen(PropFirmChallengeId)==0) return MDConfigurationError(error,"PropFirmChallengeId cannot be empty");
      if(!(PropFirmStartingBalance>=0)) return MDConfigurationError(error,"PropFirmStartingBalance cannot be negative");
      if(!(PropFirmProfitTargetPercent>=0 && (PropFirmProfitTargetPercent>0 || !PropFirmStopAtProfitTarget)))
         return MDConfigurationError(error,"an active profit target must be greater than zero");
      if(!(PropFirmMaxDailyLossPercent>0 && PropFirmMaxDailyLossPercent<100 &&
           PropFirmMaxTotalDrawdownPercent>0 && PropFirmMaxTotalDrawdownPercent<100))
         return MDConfigurationError(error,"prop-firm loss limits must be greater than 0 and below 100 percent");
      if(!(PropFirmSafetyBufferPercent>=0 && PropFirmSafetyBufferPercent<PropFirmMaxDailyLossPercent &&
           PropFirmSafetyBufferPercent<PropFirmMaxTotalDrawdownPercent))
         return MDConfigurationError(error,"safety buffer must be non-negative and below both loss limits");
      if(!MDIntegerInRange(PropFirmDailyResetHour,0,23) || !MDIntegerInRange(PropFirmDailyResetMinute,0,59))
         return MDConfigurationError(error,"prop-firm reset must use 00:00 through 23:59 server time");
      if(!MDIntegerInRange(PropFirmMaximumExposureSlots,0,60))
         return MDConfigurationError(error,"PropFirmMaximumExposureSlots must be 0 through 60");
   }
   else if(NormalDailyLimitEnabled)
   {
      if(!(NormalMaxDailyLossPercent>0 && NormalMaxDailyLossPercent<100))
         return MDConfigurationError(error,"normal daily loss limit must be greater than 0 and below 100 percent");
      if(StringLen(NormalDailyProtectionId)==0) return MDConfigurationError(error,"NormalDailyProtectionId cannot be empty");
   }
   if(!MDIntegerInRange(LaunchSplashSeconds,1,15)) return MDConfigurationError(error,"LaunchSplashSeconds must be 1 through 15");
   if(!MDIntegerInRange(ExecutionMinimumTrades,5,10000)) return MDConfigurationError(error,"ExecutionMinimumTrades must be between 5 and 10000");
   if(ExecutionExcellentMax<0 || ExecutionGoodMax<ExecutionExcellentMax || ExecutionNormalMax<ExecutionGoodMax ||
      ExecutionPoorMax<ExecutionNormalMax || ExecutionPoorMax>10)
      return MDConfigurationError(error,"execution thresholds must be ordered EXCELLENT <= GOOD <= NORMAL <= POOR and remain between 0.00 and 10.00");
   return true;
}

// Pure initialization bridge. Symbol/account values are captured by the event owner.
bool MDBuildConfiguration(const bool tester,const bool goldSymbol,const long marginMode,
                          const double point,const int digits,MDConfiguration &c,string &error,
                          const ENUM_TIMEFRAMES chartTimeframe=PERIOD_CURRENT,const bool optimization=false)
{
   ZeroMemory(c);
   if(!MDValidateInputConfiguration(error)) return false;
   c.tester=tester; c.optimization=optimization; c.goldSymbol=goldSymbol;
   c.testerNonGoldMode=tester && !goldSymbol;
   c.testerDailyOrHigher=tester && (int)chartTimeframe>=(int)PERIOD_D1;
   c.strategyEnvironmentAllowed=tester || goldSymbol;
   c.fastBacktest=FastBacktest && tester;
   c.nettingAccount=marginMode!=(long)ACCOUNT_MARGIN_MODE_RETAIL_HEDGING;
   c.newEntriesAllowed=!c.nettingAccount || AllowNettingAccount;
   c.timerEnabled=!c.testerNonGoldMode && !c.testerDailyOrHigher && (!tester || !c.fastBacktest);
   c.localLearningEnabled=!tester && !optimization && LocalLearningLogEnabled;
   c.moduleCount=c.testerNonGoldMode ? 1 : 9;
   c.quickSetup=(int)XSQuickSetup; c.aiMode=(int)AiTradingMode;
   c.sizingMode=(int)LotMode;
   c.effectiveSizingMode=c.sizingMode==5 ? (tester ? 2 : 0) : c.sizingMode;
   c.enabled[0]=XSEnableS1; c.enabled[1]=XSEnableS2; c.enabled[2]=XSEnableS3; c.enabled[3]=XSEnableS4;
   c.enabled[4]=XSEnableS5; c.enabled[5]=XSAddOnA; c.enabled[6]=XSAddOnB; c.enabled[7]=XSAddOnC; c.enabled[8]=XSAddOnD;
   c.currentBase=MagicNumber; c.previousBase=PreviousXSTradeIdentityBase; c.legacyBase=PreviousXSTradeIdentity;
   c.qualityProbeMagic=c.currentBase+7777;
   c.point=point; c.digits=digits; c.pipSize=point*((digits==3 || digits==5) ? 10.0 : 1.0);
   c.hardEntrySpreadPoints=200.0;
   c.primaryThreshold=0.53; c.consensusThreshold=0.53; c.primaryPenalty=0.25;
   c.adaptiveSizing=AdaptivePositionSize==MDAdaptive_Boost;
   c.adaptiveSizeThreshold=0.577811425; c.adaptiveBaseMultiplier=1.0; c.adaptiveBoostMultiplier=1.5;
   c.fixedLot=FixedLot; c.customRiskPercent=RiskPercent; c.maximumRiskLot=MaximumRiskLot;
   c.maxSameDirectionPositions=MaxSameDirectionPositions;
   c.lockEnabled=XSLockEnabled; c.adaptiveLock=(int)XSLockProfile>1; c.spikeShield=((int)XSLockProfile&1)!=0;
   c.persistVirtual=PersistVirtualTrailing; c.protectionMode=(int)XSProtectionMode;
   c.customBreakEvenTrailing=UseCustomBreakEvenTrailing;
   c.breakEvenStart=CustomBreakEvenStartPips*10.0; c.breakEvenLock=CustomBreakEvenLockPips*10.0;
   c.trailingStart=CustomTrailingStartPips*10.0; c.trailingDistance=CustomTrailingDistancePips*10.0;
   c.trailingStep=CustomTrailingStepPips*10.0;
   for(int i=0;i<9;i++)
      if(!MDLoadStrategyConfig(i,c.quickSetup,UsePerModuleTunedExits,XSStopLossPips,XSTargetS2Pips,
                              XSCoreTargetPips,XSLockStartPer001,XSLockPercent,
                              c.primaryThreshold,c.consensusThreshold,c.strategies[i]))
         return MDConfigurationError(error,"strategy configuration could not be initialized");
   c.tradingHours=UseTradingHours; c.deleteOutsideHours=DeletePendingOutsideHours;
   c.startHour=TradingStartHour; c.startMinute=TradingStartMinute; c.endHour=TradingEndHour; c.endMinute=TradingEndMinute;
   c.wideSpreadProtection=WideSpreadProtectionEnabled; c.wideSpreadMaxPoints=WideSpreadMaxPoints;
   c.deletePendingBeforeNews=DeletePendingBeforeNews;
   c.weekend.enabled=WeekendShieldEnabled; c.weekend.mode=(int)WeekendScheduleMode;
   c.weekend.cutoff_minutes=WeekendFridayCutoffMinutes; c.weekend.reopen_minutes=WeekendReopenDelayMinutes;
   c.weekend.fallback_friday_hour=WeekendFallbackFridayHour; c.weekend.fallback_monday_hour=WeekendFallbackMondayHour;
   c.weekend.friday_hour=WeekendCustomFridayHour; c.weekend.friday_minute=WeekendCustomFridayMinute;
   c.weekend.monday_hour=WeekendCustomMondayHour; c.weekend.monday_minute=WeekendCustomMondayMinute;
   c.normalDaily.enabled=NormalDailyLimitEnabled; c.normalDaily.prop_active=PropFirmActive;
   c.normalDaily.loss_percent=NormalMaxDailyLossPercent;
   c.normalDaily.close_positions=NormalDailyClosePositions; c.normalDaily.delete_pending=NormalDailyDeletePendings;
   c.normalDailyId=NormalDailyProtectionId;
   c.prop.enabled=PropFirmActive; c.challengeId=PropFirmChallengeId;
   c.prop.starting_balance=PropFirmStartingBalance; c.prop.target_percent=PropFirmProfitTargetPercent;
   c.prop.daily_loss_percent=PropFirmMaxDailyLossPercent; c.prop.total_loss_percent=PropFirmMaxTotalDrawdownPercent;
   c.prop.safety_percent=PropFirmSafetyBufferPercent; c.prop.stop_at_target=PropFirmStopAtProfitTarget;
   c.prop.delete_pending=PropFirmDeletePendingsWhenBlocked; c.prop.close_at_limit=PropFirmClosePositionsOnLimit;
   c.prop.close_at_target=PropFirmClosePositionsAtTarget; c.prop.drawdown_mode=(int)PropFirmDrawdownMode;
   c.prop.daily_baseline=(int)PropFirmDailyBaseline; c.prop.daily_amount=(int)PropFirmDailyLossAmount;
   c.prop.trailing_amount=(int)PropFirmTrailingAmount; c.prop.reset_hour=PropFirmDailyResetHour;
   c.prop.reset_minute=PropFirmDailyResetMinute; c.prop.max_slots=PropFirmMaximumExposureSlots;
   c.news.major_control=UseMajorEventControl; c.news.trade_nfp=TradeDuringNFP; c.news.trade_cpi=TradeDuringCPI; c.news.trade_fomc=TradeDuringFOMC;
   c.news.calendar_shield=XSCalendarShieldEnabled; c.news.filter_high=FilterHighImpactNews;
   c.news.filter_moderate=FilterModerateImpactNews; c.news.fail_closed=NewsFailClosed;
   c.news.nfp_before=NFPMinutesBefore; c.news.nfp_after=NFPMinutesAfter;
   c.news.cpi_before=CPIMinutesBefore; c.news.cpi_after=CPIMinutesAfter;
   c.news.fomc_before=FOMCMinutesBefore; c.news.fomc_after=FOMCMinutesAfter;
   c.news.news_before=NewsMinutesBefore; c.news.news_after=NewsMinutesAfter;
   c.news.official_backup=UseBuiltInMajorNewsBackup; c.news.currency=NewsCurrency;
   c.lotScaling.enabled=LotScalingEnabled; c.lotScaling.useEquity=LotScalingUseEquity;
   c.lotScaling.onlyUp=LotScalingOnlyUp; c.lotScaling.persist=LotScalingPersistState;
   c.lotScaling.baseBalance=LotScalingBaseBalance; c.lotScaling.balanceStep=LotScalingBalanceStep;
   c.lotScaling.lotStep=LotScalingLotStep; c.lotScaling.maxLot=LotScalingMaxLot; c.lotScaling.stateId=LotScalingStateId;
   c.orderComment=CommentText; c.appendModuleToComment=AppendModuleToComment;
   c.blankOrderComment=PropFirmBlankOrderComment; c.calendarWorkerSession="";
   return true;
}

void MDBuildProtectionConfiguration(const MDConfiguration &c,const MDStrategyConfig &strategy,
                                    const double tickValue,const double tickValueProfit,
                                    const double tickValueLoss,const double tickSize,
                                    XSProtectionConfig &out)
{
   ZeroMemory(out);
   out.lockEnabled=c.lockEnabled; out.adaptiveLock=c.adaptiveLock; out.spikeShield=c.spikeShield;
   out.protectionMode=c.protectionMode; out.lockStartPer001=strategy.lockStart; out.lockPercent=strategy.lockPercent;
   out.adaptiveThreshold=2.0; out.adaptiveLowPercent=35.0; out.adaptiveHighPercent=50.0;
   out.requiredConfirmQuotes=2; out.spreadTrigger=75.0; out.immediatePenetration=20.0;
   out.pipSize=c.pipSize; out.point=c.point; out.digits=c.digits;
   out.tickValue=tickValue; out.tickValueProfit=tickValueProfit; out.tickValueLoss=tickValueLoss; out.tickSize=tickSize;
}









enum XSPanelIntent
{
   MD_PANEL_NONE,
   MD_PANEL_CANCEL_AND_PAUSE,
   MD_PANEL_RESUME,
   MD_PANEL_CLOSE_TRADES,
   MD_PANEL_TOGGLE,
   MD_PANEL_EXECUTION,
   MD_PANEL_MAIN,
   MD_PANEL_RESIZE
};

struct XSPanelValue
{
   string label;
   string value;
   color ink;
};

struct XSPanelModule
{
   string name;
   string state;
   string net;
   color name_ink;
   color state_ink;
   color net_ink;
};

struct XSPanelDeal
{
   string closed;
   string module_side;
   string entry;
   string exit;
   string total;
   string grade;
   color total_ink;
   color grade_ink;
};

struct XSPanelPending
{
   ulong ticket;
   double price;
   double volume;
   bool buy_stop;
};

struct XSPanelSnapshot
{
   bool enabled;
   bool controls_enabled;
   bool dashboard_enabled;
   bool panel_visible;
   bool user_override;
   bool execution_enabled;
   bool execution_visible;
   bool splash_visible;
   double dashboard_scale;
   datetime server_time;
   bool entry_paused;
   bool pause_error;
   bool cancel_armed;
   bool close_armed;
   string close_tooltip;
   string toolbar_state;
   string toolbar_notice;
   string title;
   string subtitle;
   string entry_state;
   color entry_ink;
   XSPanelValue information[3];
   XSPanelModule modules[9];
   int module_count;
   string control_heading;
   string control_status;
   color control_ink;
   XSPanelValue metrics[4];
   string footer_mode;
   string footer_price;
   string footer_schedule;
   string execution_verdict;
   color execution_ink;
   XSPanelValue execution_cards[4];
   XSPanelDeal deals[10];
   XSPanelPending pending[];
   string execution_footnote;
   double drawdown_percent;
   double live_pnl;
   string license_text;
   color license_ink;
   string account_text;
   string activity_text;
   color activity_ink;
   bool license_valid;
   bool portal_connected;
   bool hide_link;
   string owner_text;
   string status_text;
   color status_ink;
   color account_ink;
   string overall_text;
   color overall_ink;
   string float_text;
   color float_ink;
   string today_text;
   color today_ink;
};

struct XSPanelGeometry
{
   int x,y,width,height,toolbar_y,toolbar_width,toolbar_height,columns,dpi;
   int execution_x,execution_width,execution_height;
   bool rich,side_by_side;
   double scale,exec_scale;
};

struct XSPanelCache
{
   string name;
   string signature;
   uint seen;
};

XSPanelCache md_panel_cache[];
uint md_panel_epoch=0;
int md_panel_dpi=96;
double md_panel_scale=1.0;

int XSPanelRound(const double value) { return (int)MathRound(value); }

string XSPanelSignedNumber(const double value,const int digits)
{
   return (value>=0.0 ? "+" : "")+DoubleToString(value,digits);
}

string XSPanelPropCaption(const bool enabled,const bool ready,const bool total_blocked,
                              const bool daily_blocked,const bool stop_at_target,
                              const bool target_reached,const int max_slots,const int occupied_slots)
{
   if(!enabled) return "OFF";
   if(!ready) return "STATE ERROR";
   if(total_blocked) return "TOTAL LIMIT";
   if(daily_blocked) return "DAILY LIMIT";
   if(stop_at_target && target_reached) return "TARGET REACHED";
   if(max_slots>0 && occupied_slots>=max_slots) return "CAPACITY";
   return "ACTIVE";
}

string XSPanelDailyCaption(const bool enabled,const bool prop_active,const bool ready,
                               const bool blocked,const double reference,const double equity,
                               const double loss_percent)
{
   if(!enabled || prop_active) return "OFF";
   if(!ready) return "STATE ERROR";
   if(blocked) return "DAILY LIMIT";
   double drawdown=reference>0.0 ? MathMax(0.0,(reference-equity)*100.0/reference) : 0.0;
   return DoubleToString(drawdown,1)+"% / "+DoubleToString(loss_percent,1)+"%";
}

string XSPanelWeekTime(const long seconds)
{
   string days[7]={"SUN","MON","TUE","WED","THU","FRI","SAT"};
   long week=seconds%604800;
   if(week<0) week+=604800;
   int daytime=(int)(week%86400);
   return days[(int)(week/86400)]+StringFormat(" %02d:%02d",daytime/3600,daytime%3600/60);
}

string XSPanelWeekendCaption(const bool enabled,const bool blocked,const datetime now,
                                 const datetime next_change,const long cutoff,const long resume)
{
   if(!enabled) return "WEEKEND SHIELD OFF";
   if(now<=0 || next_change<=0) return "WEEKEND SCHEDULE WAITING";
   long remaining=(long)next_change-(long)now;
   if(remaining<0) remaining=0;
   string countdown=StringFormat("%02dH %02dM",(int)(remaining%86400/3600),(int)(remaining%3600/60));
   if(remaining>=86400) countdown=IntegerToString(remaining/86400)+"D "+countdown;
   return (blocked ? "ENTRIES RESUME " : "PENDINGS OFF ")+
          XSPanelWeekTime(blocked ? resume : cutoff)+" // IN "+countdown;
}

string XSPanelSizingCaption(const int mode,const bool tester,const double fixed_lot,
                                const double custom_percent)
{
   switch(mode)
   {
      case 1: return "RISK 1.00%";
      case 2: return "RISK 2.00%";
      case 3: return "RISK "+DoubleToString(custom_percent,2)+"%";
      case 4: return "GROWTH 1% / MIN 0.01";
      case 5: return tester ? "AUTO BT / RISK 2%" : "AUTO LIVE / FIXED "+DoubleToString(fixed_lot,2);
   }
   return "FIXED "+DoubleToString(fixed_lot,2)+" LOT";
}

string XSPanelModuleState(const bool enabled,const int positions,const int pending,
                              const bool entries_allowed)
{
   if(!enabled) return "OFF";
   if(positions>0) return "POSITION "+IntegerToString(positions);
   if(pending>0) return "PENDING "+IntegerToString(pending);
   return entries_allowed ? "SCANNING" : "PAUSED";
}

int XSPanelTouch(const string name,const string signature,const ENUM_OBJECT type)
{
   int count=ArraySize(md_panel_cache),slot=-1;
   for(int i=0;i<count;++i) if(md_panel_cache[i].name==name) { slot=i; break; }
   if(slot<0)
   {
      slot=count;
      if(ArrayResize(md_panel_cache,count+1)!=count+1) return -1;
      md_panel_cache[slot].name=name; md_panel_cache[slot].signature="";
   }
   md_panel_cache[slot].seen=md_panel_epoch;
   if(md_panel_cache[slot].signature==signature) return -1;
   if(ObjectFind(0,name)<0 && !ObjectCreate(0,name,type,0,0,0)) return -1;
   md_panel_cache[slot].signature=signature;
   return slot;
}

void XSPanelPlace(const string name,const int x,const int y,const long z)
{
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,z);
}

void XSPanelRectangle(const string suffix,const int x,const int y,const int width,
                           const int height,const color fill,const color border)
{
   string name="MD_RICH_"+suffix;
   string key=StringFormat("R|%d|%d|%d|%d|%u|%u",x,y,width,height,fill,border);
   if(XSPanelTouch(name,key,OBJ_RECTANGLE_LABEL)<0) return;
   XSPanelPlace(name,x,y,500);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,width); ObjectSetInteger(0,name,OBJPROP_YSIZE,height);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,fill); ObjectSetInteger(0,name,OBJPROP_COLOR,border);
   ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT); ObjectSetInteger(0,name,OBJPROP_BACK,false);
}

string XSPanelFitText(const string text,const string font,const int font_size,const int width)
{
   uint measured_width=0,measured_height=0;
   if(width<=0 || !TextSetFont(font,-10*font_size) ||
      !TextGetSize(text,measured_width,measured_height) || (int)measured_width<=width) return text;
   string best="";
   int low=0,high=StringLen(text);
   while(low<=high)
   {
      int middle=(low+high)/2;
      string candidate=StringSubstr(text,0,middle)+"...";
      if(!TextGetSize(candidate,measured_width,measured_height)) break;
      if((int)measured_width<=width) { best=candidate; low=middle+1; }
      else high=middle-1;
   }
   return best;
}

void XSPanelLabelPart(const string suffix,const string caption,const string tooltip,
                          const int x,const int y,const int font_size,const color ink,
                          const string font,const bool right)
{
   string name="MD_RICH_"+suffix;
   string key=StringFormat("L|%d|%d|%d|%u|%d|",x,y,font_size,ink,(int)right)+font+caption+tooltip;
   int slot=XSPanelTouch(name,key,OBJ_LABEL);
   if(slot<0) return;
   XSPanelPlace(name,x,y,520);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,right ? ANCHOR_RIGHT_UPPER : ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,font_size); ObjectSetInteger(0,name,OBJPROP_COLOR,ink);
   ObjectSetString(0,name,OBJPROP_FONT,font);
   bool written=ObjectSetString(0,name,OBJPROP_TEXT,caption);
   if(!written)
   {
      ObjectDelete(0,name); md_panel_cache[slot].signature=""; return;
   }
   ObjectSetString(0,name,OBJPROP_TOOLTIP,tooltip);
}

void XSPanelLabel(const string suffix,const string text,const int x,const int y,
                      const int size,const color ink,const int width,
                      const bool bold=false,const bool right=false)
{
   int font_size=MathMax(1,XSPanelRound(MathMax(6,size)*96.0/md_panel_dpi));
   string font=(bold ? "Bahnschrift SemiBold" : "Segoe UI Semibold");
   string fitted=XSPanelFitText(text,font,font_size,width);
   int length=StringLen(fitted);
   if(length==0) return;
   if(length<=63)
   {
      XSPanelLabelPart(suffix,fitted,text,x,y,font_size,ink,font,right);
      return;
   }
   uint full_width=0,full_height=0;
   if(!TextSetFont(font,-10*font_size) || !TextGetSize(fitted,full_width,full_height))
   {
      XSPanelLabelPart(suffix,StringSubstr(fitted,0,60)+"...",text,x,y,font_size,ink,font,right);
      return;
   }
   int left=(right ? x-(int)full_width : x),offset=0,part=0;
   while(offset<length)
   {
      int count=MathMin(63,length-offset);
      if(offset+count<length)
         for(int split=count-1;split>0;--split)
            if(StringGetCharacter(fitted,offset+split)==32) { count=split+1; break; }
      uint prefix_width=0,prefix_height=0;
      if(offset>0 && !TextGetSize(StringSubstr(fitted,0,offset),prefix_width,prefix_height)) break;
      string part_suffix=(part==0 ? suffix : suffix+"TextPart"+IntegerToString(part));
      string caption=StringSubstr(fitted,offset,count);
      XSPanelLabelPart(part_suffix,caption,text,left+(int)prefix_width,y,font_size,ink,font,false);
      offset+=count; ++part;
   }
}

void XSPanelButton(const string name,const string text,const string tooltip,const int x,const int y,
                       const int width,const color ink,const color border,const int height=30)
{
   string key=StringFormat("C|%d|%d|%d|%d|%u|%u|%d|",x,y,width,height,ink,border,md_panel_dpi)+text+tooltip;
   if(XSPanelTouch(name,key,OBJ_BUTTON)<0) return;
   XSPanelPlace(name,x,y,30000);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,width); ObjectSetInteger(0,name,OBJPROP_YSIZE,height);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,XS_TILE); ObjectSetInteger(0,name,OBJPROP_COLOR,ink);
   ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,border); ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,name,OBJPROP_STATE,false);
   int font=MathMax(6,XSPanelRound(864.0/md_panel_dpi));
   int minimum=MathMax(1,(int)MathFloor(576.0/md_panel_dpi));
   string caption=(StringLen(text)>63 ? StringSubstr(text,0,60)+"..." : text);
   uint w=0,h=0;
   int room=MathMax(20,width)-14;
   for(;font>minimum;--font)
   {
      if(!TextSetFont("Segoe UI Semibold",-10*font) || !TextGetSize(caption,w,h)) break;
      if((int)w<=room && h<25) break;
   }
   if(!TextSetFont("Segoe UI Semibold",-10*font) || !TextGetSize(caption,w,h) || h>24) caption="";
   else if((int)w>room) caption=XSPanelFitText(caption,"Segoe UI Semibold",font,room);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,font);
   ObjectSetString(0,name,OBJPROP_FONT,"Segoe UI Semibold");
   ObjectSetString(0,name,OBJPROP_TEXT,caption); ObjectSetString(0,name,OBJPROP_TOOLTIP,tooltip);
}

void XSPanelSweep()
{
   for(int i=ArraySize(md_panel_cache)-1;i>=0;--i)
      if(md_panel_cache[i].seen!=md_panel_epoch)
      {
         ObjectDelete(0,md_panel_cache[i].name);
         int last=ArraySize(md_panel_cache)-1;
         if(i!=last) md_panel_cache[i]=md_panel_cache[last];
         ArrayResize(md_panel_cache,last);
      }
}

void XSPanelInvalidate()
{
   for(int i=0;i<ArraySize(md_panel_cache);++i) md_panel_cache[i].signature="";
}


XSPanelIntent XSPanelCommand(const int event_id,const string object_name)
{
   if(event_id==CHARTEVENT_CHART_CHANGE) { XSPanelInvalidate(); return MD_PANEL_RESIZE; }
   if(event_id!=CHARTEVENT_OBJECT_CLICK) return MD_PANEL_NONE;
   XSPanelIntent intent=MD_PANEL_NONE;
   if(object_name=="MDCTL_CANCEL") intent=MD_PANEL_CANCEL_AND_PAUSE;
   else if(object_name=="MDCTL_RESUME") intent=MD_PANEL_RESUME;
   else if(object_name=="MDCTL_CLOSE") intent=MD_PANEL_CLOSE_TRADES;
   else if(object_name=="MD_PANEL_TOGGLE") intent=MD_PANEL_TOGGLE;
   else if(object_name=="MD_PAGE_EXECUTION") intent=MD_PANEL_EXECUTION;
   else if(object_name=="MD_PAGE_MAIN") intent=MD_PANEL_MAIN;
   if(intent!=MD_PANEL_NONE)
   {
      ObjectSetInteger(0,object_name,OBJPROP_STATE,false);
      XSPanelInvalidate();
   }
   return intent;
}

void XSPanelDefaults(XSPanelSnapshot &state)
{
   ZeroMemory(state);
   state.title="XAUSCALPER";
   state.dashboard_scale=1.0;
   state.entry_state="STARTING";
   state.entry_ink=XS_AMBER;
   state.control_ink=XS_CYAN;
   state.execution_ink=XS_MUTED;
   state.execution_verdict="HISTORY NOT READY";
   state.control_heading="BROKER TIME WAITING";
   state.license_text="LICENSE CHECK PENDING";
   state.license_ink=XS_AMBER;
   state.account_text="";
   state.activity_text="Starting up"; state.activity_ink=XS_AMBER;
   state.account_ink=XS_MUTED; state.status_ink=XS_MUTED; state.overall_ink=XS_TEXT;
   state.float_ink=XS_MUTED; state.today_ink=XS_MUTED; state.owner_text="--"; state.status_text="--"; state.overall_text="--";
   state.information[0].label="REALIZED NET";
   state.information[1].label="DAILY SHIELD";
   state.information[2].label="SPREAD / LIMIT";
   string labels[4]={"BALANCE","EQUITY","LIVE P/L","LIVE DD"};
   for(int i=0;i<4;++i)
   {
      state.metrics[i].label=labels[i]; state.metrics[i].value="--";
      state.metrics[i].ink=XS_MUTED;
      state.execution_cards[i].value="N/D"; state.execution_cards[i].ink=XS_MUTED;
   }
   for(int i=0;i<3;++i) { state.information[i].value="--"; state.information[i].ink=XS_TEXT; }
   for(int i=0;i<9;++i)
   {
      state.modules[i].name_ink=XS_TEXT;
      state.modules[i].state_ink=XS_MUTED;
      state.modules[i].net_ink=XS_MUTED;
   }
   for(int i=0;i<10;++i)
   {
      state.deals[i].total_ink=XS_MUTED;
      state.deals[i].grade_ink=XS_MUTED;
   }
}

string XSPanelSpikeCaption(const bool lock_enabled,const bool spike_enabled,
                           const int protection_mode,const int first_confirmation,
                           const int confirmation_ticks)
{
   if(!lock_enabled) return "SPIKE SHIELD // PROFIT LOCK OFF";
   if(!spike_enabled) return "SPIKE SHIELD // OFF";
   if(protection_mode!=2) return "SPIKE SHIELD // NEEDS VIRTUAL ONLY";
   if(first_confirmation>0)
      return "SPIKE SHIELD // CONFIRMING "+IntegerToString(first_confirmation)+"/"+
             IntegerToString((uint)confirmation_ticks*2);
   return "SPIKE SHIELD // ACTIVE";
}

string XSPanelModelState(const int mode,const bool models_ready,const bool entries_allowed)
{
   if(mode!=1 && mode!=2) return "BASE // FILTER OFF";
   if(!models_ready) return "AI // NOT READY";
   return entries_allowed ? "AI // ACTIVE" : "AI // ENTRY PAUSED";
}

string XSPanelModeCaption(const int mode)
{
   return mode==0 ? "BASE // FILTER OFF" : mode==2 ? "AI / MORE TRADES" : "AI / CONSERVATIVE";
}

int XSPanelMainHeight(const XSPanelSnapshot &state,const double s)
{
   return XSPanelRound(272.0*s);
}

int XSPanelTextWidth(const string text,const string font,const int font_size)
{
   uint w=0,h=0;
   if(!TextSetFont(font,-10*font_size) || !TextGetSize(text,w,h)) return 0;
   return (int)w;
}

XSPanelGeometry XSPanelMeasure(const XSPanelSnapshot &state)
{
   XSPanelGeometry g={};
   int chart_width=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS);
   int chart_height=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS);
   g.dpi=MathMax(96,(int)TerminalInfoInteger(TERMINAL_SCREEN_DPI));
   g.x=(chart_width>=48 ? 12 : 0); g.y=(chart_height>=48 ? 12 : 0);
   int available=MathMax(1,chart_width-2*g.x);
   int rows=0;
   double scale=MathMax(0.75,MathMin(1.5,state.dashboard_scale));
   double fit=(double)(chart_height-g.y-130)/272.0;
   if(fit<scale) scale=MathMax(0.6,fit);
   g.width=XSPanelRound(280.0*scale);
   if(g.width>available) { g.width=available; scale=(double)available/280.0; }
   g.scale=scale;
   g.height=XSPanelMainHeight(state,g.scale);
   g.rich=state.panel_visible && (state.dashboard_enabled || state.user_override) && g.width>=220;
   g.toolbar_width=(g.rich ? g.width : MathMin(available,700));
   g.columns=(g.toolbar_width>=440 ? 3 : g.toolbar_width>=300 ? 2 : 1);
   int toolbar_rows=(g.columns+2)/g.columns;
   g.toolbar_height=toolbar_rows*34+56;
   g.execution_width=XSPanelRound(520.0*g.scale);
   g.exec_scale=g.scale;
   if(g.execution_width>available) { g.execution_width=available; g.exec_scale=(double)available/520.0; }
   g.execution_height=XSPanelRound(412.0*g.exec_scale);
   g.side_by_side=g.rich && state.execution_enabled && state.execution_visible &&
                  g.x+12+g.width+12+g.execution_width<=chart_width;
   g.execution_x=(g.side_by_side ? g.x+g.width+12 : g.x);
   int shown=g.height;
   if(g.rich && state.execution_enabled && state.execution_visible)
      shown=(g.side_by_side ? MathMax(g.height,g.execution_height) : g.execution_height);
   g.toolbar_y=(g.rich ? g.y+8+shown : MathMin(g.y,MathMax(0,chart_height-toolbar_rows*34-60)));
   return g;
}

void XSPanelTile(const string n,const int x,const int y,const int w,const int h,const color accent,const color fill)
{
   XSPanelRectangle(n,x,y,w,h,fill,XS_EDGE);
   XSPanelRectangle(n+"A",x,y,XSPanelRound(4*md_panel_scale),h,accent,accent);
}

string XSPanelHeadline(const XSPanelSnapshot &state)
{
   string s=state.status_text;
   if(s=="ACTIVE") return "LICENSE ACTIVE";
   if(s=="NOT VALID") return "LICENSE NOT VALID";
   if(s=="EXPIRED") return "LICENSE EXPIRED";
   if(s=="NO LICENSE") return "NO LICENSE KEY";
   if(s=="NOT ALLOWED") return "WRONG ACCOUNT";
   if(s=="--") return "CHECKING LICENSE";
   if(s=="BACKTEST") return "BACKTEST MODE";
   return s;
}

void XSPanelMain(const XSPanelSnapshot &state,const XSPanelGeometry &g)
{
   double s=g.scale;
   md_panel_scale=s;
   int W=g.width,X=g.x,Y=g.y,pad=XSPanelRound(12*s);
   int inner=W-2*pad,tx=X+pad+XSPanelRound(14*s),tw=inner-XSPanelRound(22*s);
   XSPanelRectangle("MainShadow",X+4,Y+5,W,g.height,XS_SHADOW,XS_SHADOW);
   XSPanelRectangle("MainBase",X,Y,W,g.height,XS_PANEL,XS_EDGE);
   XSPanelRectangle("MainTop",X,Y,W,XSPanelRound(3*s),XS_GOLD,XS_GOLD);
   int fs=MathMax(1,XSPanelRound(18*96.0/md_panel_dpi));
   int xau=XSPanelTextWidth("XAU","Bahnschrift SemiBold",fs);
   XSPanelLabel("TitleA","XAU",X+pad,Y+XSPanelRound(12*s),18,XS_GOLD,W/2,true);
   XSPanelLabel("TitleB","SCALPER",X+pad+xau+3,Y+XSPanelRound(12*s),18,XS_TEXT,W/2,true);

   int y=Y+XSPanelRound(44*s),h=XSPanelRound(40*s);
   XSPanelTile("Act",X+pad,y,inner,h,state.activity_ink,XS_TILE2);
   XSPanelLabel("ActL","WHAT THE EA IS DOING",tx,y+XSPanelRound(5*s),7,XS_MUTED,tw);
   XSPanelLabel("ActV",state.activity_text,tx,y+XSPanelRound(19*s),9,state.activity_ink,tw,true);

   color lic=state.status_ink;
   y=Y+XSPanelRound(90*s); h=XSPanelRound(46*s);
   XSPanelTile("Lic",X+pad,y,inner,h,lic,XS_TILE);
   XSPanelLabel("LicHead",XSPanelHeadline(state),tx,y+XSPanelRound(6*s),11,lic,tw-XSPanelRound(96*s),true);
   color link=(state.portal_connected ? XS_GREEN : XS_RED);
   if(!state.hide_link)
   {
      XSPanelRectangle("LicLink",X+W-pad-XSPanelRound(98*s),y+XSPanelRound(9*s),XSPanelRound(7*s),XSPanelRound(7*s),link,link);
      XSPanelLabel("LicLinkT",(state.portal_connected ? "CONNECTED" : "NOT CONNECTED"),X+W-pad-XSPanelRound(8*s),y+XSPanelRound(7*s),7,link,XSPanelRound(84*s),true,true);
   }
   XSPanelLabel("LicText",state.license_text,tx,y+XSPanelRound(28*s),7,XS_MUTED,tw);

   y=Y+XSPanelRound(142*s); h=XSPanelRound(38*s);
   XSPanelTile("Own",X+pad,y,inner,h,XS_CYAN,XS_TILE2);
   XSPanelLabel("OwnL","LICENSE OWNER",tx,y+XSPanelRound(5*s),7,XS_MUTED,tw);
   XSPanelLabel("OwnV",state.owner_text,tx,y+XSPanelRound(18*s),10,XS_TEXT,tw,true);

   y=Y+XSPanelRound(186*s);
   XSPanelTile("Acc",X+pad,y,inner,h,state.account_ink,XS_TILE);
   XSPanelLabel("AccL","ACCOUNT",tx,y+XSPanelRound(5*s),7,XS_MUTED,tw);
   XSPanelLabel("AccV",state.account_text,tx,y+XSPanelRound(18*s),9,state.account_ink,tw,true);

   y=Y+XSPanelRound(230*s); h=XSPanelRound(34*s);
   XSPanelTile("Pnl",X+pad,y,inner,h,state.overall_ink,XS_TILE2);
   XSPanelLabel("PnlL","OVERALL P/L",tx,y+XSPanelRound(11*s),7,XS_MUTED,XSPanelRound(80*s));
   XSPanelLabel("PnlV",state.overall_text,X+W-pad-XSPanelRound(8*s),y+XSPanelRound(8*s),11,state.overall_ink,XSPanelRound(150*s),true,true);
}

void XSPanelCorner(const string name,const string text,const int ypos,const color ink)
{
   if(StringLen(text)==0) return;
   string key=StringFormat("CR|%d|%u|",ypos,ink)+text;
   if(XSPanelTouch(name,key,OBJ_LABEL)<0) return;
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_RIGHT_LOWER);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_RIGHT_LOWER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,14);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,ypos);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,9);
   ObjectSetString(0,name,OBJPROP_FONT,"Segoe UI Semibold");
   ObjectSetInteger(0,name,OBJPROP_COLOR,ink);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,520);
}

void XSPanelExecution(const XSPanelSnapshot &state,const XSPanelGeometry &g)
{
   double s=g.exec_scale;
   int X=g.execution_x,Y=g.y,W=g.execution_width,pad=XSPanelRound(16*s),room=W-2*pad;
   XSPanelRectangle("ExecShadow",X+4,Y+5,W,g.execution_height,XS_SHADOW,XS_SHADOW);
   XSPanelRectangle("ExecBase",X,Y,W,g.execution_height,XS_PANEL,XS_EDGE);
   XSPanelRectangle("ExecTop",X,Y,W,XSPanelRound(3*s),XS_CYAN,XS_CYAN);
   XSPanelLabel("ExecTitle","EXECUTION LAB // LAST 10 CLOSED TRADES",X+pad,Y+XSPanelRound(14*s),10,XS_CYAN,room,true);
   XSPanelLabel("ExecVerdict",state.execution_verdict,X+pad,Y+XSPanelRound(38*s),9,state.execution_ink,room,true);
   XSPanelLabel("ExecPurpose","SLIPPAGE CHECK // ARE THE FILLS GOOD ENOUGH?",X+pad,Y+XSPanelRound(56*s),7,XS_MUTED,room);
   int cgap=XSPanelRound(8*s),cw=(room-3*cgap)/4,cy=Y+XSPanelRound(80*s),chh=XSPanelRound(48*s);
   for(int i=0;i<4;++i)
   {
      string n="ExecCard"+IntegerToString(i);
      int lx=X+pad+i*(cw+cgap);
      XSPanelRectangle(n,lx,cy,cw,chh,(i%2==0 ? XS_TILE : XS_TILE2),XS_EDGE);
      XSPanelLabel(n+"L",state.execution_cards[i].label,lx+XSPanelRound(8*s),cy+XSPanelRound(6*s),7,XS_MUTED,cw-XSPanelRound(12*s));
      XSPanelLabel(n+"V",state.execution_cards[i].value,lx+XSPanelRound(8*s),cy+XSPanelRound(24*s),9,
                   state.execution_cards[i].ink,cw-XSPanelRound(12*s),true);
   }
   int left_x[2]={16,112};
   int left_w[2]={92,150};
   int right_x[4]={330,396,462,504};
   int right_w[4]={60,60,66,76};
   string heads[6]={"# CLOSED","MODULE / SIDE","ENTRY","EXIT","TOTAL","GRADE"};
   int hy=Y+XSPanelRound(140*s);
   for(int c=0;c<6;++c)
   {
      int px=(c<2 ? left_x[c] : right_x[c-2]),pw=(c<2 ? left_w[c] : right_w[c-2]);
      XSPanelLabel("LedgerH"+IntegerToString(c),heads[c],X+XSPanelRound(px*s),hy,7,XS_MUTED,XSPanelRound(pw*s),false,c>=2);
   }
   for(int row=0;row<10;++row)
   {
      string values[6];
      values[0]=state.deals[row].closed; values[1]=state.deals[row].module_side;
      values[2]=state.deals[row].entry; values[3]=state.deals[row].exit;
      values[4]=state.deals[row].total; values[5]=state.deals[row].grade;
      int top=Y+XSPanelRound((160+22*row)*s);
      if(row%2==0) XSPanelRectangle("DealBand"+IntegerToString(row),X+pad,top-XSPanelRound(2*s),room,XSPanelRound(21*s),XS_TILE,XS_TILE);
      for(int c=0;c<6;++c)
      {
         color ink=(c==4 ? state.deals[row].total_ink : c==5 ? state.deals[row].grade_ink :
                    c==0 ? XS_MUTED : c==1 ? XS_CYAN : XS_TEXT);
         int px=(c<2 ? left_x[c] : right_x[c-2]),pw=(c<2 ? left_w[c] : right_w[c-2]);
         XSPanelLabel("Deal"+IntegerToString(row)+"_"+IntegerToString(c),values[c],X+XSPanelRound(px*s),top,8,ink,
                      XSPanelRound(pw*s),false,c>=2);
      }
   }
   XSPanelLabel("ExecFoot",state.execution_footnote,X+pad,Y+XSPanelRound(388*s),7,XS_MUTED,room);
}

void XSPanelToolbar(const XSPanelSnapshot &state,const XSPanelGeometry &g)
{
   if(!state.controls_enabled) return;
   int x=g.x,y=g.toolbar_y,width=g.toolbar_width;
   XSPanelRectangle("Toolbar",x,y,width,g.toolbar_height,XS_PANEL,XS_EDGE);
   XSPanelRectangle("ToolbarLine",x,y,width,2,XS_GOLD,XS_GOLD);
   int half=MathMax(36,(width-24)/2),page_width=MathMin(112,half),toggle_width=MathMin(80,half);
   bool showing=state.panel_visible && (state.dashboard_enabled || state.user_override);
   string toolbar_state=state.toolbar_state;
   if(StringLen(toolbar_state)==0) toolbar_state=(state.pause_error ? "PAUSE STATE ERROR" :
                                        state.entry_paused ? "ENTRY PAUSE: ON" : "ENTRY PAUSE: OFF");
   if(!showing) toolbar_state="XAUSCALPER // "+toolbar_state;
   if(width>=300)
      XSPanelLabel("ToolbarState",toolbar_state,x+10,y+9,8,
                   state.entry_paused ? XS_AMBER : XS_MUTED,width-page_width-toggle_width-30);
   string page=(state.execution_visible ? (g.side_by_side ? "Close slippage" : "Back to main") : "Slippage");
   string page_name=(state.execution_visible && !g.side_by_side ? "MD_PAGE_MAIN" : "MD_PAGE_EXECUTION");
   XSPanelButton(page_name,page,"Show or hide the slippage view only. Execution tracking continues while this view is closed.",
                 x+width-page_width-toggle_width-16,y+6,page_width,
                 state.execution_enabled ? XS_CYAN : XS_MUTED,XS_EDGE,24);
   XSPanelButton("MD_PANEL_TOGGLE",showing ? "Hide panel" : "Show panel",
                 "Changes graphics only. Entry settings, pending management and position protection stay unchanged.",
                 x+width-toggle_width-8,y+6,toggle_width,XS_GOLD,XS_EDGE,24);
   int button_width=(width-8-g.columns*8)/g.columns;
   XSPanelButton("MDCTL_CANCEL",state.cancel_armed ? "Confirm cancel + pause" : "Cancel + pause",
                 "Two clicks within 5 seconds. Cancel current pending orders and pause new entries; open positions remain protected.",
                 x+8,y+36,button_width,XS_GOLD,XS_EDGE);
   XSPanelButton("MDCTL_RESUME","Resume entries",
                 "Resume only after pending cleanup is complete. Existing positions and all risk guards remain active.",
                 x+8+(g.columns>1 ? button_width+8 : 0),y+(g.columns>1 ? 36 : 70),button_width,
                 state.entry_paused ? XS_GREEN : XS_MUTED,XS_EDGE);
   string tooltip=state.close_tooltip;
   if(StringLen(tooltip)==0) tooltip="Two clicks within 5 seconds. Close this EA's positions on this symbol. Pending orders and the entry pause are unchanged. ";
   XSPanelButton("MDCTL_CLOSE",state.close_armed ? "Confirm close" : "Close trades",tooltip,
                 x+8+(g.columns==3 ? 2*(button_width+8) : 0),
                 y+(g.columns==3 ? 36 : g.columns==2 ? 70 : 104),button_width,XS_RED,XS_EDGE);
   string notice=state.toolbar_notice;
   if(StringLen(notice)==0) notice="Open positions stay protected. Close trades leaves pending orders unchanged.";
   XSPanelLabel("ToolbarNotice",notice,x+10,y+g.toolbar_height-17,7,XS_MUTED,width-20);
}

void XSPanelPendingLines(const XSPanelSnapshot &state,const XSPanelGeometry &g)
{
   int left=0;
   if(g.rich) left=g.x+g.width+(g.side_by_side ? g.execution_width+12 : 0)+16;
   int top=XSPanelRound(g.scale*80.0),subwindow=0;
   datetime start=0; double unused_price=0;
   if(!ChartXYToTimePrice(0,left,top,subwindow,start,unused_price)) start=state.server_time;
   int period_seconds=PeriodSeconds(_Period);
   datetime end=start+(period_seconds>0 ? 12*period_seconds : 720);
   for(int i=0;i<ArraySize(state.pending);++i)
   {
      if(state.pending[i].ticket==0 || state.pending[i].price<=0 || state.pending[i].volume<=0) continue;
      string name="XSP_LINE_"+IntegerToString((long)state.pending[i].ticket);
      color ink=(state.pending[i].buy_stop ? XS_GREEN : XS_RED);
      string key=StringFormat("P|%I64d|%I64d|%.16g|%u",start,end,state.pending[i].price,ink);
      if(XSPanelTouch(name,key,OBJ_TREND)<0) continue;
      ObjectMove(0,name,0,start,state.pending[i].price); ObjectMove(0,name,1,end,state.pending[i].price);
      ObjectSetInteger(0,name,OBJPROP_COLOR,ink); ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_DASH);
      ObjectSetInteger(0,name,OBJPROP_WIDTH,2); ObjectSetInteger(0,name,OBJPROP_BACK,false);
      ObjectSetInteger(0,name,OBJPROP_RAY_LEFT,false); ObjectSetInteger(0,name,OBJPROP_RAY_RIGHT,true);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false); ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,name,OBJPROP_ZORDER,100);
   }
}

void XSPanelSplashLabel(const string name,const string text,const int x,const int y,const int font_size,
                        const color ink,const string font)
{
   string key=StringFormat("SL|%d|%d|%d|%u|",x,y,font_size,ink)+font+text;
   if(XSPanelTouch(name,key,OBJ_LABEL)<0) return;
   XSPanelPlace(name,x,y,10000);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,font_size); ObjectSetInteger(0,name,OBJPROP_COLOR,ink);
   ObjectSetString(0,name,OBJPROP_FONT,font);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
}

void XSPanelSplash()
{
   int width=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS);
   int height=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS);
   string back="XS_SPLASH_BACK";
   if(XSPanelTouch(back,StringFormat("S|%d|%d",width,height),OBJ_RECTANGLE_LABEL)>=0)
   {
      XSPanelPlace(back,0,0,9900);
      ObjectSetInteger(0,back,OBJPROP_XSIZE,width); ObjectSetInteger(0,back,OBJPROP_YSIZE,height);
      ObjectSetInteger(0,back,OBJPROP_BGCOLOR,XS_BG); ObjectSetInteger(0,back,OBJPROP_COLOR,XS_BG);
      ObjectSetInteger(0,back,OBJPROP_BORDER_TYPE,BORDER_FLAT); ObjectSetInteger(0,back,OBJPROP_BACK,false);
   }
   int dpi=MathMax(96,(int)TerminalInfoInteger(TERMINAL_SCREEN_DPI));
   int big=MathMax(1,XSPanelRound(40*96.0/dpi)),small=MathMax(1,XSPanelRound(9*96.0/dpi));
   int w_xau=XSPanelTextWidth("XAU","Bahnschrift SemiBold",big);
   int w_all=w_xau+XSPanelTextWidth("SCALPER","Bahnschrift SemiBold",big);
   int x=MathMax(0,(width-w_all)/2),y=MathMax(0,height/2-XSPanelRound(40*96.0/dpi)-10);
   XSPanelSplashLabel("XS_SPLASH_A","XAU",x,y,big,XS_GOLD,"Bahnschrift SemiBold");
   XSPanelSplashLabel("XS_SPLASH_B","SCALPER",x+w_xau+3,y,big,XS_TEXT,"Bahnschrift SemiBold");
   string tag="PRECISION GOLD ENGINE  //  STARTING";
   int w_tag=XSPanelTextWidth(tag,"Segoe UI Semibold",small);
   XSPanelSplashLabel("XS_SPLASH_C",tag,MathMax(0,(width-w_tag)/2),y+XSPanelRound(78*96.0/dpi),small,XS_MUTED,"Segoe UI Semibold");
   string line="XS_SPLASH_LINE";
   int line_w=MathMin(width,MathMax(80,w_all));
   if(XSPanelTouch(line,StringFormat("S|%d|%d|%d",line_w,width,y),OBJ_RECTANGLE_LABEL)>=0)
   {
      XSPanelPlace(line,MathMax(0,(width-line_w)/2),y+XSPanelRound(66*96.0/dpi),10000);
      ObjectSetInteger(0,line,OBJPROP_XSIZE,line_w); ObjectSetInteger(0,line,OBJPROP_YSIZE,3);
      ObjectSetInteger(0,line,OBJPROP_BGCOLOR,XS_GOLD); ObjectSetInteger(0,line,OBJPROP_COLOR,XS_GOLD);
      ObjectSetInteger(0,line,OBJPROP_BORDER_TYPE,BORDER_FLAT); ObjectSetInteger(0,line,OBJPROP_BACK,false);
   }
}

void XSPanelRender(const XSPanelSnapshot &state)
{
   ++md_panel_epoch;
   if(state.enabled)
   {
      XSPanelGeometry g=XSPanelMeasure(state); md_panel_dpi=g.dpi;
      if(g.rich)
      {
         XSPanelPendingLines(state,g);
         if(!state.execution_visible || g.side_by_side) XSPanelMain(state,g);
         if(state.execution_enabled && state.execution_visible) XSPanelExecution(state,g);
      }
      XSPanelToolbar(state,g);
      if(!g.rich && state.panel_visible && (state.dashboard_enabled || state.user_override))
         XSPanelLabel("SmallNote","Enlarge the chart to show the dashboard. Controls and protection remain active.",
                      g.x,g.toolbar_y+8+g.toolbar_height,8,XS_CYAN,g.toolbar_width);
      XSPanelCorner("XS_FLOAT",state.float_text,34,state.float_ink);
      XSPanelCorner("XS_TODAY",state.today_text,12,state.today_ink);
      if(state.splash_visible) XSPanelSplash();
   }
   XSPanelSweep();
   ChartRedraw();
}

void XSPanelDestroy()
{
   for(int i=0;i<ArraySize(md_panel_cache);++i) ObjectDelete(0,md_panel_cache[i].name);
   ArrayFree(md_panel_cache);
   ObjectsDeleteAll(0,"XSPL_");
   ChartRedraw();
}

struct MDManualCloseItem
{
   ulong identifier;
   bool armed,done,missing;
   ulong missing_since,next_arm;
};

struct MDManualState
{
   bool initialized,tester,paused,state_error,snapshot_failed,cleanup_authorized,needs_snapshot;
   string key,message,close_message;
   double epoch;
   ulong verify_after,cancel_deadline;
   ulong pending_tickets[];
   int cleanup_cursor,cancelled,filled,other,retries;
   bool close_click_seen;
   ulong close_last_click,close_deadline;
   MDManualCloseItem close_items[64];
   int close_size,close_remaining,close_finished,close_retries,close_delayed;
};

bool MDManualValidEpoch(const double epoch)
{
   double magnitude=MathAbs(epoch);
   return MathIsValidNumber(epoch) && epoch!=0.0 && magnitude<9007199254740000.0 &&
          MathFloor(magnitude)==magnitude;
}

double MDManualLatestEpoch(const double disk,const double global)
{
   double a=MathAbs(disk),b=MathAbs(global);
   if(a==b && (disk>0.0 || global>0.0)) return a;
   return a>b ? disk : global;
}

string MDManualKey(const long login,const string server,const string symbol,const long magic)
{
   string identity=(string)login+"|"+(string)StringLen(server)+":"+server+"|"+
                   (string)StringLen(symbol)+":"+symbol+"|"+(string)magic;
   uchar bytes[],empty[],digest[];
   int count=StringToCharArray(identity,bytes,0,WHOLE_ARRAY,CP_UTF8);
   if(count<1 || ArrayResize(bytes,count-1)!=count-1) return "";
   if(CryptEncode(CRYPT_HASH_SHA256,bytes,empty,digest)!=32) return "";
   string key="MDMC1_";
   for(int i=0;i<28;i++) key+=StringFormat("%02X",(uint)digest[i]);
   return key;
}

string MDManualPath(const MDManualState &s,const string suffix)
{
   return "XAUscalperManualControls\\"+s.key+suffix;
}

bool MDManualReadDisk(const MDManualState &s,double &epoch,bool &exists)
{
   epoch=0.0; exists=false;
   string path=MDManualPath(s,".bin");
   ResetLastError();
   if(!FileIsExist(path))
   {
      int error=GetLastError();
      return error==0 || error==5019 || error==5022;
   }
   exists=true;
   int handle=FileOpen(path,FILE_READ|FILE_BIN|FILE_SHARE_READ);
   if(handle==INVALID_HANDLE) return false;
   ulong size=FileSize(handle);
   int version=FileReadInteger(handle,INT_VALUE);
   epoch=FileReadDouble(handle);
   bool ok=size==12 && version==1 && MDManualValidEpoch(epoch);
   FileClose(handle);
   return ok;
}

bool MDManualReadGlobal(const MDManualState &s,double &epoch,bool &exists)
{
   epoch=0.0;
   exists=GlobalVariableCheck(s.key);
   return !exists || (GlobalVariableGet(s.key,epoch) && MDManualValidEpoch(epoch));
}

bool MDManualWriteDisk(const MDManualState &s,const double epoch)
{
   string temp=MDManualPath(s,".tmp");
   int handle=FileOpen(temp,FILE_WRITE|FILE_BIN);
   if(handle==INVALID_HANDLE) return false;
   ResetLastError();
   uint header=FileWriteInteger(handle,1,INT_VALUE);
   uint body=FileWriteDouble(handle,epoch);
   FileFlush(handle);
   int error=GetLastError();
   FileClose(handle);
   if(header!=4 || body!=8 || error!=0) return false;
   if(!FileMove(temp,0,MDManualPath(s,".bin"),FILE_REWRITE)) return false;
   double verified=0.0;
   bool exists=false;
   return MDManualReadDisk(s,verified,exists) && exists && verified==epoch;
}

void MDManualClearPending(MDManualState &s)
{
   ArrayResize(s.pending_tickets,0);
   s.cleanup_cursor=0;
   s.needs_snapshot=false;
}

void MDManualApplyEpoch(MDManualState &s,const double epoch)
{
   double old=s.epoch;
   s.epoch=epoch;
   s.paused=epoch>0.0 || s.state_error;
   if(old==epoch) return;
   s.cleanup_authorized=s.tester && epoch>0.0;
   s.verify_after=0;
   if(epoch>0.0)
   {
      MDManualClearPending(s);
      s.needs_snapshot=true;
   }
   else if(!s.state_error)
   {
      MDManualClearPending(s);
      s.message="ENTRIES ENABLED - existing guards still apply";
   }
}

void MDManualFailClosed(MDManualState &s,const string message)
{
   s.state_error=true;
   s.paused=true;
   s.message=message;
}

bool MDManualInitialize(MDManualState &s,const bool tester,const long login,
                        const string server,const string symbol,const long base_magic)
{
   s.initialized=true; s.tester=tester; s.paused=false; s.state_error=false;
   s.snapshot_failed=false; s.cleanup_authorized=false; s.needs_snapshot=false;
   s.epoch=0; s.verify_after=0; s.cancel_deadline=0;
   s.cancelled=0; s.filled=0; s.other=0; s.retries=0;
   s.close_click_seen=false; s.close_last_click=0; s.close_deadline=0;
   s.close_size=0; s.close_remaining=0; s.close_finished=0;
   s.close_retries=0; s.close_delayed=0;
   s.message=""; s.close_message="";
   MDManualClearPending(s);
   s.key=MDManualKey(login,server,symbol,base_magic);
   if(tester) return true;
   double disk=0,global=0;
   bool disk_exists=false,global_exists=false;
   if(StringLen(s.key)!=62 || !MDManualReadDisk(s,disk,disk_exists) ||
      !MDManualReadGlobal(s,global,global_exists))
   {
      MDManualFailClosed(s,"STATE READ FAILED - entries paused; retry CANCEL");
      return false;
   }
   double latest=MDManualLatestEpoch(disk,global);
   if(latest!=0.0 && (!global_exists || global!=latest))
   {
      FolderCreate("XAUscalperManualControls");
      int lock=FileOpen(MDManualPath(s,".lck"),FILE_READ|FILE_WRITE|FILE_BIN);
      bool synced=false;
      if(lock!=INVALID_HANDLE)
      {
         if(MDManualReadDisk(s,disk,disk_exists) && MDManualReadGlobal(s,global,global_exists))
         {
            latest=MDManualLatestEpoch(disk,global);
            synced=latest==0.0 || GlobalVariableSet(s.key,latest)!=0;
         }
         FileClose(lock);
      }
      if(!synced)
      {
         MDManualFailClosed(s,"STATE SYNC FAILED - entries paused; retry CANCEL");
         return false;
      }
   }
   MDManualApplyEpoch(s,latest);
   return true;
}

bool MDManualSync(MDManualState &s)
{
   if(!s.initialized) return true;
   if(s.tester) return s.paused;
   double global=0,disk=0;
   bool exists=false,disk_exists=false;
   if(!MDManualReadGlobal(s,global,exists))
   {
      MDManualFailClosed(s,"STATE SYNC FAILED - entries paused; retry CANCEL");
      return true;
   }
   if(!exists && s.epoch!=0.0)
   {
      if(!MDManualReadDisk(s,disk,disk_exists) || !MDManualReadGlobal(s,global,exists))
      {
         MDManualFailClosed(s,"STATE SYNC FAILED - entries paused; retry CANCEL");
         return true;
      }
      global=MDManualLatestEpoch(disk,global);
   }
   MDManualApplyEpoch(s,global);
   return s.paused;
}

bool MDManualSaveCommand(MDManualState &s,const bool pause)
{
   if(s.tester)
   {
      s.epoch=(MathAbs(s.epoch)+1.0)*(pause ? 1.0 : -1.0);
      s.state_error=false;
      return true;
   }
   if(StringLen(s.key)!=62) return false;
   FolderCreate("XAUscalperManualControls");
   int lock=FileOpen(MDManualPath(s,".lck"),FILE_READ|FILE_WRITE|FILE_BIN);
   if(lock==INVALID_HANDLE) return false;
   double disk=0,global=0,latest=0;
   bool disk_exists=false,global_exists=false;
   bool readable=MDManualReadDisk(s,disk,disk_exists) && MDManualReadGlobal(s,global,global_exists);
   bool permit=readable || pause;
   if(readable) latest=MDManualLatestEpoch(disk,global);
   else if(pause)
   {
      latest=s.epoch;
      if(GlobalVariableGet(s.key,global) && MDManualValidEpoch(global) && MathAbs(global)>MathAbs(latest))
         latest=global;
   }
   double next=MathMax(MathAbs(latest),MathAbs(s.epoch))+1.0;
   bool saved=false;
   if(permit && MDManualValidEpoch(next) && GlobalVariableSet(s.key,next)!=0)
   {
      s.epoch=next;
      double desired=pause ? next : -next;
      if(MDManualWriteDisk(s,desired) && GlobalVariableSet(s.key,desired)!=0)
      {
         s.epoch=desired;
         saved=true;
      }
      else
      {
         GlobalVariableSet(s.key,next);
         MDManualWriteDisk(s,next);
      }
   }
   GlobalVariablesFlush();
   FileClose(lock);
   return saved;
}

void MDManualSetPendingSnapshot(MDManualState &s,const ulong &tickets[],const bool ok)
{
   MDManualClearPending(s);
   int count=ArraySize(tickets);
   s.snapshot_failed=!ok;
   if(ok && ArrayResize(s.pending_tickets,count)==count)
   {
      if(count==0 || ArrayCopy(s.pending_tickets,tickets)==count) return;
   }
   s.snapshot_failed=true;
   s.message="PENDING SNAPSHOT FAILED - entries remain paused";
}

bool MDManualCancelClick(MDManualState &s,const ulong now)
{
   if(s.cancel_deadline==0 || s.cancel_deadline<now)
   {
      s.cancel_deadline=now+5000;
      s.message="CONFIRM CANCEL - press again within 5 seconds to pause entries and delete pending orders";
      return false;
   }
   if(!s.initialized) return false;
   s.cancel_deadline=0; s.paused=true; s.cleanup_authorized=false;
   if(!MDManualSaveCommand(s,true))
   {
      MDManualFailClosed(s,"SAVE FAILED - entries paused locally; press CANCEL to retry");
      return false;
   }
   s.cleanup_authorized=true; s.state_error=false;
   s.cancelled=0; s.filled=0; s.other=0; s.retries=0;
   MDManualClearPending(s);
   s.needs_snapshot=true;
   s.message="ENTRIES PAUSED - pending cleanup queued; positions protected";
   return true;
}

bool MDManualCanCleanup(MDManualState &s,const ulong now)
{
   if(!MDManualSync(s) || s.state_error) return false;
   if(!s.cleanup_authorized)
   {
      if(now<s.verify_after) return false;
      s.verify_after=now+1000;
      if(s.tester) s.cleanup_authorized=s.epoch>0.0;
      else
      {
         double disk=0; bool exists=false;
         s.cleanup_authorized=MDManualReadDisk(s,disk,exists) && exists && disk>0.0 && disk==s.epoch;
      }
   }
   if(!s.cleanup_authorized) return false;
   bool any=false;
   for(int i=0;i<ArraySize(s.pending_tickets);i++) if(s.pending_tickets[i]!=0) {any=true;break;}
   if(!any || s.snapshot_failed) s.needs_snapshot=true;
   return true;
}

ulong MDManualPendingTicket(const MDManualState &s,const int index)
{
   if(index<0 || index>=ArraySize(s.pending_tickets)) return 0;
   return s.pending_tickets[index];
}

void MDManualRetirePending(MDManualState &s,const int index,const int status)
{
   if(index<0 || index>=ArraySize(s.pending_tickets) || s.pending_tickets[index]==0 || status==0) return;
   s.pending_tickets[index]=0;
   if(status==1) s.cancelled++;
   else if(status==2) s.filled++;
   else s.other++;
}

bool MDManualResume(MDManualState &s,const bool snapshot_ok,const int current_pending_count,
                    const bool cleanup_complete)
{
   if(!s.initialized) return false;
   s.cancel_deadline=0;
   MDManualSync(s);
   if(!snapshot_ok)
   {
      s.message="PENDING SNAPSHOT FAILED - resume refused";
      return false;
   }
   if(current_pending_count>0)
   {
      if(s.paused) s.needs_snapshot=true;
      s.message="STILL "+(string)current_pending_count+" PENDING - WAIT / RETRY CANCEL";
      return false;
   }
   if(!cleanup_complete)
   {
      s.message="PENDING CLEANUP NOT FINISHED - WAIT / RETRY CANCEL";
      return false;
   }
   if(!MDManualSaveCommand(s,false))
   {
      MDManualFailClosed(s,"RESUME SAVE FAILED - entries remain paused; retry RESUME");
      return false;
   }
   s.paused=false; s.cleanup_authorized=false; s.state_error=false; s.snapshot_failed=false;
   MDManualClearPending(s);
   s.message="ENTRIES ENABLED - next normal signal; all guards apply";
   return true;
}

void MDManualExpireCloseConfirmation(MDManualState &s,const ulong now)
{
   if(s.close_deadline!=0 && now>=s.close_deadline)
   {
      s.close_deadline=0;
      s.close_message="Confirmation expired. No close command. Pending/pause unchanged.";
   }
}

int MDManualCloseClick(MDManualState &s,const bool enabled,const ulong now)
{
   if(!enabled) return 0;
   if(s.close_click_seen && now-s.close_last_click<250) return 0;
   s.close_click_seen=true; s.close_last_click=now;
   MDManualExpireCloseConfirmation(s,now);
   if(s.close_remaining>0)
   {
      s.close_message="Close already queued; no additional trades captured. Pending/pause unchanged.";
      return 0;
   }
   if(s.close_deadline==0)
   {
      s.close_deadline=now+5000;
      s.close_message="CONFIRM CLOSE - press again within 5 seconds to close recognized open trades";
      return 1;
   }
   s.close_deadline=0;
   return 2;
}

bool MDManualQueueClose(MDManualState &s,const ulong &identifiers[],const bool snapshot_ok)
{
   if(s.close_remaining>0) return false;
   ulong unique[64];
   int count=0;
   for(int i=0;snapshot_ok && i<ArraySize(identifiers);i++)
   {
      ulong identifier=identifiers[i];
      bool duplicate=false;
      for(int j=0;j<count;j++) if(unique[j]==identifier) {duplicate=true;break;}
      if(duplicate) continue;
      if(count>=64)
      {
         s.close_message="Snapshot failed: more than 64 recognized trades. Nothing queued.";
         return false;
      }
      unique[count++]=identifier;
   }
   if(!snapshot_ok)
   {
      s.close_message="Snapshot failed. Nothing queued. Pending/pause unchanged.";
      return false;
   }
   s.close_size=count; s.close_remaining=count; s.close_finished=0;
   s.close_retries=0; s.close_delayed=0;
   for(int i=0;i<count;i++)
   {
      s.close_items[i].identifier=unique[i];
      s.close_items[i].armed=false; s.close_items[i].done=false; s.close_items[i].missing=false;
      s.close_items[i].missing_since=0; s.close_items[i].next_arm=0;
   }
   s.close_message=count==0 ? "No recognized open trades. Pending/pause unchanged." :
      "Close queued: "+(string)count+" captured trades (winners/losers). Pending/pause unchanged.";
   return true;
}

bool MDManualObserveClose(MDManualState &s,const int index,const bool recognized_present,
                         const bool validation_safety,const ulong now)
{
   if(index<0 || index>=s.close_size || s.close_items[index].done || validation_safety) return false;
   if(!recognized_present)
   {
      if(!s.close_items[index].missing)
      {
         s.close_items[index].missing=true;
         s.close_items[index].missing_since=now;
      }
      else if(now-s.close_items[index].missing_since>=1000)
      {
         s.close_items[index].done=true;
         s.close_finished++;
         s.close_remaining--;
      }
      return false;
   }
   s.close_items[index].missing=false;
   s.close_items[index].missing_since=0;
   return !s.close_items[index].armed && now>=s.close_items[index].next_arm;
}

void MDManualCloseArmResult(MDManualState &s,const int index,const bool accepted,const ulong now)
{
   if(index<0 || index>=s.close_size || s.close_items[index].done) return;
   s.close_items[index].armed=accepted;
   s.close_items[index].next_arm=now+1000;
}

void MDManualCloseLostIntent(MDManualState &s,const int index)
{
   if(index>=0 && index<s.close_size && !s.close_items[index].done) s.close_items[index].armed=false;
}

void MDManualCloseStatus(MDManualState &s,const bool validation_safety)
{
   if(s.close_size==0) return;
   if(validation_safety && s.close_remaining>0)
      s.close_message="Close queued; validation safety mode blocks arming. Pending/pause unchanged.";
   else if(s.close_remaining==0)
      s.close_message="Snapshot complete: trades closed or outside scope. Pending/pause unchanged; normal entry rules apply.";
   else if(s.close_retries>0 || s.close_delayed>0)
      s.close_message="CLOSE RETRY: "+(string)s.close_retries+" not armed; "+(string)s.close_delayed+" delayed";
   else
      s.close_message="Closing captured trades: "+(string)s.close_remaining+" remain. Algo/broker limits may delay execution.";
}

















struct MDTelemetryDeal
{
   ulong ticket,position,order;
   long timeMsc;
   int module,side;
   ENUM_DEAL_ENTRY entry;
   double volume,price,profit,swap,fees,requested;
   bool orderAvailable;
};

struct MDSlippageStats
{
   int count;
   double mean,median,p95,maximum,minimum;
};

struct MDClosedExecution
{
   ulong position,cycle;
   int module,side;
   datetime opened,closed;
   double entry,exit,total,cost,entryVolume,exitVolume;
   bool entryValid,exitValid,valid;
};

struct MDTelemetryState
{
   bool netDirty,executionDirty,netReady,executionReady,incomplete;
   ulong lastAttempt,nextNetRefresh,nextExecutionRefresh,settleUntil;
   int mixedExits,closedCount,gradedCount;
   double net[9];
   int wins[9],losses[9];
   MDSlippageStats entries,exits;
   double meanEntry,meanExit,meanTotal,p95Total;
   bool latestValid;
   double latestSlippage,latestCost;
   MDClosedExecution latest[10];
   int latestCount;
   string lastSummary;
};

struct MDTelemetryPosition
{
   ulong identity,cycle;
   int owner;
   double volume,fees;
};

struct MDExecutionFillGroup
{
   ulong order,position,cycle,fallbackDeal;
   int side,module;
   datetime first,last;
   double requested,volume,weightedPrice;
};

void MDResetTelemetry(MDTelemetryState &state)
{
   ZeroMemory(state);
   state.netDirty=true;
   state.executionDirty=true;
}

void MDMarkTelemetryDirty(MDTelemetryState &state,const MqlTradeTransaction &transaction,
                          const string symbol)
{
   if(transaction.symbol!="" && transaction.symbol!=symbol) return;
   if(transaction.type!=TRADE_TRANSACTION_HISTORY_ADD &&
      transaction.type!=TRADE_TRANSACTION_HISTORY_UPDATE &&
      transaction.type!=TRADE_TRANSACTION_HISTORY_DELETE &&
      transaction.type!=TRADE_TRANSACTION_DEAL_ADD &&
      transaction.type!=TRADE_TRANSACTION_DEAL_UPDATE &&
      transaction.type!=TRADE_TRANSACTION_DEAL_DELETE) return;
   state.netDirty=true;
   state.executionDirty=true;
   state.nextExecutionRefresh=0;
   state.settleUntil=GetTickCount64()+10000;
}

bool MDTelemetryBefore(const MDTelemetryDeal &left,const MDTelemetryDeal &right)
{
   return left.timeMsc<right.timeMsc || (left.timeMsc==right.timeMsc && left.ticket<right.ticket);
}

void MDSortTelemetryDeals(MDTelemetryDeal &deals[],const int first,const int last)
{
   int i=first,j=last;
   MDTelemetryDeal pivot=deals[first+(last-first)/2];
   while(i<=j)
   {
      while(MDTelemetryBefore(deals[i],pivot)) i++;
      while(MDTelemetryBefore(pivot,deals[j])) j--;
      if(i<=j)
      {
         MDTelemetryDeal temporary=deals[i]; deals[i]=deals[j]; deals[j]=temporary;
         i++; j--;
      }
   }
   if(first<j) MDSortTelemetryDeals(deals,first,j);
   if(i<last) MDSortTelemetryDeals(deals,i,last);
}

bool MDLoadTelemetryDeals(const MDTradeContext &context,MDTelemetryDeal &deals[])
{
   const int total=HistoryDealsTotal();
   if(ArrayResize(deals,total)!=total) return false;
   int count=0;
   for(int i=0;i<total;i++)
   {
      ulong ticket=HistoryDealGetTicket(i);
      if(ticket==0) return false;
      if(HistoryDealGetString(ticket,DEAL_SYMBOL)!=context.symbol) continue;
      ENUM_DEAL_TYPE type=(ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket,DEAL_TYPE);
      if(type!=DEAL_TYPE_BUY && type!=DEAL_TYPE_SELL) continue;
      MDTelemetryDeal deal; ZeroMemory(deal);
      deal.ticket=ticket;
      deal.position=(ulong)HistoryDealGetInteger(ticket,DEAL_POSITION_ID);
      deal.order=(ulong)HistoryDealGetInteger(ticket,DEAL_ORDER);
      deal.timeMsc=HistoryDealGetInteger(ticket,DEAL_TIME_MSC);
      if(deal.timeMsc<=0) deal.timeMsc=HistoryDealGetInteger(ticket,DEAL_TIME)*1000;
      deal.module=MDRecognizeMagic(HistoryDealGetInteger(ticket,DEAL_MAGIC),context.currentBase,
                                  context.previousBase,context.legacyBase,context.quickSetup,context.enabled);
      deal.side=type==DEAL_TYPE_BUY?1:-1;
      deal.entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket,DEAL_ENTRY);
      deal.volume=HistoryDealGetDouble(ticket,DEAL_VOLUME);
      deal.price=HistoryDealGetDouble(ticket,DEAL_PRICE);
      deal.profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
      deal.swap=HistoryDealGetDouble(ticket,DEAL_SWAP);
      deal.fees=HistoryDealGetDouble(ticket,DEAL_COMMISSION)+HistoryDealGetDouble(ticket,DEAL_FEE);
      // Ticket getters preserve the selected history lists; HistoryDealSelect would reset them.
      deal.orderAvailable=deal.order!=0 && HistoryOrderGetString(deal.order,ORDER_SYMBOL)==context.symbol;
      if(deal.orderAvailable && deal.entry!=DEAL_ENTRY_OUT_BY &&
         HistoryOrderGetInteger(deal.order,ORDER_TYPE)!=ORDER_TYPE_CLOSE_BY)
         deal.requested=HistoryOrderGetDouble(deal.order,ORDER_PRICE_OPEN);
      deals[count++]=deal;
   }
   if(HistoryDealsTotal()!=total) return false;
   if(ArrayResize(deals,count)!=count) return false;
   if(count>1) MDSortTelemetryDeals(deals,0,count-1);
   return true;
}

uint MDTelemetryHash(const ulong key)
{
   ulong mixed=key^(key>>33);
   mixed*=0xff51afd7ed558ccd;
   mixed^=mixed>>33;
   return (uint)(mixed^(mixed>>32));
}

bool MDCreateTelemetryIndex(const int records,int &slots[])
{
   int capacity=16;
   while(capacity<records && capacity<536870912) capacity*=2;
   if(capacity<records || capacity>536870912) return false;
   capacity*=2;
   if(ArrayResize(slots,capacity)!=capacity) return false;
   ArrayInitialize(slots,-1);
   return true;
}

int MDTelemetryPositionIndex(const ulong identity,MDTelemetryPosition &positions[],int &used,int &slots[])
{
   int mask=ArraySize(slots)-1,slot=(int)(MDTelemetryHash(identity)&(uint)mask);
   while(slots[slot]>=0)
   {
      int index=slots[slot];
      if(positions[index].identity==identity) return index;
      slot=(slot+1)&mask;
   }
   if(used>=ArraySize(positions)) return -1;
   int index=used++;
   ZeroMemory(positions[index]); positions[index].identity=identity; positions[index].owner=-1;
   slots[slot]=index;
   return index;
}

bool MDCalculateRealizedNet(const MDTelemetryDeal &deals[],double &net[],int &wins[],int &losses[],int &mixed)
{
   MDTelemetryPosition positions[]; int slots[],used=0;
   int count=ArraySize(deals);
   if(ArrayResize(positions,count)!=count || !MDCreateTelemetryIndex(count,slots)) return false;
   ArrayInitialize(net,0.0); ArrayInitialize(wins,0); ArrayInitialize(losses,0); mixed=0;
   const double epsilon=1e-9;
   for(int i=0;i<count;i++)
   {
      MDTelemetryDeal deal=deals[i];
      if(deal.position==0 || deal.volume<=0.0) continue;
      if(deal.entry<DEAL_ENTRY_IN || deal.entry>DEAL_ENTRY_OUT_BY) continue;
      int index=MDTelemetryPositionIndex(deal.position,positions,used,slots);
      if(index<0) return false;
      MDTelemetryPosition position=positions[index];
      if(deal.entry==DEAL_ENTRY_IN)
      {
         if(position.volume<=epsilon) position.owner=deal.module;
         else if(position.owner!=deal.module) position.owner=-2;
         position.volume+=deal.volume;
         position.fees+=deal.fees;
      }
      else if(position.volume>epsilon &&
              (deal.entry==DEAL_ENTRY_INOUT || deal.volume<=position.volume+epsilon))
      {
         int owner=position.owner;
         double matched=MathMin(deal.volume,position.volume);
         double entryFees=position.fees*matched/position.volume;
         double exitFees=deal.fees*matched/deal.volume;
         position.volume-=matched;
         position.fees-=entryFees;
         if(position.volume<=epsilon)
         {
            position.owner=-1; position.volume=0.0; position.fees=0.0;
         }
         if(deal.entry==DEAL_ENTRY_INOUT && matched+epsilon<deal.volume)
         {
            position.owner=deal.module;
            position.volume=deal.volume-matched;
            position.fees=deal.fees-exitFees;
         }
         if(owner==-2) mixed++;
         if(owner>=0 && owner<9)
         {
            double realized=exitFees+entryFees+deal.profit+deal.swap;
            net[owner]+=realized;
            if(realized>=0.0) wins[owner]++; else losses[owner]++;
         }
      }
      positions[index]=position;
   }
   return true;
}

bool MDAddExecutionFill(MDExecutionFillGroup &groups[],int &used,int &slots[],
                        const MDTelemetryDeal &deal,const ulong cycle,const int owner,const double volume)
{
   ulong cycleKey=cycle==0?deal.position:cycle;
   ulong orderKey=deal.order==0?deal.ticket:deal.order;
   int mask=ArraySize(slots)-1;
   uint hash=MDTelemetryHash(cycleKey)^MDTelemetryHash(deal.position)^MDTelemetryHash(orderKey);
   int slot=(int)(hash&(uint)mask);
   while(slots[slot]>=0)
   {
      int index=slots[slot];
      if(groups[index].cycle==cycleKey && groups[index].position==deal.position &&
         groups[index].order==deal.order &&
         (deal.order!=0 || groups[index].fallbackDeal==deal.ticket)) break;
      slot=(slot+1)&mask;
   }
   int index=slots[slot];
   if(index<0)
   {
      if(used>=ArraySize(groups)) return false;
      index=used++; slots[slot]=index;
      ZeroMemory(groups[index]);
      groups[index].order=deal.order; groups[index].position=deal.position;
      groups[index].cycle=cycleKey; groups[index].fallbackDeal=deal.ticket;
      groups[index].side=deal.side; groups[index].module=owner;
      groups[index].first=(datetime)(deal.timeMsc/1000); groups[index].last=groups[index].first;
      groups[index].requested=deal.requested;
   }
   if(deal.requested<=0.0 || deal.price<=0.0) groups[index].requested=0.0;
   datetime time=(datetime)(deal.timeMsc/1000);
   groups[index].first=MathMin(groups[index].first,time);
   groups[index].last=MathMax(groups[index].last,time);
   groups[index].volume+=volume;
   groups[index].weightedPrice+=deal.price*volume;
   return true;
}

bool MDExecutionGroupValid(const MDExecutionFillGroup &group)
{
   return group.requested>0.0 && group.volume>0.0 && group.weightedPrice>0.0;
}

double MDExecutionGroupSlippage(const MDExecutionFillGroup &group)
{
   if(!MDExecutionGroupValid(group)) return 0.0;
   double average=group.weightedPrice/group.volume;
   return group.side>0 ? average-group.requested : group.requested-average;
}

void MDCalculateSlippageStats(double &values[],MDSlippageStats &stats)
{
   ZeroMemory(stats); stats.count=ArraySize(values);
   if(stats.count==0) return;
   for(int i=0;i<stats.count;i++) stats.mean+=values[i];
   stats.mean/=stats.count;
   ArraySort(values);
   stats.minimum=values[0]; stats.maximum=values[stats.count-1];
   stats.median=(stats.count%2==0) ?
      (values[stats.count/2-1]+values[stats.count/2])*0.5 : values[stats.count/2];
   int rank=MathMax(0,MathMin(stats.count-1,(int)MathCeil(stats.count*0.95)-1));
   stats.p95=values[rank];
}

int MDTelemetryCycleOwner(const ulong cycle,const MDTelemetryPosition &cycles[],const int &slots[])
{
   int mask=ArraySize(slots)-1,slot=(int)(MDTelemetryHash(cycle)&(uint)mask);
   while(slots[slot]>=0)
   {
      int index=slots[slot];
      if(cycles[index].identity==cycle) return cycles[index].owner;
      slot=(slot+1)&mask;
   }
   return -1;
}

bool MDExecutionSamples(MDExecutionFillGroup &groups[],int &used,const MDTelemetryPosition &cycles[],
                        const int &cycleSlots[],MDSlippageStats &stats)
{
   double samples[];
   if(ArrayResize(samples,used)!=used) return false;
   int retained=0,count=0;
   for(int i=0;i<used;i++)
   {
      int owner=MDTelemetryCycleOwner(groups[i].cycle,cycles,cycleSlots);
      if(owner<0) continue;
      groups[i].module=owner;
      if(MDExecutionGroupValid(groups[i])) samples[count++]=MDExecutionGroupSlippage(groups[i]);
      if(retained!=i) groups[retained]=groups[i];
      retained++;
   }
   used=retained;
   if(ArrayResize(samples,count)!=count) return false;
   MDCalculateSlippageStats(samples,stats);
   return true;
}

int MDClosedExecutionIndex(const ulong cycle,MDClosedExecution &closed[],int &used,int &slots[])
{
   int mask=ArraySize(slots)-1,slot=(int)(MDTelemetryHash(cycle)&(uint)mask);
   while(slots[slot]>=0)
   {
      int index=slots[slot];
      if(closed[index].cycle==cycle) return index;
      slot=(slot+1)&mask;
   }
   if(used>=ArraySize(closed)) return -1;
   int index=used++; slots[slot]=index;
   ZeroMemory(closed[index]); closed[index].cycle=cycle;
   closed[index].entryValid=true; closed[index].exitValid=true;
   return index;
}

bool MDCalculateExecutionHistory(const MDTelemetryDeal &deals[],const double tickSize,
                                 const double tickValue,MDTelemetryState &state)
{
   int count=ArraySize(deals);
   MDTelemetryPosition positions[],cycles[];
   MDExecutionFillGroup entries[],exits[];
   int positionSlots[],cycleSlots[],entrySlots[],exitSlots[];
   int positionsUsed=0,cyclesUsed=0,entriesUsed=0,exitsUsed=0;
   if(ArrayResize(positions,count)!=count || ArrayResize(cycles,count)!=count ||
      ArrayResize(entries,count)!=count || ArrayResize(exits,count)!=count ||
      !MDCreateTelemetryIndex(count,positionSlots) || !MDCreateTelemetryIndex(count,cycleSlots) ||
      !MDCreateTelemetryIndex(count,entrySlots) || !MDCreateTelemetryIndex(count,exitSlots)) return false;
   bool incomplete=false;
   const double epsilon=1e-9;
   for(int i=0;i<count;i++)
   {
      MDTelemetryDeal deal=deals[i];
      if(deal.position==0 || deal.volume<=0 || deal.entry<DEAL_ENTRY_IN || deal.entry>DEAL_ENTRY_OUT_BY) continue;
      int index=MDTelemetryPositionIndex(deal.position,positions,positionsUsed,positionSlots);
      if(index<0) return false;
      MDTelemetryPosition position=positions[index];
      if(!deal.orderAvailable && (deal.module>=0 || position.owner>=0)) incomplete=true;
      double opening=deal.entry==DEAL_ENTRY_IN?deal.volume:0.0;
      if(deal.entry!=DEAL_ENTRY_IN)
      {
         if(position.volume<=epsilon)
         {
            if(deal.module>=0) incomplete=true;
            continue;
         }
         if(deal.entry!=DEAL_ENTRY_INOUT && deal.volume>position.volume+epsilon)
         {
            incomplete=true;
            continue;
         }
         double matched=MathMin(position.volume,deal.volume);
         if(!MDAddExecutionFill(exits,exitsUsed,exitSlots,deal,position.cycle,position.owner,matched)) return false;
         position.volume-=matched;
         if(position.volume<=epsilon) position.volume=0.0;
         if(deal.entry==DEAL_ENTRY_INOUT) opening=deal.volume-matched;
      }
      if(opening>epsilon)
      {
         if(position.volume<=epsilon)
         {
            position.cycle=deal.ticket; position.owner=deal.module;
            int cycle=MDTelemetryPositionIndex(position.cycle,cycles,cyclesUsed,cycleSlots);
            if(cycle<0) return false;
            cycles[cycle].owner=deal.module;
         }
         else if(position.owner!=deal.module)
         {
            position.owner=-2;
            int cycle=MDTelemetryPositionIndex(position.cycle,cycles,cyclesUsed,cycleSlots);
            if(cycle<0) return false;
            cycles[cycle].owner=-2;
         }
         position.volume+=opening;
         if(!MDAddExecutionFill(entries,entriesUsed,entrySlots,deal,position.cycle,position.owner,opening)) return false;
      }
      positions[index]=position;
   }
   if(!MDExecutionSamples(entries,entriesUsed,cycles,cycleSlots,state.entries) ||
      !MDExecutionSamples(exits,exitsUsed,cycles,cycleSlots,state.exits)) return false;
   MDClosedExecution closed[]; int closedSlots[],closedUsed=0;
   if(ArrayResize(closed,exitsUsed)!=exitsUsed || !MDCreateTelemetryIndex(exitsUsed,closedSlots)) return false;
   double moneyPerPrice=tickSize>0.0 && tickValue>0.0?tickValue/tickSize:0.0;
   for(int i=0;i<exitsUsed;i++)
   {
      MDExecutionFillGroup group=exits[i];
      int index=MDClosedExecutionIndex(group.cycle,closed,closedUsed,closedSlots);
      if(index<0) return false;
      closed[index].position=group.position; closed[index].module=group.module; closed[index].side=-group.side;
      if(!MDExecutionGroupValid(group)) closed[index].exitValid=false;
      double slippage=MDExecutionGroupSlippage(group);
      closed[index].exit+=slippage*group.volume;
      closed[index].exitVolume+=group.volume;
      closed[index].cost+=slippage*group.volume*moneyPerPrice;
      closed[index].closed=MathMax(closed[index].closed,group.last);
   }
   int latestEntry=-1;
   for(int i=0;i<entriesUsed;i++)
   {
      MDExecutionFillGroup group=entries[i];
      if(group.volume>0 && (latestEntry<0 || entries[latestEntry].last<=group.last)) latestEntry=i;
      int mask=ArraySize(closedSlots)-1,slot=(int)(MDTelemetryHash(group.cycle)&(uint)mask);
      while(closedSlots[slot]>=0 && closed[closedSlots[slot]].cycle!=group.cycle) slot=(slot+1)&mask;
      int index=closedSlots[slot];
      if(index<0) continue;
      if(!MDExecutionGroupValid(group)) closed[index].entryValid=false;
      double slippage=MDExecutionGroupSlippage(group);
      closed[index].entry+=slippage*group.volume;
      closed[index].entryVolume+=group.volume;
      closed[index].cost+=slippage*group.volume*moneyPerPrice;
      if(closed[index].opened==0 || group.first<closed[index].opened) closed[index].opened=group.first;
      closed[index].module=group.module; closed[index].side=group.side;
   }
   state.latestValid=latestEntry>=0 && MDExecutionGroupValid(entries[latestEntry]);
   state.latestSlippage=state.latestValid?MDExecutionGroupSlippage(entries[latestEntry]):0.0;
   state.latestCost=state.latestValid?state.latestSlippage*entries[latestEntry].volume*moneyPerPrice:0.0;
   int retained=0;
   for(int i=0;i<closedUsed;i++)
   {
      if(closed[i].entryVolume<=0.0 || closed[i].exitVolume<=0.0 ||
         MathAbs(closed[i].entryVolume-closed[i].exitVolume)>1e-8) continue;
      closed[i].valid=closed[i].entryValid && closed[i].exitValid;
      closed[i].entry/=closed[i].entryVolume; closed[i].exit/=closed[i].exitVolume;
      closed[i].total=closed[i].entry+closed[i].exit;
      if(retained!=i) closed[retained]=closed[i];
      retained++;
   }
   // Only the first ten rows are ordered; statistics still use every completed cycle.
   for(int i=0;i<MathMin(retained,10);i++)
   {
      int newest=i;
      for(int j=i+1;j<retained;j++) if(closed[j].closed>closed[newest].closed) newest=j;
      if(newest!=i) { MDClosedExecution temporary=closed[i]; closed[i]=closed[newest]; closed[newest]=temporary; }
   }
   state.closedCount=retained; state.gradedCount=0;
   state.meanEntry=0.0; state.meanExit=0.0; state.meanTotal=0.0; state.p95Total=0.0;
   double totals[];
   if(ArrayResize(totals,retained)!=retained) return false;
   for(int i=0;i<retained;i++)
   {
      if(!closed[i].valid) continue;
      state.meanEntry+=closed[i].entry; state.meanExit+=closed[i].exit; state.meanTotal+=closed[i].total;
      totals[state.gradedCount++]=closed[i].total;
   }
   if(state.gradedCount>0)
   {
      state.meanEntry/=state.gradedCount; state.meanExit/=state.gradedCount; state.meanTotal/=state.gradedCount;
      if(ArrayResize(totals,state.gradedCount)!=state.gradedCount) return false;
      ArraySort(totals);
      int rank=MathMax(0,MathMin(state.gradedCount-1,(int)MathCeil(state.gradedCount*0.95)-1));
      state.p95Total=totals[rank];
   }
   state.latestCount=MathMin(retained,10);
   for(int i=0;i<state.latestCount;i++) state.latest[i]=closed[i];
   state.incomplete=incomplete;
   return true;
}

bool MDRefreshTelemetry(MDTelemetryState &state,const MDTradeContext &context,const bool executionEnabled)
{
   ulong now=GetTickCount64();
   if(!context.tester)
   {
      if(state.lastAttempt!=0 && now-state.lastAttempt<1000) return true;
      if(state.netDirty || state.nextNetRefresh<=now || (state.settleUntil!=0 && now<=state.settleUntil))
         state.netDirty=true;
   }
   bool executionDue=executionEnabled && !(now<state.nextExecutionRefresh &&
                      (state.nextExecutionRefresh!=0 || !state.executionDirty));
   if(!state.netDirty && !executionDue) return true;
   state.lastAttempt=now;
   datetime serverNow=TimeTradeServer();
   if(serverNow<=0) serverNow=TimeCurrent();
   if(serverNow<=0) serverNow=TimeLocal();
   if(!HistorySelect(0,serverNow+60))
   {
      if(executionDue) { state.executionReady=false; state.nextExecutionRefresh=now+30000; }
      return false;
   }
   MDTelemetryDeal deals[];
   if(!MDLoadTelemetryDeals(context,deals))
   {
      if(executionDue) { state.executionDirty=true; state.nextExecutionRefresh=now+1000; }
      return false;
   }
   bool success=true;
   if(state.netDirty)
   {
      double net[9]; int wins[9],losses[9],mixed=0;
      if(MDCalculateRealizedNet(deals,net,wins,losses,mixed))
      {
         for(int i=0;i<9;i++) { state.net[i]=net[i]; state.wins[i]=wins[i]; state.losses[i]=losses[i]; }
         if(mixed>0 && mixed!=state.mixedExits)
            Print("XAUscalper dashboard | mixed-owner netting exits excluded=",mixed,
                  " | separate strategy attribution is unavailable for combined positions");
         state.mixedExits=mixed; state.netDirty=false; state.netReady=true; state.nextNetRefresh=now+30000;
      }
      else success=false;
   }
   if(executionDue)
   {
      double tickSize=SymbolInfoDouble(context.symbol,SYMBOL_TRADE_TICK_SIZE);
      double tickValue=SymbolInfoDouble(context.symbol,SYMBOL_TRADE_TICK_VALUE_LOSS);
      if(tickValue<=0.0) tickValue=SymbolInfoDouble(context.symbol,SYMBOL_TRADE_TICK_VALUE);
      MDTelemetryState candidate=state;
      if(MDCalculateExecutionHistory(deals,tickSize,tickValue,candidate))
      {
         state=candidate; state.executionReady=true; state.executionDirty=state.incomplete;
         state.nextExecutionRefresh=GetTickCount64()+30000;
         string summary=StringFormat("XAUscalper execution quality | broker=%s | entry measured=%d avg=%.5f p95=%.5f | exit measured=%d avg=%.5f p95=%.5f | closed trades=%d measured=%d round-trip avg=%s rating=%s",
            AccountInfoString(ACCOUNT_COMPANY),state.entries.count,state.entries.mean,state.entries.p95,
            state.exits.count,state.exits.mean,state.exits.p95,state.closedCount,state.gradedCount,
            state.gradedCount>0?DoubleToString(state.meanTotal,5):"N/D",
            state.gradedCount>0?MDExecutionGrade(state.meanTotal,true):"N/D");
         if(summary!=state.lastSummary) { Print(summary); state.lastSummary=summary; }
      }
      else { state.executionDirty=true; state.nextExecutionRefresh=GetTickCount64()+1000; success=false; }
   }
   return success;
}

string MDExecutionGrade(const double slippage,const bool roundTrip)
{
   double scale=roundTrip?2.0:1.0;
   if(slippage<-0.005*scale) return "PRICE IMPROVEMENT";
   if(slippage<=ExecutionExcellentMax*scale) return "EXCELLENT";
   if(slippage<=ExecutionGoodMax*scale) return "GOOD";
   if(slippage<=ExecutionNormalMax*scale) return "NORMAL";
   if(slippage<=ExecutionPoorMax*scale) return "POOR";
   return "BAD";
}

string MDExecutionGradeLabel(const string grade,const bool compact=false)
{
   if(grade=="PRICE IMPROVEMENT") return compact?"S  BEST":"S  IMPROVED";
   if(grade=="EXCELLENT") return compact?"A+  EXC":"A+  EXCELLENT";
   if(grade=="GOOD") return "A  GOOD";
   if(grade=="NORMAL") return "B  NORMAL";
   if(grade=="POOR") return "C  POOR";
   if(grade=="BAD") return "D  BAD";
   return grade;
}

color MDExecutionGradeColor(const string grade)
{
   if(grade=="PRICE IMPROVEMENT" || grade=="EXCELLENT") return XS_GREEN;
   if(grade=="GOOD") return XS_CYAN;
   if(grade=="NORMAL") return XS_AMBER;
   if(grade=="POOR") return (color)0x498eeb;
   if(grade=="BAD") return XS_RED;
   return XS_MUTED;
}

string MDSlippageText(const double value)
{
   return (value>1e-7?"+":"")+DoubleToString(value,2);
}

string MDExecutionCostText(const double cost)
{
   if(cost>0.004) return "-"+DoubleToString(cost,2);
   if(cost<-.004) return "+"+DoubleToString(-cost,2);
   return "0.00";
}

void MDApplyTelemetryPanel(const MDTelemetryState &state,XSPanelSnapshot &view)
{
   const color positive=XS_GREEN,negative=XS_RED,muted=XS_MUTED;
   double realized=0.0;
   for(int i=0;i<9;i++)
   {
      realized+=state.net[i];
      view.modules[i].net=DoubleToString(state.net[i],2);
      view.modules[i].net_ink=state.net[i]>=0?positive:negative;
   }
   view.information[0].value=state.netReady?DoubleToString(realized,2):"--";
   view.information[0].ink=realized>=0?positive:negative;
   string grade=state.executionReady && state.gradedCount>0?MDExecutionGrade(state.meanTotal,true):
                state.executionReady && state.closedCount>0?"N/D":"WAITING";
   if(!state.executionReady) view.execution_verdict="HISTORY NOT READY";
   else if(state.closedCount==0) view.execution_verdict="WAITING FOR FIRST CLOSED TRADE";
   else if(state.gradedCount==0) view.execution_verdict=IntegerToString(state.closedCount)+" CLOSED // SLIPPAGE N/D";
   else if(state.gradedCount<ExecutionMinimumTrades)
      view.execution_verdict="CALIBRATING "+IntegerToString(state.gradedCount)+"/"+IntegerToString(ExecutionMinimumTrades)+"  //  "+MDExecutionGradeLabel(grade);
   else view.execution_verdict="BROKER  //  "+MDExecutionGradeLabel(grade);
   view.execution_ink=MDExecutionGradeColor(grade);
   view.execution_cards[0].label="LATEST FILL / COST "+AccountInfoString(ACCOUNT_CURRENCY);
   view.execution_cards[0].value=state.executionReady && state.latestValid?
      MDSlippageText(state.latestSlippage)+" / "+MDExecutionCostText(state.latestCost):(state.executionReady?"N/D":"--");
   view.execution_cards[0].ink=state.latestValid?MDExecutionGradeColor(MDExecutionGrade(state.latestSlippage,false)):muted;
   view.execution_cards[1].label="FILL GRADE";
   view.execution_cards[1].value=state.executionReady && state.latestValid?
      MDExecutionGradeLabel(MDExecutionGrade(state.latestSlippage,false)):(state.executionReady?"N/D":"WAITING");
   view.execution_cards[1].ink=view.execution_cards[0].ink;
   view.execution_cards[2].label="ROUND TRIP / P95";
   view.execution_cards[2].value=state.executionReady && state.gradedCount>0?
      MDSlippageText(state.meanTotal)+" / "+MDSlippageText(state.p95Total):(state.executionReady && state.closedCount>0?"N/D":"--");
   view.execution_cards[2].ink=view.execution_ink;
   view.execution_cards[3].label="BROKER / CLOSED";
   view.execution_cards[3].value=MDExecutionGradeLabel(grade)+" // "+IntegerToString(state.closedCount);
   view.execution_cards[3].ink=view.execution_ink;
   const string modules[9]={"S1","S2","S3","S4","S5","S6","S7","S8","S9"};
   for(int i=0;i<10;i++)
   {
      if(!state.executionReady || i>=state.latestCount)
      {
         view.deals[i].closed=""; view.deals[i].module_side="";
         view.deals[i].entry="--"; view.deals[i].exit="--"; view.deals[i].total="--"; view.deals[i].grade="--";
         view.deals[i].total_ink=muted; view.deals[i].grade_ink=muted;
         continue;
      }
      MDClosedExecution row=state.latest[i];
      MqlDateTime closedTime; ZeroMemory(closedTime); TimeToStruct(row.closed,closedTime);
      view.deals[i].closed=StringFormat("#%d %02d/%02d %02d:%02d",i+1,closedTime.day,closedTime.mon,closedTime.hour,closedTime.min);
      view.deals[i].module_side=(row.module>=0 && row.module<9?modules[row.module]:"UNKNOWN")+(row.side>0?" / BUY":" / SELL");
      view.deals[i].entry=row.entryValid?MDSlippageText(row.entry):"N/D";
      view.deals[i].exit=row.exitValid?MDSlippageText(row.exit):"N/D";
      view.deals[i].total=row.valid?MDSlippageText(row.total):"N/D";
      view.deals[i].grade=row.valid?MDExecutionGradeLabel(MDExecutionGrade(row.total,true),true):"N/D";
      view.deals[i].grade_ink=row.valid?MDExecutionGradeColor(MDExecutionGrade(row.total,true)):muted;
      view.deals[i].total_ink=view.deals[i].grade_ink;
   }
   view.execution_footnote="N/D: NO REFERENCE / + WORSE, - BETTER / COST: "+AccountInfoString(ACCOUNT_CURRENCY);
}













enum MDNewsOrderStatus
{
   MD_NEWS_STILL_PENDING=0,
   MD_NEWS_CANCELLED_CONFIRMED=1,
   MD_NEWS_FILLED_NOT_CANCELLED=2,
   MD_NEWS_EXPIRED_NOT_CANCELLED=3,
   MD_NEWS_MISSING_AWAITING_HISTORY=4
};

struct MDNewsAuditTicket
{
   ulong ticket;
   MDNewsOrderStatus status;
   uint last_retcode;
   int last_error;
   bool last_sent;
};

struct MDNewsAuditState
{
   bool active;
   ulong next_poll_ms,last_summary_ms,ended_ms;
   string panel_status;
};

string MDNewsAuditStatusName(const MDNewsOrderStatus status)
{
   switch(status)
   {
      case MD_NEWS_STILL_PENDING: return "STILL_PENDING";
      case MD_NEWS_CANCELLED_CONFIRMED: return "CANCELLED_CONFIRMED";
      case MD_NEWS_FILLED_NOT_CANCELLED: return "FILLED_NOT_CANCELLED";
      case MD_NEWS_EXPIRED_NOT_CANCELLED: return "EXPIRED_NOT_CANCELLED";
   }
   return "MISSING_AWAITING_HISTORY";
}

MDNewsOrderStatus MDNewsAuditHistoryStatus(const long state)
{
   if(state==ORDER_STATE_CANCELED) return MD_NEWS_CANCELLED_CONFIRMED;
   if(state==ORDER_STATE_PARTIAL || state==ORDER_STATE_FILLED) return MD_NEWS_FILLED_NOT_CANCELLED;
   if(state==ORDER_STATE_EXPIRED) return MD_NEWS_EXPIRED_NOT_CANCELLED;
   return MD_NEWS_MISSING_AWAITING_HISTORY;
}

bool MDNewsAuditOwnsPending(const MDTradeContext &context,const string symbol,const long magic,const long type)
{
   return symbol==context.symbol && type>=ORDER_TYPE_BUY_LIMIT && type<=ORDER_TYPE_SELL_STOP_LIMIT &&
          MDCurrentMagicModule(magic,context.currentBase,context.quickSetup,context.enabled)>=0;
}

bool MDNewsAuditSelectedPending(const MDTradeContext &context)
{
   return MDNewsAuditOwnsPending(context,OrderGetString(ORDER_SYMBOL),
                                OrderGetInteger(ORDER_MAGIC),OrderGetInteger(ORDER_TYPE));
}

// A successful current-order selection does not fall through to history.
MDNewsOrderStatus MDNewsAuditClassify(const MDTradeContext &context,const ulong ticket)
{
   if(OrderSelect(ticket))
      return MDNewsAuditSelectedPending(context) ? MD_NEWS_STILL_PENDING : MD_NEWS_MISSING_AWAITING_HISTORY;
   if(!HistoryOrderSelect(ticket)) return MD_NEWS_MISSING_AWAITING_HISTORY;
   if(!MDNewsAuditOwnsPending(context,HistoryOrderGetString(ticket,ORDER_SYMBOL),
                             HistoryOrderGetInteger(ticket,ORDER_MAGIC),
                             HistoryOrderGetInteger(ticket,ORDER_TYPE))) return MD_NEWS_MISSING_AWAITING_HISTORY;
   return MDNewsAuditHistoryStatus(HistoryOrderGetInteger(ticket,ORDER_STATE));
}

int MDNewsAuditFind(const MDNewsAuditTicket &rows[],const ulong ticket)
{
   for(int i=0;i<ArraySize(rows);i++) if(rows[i].ticket==ticket) return i;
   return -1;
}

bool MDNewsAuditRegister(MDNewsAuditTicket &rows[],const ulong ticket)
{
   if(ticket==0 || MDNewsAuditFind(rows,ticket)>=0) return true;
   int count=ArraySize(rows);
   if(count>=2048 || ArrayResize(rows,count+1)!=count+1) return false;
   rows[count].ticket=ticket;
   rows[count].status=MD_NEWS_STILL_PENDING;
   rows[count].last_retcode=0;
   rows[count].last_error=0;
   rows[count].last_sent=false;
   return true;
}

// Snapshot first, then register. Partial snapshots remain useful on allocation failure.
bool MDNewsAuditCapture(MDNewsAuditTicket &rows[],const MDTradeContext &context)
{
   ulong tickets[];
   bool complete=true;
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0 || !MDNewsAuditSelectedPending(context)) continue;
      int count=ArraySize(tickets);
      if(ArrayResize(tickets,count+1)!=count+1) { complete=false; break; }
      tickets[count]=ticket;
   }
   for(int i=0;i<ArraySize(tickets);i++)
      if(!MDNewsAuditRegister(rows,tickets[i])) complete=false;
   return complete;
}

// Returns whether the caller should capture/delete/verify, or only verify after END.
// The caller supplies the confirmed-event predicate; fail-closed health pauses do not qualify.
bool MDNewsAuditDue(MDNewsAuditState &state,MDNewsAuditTicket &rows[],const bool confirmed,
                    const bool tester,const bool act,const ulong now_ms,const string event_name,
                    const string symbol,const long magic_base)
{
   if(tester || !act) return false;
   if(confirmed)
   {
      if(!state.active)
      {
         ArrayResize(rows,0);
         state.active=true;
         state.next_poll_ms=0;
         state.last_summary_ms=0;
         state.ended_ms=0;
         Print("XAUscalper news cleanup START | event=",event_name," | symbol=",symbol,
               " | magic_base=",magic_base," | scope=CURRENT_PENDING_ONLY");
      }
   }
   else
   {
      if(state.active)
      {
         state.active=false;
         state.next_poll_ms=0;
         state.ended_ms=now_ms;
         Print("XAUscalper news cleanup END | new_entries=REEVALUATE_ALL_GUARDS_AND_STRATEGY",
               " | old_pending_levels_not_restored=true | open_positions_unchanged=true");
      }
      if(state.ended_ms==0 || now_ms-state.ended_ms>120000)
      {
         state.panel_status="";
         return false;
      }
   }
   if(now_ms<state.next_poll_ms) return false;
   state.next_poll_ms=now_ms+1000;
   return true;
}

// Return value controls logging only. A send response never changes the status.
bool MDNewsAuditRecordReceipt(MDNewsAuditState &state,MDNewsAuditTicket &rows[],const ulong ticket,
                              const bool sent,const uint retcode,const int error)
{
   if(!state.active) return false;
   int index=MDNewsAuditFind(rows,ticket);
   if(index<0) return false;
   bool duplicate=rows[index].last_retcode==retcode && rows[index].last_error==error && rows[index].last_sent;
   rows[index].last_retcode=retcode;
   rows[index].last_error=error;
   rows[index].last_sent=sent;
   return !duplicate;
}

void MDNewsAuditReceipt(MDNewsAuditState &state,MDNewsAuditTicket &rows[],const ulong ticket,
                        const bool sent,const uint retcode,const int error)
{
   if(MDNewsAuditRecordReceipt(state,rows,ticket,sent,retcode,error))
      Print("XAUscalper news DELETE RESPONSE | ticket=",ticket," | sent=",sent," | retcode=",retcode,
            " | error=",error," | awaiting_order_history=true");
}

string MDNewsAuditWaitReason(MDTradeContext &context,const MDExecutionState &execution,
                             MDExecutionHooks &hooks,const ulong ticket)
{
   if(ticket==0) return "NONE";
   if(!OrderSelect(ticket) || !MDNewsAuditSelectedPending(context)) return "AWAITING_HISTORY";
   if(!hooks.AllowTrade(context)) return "TRADING_PERMISSION_OR_CONNECTION";
   datetime now=MDBrokerNow();
   if(!MDSessionAllowsDelete(context.symbol,now)) return "BROKER_SESSION_CLOSED";
   long type=OrderGetInteger(ORDER_TYPE);
   if(type==ORDER_TYPE_BUY_STOP || type==ORDER_TYPE_SELL_STOP)
   {
      if(!context.hasCachedTick) context.hasCachedTick=SymbolInfoTick(context.symbol,context.cachedTick);
      if(context.hasCachedTick)
      {
         double quote=type==ORDER_TYPE_BUY_STOP ? context.cachedTick.ask : context.cachedTick.bid;
         double freeze=(double)SymbolInfoInteger(context.symbol,SYMBOL_TRADE_FREEZE_LEVEL)*context.point+context.point;
         if(MathAbs(OrderGetDouble(ORDER_PRICE_OPEN)-quote)<=freeze) return "WITHIN_BROKER_FREEZE_DISTANCE";
      }
   }
   if(MDBrokerNow()<execution.deleteNext || now<execution.laneUntil[MD_DELETE_LANE]) return "RETRY_COOLDOWN";
   return "AWAITING_BROKER_CONFIRMATION";
}

void MDNewsAuditVerify(MDNewsAuditState &state,MDNewsAuditTicket &rows[],MDTradeContext &context,
                       const MDExecutionState &execution,MDExecutionHooks &hooks,
                       const bool incomplete,const ulong now_ms)
{
   int pending=0,cancelled=0,filled=0,expired=0,unknown=0;
   ulong residual=0;
   bool changed=false;
   for(int i=0;i<ArraySize(rows);i++)
   {
      if(rows[i].status==MD_NEWS_STILL_PENDING || rows[i].status==MD_NEWS_MISSING_AWAITING_HISTORY)
      {
         MDNewsOrderStatus status=MDNewsAuditClassify(context,rows[i].ticket);
         if(status!=rows[i].status)
         {
            rows[i].status=status;
            changed=true;
            Print("XAUscalper news ORDER STATUS | ticket=",rows[i].ticket," | state=",MDNewsAuditStatusName(status),
                  " | last_retcode=",rows[i].last_retcode," | cancellation_is_not_inferred_from_disappearance=true");
         }
      }
      switch(rows[i].status)
      {
         case MD_NEWS_STILL_PENDING: pending++; residual=rows[i].ticket; break;
         case MD_NEWS_CANCELLED_CONFIRMED: cancelled++; break;
         case MD_NEWS_FILLED_NOT_CANCELLED: filled++; break;
         case MD_NEWS_EXPIRED_NOT_CANCELLED: expired++; break;
         default: unknown++;
      }
   }
   state.panel_status="";
   if(state.active)
   {
      if(incomplete) state.panel_status="NEWS // AUDIT INCOMPLETE - CHECK EXPERTS";
      else if(pending>0) state.panel_status="NEWS // PENDING LEFT: "+IntegerToString(pending);
      else if(unknown>0) state.panel_status="NEWS // VERIFYING ORDER HISTORY";
      else state.panel_status="NEWS // PENDING BOOK CLEAR";
   }
   if(changed || state.last_summary_ms==0 || now_ms-state.last_summary_ms>=30000)
   {
      string reason=MDNewsAuditWaitReason(context,execution,hooks,residual);
      Print("XAUscalper news cleanup VERIFIED | active=",state.active," | cancelled=",cancelled,
            " | filled=",filled," | expired=",expired," | pending=",pending," | unknown=",unknown,
            " | audit_incomplete=",incomplete," | residual_ticket=",residual," | wait_reason=",reason,
            " | retry_while_confirmed_pause=true | closes_positions=false");
      state.last_summary_ms=now_ms;
   }
}







struct MDPendingReview
{
   ulong ticket;
   int module;
   ENUM_ORDER_TYPE type;
   datetime nextAttempt;
};

struct MDLotGrowthState
{
   string prefix;
   double baseline,peak,lots;
   bool enabled,persistent,dirty;
   datetime nextSave,nextTouch;
};

struct MDEngineState
{
   bool initialized,worker,timer,closing,tradeAllowed,quoteValid;
   bool propAllowed,dailyAllowed,sessionAllowed,paused;
   bool newsBlocked,hoursAllowed,weekendBlocked,upgradePending;
   datetime upgradeLog;
   bool pendingDirty,validationComplete,validationOpened,volumeSpecificationValid,entryBudgetDeferred;
   datetime validationAttempt;
   long tickSequence,spreadSequence,spreadNextMsc;
   ulong spreadLastTicket,spreadAttempts,spreadCancelled,spreadFilled,spreadOther,spreadRetries;
   datetime moduleBars[9],lastPendingReview,nextPendingExpiry;
   ulong acceptedSignals,primaryRejects,consensusRejects,modelFailures;
   ulong moduleRejects[9],pendingReviews,pendingRejected,pendingCancelled;
   MqlTick quote;
   string permissionReason;
   datetime permissionLog;
   datetime splashUntil;
   bool panelVisible,panelUserOverride,executionVisible;
};

MDConfiguration mdConfiguration;
MDEngineState mdEngine;
MDTradeContext mdTrade;
MDExecutionState mdExecution;
MDLotGrowthState mdGrowth;
MDManualState mdManual;
MDTelemetryState mdTelemetry;
MDNewsAuditState mdNewsAudit;
MDNewsAuditTicket mdNewsAuditRows[];
XSVolumeRules mdVolume;
MDPropState mdProp;
MDNormalDailyState mdDaily;
MDWeekendState mdWeekend;
MDNewsState mdNews;
MDOfficialNewsState mdOfficialNews;
MDNewsWindow mdNewsWindows[];
MDNewsCachedRecord mdNewsCacheRecords[];
MDNewsCacheState mdNewsCache;
MDSpreadState mdSpread;
MDCWParentState mdCalendar;
MDCWWorkerState mdCalendarWorker;
MDPendingReview mdPendingReviews[];

bool MDRefreshPermissions(const bool report);
bool MDRefreshQuote();
bool MDEntryAllowed(const bool act);
bool MDTesterLowMargin();
bool MDHasPendingReview(const int module,const ENUM_ORDER_TYPE type);
bool MDEntryBudgetAvailable();
bool XSLicenseEntriesAllowed();
double XSActiveFixedLot();
int XSActiveSizing();
double XSLotGuard(const double volume);

class MDEngineExecutionHooks : public MDExecutionHooks
{
public:
   virtual bool AllowTrade(const MDTradeContext &context) { return MDRefreshPermissions(false); }
   virtual bool ReadQuote(const MDTradeContext &context,MqlTick &tick)
   {
      if(!MDRefreshQuote()) return false;
      tick=mdEngine.quote;
      return true;
   }
   virtual bool AllowEntry(const MDTradeContext &context,const long magic,const ENUM_ORDER_TYPE type)
   {
      int module=MDCurrentMagicModule(magic,context.currentBase,context.quickSetup,context.enabled);
      return module>=0 && !MDHasPendingReview(module,type) && MDEntryAllowed(false) && MDEntryBudgetAvailable();
   }
   virtual void PendingDeleteResult(const ulong ticket,const bool sent,const uint retcode,const int error)
   { MDNewsAuditReceipt(mdNewsAudit,mdNewsAuditRows,ticket,sent,retcode,error); }
   virtual bool AllowEntryRetry(const MDTradeContext &context)
   {
      return MDEntryAllowed(false);
   }
};
MDEngineExecutionHooks mdExecutionHooks;

int MDSelectedOrderModule()
{
   if(OrderGetString(ORDER_SYMBOL)!=mdTrade.symbol) return -1;
   return MDCurrentMagicModule(OrderGetInteger(ORDER_MAGIC),mdTrade.currentBase,
                               mdTrade.quickSetup,mdTrade.enabled);
}

int MDSelectedPositionModule(const bool includePrevious=true)
{
   if(PositionGetString(POSITION_SYMBOL)!=mdTrade.symbol) return -1;
   long magic=PositionGetInteger(POSITION_MAGIC);
   if(includePrevious)
      return MDRecognizeMagic(magic,mdTrade.currentBase,mdTrade.previousBase,
                              mdTrade.legacyBase,mdTrade.quickSetup,mdTrade.enabled);
   return MDCurrentMagicModule(magic,mdTrade.currentBase,mdTrade.quickSetup,mdTrade.enabled);
}

bool MDIsStopOrder(const ENUM_ORDER_TYPE type)
{
   return type==ORDER_TYPE_BUY_STOP || type==ORDER_TYPE_SELL_STOP;
}

int MDCountPositions(const int module=-1,const int side=-1,const bool includePrevious=true)
{
   int count=0;
   for(int i=0;i<PositionsTotal();i++)
   {
      if(PositionGetTicket(i)==0) continue;
      int index=MDSelectedPositionModule(includePrevious);
      if(index<0 || (module>=0 && index!=module)) continue;
      if(side>=0 && PositionGetInteger(POSITION_TYPE)!=side) continue;
      count++;
   }
   return count;
}

int MDCountPending(const int module=-1,const int side=-1)
{
   int count=0;
   for(int i=0;i<OrdersTotal();i++)
   {
      if(OrderGetTicket(i)==0) continue;
      int index=MDSelectedOrderModule();
      if(index<0 || (module>=0 && index!=module)) continue;
      ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(!MDIsStopOrder(type) || (side>=0 && type!=(side==0?ORDER_TYPE_BUY_STOP:ORDER_TYPE_SELL_STOP))) continue;
      count++;
   }
   return count;
}

int MDCountOwnedPending(const bool includePrevious=false)
{
   int count=0;
   for(int i=0;i<OrdersTotal();i++)
   {
      if(OrderGetTicket(i)==0 || OrderGetString(ORDER_SYMBOL)!=mdTrade.symbol) continue;
      long magic=OrderGetInteger(ORDER_MAGIC);
      int module=includePrevious?MDRecognizeMagic(magic,mdTrade.currentBase,mdTrade.previousBase,
         mdTrade.legacyBase,mdTrade.quickSetup,mdTrade.enabled):
         MDCurrentMagicModule(magic,mdTrade.currentBase,mdTrade.quickSetup,mdTrade.enabled);
      if(module>=0) count++;
   }
   return count;
}

bool MDCollectPendingPrices(const int module,const bool buy,double &prices[])
{
   ArrayResize(prices,0);
   ENUM_ORDER_TYPE type=buy?ORDER_TYPE_BUY_STOP:ORDER_TYPE_SELL_STOP;
   for(int i=0;i<OrdersTotal();i++)
   {
      if(OrderGetTicket(i)==0 || MDSelectedOrderModule()!=module || OrderGetInteger(ORDER_TYPE)!=type) continue;
      int n=ArraySize(prices);
      if(ArrayResize(prices,n+1)!=n+1) return false;
      prices[n]=OrderGetDouble(ORDER_PRICE_OPEN);
   }
   return true;
}

bool MDHasPendingRiskClose()
{
   for(int i=0;i<mdExecution.positionCount;i++)
      if(mdExecution.positions[i].close.identifier>0 && mdExecution.positions[i].close.reason==1) return true;
   for(int i=0;i<mdExecution.emergencyCount;i++)
      if(mdExecution.emergency[i].identifier>0 && mdExecution.emergency[i].reason==1) return true;
   return false;
}

bool MDRefreshQuote()
{
   if(mdEngine.quoteValid) return true;
   mdEngine.quoteValid=SymbolInfoTick(mdTrade.symbol,mdEngine.quote);
   mdTrade.hasCachedTick=mdEngine.quoteValid;
   if(mdEngine.quoteValid) mdTrade.cachedTick=mdEngine.quote;
   return mdEngine.quoteValid;
}

void MDRefreshVolumeSpecification()
{
   double minimum=SymbolInfoDouble(mdTrade.symbol,SYMBOL_VOLUME_MIN);
   double maximum=SymbolInfoDouble(mdTrade.symbol,SYMBOL_VOLUME_MAX);
   double step=SymbolInfoDouble(mdTrade.symbol,SYMBOL_VOLUME_STEP);
   mdEngine.volumeSpecificationValid=minimum>0 && step>0 && minimum<=maximum;
   mdVolume.step=step<=0?0.01:step;
   mdVolume.minimum=minimum<=0?mdVolume.step:minimum;
   mdVolume.maximum=maximum<=0?0:maximum;
   mdVolume.digits=2;
   for(int i=0;i<8;i++)
      if(MathAbs(mdVolume.step-MDNormalizeDecimal(mdVolume.step,i))<1e-8)
      { mdVolume.digits=i; break; }
}

void MDWarmStrategyHistory()
{
   if(!mdConfiguration.strategyEnvironmentAllowed) return;
   for(int module=0;module<9;module++)
   {
      if(!MDStrategyEnabled(module,mdConfiguration.quickSetup,mdConfiguration.enabled)) continue;
      int count=mdConfiguration.strategies[module].searchDepth+2+mdConfiguration.strategies[module].olderBars;
      if(count<=0) continue;
      MqlRates rates[];
      CopyRates(mdTrade.symbol,mdConfiguration.strategies[module].pivotTimeframe,0,count,rates);
   }
}

void MDBeginCycle()
{
   mdEngine.tickSequence++;
   mdEngine.quoteValid=false;
   mdTrade.hasCachedTick=false;
   mdTrade.tickSequence=mdEngine.tickSequence;
   mdTrade.now=MDReliableServerTime();
   mdTrade.tradeAllowed=MDRefreshPermissions(true);
   mdTrade.deleteAllowed=mdTrade.tradeAllowed;
   if(!mdEngine.volumeSpecificationValid) MDRefreshVolumeSpecification();
}

bool MDRefreshPermissions(const bool report)
{
   string reason="";
   if(!mdConfiguration.tester)
   {
      if(!TerminalInfoInteger(TERMINAL_CONNECTED)) reason="TERMINAL DISCONNECTED";
      else if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) reason="ALGO TRADING DISABLED IN TERMINAL";
      else if(!MQLInfoInteger(MQL_TRADE_ALLOWED)) reason="ALGO TRADING DISABLED FOR EA";
      else if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)) reason="ACCOUNT TRADING DISABLED";
      else if(!AccountInfoInteger(ACCOUNT_TRADE_EXPERT)) reason="EA TRADING DISABLED BY BROKER";
   }
   bool allowed=reason=="";
   if(report && (!allowed && (reason!=mdEngine.permissionReason || TimeCurrent()-mdEngine.permissionLog>=60)))
   {
      Print("XAUscalper PROTECTION LIMITED | ",reason," | physical broker-side SL remains active; virtual actions resume automatically");
      mdEngine.permissionLog=TimeCurrent();
   }
   if(report && allowed && mdEngine.permissionReason!="") Print("XAUscalper trade permissions restored | entries and protection actions resumed");
   mdEngine.permissionReason=reason;
   mdEngine.tradeAllowed=allowed;
   return allowed;
}

void MDDeleteCurrentPending(const int module=-1,const int side=-1)
{
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0) continue;
      int index=MDSelectedOrderModule();
      if(index<0 || (module>=0 && index!=module)) continue;
      ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(!MDIsStopOrder(type) || (side>=0 && type!=(side==0?ORDER_TYPE_BUY_STOP:ORDER_TYPE_SELL_STOP))) continue;
      long magic=OrderGetInteger(ORDER_MAGIC);
      MDTradeOutcome outcome;
      MDDeletePending(mdTrade,mdExecution,mdExecutionHooks,ticket,magic,outcome);
   }
}

void MDDeleteRecognizedPending()
{
   if(mdConfiguration.testerDailyOrHigher) return;
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0 || OrderGetString(ORDER_SYMBOL)!=mdTrade.symbol) continue;
      long magic=OrderGetInteger(ORDER_MAGIC);
      if(MDRecognizeMagic(magic,mdTrade.currentBase,mdTrade.previousBase,mdTrade.legacyBase,
                          mdTrade.quickSetup,mdTrade.enabled)<0 ||
         !MDIsStopOrder((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE))) continue;
      MDTradeOutcome outcome;
      MDDeletePending(mdTrade,mdExecution,mdExecutionHooks,ticket,magic,outcome);
   }
}

void MDRequestCurrentPositionsClose(const int reason)
{
   ulong tickets[];
   int total=PositionsTotal(),count=0;
   if(ArrayResize(tickets,total)!=total) return;
   for(int i=0;i<total;i++)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || MDSelectedPositionModule()<0) continue;
      tickets[count++]=ticket;
   }
   int start=0;
   if(mdExecution.lastBudgetPosition>0)
      for(int i=0;i<count;i++)
         if(PositionSelectByTicket(tickets[i]) &&
            (ulong)PositionGetInteger(POSITION_IDENTIFIER)==mdExecution.lastBudgetPosition)
         { start=(i+1)%count; break; }
   for(int i=0;i<count;i++)
   {
      if(mdConfiguration.testerNonGoldMode) continue;
      MDTradeOutcome outcome;
      MDRequestFullClose(mdTrade,mdExecution,mdExecutionHooks,tickets[(start+i)%count],reason,outcome);
   }
}

void MDApplyGuardActions(const MDGuardActions &actions)
{
   if(actions.close_positions) MDRequestCurrentPositionsClose(1);
   if(actions.delete_pending) MDDeleteRecognizedPending();
}

bool MDCheckAccountGuards(const bool act)
{
   mdEngine.propAllowed=true;
   mdEngine.dailyAllowed=true;
   MDGuardActions actions;
   if(mdConfiguration.prop.enabled)
   {
      mdEngine.propAllowed=MDPropAllow(mdConfiguration.prop,mdProp,mdConfiguration.tester,
         MDServerNow(),AccountInfoDouble(ACCOUNT_BALANCE),AccountInfoDouble(ACCOUNT_EQUITY),
         MDCountPositions()+MDCountOwnedPending(),act,actions);
      if(act) { mdProp.actions_busy=true; MDApplyGuardActions(actions); mdProp.actions_busy=false; }
   }
   if(mdConfiguration.normalDaily.enabled && !mdConfiguration.normalDaily.prop_active)
   {
      mdEngine.dailyAllowed=MDNormalDailyAllow(mdConfiguration.normalDaily,mdDaily,mdConfiguration.tester,
         MDBrokerNow(),AccountInfoDouble(ACCOUNT_EQUITY),act,MDHasPendingRiskClose(),actions);
      if(act) { mdDaily.actions_busy=true; MDApplyGuardActions(actions); mdDaily.actions_busy=false; }
   }
   return mdEngine.propAllowed && mdEngine.dailyAllowed;
}

int MDUpgradePendingCount()
{
   if(mdTrade.previousBase<=0 && mdTrade.legacyBase<=0) return 0;
   int count=0;
   for(int i=0;i<OrdersTotal();i++)
   {
      if(OrderGetTicket(i)==0 || OrderGetString(ORDER_SYMBOL)!=mdTrade.symbol) continue;
      long magic=OrderGetInteger(ORDER_MAGIC);
      long previous=magic-mdTrade.previousBase;
      if(mdTrade.previousBase>0 && previous>=1 && previous<=5) count++;
      long legacy=magic-mdTrade.legacyBase;
      if(mdTrade.legacyBase>0 && (legacy==9 || legacy==12 || legacy==13 || legacy==14 || legacy==15)) count++;
   }
   return count;
}

bool MDUpgradePendingBlocked(const bool report)
{
   int count=MDUpgradePendingCount();
   mdEngine.upgradePending=count>0;
   datetime now=TimeCurrent();
   if(now<=0) now=TimeLocal();
   if(count>0 && report && (mdEngine.upgradeLog<=0 || now-mdEngine.upgradeLog>=60))
   {
      Print("XAUscalper upgrade safety | ",count,
            " pending order(s) from another XAUscalper identity detected | new entries remain paused until those orders are removed manually");
      mdEngine.upgradeLog=now;
   }
   return mdEngine.upgradePending;
}

bool MDCheckSessionGuards(const bool act)
{
   datetime now=MDServerNow();
   bool hours=MDTradingHoursAllow(UseTradingHours,TradingStartHour,TradingStartMinute,
                                 TradingEndHour,TradingEndMinute,now);
   MDUpdateOfficialNews(mdConfiguration.news,mdOfficialNews,mdConfiguration.tester,TimeGMT(),
                        TimeTradeServer(),mdEngine.quoteValid?mdEngine.quote.time:0,GetTickCount64());
   bool news=MDNewsBlocked(mdConfiguration.news,mdNews,mdNewsWindows,mdConfiguration.tester,now,
      GetTickCount64(),mdOfficialNews.active,mdOfficialNews.event_utc,mdOfficialNews.until_utc,mdOfficialNews.name);
   MDResolveWeekend(mdTrade.symbol,mdConfiguration.weekend,mdWeekend,now);
   bool weekend=MDWeekendBlocked(mdConfiguration.weekend,mdWeekend,now);
   if(act && weekend && !mdWeekend.pending_cleanup_done)
   {
      MDDeleteCurrentPending();
      mdWeekend.pending_cleanup_done=MDCountOwnedPending()==0;
   }
   bool confirmed=MDNewsCleanupRequired(news,DeletePendingBeforeNews,mdNews);
   ulong auditNow=GetTickCount64();
   if(MDNewsAuditDue(mdNewsAudit,mdNewsAuditRows,confirmed,mdConfiguration.tester,act,
                    auditNow,mdNews.confirmed_name,mdTrade.symbol,mdTrade.currentBase))
   {
      bool complete=true;
      if(mdNewsAudit.active)
      {
         complete=MDNewsAuditCapture(mdNewsAuditRows,mdTrade);
         MDDeleteCurrentPending();
      }
      MDNewsAuditVerify(mdNewsAudit,mdNewsAuditRows,mdTrade,mdExecution,mdExecutionHooks,!complete,auditNow);
   }
   if(act && !hours && !news && DeletePendingOutsideHours) MDDeleteCurrentPending();
   bool spreadBlocked=WideSpreadProtectionEnabled && (mdSpread.blocked || mdSpread.pending_cleanup);
   mdEngine.newsBlocked=news;
   mdEngine.hoursAllowed=hours;
   mdEngine.weekendBlocked=weekend;
   bool upgrade=MDUpgradePendingBlocked(act);
   mdEngine.sessionAllowed=hours && !news && !weekend && !spreadBlocked && !upgrade;
   return mdEngine.sessionAllowed;
}

void MDProcessSpreadMaintenance()
{
   if(!WideSpreadProtectionEnabled || mdEngine.spreadSequence==mdEngine.tickSequence) return;
   mdEngine.spreadSequence=mdEngine.tickSequence;
   MqlTick spreadQuote;
   bool validQuote=SymbolInfoTick(mdTrade.symbol,spreadQuote);
   if(!MDUpdateSpreadGuard(mdSpread,spreadQuote,validQuote,mdConfiguration.pipSize,
                           WideSpreadMaxPoints,0.8)) return;
   if(!mdSpread.pending_cleanup || spreadQuote.time_msc<mdEngine.spreadNextMsc) return;
   ulong tickets[];
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0 || MDSelectedOrderModule()<0 || !MDIsStopOrder((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE))) continue;
      int n=ArraySize(tickets);
      if(ArrayResize(tickets,n+1)!=n+1) return;
      tickets[n]=ticket;
   }
   if(ArraySize(tickets)==0) { mdSpread.pending_cleanup=false; return; }
   ArraySort(tickets);
   ulong ticket=tickets[0];
   for(int i=0;i<ArraySize(tickets);i++)
      if(tickets[i]>mdEngine.spreadLastTicket) { ticket=tickets[i]; break; }
   mdEngine.spreadLastTicket=ticket;
   mdEngine.spreadNextMsc=spreadQuote.time_msc+100;
   mdEngine.spreadAttempts++;
   int status=4;
   if(OrderSelect(ticket))
   {
      if(MDSelectedOrderModule()>=0 && MDIsStopOrder((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)))
      {
         MDTradeOutcome outcome;
         MDDeletePending(mdTrade,mdExecution,mdExecutionHooks,ticket,OrderGetInteger(ORDER_MAGIC),outcome);
         status=(int)MDNewsAuditClassify(mdTrade,ticket);
      }
   }
   else status=(int)MDNewsAuditClassify(mdTrade,ticket);
   if(status==0) mdEngine.spreadRetries++;
   else if(status==1) mdEngine.spreadCancelled++;
   else if(status==2) mdEngine.spreadFilled++;
   else mdEngine.spreadOther++;
}

bool MDExposureFull()
{
   long brokerMaximum=AccountInfoInteger(ACCOUNT_LIMIT_ORDERS);
   if(brokerMaximum>0 && OrdersTotal()>=brokerMaximum-5) return true;
   int limit=mdConfiguration.testerNonGoldMode?4:60;
   if(PropFirmActive && PropFirmMaximumExposureSlots>0) limit=MathMin(limit,PropFirmMaximumExposureSlots);
   if(MDTesterLowMargin()) limit=1;
   return MDCountPositions()+MDCountOwnedPending()>=limit;
}

bool MDTesterLowMargin()
{
   if(!mdConfiguration.tester || !MDRefreshQuote()) return false;
   double volume=SymbolInfoDouble(mdTrade.symbol,SYMBOL_VOLUME_MIN);
   if(volume<=0) volume=MDFixedLots(FixedLot,mdVolume);
   double margin=0.0,free=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   return OrderCalcMargin(ORDER_TYPE_BUY,mdTrade.symbol,volume,mdEngine.quote.ask,margin) &&
          margin>0.0 && free>0.0 && free<2.0*margin;
}

bool MDTesterMarginBlocked()
{
   return mdConfiguration.tester && mdConfiguration.goldSymbol && AccountInfoDouble(ACCOUNT_MARGIN)>0.0 && MDTesterLowMargin();
}

bool MDEntryAllowed(const bool act)
{
   mdEngine.paused=MDManualSync(mdManual);
   if(!mdEngine.initialized || mdEngine.closing || mdEngine.paused || !mdConfiguration.newEntriesAllowed ||
      !mdConfiguration.strategyEnvironmentAllowed || !XSLicenseEntriesAllowed()) return false;
   if(!MDRefreshPermissions(false) || mdTrade.now<mdExecution.laneUntil[MD_ENTRY_LANE]) return false;
   if(!MDCheckSessionGuards(act) || !MDCheckAccountGuards(false)) return false;
   if(MDHasPendingRiskClose() || MDTesterMarginBlocked() || MDExposureFull()) return false;
   if(!MDBrokerSessionAllows(mdTrade.symbol,TimeCurrent()) || !MDRefreshQuote()) return false;
   if(mdEngine.quote.ask<=0 || mdEngine.quote.bid<=0) return false;
   return (mdEngine.quote.ask-mdEngine.quote.bid)/mdConfiguration.pipSize<=mdConfiguration.hardEntrySpreadPoints;
}

void MDRefreshLotGrowth()
{
   mdGrowth.enabled=LotScalingEnabled && (XSActiveSizing()==(int)MDSizing_Fixed || (XSActiveSizing()==(int)MDSizing_Auto && !mdConfiguration.tester));
   double requested=XSActiveFixedLot();
   if(mdGrowth.enabled)
   {
      double value=AccountInfoDouble(LotScalingUseEquity?ACCOUNT_EQUITY:ACCOUNT_BALANCE);
      if(mdGrowth.baseline<=0) mdGrowth.baseline=LotScalingBaseBalance>0?LotScalingBaseBalance:value;
      if(value>mdGrowth.peak) { mdGrowth.peak=value; mdGrowth.dirty=true; }
      if(LotScalingOnlyUp) value=mdGrowth.peak;
      double steps=MathMax(0.0,MathFloor((value-mdGrowth.baseline)/(LotScalingBalanceStep>0?LotScalingBalanceStep:500.0)));
      requested+=steps*LotScalingLotStep;
      if(LotScalingMaxLot>0) requested=MathMin(requested,LotScalingMaxLot);
   }
   mdGrowth.lots=MDFixedLots(requested,mdVolume);
}

bool MDInitializeLotGrowth()
{
   MDRefreshLotGrowth();
   mdGrowth.persistent=mdGrowth.enabled && LotScalingPersistState && !mdConfiguration.tester;
   if(!mdGrowth.persistent) return true;
   string identity=mdTrade.server+"|"+mdTrade.symbol+"|"+(string)mdTrade.currentBase+"|"+
                   LotScalingStateId+"|"+(LotScalingUseEquity?"EQUITY":"BALANCE");
   mdGrowth.prefix="MDLS1."+(string)mdTrade.login+"."+(string)(int)MDIdentityHash(identity)+".";
   double saved=0;
   if(LotScalingBaseBalance<=0 && GlobalVariableGet(mdGrowth.prefix+"BASE",saved) && saved>0) mdGrowth.baseline=saved;
   if(GlobalVariableGet(mdGrowth.prefix+"PEAK",saved) && saved>0) mdGrowth.peak=MathMax(mdGrowth.peak,saved);
   mdGrowth.dirty=true;
   MDRefreshLotGrowth();
   return true;
}

void MDSaveLotGrowth(const bool force=false)
{
   if(!mdGrowth.persistent || (!force && (!mdGrowth.dirty || TimeCurrent()<mdGrowth.nextSave) && TimeCurrent()<mdGrowth.nextTouch)) return;
   bool first=GlobalVariableSet(mdGrowth.prefix+"BASE",mdGrowth.baseline)>0;
   bool second=GlobalVariableSet(mdGrowth.prefix+"PEAK",mdGrowth.peak)>0;
   if(force) GlobalVariablesFlush();
   if(first && second) { mdGrowth.dirty=false; mdGrowth.nextSave=TimeCurrent()+5; mdGrowth.nextTouch=TimeCurrent()+86400; }
}

void MDPollCalendar()
{
   if(mdConfiguration.tester || mdEngine.closing || !mdCalendar.enabled) return;
   MDCWResult batch;
   MDNewsRawRecord records[];
   if(MDCWParentPoll(mdCalendar,batch,records))
   {
      bool healthy=MDApplyNewsBatch(mdConfiguration.news,mdNews,mdNewsWindows,batch.meta,records,MDServerNow());
      MDCWAcknowledgeResult(mdCalendar,healthy);
      MDCacheAcceptedNewsBatch(true,MDCWResultCanPersist(batch.request,MDServerNow(),ArraySize(records)),
         mdConfiguration.news,mdNewsCache,mdNewsCacheRecords,mdNewsWindows,batch.meta,records,
         mdTrade.login,mdTrade.server,MDServerNow());
   }
   mdNews.worker_started=mdCalendar.started;
   mdNews.worker_started_ms=mdCalendar.started_ms;
   mdNews.first_check_complete=mdCalendar.first_check_complete;
   if(mdCalendar.health_lost) mdNews.cache_healthy=false;
}

int MDPendingReviewStatus(const MDPendingReview &item)
{
   if(!OrderSelect(item.ticket) || MDSelectedOrderModule()!=item.module ||
      OrderGetInteger(ORDER_TYPE)!=item.type || !MDIsStopOrder(item.type)) return 0;
   return OrderGetInteger(ORDER_STATE)==ORDER_STATE_PLACED?2:1;
}

void MDDrainPendingReviews()
{
   for(int i=ArraySize(mdPendingReviews)-1;i>=0;i--)
   {
      int status=MDPendingReviewStatus(mdPendingReviews[i]);
      if(status==2 && mdPendingReviews[i].nextAttempt<=mdTrade.now)
      {
         mdPendingReviews[i].nextAttempt=mdTrade.now+1;
         MDTradeOutcome outcome;
         bool deleted=MDDeletePending(mdTrade,mdExecution,mdExecutionHooks,mdPendingReviews[i].ticket,
            mdTrade.currentBase+mdPendingReviews[i].module+1,outcome);
         status=MDPendingReviewStatus(mdPendingReviews[i]);
         if(status==0 && deleted) mdEngine.pendingCancelled++;
      }
      if(status==0) ArrayRemove(mdPendingReviews,i,1);
   }
}

bool MDHasPendingReview(const int module,const ENUM_ORDER_TYPE type)
{
   for(int i=0;i<ArraySize(mdPendingReviews);i++)
      if(mdPendingReviews[i].module==module && mdPendingReviews[i].type==type && MDPendingReviewStatus(mdPendingReviews[i])!=0) return true;
   return false;
}

bool MDQueuePendingReview(const ulong ticket,const int module,const ENUM_ORDER_TYPE type)
{
   for(int i=0;i<ArraySize(mdPendingReviews);i++) if(mdPendingReviews[i].ticket==ticket) return true;
   int n=ArraySize(mdPendingReviews);
   if(ArrayResize(mdPendingReviews,n+1,64)!=n+1) return false;
   mdPendingReviews[n].ticket=ticket;
   mdPendingReviews[n].module=module;
   mdPendingReviews[n].type=type;
   mdPendingReviews[n].nextAttempt=0;
   return true;
}

void MDReviewPendingModels()
{
   MDDrainPendingReviews();
   if(AiTradingMode!=MDAi_Conservative || !xsModelsReady) return;
   datetime bar=iTime(mdTrade.symbol,PERIOD_H1,0);
   if(bar<=0 || bar==mdEngine.lastPendingReview) return;
   bool complete=true;
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0) continue;
      int module=MDSelectedOrderModule();
      ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(module<0 || !MDIsStopOrder(type) || OrderGetInteger(ORDER_STATE)!=ORDER_STATE_PLACED) continue;
      bool queued=false;
      for(int j=0;j<ArraySize(mdPendingReviews);j++) if(mdPendingReviews[j].ticket==ticket) { queued=true; break; }
      if(queued) continue;
      XSModelRequest request;
      request.module=module;
      request.coreSlot=mdConfiguration.strategies[module].coreSlot;
      request.buy=type==ORDER_TYPE_BUY_STOP;
      request.signalTime=TimeCurrent();
      request.entryPrice=OrderGetDouble(ORDER_PRICE_OPEN);
      request.primaryThreshold=mdConfiguration.strategies[module].primaryThreshold;
      request.consensusThreshold=mdConfiguration.strategies[module].consensusThreshold;
      XSModelResult result;
      mdEngine.pendingReviews++;
      if(!EvaluateXSModels(request,true,false,result))
      {
         mdEngine.pendingRejected++;
         if(!MDQueuePendingReview(ticket,module,type)) complete=false;
         MDDrainPendingReviews();
      }
   }
   if(complete) mdEngine.lastPendingReview=bar;
   MDDrainPendingReviews();
}

void MDExpirePending()
{
   if(mdConfiguration.fastBacktest && !mdEngine.pendingDirty &&
      (mdEngine.nextPendingExpiry<=0 || mdTrade.now<mdEngine.nextPendingExpiry)) return;
   mdEngine.pendingDirty=false;
   mdEngine.nextPendingExpiry=0;
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0) continue;
      int module=MDSelectedOrderModule();
      if(module<0 || !MDIsStopOrder((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE))) continue;
      int hours=mdConfiguration.strategies[module].expiryHours;
      if(hours<=0) continue;
      datetime expiry=(datetime)OrderGetInteger(ORDER_TIME_EXPIRATION);
      if(expiry<=0) expiry=(datetime)OrderGetInteger(ORDER_TIME_SETUP)+hours*3600;
      if(mdTrade.now>=expiry)
      {
         MDTradeOutcome outcome;
         if(!MDDeletePending(mdTrade,mdExecution,mdExecutionHooks,ticket,OrderGetInteger(ORDER_MAGIC),outcome) && OrderSelect(ticket))
            expiry=MathMax(mdTrade.now+1,mdExecution.deleteNext);
         else continue;
      }
      if(expiry>0 && (mdEngine.nextPendingExpiry==0 || expiry<mdEngine.nextPendingExpiry)) mdEngine.nextPendingExpiry=expiry;
   }
}

bool MDSnapshotPendingCounts(int &counts[])
{
   ArrayInitialize(counts,0);
   int before=OrdersTotal();
   bool complete=true;
   for(int i=0;i<before;i++)
   {
      if(OrderGetTicket(i)==0) { complete=false; continue; }
      int module=MDSelectedOrderModule();
      long type=OrderGetInteger(ORDER_TYPE);
      if(module<0 || module>=9 || (type!=ORDER_TYPE_BUY_STOP && type!=ORDER_TYPE_SELL_STOP)) continue;
      counts[module*2+(type==ORDER_TYPE_BUY_STOP?0:1)]++;
   }
   return complete && before==OrdersTotal();
}

void MDTrimPendingBook()
{
   int counts[18];
   bool snapshotValid=MDSnapshotPendingCounts(counts);
   for(int module=0;module<9;module++) for(int side=0;side<2;side++)
   {
      int limit=mdConfiguration.strategies[module].pendingLimit;
      if(snapshotValid && counts[module*2+side]<=limit) continue;
      while(MDCountPending(module,side)>limit)
      {
         ulong furthest=0;
         double boundary=side==0?-DBL_MAX:DBL_MAX;
         for(int i=0;i<OrdersTotal();i++)
         {
            ulong ticket=OrderGetTicket(i);
            if(ticket==0 || MDSelectedOrderModule()!=module ||
               OrderGetInteger(ORDER_TYPE)!=(side==0?ORDER_TYPE_BUY_STOP:ORDER_TYPE_SELL_STOP)) continue;
            double price=OrderGetDouble(ORDER_PRICE_OPEN);
            if(side==0?price>boundary:price<boundary) { boundary=price; furthest=ticket; }
         }
         if(furthest==0) { snapshotValid=false; break; }
         if(!OrderSelect(furthest) || MDSelectedOrderModule()!=module ||
            OrderGetInteger(ORDER_TYPE)!=(side==0?ORDER_TYPE_BUY_STOP:ORDER_TYPE_SELL_STOP))
         { snapshotValid=false; continue; }
         MDTradeOutcome outcome;
         if(!MDDeletePending(mdTrade,mdExecution,mdExecutionHooks,furthest,mdTrade.currentBase+module+1,outcome))
         { mdEngine.pendingDirty=true; snapshotValid=false; break; }
         snapshotValid=MDSnapshotPendingCounts(counts);
      }
   }
}

string MDOrderComment(const int module)
{
   if(PropFirmActive && PropFirmBlankOrderComment) return "";
   const string names[9]={"XAUscalper S1","XAUscalper S2","XAUscalper S3","XAUscalper S4","XAUscalper S5","XAUscalper S6","XAUscalper S7","XAUscalper S8","XAUscalper S9"};
   const string codes[9]={"S1","S2","S3","S4","S5","S6","S7","S8","S9"};
   string text=CommentText;
   StringReplace(text,"\r"," ");
   StringReplace(text,"\n"," ");
   StringReplace(text,"\t"," ");
   if(text=="") text=names[module];
   else if(AppendModuleToComment) text+=" "+codes[module];
   return StringSubstr(text,0,31);
}

double MDEntryVolume(const bool buy,const MDPendingGeometry &signal,const XSModelResult &model)
{
   int sizing=MDEffectiveSizingMode(XSActiveSizing(),mdConfiguration.tester);
   if(sizing==0) return XSLotGuard(mdGrowth.lots);
   double probe=MDRiskProbeVolume(mdVolume),profit=0;
   if(probe<=0 || !OrderCalcProfit(buy?ORDER_TYPE_BUY:ORDER_TYPE_SELL,mdTrade.symbol,probe,
                                    signal.entryPrice,signal.stopLoss,profit)) return 0;
   double adaptive=XSAdaptiveSizeMultiplier(AdaptivePositionSize==MDAdaptive_Boost,(int)AiTradingMode,
      XSActiveSizing(),model.primaryScore,model.consensusScore);
   return XSLotGuard(MDRiskLots(XSActiveSizing(),mdConfiguration.tester,RiskPercent,
      AccountInfoDouble(ACCOUNT_BALANCE),probe,profit,adaptive,AdaptivePositionSize==MDAdaptive_Boost,
      (int)AiTradingMode,MaximumRiskLot,mdVolume));
}

bool MDAttemptEntry(const MDStrategyConfig &strategy,const bool buy)
{
   int module=strategy.moduleIndex,side=buy?0:1;
   ENUM_ORDER_TYPE type=buy?ORDER_TYPE_BUY_STOP:ORDER_TYPE_SELL_STOP;
   if(MDExposureFull() || MDHasPendingReview(module,type)) return false;
   if(MDCountPositions(module,side,true)>0) return false;
   bool addOns=(int)XSQuickSetup==2 || (int)XSQuickSetup==3;
   if((int)XSQuickSetup==4) for(int i=5;i<9;i++) addOns=addOns || mdConfiguration.enabled[i];
   if(addOns && MaxSameDirectionPositions>0 && MDCountPositions(-1,side,true)>=MaxSameDirectionPositions) return false;
   double pendingPrices[];
   if(!MDCollectPendingPrices(module,buy,pendingPrices)) return false;
   MqlRates bars[];
   ArraySetAsSeries(bars,true);
   int needed=strategy.searchDepth+2+strategy.olderBars;
   if(CopyRates(mdTrade.symbol,strategy.pivotTimeframe,0,needed,bars)<needed || !MDRefreshQuote()) return false;
   double pivot=MDFindPivot(strategy,buy,mdEngine.quote.bid,mdEngine.quote.ask,
                            mdConfiguration.pipSize,mdTrade.digits,bars,pendingPrices);
   MDPendingGeometry signal;
   double brokerDistance=SymbolInfoInteger(mdTrade.symbol,SYMBOL_TRADE_STOPS_LEVEL)*mdTrade.point;
   double stopDistance=strategy.stopDistance*mdConfiguration.pipSize;
   if(stopDistance+mdTrade.point*0.5<brokerDistance) return false;
   if(!MDBuildPendingGeometry(strategy,buy,pivot,mdEngine.quote.bid,mdEngine.quote.ask,
      mdConfiguration.pipSize,mdTrade.point,mdTrade.digits,stopDistance,brokerDistance,TimeCurrent(),signal)) return false;
   if(!MDPassPendingPlacementGates(strategy,buy,pivot,signal.entryPrice,mdConfiguration.pipSize,pendingPrices)) return false;
   XSModelRequest request;
   request.module=module;
   request.coreSlot=strategy.coreSlot;
   request.buy=buy;
   datetime decisionTime=signal.signalTime;
   request.signalTime=decisionTime;
   request.entryPrice=signal.entryPrice;
   request.primaryThreshold=strategy.primaryThreshold;
   request.consensusThreshold=strategy.consensusThreshold;
   XSCandidateContext candidate;
   PrepareXSCandidateContext(request,decisionTime,mdEngine.moduleBars[module],
      decisionTime+(long)MathMax(strategy.expiryHours,1)*3600,pivot,signal.stopLoss,signal.takeProfit,
      mdEngine.quote.bid,mdEngine.quote.ask,candidate);
   XSModelResult model;
   ulong inferenceStart=xsCandidateLog.active?GetMicrosecondCount():0;
   bool modelAllowed=EvaluateXSModels(request,XSAiModeUsesFilter((int)AiTradingMode),xsCandidateLog.active,model);
   QueueXSCandidateLog(candidate,request,model,inferenceStart>0?GetMicrosecondCount()-inferenceStart:0);
   if(!modelAllowed)
   {
      mdEngine.moduleRejects[module]++;
      if(model.reason==XSPrimaryRejected) mdEngine.primaryRejects++;
      else if(model.reason==XSConsensusRejected) mdEngine.consensusRejects++;
      else mdEngine.modelFailures++;
      return false;
   }
   if(XSAiModeUsesFilter((int)AiTradingMode)) mdEngine.acceptedSignals++;
   double volume=MDEntryVolume(buy,signal,model);
   if(volume<=0 || !MDHasSufficientMargin(mdTrade.symbol,buy?ORDER_TYPE_BUY:ORDER_TYPE_SELL,volume,signal.entryPrice)) return false;
   ENUM_ORDER_TYPE_TIME timeType;
   datetime expiration;
   MDResolvePendingExpiration(mdTrade,mdExecution,strategy.expiryHours,WeekendShieldEnabled,
      mdWeekend.blocked?0:mdWeekend.next_change,timeType,expiration);
   UpdateXSLearningCandidateLot(candidate,volume,expiration);
   MDTradeOutcome outcome;
   mdTrade.entryAllowed=true;
   mdTrade.measureTradeLatency=xsCandidateLog.active;
   bool accepted=MDPlacePending(mdTrade,mdExecution,mdExecutionHooks,mdTrade.currentBase+strategy.strategyId,
      type,volume,signal.entryPrice,signal.stopLoss,signal.takeProfit,timeType,expiration,MDOrderComment(module),outcome);
   if(outcome.attempted || outcome.checkRejected)
      RecordXSLearningOrderResult(candidate,request,model,outcome.request,outcome.checkRejected,
         accepted,outcome.result.order,outcome.result.deal,outcome.result.retcode,outcome.lastError,
         outcome.latencyMicroseconds);
   if(accepted) mdEngine.pendingDirty=true;
   return accepted;
}

bool MDAnyModuleBarReady()
{
   datetime now=TimeCurrent();
   for(int module=0;module<mdConfiguration.moduleCount;module++)
   {
      if(!MDStrategyEnabled(module,mdConfiguration.quickSetup,mdConfiguration.enabled)) continue;
      ENUM_TIMEFRAMES timeframe=mdConfiguration.strategies[module].triggerTimeframe;
      int seconds=PeriodSeconds(timeframe);
      if(mdEngine.moduleBars[module]>0 && seconds>0 && now<mdEngine.moduleBars[module]+seconds) continue;
      datetime bar=iTime(mdTrade.symbol,timeframe,0);
      if(bar>0 && bar!=mdEngine.moduleBars[module]) return true;
   }
   return false;
}

int MDPendingSendLimit()
{
   if(mdConfiguration.quickSetup==2 || mdConfiguration.quickSetup==3) return 10;
   if(mdConfiguration.quickSetup==4)
      for(int module=5;module<9;module++) if(mdConfiguration.enabled[module]) return 10;
   return 1000000;
}

bool MDEntryBudgetAvailable()
{
   if(mdExecution.entrySendCount<MDPendingSendLimit()) return true;
   mdEngine.entryBudgetDeferred=true;
   return false;
}

void MDGenerateEntries()
{
   for(int module=0;module<mdConfiguration.moduleCount;module++)
   {
      if(!MDStrategyEnabled(module,mdConfiguration.quickSetup,mdConfiguration.enabled)) continue;
      MDStrategyConfig strategy;
      MDScaleStrategyConfig(mdConfiguration.strategies[module],iOpen(mdTrade.symbol,PERIOD_D1,1),
         mdConfiguration.pipSize,mdTrade.point,SymbolInfoInteger(mdTrade.symbol,SYMBOL_TRADE_STOPS_LEVEL),
         mdConfiguration.testerNonGoldMode,strategy);
      if(mdExecution.entrySendCount>=MDPendingSendLimit()) return;
      datetime bar=iTime(mdTrade.symbol,strategy.triggerTimeframe,0);
      if(bar<=0 || bar==mdEngine.moduleBars[module]) continue;
      datetime previous=mdEngine.moduleBars[module];
      mdEngine.moduleBars[module]=bar;
      int batch=mdConfiguration.testerNonGoldMode?1:strategy.pendingLimit;
      for(int attempt=0;attempt<batch;attempt++)
      {
         if(MDExposureFull()) break;
         if(mdExecution.entrySendCount>=MDPendingSendLimit())
         { mdEngine.moduleBars[module]=previous; return; }
         bool buySent=false,sellSent=false;
         if(mdExecution.recoveredBuyBar[module]!=bar) buySent=MDAttemptEntry(strategy,true);
         if(mdExecution.entrySendCount>=MDPendingSendLimit() || mdEngine.entryBudgetDeferred ||
            mdTrade.now<mdExecution.laneUntil[MD_ENTRY_LANE])
         { mdEngine.moduleBars[module]=previous; return; }
         if(mdExecution.recoveredSellBar[module]!=bar) sellSent=MDAttemptEntry(strategy,false);
         if(mdEngine.entryBudgetDeferred || mdTrade.now<mdExecution.laneUntil[MD_ENTRY_LANE])
         { mdEngine.moduleBars[module]=previous; return; }
         if(!buySent && !sellSent) break;
      }
   }
}

XSProtectionConfig MDModuleProtection(const MDStrategyConfig &strategy)
{
   XSProtectionConfig config;
   MDBuildProtectionConfiguration(mdConfiguration,strategy,
      SymbolInfoDouble(mdTrade.symbol,SYMBOL_TRADE_TICK_VALUE),
      SymbolInfoDouble(mdTrade.symbol,SYMBOL_TRADE_TICK_VALUE_PROFIT),
      SymbolInfoDouble(mdTrade.symbol,SYMBOL_TRADE_TICK_VALUE_LOSS),
      SymbolInfoDouble(mdTrade.symbol,SYMBOL_TRADE_TICK_SIZE),config);
   return config;
}

void MDMaintainPositions()
{
   ulong tickets[];
   int total=PositionsTotal();
   if(ArrayResize(tickets,total)!=total) return;
   int count=0;
   for(int i=0;i<total;i++)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket!=0 && MDSelectedPositionModule()>=0) tickets[count++]=ticket;
   }
   MDExtraTrailingConfig custom;
   custom.enabled=UseCustomBreakEvenTrailing;
   custom.breakEvenStartPips=CustomBreakEvenStartPips;
   custom.breakEvenLockPips=CustomBreakEvenLockPips;
   custom.trailStartPips=CustomTrailingStartPips;
   custom.trailDistancePips=CustomTrailingDistancePips;
   custom.trailStepPips=CustomTrailingStepPips;
   int closeReason=(mdProp.daily_blocked || mdProp.total_blocked)?1:2;
   int start=0;
   if(!MDHasPendingRiskClose()) mdExecution.lastBudgetPosition=0;
   if(mdExecution.lastBudgetPosition>0)
      for(int i=0;i<count;i++)
         if(PositionSelectByTicket(tickets[i]) && (ulong)PositionGetInteger(POSITION_IDENTIFIER)==mdExecution.lastBudgetPosition)
         { start=(i+1)%count; break; }
   for(int i=0;i<count;i++)
   {
      ulong ticket=tickets[(start+i)%count];
      if(!PositionSelectByTicket(ticket)) continue;
      int module=MDSelectedPositionModule();
      if(module<0) continue;
      MDStrategyConfig strategy;
      MDScaleStrategyConfig(mdConfiguration.strategies[module],iOpen(mdTrade.symbol,PERIOD_D1,1),
         mdConfiguration.pipSize,mdTrade.point,SymbolInfoInteger(mdTrade.symbol,SYMBOL_TRADE_STOPS_LEVEL),
         mdConfiguration.testerNonGoldMode,strategy);
      XSProtectionConfig lock=MDModuleProtection(strategy);
      MDRefreshQuote();
      MDTradeOutcome outcome;
      MDProtectPosition(mdTrade,mdExecution,mdExecutionHooks,ticket,strategy,lock,custom,
                         mdConfiguration.strategyEnvironmentAllowed,closeReason,outcome);
   }
   MDCleanupTrackedPositions(mdTrade,mdExecution,mdExecutionHooks);
   MDResolveLegacyPeak(mdTrade,mdExecution);
   MDProcessCloseQueue(mdTrade,mdExecution,mdExecutionHooks);
}

void MDCheckDirectionLimits()
{
   bool addOns=(int)XSQuickSetup==2 || (int)XSQuickSetup==3;
   if((int)XSQuickSetup==4) for(int i=5;i<9;i++) addOns=addOns || mdConfiguration.enabled[i];
   if(!addOns || MaxSameDirectionPositions<=0) return;
   for(int side=0;side<2;side++)
   {
      int excess=MDCountPositions(-1,side,true)-MaxSameDirectionPositions;
      if(excess>0 && !mdConfiguration.testerNonGoldMode)
      {
         ulong tickets[];
         long opened[];
         for(int i=0;i<PositionsTotal();i++)
         {
            ulong ticket=PositionGetTicket(i);
            if(ticket==0 || MDSelectedPositionModule()<0 || PositionGetInteger(POSITION_TYPE)!=side) continue;
            int count=ArraySize(tickets);
            if(ArrayResize(tickets,count+1)!=count+1 || ArrayResize(opened,count+1)!=count+1) return;
            tickets[count]=ticket;
            opened[count]=PositionGetInteger(POSITION_TIME_MSC);
         }
         for(int i=0;i<ArraySize(tickets)-1;i++) for(int j=i+1;j<ArraySize(tickets);j++)
            if(opened[j]>opened[i] || (opened[j]==opened[i] && tickets[j]>tickets[i]))
            {
               long time=opened[i]; opened[i]=opened[j]; opened[j]=time;
               ulong ticket=tickets[i]; tickets[i]=tickets[j]; tickets[j]=ticket;
            }
         int closeReason=(mdProp.daily_blocked || mdProp.total_blocked)?1:2;
         for(int i=0;i<MathMin(excess,ArraySize(tickets));i++)
         {
            MDTradeOutcome outcome;
            MDRequestFullClose(mdTrade,mdExecution,mdExecutionHooks,tickets[i],closeReason,outcome);
         }
      }
      if(MDCountPositions(-1,side,true)>=MaxSameDirectionPositions) MDDeleteCurrentPending(-1,side);
   }
}

bool MDSelectedPendingRecognized()
{
   long type=OrderGetInteger(ORDER_TYPE);
   return type>=2 && type<=7 && MDSelectedOrderModule()>=0;
}

bool MDManualPendingSnapshot(ulong &tickets[])
{
   ArrayResize(tickets,0);
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0 || !MDSelectedPendingRecognized()) continue;
      int n=ArraySize(tickets);
      if(ArrayResize(tickets,n+1)!=n+1) return false;
      tickets[n]=ticket;
   }
   return true;
}

int MDManualPendingStatus(const ulong ticket)
{
   if(OrderSelect(ticket)) return MDSelectedPendingRecognized()?0:4;
   if(!HistoryOrderSelect(ticket)) return 4;
   long type=HistoryOrderGetInteger(ticket,ORDER_TYPE);
   if(HistoryOrderGetString(ticket,ORDER_SYMBOL)!=mdTrade.symbol || type<2 || type>7 ||
      MDCurrentMagicModule(HistoryOrderGetInteger(ticket,ORDER_MAGIC),mdTrade.currentBase,
                           mdTrade.quickSetup,mdTrade.enabled)<0) return 4;
   long state=HistoryOrderGetInteger(ticket,ORDER_STATE);
   if(state==ORDER_STATE_CANCELED) return 1;
   if(state==ORDER_STATE_PARTIAL || state==ORDER_STATE_FILLED) return 2;
   if(state==ORDER_STATE_EXPIRED) return 3;
   return 4;
}

void MDProcessManualPending()
{
   mdEngine.paused=MDManualSync(mdManual);
   if(!MDManualCanCleanup(mdManual,GetTickCount64())) return;
   if(mdManual.needs_snapshot)
   {
      ulong tickets[];
      bool complete=MDManualPendingSnapshot(tickets);
      MDManualSetPendingSnapshot(mdManual,tickets,complete);
      if(!complete) return;
   }
   int count=ArraySize(mdManual.pending_tickets);
   if(count==0) return;
   for(int offset=0;offset<count;offset++)
   {
      int index=(mdManual.cleanup_cursor+offset)%count;
      ulong ticket=MDManualPendingTicket(mdManual,index);
      if(ticket==0) continue;
      int status=MDManualPendingStatus(ticket);
      if(status!=0) { MDManualRetirePending(mdManual,index,status); continue; }
      if(OrderSelect(ticket) && MDSelectedPendingRecognized())
      {
         MDTradeOutcome outcome;
         MDDeletePending(mdTrade,mdExecution,mdExecutionHooks,ticket,OrderGetInteger(ORDER_MAGIC),outcome);
      }
      status=MDManualPendingStatus(ticket);
      if(status==0) mdManual.retries++;
      else MDManualRetirePending(mdManual,index,status);
      mdManual.cleanup_cursor=(index+1)%count;
      return;
   }
}

bool MDManualCleanupFinished()
{
   for(int i=0;i<ArraySize(mdManual.pending_tickets);i++)
   {
      ulong ticket=mdManual.pending_tickets[i];
      if(ticket==0) continue;
      int status=MDManualPendingStatus(ticket);
      if(status==0) return false;
      MDManualRetirePending(mdManual,i,status);
   }
   return true;
}

bool MDManualPositionSnapshot(ulong &identifiers[])
{
   ArrayResize(identifiers,0);
   for(int i=0;i<PositionsTotal();i++)
   {
      if(PositionGetTicket(i)==0 || MDSelectedPositionModule()<0) continue;
      int n=ArraySize(identifiers);
      if(ArrayResize(identifiers,n+1)!=n+1) return false;
      identifiers[n]=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
   }
   return true;
}

void MDProcessManualClose()
{
   ulong now=GetTickCount64();
   MDManualExpireCloseConfirmation(mdManual,now);
   if(mdManual.close_remaining<1) return;
   bool validationSafety=mdConfiguration.testerNonGoldMode;
   mdManual.close_retries=0;
   mdManual.close_delayed=0;
   for(int i=0;i<mdManual.close_size;i++)
   {
      if(mdManual.close_items[i].done) continue;
      XSPositionSnapshot position;
      bool present=MDFindPositionByIdentifier(mdTrade,mdManual.close_items[i].identifier,position);
      if(MDManualObserveClose(mdManual,i,present,validationSafety,now))
         MDManualCloseArmResult(mdManual,i,MDArmManualClose(mdTrade,mdExecution,position.ticket),now);
      if(!validationSafety && present && !mdConfiguration.tester && mdManual.close_items[i].armed)
      {
         bool delayed=false;
         if(!MDManualCloseIntentStatus(mdTrade,mdExecution,mdManual.close_items[i].identifier,delayed))
            MDManualCloseLostIntent(mdManual,i);
         if(delayed) mdManual.close_delayed++;
      }
      if(!mdManual.close_items[i].armed && !mdManual.close_items[i].done) mdManual.close_retries++;
   }
   MDManualCloseStatus(mdManual,validationSafety);
}

void MDFlushRuntimeState(const bool force)
{
   MDFlushProtectionState(mdTrade,mdExecution,force);
   MDSaveLotGrowth(force);
   bool cacheEnabled=!mdConfiguration.tester && !MQLInfoInteger(MQL_OPTIMIZATION) && !mdEngine.worker;
   MDSaveConfirmedNewsCache(cacheEnabled,mdConfiguration.news,mdNewsCache,mdNewsCacheRecords,
                           mdTrade.login,mdTrade.server,MDServerNow());
}

bool MDPanelStopsCompatible()
{
   double minimum=0.0;
   for(int i=0;i<mdConfiguration.moduleCount;i++)
   {
      if(!MDStrategyEnabled(i,mdConfiguration.quickSetup,mdConfiguration.enabled)) continue;
      double distance=mdConfiguration.strategies[i].stopDistance;
      if(distance<=0) distance=XSStopLossPips*10.0;
      distance*=mdConfiguration.pipSize;
      if(distance>0 && (minimum<=0 || distance<minimum)) minimum=distance;
   }
   if(minimum<=0) minimum=XSStopLossPips*10.0*mdConfiguration.pipSize;
   return minimum+0.5*mdTrade.point>=SymbolInfoInteger(mdTrade.symbol,SYMBOL_TRADE_STOPS_LEVEL)*mdTrade.point;
}

//==================== STATS + CLOSED-TRADE LABELS ====================
struct XSStatsPos
{
   ulong id;
   double net;
   double price;
   datetime when;
   bool closed;
};

struct XSStatsState
{
   double overall,today,floating;
   int dealCount;
   bool ready;
   ulong nextMs;
};
XSStatsState xsStats;

string XSMoney(const double value)
{
   return (value>=0.0 ? "+" : "")+DoubleToString(value,2);
}

void XSStatsLabel(const string name,const datetime when,const double price,const double net,const string currency)
{
   if(ObjectFind(0,name)<0)
   {
      if(!ObjectCreate(0,name,OBJ_TEXT,0,when,price)) return;
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,name,OBJPROP_BACK,false);
      ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LOWER);
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,9);
      ObjectSetString(0,name,OBJPROP_FONT,"Arial");
      ObjectSetInteger(0,name,OBJPROP_TIMEFRAMES,OBJ_ALL_PERIODS);
      ObjectSetInteger(0,name,OBJPROP_ZORDER,200);
   }
   ObjectSetInteger(0,name,OBJPROP_TIME,when);
   ObjectSetDouble(0,name,OBJPROP_PRICE,price);
   ObjectSetString(0,name,OBJPROP_TEXT,XSMoney(net)+" "+currency);
   ObjectSetInteger(0,name,OBJPROP_COLOR,net>=0.0 ? XS_GREEN : XS_RED);
}

void XSStatsRefresh(const bool force)
{
   ulong now=GetTickCount64();
   double floating=0.0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || MDSelectedPositionModule()<0) continue;
      floating+=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
   }
   xsStats.floating=floating;
   if(!force && xsStats.ready && now<xsStats.nextMs) return;
   xsStats.nextMs=now+(MQLInfoInteger(MQL_TESTER) ? 1000 : 4000);
   if(!HistorySelect(0,TimeCurrent()+86400)) return;
   int total=HistoryDealsTotal();
   if(!force && xsStats.ready && total==xsStats.dealCount) return;
   MqlDateTime parts;
   TimeToStruct(TimeCurrent(),parts);
   parts.hour=0; parts.min=0; parts.sec=0;
   datetime dayStart=StructToTime(parts);
   datetime labelFrom=TimeCurrent()-30*86400;
   XSStatsPos positions[];
   int count=0;
   double overall=0.0,today=0.0;
   for(int i=0;i<total;i++)
   {
      ulong ticket=HistoryDealGetTicket(i);
      if(ticket==0) continue;
      long type=HistoryDealGetInteger(ticket,DEAL_TYPE);
      if(type!=DEAL_TYPE_BUY && type!=DEAL_TYPE_SELL) continue;
      if(HistoryDealGetString(ticket,DEAL_SYMBOL)!=mdTrade.symbol) continue;
      if(MDRecognizeMagic(HistoryDealGetInteger(ticket,DEAL_MAGIC),mdTrade.currentBase,mdTrade.previousBase,
                          mdTrade.legacyBase,mdTrade.quickSetup,mdTrade.enabled)<0) continue;
      double net=HistoryDealGetDouble(ticket,DEAL_PROFIT)+HistoryDealGetDouble(ticket,DEAL_SWAP)+
                 HistoryDealGetDouble(ticket,DEAL_COMMISSION)+HistoryDealGetDouble(ticket,DEAL_FEE);
      datetime when=(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
      overall+=net;
      if(when>=dayStart) today+=net;
      if(when<labelFrom) continue;
      ulong id=(ulong)HistoryDealGetInteger(ticket,DEAL_POSITION_ID);
      int slot=-1;
      for(int k=count-1;k>=0 && k>=count-800;k--)
         if(positions[k].id==id) { slot=k; break; }
      if(slot<0)
      {
         if(ArrayResize(positions,count+1,256)!=count+1) continue;
         positions[count].id=id; positions[count].net=0.0; positions[count].price=0.0;
         positions[count].when=0; positions[count].closed=false;
         slot=count; count++;
      }
      positions[slot].net+=net;
      if(HistoryDealGetInteger(ticket,DEAL_ENTRY)!=DEAL_ENTRY_IN)
      {
         positions[slot].when=when;
         positions[slot].price=HistoryDealGetDouble(ticket,DEAL_PRICE);
         positions[slot].closed=true;
      }
   }
   xsStats.overall=overall; xsStats.today=today;
   xsStats.dealCount=total; xsStats.ready=true;
   string currency=AccountInfoString(ACCOUNT_CURRENCY);
   double point=SymbolInfoDouble(mdTrade.symbol,SYMBOL_POINT);
   double gap=(point>0.0 ? point*30.0 : 0.0);
   int usedShift[],usedCount[];
   int used=0,drawn=0;
   for(int k=count-1;k>=0 && drawn<400;k--)
   {
      if(!positions[k].closed || positions[k].when<=0) continue;
      int shift=iBarShift(mdTrade.symbol,_Period,positions[k].when,false);
      double top=positions[k].price;
      if(shift>=0)
      {
         double high=iHigh(mdTrade.symbol,_Period,shift);
         if(high>top) top=high;
      }
      int level=0,found=-1;
      for(int u=0;u<used;u++)
         if(usedShift[u]==shift) { found=u; break; }
      if(found>=0) { level=usedCount[found]; usedCount[found]++; }
      else if(ArrayResize(usedShift,used+1,128)==used+1 && ArrayResize(usedCount,used+1,128)==used+1)
      {
         usedShift[used]=shift; usedCount[used]=1; used++;
      }
      XSStatsLabel("XSPL_"+(string)positions[k].id,positions[k].when,top+gap*(1+level*4),positions[k].net,currency);
      drawn++;
   }
}

void XSStatsPanel(XSPanelSnapshot &view)
{
   string currency=AccountInfoString(ACCOUNT_CURRENCY);
   view.overall_text=XSMoney(xsStats.overall)+" "+currency;
   view.overall_ink=(xsStats.overall>0.0 ? XS_GREEN : xsStats.overall<0.0 ? XS_RED : XS_TEXT);
   view.float_text="Floating P/L: "+XSMoney(xsStats.floating)+" "+currency;
   view.float_ink=(xsStats.floating>=0.0 ? XS_GREEN : XS_RED);
   view.today_text="Today: "+XSMoney(xsStats.today)+" "+currency;
   view.today_ink=(xsStats.today>=0.0 ? XS_GREEN : XS_RED);
}

//==================== LICENSE / PORTAL LINK ====================
// Allow the backend address in MT5: Tools > Options > Expert Advisors > Allow WebRequest for listed URL
#define XS_EA_VERSION "1.1.0"
#define XS_REMOVE_ON_INVALID 0   // 0 = stay on the chart, locked, and show the reason. 1 = remove the EA
int xsPortal=2;                                        // 2 = Cloudflare Worker backend
#define XS_PORTAL_MODE     xsPortal
#define XS_PERIOD_MS  (XS_PORTAL_MODE==1 ? 60000 : 30000)      // how often each backend call repeats
#define XS_TTL_MS     (XS_PORTAL_MODE==1 ? 240000 : 120000)    // new entries pause if the backend is silent this long

struct XSLicenseState
{
   bool deniedAlert,slim,tester,firstDone,valid,allowed,blocked,revoked,webDenied,keyMissing,mismatch,fatal,fatalShown,closeAllPending;
   string status,owner,expiry,reason,lastLog,lastResponse;
   double forceLot,maxDailyLoss;
   ulong lastOkMs,nextValidateMs,nextBeatMs,nextCommandsMs,nextHistoryMs,nextTransMs,nextEnforceMs,lastLogMs;
   int failures,histTotal;
   ulong lastClosed,lastTrans;
};
XSLicenseState xsLic;

struct XSClosedTrade
{
   ulong id,closeTicket;
   string symbol,comment;
   int type;
   double inVol,outVol,openPrice,closeValue,sl,tp,commission,swap,profit;
   datetime openTime,closeTime;
   long magic;
   bool done;
};

string XSJsonEscape(string s)
{
   StringReplace(s,"\\","\\\\");
   StringReplace(s,"\"","\\\"");
   StringReplace(s,"\r"," ");
   StringReplace(s,"\n"," ");
   StringReplace(s,"\t"," ");
   return s;
}

string XSJsonRaw(const string json,const string key)
{
   string needle="\""+key+"\"";
   int p=StringFind(json,needle);
   if(p<0) return "";
   p+=StringLen(needle);
   int len=StringLen(json);
   while(p<len)
   {
      ushort c=StringGetCharacter(json,p);
      if(c==' ' || c==':' || c=='\t' || c=='\r' || c=='\n') p++; else break;
   }
   if(p>=len) return "";
   int q=p;
   if(StringGetCharacter(json,p)=='"')
   {
      q=p+1;
      while(q<len && StringGetCharacter(json,q)!='"')
      {
         if(StringGetCharacter(json,q)=='\\') q++;
         q++;
      }
      return StringSubstr(json,p+1,MathMax(0,q-p-1));
   }
   while(q<len)
   {
      ushort c=StringGetCharacter(json,q);
      if(c==',' || c=='}' || c==']' || c==' ' || c=='\r' || c=='\n') break;
      q++;
   }
   return StringSubstr(json,p,q-p);
}

bool XSJsonBool(const string json,const string key,const bool fallback)
{
   string raw=XSJsonRaw(json,key);
   if(raw=="true") return true;
   if(raw=="false") return false;
   return fallback;
}

double XSJsonNumber(const string json,const string key,const double fallback)
{
   string raw=XSJsonRaw(json,key);
   if(raw=="" || raw=="null") return fallback;
   return StringToDouble(raw);
}

string XSIso(const datetime server_time)
{
   datetime offset=TimeTradeServer()-TimeGMT();
   offset=(datetime)(((long)offset+450)/900*900);
   MqlDateTime d;
   TimeToStruct(server_time-offset,d);
   return StringFormat("%04d-%02d-%02dT%02d:%02d:%02dZ",d.year,d.mon,d.day,d.hour,d.min,d.sec);
}

string XSGv(const string name)
{
   return "XSL2."+(string)AccountInfoInteger(ACCOUNT_LOGIN)+"."+name+(string)xsPortal;
}

string XSHost()
{
   return "https://tg-backend.topgearsolutions.workers.dev";
}

void XSLog(const string text)
{
   ulong now=GetTickCount64();
   if(text==xsLic.lastLog && now-xsLic.lastLogMs<600000) return;
   xsLic.lastLog=text;
   xsLic.lastLogMs=now;
   Print("XAUscalper: ",text);
}

string XSEndpoint(const string name)
{
   if(name=="validate") return XSHost()+"/ea-validate";
   if(name=="heartbeat") return XSHost()+"/ea-heartbeat";
   if(name=="history") return XSHost()+"/ea-history";
   if(name=="transactions") return XSHost()+"/ea-transactions";
   if(name=="commands") return XSHost()+"/ea-commands";
   return XSHost()+"/"+name;
}

string XSStamp(const datetime server_time)
{
   if(XS_PORTAL_MODE==1) return TimeToString(server_time,TIME_DATE|TIME_SECONDS);
   return XSIso(server_time);
}

string XSTicketJson(const ulong id)
{
   return XS_PORTAL_MODE==1 ? "\""+(string)id+"\"" : (string)id;
}

string XSCase(const string text)
{
   string out=text;
   if(XS_PORTAL_MODE==1) StringToLower(out);
   return out;
}

double XSLotGuard(const double volume)
{
   if(!(volume>0.0)) return 0.0;
   int sizing=MDEffectiveSizingMode(XSActiveSizing(),mdConfiguration.tester);
   double cap=0.0;
   if(xsLic.forceLot>0.0) cap=xsLic.forceLot;          // a lot set by the portal is a hard ceiling
   else if(sizing==0) cap=XSActiveFixedLot();          // fixed mode: exactly the lot that was typed
   else if(MaximumRiskLot>0.0) cap=MaximumRiskLot;     // risk modes: the maximum-lot input
   double lots=volume;
   if(cap>0.0 && lots>cap) lots=cap;
   lots=MDFixedLots(lots,mdVolume);                    // broker minimum / step / maximum
   XSLog("lot check: mode="+(string)sizing+", calculated="+DoubleToString(volume,2)+
         ", sent="+DoubleToString(lots,mdVolume.digits)+
         ", broker min/step/max="+DoubleToString(mdVolume.minimum,2)+"/"+DoubleToString(mdVolume.step,2)+"/"+
         DoubleToString(mdVolume.maximum,2));
   return lots;
}

string XSLicenseKeyText()
{
   string key=LicenseKey;
   StringTrimLeft(key);
   StringTrimRight(key);
   return key;
}

double XSActiveFixedLot()
{
   return xsLic.forceLot>0.0 ? xsLic.forceLot : FixedLot;
}

int XSActiveSizing()
{
   return xsLic.forceLot>0.0 ? (int)MDSizing_Fixed : (int)LotMode;
}

bool XSLicenseEntriesAllowed()
{
   if(xsLic.tester) return true;
   if(!xsLic.firstDone || !xsLic.valid || !xsLic.allowed || xsLic.blocked || xsLic.revoked || xsLic.fatal) return false;
   if(GetTickCount64()-xsLic.lastOkMs>XS_TTL_MS) return false;
   if(xsLic.maxDailyLoss>0.0 && (xsStats.today+xsStats.floating)<=-xsLic.maxDailyLoss) return false;
   return true;
}

string XSAccountTypeText()
{
   long mode=AccountInfoInteger(ACCOUNT_TRADE_MODE);
   if(mode==ACCOUNT_TRADE_MODE_REAL) return "real";
   if(mode==ACCOUNT_TRADE_MODE_DEMO) return "demo";
   return "contest";
}

string XSLicenseBase()
{
   return "{\"license_key\":\""+XSJsonEscape(XSLicenseKeyText())+"\",\""+
          (XS_PORTAL_MODE==1 ? "mt5_account_number" : "mt5_account")+"\":\""+
          (string)AccountInfoInteger(ACCOUNT_LOGIN)+"\""+
          (xsLic.slim ? "" : ",\"account_type\":\""+XSAccountTypeText()+"\",\"is_tester\":"+
                             ((bool)MQLInfoInteger(MQL_TESTER) ? "true" : "false"));
}

bool XSHttpPost(const string endpoint,const string body,string &response,int &code)
{
   char data[],result[];
   string headers="Content-Type: application/json\r\n",resultHeaders="";
   int n=StringToCharArray(body,data,0,StringLen(body),CP_UTF8);
   if(n<0) return false;
   ArrayResize(data,n);
   ResetLastError();
   code=WebRequest("POST",XSEndpoint(endpoint),headers,3000,data,result,resultHeaders);
   if(code==-1)
   {
      int err=GetLastError();
      bool denied=(err==4060 || err==4014);
      if(denied && !xsLic.deniedAlert)
      {
         xsLic.deniedAlert=true;
         Alert("XAUscalper: in MT5 open Tools > Options > Expert Advisors, tick Allow WebRequest and add this address: ",
               "https://tg-backend.topgearsolutions.workers.dev");
      }
      xsLic.webDenied=denied;
      XSLog("cannot reach the portal ("+endpoint+"), error "+(string)err);
      response="";
      return false;
   }
   xsLic.webDenied=false;
   response=CharArrayToString(result,0,WHOLE_ARRAY,CP_UTF8);
   if(code!=200) XSLog("portal answered HTTP "+(string)code+" for "+endpoint);
   if(code==400 && !xsLic.slim)
   {
      xsLic.slim=true;
      XSLog("portal rejected the request format; retrying with the basic fields only");
   }
   return code==200;
}

void XSLicenseFailure()
{
   xsLic.failures++;
   ulong delay=15000;
   for(int i=1;i<xsLic.failures && delay<60000;i++) delay*=2;
   ulong next=GetTickCount64()+MathMin((ulong)60000,delay);
   xsLic.nextValidateMs=next; xsLic.nextBeatMs=next+5000; xsLic.nextCommandsMs=next+10000;
   xsLic.nextHistoryMs=MathMax(xsLic.nextHistoryMs,next+15000);
   xsLic.nextTransMs=MathMax(xsLic.nextTransMs,next+20000);
}

void XSApplyForceLot(const double lot)
{
   if(MathAbs(lot-xsLic.forceLot)<0.0000001) return;
   xsLic.forceLot=lot;
   GlobalVariableSet(XSGv("FL"),lot);
   if(mdEngine.initialized)
   {
      MDDeleteRecognizedPending();
      MDRefreshLotGrowth();
   }
}

void XSLicenseApply(const string response,const bool full)
{
   string status=XSJsonRaw(response,"status");
   string action=XSJsonRaw(response,"action");
   bool splitOnly=(status=="waiting_split" || status=="action_required");
   if(splitOnly) { status="active"; action="NONE"; }
   xsLic.failures=0;
   xsLic.firstDone=true;
   xsLic.lastOkMs=GetTickCount64();
   if(!full && (status=="invalid" || status=="account_mismatch"))
   {
      XSLog("portal answered '"+status+"' on a data call; waiting for the next license check");
      return;
   }
   xsLic.status=status;
   if(full)
   {
      xsLic.owner=XSJsonRaw(response,"owner_name");
      if(xsLic.owner=="null") xsLic.owner="";
      StringReplace(xsLic.owner,"\\\"","\"");
      xsLic.expiry=XSJsonRaw(response,"expiry");
      if(xsLic.expiry=="null") xsLic.expiry="";
      xsLic.mismatch=!XSJsonBool(response,"account_match",true) || status=="account_mismatch";
   }
   else if(status=="account_mismatch") xsLic.mismatch=true;
   xsLic.reason=XSJsonRaw(response,"reason");
   if(full && xsLic.owner=="")
   {
      xsLic.owner=XSJsonRaw(response,"client_name");
      if(xsLic.owner=="null") xsLic.owner="";
   }
   if(status=="invalid" && StringFind(xsLic.reason,"match")>=0) xsLic.mismatch=true;
   bool force=XSJsonBool(response,"force_risk",false);
   double recommended=XSJsonNumber(response,"recommended_lot",0.0);
   if(recommended<=0.0) recommended=XSJsonNumber(response,"lot",0.0);
   XSApplyForceLot(force && recommended>0.0 ? recommended : 0.0);
   xsLic.revoked=(action=="STOP_AND_CLOSE_ALL" || status=="revoked");
   xsLic.allowed=((XSJsonBool(response,"valid",false) || splitOnly) && !xsLic.mismatch && status=="active" && action=="NONE");
   xsLic.valid=xsLic.allowed;
   xsLic.blocked=(!xsLic.allowed && !xsLic.revoked);
   XSLog("portal replied: status="+status+", action="+action);
}

void XSLoadPortalState()
{
   double saved=0.0;
   xsLic.lastClosed=0; xsLic.lastTrans=0; xsLic.forceLot=0.0; xsLic.maxDailyLoss=0.0; xsLic.histTotal=0;
   if(GlobalVariableGet(XSGv("LC"),saved) && saved>0.0) xsLic.lastClosed=(ulong)saved;
   if(GlobalVariableGet(XSGv("LT"),saved) && saved>0.0) xsLic.lastTrans=(ulong)saved;
   if(GlobalVariableGet(XSGv("FL"),saved) && saved>0.0) xsLic.forceLot=saved;
   if(GlobalVariableGet(XSGv("DL"),saved) && saved>0.0) xsLic.maxDailyLoss=saved;
}

void XSPortalChanged()
{
   GlobalVariableSet("XSL2."+(string)AccountInfoInteger(ACCOUNT_LOGIN)+".PT",(double)xsPortal);
   XSLoadPortalState();
   xsLic.nextHistoryMs=GetTickCount64()+5000;
}

bool XSValidateOn(const int portal)
{
   int previous=xsPortal;
   xsPortal=portal;
   string body=XSLicenseBase()+(XS_PORTAL_MODE==1 ? "}" : ",\"current_lot\":"+DoubleToString(XSActiveFixedLot(),2)+"}");
   string response=""; int code=0;
   if(!XSHttpPost("validate",body,response,code))
   {
      xsPortal=previous;
      return false;
   }
   xsLic.lastResponse=response;
   XSLicenseApply(response,true);
   if(portal!=previous) XSPortalChanged();
   return true;
}

void XSLicenseValidate()
{
   ulong now=GetTickCount64();
   xsLic.nextValidateMs=now+XS_PERIOD_MS;
   if(XSLicenseKeyText()=="")
   {
      xsLic.keyMissing=true; xsLic.valid=false; xsLic.allowed=false; xsLic.firstDone=true; xsLic.status="no_key";
      return;
   }
   xsLic.keyMissing=false;
   xsPortal=2;
   if(!XSValidateOn(2))
   {
      XSLicenseFailure();
      return;
   }
}

string XSOrderTypeText(const long type)
{
   switch((int)type)
   {
      case ORDER_TYPE_BUY_LIMIT: return "BUY_LIMIT";
      case ORDER_TYPE_SELL_LIMIT: return "SELL_LIMIT";
      case ORDER_TYPE_BUY_STOP: return "BUY_STOP";
      case ORDER_TYPE_SELL_STOP: return "SELL_STOP";
      case ORDER_TYPE_BUY_STOP_LIMIT: return "BUY_STOP_LIMIT";
      case ORDER_TYPE_SELL_STOP_LIMIT: return "SELL_STOP_LIMIT";
   }
   return "BUY_LIMIT";
}

void XSLicenseBeat()
{
   ulong now=GetTickCount64();
   xsLic.nextBeatMs=now+XS_PERIOD_MS;
   if(XSLicenseKeyText()=="") return;
   string positions="",orders="";
   int count=0;
   for(int i=0;i<PositionsTotal() && count<300;i++)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0) continue;
      string item="{\"ticket\":"+XSTicketJson(ticket)+",\"type\":\""+
                  XSCase(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY ? "BUY" : "SELL")+"\",\"lots\":"+
                  DoubleToString(PositionGetDouble(POSITION_VOLUME),2)+",\"profit\":"+
                  DoubleToString(PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP),2);
      if(XS_PORTAL_MODE==1)
         item+=",\"symbol\":\""+XSJsonEscape(PositionGetString(POSITION_SYMBOL))+"\",\"open_price\":"+
               DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN),5)+",\"sl\":"+
               DoubleToString(PositionGetDouble(POSITION_SL),5)+",\"tp\":"+
               DoubleToString(PositionGetDouble(POSITION_TP),5)+",\"open_time\":\""+
               XSStamp((datetime)PositionGetInteger(POSITION_TIME))+"\"";
      positions+=(count>0 ? "," : "")+item+"}";
      count++;
   }
   count=0;
   for(int i=0;i<OrdersTotal() && count<300;i++)
   {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0) continue;
      string item="{\"ticket\":"+XSTicketJson(ticket)+",\"type\":\""+
                  XSCase(XSOrderTypeText(OrderGetInteger(ORDER_TYPE)))+"\",\"lots\":"+
                  DoubleToString(OrderGetDouble(ORDER_VOLUME_CURRENT),2);
      if(XS_PORTAL_MODE==1)
         item+=",\"symbol\":\""+XSJsonEscape(OrderGetString(ORDER_SYMBOL))+"\",\"price\":"+
               DoubleToString(OrderGetDouble(ORDER_PRICE_OPEN),5);
      orders+=(count>0 ? "," : "")+item+"}";
      count++;
   }
   string body=XSLicenseBase()+
      ",\"balance\":"+DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2)+
      ",\"equity\":"+DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2)+
      ",\"margin\":"+DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN),2)+
      ",\"free_margin\":"+DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE),2)+
      ",\"floating_pnl\":"+DoubleToString(AccountInfoDouble(ACCOUNT_PROFIT),2)+
      (XS_PORTAL_MODE==1 ? ",\"margin_level\":"+DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL),2) :
                      ",\"current_lot\":"+DoubleToString(XSActiveFixedLot(),2))+
      ",\"open_positions\":["+positions+"],\"pending_orders\":["+orders+"]"+
      ",\"broker\":\""+XSJsonEscape(AccountInfoString(ACCOUNT_COMPANY))+"\""+
      ",\"currency\":\""+XSJsonEscape(AccountInfoString(ACCOUNT_CURRENCY))+"\""+
      ",\"ea_version\":\""+XS_EA_VERSION+"\",\"server_time\":\""+XSStamp(TimeTradeServer())+"\"}";
   string response=""; int code=0;
   if(!XSHttpPost("heartbeat",body,response,code)) { XSLicenseFailure(); return; }
   XSLicenseApply(response,false);
}

void XSLicenseCommands()
{
   ulong now=GetTickCount64();
   xsLic.nextCommandsMs=now+XS_PERIOD_MS;
   if(XSLicenseKeyText()=="") return;
   string response=""; int code=0;
   string pollBody=XSLicenseBase()+"}";
   if(!XSHttpPost("commands",pollBody,response,code)) { XSLicenseFailure(); return; }
   XSLicenseApply(response,false);
   bool gotCommands=(StringFind(response,"\"command\"")>=0);
   if(StringFind(response,"\"CLOSE_ALL\"")>=0) xsLic.closeAllPending=true;
   if(StringFind(response,"\"CLEAR_PENDINGS\"")>=0 && mdEngine.initialized) MDDeleteRecognizedPending();
   int p=StringFind(response,"\"APPLY_FORCE_RISK\"");
   if(p>=0)
   {
      string tail=StringSubstr(response,p);
      double lot=XSJsonNumber(tail,"recommended_lot",0.0);
      if(lot<=0.0) lot=XSJsonNumber(tail,"lot",0.0);
      if(lot<=0.0) lot=XSJsonNumber(tail,"max_lot",0.0);
      double loss=XSJsonNumber(tail,"max_daily_loss",0.0);
      if(lot>0.0) XSApplyForceLot(lot);
      if(loss>0.0)
      {
         xsLic.maxDailyLoss=loss;
         GlobalVariableSet(XSGv("DL"),loss);
      }
   }
   if(XS_PORTAL_MODE==1 && gotCommands)
   {
      string ackResponse=""; int ackCode=0;
      XSHttpPost("commands",XSLicenseBase()+",\"ack_all\":true}",ackResponse,ackCode);
   }
}

string XSTransactionKind(const long type,const double amount)
{
   if(type==DEAL_TYPE_BALANCE) return amount>=0.0 ? "deposit" : "withdrawal";
   if(type==DEAL_TYPE_CREDIT) return "credit";
   if(type==DEAL_TYPE_CORRECTION) return "correction";
   if(type==DEAL_TYPE_BONUS) return "bonus";
   return "other";
}

void XSLicenseUploadHistory()
{
   ulong now=GetTickCount64();
   xsLic.nextHistoryMs=now+(XS_PORTAL_MODE==1 ? 300000 : 60000);
   if(XSLicenseKeyText()=="") return;
   if(!HistorySelect(0,TimeCurrent()+86400)) return;
   int total=HistoryDealsTotal();
   if(total==xsLic.histTotal && xsLic.histTotal>0) return;
   CHashMap<ulong,int> index;
   XSClosedTrade trades[];
   int order[];
   int count=0,ordered=0;
   for(int i=0;i<total;i++)
   {
      ulong ticket=HistoryDealGetTicket(i);
      if(ticket==0) continue;
      long type=HistoryDealGetInteger(ticket,DEAL_TYPE);
      if(type!=DEAL_TYPE_BUY && type!=DEAL_TYPE_SELL) continue;
      ulong pid=(ulong)HistoryDealGetInteger(ticket,DEAL_POSITION_ID);
      long entry=HistoryDealGetInteger(ticket,DEAL_ENTRY);
      int slot=-1;
      if(!index.TryGetValue(pid,slot))
      {
         if(entry!=DEAL_ENTRY_IN) continue;
         if(ArrayResize(trades,count+1,512)!=count+1) continue;
         trades[count].id=pid; trades[count].closeTicket=0;
         trades[count].symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
         trades[count].comment=HistoryDealGetString(ticket,DEAL_COMMENT);
         trades[count].type=(type==DEAL_TYPE_BUY ? 0 : 1);
         trades[count].inVol=0.0; trades[count].outVol=0.0; trades[count].closeValue=0.0;
         trades[count].openPrice=HistoryDealGetDouble(ticket,DEAL_PRICE);
         trades[count].sl=0.0; trades[count].tp=0.0;
         trades[count].commission=0.0; trades[count].swap=0.0; trades[count].profit=0.0;
         trades[count].openTime=(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
         trades[count].closeTime=0;
         trades[count].magic=HistoryDealGetInteger(ticket,DEAL_MAGIC);
         trades[count].done=false;
         index.Add(pid,count);
         slot=count;
         count++;
      }
      double volume=HistoryDealGetDouble(ticket,DEAL_VOLUME);
      trades[slot].commission+=HistoryDealGetDouble(ticket,DEAL_COMMISSION)+HistoryDealGetDouble(ticket,DEAL_FEE);
      trades[slot].swap+=HistoryDealGetDouble(ticket,DEAL_SWAP);
      trades[slot].profit+=HistoryDealGetDouble(ticket,DEAL_PROFIT);
      if(entry==DEAL_ENTRY_IN) { trades[slot].inVol+=volume; continue; }
      trades[slot].outVol+=volume;
      trades[slot].closeValue+=HistoryDealGetDouble(ticket,DEAL_PRICE)*volume;
      trades[slot].closeTime=(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
      trades[slot].closeTicket=ticket;
      trades[slot].sl=HistoryDealGetDouble(ticket,DEAL_SL);
      trades[slot].tp=HistoryDealGetDouble(ticket,DEAL_TP);
      if(!trades[slot].done && trades[slot].inVol>0.0 && trades[slot].outVol>=trades[slot].inVol-0.0000001)
      {
         trades[slot].done=true;
         if(ArrayResize(order,ordered+1,512)==ordered+1) { order[ordered]=slot; ordered++; }
      }
   }
   // closed trades, oldest first, 200 per request
   string json="";
   int batch=0,pending=0;
   ulong maxTicket=xsLic.lastClosed;
   for(int k=0;k<ordered;k++)
   {
      int s=order[k];
      if(trades[s].closeTicket<=xsLic.lastClosed) continue;
      if(batch>=200) { pending++; continue; }
      double closePrice=(trades[s].outVol>0.0 ? trades[s].closeValue/trades[s].outVol : 0.0);
      string comment=trades[s].comment;
      if(StringLen(comment)>60) comment=StringSubstr(comment,0,60);
      json+=(batch>0 ? "," : "")+"{\"ticket\":"+XSTicketJson(trades[s].id)+
         ",\"symbol\":\""+XSJsonEscape(trades[s].symbol)+"\""+
         ",\"type\":\""+XSCase(trades[s].type==0 ? "BUY" : "SELL")+"\""+
         ",\"lots\":"+DoubleToString(trades[s].inVol,2)+
         ",\"open_time\":\""+XSStamp(trades[s].openTime)+"\""+
         ",\"close_time\":\""+XSStamp(trades[s].closeTime)+"\""+
         ",\"open_price\":"+DoubleToString(trades[s].openPrice,5)+
         ",\"close_price\":"+DoubleToString(closePrice,5)+
         (trades[s].sl>0.0 ? ",\"sl\":"+DoubleToString(trades[s].sl,5) : "")+
         (trades[s].tp>0.0 ? ",\"tp\":"+DoubleToString(trades[s].tp,5) : "")+
         ",\"commission\":"+DoubleToString(trades[s].commission,2)+
         ",\"swap\":"+DoubleToString(trades[s].swap,2)+
         ",\"profit\":"+DoubleToString(trades[s].profit,2)+
         ",\"magic\":"+(XS_PORTAL_MODE==1 ? "\""+(string)trades[s].magic+"\"" : (string)trades[s].magic)+
         ",\"comment\":\""+XSJsonEscape(comment)+"\"}";
      if(trades[s].closeTicket>maxTicket) maxTicket=trades[s].closeTicket;
      batch++;
   }
   string response=""; int code=0;
   if(batch>0)
   {
      if(!XSHttpPost("history",XSLicenseBase()+(XS_PORTAL_MODE==1 && xsLic.lastClosed==0 ? ",\"full_backfill\":true" : "")+
                     ",\"trades\":["+json+"]}",response,code))
      { xsLic.nextHistoryMs=now+120000; return; }
      xsLic.lastClosed=maxTicket;
      GlobalVariableSet(XSGv("LC"),(double)maxTicket);
      if(pending>0) { xsLic.nextHistoryMs=now+3000; return; }
   }
   // deposits, withdrawals and other account movements
   string moves="";
   int moveCount=0;
   ulong maxMove=xsLic.lastTrans;
   bool more=false;
   for(int i=0;i<total;i++)
   {
      ulong ticket=HistoryDealGetTicket(i);
      if(ticket==0 || ticket<=xsLic.lastTrans) continue;
      long type=HistoryDealGetInteger(ticket,DEAL_TYPE);
      if(type!=DEAL_TYPE_BALANCE && type!=DEAL_TYPE_CREDIT && type!=DEAL_TYPE_CORRECTION &&
         type!=DEAL_TYPE_BONUS && type!=DEAL_TYPE_CHARGE) continue;
      if(moveCount>=200) { more=true; break; }
      double amount=HistoryDealGetDouble(ticket,DEAL_PROFIT);
      string note=HistoryDealGetString(ticket,DEAL_COMMENT);
      if(StringLen(note)>60) note=StringSubstr(note,0,60);
      string kind=XSTransactionKind(type,amount);
      if(XS_PORTAL_MODE==1)
      {
         if(kind=="bonus") kind="credit";
         else if(kind=="other") kind="correction";
      }
      moves+=(moveCount>0 ? "," : "")+"{\"ticket\":"+XSTicketJson(ticket)+
         ",\""+(XS_PORTAL_MODE==1 ? "type" : "kind")+"\":\""+kind+"\""+
         ",\"amount\":"+DoubleToString(amount,2)+
         ",\"time\":\""+XSStamp((datetime)HistoryDealGetInteger(ticket,DEAL_TIME))+"\""+
         ",\"comment\":\""+XSJsonEscape(note)+"\"}";
      if(ticket>maxMove) maxMove=ticket;
      moveCount++;
   }
   if(moveCount>0)
   {
      if(!XSHttpPost("transactions",XSLicenseBase()+",\"transactions\":["+moves+"]}",response,code))
      { xsLic.nextHistoryMs=now+120000; return; }
      xsLic.lastTrans=maxMove;
      GlobalVariableSet(XSGv("LT"),(double)maxMove);
      if(more) { xsLic.nextHistoryMs=now+3000; return; }
   }
   xsLic.histTotal=total;
}

bool XSLicenseFatal()
{
   if(XS_REMOVE_ON_INVALID==0) return false;
   return xsLic.mismatch || xsLic.status=="account_mismatch" || xsLic.status=="invalid";
}

string XSLicenseFatalText()
{
   if(xsLic.reason!="" && xsLic.reason!="null") return xsLic.reason+". The EA has been removed.";
   if(xsLic.status=="invalid") return "License key not recognised. The EA has been removed.";
   return "This license is registered to a different account. The EA has been removed.";
}

int XSOpenPositionCount()
{
   int count=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || MDSelectedPositionModule()<0) continue;
      count++;
   }
   return count;
}

void XSLicenseEnforce()
{
   if(!mdEngine.initialized || mdEngine.closing || mdEngine.worker) return;
   if(xsLic.fatal)
   {
      MDDeleteRecognizedPending();
      MDRequestCurrentPositionsClose(1);
      if(XSOpenPositionCount()==0) ExpertRemove();
      return;
   }
   if(xsLic.closeAllPending)
   {
      MDDeleteRecognizedPending();
      MDRequestCurrentPositionsClose(1);
      if(XSOpenPositionCount()==0) xsLic.closeAllPending=false;
      return;
   }
   if(xsLic.revoked)
   {
      MDDeleteRecognizedPending();
      MDRequestCurrentPositionsClose(1);
   }
   else if(!XSLicenseEntriesAllowed())
      MDDeleteRecognizedPending();
}

void XSLicenseCheckFatal()
{
   if(xsLic.fatal || !XSLicenseFatal()) return;
   xsLic.fatal=true;
   if(!xsLic.fatalShown) { xsLic.fatalShown=true; Alert("XAUscalper: ",XSLicenseFatalText()); }
}

void XSLicenseService()
{
   if(xsLic.tester) return;
   ulong now=GetTickCount64();
   if(!xsLic.fatal)
   {
      if(now>=xsLic.nextValidateMs) XSLicenseValidate();
      else if(now>=xsLic.nextBeatMs) XSLicenseBeat();
      else if(now>=xsLic.nextCommandsMs) XSLicenseCommands();
      else if(xsLic.firstDone && xsLic.status=="active" && now>=xsLic.nextHistoryMs) XSLicenseUploadHistory();
      XSLicenseCheckFatal();
   }
   if(now>=xsLic.nextEnforceMs)
   {
      xsLic.nextEnforceMs=now+2000;
      XSLicenseEnforce();
   }
}

bool XSLicenseInit()
{
   ZeroMemory(xsLic);
   xsLic.tester=((bool)MQLInfoInteger(MQL_TESTER) || (bool)MQLInfoInteger(MQL_OPTIMIZATION));
   if(xsLic.tester) return true;
   xsPortal=2; // dedicated Cloudflare namespace; starts a clean history cursor for migration
   XSLoadPortalState();
   XSLicenseValidate();
   ulong now=GetTickCount64();
   xsLic.nextBeatMs=now+5000; xsLic.nextCommandsMs=now+12000;
   xsLic.nextHistoryMs=now+20000;
   if(XSLicenseFatal())
   {
      Alert("XAUscalper: ",XSLicenseFatalText());
      return false;
   }
   return true;
}

string XSDateOnly(const string iso)
{
   return StringLen(iso)>=10 ? StringSubstr(iso,0,10) : iso;
}

void XSLicensePanel(XSPanelSnapshot &view)
{
   long login=AccountInfoInteger(ACCOUNT_LOGIN);
   view.license_valid=false;
   view.owner_text=(xsLic.owner!="" ? xsLic.owner : "--");
   view.account_text=(string)login;
   view.account_ink=XS_MUTED;
   view.status_text="--";
   view.status_ink=XS_MUTED;
   string status=xsLic.status;
   view.portal_connected=(xsLic.lastOkMs>0 && !xsLic.webDenied && (xsLic.tester || GetTickCount64()-xsLic.lastOkMs<=XS_TTL_MS));
   if(xsLic.tester)
   {
      view.hide_link=true; view.license_valid=true;
      view.license_text="Backtest // license not required";
      view.owner_text="BACKTEST"; view.account_ink=XS_CYAN;
      view.status_text="BACKTEST"; view.status_ink=XS_CYAN;
      return;
   }
   if(xsLic.keyMissing) { view.license_text="Enter your license key in the EA inputs"; view.status_text="NO LICENSE"; view.status_ink=XS_RED; return; }
   if(xsLic.webDenied)
   {
      view.license_text=(xsLic.tester ? "The backtest cannot reach the license server" : "Allow the Cloudflare Worker URL in MT5 > Options > Expert Advisors");
      view.status_text="SETUP NEEDED"; view.status_ink=XS_AMBER; return;
   }
   if(!xsLic.firstDone) { view.license_text="Checking license..."; view.status_text="CHECKING"; view.status_ink=XS_AMBER; return; }
   if(xsLic.mismatch)
   {
      view.license_text="This license belongs to another account";
      view.account_text=(string)login+"  //  WRONG ACCOUNT"; view.account_ink=XS_RED;
      view.status_text="NOT ALLOWED"; view.status_ink=XS_RED; return;
   }
   if(xsLic.revoked || status=="revoked") { view.license_text="License removed // trading stopped"; view.status_text="STOPPED"; view.status_ink=XS_RED; return; }
   if(status=="expired") { view.license_text="License has expired"; view.status_text="EXPIRED"; view.status_ink=XS_RED; return; }
   if(status=="not_started") { view.license_text="License has not started yet"; view.status_text="NOT STARTED"; view.status_ink=XS_AMBER; return; }
   if(status=="invalid") { view.license_text=(xsLic.reason!="" && xsLic.reason!="null" ? xsLic.reason : "License key not recognised"); view.status_text="NOT VALID"; view.status_ink=XS_RED; return; }
   view.account_text=(string)login+"  //  MATCHED"; view.account_ink=XS_GREEN;
   if(status=="action_required" || status=="paused")
   {
      view.license_valid=true;
      view.license_text="Trading is paused until action is completed";
      view.status_text=(status=="paused" ? "PAUSED" : "ACTION NEEDED"); view.status_ink=XS_AMBER; return;
   }
   if(!XSLicenseEntriesAllowed())
   {
      view.license_valid=(status=="active");
      bool offline=(GetTickCount64()-xsLic.lastOkMs>XS_TTL_MS);
      view.license_text=(offline ? "Cannot reach the portal // new entries paused" : "Daily loss limit reached // entries paused");
      view.status_text=(offline ? "OFFLINE" : "LIMIT REACHED"); view.status_ink=XS_AMBER; return;
   }
   view.license_valid=true;
   view.license_text=(xsLic.tester ? "Verified // backtest" : xsLic.expiry!="" ? "Valid until "+XSDateOnly(xsLic.expiry) : "Verified with the portal");
   if(xsLic.forceLot>0.0) view.license_text+=" // lot "+DoubleToString(xsLic.forceLot,2);
   view.status_text="ACTIVE"; view.status_ink=XS_GREEN;
}

//==================== ACTIVITY MESSAGES (chart + Experts tab) ====================
string xsLastActivity="";
ulong xsLastActivityMs=0;
int xsLastPositions=-1,xsLastPending=-1;

string XSLicenseActivity(bool &bad)
{
   bad=false;
   if(xsLic.keyMissing) { bad=true; return "no license key entered"; }
   if(xsLic.webDenied) return "cannot reach the license server (allow its address in MT5)";
   if(!xsLic.firstDone) return "checking the license";
   if(xsLic.mismatch) { bad=true; return "this license belongs to another account"; }
   if(xsLic.revoked) { bad=true; return "license removed, closing trades"; }
   if(xsLic.status=="expired") { bad=true; return "license expired"; }
   if(xsLic.status=="invalid" || xsLic.status=="not_started") { bad=true; return "license not valid"; }
   if(xsLic.blocked) return "paused by your provider";
   if(GetTickCount64()-xsLic.lastOkMs>XS_TTL_MS) return "cannot reach the license server";
   if(xsLic.maxDailyLoss>0.0 && (xsStats.today+xsStats.floating)<=-xsLic.maxDailyLoss) return "daily loss limit reached";
   return "license check";
}

void XSActivityLog(const string text,const int positions,const int pending)
{
   ulong now=GetTickCount64();
   if(text!=xsLastActivity || now-xsLastActivityMs>900000)
   {
      xsLastActivity=text;
      xsLastActivityMs=now;
      Print("XAUscalper: ",text);
   }
   if(positions!=xsLastPositions || pending!=xsLastPending)
   {
      if(xsLastPositions>=0) Print("XAUscalper: open trades ",positions,", pending orders ",pending);
      xsLastPositions=positions;
      xsLastPending=pending;
   }
}

void XSActivityBuild(XSPanelSnapshot &view,const string control,const bool scanning,const int positions,const int pending)
{
   string text="Starting up";
   color ink=XS_AMBER;
   bool paused=true;
   bool spread=WideSpreadProtectionEnabled && (mdSpread.blocked || mdSpread.pending_cleanup);
   if(!XSLicenseEntriesAllowed())
   {
      bool bad=false;
      text="Paused // "+XSLicenseActivity(bad);
      ink=(bad ? XS_RED : XS_AMBER);
   }
   else if(scanning)
   {
      if(spread) text="Paused // spread too wide, waiting for it to normalise";
      else
      {
         paused=false;
         ink=XS_GREEN;
         if(positions>0 && pending>0) text="Managing "+IntegerToString(positions)+" open trade(s) // "+IntegerToString(pending)+" order(s) waiting";
         else if(positions>0) text="Managing "+IntegerToString(positions)+" open trade(s) // protection active";
         else if(pending>0) { text="Orders placed // waiting for price to trigger"; ink=XS_CYAN; }
         else text="Looking for a market opportunity";
      }
   }
   else if(StringFind(control,"PROTECTION ONLY")==0) text="Paused // this symbol or account type is not supported";
   else if(StringFind(control,"ALGO OFF")==0) text="Paused // Algo Trading is switched off in MT5";
   else if(StringFind(control,"MANUAL PAUSE")==0) text="Paused // entries switched off manually";
   else if(StringFind(control,"BROKER STOP")==0) text="Paused // broker stop level is too wide for this symbol";
   else if(StringFind(control,"PROP SHIELD")==0 || StringFind(control,"DAILY SHIELD")==0) text="Paused // daily loss protection reached";
   else if(StringFind(control,"UPGRADE")==0) text="Paused // remove old pending orders first";
   else if(StringFind(control,"WEEKEND")==0) text="Paused // weekend protection";
   else if(StringFind(control,"SESSION")==0) text="Paused // market session is closed";
   else if(StringFind(control,"TRADE WINDOW")==0) text="Paused // outside the set trading hours";
   else if(StringFind(control,"2X AI")==0) text="Starting // loading the AI filter";
   else if(StringFind(control,"CALENDAR INITIAL")==0) text="Starting // checking the news calendar";
   else if(StringFind(control,"CALENDAR UNAVAILABLE")==0) text="Paused // news calendar unavailable (safety pause)";
   else if(StringFind(control,"NEWS SHIELD")==0) text="Paused for news";
   else text="Paused for news // "+control;
   if(paused && positions>0) text+=" | "+IntegerToString(positions)+" open trade(s) protected";
   view.activity_text=text;
   view.activity_ink=ink;
   XSActivityLog(text,positions,pending);
}

void MDUpdatePanel()
{
   if(mdConfiguration.tester)
   {
      if(!MQLInfoInteger(MQL_VISUAL_MODE)) return;
      static ulong lastTesterDraw=0;
      ulong nowMs=GetTickCount64();
      if(nowMs-lastTesterDraw<400) return;
      lastTesterDraw=nowMs;
   }
   MDRefreshTelemetry(mdTelemetry,mdTrade,ShowExecutionComparison);
   XSPanelSnapshot view;
   XSPanelDefaults(view);
   view.enabled=true;
   view.controls_enabled=true;
   view.dashboard_enabled=XSDashboardVisible;
   view.panel_visible=mdEngine.panelVisible;
   view.user_override=mdEngine.panelUserOverride;
   view.execution_enabled=ShowExecutionComparison;
   view.execution_visible=mdEngine.executionVisible;
   view.splash_visible=ShowLaunchSplash && TimeLocal()<mdEngine.splashUntil;
   view.dashboard_scale=XSDashboardScale;
   view.server_time=TimeCurrent();
   view.entry_paused=mdEngine.paused;
   view.pause_error=mdManual.state_error;
   view.cancel_armed=mdManual.cancel_deadline>GetTickCount64();
   view.close_armed=mdManual.close_deadline>GetTickCount64();
   view.close_tooltip=mdManual.close_message;
   view.toolbar_notice=mdManual.message;
   view.subtitle=mdTrade.symbol+" // "+XSPanelSizingCaption(XSActiveSizing(),mdConfiguration.tester,XSActiveFixedLot(),RiskPercent);
   string propCaption=XSPanelPropCaption(PropFirmActive,mdProp.ready,mdProp.total_blocked,
      mdProp.daily_blocked,PropFirmStopAtProfitTarget,mdProp.target_reached,PropFirmMaximumExposureSlots,
      PropFirmActive?MDCountPositions()+MDCountOwnedPending():0);
   string dailyCaption=XSPanelDailyCaption(NormalDailyLimitEnabled,PropFirmActive,mdDaily.ready,
      mdDaily.blocked,mdDaily.reference,AccountInfoDouble(ACCOUNT_EQUITY),NormalMaxDailyLossPercent);
   string control="SCANNING FOR THE NEXT VALID SETUP";
   if(!mdConfiguration.strategyEnvironmentAllowed || !mdConfiguration.newEntriesAllowed) control="PROTECTION ONLY // PROFILE CHECK";
   else if(!mdEngine.tradeAllowed) control="ALGO OFF // PROTECTION LIMITED";
   else if(mdEngine.paused) control="MANUAL PAUSE // POSITIONS PROTECTED";
   else if(!XSLicenseEntriesAllowed()) control="LICENSE // ENTRIES PAUSED";
   else if(!MDPanelStopsCompatible()) control="BROKER STOP LEVEL // INCOMPATIBLE";
   else if(PropFirmActive && !mdEngine.propAllowed) control="PROP SHIELD // "+propCaption;
   else if(!PropFirmActive && NormalDailyLimitEnabled && !mdEngine.dailyAllowed) control="DAILY SHIELD // "+dailyCaption;
   else if(MDUpgradePendingBlocked(false)) control="UPGRADE // REMOVE OLD PENDING";
   else if(mdEngine.weekendBlocked) control="WEEKEND SHIELD // PAUSED";
   else if(!MDBrokerSessionAllows(mdTrade.symbol,TimeCurrent())) control="SESSION // PAUSED";
   else if(!mdEngine.hoursAllowed) control="TRADE WINDOW // PAUSED";
   else if(mdEngine.newsBlocked) control=mdNews.reason!=""?mdNews.reason:"NEWS SHIELD // ACTIVE";
   else if(XSAiModeUsesFilter((int)AiTradingMode) && !xsModelsReady) control="2X AI // NOT READY";
   bool presentationAllowed=control=="SCANNING FOR THE NEXT VALID SETUP";
   XSActivityBuild(view,control,presentationAllowed,MDCountPositions(),MDCountOwnedPending());
   view.entry_state=XSPanelModelState((int)AiTradingMode,xsModelsReady,presentationAllowed);
   view.entry_ink=presentationAllowed?XS_GREEN:XS_AMBER;
   view.control_status=control;
   view.information[1].label=PropFirmActive || !NormalDailyLimitEnabled?"PROP SHIELD":"DAILY SHIELD";
   view.information[1].value=PropFirmActive || !NormalDailyLimitEnabled?propCaption:dailyCaption;
   double displaySpread=SymbolInfoInteger(mdTrade.symbol,SYMBOL_SPREAD)*mdTrade.point/mdConfiguration.pipSize;
   view.information[2].value=DoubleToString(displaySpread,0)+" / "+DoubleToString(mdConfiguration.hardEntrySpreadPoints,0);
   MqlDateTime brokerTime;
   if(TimeToStruct(MDServerNow(),brokerTime))
   {
      string days[7]={"SUN","MON","TUE","WED","THU","FRI","SAT"};
      view.control_heading="SIGNAL CORE // BROKER "+days[brokerTime.day_of_week]+" "+StringFormat("%02d:%02d",brokerTime.hour,brokerTime.min);
   }
   double balance=AccountInfoDouble(ACCOUNT_BALANCE),equity=AccountInfoDouble(ACCOUNT_EQUITY);
   view.metrics[0].value=DoubleToString(balance,2);
   view.metrics[1].value=DoubleToString(equity,2);
   view.metrics[2].value=XSPanelSignedNumber(equity-balance,2);
   view.metrics[3].value=DoubleToString(balance>0?MathMax(0.0,(balance-equity)*100.0/balance):0.0,2)+"%";
   view.module_count=mdConfiguration.moduleCount;
   for(int module=0;module<mdConfiguration.moduleCount;module++)
   {
      view.modules[module].name=mdConfiguration.strategies[module].name;
      bool enabled=MDStrategyEnabled(module,mdConfiguration.quickSetup,mdConfiguration.enabled);
      int positions=MDCountPositions(module),pending=MDCountPending(module);
      view.modules[module].state=XSPanelModuleState(enabled,positions,pending,presentationAllowed);
      view.modules[module].state_ink=enabled?(positions>0?XS_GREEN:XS_CYAN):XS_MUTED;
      view.modules[module].net="--";
   }
   for(int i=0;i<OrdersTotal();i++)
   {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0 || MDSelectedOrderModule()<0) continue;
      ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(!MDIsStopOrder(type)) continue;
      int n=ArraySize(view.pending);
      if(ArrayResize(view.pending,n+1)!=n+1) break;
      view.pending[n].ticket=ticket;
      view.pending[n].price=OrderGetDouble(ORDER_PRICE_OPEN);
      view.pending[n].volume=OrderGetDouble(ORDER_VOLUME_CURRENT);
      view.pending[n].buy_stop=type==ORDER_TYPE_BUY_STOP;
   }
   view.footer_price=mdTrade.symbol+"  "+DoubleToString(SymbolInfoDouble(mdTrade.symbol,SYMBOL_BID),mdTrade.digits);
   view.footer_mode=XSPanelModeCaption((int)AiTradingMode)+" // "+AccountInfoString(ACCOUNT_CURRENCY);
   int firstConfirmation=0;
   for(int i=0;i<mdExecution.positionCount;i++)
      if(mdExecution.positions[i].protection.identifier>0 && mdExecution.positions[i].protection.confirmQuotes>0)
      { firstConfirmation=mdExecution.positions[i].protection.confirmQuotes; break; }
   view.footer_schedule=XSPanelSpikeCaption(mdConfiguration.lockEnabled,mdConfiguration.spikeShield,
      mdConfiguration.protectionMode,firstConfirmation,2)+" // "+
      XSPanelWeekendCaption(WeekendShieldEnabled,mdWeekend.blocked,MDServerNow(),mdWeekend.next_change,
                                 mdWeekend.cutoff,mdWeekend.resume);
   XSStatsRefresh(false);
   XSStatsPanel(view);
   XSLicensePanel(view);
   MDApplyTelemetryPanel(mdTelemetry,view);
   view.controls_enabled=false;
   XSPanelRender(view);
}

int MDInitializeEngine()
{
   ZeroMemory(mdEngine);
   mdEngine.spreadSequence=-1;
   string workerSession=XSWorkerSessionForChart();
   mdEngine.worker=workerSession!="";
   if(mdEngine.worker) return MDCWInitializeWorker(workerSession,mdCalendarWorker)?INIT_SUCCEEDED:INIT_FAILED;
   if(!XSLicenseInit()) return INIT_FAILED;
   ZeroMemory(mdExecution);
   ZeroMemory(mdGrowth);
   ZeroMemory(mdTrade);
   ZeroMemory(mdProp);
   ZeroMemory(mdDaily);
   ZeroMemory(mdWeekend);
   ZeroMemory(mdNews);
   ZeroMemory(mdOfficialNews);
   ZeroMemory(mdNewsCache);
   ZeroMemory(mdSpread);
   ZeroMemory(mdNewsAudit);
   ArrayResize(mdNewsAuditRows,0);
   MDResetTelemetry(mdTelemetry);
   ArrayResize(mdPendingReviews,0);
   ArrayResize(mdNewsWindows,0);
   ArrayResize(mdNewsCacheRecords,0);
   bool tester=(bool)MQLInfoInteger(MQL_TESTER);
   bool gold=MDIsGoldSymbol(_Symbol);
   string error="";
   if(!MDIntegerInRange((int)XSLockProfile,0,3))
   {
      MDConfigurationError(error,"choose a valid ProfitLock profile");
      Print("XAUscalper initialization rejected | ",error);
      return INIT_PARAMETERS_INCORRECT;
   }
   if(!tester)
   {
      long chartIsObject=0;
      if(!ChartGetInteger(0,CHART_IS_OBJECT,0,chartIsObject) || chartIsObject!=0)
      {
         mdEngine.worker=true;
         Print("XAUscalper initialization refused | chart object or chart identity unavailable | missing calendar helper session");
         return INIT_FAILED;
      }
   }
   if(!MDBuildConfiguration(tester,gold,(ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE),
                             _Point,_Digits,mdConfiguration,error,_Period,(bool)MQLInfoInteger(MQL_OPTIMIZATION)))
   { Print("XAUscalper initialization rejected | ",error); return INIT_PARAMETERS_INCORRECT; }
   mdTrade.symbol=_Symbol;
   mdTrade.server=AccountInfoString(ACCOUNT_SERVER);
   mdTrade.login=AccountInfoInteger(ACCOUNT_LOGIN);
   mdTrade.currentBase=MagicNumber;
   mdTrade.previousBase=PreviousXSTradeIdentityBase;
   mdTrade.legacyBase=PreviousXSTradeIdentity;
   mdTrade.quickSetup=(int)XSQuickSetup;
   mdTrade.tester=tester;
   mdTrade.fastMode=mdConfiguration.fastBacktest;
   mdTrade.persistVirtual=PersistVirtualTrailing;
   mdTrade.protectionMode=(int)XSProtectionMode;
   mdTrade.point=_Point;
   mdTrade.digits=_Digits;
   mdTrade.now=MDReliableServerTime();
   for(int i=0;i<9;i++)
   {
      mdTrade.enabled[i]=mdConfiguration.enabled[i];
      mdTrade.triggerTimeframes[i]=mdConfiguration.strategies[i].triggerTimeframe;
   }
   MDRefreshVolumeSpecification();
   MDWarmStrategyHistory();
   if(XSAiModeUsesFilter((int)AiTradingMode) && !InitializeXSModels())
   { Print("Dual-AI initialization failed; no trading authority granted"); return INIT_FAILED; }
   mdProp.prefix=MDGuardPrefix(true,mdTrade.login,8000,mdTrade.server,mdTrade.symbol,PropFirmChallengeId);
   mdDaily.prefix=MDGuardPrefix(false,mdTrade.login,8000,mdTrade.server,mdTrade.symbol,NormalDailyProtectionId);
   if(!MDInitProp(mdConfiguration.prop,mdProp,tester,MDServerNow(),AccountInfoDouble(ACCOUNT_BALANCE),AccountInfoDouble(ACCOUNT_EQUITY)) ||
      !MDInitNormalDaily(mdConfiguration.normalDaily,mdDaily,tester,MDBrokerNow(),AccountInfoDouble(ACCOUNT_EQUITY)))
   { Print("XAUscalper risk-state initialization failed"); ReleaseXSModels(); return INIT_FAILED; }
   if(!MDInitializeLotGrowth()) { ReleaseXSModels(); return INIT_FAILED; }
   MDSaveLotGrowth(true);
   MDManualInitialize(mdManual,tester,mdTrade.login,mdTrade.server,mdTrade.symbol,mdTrade.currentBase);
   mdEngine.paused=mdManual.paused;
   MDResolveWeekend(_Symbol,mdConfiguration.weekend,mdWeekend,MDServerNow(),true);
   bool newsEnabled=(mdConfiguration.news.calendar_shield && (mdConfiguration.news.filter_high || mdConfiguration.news.filter_moderate)) ||
      (mdConfiguration.news.major_control && (!mdConfiguration.news.trade_nfp || !mdConfiguration.news.trade_cpi || !mdConfiguration.news.trade_fomc));
   int lookback=0,lookahead=0;
   if(mdConfiguration.news.calendar_shield)
   { lookback=mdConfiguration.news.news_after; lookahead=mdConfiguration.news.news_before; }
   for(int kind=1;kind<=3;kind++)
   {
      int before=0,after=0;
      if(MDNewsMajorPolicy(mdConfiguration.news,kind,before,after))
      { lookback=MathMax(lookback,after); lookahead=MathMax(lookahead,before); }
   }
   MDCWConfigureParent(mdCalendar,newsEnabled,MDNewsCurrency(NewsCurrency),lookback,lookahead);
   MDLoadConfirmedNewsCache(!tester && !MQLInfoInteger(MQL_OPTIMIZATION),mdConfiguration.news,mdNewsCache,
      mdNewsCacheRecords,mdNewsWindows,mdTrade.login,mdTrade.server,MDServerNow());
   mdEngine.panelVisible=XSDashboardVisible;
   mdEngine.executionVisible=ShowExecutionComparison;
   mdEngine.splashUntil=TimeLocal()+LaunchSplashSeconds;
   InitializeXSLearningLog(LocalLearningLogEnabled,mdTrade.symbol,(ulong)mdTrade.currentBase,
      mdTrade.point,SymbolInfoDouble(mdTrade.symbol,SYMBOL_TRADE_TICK_SIZE),
      SymbolInfoDouble(mdTrade.symbol,SYMBOL_TRADE_TICK_VALUE),"MD421-PROTECTION-RECHECK-RC-20261004");
   mdEngine.pendingDirty=true;
   mdEngine.initialized=true;
   MDBeginCycle();
   MDRefreshQuote();
   if(mdConfiguration.timerEnabled)
      mdEngine.timer=EventSetTimer(1);
   if(!mdEngine.timer && !tester) Print("XAUscalper timer unavailable; tick persistence fallback remains active");
   MDPollCalendar();
   MDCheckSessionGuards(false);
   MDUpdatePanel();
   return INIT_SUCCEEDED;
}

ulong MDFindValidationPosition()
{
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket>0 && PositionGetString(POSITION_SYMBOL)==mdTrade.symbol &&
         PositionGetInteger(POSITION_MAGIC)==mdConfiguration.qualityProbeMagic) return ticket;
   }
   return 0;
}

bool MDValidationClosedNormally()
{
   if(!HistorySelect(0,TimeCurrent())) return false;
   for(int i=HistoryDealsTotal()-1;i>=0;i--)
   {
      ulong deal=HistoryDealGetTicket(i);
      if(deal==0 || HistoryDealGetString(deal,DEAL_SYMBOL)!=mdTrade.symbol ||
         HistoryDealGetInteger(deal,DEAL_MAGIC)!=mdConfiguration.qualityProbeMagic) continue;
      ENUM_DEAL_ENTRY entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal,DEAL_ENTRY);
      if(entry!=DEAL_ENTRY_OUT && entry!=DEAL_ENTRY_INOUT && entry!=DEAL_ENTRY_OUT_BY) continue;
      if(HistoryDealGetInteger(deal,DEAL_REASON)==DEAL_REASON_SO)
      { Print("XS validation close was a stop-out; validation is not complete"); return false; }
      return true;
   }
   return false;
}

string MDValidationComment()
{
   if(PropFirmActive && PropFirmBlankOrderComment) return "";
   string comment=CommentText;
   StringReplace(comment,"\r"," "); StringReplace(comment,"\n"," "); StringReplace(comment,"\t"," ");
   if(comment!="" && AppendModuleToComment) comment+=" ";
   return StringSubstr(comment,0,31);
}

void MDProcessValidationTrade()
{
   if(mdEngine.validationComplete) return;
   ulong ticket=MDFindValidationPosition();
   if(ticket>0)
   {
      MDTradeOutcome outcome;
      if(MDCloseValidationTrade(mdTrade,mdExecution,ticket,outcome)) mdEngine.validationComplete=MDValidationClosedNormally();
      return;
   }
   if(mdEngine.validationOpened)
   { mdEngine.validationComplete=MDValidationClosedNormally(); return; }
   mdEngine.paused=MDManualSync(mdManual);
   datetime now=TimeCurrent();
   if(mdEngine.paused || (mdEngine.validationAttempt>0 && now-mdEngine.validationAttempt<300) ||
      !MDRefreshQuote() || mdEngine.quote.ask<=0 || mdEngine.quote.bid<=0) return;
   double volume=SymbolInfoDouble(mdTrade.symbol,SYMBOL_VOLUME_MIN);
   if(volume<=0) return;
   volume=MDNormalizeDecimal(volume,mdVolume.digits);
   long mode=SymbolInfoInteger(mdTrade.symbol,SYMBOL_TRADE_MODE);
   if(mode!=SYMBOL_TRADE_MODE_LONGONLY && mode!=SYMBOL_TRADE_MODE_SHORTONLY && mode!=SYMBOL_TRADE_MODE_FULL) return;
   mdEngine.validationAttempt=now;
   MDTradeOutcome outcome;
   ZeroMemory(outcome);
   bool opened=false;
   if(mode==SYMBOL_TRADE_MODE_LONGONLY || mode==SYMBOL_TRADE_MODE_FULL)
      opened=MDPlaceValidationTrade(mdTrade,mdExecution,ORDER_TYPE_BUY,volume,
         MDValidationStop(mdTrade,ORDER_TYPE_BUY,mdEngine.quote),MDValidationComment(),outcome);
   if(!opened && !(outcome.sent && outcome.result.retcode==TRADE_RETCODE_PLACED) &&
      (mode==SYMBOL_TRADE_MODE_SHORTONLY || mode==SYMBOL_TRADE_MODE_FULL))
      opened=MDPlaceValidationTrade(mdTrade,mdExecution,ORDER_TYPE_SELL,volume,
         MDValidationStop(mdTrade,ORDER_TYPE_SELL,mdEngine.quote),MDValidationComment(),outcome);
   if(!opened)
   {
      Print("XS validation entry retry | lot=",DoubleToString(volume,mdVolume.digits),
            " | retcode=",outcome.result.retcode," | error=",outcome.lastError);
      return;
   }
   mdEngine.validationOpened=true;
   ticket=MDFindValidationPosition();
   if(ticket>0 && MDCloseValidationTrade(mdTrade,mdExecution,ticket,outcome))
      mdEngine.validationComplete=MDValidationClosedNormally();
}

void MDProcessTickCore()
{
   if(!mdEngine.initialized || mdEngine.worker || mdEngine.closing) return;
   MDBeginCycle();
   MDRefreshLotGrowth();
   bool accountAllowed=MDCheckAccountGuards(true);
   if(mdConfiguration.testerNonGoldMode || mdConfiguration.testerDailyOrHigher)
   {
      if(accountAllowed) MDProcessValidationTrade();
      MDProcessManualClose();
      MDProcessManualPending();
      return;
   }
   mdEngine.entryBudgetDeferred=false;
   mdExecution.entrySendCount=0;
   if(mdConfiguration.nettingAccount && !AllowNettingAccount && OrdersTotal()>0) MDDeleteRecognizedPending();
   MDMaintainPositions();
   MDCheckDirectionLimits();
   MDProcessManualClose();
   MDProcessManualPending();
   MDProcessSpreadMaintenance();
   if(!mdConfiguration.tester && !mdEngine.timer)
   { MDFlushRuntimeState(false); MDPollCalendar(); XSLicenseService(); }
   if(!mdConfiguration.strategyEnvironmentAllowed) return;
   MDReviewPendingModels();
   MDExpirePending();
   MDTrimPendingBook();
   bool sessionAllowed=MDCheckSessionGuards(true);
   if(accountAllowed && sessionAllowed && MDAnyModuleBarReady() && MDEntryAllowed(false)) MDGenerateEntries();
   if(mdConfiguration.tester && MQLInfoInteger(MQL_VISUAL_MODE) && !mdEngine.timer) MDUpdatePanel();
}

void MDProcessTick()
{
   MDProcessTickCore();
   if(!mdEngine.initialized || mdEngine.worker || mdEngine.closing) return;
   if(xsCandidateLog.active && mdEngine.quoteValid)
      UpdateXSLearningQuote(mdEngine.quote.bid,mdEngine.quote.ask,mdEngine.quote.time_msc>0?
         mdEngine.quote.time_msc:(long)mdEngine.quote.time*1000);
   if(!mdConfiguration.tester && !mdEngine.timer) ServiceXSLearningLog();
}

void MDProcessTimer()
{
   if(!mdEngine.initialized || mdEngine.worker || mdEngine.closing || mdConfiguration.testerNonGoldMode ||
      mdConfiguration.testerDailyOrHigher || mdConfiguration.fastBacktest) return;
   if(!mdConfiguration.tester)
   {
      MDBeginCycle();
      MDCheckAccountGuards(true);
      MDMaintainPositions();
      MDProcessManualClose();
      MDProcessManualPending();
      MDProcessSpreadMaintenance();
      MDDrainPendingReviews();
      MDPollCalendar();
      XSLicenseService();
   }
   MDRefreshPermissions(true);
   MDFlushRuntimeState(false);
   ServiceXSLearningLog();
   MDRefreshQuote();
   MDUpdatePanel();
}

void MDProcessTradeTransaction(const MqlTradeTransaction &transaction,const MqlTradeRequest &request,
                               const MqlTradeResult &result)
{
   if(!mdEngine.initialized || mdEngine.worker || mdEngine.closing) return;
   if((int)transaction.type<3 && (((int)transaction.order_type&~3)==4)) mdEngine.pendingDirty=true;
   MDRefreshLotGrowth();
   if(transaction.symbol!="" && transaction.symbol!=mdTrade.symbol) return;
   MDMarkTelemetryDirty(mdTelemetry,transaction,mdTrade.symbol);
   mdExecution.positionsDirty=true;
   MDSchedulePositionCleanup(mdTrade,mdExecution);
   QueueXSLearningTransaction(transaction,result,mdEngine.quoteValid?mdEngine.quote.bid:0,
      mdEngine.quoteValid?mdEngine.quote.ask:0,mdEngine.quoteValid && mdEngine.quote.time_msc>0?
      mdEngine.quote.time_msc:(long)TimeCurrent()*1000);
}

void MDProcessChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{
   if(mdEngine.worker) { MDCWWorkerChartEvent(mdCalendarWorker,id,sparam); return; }
   if(!mdEngine.initialized || mdEngine.closing) return;
   XSPanelIntent intent=XSPanelCommand(id,sparam);
   if(intent==MD_PANEL_CANCEL_AND_PAUSE)
   {
      if(MDManualCancelClick(mdManual,GetTickCount64()))
      {
         ulong tickets[];
         bool complete=MDManualPendingSnapshot(tickets);
         MDManualSetPendingSnapshot(mdManual,tickets,complete);
      }
      mdEngine.paused=mdManual.paused;
   }
   else if(intent==MD_PANEL_RESUME)
   {
      ulong tickets[];
      bool complete=MDManualPendingSnapshot(tickets);
      bool cleaned=complete && ArraySize(tickets)==0?MDManualCleanupFinished():false;
      MDManualResume(mdManual,complete,ArraySize(tickets),cleaned);
      mdEngine.paused=mdManual.paused;
   }
   else if(intent==MD_PANEL_CLOSE_TRADES)
   {
      if(MDManualCloseClick(mdManual,true,GetTickCount64())==2)
      {
         ulong identifiers[];
         bool complete=MDManualPositionSnapshot(identifiers);
         MDManualQueueClose(mdManual,identifiers,complete);
      }
   }
   else if(intent==MD_PANEL_TOGGLE)
   { mdEngine.panelVisible=!mdEngine.panelVisible; mdEngine.panelUserOverride=true; }
   else if(intent==MD_PANEL_EXECUTION) mdEngine.executionVisible=!mdEngine.executionVisible;
   else if(intent==MD_PANEL_MAIN) mdEngine.executionVisible=false;
   if(intent!=MD_PANEL_NONE) { XSPanelInvalidate(); MDUpdatePanel(); }
}

void MDShutdownEngine(const int reason)
{
   if(mdEngine.worker) return;
   mdEngine.closing=true;
   if(mdEngine.initialized)
   {
      MDFlushRuntimeState(true);
      MDSaveProp(mdConfiguration.prop,mdProp,mdConfiguration.tester);
      MDSaveNormalDaily(mdConfiguration.normalDaily,mdDaily,mdConfiguration.tester);
      MDCWDisposeTransport(mdCalendar);
      CloseXSLearningLog(reason);
      Print("XAUscalper AI summary | accepted=",mdEngine.acceptedSignals," | primary_rejected=",mdEngine.primaryRejects,
            " | consensus_rejected=",mdEngine.consensusRejects," | failures=",mdEngine.modelFailures,
            " | pending_reviews=",mdEngine.pendingReviews," | pending_rejected=",mdEngine.pendingRejected,
            " | cancelled=",mdEngine.pendingCancelled);
   }
   EventKillTimer();
   ReleaseXSModels();
   XSPanelDestroy();
   Comment("");
   mdEngine.initialized=false;
}




int OnInit() { return MDInitializeEngine(); }
void OnTick() { MDProcessTick(); }
void OnTimer() { MDProcessTimer(); }
void OnDeinit(const int reason) { MDShutdownEngine(reason); }
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{
   MDProcessChartEvent(id,lparam,dparam,sparam);
}
void OnTradeTransaction(const MqlTradeTransaction &transaction,const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   MDProcessTradeTransaction(transaction,request,result);
}



